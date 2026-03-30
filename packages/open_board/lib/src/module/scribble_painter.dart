// 🎯 Dart imports:
// ignore_for_file: unused_element

import 'dart:math' as math;
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
  ScribblePainter({
    required this.state,
    required this.modeState,
    required this.drawPointer,
    required this.drawEraser,
    required this.pressureFactor,
    required this.speedFactor,
    required this.minWidthFactor,
    this.repaint,
    this.background,
    this.isActiveLine = false,
    this.activeHandle = HandlePosition.none,
    this.selectedStrokeIds = const [],
    this.showLassoOverlay = false,
    this.lassoSelectionState,
    this.onLassoDelete,
    this.onLassoTransformStart,
    this.onLassoTransformUpdate,
    this.onLassoTransformEnd,
    this.onLassoMoveStart,
    this.onLassoMoveUpdate,
    this.onLassoMoveEnd,
  }) : super(repaint: repaint);
  final Listenable? repaint;
  final ui.Image? background;

  final double pressureFactor;
  final double speedFactor;
  final double minWidthFactor;

  final ScribbleState state;
  final ScribbleModeState modeState;
  final bool drawPointer;
  final bool drawEraser;
  final bool isActiveLine;
  final List<int> selectedStrokeIds;
  final bool showLassoOverlay;
  final LassoSelectionState? lassoSelectionState;

  // 올가미 오버레이 콜백 함수들
  final VoidCallback? onLassoDelete;
  final void Function(DragStartDetails)? onLassoTransformStart;
  final void Function(DragUpdateDetails)? onLassoTransformUpdate;
  final void Function(DragEndDetails)? onLassoTransformEnd;
  final void Function(DragStartDetails)? onLassoMoveStart;
  final void Function(DragUpdateDetails)? onLassoMoveUpdate;
  final void Function(DragEndDetails)? onLassoMoveEnd;

  final HandlePosition activeHandle;

  var vertices = <Offset>[];
  List<Stroke> get lines => state.lines;

  // 폐곡선 인식 임계값 (시작점과 끝점 사이 거리가 둘레의 15% 미만이면 폐곡선)
  final double _closedThreshold = 0.15;

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

      final strokeDelegate = StrokePaintDelegate(strokes: []);
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
    final strokeDelegate = StrokePaintDelegate(strokes: []);
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

  // ──────────────────────────────────────────────────────────
  // 아래는 도형 감지/수학 유틸리티 메서드들 (기존 호환성 유지)
  // ──────────────────────────────────────────────────────────

  /// 세 점 사이의 각도를 계산 (degrees)
  double _cornerAngle(Point prev, Point mid, Point next) {
    final v1x = prev.x - mid.x;
    final v1y = prev.y - mid.y;
    final v2x = next.x - mid.x;
    final v2y = next.y - mid.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);

    if (mag1 * mag2 == 0) return 180.0;

    double cosAngle = dot / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    final angleRad = math.acos(cosAngle);
    return angleRad * 180 / math.pi;
  }

  /// 모서리(코너) 감지
  List<int> _detectCorners(List<Point> points, {double minAngle = 60.0}) {
    if (points.length < 3) return [];

    final List<int> cornerIndices = [];
    final int n = points.length;

    for (int i = 1; i < n - 1; i++) {
      double angle = _cornerAngle(points[i - 1], points[i], points[i + 1]);
      if (angle < minAngle) {
        cornerIndices.add(i);
        i += 1;
      }
    }

    if (n > 3) {
      double angleStart = _cornerAngle(points[n - 2], points[n - 1], points[0]);
      double angleEnd = _cornerAngle(points[n - 1], points[0], points[1]);

      if (angleStart < minAngle) cornerIndices.add(n - 1);
      if (angleEnd < minAngle) cornerIndices.add(0);
    }

    return cornerIndices.toSet().toList()..sort();
  }

  /// 내각 계산 (라디안)
  double _calculateInteriorAngle(Point a, Point b, Point c) {
    final v1x = a.x - b.x;
    final v1y = a.y - b.y;
    final v2x = c.x - b.x;
    final v2y = c.y - b.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);

    if (mag1 * mag2 == 0) return 0.0;

    double cosAngle = dot / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    return math.acos(cosAngle);
  }

  /// 중심점 계산
  Point _calculateCentroid(List<Point> points) {
    if (points.isEmpty) return Point(x: 0, y: 0);

    double sumX = 0, sumY = 0;
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
    }
    return Point(x: sumX / points.length, y: sumY / points.length);
  }

  /// 두 점 사이의 거리 계산
  double _calculateDistance(Point p1, Point p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 폐곡선 여부 확인
  bool _isClosedShape(List<Point> points, double perimeter) {
    if (points.length < 3) return false;

    final firstLastDistance = _calculateDistance(points.first, points.last);
    return firstLastDistance < perimeter * _closedThreshold;
  }

  /// 별 모양 감지
  bool _detectStarShape(List<Point> points, Point centroid) {
    if (points.length < 5) return false;

    List<Point> convexHull = _calculateConvexHull(points);

    double originalArea = _calculatePolygonArea(points);
    double convexHullArea = _calculatePolygonArea(convexHull);

    if (convexHullArea <= 0) return false;
    double areaRatio = originalArea / convexHullArea;

    final cornerIndices = _detectCorners(points, minAngle: 45.0);

    return (areaRatio >= 0.3 && areaRatio <= 0.7) &&
        (cornerIndices.length >= 5 && cornerIndices.length <= 10);
  }

  /// 다각형 면적 계산 (Shoelace 공식)
  double _calculatePolygonArea(List<Point> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      area += (points[j].x + points[i].x) * (points[j].y - points[i].y);
      j = i;
    }

    return area.abs() / 2.0;
  }

  /// Convex Hull 계산 (Graham Scan)
  List<Point> _calculateConvexHull(List<Point> points) {
    if (points.length < 3) return List.from(points);

    Point pivot = points[0];
    for (int i = 1; i < points.length; i++) {
      if (points[i].y < pivot.y ||
          (points[i].y == pivot.y && points[i].x < pivot.x)) {
        pivot = points[i];
      }
    }

    final sortedPoints = List<Point>.from(points);
    sortedPoints.remove(pivot);
    sortedPoints.sort((a, b) {
      double angleA = math.atan2(a.y - pivot.y, a.x - pivot.x);
      double angleB = math.atan2(b.y - pivot.y, b.x - pivot.x);

      if (angleA == angleB) {
        double distA =
            (a.x - pivot.x) * (a.x - pivot.x) +
            (a.y - pivot.y) * (a.y - pivot.y);
        double distB =
            (b.x - pivot.x) * (b.x - pivot.x) +
            (b.y - pivot.y) * (b.y - pivot.y);
        return distA.compareTo(distB);
      }

      return angleA.compareTo(angleB);
    });

    List<Point> hull = [pivot];
    if (sortedPoints.isNotEmpty) {
      hull.add(sortedPoints[0]);
    }

    for (int i = 1; i < sortedPoints.length; i++) {
      while (hull.length > 1 &&
          !_isCounterClockwise(
            hull[hull.length - 2],
            hull[hull.length - 1],
            sortedPoints[i],
          )) {
        hull.removeLast();
      }
      hull.add(sortedPoints[i]);
    }

    return hull;
  }

  bool _isCounterClockwise(Point a, Point b, Point c) {
    return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) > 0;
  }

  /// Douglas-Peucker 점 단순화
  List<Point> _simplifyPoints(List<Point> points, double epsilon) {
    if (points.length <= 2) return List.from(points);

    final Point start = points.first;
    final Point end = points.last;

    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance > epsilon) {
      final List<Point> firstPart = _simplifyPoints(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      final List<Point> secondPart = _simplifyPoints(
        points.sublist(maxIndex),
        epsilon,
      );

      return [...firstPart.sublist(0, firstPart.length - 1), ...secondPart];
    } else {
      return [start, end];
    }
  }

  /// 점과 직선 사이의 수직 거리
  double _perpendicularDistance(Point point, Point lineStart, Point lineEnd) {
    final double dx = lineEnd.x - lineStart.x;
    final double dy = lineEnd.y - lineStart.y;
    final double lineLengthSquared = dx * dx + dy * dy;

    if (lineLengthSquared == 0) {
      return _calculateDistance(point, lineStart);
    }

    final double t =
        ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) /
        lineLengthSquared;

    double projX, projY;
    if (t < 0) {
      projX = lineStart.x;
      projY = lineStart.y;
    } else if (t > 1) {
      projX = lineEnd.x;
      projY = lineEnd.y;
    } else {
      projX = lineStart.x + t * dx;
      projY = lineStart.y + t * dy;
    }

    final double distX = point.x - projX;
    final double distY = point.y - projY;
    return math.sqrt(distX * distX + distY * distY);
  }

  /// 점 회전
  Point _rotatePoint(
    double x,
    double y,
    double cosTheta,
    double sinTheta,
    Point center,
  ) {
    final rotatedX = x * cosTheta - y * sinTheta + center.x;
    final rotatedY = x * sinTheta + y * cosTheta + center.y;
    return Point(x: rotatedX, y: rotatedY);
  }

  /// 둘레 길이 계산
  double _calculatePerimeter(List<Point> points) {
    if (points.length < 2) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      perimeter += _calculateDistance(points[i], points[i + 1]);
    }

    perimeter += _calculateDistance(points.first, points.last);

    return perimeter;
  }

  /// 직진성 평가
  double _evaluateLinearity(List<Point> points) {
    if (points.length < 3) return 1.0;

    final first = points.first;
    final last = points.last;

    final dx = last.x - first.x;
    final dy = last.y - first.y;
    final lineLength = math.sqrt(dx * dx + dy * dy);

    if (lineLength < 0.001) return 0.0;

    final unitDx = dx / lineLength;
    final unitDy = dy / lineLength;

    double totalDeviation = 0.0;
    double maxDeviation = 0.0;

    for (int i = 1; i < points.length - 1; i++) {
      final p = points[i];

      final t =
          ((p.x - first.x) * unitDx + (p.y - first.y) * unitDy) / lineLength;

      double distance;
      if (t < 0) {
        distance = math.sqrt(
          (p.x - first.x) * (p.x - first.x) + (p.y - first.y) * (p.y - first.y),
        );
      } else if (t > 1) {
        distance = math.sqrt(
          (p.x - last.x) * (p.x - last.x) + (p.y - last.y) * (p.y - last.y),
        );
      } else {
        final projX = first.x + t * lineLength * unitDx;
        final projY = first.y + t * lineLength * unitDy;

        distance = math.sqrt(
          (p.x - projX) * (p.x - projX) + (p.y - projY) * (p.y - projY),
        );
      }

      totalDeviation += distance;
      maxDeviation = math.max(maxDeviation, distance);
    }

    final avgDeviation = totalDeviation / (points.length - 2);

    final relativeTotalDeviation = avgDeviation / lineLength;
    final relativeMaxDeviation = maxDeviation / lineLength;

    double linearityScore =
        1.0 -
        math.min(
          1.0,
          math.max(relativeTotalDeviation * 2, relativeMaxDeviation),
        );

    return linearityScore;
  }
}
