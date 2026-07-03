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
  });

  final String idref;
  final String href;
  final String mediaType;
  final bool linear;
  final List<String> properties; // page-spread-left, page-spread-right 등
}
