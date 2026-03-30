import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/geometry_utils.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/painter/paint_delegate.dart';

/// 도형(선, 원, 다각형 등) 렌더링을 담당하는 Delegate
class ShapePaintDelegate implements PaintDelegate {
  ShapePaintDelegate({
    required this.strokes,
  });

  /// 렌더링할 도형 스트로크 목록
  final List<Stroke> strokes;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.options.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      drawShape(canvas, paint, stroke);
    }
  }

  /// 도형 타입에 따라 적절한 렌더링 메서드 호출
  void drawShape(ui.Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.length < 2) return;

    switch (stroke.shapeType) {
      case "line":
        _drawLine(canvas, paint, stroke);
        break;
      case "circle":
      case "ellipse":
        _drawCircle(canvas, paint, stroke);
        break;
      case "polyline":
        _drawPolyline(canvas, paint, stroke);
      default:
        if (stroke.segments.isNotEmpty) {
          _drawPolygon(canvas, paint, stroke);

          if (stroke.shapeType == "triangle" && stroke.segments.length >= 3) {
          } else if (stroke.shapeType == "rectangle" &&
              stroke.segments.length >= 4) {}
        }
        break;
    }
  }

  /// 직선 그리기
  void _drawLine(ui.Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.length < 2) return;

    final List<Point> points = stroke.points;
    final Point start = points.first;
    final Point end = points.last;

    final path = Path();
    path.moveTo(start.x, start.y);
    path.lineTo(end.x, end.y);

    canvas.drawPath(path, paint);
  }

  /// 원/타원 그리기 (PCA 기반 주축 분석)
  void _drawCircle(ui.Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.length < 5) {
      _drawPolyline(canvas, paint, stroke);
      return;
    }

    // 중심점 계산
    final centroid = GeometryUtils.calculateCentroid(stroke.points);

    // PCA를 사용한 타원 주축 분석
    double covXx = 0, covYy = 0, covXy = 0;
    for (final point in stroke.points) {
      final dx = point.x - centroid.x;
      final dy = point.y - centroid.y;
      covXx += dx * dx;
      covYy += dy * dy;
      covXy += dx * dy;
    }

    covXx /= stroke.points.length;
    covYy /= stroke.points.length;
    covXy /= stroke.points.length;

    // 회전 각도 계산
    double angle = 0.0;
    if (!(covXx == covYy && covXy == 0.0)) {
      angle = 0.5 * math.atan2(2 * covXy, covXx - covYy);
    }

    // 고유값 계산
    final trace = covXx + covYy;
    final det = covXx * covYy - covXy * covXy;
    final disc = math.sqrt(trace * trace - 4 * det);
    final eigenvalue1 = (trace + disc) / 2;
    final eigenvalue2 = (trace - disc) / 2;

    // 타원 반지름 계산
    final principalAxisLength = math.sqrt(math.max(eigenvalue1, 0));
    final secondaryAxisLength = math.sqrt(math.max(eigenvalue2, 0));
    final aspectRatio = principalAxisLength > 0
        ? secondaryAxisLength / principalAxisLength
        : 1.0;

    final isNearCircular = aspectRatio > 0.9;

    // 실제 타원 크기 계산
    double maxDistX = 0.0;
    double maxDistY = 0.0;

    for (final point in stroke.points) {
      final dx = point.x - centroid.x;
      final dy = point.y - centroid.y;

      final cosA = math.cos(-angle);
      final sinA = math.sin(-angle);
      final rx = dx * cosA - dy * sinA;
      final ry = dx * sinA + dy * cosA;

      maxDistX = math.max(maxDistX, rx.abs());
      maxDistY = math.max(maxDistY, ry.abs());
    }

    final radiusX = isNearCircular
        ? math.max(maxDistX, maxDistY)
        : math.max(principalAxisLength * 1.2, maxDistX * 0.95);

    final radiusY = isNearCircular
        ? radiusX
        : math.max(secondaryAxisLength * 1.2, maxDistY * 0.95);

    canvas.save();
    canvas.translate(centroid.x, centroid.y);
    canvas.rotate(angle);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: radiusX * 2,
      height: radiusY * 2,
    );

    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  /// 폴리곤(닫힌 다각형) 그리기
  void _drawPolygon(ui.Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();

    if (stroke.segments.isNotEmpty) {
      path.moveTo(stroke.segments[0].start.x, stroke.segments[0].start.y);

      for (final segment in stroke.segments) {
        path.lineTo(segment.start.x, segment.start.y);
      }

      if (stroke.segments.isNotEmpty) {
        path.lineTo(stroke.segments[0].start.x, stroke.segments[0].start.y);
      }
    } else {
      final points = stroke.points;
      path.moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
      path.lineTo(points[0].x, points[0].y);
    }

    canvas.drawPath(path, paint);
  }

  /// 폴리라인(열린 선분 연결) 그리기
  void _drawPolyline(ui.Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final polyPaint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = stroke.options.size
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (stroke.segments.isNotEmpty) {
      path.moveTo(stroke.segments[0].start.x, stroke.segments[0].start.y);

      for (final segment in stroke.segments) {
        path.lineTo(segment.end.x, segment.end.y);
      }
    } else {
      final points = stroke.points;
      path.moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
    }

    canvas.drawPath(path, polyPaint);
  }

}
