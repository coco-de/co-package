import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';

import '../../helpers/test_helpers.dart';

/// UB-555 회귀 테스트 — "자유 도형" 모드에서 도형을 세밀하게 그리지 않아도
/// (모서리가 둥글게 말리거나 손떨림이 섞여도) 원하는 도형으로 인식되는지
/// 검증한다.
///
/// 여기 쓰인 케이스는 손 떨림/모서리 라운딩을 흉내낸 무작위 시드(50개)
/// 스윕에서 fix 이전 알고리즘이 실제로 오분류했던 지점을 그대로 고정한
/// 것이다 — "적당히 그럴듯한 값" 이 아니라 실측 재현 사례다.
void main() {
  group('ShapeDetector 손그림 민감도 (UB-555)', () {
    test('모서리가 둥글게 말린 사각형도 rectangle로 인식된다', () {
      // cornerRadiusRatio 0.16 — 변경 전에는 코너 클러스터링이 없어
      // 라운딩된 모서리가 여러 개의 얕은 꺾임으로 쪼개져
      // irregularQuadrilateral 로 떨어졌다.
      final points = handDrawnRectanglePoints(
        left: 0,
        top: 0,
        right: 200,
        bottom: 140,
        rng: math.Random(0),
        jitterRatio: 0.0,
        cornerRadiusRatio: 0.16,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, isIn([ShapeType.rectangle, ShapeType.square]));
    });

    test('손떨림이 섞인 사각형이 원/타원으로 오분류되지 않는다', () {
      // cornerRadiusRatio 0.10 + jitterRatio 0.02 — 변경 전에는 단순화 후
      // 점 개수가 원/타원 감지 게이트(8개)를 넘기면 circleScore 공식의
      // distance/aspect 항이 사실상 항상 만점에 가까워 사각형도 ellipse로
      // 판정됐다.
      final points = handDrawnRectanglePoints(
        left: 0,
        top: 0,
        right: 200,
        bottom: 140,
        rng: math.Random(5),
        jitterRatio: 0.02,
        cornerRadiusRatio: 0.10,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, isIn([ShapeType.rectangle, ShapeType.square]));
    });

    test('손떨림이 섞인 삼각형이 원/타원으로 오분류되지 않는다', () {
      final points = handDrawnTrianglePoints(
        vertices: [
          [0, 0],
          [140, 0],
          [70, 121],
        ],
        rng: math.Random(2),
        jitterRatio: 0.03,
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

    test('진짜 원은 여전히 circle로 인식된다 (회귀 방지)', () {
      // circleScore 공식을 사각형 오분류를 막는 방향으로 재조정했으므로,
      // 진짜 원/타원 인식이 함께 깨지지 않는지 반드시 함께 고정해야 한다.
      final points = handDrawnCirclePoints(
        centerX: 100,
        centerY: 100,
        radius: 80,
        rng: math.Random(9),
        jitterRatio: 0.03,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, ShapeType.circle);
    });

    test('손그림 사각형 100회 시도 중 다수가 rectangle로 인식된다', () {
      // 개별 결정적 케이스뿐 아니라 넓은 분포에서도 개선됐는지 확인하는
      // 통계적 가드. 임계값은 fix 이전 실측(31/100)보다 넉넉히 높게 잡아
      // 알고리즘이 조금만 흔들려도 깨지지 않게 한다.
      final rng = math.Random(42);
      var rectangleCount = 0;
      const trials = 100;
      for (var i = 0; i < trials; i++) {
        final points = handDrawnRectanglePoints(
          left: 0,
          top: 0,
          right: 200,
          bottom: 140,
          rng: rng,
        );
        final stroke = createStroke(points: points, ink: 'shape');
        final result = ShapeDetector.instance.detectAndTransform(stroke);
        if (result.shapeType == ShapeType.rectangle ||
            result.shapeType == ShapeType.square) {
          rectangleCount++;
        }
      }

      expect(rectangleCount, greaterThanOrEqualTo(60));
    });
  });
}
