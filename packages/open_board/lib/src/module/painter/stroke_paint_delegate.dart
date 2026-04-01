  import 'dart:ui' as ui;

  import 'package:flutter/material.dart';
  import 'package:open_board/src/core/const.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/painter/paint_delegate.dart';
  import 'package:open_board/src/module/painters/sketch_line_painter.dart';

  /// 펜/연필/마커 스트로크 렌더링을 담당하는 Delegate
  class StrokePaintDelegate with SketchLinePainter implements PaintDelegate {
    /// 렌더링할 스트로크 목록
    final List<Stroke> strokes;

    /// 현재 줌 레벨 (fixedPen 렌더링 보정에 사용)
    final double scaleFactor;

    StrokePaintDelegate({required this.strokes, this.scaleFactor = 1.0});

    @override
    void paint(ui.Canvas canvas, ui.Size size) {
      for (final stroke in strokes) {
        drawStroke(canvas, stroke);
      }
    }

    /// 단일 스트로크를 잉크 타입에 따라 렌더링
    void drawStroke(ui.Canvas canvas, Stroke stroke) {
      switch (stroke.ink) {
        case "pen":
          drawPen(canvas, stroke);
          break;
        case "pencil":
          drawPencil(canvas, stroke);
          break;
        case "marker":
          drawMarker(canvas, stroke);
          break;
        case "fixedPen":
          drawFixedPen(canvas, stroke);
          break;
        case "shape":
          // shape 타입인 경우 간단하게 선으로 처리
          drawPen(canvas, stroke);
          break;
        case "erase":
          break;
        default:
          break;
      }
    }

    /// 펜 스트로크 렌더링 (압력 감지 두께 변화)
    void drawPen(ui.Canvas canvas, Stroke stroke) {
      Paint paint = Paint()
        ..color = Color(stroke.color)
        ..style = PaintingStyle.fill;
      final path = getPathForStrokeOld(stroke);
      if (path == null) {
        return;
      }
      canvas.drawPath(path, paint);
    }

    /// 연필 스트로크 렌더링 (균일 두께)
    void drawPencil(ui.Canvas canvas, Stroke stroke) {
      Paint paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.options.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = getSimplePathForStroke(stroke);
      if (path == null) {
        return;
      }
      canvas.drawPath(path, paint);
    }

    /// 고정 두께 펜 렌더링: 화면상 물리적 두께가 줌 레벨과 무관하게 항상 동일
    /// stroke.width에 원래 선택한 두께가 저장되어 있으므로,
    /// 렌더링 시 현재 scaleFactor로 나눠서 보정한다.
    void drawFixedPen(ui.Canvas canvas, Stroke stroke) {
      final adjustedSize = stroke.width / scaleFactor;
      final adjustedStroke = Stroke(
        points: stroke.points,
        color: stroke.color,
        ink: stroke.ink,
        createdAt: stroke.createdAt,
        width: stroke.width,
        shapeType: stroke.shapeType,
        segments: stroke.segments,
        confidence: stroke.confidence,
        options: StrokeOptions(
          size: adjustedSize,
          thinning: stroke.options.thinning,
          smoothing: stroke.options.smoothing,
          streamline: stroke.options.streamline,
          taperStart: stroke.options.taperStart,
          capStart: stroke.options.capStart,
          taperEnd: stroke.options.taperEnd,
          capEnd: stroke.options.capEnd,
          simulatePressure: stroke.options.simulatePressure,
          isComplete: stroke.options.isComplete,
        ),
      );
      Paint paint = Paint()
        ..color = Color(stroke.color)
        ..style = PaintingStyle.fill;
      final path = getPathForStrokeOld(adjustedStroke);
      if (path == null) {
        return;
      }
      canvas.drawPath(path, paint);
    }

    /// 마커 스트로크 렌더링 (투명도 적용, 두께 2배)
    void drawMarker(ui.Canvas canvas, Stroke stroke) {
      stroke.color = applyTransparencyToMarkerColorValue(stroke.color);

      Paint paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.options.size * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = getSimplePathForStroke(
        Stroke(
          points: stroke.points,
          color: stroke.color,
          ink: stroke.ink,
          createdAt: stroke.createdAt,
          options: StrokeOptions(
            size: stroke.options.size * 2,
            thinning: stroke.options.thinning,
            smoothing: stroke.options.smoothing,
            streamline: stroke.options.streamline,
            taperStart: stroke.options.taperStart,
            capStart: stroke.options.capStart,
            taperEnd: stroke.options.taperEnd,
            capEnd: stroke.options.capEnd,
            simulatePressure: stroke.options.simulatePressure,
            isComplete: stroke.options.isComplete,
          ),
        ),
      );
      if (path == null) {
        return;
      }
      canvas.drawPath(path, paint);
    }
  }
