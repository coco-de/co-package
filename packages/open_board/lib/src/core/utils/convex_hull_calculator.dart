import 'dart:math' as math;
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'geometry_utils.dart';

/// 컨벡스 헐(Convex Hull) 계산을 담당하는 클래스
class ConvexHullCalculator {
  const ConvexHullCalculator._();

  /// 컨벡스 헐(Convex Hull) 계산 - Graham Scan 알고리즘
  static List<Point> calculateConvexHull(List<Point> points) {
    if (points.length < 3) return List<Point>.of(points);

    // 1. y값이 가장 작은 점 찾기 (y값이 같다면 x값이 작은 것)
    Point pivot = _findPivotPoint(points);

    // 2. 기준점 기준으로 다른 점들을 각도 순으로 정렬
    final sortedPoints = _sortPointsByAngle(points, pivot);

    // 중복 제거
    final filteredPoints = _removeDuplicateAngles(sortedPoints, pivot);

    // 점이 2개 이하면 convex hull을 만들 수 없음
    if (filteredPoints.length <= 2) {
      return [pivot, ...filteredPoints];
    }

    // 3. Graham Scan 수행
    return _performGrahamScan(pivot, filteredPoints);
  }

  /// 가장 아래 있는 점 찾기 (피봇 포인트)
  static Point _findPivotPoint(List<Point> points) {
    Point pivot = points[0];
    for (int i = 1; i < points.length; i++) {
      if (points[i].y < pivot.y ||
          (points[i].y == pivot.y && points[i].x < pivot.x)) {
        pivot = points[i];
      }
    }
    return pivot;
  }

  /// 각도 기준으로 점들 정렬
  static List<Point> _sortPointsByAngle(List<Point> points, Point pivot) {
    final sortedPoints = <Point>[];
    for (final point in points) {
      if (point != pivot) {
        sortedPoints.add(point);
      }
    }

    sortedPoints.sort((a, b) {
      double angleA = math.atan2(a.y - pivot.y, a.x - pivot.x);
      double angleB = math.atan2(b.y - pivot.y, b.x - pivot.x);

      if (angleA == angleB) {
        // 같은 각도면 거리가 더 가까운 점이 먼저
        return GeometryUtils.calculateDistance(
          pivot,
          a,
        ).compareTo(GeometryUtils.calculateDistance(pivot, b));
      }

      return angleA.compareTo(angleB);
    });

    return sortedPoints;
  }

  /// 중복 각도 제거
  static List<Point> _removeDuplicateAngles(
    List<Point> sortedPoints,
    Point pivot,
  ) {
    if (sortedPoints.isEmpty) return [];

    int k = 0;
    for (int i = 0; i < sortedPoints.length; i++) {
      // 각도가 같으면 가장 먼 점만 유지
      // (정렬이 동일각 시 가까운 점 우선이므로 그룹 끝까지 전진 후 현재 점을
      //  보존한다. i-1을 보존하면 마지막 극점이 항상 탈락하고 동일각 그룹에서
      //  가까운 점이 남아 잘못된 헐이 만들어진다)
      while (i < sortedPoints.length - 1 &&
          GeometryUtils.calculateOrientation(
                pivot,
                sortedPoints[i],
                sortedPoints[i + 1],
              ) ==
              0) {
        i++;
      }
      sortedPoints[k++] = sortedPoints[i];
    }

    // 실제 정렬된 점 배열 크기 조정
    sortedPoints.length = k;
    return sortedPoints;
  }

  /// Graham Scan 수행
  static List<Point> _performGrahamScan(
    Point pivot,
    List<Point> sortedPoints,
  ) {
    final hull = [pivot, sortedPoints[0], sortedPoints[1]];

    for (int i = 2; i < sortedPoints.length; i++) {
      while (hull.length > 1 &&
          GeometryUtils.calculateOrientation(
                hull[hull.length - 2],
                hull[hull.length - 1],
                sortedPoints[i],
              ) !=
              2) {
        hull.removeLast();
      }
      hull.add(sortedPoints[i]);
    }

    return hull;
  }
}
