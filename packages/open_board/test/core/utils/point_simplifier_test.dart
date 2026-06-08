import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/point_simplifier.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('PointSimplifier', () {
    group('simplifyPoints', () {
      test('2개 이하 포인트는 그대로', () {
        final points = createPoints([
          [0, 0],
        ]);
        final result = PointSimplifier.simplifyPoints(points, 1.0);
        expect(result.length, 1);
      });

      test('2개 포인트는 그대로', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        final result = PointSimplifier.simplifyPoints(points, 1.0);
        expect(result.length, 2);
      });

      test('직선 포인트 단순화', () {
        final points = createLinePoints(
          fromX: 0,
          fromY: 0,
          toX: 100,
          toY: 0,
          count: 50,
        );
        final result = PointSimplifier.simplifyPoints(points, 1.0);
        expect(result.length, lessThan(points.length));
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('epsilon이 클수록 더 많이 단순화', () {
        final points = createLinePoints(count: 30);
        final small = PointSimplifier.simplifyPoints(points, 0.1);
        final large = PointSimplifier.simplifyPoints(points, 10.0);
        expect(large.length, lessThanOrEqualTo(small.length));
      });
    });
  });
}
