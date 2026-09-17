// Domain Entity — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.4.

/// EPUB spine 항목. OPF의 `<itemref>`와 manifest의 `<item>`을 결합한 표현.
class EpubSpineItem {
  const EpubSpineItem({
    required this.idref,
    required this.href,
    required this.mediaType,
    this.linear = true,
    this.properties = const [],
    this.mediaOverlayHref,
  });

  final String idref;
  final String href;
  final String mediaType;
  final bool linear;
  final List<String> properties; // page-spread-left, page-spread-right 등

  /// 이 spine 문서에 연결된 Media Overlay(.smil) 파일의 OPF 기준 상대 경로.
  /// manifest item의 `media-overlay` 속성(SMIL manifest item id 참조)을 해석해
  /// 채운다. MO가 없으면 null. (S15.1, gap #6 배선분)
  final String? mediaOverlayHref;
}
