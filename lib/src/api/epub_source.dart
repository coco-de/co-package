// Public API — open_epub 1.0
// Story: S1.20 (#36) — EpubSource 추상 (bytes/file/url)
// BDD: F1 (EPUB 책 열기), Edge-security (size limit, 200MB default)

import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/entity/epub_failure.dart';

// 파일 읽기는 dart:io 의존이라 web에서 컴파일되지 않는다.
// 조건부 import로 web에서는 UnsupportedError를 던지는 stub을 사용한다.
import 'epub_file_reader_io.dart'
    if (dart.library.html) 'epub_file_reader_web.dart' as file_reader;

/// 책 소스 추상. bytes/file/url 3개 factory 지원.
///
/// [readBytes]는 EPUB ZIP 컨테이너의 원본 바이트를 반환한다. 크기 제한·보안
/// 검증은 상위(EpubRepository.load + EpubSecurityConfig)에서 적용한다.
abstract class EpubSource {
  factory EpubSource.bytes(Uint8List bytes) = _BytesSource;
  factory EpubSource.file(String path) = _FileSource;
  factory EpubSource.url(Uri url, {Map<String, String>? headers}) = _UrlSource;

  Future<Uint8List> readBytes();
  String get debugIdentifier;
}

/// 메모리 바이트 소스. (가장 단순·플랫폼 무관, 테스트의 기본 소스)
class _BytesSource implements EpubSource {
  _BytesSource(this._bytes);
  final Uint8List _bytes;
  @override
  Future<Uint8List> readBytes() async => _bytes;
  @override
  String get debugIdentifier => 'bytes(${_bytes.length}B)';
}

/// 로컬 파일 소스. web에서는 [UnsupportedError].
class _FileSource implements EpubSource {
  _FileSource(this._path);
  final String _path;
  @override
  Future<Uint8List> readBytes() => file_reader.readFileBytes(_path);
  @override
  String get debugIdentifier => 'file($_path)';
}

/// 원격 URL 소스. http 패키지를 사용하므로 모든 플랫폼에서 동작한다.
class _UrlSource implements EpubSource {
  _UrlSource(this._url, {Map<String, String>? headers}) : _headers = headers;
  final Uri _url;
  final Map<String, String>? _headers;
  @override
  Future<Uint8List> readBytes() async {
    final http.Response res;
    try {
      res = await http.get(_url, headers: _headers);
    } on Object catch (e) {
      throw EpubNetworkFailure('failed to fetch $_url: $e');
    }
    if (res.statusCode != 200) {
      throw EpubNetworkFailure('HTTP ${res.statusCode} for $_url');
    }
    return res.bodyBytes;
  }

  @override
  String get debugIdentifier => 'url($_url)';
}
