// Presentation Engine — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.7, S1.9.
// BDD: F3.1 (viewport fit), F3.3 (auto spread ≥1024px)

class ViewportFitter {
  /// 페이지 비율을 화면 viewport에 맞추는 scale 계산.
  double computeScale({
    required double pageWidth,
    required double pageHeight,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    throw UnimplementedError('S1.7');
  }

  /// FR-3.4: 화면 폭 기반 spread 자동 분기.
  bool shouldUseTwoPageSpread(double screenWidth, String renditionSpread) {
    throw UnimplementedError('S1.9');
  }
}
