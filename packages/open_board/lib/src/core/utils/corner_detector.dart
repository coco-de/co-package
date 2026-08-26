import 'dart:math' as math;

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'geometry_utils.dart';
import 'convex_hull_calculator.dart';

/// 거리 정보를 가진 포인트 클래스 (헬퍼)
class _PointWithDistance {
  final Point point;
  final double distance;

  const _PointWithDistance(this.point, this.distance);
}

/// 코너 감지를 담당하는 클래스
class CornerDetector {
  const CornerDetector._();

  /// 중요한 코너점 감지 - 각도 기반 단순 접근법
  ///
  /// 손으로 그린 모서리는 완벽한 꺾임 1점이 아니라 둥글게 말리거나
  /// 손떨림으로 흔들린 짧은 곡선 구간으로 나타난다. 그 구간 안의 점들은
  /// 각각 독립적으로 [cornerAngleThreshold] 미만일 수 있어, 예전 구현처럼
  /// 문턱을 넘는 점을 전부 코너로 세면 물리적으로 하나인 모서리가 여러
  /// 코너로 쪼개져 사각형이 오각형·육각형으로 오분류됐다(UB-555). 그래서
  /// 문턱을 넘는 점들을 인접한 "구간(run)"으로 묶고, 각 구간에서 각도가
  /// 가장 작은(가장 뾰족한) 점 하나만 그 모서리의 대표 코너로 채택한다.
  ///
  /// [minDistanceThreshold] 는 "같은 모서리" 로 묶어 대표 코너 하나만 남길
  /// 거리 기준이다. 도형 크기에 비례해 호출측(ShapeDetector)이 넘겨줄 수
  /// 있도록 파라미터화했고, 기본값 10px는 기존 동작(고정 픽셀 기준)을
  /// 그대로 보존한다.
  static List<Point> detectSignificantCorners(
    List<Point> points, {
    double minDistanceThreshold = 10.0,
  }) {
    if (points.length < 3) return List.of(points);

    // 각도 임계값 - 꺾임 각도가 이 값보다 작으면 코너로 인식
    const cornerAngleThreshold = 120.0;

    // 1) 문턱 미만인 후보 인덱스와 각도를 전부 수집한다.
    final candidateAngles = <int, double>{};
    for (int i = 1; i < points.length - 1; i++) {
      final angle = GeometryUtils.calculateCornerAngle(
        points[i - 1],
        points[i],
        points[i + 1],
      );
      if (angle < cornerAngleThreshold) {
        candidateAngles[i] = angle;
      }
    }
    final candidateIndices = candidateAngles.keys.toList()..sort();

    // 코너 후보 목록 (시작점은 항상 포함)
    final corners = [points.first];

    // 2) 서로 가까운(= 물리적으로 같은 모서리일 가능성이 높은) 후보를 하나의
    // 구간으로 묶어, 그 구간에서 가장 뾰족한 점만 대표 코너로 채택한다.
    // 단순화(Douglas-Peucker) 이후에는 인접 인덱스라도 서로 다른 진짜
    // 코너를 가리킬 수 있으므로(예: 사각형의 변 하나를 사이에 둔 두 꼭짓점),
    // 인덱스 인접성이 아니라 **점 사이 거리**로 같은 모서리 여부를 판단한다.
    int runStart = 0;
    while (runStart < candidateIndices.length) {
      int runEnd = runStart;
      while (runEnd + 1 < candidateIndices.length &&
          GeometryUtils.calculateDistance(
                points[candidateIndices[runEnd]],
                points[candidateIndices[runEnd + 1]],
              ) <
              minDistanceThreshold) {
        runEnd++;
      }

      int sharpestIndex = candidateIndices[runStart];
      double sharpestAngle = candidateAngles[sharpestIndex]!;
      for (int k = runStart + 1; k <= runEnd; k++) {
        final idx = candidateIndices[k];
        final angle = candidateAngles[idx]!;
        if (angle < sharpestAngle) {
          sharpestAngle = angle;
          sharpestIndex = idx;
        }
      }

      final curr = points[sharpestIndex];
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

      runStart = runEnd + 1;
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
    } // 삼각형이 아니면 균등 간격으로 코너 생성
    if (simplifiedPoints.length >= 5) {
      corners.add(simplifiedPoints[0]);
      corners.add(simplifiedPoints[simplifiedPoints.length ~/ 2]);
      corners.add(simplifiedPoints[simplifiedPoints.length * 2 ~/ 3]);
    } else {
      // 포인트가 적으면 모든 포인트를 코너로 사용
      corners.addAll(simplifiedPoints);
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
    if (points.length <= 3) return List.of(points);

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
      final angleA = math.atan2(
        a.y - resultCentroid.y,
        a.x - resultCentroid.x,
      );
      final angleB = math.atan2(
        b.y - resultCentroid.y,
        b.x - resultCentroid.x,
      );
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
