// Public API — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.20.
// BDD: F1 (EPUB 책 열기), Edge-security (size limit, 200MB default)

import 'dart:typed_data';

/// 책 소스 추상. bytes/file/url 3개 factory 지원.
abstract class EpubSource {
  factory EpubSource.bytes(Uint8List bytes) = _BytesSource;
  factory EpubSource.file(String path) = _FileSource;
  factory EpubSource.url(Uri url, {Map<String, String>? headers}) = _UrlSource;

  Future<Uint8List> readBytes();
  String get debugIdentifier;
}

class _BytesSource implements EpubSource {
  _BytesSource(this._bytes);
  final Uint8List _bytes;
  @override
  Future<Uint8List> readBytes() async => throw UnimplementedError('S1.20');
  @override
  String get debugIdentifier => throw UnimplementedError('S1.20');
}

class _FileSource implements EpubSource {
  _FileSource(this._path);
  final String _path;
  @override
  Future<Uint8List> readBytes() async => throw UnimplementedError('S1.20');
  @override
  String get debugIdentifier => throw UnimplementedError('S1.20');
}

class _UrlSource implements EpubSource {
  _UrlSource(this._url, {Map<String, String>? headers}) : _headers = headers;
  final Uri _url;
  final Map<String, String>? _headers;
  @override
  Future<Uint8List> readBytes() async => throw UnimplementedError('S1.20');
  @override
  String get debugIdentifier => throw UnimplementedError('S1.20');
}
