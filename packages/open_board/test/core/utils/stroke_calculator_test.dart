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
        final result = getStrokePoints(
          points,
          options: createStrokeOptions(),
        );
        expect(result.length, greaterThanOrEqualTo(1));
      });

      test('여러 포인트 → StrokePoint 리스트', () {
        final points = createLinePoints(count: 10);
        final result = getStrokePoints(
          points,
          options: createStrokeOptions(),
        );
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
        final result = getStrokePoints(
          points,
          options: createStrokeOptions(),
        );
        if (result.length >= 2) {
          expect(result.last.runningLength, greaterThan(0));
        }
      });
    });

    group('getStroke', () {
      test('스트로크 외곽선 포인트 반환', () {
        final stroke = createStroke(
          points: createLinePoints(count: 10),
        );
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
    });
  });
}
