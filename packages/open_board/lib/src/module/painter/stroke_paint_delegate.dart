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

  const StrokePaintDelegate({required this.strokes, this.scaleFactor = 1.0});

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
      ..style = .fill;
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
      ..strokeCap = .round
      ..strokeJoin = .round
      ..style = .stroke;
    final path = getSimplePathForStroke(stroke);
    if (path == null) {
      return;
    }
    canvas.drawPath(path, paint);
  }

  /// 고정 두께 펜 렌더링:
  ///   1) 그릴 당시 줌에 맞춰 캔버스 두께가 자동으로 결정됨 (생성 시 한 번):
  ///      더 확대해서 그리면 캔버스 좌표상 더 가는 선, 같은 슬라이더라도
  ///      모든 줌에서 그릴 때의 화면 픽셀 두께는 일정하게 보임.
  ///   2) 한 번 그려진 스트로크의 캔버스 두께는 frozen — 줌 변화 시 동적으로
  ///      재계산하지 않고 stroke.options.size를 그대로 사용. 따라서 기존
  ///      스트로크는 일반 펜처럼 줌과 함께 화면상 비례 스케일됨.
  ///   3) 스트로크 전 구간 균일 두께 (thinning 0 + simulatePressure false).
  void drawFixedPen(ui.Canvas canvas, Stroke stroke) {
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
        // frozen된 스트로크 자체의 size 사용 (재계산 X)
        size: stroke.options.size,
        // 기존 저장 strokes도 균일 두께 보장 (압력/속도 변화 무시)
        thinning: 0.0,
        smoothing: stroke.options.smoothing,
        streamline: stroke.options.streamline,
        taperStart: stroke.options.taperStart,
        capStart: stroke.options.capStart,
        taperEnd: stroke.options.taperEnd,
        capEnd: stroke.options.capEnd,
        simulatePressure: false,
        isComplete: stroke.options.isComplete,
      ),
    );
    Paint paint = Paint()
      ..color = Color(stroke.color)
      ..style = .fill;
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
      ..strokeCap = .round
      ..strokeJoin = .round
      ..style = .stroke;
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
