import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

import '../../helpers/test_helpers.dart';

/// UB-555 3차 회귀 테스트 — 지터(손떨림)가 커질수록 `CornerDetector`가
/// 진짜 코너 수(삼각형=3, 사각형=4)보다 훨씬 많은 코너를 검출해
/// 오각형·육각형·다각형으로 오분류되는 문제를 고정한다.
///
/// 1·2차(#263, #264)는 "원으로 새는" 문제를 막았지만, 지터가 만드는
/// 국소적인 짧은 방향 반전이 코너 각도 문턱(120도)을 반복적으로 넘어
/// 코너를 과다 검출하는 문제는 남아 있었다 — 실사용 피드백: "삼각형,
/// 사각형을 신경써서 그려야 하는 문제는 기존이랑 크게 차이가 없어".
///
/// 진단(코너 개수 분포 실측, seedBase=9000): jitter 6%에서 삼각형이 5~10개,
/// 사각형이 5~7개 코너로 잡히는 것을 확인했고, 이 초과분이 그대로
/// pentagon/hexagon/polygon/irregularQuadrilateral 오분류로 이어졌다.
///
/// 3가지 독립 전략(넓은 윈도우 각도 추정 · 적응형 사전 단순화 · 코너 사후
/// 축소)을 병렬 구현·실측 비교한 뒤, 파이프라인의 서로 다른 단계에
/// 개입하는 두 전략(넓은 윈도우 각도 추정 + 코너 사후 축소)을 합성했다 —
/// 둘 중 어느 하나만으로는 얻지 못하는 개선을 함께 냈다(각 개별 전략보다
/// 사각형·삼각형 합산 성공률이 모두 높다).
///
/// 여기 쓰인 시드는 "적당히 그럴듯한 값"이 아니라, 1·2차만 반영된 코드에서
/// 실제로 오분류됐던 지점을 그대로 고정한 것이다(검증: 이 fix를 되돌린
/// 상태로 같은 시드를 돌리면 hexagon/pentagon/polygon이 나온다).
void main() {
  group('ShapeDetector 코너 과다 검출 방지 (UB-555 3차)', () {
    test('지터가 큰 삼각형이 hexagon으로 새지 않는다 (실측 오분류 시드)', () {
      // seed=3008, jitterRatio=0.06 — 1·2차만 반영된 코드에서는
      // CornerDetector가 이 궤적에서 6개 코너를 검출해 hexagon으로
      // 오분류했다.
      final points = handDrawnTrianglePoints(
        vertices: [
          [0, 0],
          [140, 0],
          [70, 121],
        ],
        rng: math.Random(3008),
        jitterRatio: 0.06,
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

    test('지터가 큰 사각형이 hexagon으로 새지 않는다 (실측 오분류 시드)', () {
      // seed=1006, jitterRatio=0.06 — 1·2차만 반영된 코드에서는 hexagon으로
      // 오분류됐다.
      final points = handDrawnRectanglePoints(
        left: 0,
        top: 0,
        right: 160,
        bottom: 160,
        rng: math.Random(1006),
        jitterRatio: 0.06,
        cornerRadiusRatio: 0.08,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, isIn([ShapeType.rectangle, ShapeType.square]));
    });

    test('모서리가 크게 둥근 사각형이 pentagon으로 새지 않는다 (실측 오분류 시드)', () {
      // seed=2023, cornerRadiusRatio=0.16, jitterRatio=0.02 — 1·2차만
      // 반영된 코드에서는 pentagon으로 오분류됐다.
      final points = handDrawnRectanglePoints(
        left: 0,
        top: 0,
        right: 160,
        bottom: 160,
        rng: math.Random(2023),
        jitterRatio: 0.02,
        cornerRadiusRatio: 0.16,
      );
      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, isIn([ShapeType.rectangle, ShapeType.square]));
    });

    test('진짜 원은 지터가 커도(jitter 3%) 200회 전부 circle로 인식된다 (회귀 방지)', () {
      // 3차에서 추가한 완화된 bow-ratio 재시도(코너 개수가 정확히 3·4개일
      // 때도 완화된 임계값으로 재검증)가 원 판정 보호를 침해하지 않는지
      // 반드시 함께 고정해야 한다.
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

    test('지터 6% 삼각형 150회 시도 중 다수가 삼각형으로 인식된다 (통계적 가드)', () {
      // 개별 결정적 케이스뿐 아니라 넓은 분포에서도 개선됐는지 확인하는
      // 통계적 가드. 1·2차만 반영된 코드에서의 실측: 150개 중 6개(4%)만
      // 삼각형으로 인식됐다. 임계값은 이 fix 시점 실측(68/150, 45%)보다
      // 낮게(40개, 27%) 잡아 알고리즘이 조금만 흔들려도 깨지지 않게 한다.
      var success = 0;
      const trials = 150;
      for (var i = 0; i < trials; i++) {
        final rng = math.Random(3006 + i);
        final points = handDrawnTrianglePoints(
          vertices: [
            [0, 0],
            [140, 0],
            [70, 121],
          ],
          rng: rng,
          jitterRatio: 0.06,
        );
        final stroke = createStroke(points: points, ink: 'shape');
        final result = ShapeDetector.instance.detectAndTransform(stroke);
        if (result.shapeType == ShapeType.triangle ||
            result.shapeType == ShapeType.rightTriangle ||
            result.shapeType == ShapeType.equilateralTriangle ||
            result.shapeType == ShapeType.isoscelesTriangle ||
            result.shapeType == ShapeType.irregularTriangle) {
          success++;
        }
      }

      expect(success, greaterThanOrEqualTo(40));
    });

    test('지터 6% 사각형 150회 시도 중 다수가 사각형으로 인식된다 (통계적 가드)', () {
      // 1·2차만 반영된 코드에서의 실측: 150개 중 35개(23%)만 사각형으로
      // 인식됐다. 임계값은 이 fix 시점 실측(123/150, 82%)보다 낮게(100개,
      // 67%) 잡는다.
      var success = 0;
      const trials = 150;
      for (var i = 0; i < trials; i++) {
        final rng = math.Random(1006 + i);
        final points = handDrawnRectanglePoints(
          left: 0,
          top: 0,
          right: 160,
          bottom: 160,
          rng: rng,
          jitterRatio: 0.06,
          cornerRadiusRatio: 0.08,
        );
        final stroke = createStroke(points: points, ink: 'shape');
        final result = ShapeDetector.instance.detectAndTransform(stroke);
        if (result.shapeType == ShapeType.rectangle ||
            result.shapeType == ShapeType.square) {
          success++;
        }
      }

      expect(success, greaterThanOrEqualTo(100));
    });

    test('세 변이 바깥으로 볼록한 폐곡선(비-지터)은 여전히 삼각형으로 스냅되지 않는다', () {
      // 3차에서 추가한 완화된 bow-ratio 재시도는 "지터로 흔들린 직선"만
      // 통과시켜야 하고, 의도적으로 한쪽으로 볼록하게 그린 폐곡선(지터가
      // 아니라 진짜 곡률)은 여전히 거부해야 한다 — 부호 상쇄 검증
      // (`requireSignCancellation`)이 이를 가른다. 변 길이 대비 8.3%
      // 볼록(완화된 bow-ratio 0.14보다는 작지만 엄격한 0.06보다는 큼)한
      // 폐곡선으로, 완화된 bow-ratio만 있었다면(부호 상쇄 검증 없이)
      // 삼각형으로 잘못 통과했을 케이스다.
      final vertices = [
        [0.0, 0.0],
        [120.0, 0.0],
        [60.0, 104.0],
      ];
      final center = [60.0, 34.7];
      final points = <Point>[];
      for (var v = 0; v < vertices.length; v++) {
        final a = vertices[v];
        final b = vertices[(v + 1) % vertices.length];
        final mx = (a[0] + b[0]) / 2;
        final my = (a[1] + b[1]) / 2;
        final ox = mx - center[0];
        final oy = my - center[1];
        final len = math.sqrt(ox * ox + oy * oy);
        for (var i = 0; i < 20; i++) {
          final t = i / 20;
          final sag = len > 0 ? math.sin(t * math.pi) * 10 : 0.0;
          points.add(
            Point(
              x: a[0] + (b[0] - a[0]) * t + (len > 0 ? ox / len * sag : 0),
              y: a[1] + (b[1] - a[1]) * t + (len > 0 ? oy / len * sag : 0),
            ),
          );
        }
      }
      points.add(Point(x: vertices.first[0], y: vertices.first[1]));

      final stroke = createStroke(points: points, ink: 'shape');
      final result = ShapeDetector.instance.detectAndTransform(stroke);

      expect(result.shapeType, ShapeType.polyline);
    });
  });
}
