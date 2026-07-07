import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/image/image_drawable_layer.dart';
import 'package:open_board/src/module/widgets/selection_overlay.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/scribble_painter.dart' as painter;
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/text_painter.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// ScribbleWidget의 렌더링 레이어들을 관리하는 클래스
class ScribbleRenderLayers {
  final ScribbleNotifier scribbleNotifier;
  final ScribbleModeNotifier modeNotifier;
  final ScribbleWidgetState widgetState;
  final ValueNotifier<bool> strokeCountNotifier;
  final ui.Image? background;
  final Widget? backgroundChild;
  final Size? size;
  final bool drawPen;
  final bool drawEraser;
  final double pressureFactor;
  final double speedFactor;
  final double minWidthFactor;

  const ScribbleRenderLayers({
    required this.scribbleNotifier,
    required this.modeNotifier,
    required this.widgetState,
    required this.strokeCountNotifier,
    required this.background,
    required this.backgroundChild,
    required this.size,
    required this.drawPen,
    required this.drawEraser,
    this.pressureFactor = 1.0,
    this.speedFactor = 1.0,
    this.minWidthFactor = 0.3,
  });

  /// 배경 레이어 빌드
  List<Widget> buildBackgroundLayers() {
    final layers = <Widget>[];

    if (background != null) {
      layers.add(
        Positioned.fill(
          child: RawImage(
            image: background,
            fit: .contain, // 🎯 비율 유지하면서 화면에 맞춤 (fill → contain)
          ),
        ),
      );
    } else if (backgroundChild != null) {
      layers.add(Positioned.fill(child: backgroundChild!));
    }

    return layers;
  }

  /// 완성된 스트로크 레이어 빌드
  /// 🎯 ValueListenableBuilder로 modeNotifier를 구독해 줌 변화(scaleFactor 갱신)
  ///    시점에도 painter가 즉시 새 modeState로 재구성되도록 한다.
  ///    (기존엔 modeNotifier.state를 직접 읽어 fixedPen 보정이 새 줌으로 적용
  ///     되지 않음 → 기존 스트로크가 줌에 비례해 커지는 버그)
  Widget buildCompletedStrokesLayer() {
    return Positioned.fill(
      child: ValueListenableBuilder<ScribbleModeState>(
        valueListenable: modeNotifier,
        builder: (context, modeState, _) {
          return CustomPaint(
            painter: painter.ScribblePainter(
              state: scribbleNotifier.currentState,
              modeState: modeState,
              drawPointer: drawPen,
              drawEraser: drawEraser,
              background: background,
              selectedStrokeIds: widgetState.selectedStrokeIds,
              activeHandle: widgetState.activeHandle,
              showLassoOverlay: widgetState.showLassoOverlay,
              lassoSelectionState: widgetState.lassoSelectionState,
              repaint: strokeCountNotifier,
            ),
          );
        },
      ),
    );
  }

  /// 텍스트 레이어 빌드
  Widget buildTextLayer({required bool showTextOverlay}) {
    return Positioned.fill(
      child: CustomPaint(
        painter: TextDrawablePainter(
          textDrawables: scribbleNotifier.getCurrentTextDrawables(),
          selectedTextDrawable: widgetState.selectedTextDrawable,
          isTransforming:
              widgetState.isTextTransforming || widgetState.isTextResizing,
          editingTextId: widgetState.editingTextId,
        ),
      ),
    );
  }

  /// 🖼️ 이미지 임베드 레이어 빌드
  ///
  /// 이미지 모드(`InkModes.image`) 및 올가미 모드(`InkModes.lasso`, kobic
  /// #7888)일 때 상호작용(선택/이동/크기조절/회전/삭제)을 허용하고, 그 외
  /// 모드에서는 [IgnorePointer] 로 감싸 이미지만 정적 렌더링하여 스트로크/
  /// 텍스트 포인터 파이프라인을 방해하지 않는다. 올가미 모드에서 기존
  /// 이미지를 직접 터치했을 때 올가미 자유선 그리기가 함께 시작되지 않도록
  /// 하는 가드는 `LassoSelectionManager.handleLassoModePointerDown` 참조.
  Widget buildImageLayer() {
    return ValueListenableBuilder<ScribbleModeState>(
      valueListenable: modeNotifier,
      builder: (context, modeState, _) {
        final selectedInk = modeState.inkGroupInfo.selectedInk;
        final imageInteractive =
            selectedInk == InkModes.image || selectedInk == InkModes.lasso;
        return IgnorePointer(
          ignoring: !imageInteractive,
          child: ImageDrawableLayer(
            notifier: scribbleNotifier,
            widgetState: widgetState,
            interactive: imageInteractive,
          ),
        );
      },
    );
  }

  /// 활성 스트로크 레이어 빌드 (실시간 그리기)
  Widget buildActiveStrokeLayer() {
    return ValueListenableBuilder<ScribbleState>(
      valueListenable: scribbleNotifier,
      builder: (context, state, _) {
        final drawCurrentTool =
            drawPen && state is Drawing || drawEraser && state is Erasing;

        if (!drawCurrentTool) {
          return const SizedBox.shrink();
        }

        return CustomPaint(
          size: size ?? .infinite,
          painter: painter.ScribblePainter(
            state: state,
            modeState: modeNotifier.state,
            drawPointer: drawPen,
            drawEraser: drawEraser,
            isActiveLine: true,
            showLassoOverlay: widgetState.showLassoOverlay,
          ),
        );
      },
    );
  }

  /// 올가미 선택 오버레이 레이어 빌드 (드래그 핸들러만 제공, 시각적 요소는 페인터에서 렌더링)
  List<Widget> buildLassoOverlayLayers({
    required VoidCallback onDelete,
    required Function(DragStartDetails) onResizeRotateStart,
    required Function(DragUpdateDetails) onResizeRotateUpdate,
    required Function(DragEndDetails) onResizeRotateEnd,
    required Function(DragStartDetails) onMoveStart,
    required Function(DragUpdateDetails) onMoveUpdate,
    required Function(DragEndDetails) onMoveEnd,
  }) {
    if (!widgetState.showLassoOverlay ||
        widgetState.selectedStrokeIds.isEmpty) {
      return [];
    }

    // 실시간 업데이트를 위해 ValueListenableBuilder 사용
    return [
      ValueListenableBuilder<ScribbleState>(
        valueListenable: scribbleNotifier,
        builder: (context, state, _) {
          // 원본 바운딩 박스 사용 (회전/크기조절 시에도 원본 유지)
          final boundingBox =
              widgetState.lassoSelectionState.boundingBox ??
              _calculateBoundingBox(widgetState.selectedStrokeIds);

          // 드래그 핸들러 생성
          return Stack(
            children: _buildLassoDragHandlers(
              boundingBox: boundingBox,
              orientedBoundingBox:
                  widgetState.lassoSelectionState.orientedBoundingBox,
              onDelete: onDelete,
              onTransformStart: onResizeRotateStart,
              onTransformUpdate: onResizeRotateUpdate,
              onTransformEnd: onResizeRotateEnd,
              onMoveStart: onMoveStart,
              onMoveUpdate: onMoveUpdate,
              onMoveEnd: onMoveEnd,
            ),
          );
        },
      ),
    ];
  }

  /// 텍스트 선택 오버레이 레이어 빌드 (드래그 핸들러만 제공)
  List<Widget> buildTextOverlayLayers({
    required VoidCallback onTextDelete,
    required Function(DragStartDetails) onTextTransformStart,
    required Function(DragUpdateDetails) onTextTransformUpdate,
    required Function(DragEndDetails) onTextTransformEnd,
    required Function(DragStartDetails) onTextMoveStart,
    required Function(DragUpdateDetails) onTextMoveUpdate,
    required Function(DragEndDetails) onTextMoveEnd,
    required bool showTextOverlay,
  }) {
    if (!showTextOverlay || widgetState.selectedTextDrawable == null) {
      return [];
    }

    final selectedText = widgetState.selectedTextDrawable!;

    // 텍스트 바운딩 박스 계산 (축 정렬)
    final bounds = _calculateTextBounds(selectedText);

    // 회전된 텍스트의 경우 시각적 핸들 위치(회전된 모서리)와
    // 핸들 GestureDetector 위치를 일치시켜야 커서/탭 포인트가
    // 보이는 핸들 위에 정확히 떨어진다.
    final handlePositions = _calculateRotatedHandlePositions(selectedText);

    // 드래그 핸들러만 제공 (시각적 요소는 TextDrawablePainter에서 처리)
    final overlayWidgets = buildSelectionOverlay(
      type: .text,
      boundingBox: bounds,
      onDelete: onTextDelete,
      onTransformStart: onTextTransformStart,
      onTransformUpdate: onTextTransformUpdate,
      onTransformEnd: onTextTransformEnd,
      onMoveStart: onTextMoveStart,
      onMoveUpdate: onTextMoveUpdate,
      onMoveEnd: onTextMoveEnd,
      deleteButtonPosition: handlePositions?['delete'],
      transformButtonPosition: handlePositions?['transform'],
    );

    return overlayWidgets;
  }

  /// 회전된 텍스트의 회전된 핸들 위치 계산
  /// (TextDrawablePainter가 그리는 시각적 핸들 위치와 동일)
  /// 회전이 0이면 null을 반환해 기본(축 정렬) 위치를 사용하게 한다.
  Map<String, Offset>? _calculateRotatedHandlePositions(
    TextDrawable textDrawable,
  ) {
    double rotation = 0.0;
    try {
      rotation = textDrawable.rotation;
    } on Exception {
      rotation = 0.0;
    }
    if (rotation == 0.0) return null;

    final textSpan = TextSpan(
      text: textDrawable.text,
      style: textDrawable.style,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textDrawable.alignment.textAlign,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final center = textDrawable.position;
    final halfWidth = textPainter.width / 2;
    final halfHeight = textPainter.height / 2;

    // 패딩(4px)을 포함한 모서리 — TextDrawablePainter._getRotatedButtonPositions와 일치
    final corners = <Offset>[
      Offset(-halfWidth - 4, -halfHeight - 4), // 좌상단
      Offset(halfWidth + 4, -halfHeight - 4), // 우상단
      Offset(halfWidth + 4, halfHeight + 4), // 우하단
      Offset(-halfWidth - 4, halfHeight + 4), // 좌하단
    ];

    final cos = math.cos(rotation);
    final sin = math.sin(rotation);

    final rotatedCorners = corners
        .map(
          (c) => Offset(
            center.dx + c.dx * cos - c.dy * sin,
            center.dy + c.dx * sin + c.dy * cos,
          ),
        )
        .toList();

    return {
      'delete': rotatedCorners[1], // 우상단
      'transform': rotatedCorners[3], // 좌하단
    };
  }

  /// 모든 레이어를 순서대로 빌드
  List<Widget> buildAllLayers({
    required VoidCallback onDelete,
    required Function(DragStartDetails) onResizeRotateStart,
    required Function(DragUpdateDetails) onResizeRotateUpdate,
    required Function(DragEndDetails) onResizeRotateEnd,
    required Function(DragStartDetails) onMoveStart,
    required Function(DragUpdateDetails) onMoveUpdate,
    required Function(DragEndDetails) onMoveEnd,
    required VoidCallback onTextDelete,
    required Function(DragStartDetails) onTextTransformStart,
    required Function(DragUpdateDetails) onTextTransformUpdate,
    required Function(DragEndDetails) onTextTransformEnd,
    required Function(DragStartDetails) onTextMoveStart,
    required Function(DragUpdateDetails) onTextMoveUpdate,
    required Function(DragEndDetails) onTextMoveEnd,
    required bool showTextOverlay,
  }) {
    final lassoOverlayLayers = buildLassoOverlayLayers(
      onDelete: onDelete,
      onResizeRotateStart: onResizeRotateStart,
      onResizeRotateUpdate: onResizeRotateUpdate,
      onResizeRotateEnd: onResizeRotateEnd,
      onMoveStart: onMoveStart,
      onMoveUpdate: onMoveUpdate,
      onMoveEnd: onMoveEnd,
    );

    final textOverlayLayers = buildTextOverlayLayers(
      onTextDelete: onTextDelete,
      onTextTransformStart: onTextTransformStart,
      onTextTransformUpdate: onTextTransformUpdate,
      onTextTransformEnd: onTextTransformEnd,
      onTextMoveStart: onTextMoveStart,
      onTextMoveUpdate: onTextMoveUpdate,
      onTextMoveEnd: onTextMoveEnd,
      showTextOverlay: showTextOverlay,
    );

    return [
      // 1. 배경 레이어들
      ...buildBackgroundLayers(),

      // 2. 완성된 스트로크 레이어 (올가미 오버레이 포함)
      buildCompletedStrokesLayer(),

      // 3. 텍스트 레이어 (오버레이 버튼 포함)
      buildTextLayer(showTextOverlay: showTextOverlay),

      // 4. 활성 스트로크 레이어 (실시간 그리기)
      buildActiveStrokeLayer(),

      // 5. 올가미 선택 오버레이 레이어 (드래그 핸들러)
      ...lassoOverlayLayers,

      // 6. 텍스트 선택 오버레이 레이어 (드래그 핸들러)
      ...textOverlayLayers,

      // 7. 🖼️ 이미지 임베드 레이어 (렌더 + 이미지 모드 시 선택/변형)
      buildImageLayer(),
    ];
  }

  /// 바운딩 박스 계산 (내부 헬퍼 메서드)
  Rect _calculateBoundingBox(List<int> strokeIds) {
    if (strokeIds.isEmpty) return .zero;

    final strokes = scribbleNotifier.currentState.scribble.strokes;
    double minX = .infinity;
    double minY = .infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final id in strokeIds) {
      if (id >= 0 && id < strokes.length) {
        final stroke = strokes[id];
        for (final point in stroke.points) {
          minX = math.min(minX, point.x);
          minY = math.min(minY, point.y);
          maxX = math.max(maxX, point.x);
          maxY = math.max(maxY, point.y);
        }
      }
    }

    if (minX == .infinity) return .zero;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 텍스트 바운딩 박스 계산 (내부 헬퍼 메서드)
  Rect _calculateTextBounds(TextDrawable textDrawable) {
    return TextDrawablePainter.getTextBounds(textDrawable);
  }

  /// 올가미 드래그 핸들러 빌드 (시각적 요소 없이 드래그만)
  List<Widget> _buildLassoDragHandlers({
    required Rect boundingBox,
    required painter.OrientedBoundingBox? orientedBoundingBox,
    required VoidCallback onDelete,
    required Function(DragStartDetails) onTransformStart,
    required Function(DragUpdateDetails) onTransformUpdate,
    required Function(DragEndDetails) onTransformEnd,
    required Function(DragStartDetails) onMoveStart,
    required Function(DragUpdateDetails) onMoveUpdate,
    required Function(DragEndDetails) onMoveEnd,
  }) {
    const handleSize = 49.0; // 터치 영역 크기 (삭제/변형 버튼) - 시각 버튼 35px 대비 여유

    // 버튼 위치 계산
    Offset deleteButtonPosition;
    Offset transformButtonPosition;

    if (orientedBoundingBox?.corners != null &&
        orientedBoundingBox!.corners.length >= 4) {
      // 회전된 올가미 박스의 경우: 실제 모서리 위치 사용
      final corners = orientedBoundingBox.corners;
      deleteButtonPosition = corners[1]; // 우상단
      transformButtonPosition = corners[3]; // 좌하단
    } else {
      // 일반 박스의 경우: 기존 방식
      deleteButtonPosition = Offset(boundingBox.right, boundingBox.top);
      transformButtonPosition = Offset(boundingBox.left, boundingBox.bottom);
    }

    final widgets = [
      // 바운딩 박스 전체 영역 드래그 (이동)
      Positioned(
        left: boundingBox.left,
        top: boundingBox.top,
        width: boundingBox.width,
        height: boundingBox.height,
        child: GestureDetector(
          behavior: .translucent,
          onPanStart: onMoveStart,
          onPanUpdate: onMoveUpdate,
          onPanEnd: onMoveEnd,
          child: Container(
            // 투명한 컨테이너로 터치 영역만 제공
            color: Colors.transparent,
          ),
        ),
      ),

      // 삭제 버튼 드래그 핸들러 (우상단)
      Positioned(
        left: deleteButtonPosition.dx - handleSize / 2,
        top: deleteButtonPosition.dy - handleSize / 2,
        child: GestureDetector(
          behavior: .opaque,
          onTap: onDelete,
          child: Container(
            width: handleSize,
            height: handleSize,
            // 투명한 컨테이너로 터치 영역만 제공
            color: Colors.transparent,
          ),
        ),
      ),

      // 크기조절/회전 버튼 드래그 핸들러 (좌하단)
      Positioned(
        left: transformButtonPosition.dx - handleSize / 2,
        top: transformButtonPosition.dy - handleSize / 2,
        child: GestureDetector(
          behavior: .opaque,
          onPanStart: onTransformStart,
          onPanUpdate: onTransformUpdate,
          onPanEnd: onTransformEnd,
          child: Container(
            width: handleSize,
            height: handleSize,
            // 투명한 터치 영역
            color: Colors.transparent,
          ),
        ),
      ),
    ];

    return widgets;
  }
}
