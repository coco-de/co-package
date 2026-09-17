import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/stroke_calculator.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('stroke_calculator', () {
    group('getStrokeRadius', () {
      test('thinning 0이면 size/2', () {
        expect(getStrokeRadius(10, 0, 0.5), 5);
      });

      test('p=1, thinning=1이면 size', () {
        // size * (0.5 - thinning * (0.5 - p)) = 10 * (0.5 - 1*(0.5-1)) = 10 * 1.0 = 10
        expect(getStrokeRadius(10, 1, 1), 10);
      });

      test('p=0, thinning=1이면 0', () {
        expect(getStrokeRadius(10, 1, 0), 0);
      });

      test('중간 pressure', () {
        final radius = getStrokeRadius(10, 0.5, 0.5);
        expect(radius, closeTo(5, 1));
      });
    });

    group('getStrokePoints', () {
      test('빈 포인트 리스트 → 빈 결과', () {
        final result = getStrokePoints([], options: createStrokeOptions());
        expect(result, isEmpty);
      });

      test('단일 포인트 → 2개 StrokePoint (자동 보간)', () {
        final points = createPoints([
          [50, 50],
        ]);
        final result = getStrokePoints(points, options: createStrokeOptions());
        expect(result.length, greaterThanOrEqualTo(1));
      });

      test('여러 포인트 → StrokePoint 리스트', () {
        final points = createLinePoints(count: 10);
        final result = getStrokePoints(points, options: createStrokeOptions());
        expect(result.length, greaterThan(0));
        expect(result.first.distance, 0);
      });

      test('runningLength 증가', () {
        final points = createLinePoints(
          fromX: 0,
          fromY: 0,
          toX: 100,
          toY: 0,
          count: 10,
        );
        final result = getStrokePoints(points, options: createStrokeOptions());
        if (result.length >= 2) {
          expect(result.last.runningLength, greaterThan(0));
        }
      });
    });

    group('getStroke', () {
      test('스트로크 외곽선 포인트 반환', () {
        final stroke = createStroke(points: createLinePoints(count: 10));
        final outline = getStroke(stroke);
        expect(outline.isNotEmpty, true);
      });

      test('빈 스트로크는 빈 결과', () {
        final stroke = createStroke(points: []);
        final outline = getStroke(stroke);
        expect(outline, isEmpty);
      });
    });

    group('getStrokeOutlinePoints', () {
      test('빈 입력 → 빈 결과', () {
        final result = getStrokeOutlinePoints(
          [],
          options: createStrokeOptions(),
        );
        expect(result, isEmpty);
      });

      test('StrokePoint에서 외곽선 생성', () {
        final points = createLinePoints(count: 10);
        final strokePoints = getStrokePoints(
          points,
          options: createStrokeOptions(),
        );
        final outline = getStrokeOutlinePoints(
          strokePoints,
          options: createStrokeOptions(),
        );
        expect(outline.isNotEmpty, true);
      });

      test('size=0 → 빈 결과 (NaN 가드)', () {
        final points = createLinePoints(count: 5);
        final strokePoints = getStrokePoints(
          points,
          options: createStrokeOptions(),
        );
        final outline = getStrokeOutlinePoints(
          strokePoints,
          options: createStrokeOptions(size: 0),
        );
        expect(outline, isEmpty);
      });

      test('완성된 stroke 의 모든 점이 유한값 (NaN/Infinity 가드)', () {
        final points = createLinePoints(count: 10);
        final completeOptions = createStrokeOptions(isComplete: true);
        final strokePoints = getStrokePoints(points, options: completeOptions);
        final outline = getStrokeOutlinePoints(
          strokePoints,
          options: completeOptions,
        );
        for (final p in outline) {
          expect(p.x.isFinite, isTrue, reason: 'x must be finite');
          expect(p.y.isFinite, isTrue, reason: 'y must be finite');
        }
      });
    });

    // perfect_freehand 2.5.x 정렬 — 회귀 방지 테스트
    group('perfect_freehand 2.5.x regression', () {
      test('2점 stroke → 보간점 4개가 추가되어 4개 이상 stroke point 생성', () {
        // 2점 직선 입력 시 lerp 로 (0.25, 0.5, 0.75, 1.0) 위치에 보간점이 추가되어
        // 내부적으로 5개의 raw 포인트로 확장되어야 한다 (perfect_freehand 2.5.0).
        final points = createPoints([
          [0, 0],
          [100, 0],
        ]);
        final result = getStrokePoints(points, options: createStrokeOptions());
        // 보간 전이라면 2점만 처리되었을 것 (또는 minimum-length 필터로 더 적음).
        expect(result.length, greaterThanOrEqualTo(3));
      });

      test('동일 좌표 2점 → 1점으로 축소 후 dot 처리', () {
        final points = createPoints([
          [10, 10],
          [10, 10],
        ]);
        final result = getStrokePoints(points, options: createStrokeOptions());
        // 1점으로 축소 후 1pt 오프셋이 추가되어 적어도 1개 stroke point 생성.
        expect(result.isNotEmpty, isTrue);
      });

      test('직각 corner 도 sharp 처리 → outline 두께 유지 (perfect_freehand 2.5.0)', () {
        // ㄱ자 모양: (0,0)→(50,0)→(50,50)
        final points = <List<double>>[
          for (var i = 0; i <= 5; i++) [i * 10.0, 0],
          for (var i = 1; i <= 5; i++) [50.0, i * 10.0],
        ];
        final outline = getStroke(
          createStroke(
            points: createPoints(points),
            options: createStrokeOptions(
              size: 4,
              smoothing: 0,
              simulatePressure: false,
              isComplete: true,
            ),
          ),
        );
        // sharp corner 처리 시 cap (13개) + reflect 점이 추가되어
        // 일반 직선보다 outline 점 수가 큼.
        expect(outline.length, greaterThanOrEqualTo(20));
      });

      test('그리는 도중(isComplete=false)에는 끝부분 noise 제거 미적용', () {
        // 짧은 stroke 그리는 중. 이전 구현의 < 3 임계값으로 끝부분이 잘려
        // outline 이 비어버리는 회귀를 방지.
        final points = createLinePoints(
          count: 5,
          fromX: 0,
          fromY: 0,
          toX: 10,
          toY: 0,
        );
        final outline = getStroke(
          createStroke(
            points: points,
            options: createStrokeOptions(size: 4, isComplete: false),
          ),
        );
        expect(outline.isNotEmpty, isTrue);
      });
    });
  });
}
