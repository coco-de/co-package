// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:

// 🌎 Project imports:
import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'geometry_utils.dart';
import 'point_simplifier.dart';
import 'corner_detector.dart';
import 'convex_hull_calculator.dart';

/// 도형 타입을 나타내는 열거형
enum ShapeType {
  none,
  line,
  rectangle,
  square,
  diamond,
  parallelogram,
  trapezoid,
  irregularQuadrilateral,
  triangle,
  rightTriangle,
  equilateralTriangle,
  isoscelesTriangle,
  irregularTriangle,
  polygon,
  pentagon,
  hexagon,
  circle,
  ellipse,
  arrow,
  doubleArrow,
  blockArrow,
  connector,
  polyline,
  pending,
}

/// 도형 특성을 나타내는 클래스 - 알고리즘 계산에 사용
class ShapeCharacteristics {
  final Rect boundingBox;
  final Point centroid;
  final double aspectRatio;
  final List<Point> convexHull;

  const ShapeCharacteristics({
    required this.boundingBox,
    required this.centroid,
    required this.aspectRatio,
    required this.convexHull,
  });
}

/// 도형 인식 결과를 담는 클래스
class ShapeDetectionResult {
  final ShapeType shapeType;
  final Stroke transformedStroke;

  const ShapeDetectionResult(this.shapeType, this.transformedStroke);

  /// 문자열 형태의 shapeType 반환
  String get shapeTypeString {
    switch (shapeType) {
      case .line:
        return 'line';
      case .rectangle:
        return 'rectangle';
      case .square:
        return 'square';
      case .diamond:
        return 'diamond';
      case .parallelogram:
        return 'parallelogram';
      case .trapezoid:
        return 'trapezoid';
      case .irregularQuadrilateral:
        return 'irregular_quadrilateral';
      case .triangle:
        return 'triangle';
      case .rightTriangle:
        return 'right_triangle';
      case .equilateralTriangle:
        return 'equilateral_triangle';
      case .isoscelesTriangle:
        return 'isosceles_triangle';
      case .irregularTriangle:
        return 'irregular_triangle';
      case .polygon:
        return 'polygon';
      case .pentagon:
        return 'pentagon';
      case .hexagon:
        return 'hexagon';
      case .circle:
        return 'circle';
      case .ellipse:
        return 'ellipse';
      case .arrow:
        return 'arrow';
      case .doubleArrow:
        return 'double_arrow';
      case .blockArrow:
        return 'block_arrow';
      case .connector:
        return 'connector';
      case .polyline:
        return 'polyline';
      case .pending:
        return 'pending';
      case .none:
        return '';
    }
  }
}

/// 도형 인식 및 변환을 담당하는 메인 클래스
class ShapeDetector {
  /// 싱글턴 인스턴스
  static final ShapeDetector instance = ShapeDetector._();

  // 폐곡선 인식 임계값 (시작점과 끝점 사이 거리가 둘레의 15% 미만이면 폐곡선)
  static const double _closedThreshold = 0.15;

  /// 인스턴스 생성을 제한하는 private 생성자
  const ShapeDetector._();

  /// 도형 인식 및 변환 - 메인 진입점
  ShapeDetectionResult detectAndTransform(Stroke stroke) {
    // 원본 점이 너무 적으면 그대로 사용
    if (stroke.points.length < 5) {
      return ShapeDetectionResult(.polyline, stroke);
    }

    // 1. 기본 정보 계산
    final perimeter = GeometryUtils.calculatePolygonPerimeter(stroke.points);
    final isClosed = _isClosedShape(stroke.points, perimeter);
    final almostClosed = _isAlmostClosed(stroke.points, perimeter);

    // 2. 포인트 단순화
    final simplifiedPoints = _performPointSimplification(
      stroke.points,
      perimeter,
    );

    // 3. 변환된 스트로크 생성
    final transformedStroke = _createTransformedStroke(stroke);

    if (isClosed || almostClosed) {
      // 4. 원 판정보다 먼저 다각형 코너를 신뢰할 관문(veto, UB-555 2차)
      //
      // 원 판정(`_isCircleOrEllipse`)이 `_detectPolygonalShapes`보다 먼저
      // 실행되는데, 둘 다 "이 도형이 몇 개의 코너를 가졌는가"를 스스로
      // 다시 계산한다 — 원 판정을 통과 못 해 다각형 경로로 넘어가도 그
      // 경로가 **독립적으로 재계산**하다 보니, 여기서 "3~4개의 뚜렷한
      // 코너"를 이미 확인했더라도 다각형 경로가 다른 기준(예: 코너가
      // 정확히 3개가 아니거나 `evaluateTriangleShape`가 다른 컨벡스 헐
      // 후보를 뽑아 재평가)으로 실패하면 그 정보가 그대로 버려진다(실측:
      // 이 관문 없이 원 판정만 거부하게 했더니 삼각형 판정률 자체는
      // 그대로였고, 미스 유형만 ellipse/circle에서 polyline으로 바뀌었을
      // 뿐이었다). 그래서 여기서 이미 검증된 코너로 **직접 도형을
      // 구성해 반환**한다 — 같은 3~4점을 두 경로가 서로 다른 기준으로
      // 두 번 판정하지 않는다.
      final earlyResult = _tryPolygonVetoBeforeCircle(
        simplifiedPoints,
        transformedStroke,
        perimeter,
      );
      if (earlyResult != null) {
        _stampTimestamps(stroke, earlyResult.transformedStroke);
        return earlyResult;
      }

      // 5. 원/타원 감지 시도
      final circleResult = _tryDetectCircleOrEllipse(
        simplifiedPoints,
        transformedStroke,
      );
      if (circleResult != null) {
        _stampTimestamps(stroke, circleResult.transformedStroke);
        return circleResult;
      }
    }

    // 6. 코너 기반 도형 감지
    final result = _detectPolygonalShapes(
      simplifiedPoints,
      transformedStroke,
      isClosed,
      almostClosed,
      perimeter,
    );
    _stampTimestamps(stroke, result.transformedStroke);
    return result;
  }

  /// 원 판정 전에 "명확한 3~4코너 다각형"을 먼저 확정해 반환한다
  /// (UB-555 2차 — `detectAndTransform`의 4단계에서 호출).
  ///
  /// 여기서 쓰는 코너 목록은 `_detectPolygonalShapes`가 다각형 분류에
  /// 쓰는 것과 **같은** `CornerDetector.detectSignificantCorners`이며,
  /// 같은 각도 임계값·perimeter 비례 클러스터 거리를 쓴다 —
  /// `allowFewCornerFallback: false`로 "후보 2개 미만이면 3점으로
  /// 대체" 폴백만 끈다(원이 다각형으로 위장되는 것을 막기 위함, 아래
  /// 참조). `_isCircleOrEllipse`의 `cornerScore`는 **의도적으로 다른**
  /// 카운터(`CornerDetector.cornerClusterPoints`)를 쓴다 — 이쪽은
  /// "시작점 항상 코너 포함"이 없는 순수 순환 판정이라, 진짜 원의
  /// 코너 수를 부풀리지 않는다. 이 관문(다각형 선-베토)은 반대로 그
  /// 강제 포함이 **필요**하다 — Douglas-Peucker가 진짜 코너 하나를
  /// 궤적의 시작/끝 이음매에서 두 점으로 쪼개 각각 개별로는 각도
  /// 문턱을 못 넘기는 경우, 시작점 강제 포함만이 그 코너를 놓치지
  /// 않는다(실측: 라운딩 16% 사각형이 `cornerClusterPoints`로는 코너
  /// 3개로 잡혀 rightTriangle로 오분류됐다 — `detectSignificantCorners`
  /// 문서의 상세 참조). 즉 두 경로가 "코너를 어떻게 세는가"에서
  /// 갈리는 것은 실수가 아니라, 각자가 처한 반대 방향의 리스크
  /// (원의 코너 수 부풀림 vs 다각형의 이음매 코너 누락)에 맞춘
  /// 의도적 선택이다.
  ///
  /// 코너 개수가 정확히 3(삼각형) 또는 4(사각형)이고, 두 가지 검증을
  /// **모두** 통과해야 다각형으로 확정한다:
  /// ① 형태 검증 — 삼각형은 `evaluateTriangleShape`, 사각형은
  ///    `_isRightAngled`+`_hasParallelSides`. 이미 `_detectPolygonalShapes`
  ///    /`ShapeDetector`가 신뢰하는 기존 로직을 그대로 재사용한다.
  /// ② 직선 변 검증(`_hasStraightPolygonEdges`) — ①만으로는 부족하다.
  ///    세 점(또는 네 점)의 내각 합/각도는 그 점들이 **어디서 왔는지**
  ///    묻지 않는다. 원 둘레에서 지터로 우연히 뽑힌 점들도 유클리드
  ///    항등식(3점의 내각 합은 항상 180도에 가깝다)상 삼각형처럼 보이는
  ///    각도를 가질 수 있다 — 실측: 지터 6~8% 원에서 ①만으로는 threshold를
  ///    0.85까지 올려도 오분류가 사라지지 않았다. 진짜 다각형의 변은
  ///    (손떨림을 빼면) 코너 사이를 직선으로 잇는 반면, 원에서 뽑은
  ///    코너 사이의 실제 궤적은 호(arc)라 그 직선에서 크게 벗어난다 —
  ///    이 벗어남을 직접 측정해야 두 경우가 갈린다.
  ///
  /// 둘 다 통과하면 `_createPolygonFromCorners`로 **바로 도형을 구성해
  /// 반환**한다 — 원 판정을 거부만 하고 다각형 경로가 이 코너를 다시
  /// 독립적으로 재평가하게 두면(원래 시도), 그 경로가 다른 세부 기준
  /// (예: 폴백 코너 생성, 다른 컨벡스 헐 후보)으로 재차 실패해 결국
  /// polyline으로 떨어지는 낭비가 생긴다(실측: 이 직접 구성 없이
  /// 원판정 거부만 했을 때 삼각형 인식률 자체는 그대로였고 미스 유형만
  /// circle/ellipse에서 polyline으로 바뀌었을 뿐이었다).
  ///
  /// 어느 조건도 만족하지 않으면(코너 0~2·5개 이상, 또는 3~4개라도 형태·
  /// 직선 검증 실패) `null`을 반환해 평소대로 원 판정으로 진행한다.
  ShapeDetectionResult? _tryPolygonVetoBeforeCircle(
    List<Point> simplifiedPoints,
    Stroke transformedStroke,
    double perimeter,
  ) {
    final cornerClusterDistance = math.max(10.0, perimeter * 0.03);
    final earlyCorners = CornerDetector.detectSignificantCorners(
      simplifiedPoints,
      minDistanceThreshold: cornerClusterDistance,
      allowFewCornerFallback: false,
    );

    final directTriangle = _tryCornersAsTriangle(
      earlyCorners,
      simplifiedPoints,
      transformedStroke,
    );
    if (directTriangle != null) return directTriangle;

    final directQuad = _tryCornersAsQuadrilateral(
      earlyCorners,
      simplifiedPoints,
      transformedStroke,
    );
    if (directQuad != null) return directQuad;

    // UB-555 3차 synthesis: 정확히 3·4개인데 엄격한 bow-ratio(0.06)만
    // 실패한 경우, 완화된 bow-ratio로 재시도한다. 넓은 윈도우 각도 추정과
    // 결합하면 지터가 큰 손그림도 코너 개수 자체는 정확히 3·4개로 잡히는
    // 경우가 늘어나는데, 그 개수만 정확하고 개별 변의 흔들림(bow)이 여전히
    // 엄격한 임계값을 넘는 경우가 다수 관찰되어 이 재시도를 추가한다.
    //
    // ⚠️ `requireSignCancellation: true` 가 반드시 필요하다 — 완화된
    // bow-ratio(0.14)만으로는 지터(부호가 상쇄됨)와 의도적인 한쪽 곡률
    // (예: 세 변이 바깥으로 8% 볼록한 폐곡선)을 구분하지 못해, 후자가
    // 삼각형으로 오분류되는 회귀가 실측됐다(`shape_detector_test.dart`의
    // bulge=10 고정 회귀 테스트). 코너가 원래부터 정확히 3·4개인 이
    // 직접-매치 경로는(아래 그리디 축소 경로와 달리) 지터가 전혀 없는
    // "의도적으로 흽게 그린 폐곡선" 입력도 그대로 통과할 수 있어, 이
    // 경로에서만 부호 상쇄 검증을 추가로 요구한다.
    if (earlyCorners.length == 3) {
      final relaxedTriangle = _tryCornersAsTriangle(
        earlyCorners,
        simplifiedPoints,
        transformedStroke,
        maxEdgeBowRatio: _greedyReductionMaxEdgeBowRatio,
        requireSignCancellation: true,
      );
      if (relaxedTriangle != null) return relaxedTriangle;
    } else if (earlyCorners.length == 4) {
      final relaxedQuad = _tryCornersAsQuadrilateral(
        earlyCorners,
        simplifiedPoints,
        transformedStroke,
        maxEdgeBowRatio: _greedyReductionMaxEdgeBowRatio,
        requireSignCancellation: true,
      );
      if (relaxedQuad != null) return relaxedQuad;
    }

    // 코너가 정확히 3·4개가 아니면(지터가 만든 가짜 코너로 과다 검출됐을
    // 가능성) 그리디 축소(Visvalingam-Whyatt, UB-555 3차)로 3개·4개 후보를
    // 만들어 같은 검증(형태 점수 + 직선 변)으로 재시도한다.
    //
    // 상한(`_maxCornersForGreedyReduction`)을 두는 이유: 코너가 극단적으로
    // 많으면(예: 지터가 매우 큰 진짜 원이 순수 각도 문턱만으로 십수 개의
    // 노이즈 코너를 만든 경우) 그리디 축소가 "그럴듯해 보이는" 3~4점을
    // 항상 만들어낼 수 있다 — 축소 자체는 넓이 최소화만 볼 뿐 결과가
    // 실제로 직선 변인지는 모른다. 아래 `_hasStraightPolygonEdges`가 주된
    // 방어선이지만(원의 현은 실제 궤적에서 크게 벗어나 대개 여기서
    // 걸러진다), 상한을 함께 둬 애초에 시도 자체를 제한한다 — 실측
    // 코너 분포(지터 8%까지의 진짜 삼각형·사각형)가 최대 10개 안팎이라
    // 목표 개선 범위를 덮으면서, 극단적으로 많은 코너는 다각형 궤적보다
    // 원 궤적을 가리킬 가능성이 높다고 보고 시도하지 않는다.
    // 축소는 4코너(사각형) 후보를 먼저 시도한다 — 3코너 축소가 항상 더
    // "쉽게"(적은 개수라 형태 검증 통과가 더 쉬움) 통과하다 보니, 순서를
    // 반대로 하면 실제로는 사각형인 도형이 그보다 먼저 통과해버린 잘못된
    // 삼각형 후보에 가로채인다(실측: 3코너 우선일 때 square_jitter 스윕에
    // rightTriangle/isoscelesTriangle 오분류가 새로 대거 발생했고, 4코너
    // 우선으로 바꾸자 사라졌다 — 두 성공률은 그대로이거나 더 좋아졌다).
    if (earlyCorners.length > 4 &&
        earlyCorners.length <= _maxCornersForGreedyReduction) {
      final reducedToQuad = CornerDetector.reduceCornersGreedily(
        earlyCorners,
        target: 4,
      );
      final reducedQuad = _tryCornersAsQuadrilateral(
        reducedToQuad,
        simplifiedPoints,
        transformedStroke,
        maxEdgeBowRatio: _greedyReductionMaxEdgeBowRatio,
      );
      if (reducedQuad != null) return reducedQuad;

      final reducedToTriangle = CornerDetector.reduceCornersGreedily(
        earlyCorners,
        target: 3,
      );
      final reducedTriangle = _tryCornersAsTriangle(
        reducedToTriangle,
        simplifiedPoints,
        transformedStroke,
        maxEdgeBowRatio: _greedyReductionMaxEdgeBowRatio,
      );
      if (reducedTriangle != null) return reducedTriangle;
    }

    return null;
  }

  // 그리디 코너 축소를 시도할 원본 코너 개수의 상한 (UB-555 3차).
  // 위 `_tryPolygonVetoBeforeCircle`의 상한 사유 주석 참조.
  static const int _maxCornersForGreedyReduction = 20;

  // 그리디 축소로 만든 3~4코너 후보에 적용하는 직선 변 허용 오차
  // (UB-555 3차, `_hasStraightPolygonEdges`의 [maxEdgeBowRatio]로 전달됨).
  //
  // 원본 코너가 정확히 3·4개일 때 쓰는 `_polygonVetoMaxEdgeBowRatio`(0.06)를
  // 그대로 재사용하면 안 된다 — 진단 실측(150개 시드 스윕, 코너 축소 후
  // bow ratio 분포):
  //
  //   삼각형 지터  4%: p75=0.050   6%: p75=0.077   8%: p75=0.111 (중앙값 0.092)
  //   사각형 지터  4%: p75=0.098   6%: p75=0.137   8%: p75=0.171
  //   진짜 원(축소 시도 자체가 발생한 지터 6~8%만): **최솟값 0.157~0.180**
  //
  // 즉 지터 자체가 만드는 "직선인데 흔들린" 편차가 이미 원래 임계값
  // 0.06을 가볍게 넘는다 — 0.06을 그대로 쓰면 축소가 거의 항상 실패해
  // (실측: 재시도 141건 중 140건이 이 이유로 실패) 개선 효과가 사라진다.
  // 반면 진짜 원을 억지로 3~4점으로 욱여넣으면 남는 호(arc)의 bow ratio가
  // 0.157 밑으로 내려간 사례가 없어(같은 스윕), 0.06과 0.157 사이 어디든
  // "지터로 흔들린 직선"과 "원의 호"를 갈라낼 여지가 있다. 이 여지의
  // 대략 중간(사각형 지터 8%의 p75 근방)인 0.14를 택해, 원 오분류
  // 위험에 매 안전한 마진(≈0.017)을 남기면서 목표 개선폭 대부분을
  // 확보한다 — 임계값을 원의 실측 최솟값에 바짝 붙이면 시드가 조금만
  // 바뀌어도(더 많은 트라이얼) 회귀할 수 있다.
  static const double _greedyReductionMaxEdgeBowRatio = 0.14;

  /// [corners]가 정확히 3개이고 삼각형 형태·직선 변 검증을 모두 통과하면
  /// 그 자리에서 도형을 구성해 반환한다. 통과하지 못하면 `null`.
  ///
  /// [corners]는 `_hasStraightPolygonEdges`가 요구하는 traversal-order(원본
  /// 발견 순서, 정렬되지 않음) 그대로여야 한다 — `_createPolygonFromCorners`
  /// 호출은 검증을 통과한 뒤에만 일어나므로, 그 안에서 일어나는 정렬(각도
  /// 순 재배열)이 이 함수의 직선 변 검사에 영향을 주지 않는다.
  ///
  /// [maxEdgeBowRatio]는 직선 변 검증의 허용 오차다 — 원본 코너 개수가
  /// 이미 3개(축소를 거치지 않음)인 호출은 기존 동작 그대로
  /// `_polygonVetoMaxEdgeBowRatio`(0.06)를 쓰고, 그리디 축소를 거친
  /// 호출은 더 느슨한 `_greedyReductionMaxEdgeBowRatio`를 명시적으로
  /// 넘긴다(위 상수 주석의 실측 근거 참조) — 기존 정확-3-코너 경로의
  /// 동작을 조금도 바꾸지 않기 위해 기본값을 분리했다.
  ShapeDetectionResult? _tryCornersAsTriangle(
    List<Point> corners,
    List<Point> simplifiedPoints,
    Stroke transformedStroke, {
    double maxEdgeBowRatio = _polygonVetoMaxEdgeBowRatio,
    bool requireSignCancellation = false,
  }) {
    if (corners.length != 3) return null;

    final triangleScore = CornerDetector.calculateTriangleScoreForCorners(
      corners,
    );
    if (triangleScore > 0.65 &&
        _hasStraightPolygonEdges(
          corners,
          simplifiedPoints,
          maxEdgeBowRatio: maxEdgeBowRatio,
          requireSignCancellation: requireSignCancellation,
        )) {
      _createPolygonFromCorners(transformedStroke, corners, true);
      final triangleType = _determineTriangleType(corners);
      return ShapeDetectionResult(triangleType, transformedStroke);
    }
    return null;
  }

  /// [corners]가 정확히 4개이고 직각·평행변·직선 변 검증을 모두 통과하면
  /// 그 자리에서 도형을 구성해 반환한다. 통과하지 못하면 `null`.
  ///
  /// 순서 요구 사항·[maxEdgeBowRatio] 의미는 [_tryCornersAsTriangle]과 같다.
  ShapeDetectionResult? _tryCornersAsQuadrilateral(
    List<Point> corners,
    List<Point> simplifiedPoints,
    Stroke transformedStroke, {
    double maxEdgeBowRatio = _polygonVetoMaxEdgeBowRatio,
    bool requireSignCancellation = false,
  }) {
    if (corners.length != 4) return null;

    final angles = _calculateCornerAngles(corners);
    final sides = _calculateSideLengths(corners);
    if (_isRightAngled(angles) &&
        _hasParallelSides(sides) &&
        _hasStraightPolygonEdges(
          corners,
          simplifiedPoints,
          maxEdgeBowRatio: maxEdgeBowRatio,
          requireSignCancellation: requireSignCancellation,
        )) {
      _createPolygonFromCorners(transformedStroke, corners, true);
      final quadType = _determineQuadrilateralType(corners);
      return ShapeDetectionResult(quadType, transformedStroke);
    }
    return null;
  }

  /// 변환 점들에 원본 스트로크의 timestamp를 선형 보간으로 스탬프한다.
  ///
  /// 변환 기하 점은 합성 점이라 timestamp가 0인데, 이대로 두면
  /// timestamp 정렬 소비자(페이지 병합 등)에서 동률 정렬로 점 순서가
  /// 뒤섞일 수 있고 리플레이에서도 진행 정보가 사라진다.
  void _stampTimestamps(Stroke source, Stroke transformed) {
    final points = transformed.points;
    if (points.isEmpty || source.points.isEmpty) return;

    final t0 = source.points.first.timestamp;
    final t1 = source.points.last.timestamp;
    for (var i = 0; i < points.length; i++) {
      final ts = points.length < 2
          ? t1
          : t0 + (t1 - t0) * i ~/ (points.length - 1);
      // 코너 점은 원본 점 객체를 공유할 수 있으므로 in-place 변형 대신
      // 복제본에 스탬프해 원본 스트로크를 변형하지 않는다.
      if (points[i].timestamp != ts) {
        points[i] = points[i].deepCopy()..timestamp = ts;
      }
    }
  }

  /// 포인트 단순화 수행
  List<Point> _performPointSimplification(
    List<Point> points,
    double perimeter,
  ) {
    double simplificationFactor = 0.01;

    // 포인트가 많을수록 단순화 강도 증가
    if (points.length > 200) {
      simplificationFactor = 0.01 * (1 + (points.length - 200) / 300);
    }

    final simplifiedPoints = PointSimplifier.simplifyPoints(
      points,
      perimeter * simplificationFactor,
    );

    return simplifiedPoints;
  }

  /// 변환된 스트로크 생성
  ///
  /// points는 비워둔 채 시작한다. 원본 손그림 점을 그대로 담으면 이후
  /// 변환 점들과 섞여 타원 재계산(PCA)이 부정확해지고 직선의 시작점이
  /// 어긋나므로, 변환된 기하만 채워 넣는다.
  Stroke _createTransformedStroke(Stroke stroke) {
    return Stroke(
      color: stroke.color,
      ink: "shape",
      width: stroke.width,
      createdAt: stroke.createdAt,
      options: stroke.options,
    );
  }

  /// 원/타원 감지 시도
  ShapeDetectionResult? _tryDetectCircleOrEllipse(
    List<Point> points,
    Stroke transformedStroke,
  ) {
    if (_isCircleOrEllipse(points)) {
      _createEllipse(transformedStroke, points);

      final ellipseType = _determineEllipseType(points);
      return ShapeDetectionResult(ellipseType, transformedStroke);
    }
    return null;
  }

  /// 다각형 모양 감지
  ShapeDetectionResult _detectPolygonalShapes(
    List<Point> simplifiedPoints,
    Stroke transformedStroke,
    bool isClosed,
    bool almostClosed,
    double perimeter,
  ) {
    // 코너 클러스터링 거리는 도형 크기에 비례해야 한다 — 고정 10px는 큰
    // 도형의 둥근 모서리(예: 둘레 700px에서 반경 20px 라운딩)를 하나로
    // 묶지 못해 사각형이 오각형·육각형으로 쪼개졌다(UB-555). 반대로 아주
    // 작게 그린 도형에서 지나치게 커지지 않도록 하한(10px)은 유지한다.
    final cornerClusterDistance = math.max(10.0, perimeter * 0.03);

    // 코너 감지
    final corners = CornerDetector.detectSignificantCorners(
      simplifiedPoints,
      minDistanceThreshold: cornerClusterDistance,
    );

    // 폐곡선이지만 코너가 부족한 경우 코너 생성
    List<Point> finalCorners = corners;
    if (isClosed && corners.length < 3 && simplifiedPoints.length >= 3) {
      finalCorners = CornerDetector.generateCornersForClosedShape(
        simplifiedPoints,
      );
    }

    return _classifyShapeByCorners(
      finalCorners,
      transformedStroke,
      isClosed,
      almostClosed,
      simplifiedPoints,
    );
  }

  /// 코너 수에 따른 도형 분류
  ShapeDetectionResult _classifyShapeByCorners(
    List<Point> corners,
    Stroke transformedStroke,
    bool isClosed,
    bool almostClosed,
    List<Point> simplifiedPoints,
  ) {
    // 삼각형 확인 (코너가 정확히 3개일 때)
    if (corners.length == 3 && (isClosed || almostClosed)) {
      final triangleScore = CornerDetector.evaluateTriangleShape(
        simplifiedPoints,
      );
      if (triangleScore > 0.65) {
        _createPolygonFromCorners(transformedStroke, corners, true);

        final triangleType = _determineTriangleType(corners);
        return ShapeDetectionResult(triangleType, transformedStroke);
      }
    }

    // 사각형 확인
    if (corners.length == 4 && isClosed) {
      _createPolygonFromCorners(transformedStroke, corners, true);

      final quadType = _determineQuadrilateralType(corners);
      return ShapeDetectionResult(quadType, transformedStroke);
    }

    // 코너가 5개 이상 → 펜타곤/헥사곤/폴리곤으로 향하기 전에, 지터가 만든
    // 가짜 코너로 과다 검출됐을 가능성을 그리디 축소로 먼저 배제한다
    // (UB-555 3차). `_tryPolygonVetoBeforeCircle`(원 판정 이전 관문)과 같은
    // 목적의 재시도이지만 이 지점이 별도로 필요한 이유가 있다: 그 관문은
    // 원 판정 **이전에만** 실행되는데(원 판정 게이트는 `isClosed ||
    // almostClosed`일 때만 도는 반면, 여기 `_classifyShapeByCorners`는
    // 폐곡선이 아닌 경우에도 호출된다), 코너 개수가 그 관문의 상한
    // (`_maxCornersForGreedyReduction`)을 넘거나 축소 결과가 검증(형태
    // 점수·직선 변)을 통과하지 못해 그 관문이 `null`을 반환한 경우
    // (원 판정으로 넘어갔다가 원도 아니라고 판정된 경우 포함), 지금까지는
    // 재시도 없이 곧장 코너 "개수"만으로 pentagon/hexagon/polygon이
    // 확정됐다. 여기서 같은 코너 집합으로 한 번 더(그리고 원 판정을
    // 아예 거치지 않는 열린/거의-닫힌 도형에서도) 시도한다.
    //
    // ⚠️ 진짜 오각형·육각형을 삼각형·사각형으로 잘못 욱여넣지 않도록
    // `_tryCornersAsTriangle`/`_tryCornersAsQuadrilateral`이 강제하는
    // 엄격한 검증(형태 점수 > 0.65, 직각+평행변, 그리고 무엇보다
    // `_hasStraightPolygonEdges` — 축소로 제거된 코너 사이 실제 궤적이
    // 직선에서 크게 벗어나면 거부)을 그대로 재사용한다. 진짜 5각·6각
    // 도형은 코너를 3~4개로 줄이면 남은 변 상당수가 원래 다른 코너를
    // 지나던 실제 궤적을 직선으로 잘못 근사하게 되므로 이 검증에서
    // 걸러진다 — 반대로 지터가 흩뿌린 가짜 코너만 제거된 경우에는 실제
    // 궤적이 원래부터 직선에 가까웠으므로 통과한다.
    // 축소 순서(4코너 우선)는 `_tryPolygonVetoBeforeCircle`과 같은 이유로
    // 고정한다 — 위 그 함수의 주석 참조.
    if (corners.length >= 5 &&
        corners.length <= _maxCornersForGreedyReduction) {
      if (isClosed) {
        final reducedToQuad = CornerDetector.reduceCornersGreedily(
          corners,
          target: 4,
        );
        final reducedQuad = _tryCornersAsQuadrilateral(
          reducedToQuad,
          simplifiedPoints,
          transformedStroke,
          maxEdgeBowRatio: _greedyReductionMaxEdgeBowRatio,
        );
        if (reducedQuad != null) return reducedQuad;
      }

      if (isClosed || almostClosed) {
        final reducedToTriangle = CornerDetector.reduceCornersGreedily(
          corners,
          target: 3,
        );
        final reducedTriangle = _tryCornersAsTriangle(
          reducedToTriangle,
          simplifiedPoints,
          transformedStroke,
          maxEdgeBowRatio: _greedyReductionMaxEdgeBowRatio,
        );
        if (reducedTriangle != null) return reducedTriangle;
      }
    }

    // 다각형 확인
    if (corners.length >= 5 && isClosed) {
      _createPolygonFromCorners(transformedStroke, corners, true);

      final polygonType = _determinePolygonType(corners);
      return ShapeDetectionResult(polygonType, transformedStroke);
    }

    // 직선 확인
    if (corners.length == 2) {
      transformedStroke.points.add(corners[0]);
      transformedStroke.points.add(corners[1]);
      return ShapeDetectionResult(.line, transformedStroke);
    }

    // 기본값: 폴리라인
    // 코너가 2개 미만이면 선분을 만들 수 없고, 분류 게이트를 통과하지 못한
    // 폐곡선을 코너 몇 점으로 축약하면 사용자가 그린 닫힘 변이 소실되므로
    // 단순화된 점들로 형태를 보존한다.
    final useSimplified = corners.length < 2 || isClosed || almostClosed;
    final fallbackPoints = useSimplified
        ? [
            ...simplifiedPoints,
            if ((isClosed || almostClosed) && simplifiedPoints.isNotEmpty)
              simplifiedPoints.first,
          ]
        : corners;
    _createPolylineFromCorners(transformedStroke, fallbackPoints);
    return ShapeDetectionResult(.polyline, transformedStroke);
  }

  /// 원/타원 여부 판별
  bool _isCircleOrEllipse(List<Point> points) {
    if (points.length < 8) return false;

    final characteristics = _calculateShapeCharacteristics(points);
    final center = characteristics.centroid;

    // 중심에서 각 점까지의 거리 분석
    final distances = points
        .map((point) => GeometryUtils.calculateDistance(center, point))
        .toList();

    final avgDistance = distances.reduce((a, b) => a + b) / distances.length;
    final variance =
        distances
            .map((dist) => math.pow(dist - avgDistance, 2))
            .reduce((a, b) => a + b) /
        distances.length;
    final stdDev = math.sqrt(variance);
    final stdDevRatio = stdDev / avgDistance;

    // 컨벡스 헐 점 비율
    final hullRatio = characteristics.convexHull.length / points.length;

    // 종횡비
    final aspectRatio = characteristics.aspectRatio;
    final adjustedAspectRatio = aspectRatio > 1 ? 1 / aspectRatio : aspectRatio;

    // 예리한 모서리 수 확인
    //
    // 예전에는 이 값을 별도의 크루드한 `_countSharpCorners`(고정 step으로
    // 원형 wrap 샘플링, 각도 임계 110°)로 계산했는데, 이 방법은
    // `_detectPolygonalShapes`가 신뢰하는 `CornerDetector`(같은 UB-555에서
    // 클러스터링으로 보강됨)와 **다른, 더 약한** 신호였다 — 원 판정 게이트가
    // 다각형 판정 게이트보다 먼저 실행되는데 더 부정확한 코너 신호를 쓰고
    // 있었던 것(UB-555 2차 원인). 다각형 경로와 **같은 방식**
    // (`CornerDetector`, 같은 perimeter 비례 클러스터 거리)으로 계산해
    // 두 경로의 코너 판정이 일관되게 만든다.
    //
    // `CornerDetector.detectSignificantCorners`를 그대로 재사용하지 않는
    // 이유: 그 함수는 다각형 분류용으로 "시작점 항상 코너 포함" +
    // "후보가 2개 미만이면 시작/중간/끝점으로 최소 3개 보장" 편향이 있어,
    // 진짜 원에도 코너 3개를 강제한다(진단 실측: jitter 0~3% 원 60/60
    // 시행 전부 "코너 3개"로 나옴 — 이 편향을 그대로 원 판정에 쓰면 진짜
    // 원의 cornerScore가 부당하게 깎여 회귀가 난다). 그래서 그 두 편향을
    // 제거한 `countCornerClusters`(순수 각도 기반, 순환 인덱싱)를 쓴다.
    final perimeter = GeometryUtils.calculatePolygonPerimeter(points);
    final cornerClusterDistance = math.max(10.0, perimeter * 0.03);

    final cornerClusterPoints = CornerDetector.cornerClusterPoints(
      points,
      minDistanceThreshold: cornerClusterDistance,
    );
    final sharpCorners = cornerClusterPoints.length;

    // 종합 점수 계산
    double hullScore = (hullRatio < 0.3)
        ? 1.0
        : math.max(0.0, 1.0 - (hullRatio - 0.3) * 2);
    double distanceScore = (stdDevRatio < 0.35)
        ? 1.0
        : math.max(0.0, 1.0 - (stdDevRatio - 0.35) * 2);
    double aspectScore = (adjustedAspectRatio > 0.5)
        ? 1.0
        : adjustedAspectRatio / 0.5;
    // 예리한 모서리가 실제로는 원/타원과 사각형·삼각형을 가르는 가장 강한
    // 신호인데, 종전 공식은 3개까지는 무조건 만점(1.0)을 주고 4개에서야
    // 0.667로 완만히 내려가 사각형(코너 4개)도 원으로 오분류됐다(UB-555).
    // 코너 1개당 선형으로 깎아 4개째에 이미 0에 수렴하도록 더 가파르게 한다.
    double cornerScore = math.max(0.0, 1.0 - sharpCorners * 0.25);

    // distanceScore·aspectScore는 사각형처럼 어느 정도 정사각에 가까운
    // 도형에서도 거의 항상 만점에 가까워 원/사각형을 가르지 못한다(#UB-555
    // 진단: 완벽한 직사각형도 두 항만으로 0.6점이 보장됨). 실제 판별력을
    // 가진 hullScore·cornerScore의 가중치를 높이고 나머지는 낮춘다.
    double circleScore =
        hullScore * 0.25 +
        distanceScore * 0.25 +
        aspectScore * 0.15 +
        cornerScore * 0.35;

    // ⚠️ 명확한 3~4코너 다각형(진짜 삼각형·사각형)에 대한 하드 베토는
    // 여기가 아니라 `detectAndTransform`의 원 판정 **이전** 단계
    // (`_tryPolygonVetoBeforeCircle`)에서 처리한다 — 그 관문이 통과하면
    // 원 판정 자체를 아예 시도하지 않고 다각형을 바로 구성해 반환하므로,
    // 이 함수가 다시 별도로 판단할 필요가 없다(중복 게이트 방지, 아래
    // `_tryPolygonVetoBeforeCircle` 주석 참조). 이 함수(및 그 안의
    // `cornerScore`)는 그 관문을 통과하지 못한(코너 0~2·5개 이상, 또는
    // 3~4개라도 직선 변·형태 검증에 실패한) 나머지 경우에 대한 연속
    // 가중치 판정만 담당한다.
    return circleScore > 0.65;
  }

  // 원 판정 전 다각형 코너 신뢰도 게이트에 쓰는 임계값 — 변의 중간 점이
  // 그 변의 시작-끝을 잇는 직선에서 이 비율(변 길이 대비 최대 수직 거리)
  // 이상 벗어나면 직선이 아니라 호(원의 일부)로 간주한다.
  static const double _polygonVetoMaxEdgeBowRatio = 0.06;

  /// 코너 사이 각 "변"이 실제로 직선에 가까운지 검사한다 (원/사각형·삼각형
  /// 오분류 방지 하드 베토의 일부, UB-555 2차).
  ///
  /// [traversalOrderCorners]는 `CornerDetector.detectSignificantCorners`가
  /// 돌려주는, **정렬하지 않은 원본 발견 순서**(=simplifiedPoints 안에서의
  /// 인덱스 오름차순, 즉 실제로 그려진 순서) 그대로여야 한다. 각도/변
  /// 길이 최종 분류에 쓰는 `_orderCornersPreservingDirection` 정렬본(중심
  /// 각도 기준 재배열)을 넘기면, 코너 사이 인덱스 구간이 실제로 그려진
  /// 변이 아니라 도형을 가로지르는 임의 구간을 가리킬 수 있어 이 검사가
  /// 무의미해진다 — 두 정렬은 서로 다른 목적이라 섞어 쓰면 안 된다.
  ///
  /// 세 점(또는 네 점)의 내각 합/각도만으로는 원 둘레에서 우연히 뽑힌
  /// 점들과 진짜 다각형 코너를 가르지 못한다(유클리드 항등식으로 3점의
  /// 내각 합은 항상 180도에 가깝다) — 원의 현(chord)은 그 위의 실제
  /// 궤적이 직선에서 크게 벗어나는 반면, 진짜 다각형의 변은 손떨림
  /// 잡음을 빼면 벗어남이 작다는 점으로 가른다.
  ///
  /// 마지막 코너에서 첫 코너로 되짚는 "닫힘 변"은 원본 점이 없는 합성
  /// 구간이라 검사하지 않는다 — 실제로 그려진 변들만으로도 충분한 신호다.
  ///
  /// [maxEdgeBowRatio]는 기본적으로 [_polygonVetoMaxEdgeBowRatio](0.06)를
  /// 쓰지만, 그리디 코너 축소(UB-555 3차)를 거친 후보를 검증할 때는 호출측
  /// (`_tryCornersAsTriangle`/`_tryCornersAsQuadrilateral`)이 더 느슨한
  /// [_greedyReductionMaxEdgeBowRatio]를 명시적으로 넘긴다 — 그 상수의
  /// 주석에 실측 근거가 있다.
  ///
  /// [requireSignCancellation]이 true면(UB-555 3차 — 원 판정 이전 관문의
  /// "완화된 bow-ratio 직접 재시도"에서만 켠다), 완화된 임계값만으로는
  /// 구분하지 못하는 두 경우를 추가로 가른다 — 지터(각 점이 독립적으로
  /// 좌우 무작위로 흔들림, 변을 따라 부호가 번갈아 상쇄됨)와 의도적인
  /// 곡률/볼록 변형(한 방향으로만 일관되게 부푼 변, 부호가 상쇄되지 않음).
  /// 완화 전 엄격한 임계값(0.06)은 어느 쪽도 통과시키지 않아 이 구분이
  /// 필요 없었지만, 완화된 임계값(0.14)은 순수 곡률로 만든 변(예: 변
  /// 길이의 8%만큼 한 방향으로 부푼 변)까지 통과시켜 "삼각형이 아닌
  /// 폐곡선(예: 세 변이 바깥으로 볼록한 폐곡선)이 삼각형으로 오분류"되는
  /// 회귀를 낳는다(실측: `shape_detector_test.dart`의 bulge=10 고정
  /// 회귀 테스트). 지터는 `Σ|d| ≈ |Σd|` 가 크게 벌어지는(부호가 상쇄돼
  /// `|Σd|` 가 `Σ|d|` 보다 훨씬 작은) 반면, 일관된 곡률은 `Σ|d| ≈ |Σd|`
  /// (거의 상쇄되지 않음)이다 — 이 비율로 둘을 가른다.
  bool _hasStraightPolygonEdges(
    List<Point> traversalOrderCorners,
    List<Point> simplifiedPoints, {
    double maxEdgeBowRatio = _polygonVetoMaxEdgeBowRatio,
    bool requireSignCancellation = false,
  }) {
    final indices = traversalOrderCorners
        .map((corner) => simplifiedPoints.indexOf(corner))
        .toList();

    for (var i = 0; i < indices.length - 1; i++) {
      final startIdx = indices[i];
      final endIdx = indices[i + 1];
      if (startIdx < 0 || endIdx < 0 || endIdx <= startIdx + 1) {
        // 코너를 못 찾았거나(있을 수 없지만 방어적으로), 사이에 검사할
        // 중간 점이 없으면(인접 인덱스) 통과시킨다 — 판단할 근거가 없다.
        continue;
      }

      final a = simplifiedPoints[startIdx];
      final b = simplifiedPoints[endIdx];
      final chordLength = GeometryUtils.calculateDistance(a, b);
      if (chordLength < 1e-6) continue;

      double maxDeviation = 0;
      var sumAbsDeviation = 0.0;
      var sumSignedDeviation = 0.0;
      for (var k = startIdx + 1; k < endIdx; k++) {
        final deviation = _perpendicularDistance(simplifiedPoints[k], a, b);
        if (deviation > maxDeviation) maxDeviation = deviation;
        if (requireSignCancellation) {
          final signed = _signedPerpendicularDistance(
            simplifiedPoints[k],
            a,
            b,
          );
          sumAbsDeviation += signed.abs();
          sumSignedDeviation += signed;
        }
      }

      if (maxDeviation / chordLength > maxEdgeBowRatio) {
        return false;
      }

      // 부호 상쇄 비율이 낮으면(=한 방향으로 일관되게 부풀었으면) 지터가
      // 아니라 의도적 곡률로 보고 거부한다. 편차가 거의 없는 변
      // (sumAbsDeviation ≈ 0)은 애초에 판단할 근거가 없으니 통과시킨다.
      if (requireSignCancellation && sumAbsDeviation > 1e-6) {
        final cancellationRatio = sumSignedDeviation.abs() / sumAbsDeviation;
        if (cancellationRatio > 0.5) {
          return false;
        }
      }
    }

    return true;
  }

  /// 점 [p]에서 직선 [a]-[b]까지의 수직 거리
  double _perpendicularDistance(Point p, Point a, Point b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return GeometryUtils.calculateDistance(p, a);
    }

    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared;
    final projX = a.x + t * dx;
    final projY = a.y + t * dy;
    final ddx = p.x - projX;
    final ddy = p.y - projY;
    return math.sqrt(ddx * ddx + ddy * ddy);
  }

  /// 점 [p]에서 직선 [a]-[b]까지의 **부호 있는** 수직 거리 —
  /// [_hasStraightPolygonEdges]의 [requireSignCancellation] 판정 전용.
  /// 부호는 [a]→[b] 방향 기준 왼쪽(+)/오른쪽(-)을 가리킨다(외적 부호).
  double _signedPerpendicularDistance(Point p, Point a, Point b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 1e-9) return 0.0;
    final cross = dx * (p.y - a.y) - dy * (p.x - a.x);
    return cross / length;
  }

  /// 타원 생성
  void _createEllipse(Stroke stroke, List<Point> points) {
    final characteristics = _calculateShapeCharacteristics(points);
    final center = characteristics.centroid;
    final boundingBox = characteristics.boundingBox;

    // 회전각 계산
    double rotation = _calculateRotation(points, center);

    // 타원 크기 계산
    double width = boundingBox.width;
    double height = boundingBox.height;

    // 원형에 가까울 경우 조정
    final aspectRatio = characteristics.aspectRatio;
    final isNearlyCircle = aspectRatio > 0.9 && aspectRatio < 1.1;

    if (isNearlyCircle) {
      final radius = math.max(width, height) / 2;
      width = radius * 2;
      height = radius * 2;
      rotation = 0;
    }

    // 타원 점 생성
    final numPoints = isNearlyCircle ? 36 : 48;
    _generateEllipsePoints(
      stroke,
      center,
      width / 2,
      height / 2,
      rotation,
      numPoints,
    );
  }

  /// 회전각 계산
  double _calculateRotation(List<Point> points, Point center) {
    double sumXY = 0, sumXX = 0, sumYY = 0;

    for (final point in points) {
      final dx = point.x - center.x;
      final dy = point.y - center.y;
      sumXX += dx * dx;
      sumYY += dy * dy;
      sumXY += dx * dy;
    }

    if (sumXY != 0) {
      return 0.5 * math.atan2(2 * sumXY, sumXX - sumYY);
    }
    return 0.0;
  }

  /// 타원 점 생성
  void _generateEllipsePoints(
    Stroke stroke,
    Point center,
    double radiusX,
    double radiusY,
    double rotation,
    int numPoints,
  ) {
    for (int i = 0; i <= numPoints; i++) {
      final angle = i * (2 * math.pi / numPoints);

      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      final cosRotation = math.cos(rotation);
      final sinRotation = math.sin(rotation);

      final x =
          center.x +
          radiusX * cosAngle * cosRotation -
          radiusY * sinAngle * sinRotation;
      final y =
          center.y +
          radiusX * cosAngle * sinRotation +
          radiusY * sinAngle * cosRotation;

      stroke.points.add(Point(x: x, y: y));
    }
  }

  /// 코너점으로 다각형 생성
  void _createPolygonFromCorners(
    Stroke stroke,
    List<Point> corners,
    bool close,
  ) {
    if (corners.length < 3 && close) {
      return;
    }

    // 원래 그린 순서를 유지하면서 정렬
    if (corners.length >= 3) {
      final orderedCorners = _orderCornersPreservingDirection(corners);
      stroke.points.addAll(orderedCorners);

      // 폐곡선이면 첫 점을 다시 추가하여 닫기
      if (close && orderedCorners.isNotEmpty) {
        stroke.points.add(orderedCorners.first);
      }

      _generateSegments(stroke, orderedCorners, close);
    }
  }

  /// 방향을 보존하며 코너 정렬
  List<Point> _orderCornersPreservingDirection(List<Point> corners) {
    if (corners.length <= 2) return corners;

    final originalCentroid = GeometryUtils.calculateCentroid(corners);

    if (corners.length == 3 || corners.length == 4) {
      final firstPoint = corners.first;
      final startAngle = math.atan2(
        firstPoint.y - originalCentroid.y,
        firstPoint.x - originalCentroid.x,
      );

      corners.sort((a, b) {
        final angleA =
            (math.atan2(a.y - originalCentroid.y, a.x - originalCentroid.x) -
                startAngle) %
            (2 * math.pi);
        final angleB =
            (math.atan2(b.y - originalCentroid.y, b.x - originalCentroid.x) -
                startAngle) %
            (2 * math.pi);
        return angleA.compareTo(angleB);
      });
    } else {
      corners.sort((a, b) {
        final angleA = math.atan2(
          a.y - originalCentroid.y,
          a.x - originalCentroid.x,
        );
        final angleB = math.atan2(
          b.y - originalCentroid.y,
          b.x - originalCentroid.x,
        );
        return angleA.compareTo(angleB);
      });
    }

    return corners;
  }

  /// 세그먼트 생성
  void _generateSegments(Stroke stroke, List<Point> corners, bool close) {
    for (int i = 0; i < corners.length; i++) {
      final segment = Segment()
        ..start = corners[i]
        ..end = corners[(i + 1) % corners.length];

      stroke.segments.add(segment);
    }

    if (!close && corners.length > 1) {
      stroke.segments.last.end = corners.last;
    }
  }

  /// 코너점으로 폴리라인 생성
  void _createPolylineFromCorners(Stroke stroke, List<Point> corners) {
    for (int i = 0; i < corners.length - 1; i++) {
      final segment = Segment()
        ..start = corners[i]
        ..end = corners[i + 1];

      stroke.segments.add(segment);
    }

    stroke.points.addAll(corners);
  }

  /// 폐곡선 여부 확인
  bool _isClosedShape(List<Point> points, double perimeter) {
    if (points.length < 3) return false;

    final distance = GeometryUtils.calculateDistance(points.first, points.last);
    final threshold = perimeter * _closedThreshold;

    // 추가 검증 로직
    if (distance < threshold && points.length > 10) {
      return _validateClosedShape(points, perimeter, distance, threshold);
    }

    return distance < threshold;
  }

  /// 폐곡선 검증
  bool _validateClosedShape(
    List<Point> points,
    double perimeter,
    double distance,
    double threshold,
  ) {
    final tenthOfLength = (points.length ~/ 10).toInt();
    final minSampleSize = math.min(5, tenthOfLength);

    final startVector = GeometryUtils.calculatePathDirection(
      points,
      0,
      minSampleSize,
    );
    final endStartIdx = points.length - minSampleSize - 1;
    final endEndIdx = points.length - 1;
    final endVector = GeometryUtils.calculatePathDirection(
      points,
      endStartIdx,
      endEndIdx,
    );

    final dotProduct =
        startVector.x * endVector.x + startVector.y * endVector.y;
    final magnitudeProduct =
        math.sqrt(
          startVector.x * startVector.x + startVector.y * startVector.y,
        ) *
        math.sqrt(endVector.x * endVector.x + endVector.y * endVector.y);

    if (magnitudeProduct > 0) {
      final cosAngle = (dotProduct / magnitudeProduct).clamp(-1.0, 1.0);
      final angleRad = math.acos(cosAngle);
      final angleDeg = angleRad * 180 / math.pi;

      if (angleDeg < 30 && distance > threshold * 0.5) {
        return false;
      }
    }

    if (perimeter > 500 && distance > threshold * 0.7) {
      return false;
    }

    return true;
  }

  /// 거의 폐곡선에 가까운지 확인
  bool _isAlmostClosed(List<Point> points, double perimeter) {
    if (points.length < 3) return false;

    final distance = GeometryUtils.calculateDistance(points.first, points.last);
    final threshold = perimeter * 0.25;

    return distance < threshold;
  }

  /// 도형 특성 계산
  ShapeCharacteristics _calculateShapeCharacteristics(List<Point> points) {
    if (points.isEmpty) {
      return ShapeCharacteristics(
        boundingBox: .zero,
        centroid: Point(x: 0, y: 0),
        aspectRatio: 1.0,
        convexHull: [],
      );
    }

    final boundingBox = GeometryUtils.calculateBoundingBox(points);
    final centroid = GeometryUtils.calculateCentroid(points);
    final perimeter = GeometryUtils.calculatePolygonPerimeter(points);
    final aspectRatio = boundingBox.width > 0
        ? boundingBox.height / boundingBox.width
        : 1.0;

    final simplifiedPoints = PointSimplifier.simplifyPoints(
      points,
      perimeter * 0.02,
    );
    final convexHull = ConvexHullCalculator.calculateConvexHull(
      simplifiedPoints,
    );
    return ShapeCharacteristics(
      boundingBox: boundingBox,
      centroid: centroid,
      aspectRatio: aspectRatio,
      convexHull: convexHull,
    );
  }

  /// 사각형 세부 유형 판별
  ShapeType _determineQuadrilateralType(List<Point> corners) {
    if (corners.length != 4) return .irregularQuadrilateral;

    final sides = _calculateSideLengths(corners);
    final angles = _calculateCornerAngles(corners);
    final isRightAngled = _isRightAngled(angles);

    // 변의 길이 비율 검사
    final maxSide = sides.reduce(math.max);
    final minSide = sides.reduce(math.min);
    final sideRatio = minSide / maxSide;

    // 정사각형 검사
    if (sideRatio > 0.9 && isRightAngled) {
      return .square;
    }

    // 다이아몬드 검사
    if (sideRatio > 0.9 && !isRightAngled) {
      final boundingBox = GeometryUtils.calculateBoundingBox(corners);
      final aspectRatio = boundingBox.width / boundingBox.height;

      if (aspectRatio > 0.8 && aspectRatio < 1.2) {
        return .diamond;
      }
    }

    // 직사각형 검사
    if (isRightAngled && _hasParallelSides(sides)) {
      return .rectangle;
    }

    return .irregularQuadrilateral;
  }

  /// 변의 길이 계산
  List<double> _calculateSideLengths(List<Point> corners) {
    final sides = <double>[];
    for (int i = 0; i < corners.length; i++) {
      final next = (i + 1) % corners.length;
      sides.add(GeometryUtils.calculateDistance(corners[i], corners[next]));
    }
    return sides;
  }

  /// 코너 각도 계산
  List<double> _calculateCornerAngles(List<Point> corners) {
    final angles = <double>[];
    for (int i = 0; i < corners.length; i++) {
      final prev = corners[(i - 1 + corners.length) % corners.length];
      final curr = corners[i];
      final next = corners[(i + 1) % corners.length];
      angles.add(GeometryUtils.calculateCornerAngle(prev, curr, next));
    }
    return angles;
  }

  /// 직각인지 확인
  ///
  /// 손그림 코너는 둥글게 말리거나 손떨림으로 흔들려 대표 코너점이 정확히
  /// 90도로 잡히지 않는다. ±15도(75~105)는 화면 위 자유 곡선 드로잉에는
  /// 너무 엄격해 멀쩡한 사각형이 `irregularQuadrilateral` 로 떨어졌다
  /// (UB-555). 다각형 오각형·삼각형 오분류를 막는 `_hasParallelSides` 와
  /// 함께 걸리므로 ±22도로 완화해도 무관한 사각형(마름모 등)과의 경계는
  /// 변 길이 비율 검사가 여전히 지킨다.
  bool _isRightAngled(List<double> angles) {
    return angles.every((angle) => angle >= 68 && angle <= 112);
  }

  /// 평행한 변이 있는지 확인
  ///
  /// 10% 허용치는 손으로 그린 변의 길이 차를 거의 허용하지 않는다.
  /// 18%로 완화해도 마름모(다이아몬드)는 `sideRatio > 0.9` 검사에서 먼저
  /// 갈리므로 서로 혼동되지 않는다.
  bool _hasParallelSides(List<double> sides) {
    return (sides[0] - sides[2]).abs() / math.max(sides[0], sides[2]) < 0.18 &&
        (sides[1] - sides[3]).abs() / math.max(sides[1], sides[3]) < 0.18;
  }

  /// 삼각형 세부 유형 판별
  ShapeType _determineTriangleType(List<Point> corners) {
    if (corners.length != 3) return .irregularTriangle;

    final sides = _calculateSideLengths(corners);
    final angles = _calculateCornerAngles(corners);

    // 직각 삼각형 검사
    if (angles.any((angle) => angle >= 85 && angle <= 95)) {
      return .rightTriangle;
    }

    // 정삼각형 검사
    final maxSide = sides.reduce(math.max);
    final minSide = sides.reduce(math.min);
    final sideRatio = minSide / maxSide;

    if (sideRatio > 0.9) {
      return .equilateralTriangle;
    }

    // 이등변 삼각형 검사
    final sortedSides = List<double>.of(sides)..sort();
    if ((sortedSides[0] / sortedSides[1]) > 0.9 ||
        (sortedSides[1] / sortedSides[2]) > 0.9) {
      return .isoscelesTriangle;
    }

    return .irregularTriangle;
  }

  /// 다각형 세부 유형 판별
  ShapeType _determinePolygonType(List<Point> corners) {
    switch (corners.length) {
      case 5:
        return .pentagon;
      case 6:
        return .hexagon;
      default:
        return .polygon;
    }
  }

  /// 원/타원 세부 유형 판별
  ShapeType _determineEllipseType(List<Point> points) {
    final characteristics = _calculateShapeCharacteristics(points);
    final aspectRatio = characteristics.aspectRatio;

    return aspectRatio >= 0.9 && aspectRatio <= 1.1 ? .circle : .ellipse;
  }
}
