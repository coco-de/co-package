// 🎯 Dart imports:
import 'dart:math';

class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}

class DouglasPeucker {
  /// 폴리라인 단순화는 더글러스-피커와 방사형 거리 알고리즘의 조합을 사용합니다.
  ///
  /// [points]
  /// [tolerance] 이중 허용오차 단순화 정도에 영향을 줍니다(포인트 좌표와 동일한 메트릭).
  static List<Point> simplify(
    List<Point> points, {
    required double tolerance,
  }) {
    if (points.length < 2) {
      return points;
    }

    final sqTolerance = pow(tolerance, 2).toDouble();

    points = simplifyRadialDistance(points, sqTolerance);

    points = simplifyDouglasPeucker(points, sqTolerance);

    return points;
  }

  /// 기본 거리 기반 단순화
  static List<Point> simplifyRadialDistance(
    List<Point> points,
    double sqTolerance,
  ) {
    if (points.length < 2) {
      return points;
    }

    var prevPoint = points.first;
    final newPoints = [prevPoint];
    late Point currentPoint;

    for (Point iPoint in points) {
      currentPoint = iPoint;
      if (getSquareDistance(currentPoint, prevPoint) > sqTolerance) {
        newPoints.add(currentPoint);
        prevPoint = currentPoint;
      }
    }

    if (prevPoint.x != currentPoint.x && prevPoint.y != currentPoint.y) {
      newPoints.add(currentPoint);
    }

    return newPoints;
  }

  /// 두 점 사이의 제곱 거리
  static double getSquareDistance(Point p1, Point p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return pow(dx, 2).toDouble() + pow(dy, 2).toDouble();
  }

  /// 점으로부터 세그먼트까지의 제곱 거리
  static double getSquareSegmentDistance(Point p, Point p1, Point p2) {
    var x = p1.x;
    var y = p1.y;
    var dx = p2.x - x;
    var dy = p2.y - y;
    if (dx != 0 || dy != 0) {
      final t = ((p.x - x) * dx + (p.y - y) * dy) / (dx * dx + dy * dy);
      if (t > 1) {
        x = p2.x;
        y = p2.y;
      } else if (t > 0) {
        x += dx * t;
        y += dy * t;
      }
    }
    dx = p.x - x;
    dy = p.y - y;
    return dx * dx + dy * dy;
  }

  static void simplifyDouglasPeuckerStep(
    List<Point> points,
    int first,
    int last,
    double sqTolerance,
    List<Point> simplified,
  ) {
    var maxSqDist = sqTolerance;
    var index = 0;

    for (int i = first + 1; i < last; i++) {
      var sqDist = getSquareSegmentDistance(
        points[i],
        points[first],
        points[last],
      );

      if (sqDist > maxSqDist) {
        index = i;
        maxSqDist = sqDist;
      }
    }

    if (maxSqDist > sqTolerance) {
      if (index - first > 1) {
        simplifyDouglasPeuckerStep(
          points,
          first,
          index,
          sqTolerance,
          simplified,
        );
      }
      simplified.add(points[index]);
      if (last - index > 1) {
        simplifyDouglasPeuckerStep(
          points,
          index,
          last,
          sqTolerance,
          simplified,
        );
      }
    }
  }

  // Ramer-Douglas-Peucker 알고리즘을 이용한 단순화
  static List<Point> simplifyDouglasPeucker(
    List<Point> points,
    double sqTolerance,
  ) {
    final last = points.length - 1;
    final simplified = [points.first];
    simplifyDouglasPeuckerStep(points, 0, last, sqTolerance, simplified);
    simplified.add(points[last]);

    return simplified;
  }
}
