import 'dart:math';

import 'package:mime/mime.dart';

import '../clock.dart';
import '../disk.dart';
import '../exceptions.dart';
import '../key_normalizer.dart';
import '../types.dart';
import 'upload_slot.dart';

/// Why [DirectUploads.create] refused to sign a slot.
enum UploadRejection {
  /// The file has no bytes.
  empty,

  /// The file is bigger than [DirectUploads.maxBytes].
  tooLarge,

  /// The content type is not one of [DirectUploads.allowedContentTypes].
  contentTypeNotAllowed,
}

/// [DirectUploads.create] refused the file. A server maps this to a 4xx answer.
class UploadRejectedException implements Exception {
  /// What was wrong with the file.
  final UploadRejection rejection;

  /// Plain-English message.
  final String message;

  const UploadRejectedException(this.rejection, this.message);

  @override
  String toString() {
    return 'UploadRejectedException(${rejection.name}): $message';
  }
}

/// Signs direct uploads into one folder of a [Disk], and takes the files back
/// out: the server half of a client sending a file straight to the storage.
///
/// The client never holds a storage key. It asks the server for a slot
/// ([create]), the server checks the file's declared type and size and signs
/// a `PUT` for a key *the server chose*; the client sends the bytes to the
/// storage ([UploadSlot.upload]). To remove a file the client sends back the
/// public URL it was given and the server deletes it ([deleteByUrl]) — only
/// when that URL is inside [prefix].
///
/// **Authorization is the endpoint's job.** This class decides *where* a file
/// may go and *which* files it may remove, not *who* may ask. Make one per
/// request with the user in the prefix (`editor/$userId`), and one user's URL
/// cannot delete another's file.
///
/// ```dart
/// DirectUploads uploads = DirectUploads(disk: disk, prefix: 'editor/$userId');
///
/// // endpoint: createImageUpload(contentType, size)
/// UploadSlot slot = await uploads.create(contentType: type, size: size);
/// return slot.toJson();
///
/// // endpoint: deleteImage(url)
/// await uploads.deleteByUrl(url);
/// ```
class DirectUploads {
  /// The content types of the web's four raster image formats.
  static const Set<String> imageContentTypes = <String>{
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  };

  static const Map<String, String> _extensions = <String, String>{
    'image/png': 'png',
    'image/jpeg': 'jpg',
    'image/gif': 'gif',
    'image/webp': 'webp',
  };

  /// Random bytes in a file's name: 128 bits, so a name cannot be guessed.
  static const int _idBytes = 16;

  /// The disk the files go to. Its driver does the signing, so it must be one
  /// that can ([S3Driver] can; the local disk cannot).
  final Disk disk;

  /// The folder every file goes into and every deletion is held to, without a
  /// trailing slash.
  final String prefix;

  /// The content types [create] signs a slot for, in lower case.
  final Set<String> allowedContentTypes;

  /// The largest file [create] signs a slot for, in bytes.
  final int maxBytes;

  /// How long a slot's [UploadSlot.uploadUrl] stays valid.
  final Duration expiresIn;

  /// Whether the signature pins the upload to the exact size the client said
  /// it would send. With it, a client cannot sign for 10 KiB and send 10 GiB;
  /// without it, only [maxBytes] checked by the *client* stands in the way.
  final bool signContentLength;

  /// Time for the year and month folders. Inject a fixed clock in tests.
  final Clock clock;

  final Random _random;

  /// Creates the uploader for [prefix], a folder of [disk].
  ///
  /// [prefix] is required and not empty: an uploader that could remove files
  /// from the root of the bucket would be a way to remove all of them.
  DirectUploads({
    required this.disk,
    required String prefix,
    this.allowedContentTypes = imageContentTypes,
    this.maxBytes = 10 * 1024 * 1024,
    this.expiresIn = const Duration(minutes: 5),
    this.signContentLength = true,
    this.clock = const Clock(),
    Random? random,
  }) : prefix = _checkedPrefix(prefix),
       _random = random ?? Random.secure();

  static String _checkedPrefix(String prefix) {
    String clean = const KeyNormalizer().prefix(prefix);
    if (clean.isEmpty) {
      throw ArgumentError.value(
        prefix,
        'prefix',
        'must name a folder; an uploader on the root could delete any file',
      );
    }
    return clean;
  }

  /// Reserves a key for a file of [contentType] and [size] bytes, and signs a
  /// `PUT` for it.
  ///
  /// The key is `<prefix>/<year>/<month>/<random>.<extension>`: nothing the
  /// client said goes into it, only the extension that matches the type.
  ///
  /// Throws [UploadRejectedException] when the file is empty, too big or of a
  /// type that is not allowed.
  Future<UploadSlot> create({
    required String contentType,
    required int size,
  }) async {
    String type = contentType.split(';').first.trim().toLowerCase();
    if (size <= 0) {
      throw const UploadRejectedException(
        UploadRejection.empty,
        'The file is empty',
      );
    }
    if (size > maxBytes) {
      throw UploadRejectedException(
        UploadRejection.tooLarge,
        'The file is $size bytes; the limit is $maxBytes',
      );
    }
    if (!allowedContentTypes.contains(type)) {
      throw UploadRejectedException(
        UploadRejection.contentTypeNotAllowed,
        '"$type" is not an allowed content type',
      );
    }
    String key = _newKey(type);
    String uploadUrl = await disk.getSignedUploadUrl(
      key,
      options: SignedUrlOptions(
        expiresIn: expiresIn,
        contentType: type,
        contentLength: signContentLength ? size : null,
      ),
    );
    String publicUrl = await disk.getUrl(key);
    return UploadSlot(
      uploadUrl: uploadUrl,
      publicUrl: publicUrl,
      headers: <String, String>{'content-type': type},
    );
  }

  /// The key behind [url], or null when [url] is not a plain address of a file
  /// inside [prefix].
  ///
  /// Only an address built from the disk's own URL for [prefix] counts: no
  /// query or fragment, no `..`, nothing that decodes to a way out of the
  /// folder. This is what keeps [deleteByUrl] from removing a file the
  /// uploader did not make room for.
  Future<String?> keyOf(String url) async {
    String lead = '${await disk.getUrl(prefix)}/';
    if (!url.startsWith(lead)) {
      return null;
    }
    String rest = url.substring(lead.length);
    if (rest.isEmpty || rest.contains('?') || rest.contains('#')) {
      return null;
    }
    String decoded;
    try {
      decoded = Uri.decodeComponent(rest);
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
    String key;
    try {
      key = const KeyNormalizer().key('$prefix/$decoded');
    } on InvalidKeyException {
      return null;
    }
    // The normalizer folds `a//b` and `./`; what is left must still be inside.
    return key.startsWith('$prefix/') ? key : null;
  }

  /// Deletes the file at [url], which must be a file inside [prefix]. A file
  /// that is already gone is not an error, so a repeated call is harmless.
  ///
  /// Throws [InvalidKeyException] for any other address.
  Future<void> deleteByUrl(String url) async {
    String? key = await keyOf(url);
    if (key == null) {
      throw InvalidKeyException(url, 'not a file of this uploader');
    }
    await disk.delete(key);
  }

  String _newKey(String type) {
    DateTime now = clock.now();
    String month = now.month.toString().padLeft(2, '0');
    String extension = _extensions[type] ?? extensionFromMime(type) ?? 'bin';
    return '$prefix/${now.year}/$month/${_newId()}.$extension';
  }

  String _newId() {
    StringBuffer id = StringBuffer();
    for (int i = 0; i < _idBytes; i++) {
      id.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return id.toString();
  }
}
