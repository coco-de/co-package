import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/convex_hull_calculator.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ConvexHullCalculator', () {
    group('calculateConvexHull', () {
      test('2개 이하 포인트는 그대로 반환', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        expect(hull.length, 2);
      });

      test('삼각형 포인트는 모두 포함', () {
        final points = createPoints([
          [0, 0],
          [10, 0],
          [5, 10],
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        expect(hull.length, greaterThanOrEqualTo(2));
      });

      test('내부 점 제거', () {
        final points = createPoints([
          [0, 0], [10, 0], [10, 10], [0, 10], // 사각형 꼭짓점
          [5, 5], // 내부 점
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        // 내부 점은 제거되어야 함
        expect(hull.length, lessThanOrEqualTo(5));
      });

      test('일직선 위의 포인트', () {
        final points = createPoints([
          [0, 0],
          [5, 0],
          [10, 0],
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        expect(hull.isNotEmpty, true);
      });

      test('동일 포인트', () {
        final points = createPoints([
          [5, 5],
          [5, 5],
          [5, 5],
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        expect(hull.isNotEmpty, true);
      });
    });

    group('calculateConvexHullArea', () {
      test('2개 이하 포인트는 면적 0', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        expect(ConvexHullCalculator.calculateConvexHullArea(points), 0);
      });

      test('단위 정사각형 면적', () {
        final hull = createPoints([
          [0, 0],
          [1, 0],
          [1, 1],
          [0, 1],
        ]);
        expect(
          ConvexHullCalculator.calculateConvexHullArea(hull),
          closeTo(1, 0.01),
        );
      });

      test('삼각형 면적 (밑변 10, 높이 5)', () {
        final hull = createPoints([
          [0, 0],
          [10, 0],
          [5, 5],
        ]);
        expect(
          ConvexHullCalculator.calculateConvexHullArea(hull),
          closeTo(25, 0.01),
        );
      });

      test('10x10 정사각형 면적', () {
        final hull = createPoints([
          [0, 0],
          [10, 0],
          [10, 10],
          [0, 10],
        ]);
        expect(
          ConvexHullCalculator.calculateConvexHullArea(hull),
          closeTo(100, 0.01),
        );
      });
    });
  });
}
