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
    this.transformationController,
    this.foregroundBuilder,
  })  : assert(minZoom > 0, 'minZoom must be > 0'),
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

  /// 호스트가 zoom/pan을 공유·관찰하려면 주입한다(open-board 필기 오버레이가
  /// 같은 변환 행렬로 본문과 필기 레이어를 정렬, S8.3). null이면 내부 생성.
  /// 주입 시 dispose는 호스트 책임.
  final TransformationController? transformationController;

  /// 페이지 콘텐츠 위에 **같은 논리 좌표 공간**으로 합성되는 전경 오버레이를
  /// 빌드한다(open-board 절대좌표 필기 캔버스 등, S8.6). [logicalSize]는 페이지
  /// 논리 크기 — 빌더의 로컬 좌표가 곧 페이지 절대좌표이며, fit·zoom·pan과 함께
  /// 자동 변환된다. null이면 오버레이 없음.
  ///
  /// 오버레이는 `content`와 동일한 `SizedBox(logicalSize)` 안에 Stack으로 쌓이므로
  /// 별도 좌표 변환 없이 절대좌표로 그릴 수 있다. 드로잉 중 pan/zoom 충돌을 막으려면
  /// [enableZoom]을 false로 두어 InteractiveViewer를 비활성화한다.
  final Widget Function(BuildContext context, Size logicalSize)?
  foregroundBuilder;

  @override
  State<FixedLayoutPage> createState() => FixedLayoutPageState();
}

@visibleForTesting
class FixedLayoutPageState extends State<FixedLayoutPage> {
  late final TransformationController _controller;

  /// 내부 생성 컨트롤러만 dispose한다(주입된 것은 호스트 소유).
  bool _ownsController = false;

  TransformationController get controller => _controller;

  /// 현재 배율 (TransformationController의 scale).
  double get currentScale => _controller.value.getMaxScaleOnAxis();

  /// 1.0x 기준에서 줌 인된 상태인지.
  bool get isZoomedIn => currentScale > widget.minZoom + 0.001;

  @override
  void initState() {
    super.initState();
    final injected = widget.transformationController;
    _controller = injected ?? TransformationController();
    _ownsController = injected == null;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
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

        // 전경 오버레이가 있으면 content와 같은 논리 좌표 공간에 Stack으로 쌓는다.
        // 두 자식 모두 SizedBox(logicalSize)의 tight 제약을 받아 페이지 절대좌표를
        // 공유하므로, FittedBox·InteractiveViewer 변환이 동일하게 적용된다(S8.6).
        final overlay = widget.foregroundBuilder;
        final Widget logicalChild = overlay == null
            ? widget.content
            : Stack(
                fit: StackFit.expand,
                children: [
                  widget.content,
                  overlay(ctx, widget.logicalSize),
                ],
              );

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
                child: logicalChild,
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
