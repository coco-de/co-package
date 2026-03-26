import 'dart:math' as math;

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'geometry_utils.dart';
import 'convex_hull_calculator.dart';

/// 거리 정보를 가진 포인트 클래스 (헬퍼)
class _PointWithDistance {
  final Point point;
  final double distance;

  _PointWithDistance(this.point, this.distance);
}

/// 코너 감지를 담당하는 클래스
class CornerDetector {
  CornerDetector._();

  /// 중요한 코너점 감지 - 각도 기반 단순 접근법
  static List<Point> detectSignificantCorners(List<Point> points) {
    if (points.length < 3) return List.from(points);

    // 각도 임계값 - 꺾임 각도가 이 값보다 작으면 코너로 인식
    const cornerAngleThreshold = 120.0;

    // 최소 거리 임계값 - 너무 가까운 코너는 제거
    const minDistanceThreshold = 10.0;

    // 코너 후보 목록 (시작점은 항상 포함)
    final corners = <Point>[points.first];

    // 중간 점들에서 코너 탐색
    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      // 각도 계산
      final angle = GeometryUtils.calculateCornerAngle(prev, curr, next);

      // 꺾임이 크면 코너로 간주
      if (angle < cornerAngleThreshold) {
        // 이전 코너와의 거리 확인
        bool isTooClose = false;
        for (final corner in corners) {
          if (GeometryUtils.calculateDistance(curr, corner) <
              minDistanceThreshold) {
            isTooClose = true;
            break;
          }
        }

        if (!isTooClose) {
          corners.add(curr);
        }
      }
    }

    // 마지막 점 추가 (이전 코너와 충분히 떨어져 있으면)
    final lastPoint = points.last;
    bool isTooClose = false;

    for (final corner in corners) {
      if (GeometryUtils.calculateDistance(lastPoint, corner) <
          minDistanceThreshold) {
        isTooClose = true;
        break;
      }
    }

    if (!isTooClose && corners.isNotEmpty) {
      corners.add(lastPoint);
    }

    // 코너가 너무 적거나 없으면 시작, 중간, 끝 점 사용
    if (corners.length < 2 && points.length >= 3) {
      corners.clear();
      corners.add(points.first);

      // 중간 지점
      final middleIdx = points.length ~/ 2;
      corners.add(points[middleIdx]);

      // 마지막 점
      corners.add(points.last);
    }

    return corners;
  }

  /// 코너 감지 - 작은 움직임은 무시하도록 개선된 버전
  static bool isSignificantCorner(
    Point prev,
    Point curr,
    Point next,
    double minDistance,
    double angleThreshold,
  ) {
    // 1. 이전 점과 현재 점, 현재 점과 다음 점 사이의 거리 확인
    final prevDist = GeometryUtils.calculateDistance(prev, curr);
    final nextDist = GeometryUtils.calculateDistance(curr, next);

    // 두 거리 중 하나라도 최소 거리보다 작으면 코너로 인식하지 않음
    if (prevDist < minDistance || nextDist < minDistance) {
      return false;
    }

    // 2. 각도 기반 코너 감지
    final angle = GeometryUtils.calculateCornerAngle(prev, curr, next);

    // 3. 각도와 거리를 함께 고려한 코너 감지
    // 거리가 작을수록 요구되는 각도가 더 작아져야 함 (더 뾰족해야 함)
    final distFactor = math.min(prevDist, nextDist) / minDistance;
    final adjustedThreshold =
        angleThreshold * (0.5 + 0.5 * math.min(distFactor, 2.0) / 2.0);

    return angle < adjustedThreshold;
  }

  /// 특정 인덱스의 점이 유의미한 코너인지 확인
  static bool isSignificantPoint(
    List<Point> points,
    int index,
    double minDistance,
  ) {
    if (points.length < 3) return true;
    if (index <= 0 || index >= points.length - 1) {
      // 첫 점이나 끝 점인 경우, 인접점과의 거리를 확인
      final point = points[index];
      final neighbor = (index == 0) ? points[1] : points[index - 1];
      return GeometryUtils.calculateDistance(point, neighbor) >= minDistance;
    }

    // 중간 점인 경우, 이전/다음 점과의 각도와 거리 확인
    final prev = points[index - 1];
    final curr = points[index];
    final next = points[index + 1];

    // 거리가 충분히 멀고, 각도가 작을수록(꺾임이 클수록) 유의미한 코너
    final prevDist = GeometryUtils.calculateDistance(prev, curr);
    final nextDist = GeometryUtils.calculateDistance(curr, next);

    if (prevDist < minDistance || nextDist < minDistance) {
      return false;
    }

    final angle = GeometryUtils.calculateCornerAngle(prev, curr, next);
    return angle < 120; // 120도보다 작으면 유의미한 꺾임으로 간주
  }

  /// 가까운 코너들을 병합
  static List<Point> mergeCloseCorners(
    List<Point> corners,
    double minDistance,
  ) {
    if (corners.length <= 3) return corners;

    final result = <Point>[];
    final visited = List<bool>.filled(corners.length, false);

    for (int i = 0; i < corners.length; i++) {
      if (visited[i]) continue;

      // 현재 코너와 가까운 다른 코너들 찾기
      final cluster = <Point>[corners[i]];
      visited[i] = true;

      for (int j = i + 1; j < corners.length; j++) {
        if (!visited[j] &&
            GeometryUtils.calculateDistance(corners[i], corners[j]) <
                minDistance) {
          cluster.add(corners[j]);
          visited[j] = true;
        }
      }

      // 클러스터의 중심점 계산 (병합된 코너)
      if (cluster.length > 1) {
        double sumX = 0, sumY = 0;
        for (final p in cluster) {
          sumX += p.x;
          sumY += p.y;
        }
        result.add(Point(x: sumX / cluster.length, y: sumY / cluster.length));
      } else {
        result.add(cluster[0]);
      }
    }

    return result;
  }

  /// 폐곡선이지만 코너가 부족할 때 코너 생성
  static List<Point> generateCornersForClosedShape(
    List<Point> simplifiedPoints,
  ) {
    if (simplifiedPoints.length < 3) return simplifiedPoints;

    final corners = <Point>[];

    // 삼각형 특성 먼저 평가
    final isTriangle = evaluateTriangleShape(simplifiedPoints) > 0.6;

    if (isTriangle) {
      // 삼각형으로 판단되면 삼각형에 최적화된 3개 코너 찾기
      return findBestTriangleCorners(simplifiedPoints);
    } else {
      // 삼각형이 아니면 균등 간격으로 코너 생성
      if (simplifiedPoints.length >= 5) {
        corners.add(simplifiedPoints[0]);
        corners.add(simplifiedPoints[simplifiedPoints.length ~/ 2]);
        corners.add(simplifiedPoints[simplifiedPoints.length * 2 ~/ 3]);
      } else {
        // 포인트가 적으면 모든 포인트를 코너로 사용
        corners.addAll(simplifiedPoints);
      }
    }

    return corners;
  }

  /// 삼각형 형태 평가 - 도형이 삼각형에 얼마나 가까운지 평가
  static double evaluateTriangleShape(List<Point> points) {
    if (points.length < 3) return 0.0;

    // 컨벡스 헐 계산
    final hull = ConvexHullCalculator.calculateConvexHull(points);

    // 컨벡스 헐이 3개 또는 4개면 삼각형일 가능성이 높음
    if (hull.length < 3 || hull.length > 5) return 0.0;

    // 최적의 삼각형 코너 3개 찾기
    final bestCorners = findBestTriangleCorners(points);

    return _calculateTriangleScore(bestCorners);
  }

  /// 최적의 삼각형 코너 3개 찾기
  static List<Point> findBestTriangleCorners(List<Point> points) {
    if (points.length <= 3) return List.from(points);

    // 컨벡스 헐에서 가장 멀리 떨어진 3개 점 찾기
    final hull = ConvexHullCalculator.calculateConvexHull(points);

    // 헐 포인트가 3개 이하면 그대로 사용
    if (hull.length <= 3) return hull;

    // 헐 포인트가 4개 이상이면 가장 중요한 3개 코너 선택
    final centroid = GeometryUtils.calculateCentroid(hull);
    final pointsWithDistance = <_PointWithDistance>[];

    // 모든 헐 포인트에 대해 중심점으로부터의 거리 계산
    for (final point in hull) {
      final distance = GeometryUtils.calculateDistance(centroid, point);
      pointsWithDistance.add(_PointWithDistance(point, distance));
    }

    // 거리에 따라 정렬 (가장 먼 포인트들이 중요한 코너일 가능성 높음)
    pointsWithDistance.sort((a, b) => b.distance.compareTo(a.distance));

    // 가장 먼 3개 포인트 선택
    final result = <Point>[];
    for (int i = 0; i < math.min(3, pointsWithDistance.length); i++) {
      result.add(pointsWithDistance[i].point);
    }

    // 시계 방향으로 정렬
    final resultCentroid = GeometryUtils.calculateCentroid(result);
    result.sort((a, b) {
      final angleA = math.atan2(a.y - resultCentroid.y, a.x - resultCentroid.x);
      final angleB = math.atan2(b.y - resultCentroid.y, b.x - resultCentroid.x);
      return angleA.compareTo(angleB);
    });

    return result;
  }

  /// 삼각형 점수 계산
  static double _calculateTriangleScore(List<Point> corners) {
    if (corners.length != 3) return 0.0;

    // 삼각형의 내각 계산 (이상적인 삼각형은 내각 합이 180도)
    final angle1 = GeometryUtils.calculateCornerAngle(
      corners[2],
      corners[0],
      corners[1],
    );
    final angle2 = GeometryUtils.calculateCornerAngle(
      corners[0],
      corners[1],
      corners[2],
    );
    final angle3 = GeometryUtils.calculateCornerAngle(
      corners[1],
      corners[2],
      corners[0],
    );

    final angleSum = angle1 + angle2 + angle3;
    final angleDiff = (angleSum - 180.0).abs();

    // 각도가 너무 극단적인지 확인 (너무 뾰족하거나 너무 둔한 각이 있으면 감점)
    bool hasExtremeAngle = false;
    if (angle1 < 15 || angle1 > 150) hasExtremeAngle = true;
    if (angle2 < 15 || angle2 > 150) hasExtremeAngle = true;
    if (angle3 < 15 || angle3 > 150) hasExtremeAngle = true;

    // 변의 길이 계산 및 비율 계산
    final side1 = GeometryUtils.calculateDistance(corners[0], corners[1]);
    final side2 = GeometryUtils.calculateDistance(corners[1], corners[2]);
    final side3 = GeometryUtils.calculateDistance(corners[2], corners[0]);

    final minSide = math.min(math.min(side1, side2), side3);
    final maxSide = math.max(math.max(side1, side2), side3);
    final sideRatio = minSide / maxSide;

    // 점수 계산 (1.0이 가장 이상적인 삼각형)
    double score = 1.0;

    // 각도 합이 180도에서 많이 벗어나면 감점
    if (angleDiff > 10) {
      score -= math.min(angleDiff / 40.0, 0.4);
    }

    // 극단적 각도가 있으면 감점
    if (hasExtremeAngle) {
      score -= 0.3;
    }

    // 변 길이 비율이 너무 차이나면 감점
    if (sideRatio < 0.3) {
      score -= (0.3 - sideRatio) * 0.6;
    }

    return math.max(0.0, math.min(1.0, score));
  }
}
