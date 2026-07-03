// Domain Entity — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.2, S1.3.
// BDD: F4 (TOC)

/// EPUB 목차 트리. NCX (2.0) 또는 nav.xhtml (3.x) 파싱 결과.
class EpubOutline {
  const EpubOutline({required this.items});

  final List<EpubOutlineItem> items;

  static const EpubOutline empty = EpubOutline(items: []);
}

class EpubOutlineItem {
  const EpubOutlineItem({
    required this.title,
    required this.spineHref,
    this.charOffset,
    this.children = const [],
  });

  final String title;
  final String spineHref;
  final int? charOffset;
  final List<EpubOutlineItem> children;
}
