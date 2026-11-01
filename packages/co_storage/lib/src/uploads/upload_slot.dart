import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// A signed place to put one file, handed from a server to a client.
///
/// The server makes it (`DirectUploads.create`) and sends it as JSON
/// ([toJson]); the client reads it ([UploadSlot.fromJson]) and sends the file
/// with [upload]. The slot holds no secret: [uploadUrl] is signed for one key,
/// one content type and one size, for a few minutes, and [publicUrl] is where
/// the file can be read from once it is there.
///
/// This file needs only `package:http`, so it compiles for the web.
class UploadSlot {
  /// Where to `PUT` the file: a URL signed for one key.
  final String uploadUrl;

  /// Where the file can be read from once it is uploaded. This is the address
  /// to keep (in a document, a database row).
  final String publicUrl;

  /// Headers the `PUT` must carry, exactly as given — `content-type` is part
  /// of the signature, so a different value is refused.
  final Map<String, String> headers;

  const UploadSlot({
    required this.uploadUrl,
    required this.publicUrl,
    this.headers = const <String, String>{},
  });

  /// Reads a slot from [json], the shape [toJson] writes.
  ///
  /// Throws a [FormatException] when a field is missing or of the wrong type.
  factory UploadSlot.fromJson(Map<String, Object?> json) {
    Object? uploadUrl = json['uploadUrl'];
    Object? publicUrl = json['publicUrl'];
    if (uploadUrl is! String || publicUrl is! String) {
      throw FormatException(
        'An upload slot needs "uploadUrl" and "publicUrl" strings',
        json,
      );
    }
    Map<String, String> headers = <String, String>{};
    Object? sent = json['headers'];
    if (sent is Map) {
      for (MapEntry<Object?, Object?> entry in sent.entries) {
        Object? name = entry.key;
        Object? value = entry.value;
        if (name is! String || value is! String) {
          throw FormatException('Upload slot headers must be strings', json);
        }
        headers[name] = value;
      }
    } else if (sent != null) {
      throw FormatException('Upload slot "headers" must be a map', json);
    }
    return UploadSlot(
      uploadUrl: uploadUrl,
      publicUrl: publicUrl,
      headers: headers,
    );
  }

  /// The slot as plain JSON, for a server to send.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'uploadUrl': uploadUrl,
      'publicUrl': publicUrl,
      'headers': Map<String, String>.of(headers),
    };
  }

  /// Sends [bytes] to [uploadUrl] and completes once the storage accepted them.
  ///
  /// Throws [UploadFailedException] when it answers anything but success.
  /// Pass [client] to reuse one (or to fake the storage in a test); otherwise a
  /// client lives for this call only.
  ///
  /// In a browser the bucket's CORS rules must allow `PUT` and the
  /// `content-type` header from the page's origin.
  Future<void> upload(Uint8List bytes, {http.Client? client}) async {
    http.Client sender = client ?? http.Client();
    try {
      http.Response response = await sender.put(
        Uri.parse(uploadUrl),
        headers: headers,
        body: bytes,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw UploadFailedException(response.statusCode, response.body);
      }
    } finally {
      if (client == null) {
        sender.close();
      }
    }
  }
}

/// The storage answered an [UploadSlot.upload] with something other than
/// success — an expired or mismatched signature, a CORS or permission error.
class UploadFailedException implements Exception {
  /// The HTTP status the storage answered with.
  final int statusCode;

  /// The body of that answer; S3 explains the refusal there, in XML.
  final String body;

  const UploadFailedException(this.statusCode, this.body);

  @override
  String toString() {
    return 'UploadFailedException: the storage answered $statusCode\n$body';
  }
}
