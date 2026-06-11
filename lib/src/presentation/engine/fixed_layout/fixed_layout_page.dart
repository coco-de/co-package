// Presentation Engine — open_epub 1.0
// Story: S1.7 (#13) — viewport contain fit
// Story: S1.8 (#14) — InteractiveViewer 핀치 줌 + 더블 탭
// BDD: F3.1 (viewport fit), F3.2 (핀치 줌 + 더블 탭 원복)

import 'package:flutter/material.dart';

import 'viewport_fitter.dart';

/// 단일 Fixed Layout 페이지를 viewport에 fit한 채로 표시한다.
///
/// - viewport contain fit (S1.7): logical size를 화면에 비율 유지로 fit.
/// - 핀치 줌 (S1.8): [InteractiveViewer]로 [minZoom] ~ [maxZoom] 배율 줌 + 패닝.
/// - 더블 탭 토글 (S1.8): tap 위치를 중심으로 [doubleTapZoom] ↔ 1.0x 토글.
class FixedLayoutPage extends StatefulWidget {
  const FixedLayoutPage({
    super.key,
    required this.logicalSize,
    required this.content,
    this.fitter = const ViewportFitter(),
    this.alignment = Alignment.center,
    this.minZoom = 1.0,
    this.maxZoom = 4.0,
    this.doubleTapZoom = 2.0,
    this.enableZoom = true,
  }) : assert(minZoom > 0, 'minZoom must be > 0'),
       assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom'),
       assert(
         doubleTapZoom >= minZoom && doubleTapZoom <= maxZoom,
         'doubleTapZoom must be within [minZoom, maxZoom]',
       );

  final Size logicalSize;
  final Widget content;
  final ViewportFitter fitter;
  final AlignmentGeometry alignment;

  /// InteractiveViewer 최소 배율 (default 1.0x).
  final double minZoom;

  /// InteractiveViewer 최대 배율 (default 4.0x — BDD F3.2).
  final double maxZoom;

  /// 더블 탭 시 토글되는 배율 (default 2.0x).
  final double doubleTapZoom;

  /// false면 InteractiveViewer 비활성 (테스트 / 비 줌 모드).
  final bool enableZoom;

  @override
  State<FixedLayoutPage> createState() => FixedLayoutPageState();
}

@visibleForTesting
class FixedLayoutPageState extends State<FixedLayoutPage> {
  late final TransformationController _controller;

  TransformationController get controller => _controller;

  /// 현재 배율 (TransformationController의 scale).
  double get currentScale => _controller.value.getMaxScaleOnAxis();

  /// 1.0x 기준에서 줌 인된 상태인지.
  bool get isZoomedIn => currentScale > widget.minZoom + 0.001;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 더블 탭 시 호출. tap 위치를 중심으로 toggle.
  void onDoubleTapAt(Offset localPos) {
    if (isZoomedIn) {
      _controller.value = Matrix4.identity();
      return;
    }
    final z = widget.doubleTapZoom;
    // localPos를 zoom 중심으로 — 해당 점을 fixed하기 위해 translate 후 scale.
    final m = Matrix4.identity()
      ..translateByDouble(-localPos.dx * (z - 1), -localPos.dy * (z - 1), 0, 1)
      ..scaleByDouble(z, z, z, 1);
    _controller.value = m;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final scale = widget.fitter.computeScale(
          pageWidth: widget.logicalSize.width,
          pageHeight: widget.logicalSize.height,
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );
        final fittedW = widget.logicalSize.width * scale;
        final fittedH = widget.logicalSize.height * scale;

        final fitted = Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: fittedW,
            height: fittedH,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: widget.logicalSize.width,
                height: widget.logicalSize.height,
                child: widget.content,
              ),
            ),
          ),
        );

        if (!widget.enableZoom) return fitted;

        return GestureDetector(
          onDoubleTapDown: (details) => onDoubleTapAt(details.localPosition),
          onDoubleTap: () {}, // 더블탭 트리거를 위해 빈 핸들러 제공
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: widget.minZoom,
            maxScale: widget.maxZoom,
            panEnabled: true,
            scaleEnabled: true,
            child: fitted,
          ),
        );
      },
    );
  }
}
