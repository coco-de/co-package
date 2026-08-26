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
  ///
  /// [allowFewCornerFallback]가 true(기본값, 기존 동작)면 문턱을 넘는 후보가
  /// 1개 이하로 발견됐을 때 시작/중간/끝 3점으로 채워 넣는 폴백을 적용한다.
  /// 이 폴백은 원래 "다각형을 못 그려도 뭔가는 그린다"는 최후 수단이지,
  /// "이 3점이 진짜 다각형 코너다"라는 신호가 아니다. 매끄러운 원이나
  /// 타원처럼 각진 후보가 전혀 없는 도형에서도 항상 정확히 3점을
  /// 만들어내므로, 호출측이 "이 코너 수가 원이 아니라 다각형이라는 근거로
  /// 신뢰할 만한가"를 판단해야 하는 자리(예: 원 판정보다 먼저 도는 관문,
  /// `ShapeDetector._tryPolygonVetoBeforeCircle`)에서 false로 꺼서 폴백
  /// 이전의 원본 코너 수(0~1개)를 그대로 받을 수 있다(UB-555 2차).
  ///
  /// ⚠️ 시작점은 [allowFewCornerFallback] 과 무관하게 **항상** 코너 후보에
  /// 포함된다(아래 "코너 후보 목록" 참조) — 순수 각도 기반 순환 판정으로
  /// 대체하면(예: 이전에 시도한 `cornerClusterPoints`), 손그림이 시작/끝나는
  /// 지점의 코너가 Douglas-Peucker 단순화로 두 점에 걸쳐 나뉘어 각 점의
  /// 국소 각도가 개별적으로는 문턱을 넘지 못하는 경우(둘레의 이음매에서만
  /// 발생) 그 코너 자체를 통째로 놓친다 — 실측: 라운딩 16% 사각형 하나가
  /// 코너 3개(진짜 4개 중 1개 누락)로 잡혀 rightTriangle 로 오분류됐다.
  /// 시작점 강제 포함은 이 놓침을 막는 안전장치이지 제거 대상이 아니다.
  ///
  /// ⭐ [angleWindowDistance] (UB-555 3차, "넓은 윈도우 각도 추정") — 후보
  /// 각도를 **바로 이웃한 점**(`i-1, i, i+1`)이 아니라, `i` 로부터 둘레
  /// 거리 기준으로 [angleWindowDistance]만큼 떨어진 두 점(`i-k, i, i+k`,
  /// `k`는 점 간격에 따라 동적으로 정해짐)으로 계산한다.
  /// [handDrawnRectanglePoints]/[handDrawnTrianglePoints] 등이 만드는
  /// 손떨림은 **점마다 독립적으로 가해지는 무작위 오프셋**이라, 좁은
  /// 윈도우(바로 이웃 1점)에서는 그 오프셋 자체가 방향을 반전시켜 120도
  /// 문턱을 쉽게 넘는다. 윈도우를 넓히면 "신호"(변을 따라 실제로 누적된
  /// 방향 변화)의 크기(≈windowDistance)가 "잡음"(개별 점의 오프셋 크기,
  /// 최대 `side*jitterRatio`)에 비해 상대적으로 커져, 잡음이 유발하는 각도
  /// 왜곡이 `atan(잡음/windowDistance)` 만큼 줄어든다 — 오프셋 자체를
  /// 지우는 것이 아니라(그러면 진짜 코너도 지워진다), 오프셋이 각도
  /// 판정에 기여하는 **비중**을 낮추는 방식이다.
  ///
  /// 기본값은 `minDistanceThreshold`(이미 호출측이 perimeter 비례로
  /// 넘겨주는 값)를 그대로 재사용한다 — 새 파라미터를 별도로 계산해
  /// 넘기지 않아도 기존 호출부가 자동으로 넓은 윈도우 이득을 받는다.
  static List<Point> detectSignificantCorners(
    List<Point> points, {
    double minDistanceThreshold = 10.0,
    bool allowFewCornerFallback = true,
    double? angleWindowDistance,
  }) {
    if (points.length < 3) return List.of(points);

    // 각도 임계값 - 꺾임 각도가 이 값보다 작으면 코너로 인식
    const cornerAngleThreshold = 120.0;
    final windowDistance = angleWindowDistance ?? minDistanceThreshold;

    // 1) 문턱 미만인 후보 인덱스와 각도를 전부 수집한다. 각 점의 각도는
    // 바로 이웃이 아니라 [windowDistance]만큼 떨어진 넓은 윈도우로 잰다
    // (위 doc 참조) — 배열 경계는 `_walkArcDistance`가 자연히 클램프하므로
    // 루프 범위(`1..length-2`)는 "시작/끝점은 별도로 처리한다"는 기존
    // 의미 그대로 유지한다.
    final candidateAngles = <int, double>{};
    for (int i = 1; i < points.length - 1; i++) {
      final angle = _wideWindowCornerAngle(points, i, windowDistance);
      if (angle < cornerAngleThreshold) {
        candidateAngles[i] = angle;
      }
    }
    final candidateIndices = candidateAngles.keys.toList()..sort();

    // 1b) 구간 내 대표점(=가장 뾰족한 점) 선정은 **좁은(바로 이웃) 각도**로
    // 한다 — 넓은 윈도우는 "이 지점이 코너 후보인가"(잡음 필터링)에는
    // 강하지만, "이 후보들 중 정확히 어느 점이 시각적 꼭짓점에 가장
    // 가까운가"에는 오히려 약하다. 넓은 창은 먼 두 점 사이의 평균적
    // 방향으로 각도를 재므로, 같은 구간 안에서 서로 다른 두 후보가 거의
    // 같은 넓은-각도를 가질 수 있고, 그중 실제 꼭짓점에서 살짝 벗어난
    // 점이 대표로 뽑히면 그 점을 기준으로 그은 변이 실제 궤적(및 다음
    // 코너까지 남은 잡음 점들)에서 크게 벗어나 `_hasStraightPolygonEdges`
    // (원 판정 전 다각형 선-베토, bow-ratio 직선 변 검증)를 통과하지
    // 못하는 회귀가 실측됐다 — 진단 스윕: 넓은 각도로 대표점을 뽑으면
    // bow-ratio가 tight 대비 최대 2배까지 벌어져 진짜 삼각형 6/200이
    // circle로 새 버렸다(개선 전 0/200). 좁은 각도로 뽑으면 그 6건 모두
    // 원래대로 삼각형으로 복귀하면서도, 후보 자체를 줄이는 넓은-윈도우
    // 필터링 효과(오각형·육각형 오분류 감소)는 그대로 유지된다.
    final tightAngles = <int, double>{};
    for (final idx in candidateIndices) {
      tightAngles[idx] = GeometryUtils.calculateCornerAngle(
        points[idx - 1],
        points[idx],
        points[idx + 1],
      );
    }

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
      double sharpestAngle = tightAngles[sharpestIndex]!;
      for (int k = runStart + 1; k <= runEnd; k++) {
        final idx = candidateIndices[k];
        final angle = tightAngles[idx]!;
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
    if (allowFewCornerFallback && corners.length < 2 && points.length >= 3) {
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

  /// [detectSignificantCorners]와 달리 "시작점 항상 코너 포함"과 "후보가
  /// 2개 미만이면 시작·중간·끝점으로 대체해 최소 3개를 보장한다" 두 편향이
  /// **없는** 코너 카운터다. 다각형 분류(그리고 [detectAndTransform]의
  /// 다각형 선-베토)에서는 그 두 편향이 합리적이지만(닫힌 도형은 최소
  /// 3점이 있어야 다각형을 이루고, 이음매에 걸친 진짜 코너를 놓치면 안
  /// 된다), 원/타원 판별(`ShapeDetector._isCircleOrEllipse`의
  /// `cornerScore`)에 그대로 재사용하면 **진짜 원도 항상 코너 1개 이상(강제
  /// 포함된 시작점) 또는 3개(폴백)로 잡혀** cornerScore가 부당하게
  /// 오염된다 — 진단 스윕 실측: jitter 0~3% 원 60/60 시행 전부 "코너
  /// 3개"로 오판됐다.
  ///
  /// 이 함수는 그 두 편향을 제거하고 각도 기준만으로 판정한다. 대신
  /// 궤적을 **순환(닫힌 폐곡선)으로 인덱싱**해, 그리기 시작점이 실제
  /// 꼭짓점인 경우(사각형을 모서리에서부터 그리기 시작한 경우)의 코너까지
  /// 놓치지 않는다 — `detectSignificantCorners`가 `i=1..length-2`만 훑어
  /// prev/next가 없는 경계(양 끝)를 검사하지 못하는 것과 달리, 여기서는
  /// `(i±1+n)%n`으로 감싸 경계에서도 각도를 정상 계산한다.
  ///
  /// ⚠️ 이 순환 인덱싱은 "시작점 강제 포함"이 없어, Douglas-Peucker
  /// 단순화가 실제 코너 하나를 이음매 앞뒤 두 점으로 쪼개 각 점의 국소
  /// 각도가 개별적으로는 문턱을 넘지 못하는 경우 그 코너를 놓칠 수 있다
  /// (다각형 선-베토가 `detectSignificantCorners`를 쓰는 이유 — 위 그
  /// 함수의 doc 참조). 원/타원 연속 점수용으로는 이 리스크보다 "진짜
  /// 원의 코너 수를 부풀리지 않는 것"이 더 중요해 이 트레이드오프를
  /// 택했다.
  static int countCornerClusters(
    List<Point> points, {
    double minDistanceThreshold = 10.0,
    double cornerAngleThreshold = 120.0,
  }) {
    return cornerClusterPoints(
      points,
      minDistanceThreshold: minDistanceThreshold,
      cornerAngleThreshold: cornerAngleThreshold,
    ).length;
  }

  /// [countCornerClusters]와 같은 판정 로직으로 대표 코너 "점" 자체를
  /// 반환한다 — 개수뿐 아니라 실제 형태(직각·평행변 등)까지 확인해야 하는
  /// 하드 베토 판정에 쓰인다.
  ///
  /// [cornerAngleThreshold] 기본값은 [detectSignificantCorners]와 같은
  /// **120°**다 — 두 경로(원 판정·다각형 판정)가 "무엇을 코너로 보는가"에
  /// 대해 같은 기준을 쓰도록 맞춘 것이 이 함수의 핵심 목적이라, 각도
  /// 임계값 자체를 다르게 가져가면 그 일관성이 다시 깨진다.
  ///
  /// ⚠️ 이 임계값 때문에 지터가 아주 큰(6~8%) 진짜 원도 드물게 노이즈를
  /// 코너로 잡을 수 있다 — 더 엄격한 임계값(100°)이나 컨벡스 헐 크기
  /// 게이트로 이를 추가로 걸러보려 했으나(진단 스윕 실측), 둘 다 지터가
  /// 큰 진짜 사각형·삼각형까지 함께 걸러 목표 도형(둥글게 그린 사각형·
  /// 삼각형)의 개선폭을 오히려 깎았다 — 자세한 트레이드오프는
  /// `ShapeDetector._isCircleOrEllipse`의 하드 베토 주석 참조.
  ///
  /// ⭐ UB-555 3차에서 [detectSignificantCorners]에는 "넓은 윈도우" 를
  /// 적용했지만, 이 함수에는 **의도적으로 적용하지 않았다**. 진단 스윕
  /// 실측: 여기에 같은 원리(넓은 윈도우 후보 판정 + 좁은 윈도우 대표점
  /// 선정)를 적용하면 `circle_jitter` 스윕 자체는 크게 개선되지만
  /// (121→150/150, 74→148/150), 그 대가로 **둥글게 그린 사각형이
  /// circle로 새는 오분류가 늘어** `square_corner_0.2` 한 스윕에서만
  /// circle 오분류가 53→78건으로 증가했다 — 이 함수의 코너 수가
  /// [_isCircleOrEllipse]의 `cornerScore`에 직접 들어가므로, 코너를 조금만
  /// 적게 세어도 원 판정 쪽으로 저울이 기운다(이 클래스 문서 상단, 그리고
  /// `_isCircleOrEllipse`의 하드 베토 주석이 설명하는 바로 그 반대 방향
  /// 제약). 즉 순추가 스윕 합계는 개선되어도, "각진 도형이 원으로 새지
  /// 않아야 한다"는 이 리포의 더 강한 우선순위(회귀 방지 테스트로 고정됨,
  /// `shape_detector_circle_gate_corner_signal_test.dart`)를 침해한다.
  /// 반대 방향(원이 다각형으로 새는 것)에서는 [detectSignificantCorners]
  /// 단독 변경만으로도 이미 안전하게 회귀 없이 개선됐으므로(아래 참조),
  /// 이 함수는 원래의 좁은(바로 이웃) 각도 판정을 그대로 유지한다.
  static List<Point> cornerClusterPoints(
    List<Point> points, {
    double minDistanceThreshold = 10.0,
    double cornerAngleThreshold = 120.0,
  }) {
    final n = points.length;
    if (n < 3) return const <Point>[];

    final candidateAngles = <int, double>{};
    for (int i = 0; i < n; i++) {
      final prev = points[(i - 1 + n) % n];
      final curr = points[i];
      final next = points[(i + 1) % n];
      final angle = GeometryUtils.calculateCornerAngle(prev, curr, next);
      if (angle < cornerAngleThreshold) {
        candidateAngles[i] = angle;
      }
    }
    final candidateIndices = candidateAngles.keys.toList()..sort();
    if (candidateIndices.isEmpty) return const <Point>[];

    // 인접 후보를 구간(run)으로 묶고 구간마다 가장 뾰족한 대표점 하나만
    // 남긴다 — detectSignificantCorners와 같은 클러스터링 원리.
    final repIndices = <int>[];
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
      repIndices.add(sharpestIndex);
      runStart = runEnd + 1;
    }

    // 순환 경계 병합 — 정렬된 인덱스 목록의 첫/마지막 구간이 실제로는
    // n-1 ↔ 0 경계를 사이에 둔 같은 물리적 코너를 가리킬 수 있다.
    if (repIndices.length >= 2) {
      final wrapDistance = GeometryUtils.calculateDistance(
        points[repIndices.first],
        points[repIndices.last],
      );
      if (wrapDistance < minDistanceThreshold) {
        repIndices.removeLast();
      }
    }

    // 대표점끼리도 서로 너무 가까우면 병합한다(비순차 클러스터링 잔여분).
    final acceptedPoints = <Point>[];
    for (final idx in repIndices) {
      final p = points[idx];
      bool tooClose = false;
      for (final accepted in acceptedPoints) {
        if (GeometryUtils.calculateDistance(p, accepted) <
            minDistanceThreshold) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) {
        acceptedPoints.add(p);
      }
    }

    return acceptedPoints;
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
      final angleA = math.atan2(a.y - resultCentroid.y, a.x - resultCentroid.x);
      final angleB = math.atan2(b.y - resultCentroid.y, b.x - resultCentroid.x);
      return angleA.compareTo(angleB);
    });

    return result;
  }

  /// 코너 3개의 삼각형 형태 적합도 점수를 계산한다.
  ///
  /// [evaluateTriangleShape]는 점 구름 전체에서 컨벡스 헐로 자체 후보를
  /// 다시 뽑아 평가하므로(둘레가 매끈한 도형은 헐 점이 6개를 넘어 게이트에서
  /// 0점 처리될 수 있다), 호출측이 이미 확보한 특정 3점 후보를 그대로
  /// 평가하고 싶을 때는 이 메서드를 쓴다(UB-555 2차: 원 판정 전 다각형
  /// 코너 신뢰도 검사 — 같은 3점을 두 번, 서로 다른 기준으로 재추출하지
  /// 않는다).
  static double calculateTriangleScoreForCorners(List<Point> corners) {
    return _calculateTriangleScore(corners);
  }

  /// 코너 개수를 그리디하게 [target]개로 축소한다(Visvalingam–Whyatt 방식,
  /// UB-555 3차).
  ///
  /// 지터가 커질수록 [detectSignificantCorners]가 진짜 코너 수(삼각형=3,
  /// 사각형=4)보다 훨씬 많은 "가짜 코너"를 검출한다 — 지터가 만드는 국소적인
  /// 짧은 방향 반전이 각도 문턱(120도)을 넘어서기 때문이다. 이 가짜 코너들은
  /// 한 변을 따라 띄엄띄엄 흩어져 있어 [detectSignificantCorners]의 거리
  /// 기반 클러스터링(서로 [minDistanceThreshold] 이내인 인접 후보만 병합)이
  /// 하나로 묶지 못한다.
  ///
  /// 이 함수는 클러스터링 대신 **사후 축소**로 같은 문제를 다룬다: 매 단계
  /// "제거해도 실루엣 왜곡이 가장 작은" 코너 하나를 골라 제거하고, 목표
  /// 개수에 도달할 때까지 반복한다. 왜곡의 척도는 그 코너와 양 이웃이
  /// 이루는 삼각형의 넓이다(Visvalingam-Whyatt의 고전적 비용 함수) — 이
  /// 삼각형이 작을수록 그 코너는 이웃 두 코너를 잇는 직선에 가깝고, 제거해도
  /// 폴리곤 실루엣이 거의 바뀌지 않는다. 지터가 만든 가짜 코너는 정의상 그
  /// 직선 근방의 짧은 요동이므로 이 비용이 작고, 먼저 제거된다.
  ///
  /// 이웃은 **순환(첫/마지막이 서로 이웃)**으로 계산한다 — 폐곡선 다각형의
  /// 코너 목록이므로 마지막 코너 다음은 다시 첫 코너다.
  ///
  /// [corners]는 원본 발견 순서(그려진 순서, `detectSignificantCorners`가
  /// 반환하는 순서)를 유지해야 하고, 반환값도 그 순서의 부분수열을 그대로
  /// 유지한다 — 이 순서가 유지돼야 호출측
  /// (`ShapeDetector._hasStraightPolygonEdges`)이 인접 반환값 쌍을 실제로
  /// 그려진 변으로 올바르게 해석할 수 있다. 이 함수 자체는 그 직선 변
  /// 검증을 하지 않는다 — "가장 작은 넓이" 순으로 지웠다는 것이
  /// 자동으로 "남은 코너 사이가 직선"이라는 뜻은 아니다(특히 진짜 원처럼
  /// 애초에 직선 변이 없는 도형에서는 이 축소가 3~4개의 그럴듯해 보이는
  /// 점을 만들어낼 수 있다) — 그 검증은 축소 결과를 실제로 채택하기 전에
  /// 호출측이 반드시 별도로 수행해야 한다.
  ///
  /// [target]이 3 미만이면(다각형이 성립하지 않음) 또는 [corners].length가
  /// [target] 이하면 축소할 필요가 없으므로 원본의 복사본을 그대로 반환한다.
  static List<Point> reduceCornersGreedily(
    List<Point> corners, {
    required int target,
  }) {
    if (target < 3 || corners.length <= target) {
      return List<Point>.of(corners);
    }

    final working = List<Point>.of(corners);
    while (working.length > target) {
      final n = working.length;
      var minCost = double.infinity;
      var minIndex = 0;
      for (var i = 0; i < n; i++) {
        final prev = working[(i - 1 + n) % n];
        final curr = working[i];
        final next = working[(i + 1) % n];
        final cost = _triangleArea(prev, curr, next);
        if (cost < minCost) {
          minCost = cost;
          minIndex = i;
        }
      }
      working.removeAt(minIndex);
    }

    return working;
  }

  /// 세 점이 이루는 삼각형의 넓이 (Visvalingam-Whyatt 비용 함수).
  static double _triangleArea(Point a, Point b, Point c) {
    return ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)).abs() / 2;
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

  /// [start]에서 [forward] 방향(비순환, 배열 끝에서 멈춤)으로 둘레 거리를
  /// 누적해 [distance] 이상이 되는 순간의 인덱스를 반환한다 — "넓은 윈도우
  /// 각도 추정"(UB-555 3차)의 핵심 보조 함수. `points`의 점 간격은
  /// Douglas-Peucker 단순화 이후 균일하지 않으므로(직선 구간은 2점,
  /// 노이즈가 남은 구간은 여러 점), 인덱스를 고정 개수만큼 건너뛰는 대신
  /// **실제 둘레 거리**를 기준으로 걷는다.
  ///
  /// 배열 경계에 닿으면(더 갈 곳이 없으면) 그 자리에서 멈춘다 — 코너가
  /// 궤적의 시작/끝 가까이에 있어 요청한 [distance]를 다 채우지 못해도
  /// 예외를 던지지 않고 "갈 수 있는 만큼만" 돌려준다. 이는 기존 좁은
  /// 윈도우(바로 이웃 1점)가 배열 경계에서 자연히 짧아지던 것과 같은
  /// 동작이며, 새로 도입한 위험이 아니다.
  static int _walkArcDistance(
    List<Point> points,
    int start,
    double distance, {
    required bool forward,
  }) {
    var idx = start;
    var accumulated = 0.0;
    while (accumulated < distance) {
      final nextIdx = forward ? idx + 1 : idx - 1;
      if (nextIdx < 0 || nextIdx >= points.length) break;
      accumulated += GeometryUtils.calculateDistance(
        points[idx],
        points[nextIdx],
      );
      idx = nextIdx;
    }
    return idx;
  }

  /// 넓은 윈도우(k-cosine 방식)로 점 [i]의 코너 각도를 계산한다 —
  /// [detectSignificantCorners] doc의 "⭐ angleWindowDistance" 절 참조.
  /// [i]로부터 둘레 거리 기준 [windowDistance]만큼 떨어진 앞뒤 점을 찾아
  /// 그 두 점과 [i]로 각도를 잰다(비순환 — 배열 경계에서 자연히 클램프).
  static double _wideWindowCornerAngle(
    List<Point> points,
    int i,
    double windowDistance,
  ) {
    final behindIdx = _walkArcDistance(
      points,
      i,
      windowDistance,
      forward: false,
    );
    final aheadIdx = _walkArcDistance(points, i, windowDistance, forward: true);
    return GeometryUtils.calculateCornerAngle(
      points[behindIdx],
      points[i],
      points[aheadIdx],
    );
  }
}
