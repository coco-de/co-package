  // 🎯 Dart imports:
  import 'dart:ui' as ui;

  // 🐦 Flutter imports:

  import 'package:flutter/material.dart';
  // 🌎 Project imports:
  import 'package:open_board/src/core/const.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/models/lasso_selection_state.dart';
  import 'package:open_board/src/module/painter/cursor_paint_delegate.dart';
  import 'package:open_board/src/module/painter/lasso_paint_delegate.dart';
  import 'package:open_board/src/module/painter/shape_paint_delegate.dart';
  import 'package:open_board/src/module/painter/stroke_paint_delegate.dart';
  import 'package:open_board/src/module/painters/sketch_line_painter.dart';
  import 'package:open_board/src/module/state/scribble.state.dart';
  import 'package:open_board/src/module/state/scribble_mode.state.dart';

  // Re-exports for backward compatibility
  export 'package:open_board/src/module/models/lasso_selection_state.dart';
  export 'package:open_board/src/module/models/oriented_bounding_box.dart';
  export 'package:open_board/src/module/painters/sketch_line_painter.dart';

  class ScribblePainter extends CustomPainter with SketchLinePainter {
    final Listenable? repaint;
    final ui.Image? background;
    final ScribbleState state;

    final ScribbleModeState modeState;
    final bool drawPointer;
    final bool drawEraser;
    final bool isActiveLine;
    final List<int> selectedStrokeIds;
    final bool showLassoOverlay;
    final LassoSelectionState? lassoSelectionState;
    final HandlePosition activeHandle;

    ScribblePainter({
      required this.state,
      required this.modeState,
      required this.drawPointer,
      required this.drawEraser,
      this.repaint,
      this.background,
      this.isActiveLine = false,
      this.activeHandle = HandlePosition.none,
      this.selectedStrokeIds = const [],
      required this.showLassoOverlay,
      this.lassoSelectionState,
    }) : super(repaint: repaint);
    @override
    bool shouldRepaint(ScribblePainter oldDelegate) {
      // 🚀 성능 최적화: 실제 변경사항이 있을 때만 repaint
      return state != oldDelegate.state ||
          modeState != oldDelegate.modeState ||
          drawPointer != oldDelegate.drawPointer ||
          drawEraser != oldDelegate.drawEraser ||
          isActiveLine != oldDelegate.isActiveLine ||
          activeHandle != oldDelegate.activeHandle ||
          selectedStrokeIds != oldDelegate.selectedStrokeIds ||
          showLassoOverlay != oldDelegate.showLassoOverlay ||
          lassoSelectionState != oldDelegate.lassoSelectionState ||
          background != oldDelegate.background;
    }

    @override
    void paint(Canvas canvas, Size size) {
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.clipRect(rect);

      // 1. 배경 이미지 렌더링
      _drawBackground(canvas);

      // 2. 스트로크/도형/올가미 렌더링
      if (isActiveLine) {
        _paintActiveLine(canvas);
      } else {
        _paintStaticStrokes(canvas, size);
      }

      // 3. 커서/지우개 포인터 렌더링
      final cursorDelegate = CursorPaintDelegate(
        state: state,
        modeState: modeState,
        drawEraser: drawEraser,
      );
      cursorDelegate.paint(canvas, size);
    }

    /// 배경 이미지 렌더링
    void _drawBackground(Canvas canvas) {
      if (!isActiveLine && background != null) {
        canvas.drawImageRect(
          background!,
          Rect.fromPoints(
            Offset.zero,
            Offset(background!.width.toDouble(), background!.height.toDouble()),
          ),
          Rect.fromPoints(
            Offset.zero,
            Offset(
              background!.width.toDouble() * maxScale,
              background!.height.toDouble() * maxScale,
            ),
          ),
          Paint(),
        );
      }
    }

    /// 현재 그리는 중인 활성 라인 렌더링
    void _paintActiveLine(Canvas canvas) {
      if (state is Drawing && (state as Drawing).activeLine != null) {
        final line = (state as Drawing).activeLine!;

        final strokeDelegate = StrokePaintDelegate(
          strokes: [],
          scaleFactor: modeState.scaleFactor,
        );
        final shapeDelegate = ShapePaintDelegate(strokes: []);

        switch (line.ink) {
          case "marker":
            strokeDelegate.drawMarker(canvas, line);
            break;
          case "pencil":
            strokeDelegate.drawPencil(canvas, line);
            break;
          case "pen":
            strokeDelegate.drawPen(canvas, line);
            break;
          case "fixedPen":
            strokeDelegate.drawFixedPen(canvas, line);
            break;
          case "lasso":
            final lassoDelegate = LassoPaintDelegate(
              allStrokes: state.scribble.strokes,
              selectedStrokeIds: selectedStrokeIds,
              showLassoOverlay: showLassoOverlay,
              lassoSelectionState: lassoSelectionState,
              isActiveLine: true,
            );
            lassoDelegate.drawLassoLine(canvas, line);
            break;
          case "shape":
            if (line.shapeType == "pending") {
              strokeDelegate.drawPen(canvas, line);
            } else {
              final paint = Paint()
                ..color = Color(line.color)
                ..strokeWidth = line.options.size
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke;
              shapeDelegate.drawShape(canvas, paint, line);
            }
            break;
          case "erase":
            break;
        }
      }
    }

    /// 정적 스트로크(완성된 스트로크들) 렌더링
    void _paintStaticStrokes(Canvas canvas, Size size) {
      // 올가미 스트로크 분류
      final nonLassoStrokes = <Stroke>[];
      final Map<int, int> strokeIndexMap = {};

      for (int i = 0; i < state.scribble.strokes.length; i++) {
        final line = state.scribble.strokes[i];
        if (line.ink != "lasso") {
          nonLassoStrokes.add(line);
          strokeIndexMap[nonLassoStrokes.length - 1] = i;
        }
      }

      // delegate 인스턴스 생성
      final strokeDelegate = StrokePaintDelegate(
        strokes: [],
        scaleFactor: modeState.scaleFactor,
      );
      final shapeDelegate = ShapePaintDelegate(strokes: []);

      // 선택되지 않은 일반 스트로크 렌더링
      for (int i = 0; i < nonLassoStrokes.length; i++) {
        final line = nonLassoStrokes[i];
        final originalIndex = strokeIndexMap[i];

        if (selectedStrokeIds.contains(originalIndex)) {
          continue;
        }

        if (line.shapeType.isNotEmpty) {
          final paint = Paint()
            ..color = Color(line.color)
            ..strokeWidth = line.options.size
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
          shapeDelegate.drawShape(canvas, paint, line);
        } else {
          strokeDelegate.drawStroke(canvas, line);
        }
      }

      // 올가미 관련 렌더링 (선택된 스트로크, 올가미 라인, 오버레이)
      final lassoDelegate = LassoPaintDelegate(
        allStrokes: state.scribble.strokes,
        selectedStrokeIds: selectedStrokeIds,
        showLassoOverlay: showLassoOverlay,
        lassoSelectionState: lassoSelectionState,
      );
      lassoDelegate.paint(canvas, size);
    }
  }
