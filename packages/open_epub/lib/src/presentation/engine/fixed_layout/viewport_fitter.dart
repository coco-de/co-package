// Presentation Engine — open_epub 1.0
// Story: S1.7 (#13) — Fixed Layout viewport fit (computeScale)
// Story: S1.9 (#15) — auto spread breakpoint (별도 PR)
// BDD: F3.1 (viewport fit), F3.3 (auto spread)

import 'dart:math' as math;

import '../../../domain/entity/epub_metadata.dart';

/// Fixed Layout 페이지의 viewport 적합 계산.
///
/// `computeScale`은 logical page 크기(EPUB 메타의 `rendition:viewport`)를
/// 화면 viewport에 fit시키는 스케일을 반환한다 (`BoxFit.contain` 동치).
class ViewportFitter {
  const ViewportFitter();

  /// logical page를 화면 viewport에 contain fit. 비율 유지하며 작은 축 기준.
  ///
  /// pageWidth/pageHeight가 0 또는 음수면 안전한 default `1.0`을 반환한다
  /// (호출자가 invalid 페이지를 그릴 책임 — 본 메서드는 throw하지 않는다).
  double computeScale({
    required double pageWidth,
    required double pageHeight,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    if (pageWidth <= 0 || pageHeight <= 0) return 1.0;
    if (viewportWidth <= 0 || viewportHeight <= 0) return 1.0;
    final scaleX = viewportWidth / pageWidth;
    final scaleY = viewportHeight / pageHeight;
    return math.min(scaleX, scaleY);
  }

  /// FR-3.4 / BDD F3.3 — 화면 폭 기반 spread 자동 분기.
  /// Architecture §10.2 + UX Spec §3 breakpoint = 1024px.
  ///
  /// EPUB 메타 [EpubSpread]:
  /// - [EpubSpread.none] → 항상 1-page
  /// - [EpubSpread.both] → 항상 2-page
  /// - [EpubSpread.landscape] → 가로 화면일 때만 2-page (orientation은 viewport
  ///   width > height로 추정)
  /// - [EpubSpread.portrait] → 세로 화면일 때만 2-page
  /// - [EpubSpread.auto] → screenWidth ≥ 1024px에서만 2-page
  bool shouldUseTwoPageSpread({
    required double screenWidth,
    required double screenHeight,
    required EpubSpread spread,
  }) {
    switch (spread) {
      case EpubSpread.none:
        return false;
      case EpubSpread.both:
        return true;
      case EpubSpread.landscape:
        return screenWidth > screenHeight;
      case EpubSpread.portrait:
        return screenHeight > screenWidth;
      case EpubSpread.auto:
        return screenWidth >= 1024;
    }
  }
}
