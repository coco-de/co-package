  import 'dart:ui' as ui;

  import 'package:flutter/material.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/models/lasso_selection_state.dart';
  import 'package:open_board/src/module/painter/paint_delegate.dart';
  import 'package:open_board/src/module/painter/shape_paint_delegate.dart';
  import 'package:open_board/src/module/painter/stroke_paint_delegate.dart';

  /// 올가미(lasso) 오버레이 렌더링을 담당하는 Delegate
  ///
  /// 올가미 선택 점선, 선택된 스트로크 강조, 바운딩 박스,
  /// 삭제/변형 버튼 등을 렌더링합니다.
  class LassoPaintDelegate implements PaintDelegate {
    /// 전체 스트로크 목록
    final List<Stroke> allStrokes;

    /// 선택된 스트로크 ID 목록
    final List<int> selectedStrokeIds;

    /// 올가미 오버레이 표시 여부
    final bool showLassoOverlay;

    /// 올가미 선택 상태
    final LassoSelectionState? lassoSelectionState;

    /// 현재 활성 라인인지 여부
    final bool isActiveLine;

    // 내부에서 스트로크/도형 렌더링 시 사용할 delegate
    final StrokePaintDelegate _strokeDelegate = StrokePaintDelegate(
      strokes: [],
    );

    final ShapePaintDelegate _shapeDelegate = ShapePaintDelegate(strokes: []);
    LassoPaintDelegate({
      required this.allStrokes,
      required this.selectedStrokeIds,
      required this.showLassoOverlay,
      required this.lassoSelectionState,
      this.isActiveLine = false,
    });

    @override
    void paint(ui.Canvas canvas, ui.Size size) {
      // 선택된 스트로크 그리기
      if (selectedStrokeIds.isNotEmpty) {
        drawSelectedStrokes(canvas);
      }

      // 올가미 스트로크 찾기 및 그리기
      Stroke? lassoStroke;
      for (final stroke in allStrokes) {
        if (stroke.ink == "lasso") {
          if (lassoStroke == null ||
              DateTime.parse(
                stroke.createdAt,
              ).isAfter(DateTime.parse(lassoStroke.createdAt))) {
            lassoStroke = stroke;
          }
        }
      }

      if (lassoStroke != null) {
        drawLassoLine(canvas, lassoStroke);
      }

      // 올가미 오버레이 렌더링
      if (showLassoOverlay &&
          selectedStrokeIds.isNotEmpty &&
          lassoSelectionState != null) {
        drawLassoOverlay(canvas);
      }
    }

    /// 올가미 선택 라인 그리기 (점선 + 반투명 배경)
    void drawLassoLine(ui.Canvas canvas, Stroke stroke) {
      if (stroke.points.isEmpty) return;

      // 변환 중인지 확인
      bool isTransforming = false;

      if (selectedStrokeIds.isNotEmpty && showLassoOverlay) {
        final currentStrokeIndex = allStrokes.indexOf(stroke);
        if (currentStrokeIndex >= 0) {
          final lassoStrokes = allStrokes
              .where((s) => s.ink == "lasso")
              .toList();
          if (lassoStrokes.isNotEmpty && stroke == lassoStrokes.last) {
            isTransforming = true;
          }
        }
      }

      // 경로 생성
      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }

      // 닫힌 경로 만들기
      if (stroke.points.length > 2 && !isActiveLine) {
        path.close();
      }

      // 변환 중일 때 반투명 배경 채우기
      if (isTransforming && stroke.points.length > 2 && !isActiveLine) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.blue.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill,
        );
      }

      // 점선 테두리
      final borderPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      drawDashedPath(canvas, path, borderPaint, const [10.0, 6.0]);
    }

    /// 선택된 스트로크 그리기
    void drawSelectedStrokes(ui.Canvas canvas) {
      if (selectedStrokeIds.isEmpty) return;

      final selectedStrokes = <Stroke>[];

      for (final id in selectedStrokeIds) {
        if (id >= 0 && id < allStrokes.length) {
          selectedStrokes.add(allStrokes[id]);
        }
      }

      if (selectedStrokes.isEmpty) return;

      canvas.save();

      for (final stroke in selectedStrokes) {
        if (stroke.shapeType.isNotEmpty) {
          final paint = Paint()
            ..color = Color(stroke.color)
            ..strokeWidth = stroke.options.size
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
          _shapeDelegate.drawShape(canvas, paint, stroke);
        } else {
          _strokeDelegate.drawStroke(canvas, stroke);
        }
      }

      canvas.restore();
    }

    /// 올가미 오버레이 렌더링 (삭제/변형 버튼)
    void drawLassoOverlay(ui.Canvas canvas) {
      if (lassoSelectionState?.boundingBox == null) return;

      final boundingBox = lassoSelectionState!.boundingBox!;
      const handleSize = 50.0;
      const borderColor = Colors.blue;

      // 1. 바운딩 박스 테두리
      drawBoundingBox(canvas, boundingBox, lassoSelectionState, borderColor);

      // 2. 버튼 위치 계산
      Offset deleteButtonPosition;
      Offset transformButtonPosition;

      if (lassoSelectionState?.orientedBoundingBox?.corners != null &&
          lassoSelectionState!.orientedBoundingBox!.corners.length >= 4) {
        final corners = lassoSelectionState!.orientedBoundingBox!.corners;
        deleteButtonPosition = corners[1]; // 우상단
        transformButtonPosition = corners[3]; // 좌하단
      } else {
        deleteButtonPosition = Offset(boundingBox.right, boundingBox.top);
        transformButtonPosition = Offset(boundingBox.left, boundingBox.bottom);
      }

      // 3. 삭제 버튼 (우상단)
      drawOverlayButton(
        canvas,
        deleteButtonPosition,
        handleSize,
        Colors.red,
        Icons.delete,
      );

      // 4. 크기조절/회전 버튼 (좌하단)
      drawOverlayButton(
        canvas,
        transformButtonPosition,
        handleSize,
        borderColor,
        Icons.transform,
      );
    }

    /// 바운딩 박스 테두리 그리기
    void drawBoundingBox(
      ui.Canvas canvas,
      Rect boundingBox,
      LassoSelectionState? lassoState,
      Color borderColor,
    ) {
      final paint = Paint()
        ..color = borderColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final fillPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      if (lassoState?.orientedBoundingBox?.corners != null &&
          lassoState!.orientedBoundingBox!.corners.length >= 4) {
        final corners = lassoState.orientedBoundingBox!.corners;

        final path = Path();
        path.moveTo(corners[0].dx, corners[0].dy);
        for (int i = 1; i < corners.length; i++) {
          path.lineTo(corners[i].dx, corners[i].dy);
        }
        path.close();

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawRect(boundingBox, fillPaint);
        canvas.drawRect(boundingBox, paint);
      }
    }

    /// 오버레이 버튼(삭제/변형) 그리기
    void drawOverlayButton(
      ui.Canvas canvas,
      Offset center,
      double size,
      Color color,
      IconData icon,
    ) {
      final radius = size / 2;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      if (icon == Icons.delete) {
        _drawDeleteIcon(canvas, center);
      } else if (icon == Icons.transform) {
        _drawTransformIcon(canvas, center);
      }
    }

    /// 점선 경로 그리기
    void drawDashedPath(
      ui.Canvas canvas,
      Path path,
      Paint paint,
      List<double> dashPattern,
    ) {
      final dashLength = dashPattern[0];
      final dashSpace = dashPattern[1];

      final pathMetrics = path.computeMetrics();

      for (final metric in pathMetrics) {
        double distance = 0.0;
        bool draw = true;

        while (distance < metric.length) {
          final length = draw ? dashLength : dashSpace;
          if (draw) {
            final extractPath = metric.extractPath(distance, distance + length);
            canvas.drawPath(extractPath, paint);
          }
          distance += length;
          draw = !draw;
        }
      }
    }

    void _drawDeleteIcon(ui.Canvas canvas, Offset center) {
      final p = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      const s = 12.0;
      canvas.drawLine(
        center + const Offset(-s / 2, -s / 2),
        center + const Offset(s / 2, s / 2),
        p,
      );
      canvas.drawLine(
        center + const Offset(s / 2, -s / 2),
        center + const Offset(-s / 2, s / 2),
        p,
      );
    }

    void _drawTransformIcon(ui.Canvas canvas, Offset center) {
      final p = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      const s = 10.0;
      canvas.drawLine(
        center + const Offset(-s / 2, s / 2),
        center + const Offset(s / 2, -s / 2),
        p,
      );
      canvas.drawLine(
        center + const Offset(s / 2, -s / 2),
        center + const Offset(s / 2 - 4, -s / 2 + 2),
        p,
      );
      canvas.drawLine(
        center + const Offset(s / 2, -s / 2),
        center + const Offset(s / 2 - 2, -s / 2 + 4),
        p,
      );
    }
  }
