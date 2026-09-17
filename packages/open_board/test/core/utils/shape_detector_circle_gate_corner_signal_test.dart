import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';

import '../../helpers/test_helpers.dart';

/// UB-555 2차 회귀 테스트 — 원/타원 판정(`_isCircleOrEllipse`)이 다각형
/// 판정과 다른(더 약한) 코너 신호를 써서, 손떨림·모서리 라운딩이 섞인
/// 삼각형·사각형이 여전히 circle/ellipse 로 새는 문제를 고정한다.
///
/// #263(1차 UB-555)이 다각형 경로(`CornerDetector`)의 코너 클러스터링을
/// 고쳤지만, 원 판정 경로가 먼저 실행되면서 그 개선을 못 보고 자체적으로
/// 크루드한(고정 step, 다른 각도 임계값) 코너 카운터를 썼다 — 그 결과
/// 다각형 경로라면 코너 3~4개로 정확히 잡았을 도형도 원 판정 게이트에서
/// 코너가 적게 잡혀 circleScore 가 부당하게 높게 나왔다.
///
/// 여기 쓰인 시드는 "적당히 그럴듯한 값" 이 아니라, fix 이전 코드에서
/// 실제로 circle/ellipse 로 오분류됐던 지점을 그대로 고정한 것이다
/// (검증: 이 fix 를 되돌린 상태로 같은 시드를 돌리면 circle 이 나온다).
void main() {
  group('ShapeDetector 원 판정 코너 신호 일관성 (UB-555 2차)', () {
    test('손떨림이 섞인 삼각형이 circle로 새지 않는다 (실측 오분류 시드)', () {
      // seed=2, jitterRatio=0.04 — fix 이전에는 원 판정 경로의 크루드한
      // 코너 카운터가 이 삼각형의 코너를 충분히 잡지 못해 circleScore가
      // 게이트(0.65)를 넘어 circle로 오분류됐다.
      final points = handDrawnTrianglePoints(
        vertices: [
          [0, 0],
          [160, 10],
          [80, 150],
        ],
        rng: math.Random(2),
        jitterRatio: 0.04,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(
        result.shapeType,
        isIn([
          ShapeType.triangle,
          ShapeType.rightTriangle,
          ShapeType.equilateralTriangle,
          ShapeType.isoscelesTriangle,
          ShapeType.irregularTriangle,
        ]),
      );
    });

    test('둥글게 그린 사각형이 circle 대신 rectangle로 인식된다 (실측 오분류 시드)', () {
      // seed=16, cornerRadiusRatio=0.12, jitterRatio=0.02 — fix 이전에는
      // 동일한 이유로 circle 오분류, fix 이후에는 하드 베토
      // (`evaluateTriangleShape`/`_isRightAngled`+`_hasParallelSides` 재사용)
      // 가 다각형 경로와 같은 검증으로 circle 판정을 거부하고 rectangle로
      // 넘긴다.
      final points = handDrawnRectanglePoints(
        left: 0,
        top: 0,
        right: 160,
        bottom: 160,
        rng: math.Random(16),
        jitterRatio: 0.02,
        cornerRadiusRatio: 0.12,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, isIn([ShapeType.rectangle, ShapeType.square]));
    });

    test('진짜 원은 지터가 커도(jitter 3%) 200회 전부 circle로 인식된다 (회귀 방지)', () {
      // 코너 신호를 다각형 경로와 일관되게 맞추고 하드 베토를 추가하는
      // 과정에서, 노이즈가 우연히 코너 3~4개로 잡히는 진짜 원까지 걸러질
      // 위험이 가장 큰 회귀 지점이었다. 200개 시드 전수에서 하나도 새지
      // 않아야 한다 — 하나라도 실패하면 하드 베토가 너무 공격적으로
      // 재조정된 것이다.
      for (var seed = 0; seed < 200; seed++) {
        final points = handDrawnCirclePoints(
          centerX: 100,
          centerY: 100,
          radius: 80,
          rng: math.Random(seed),
          jitterRatio: 0.03,
        );
        final stroke = createStroke(points: points, ink: 'shape');
        final result = ShapeDetector.instance.detectAndTransform(stroke);

        expect(
          result.shapeType,
          ShapeType.circle,
          reason: 'seed=$seed 에서 진짜 원이 ${result.shapeType} 로 오분류됐다',
        );
      }
    });

    test('손떨림이 섞인 삼각형(jitter 4%) 200회 시도 중 circle 오분류가 실측 대비 크게 줄어든다', () {
      // 개별 결정적 케이스뿐 아니라 넓은 분포에서도 개선됐는지 확인하는
      // 통계적 가드. fix 이전 실측: 200개 시드 중 50개(25%)가 circle로
      // 오분류됐다. 임계값은 그 절반보다 넉넉히 낮게(20개, 10%) 잡아
      // 알고리즘이 조금만 흔들려도 깨지지 않게 한다.
      var circleCount = 0;
      const trials = 200;
      for (var seed = 0; seed < trials; seed++) {
        final points = handDrawnTrianglePoints(
          vertices: [
            [0, 0],
            [160, 10],
            [80, 150],
          ],
          rng: math.Random(seed),
          jitterRatio: 0.04,
        );
        final stroke = createStroke(points: points, ink: 'shape');
        final result = ShapeDetector.instance.detectAndTransform(stroke);
        if (result.shapeType == ShapeType.circle ||
            result.shapeType == ShapeType.ellipse) {
          circleCount++;
        }
      }

      expect(circleCount, lessThanOrEqualTo(20));
    });

    test('명확한 3~4코너 다각형은 원 판정 자체를 거치지 않고 직접 구성된다 '
        '(실측 오분류 시드, UB-555 2차 합성)', () {
      // seed=3004, jitterRatio=0.04 — 위 코너 신호 통일(#0e09546)만으로는
      // 이 케이스가 여전히 ellipse로 샜다: 3점의 내각 합은 유클리드
      // 항등식상 항상 180도에 가까워, 원 둘레에서 우연히 뽑힌 점들도
      // 삼각형처럼 보이는 각도를 가질 수 있기 때문이다(코너 "개수"만
      // 보정해서는 못 잡는 함정). `detectAndTransform`이 원 판정
      // **이전**에 `_tryPolygonVetoBeforeCircle`로 명확한 3~4코너
      // 다각형을 먼저 확정하고, 그 관문이 `_hasStraightPolygonEdges`
      // (코너 사이 실제 궤적이 직선에서 크게 벗어나면 거부 — 원의 현은
      // 벗어나고 다각형의 변은 벗어나지 않는다)로 이 함정을 걸러낸
      // 뒤에야 이 시드가 고쳐졌다.
      final points = handDrawnTrianglePoints(
        vertices: [
          [0, 0],
          [140, 0],
          [70, 121],
        ],
        rng: math.Random(3004),
        jitterRatio: 0.04,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(
        result.shapeType,
        isIn([
          ShapeType.triangle,
          ShapeType.rightTriangle,
          ShapeType.equilateralTriangle,
          ShapeType.isoscelesTriangle,
          ShapeType.irregularTriangle,
        ]),
      );
    });

    test('손떨림이 섞인 삼각형(jitter 4%) circle/ellipse 오분류가 코너 신호 '
        '통일만 했을 때보다 더 줄어든다 (UB-555 2차 합성)', () {
      // 바로 위 통계 가드(코너 신호 통일 직후 실측: 200개 중 ≤20개)보다
      // 한 단계 더 강한 상한이다 — 다각형 선-베토(bow-ratio 직선 변
      // 검증 포함)가 유클리드 항등식 함정으로 새던 나머지를 추가로
      // 막았는지 고정한다. 임계값은 이 fix 시점 실측(0개)보다 넉넉히
      // 높게(5개) 잡아 알고리즘이 조금만 흔들려도 깨지지 않게 한다.
      var circleCount = 0;
      const trials = 200;
      for (var seed = 0; seed < trials; seed++) {
        final points = handDrawnTrianglePoints(
          vertices: [
            [0, 0],
            [160, 10],
            [80, 150],
          ],
          rng: math.Random(seed),
          jitterRatio: 0.04,
        );
        final stroke = createStroke(points: points, ink: 'shape');
        final result = ShapeDetector.instance.detectAndTransform(stroke);
        if (result.shapeType == ShapeType.circle ||
            result.shapeType == ShapeType.ellipse) {
          circleCount++;
        }
      }

      expect(circleCount, lessThanOrEqualTo(5));
    });
  });
}
