import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/geometry_utils.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/painter/paint_delegate.dart';

/// 도형(선, 원, 다각형 등) 렌더링을 담당하는 Delegate
class ShapePaintDelegate implements PaintDelegate {
  /// 렌더링할 도형 스트로크 목록
  final List<Stroke> strokes;

  const ShapePaintDelegate({required this.strokes});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.options.size
        ..strokeCap = .round
        ..strokeJoin = .round
        ..style = .stroke;
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
      case "rectangle":
      case "square":
        // 결정적 사각형: 세그먼트 없이 2점(bounding-box) → drawRect.
        // 자동 인식 사각형(세그먼트 보유)은 기존 폴리곤 렌더.
        if (stroke.segments.isEmpty && stroke.points.length == 2) {
          _drawRect(canvas, paint, stroke);
        } else if (stroke.segments.isNotEmpty) {
          _drawPolygon(canvas, paint, stroke);
        }
        break;
      case "circle":
      case "ellipse":
        // 결정적 타원: 2점(bounding-box) → drawOval.
        // 자동 인식 타원(다점)은 PCA 기반 렌더.
        if (stroke.points.length == 2) {
          _drawOvalFromBounds(canvas, paint, stroke);
        } else {
          _drawCircle(canvas, paint, stroke);
        }
        break;
      case "polyline":
        _drawPolyline(canvas, paint, stroke);
      default:
        if (stroke.segments.isNotEmpty) {
          _drawPolygon(canvas, paint, stroke);
        }
        break;
    }
  }

  /// 2점(bounding-box) 사각형 그리기 — 결정적 도형 도구용.
  void _drawRect(ui.Canvas canvas, Paint paint, Stroke stroke) {
    final start = stroke.points.first;
    final end = stroke.points.last;
    canvas.drawRect(
      Rect.fromPoints(Offset(start.x, start.y), Offset(end.x, end.y)),
      paint,
    );
  }

  /// 2점(bounding-box) 타원 그리기 — 결정적 도형 도구용.
  void _drawOvalFromBounds(ui.Canvas canvas, Paint paint, Stroke stroke) {
    final start = stroke.points.first;
    final end = stroke.points.last;
    canvas.drawOval(
      Rect.fromPoints(Offset(start.x, start.y), Offset(end.x, end.y)),
      paint,
    );
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
      center: .zero,
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
      // 세그먼트는 닫힌 링(마지막 end == 첫 start)으로 생성되므로
      // 각 세그먼트의 end를 따라가면 폐곡선이 완성된다.
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
      path.lineTo(points[0].x, points[0].y);
    }

    canvas.drawPath(path, paint);
  }

  /// 폴리라인(열린 선분 연결) 그리기
  void _drawPolyline(ui.Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.isEmpty) return;

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

    canvas.drawPath(path, paint);
  }
}
