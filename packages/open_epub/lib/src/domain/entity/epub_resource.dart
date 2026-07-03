// Domain Entity — open_epub 1.0
// Story: S1.21 (#37) — 세션이 본문 XHTML/이미지를 읽기 위한 리소스 접근 추상.

import 'dart:typed_data';

/// EPUB 내부 리소스 (이미지/CSS/폰트 등). path normalization 적용 후 노출.
class EpubResource {
  const EpubResource({
    required this.href,
    required this.mediaType,
    required this.bytes,
  });

  final String href;
  final String mediaType;
  final Uint8List bytes;
}

/// 열린 EPUB 컨테이너의 리소스 reader. href는 OPF 기준 상대 경로이며
/// `.`/`..` 정규화는 구현체가 책임진다. 없는 리소스는 null.
abstract class EpubResourceReader {
  Uint8List? readBytes(String href);
  String? readString(String href);
}

/// 리소스가 없는 reader (기본값·테스트 더블용).
class EmptyEpubResourceReader implements EpubResourceReader {
  const EmptyEpubResourceReader();

  @override
  Uint8List? readBytes(String href) => null;

  @override
  String? readString(String href) => null;
}
