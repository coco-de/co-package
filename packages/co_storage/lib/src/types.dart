// Forked from dox_storage 3.0.1 (MIT, see THIRD_PARTY_LICENSES and FORK.md).
// Source: https://github.com/dartondox/dox-storage

import 'constants/storage_constants.dart';

/// Who can read a file through its public URL.
enum Visibility { public, private }

/// Options for writing a file.
class WriteOptions {
  /// MIME type. When null, drivers guess it from the key.
  final String? contentType;

  /// When null, the driver uses its default visibility.
  final Visibility? visibility;

  const WriteOptions({this.contentType, this.visibility});
}

/// Options for signed URLs.
class SignedUrlOptions {
  /// How long the URL stays valid.
  final Duration expiresIn;

  /// Download: ask the server to send this Content-Type.
  /// Upload: the Content-Type the client must send.
  final String? contentType;

  /// Download only: ask the server to send this Content-Disposition,
  /// for example `attachment; filename="report.pdf"`.
  final String? contentDisposition;

  /// Upload only: the exact number of bytes the client must send. It is
  /// signed into the URL, so S3 refuses a body of any other size. A signed
  /// URL has no other way to cap the size of what is uploaded.
  ///
  /// Added by Cocode (not in dox_storage); see FORK.md.
  final int? contentLength;

  const SignedUrlOptions({
    this.expiresIn = StorageConstants.defaultSignedUrlExpiry,
    this.contentType,
    this.contentDisposition,
    this.contentLength,
  });
}

/// Options for listing files.
class ListOptions {
  /// When true, list every file under the prefix (no folders).
  /// When false, list direct files and folders only.
  final bool recursive;

  /// Page size. When null, all entries are returned in one result.
  final int? limit;

  /// The token from the previous page.
  final String? paginationToken;

  const ListOptions({this.recursive = false, this.limit, this.paginationToken});
}

/// Facts about a stored file.
class ObjectMetaData {
  final int size;
  final String contentType;
  final DateTime lastModified;
  final String etag;

  const ObjectMetaData({
    required this.size,
    required this.contentType,
    required this.lastModified,
    required this.etag,
  });

  @override
  String toString() {
    return 'ObjectMetaData(size: $size, contentType: $contentType, '
        'lastModified: $lastModified, etag: $etag)';
  }
}

/// One entry in a listing: a file or a folder.
sealed class DriveEntry {
  /// Full key (file) or full prefix without trailing slash (folder).
  final String key;

  const DriveEntry(this.key);

  /// Last part of the key.
  String get name {
    return key.split('/').last;
  }
}

/// A file in a listing.
class DriveFile extends DriveEntry {
  const DriveFile(super.key);

  @override
  String toString() {
    return 'DriveFile($key)';
  }
}

/// A folder in a listing.
class DriveDirectory extends DriveEntry {
  const DriveDirectory(super.key);

  @override
  String toString() {
    return 'DriveDirectory($key)';
  }
}

/// One page of a listing.
class ListResult {
  final List<DriveEntry> objects;

  /// Pass this to the next `listAll` call. Null on the last page.
  final String? paginationToken;

  const ListResult(this.objects, {this.paginationToken});
}
