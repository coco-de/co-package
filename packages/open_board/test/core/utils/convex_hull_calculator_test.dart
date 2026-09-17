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

      test('삼각형 포인트는 모두 포함 (마지막 극점 누락 회귀)', () {
        final points = createPoints([
          [0, 0],
          [10, 0],
          [5, 10],
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        // off-by-one으로 마지막 극점이 탈락하면 2개만 남는다
        expect(hull.length, 3);
        for (final p in points) {
          expect(
            hull.any((h) => h.x == p.x && h.y == p.y),
            isTrue,
            reason: '삼각형 꼭짓점 (${p.x},${p.y})은 헐에 포함되어야 한다',
          );
        }
      });

      test('내부 점 제거 — 사각형 꼭짓점 4개만 정확히 남는다', () {
        final points = createPoints([
          [0, 0], [10, 0], [10, 10], [0, 10], // 사각형 꼭짓점
          [5, 5], // 내부 점
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        expect(hull.length, 4);
        expect(hull.any((h) => h.x == 5 && h.y == 5), isFalse);
        for (final corner in [(10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]) {
          expect(
            hull.any((h) => h.x == corner.$1 && h.y == corner.$2),
            isTrue,
            reason: '꼭짓점 $corner 은 헐에 포함되어야 한다',
          );
        }
      });

      test('피벗과 동일각 점들 — 가장 먼 점이 보존된다', () {
        // (0,0) 피벗 기준 (5,5)와 (10,10)은 동일각 — 더 먼 (10,10)이 남아야 함
        final points = createPoints([
          [0, 0],
          [5, 5],
          [10, 10],
          [10, 0],
          [0, 10],
        ]);
        final hull = ConvexHullCalculator.calculateConvexHull(points);
        expect(
          hull.any((h) => h.x == 10 && h.y == 10),
          isTrue,
          reason: '동일각 그룹에서 가까운 점이 보존되면 헐 꼭짓점 (10,10)이 소실된다',
        );
        expect(hull.any((h) => h.x == 5 && h.y == 5), isFalse);
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
  });
}
