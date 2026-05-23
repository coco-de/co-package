// Presentation Engine — open_epub 1.0
// Story: S1.7 (#13) — Fixed Layout 페이지 표시 (단일 페이지 fit)
// Story: S1.8 (#14) — InteractiveViewer 줌 (별도 PR)
// BDD: F3.1 (viewport fit)

import 'package:flutter/material.dart';

import 'viewport_fitter.dart';

/// 단일 Fixed Layout 페이지를 viewport에 fit한 채로 표시한다.
///
/// 콘텐츠는 logical page 크기 (`logicalSize` — EPUB 메타 `rendition:viewport`)
/// 안에서 렌더되고, [ViewportFitter.computeScale]로 화면 viewport에 비율
/// contain fit된다 (디자인 깨짐 없음 — BDD F3.1).
///
/// 핀치 줌 / 더블 탭 줌은 S1.8 (#14)에서 [InteractiveViewer]로 wrap 예정.
class FixedLayoutPage extends StatelessWidget {
  const FixedLayoutPage({
    super.key,
    required this.logicalSize,
    required this.content,
    this.fitter = const ViewportFitter(),
    this.alignment = Alignment.center,
  });

  /// EPUB 메타로 결정된 페이지의 논리 크기 (예: 1024 × 768).
  final Size logicalSize;

  /// 실제 페이지 콘텐츠 (SVG, XHTML, Image 등을 widget으로 wrapping해서 전달).
  final Widget content;

  /// 화면 viewport에 fit시키는 fitter (테스트에서 주입 가능).
  final ViewportFitter fitter;

  /// 페이지 정렬 (default center).
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final scale = fitter.computeScale(
          pageWidth: logicalSize.width,
          pageHeight: logicalSize.height,
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );
        return Align(
          alignment: alignment,
          child: SizedBox(
            width: logicalSize.width * scale,
            height: logicalSize.height * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: logicalSize.width,
                height: logicalSize.height,
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}
