// Presentation Engine — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.6.
// BDD: F2.3 (페이지 전환 ≤ 150ms)

abstract class PaginationStrategy {
  /// 콘텐츠 + viewport 크기를 받아 페이지 분할 인덱스를 산출.
  List<int> paginate({
    required String xhtmlContent,
    required double viewportWidth,
    required double viewportHeight,
    required double fontSize,
    required double lineHeight,
  });
}
