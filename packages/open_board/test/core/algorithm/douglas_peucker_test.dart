import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/algorithm/douglas_peucker.dart';

void main() {
  group('DouglasPeucker', () {
    group('getSquareDistance', () {
      test('동일 점 사이 거리는 0', () {
        final p = Point(0, 0);
        expect(DouglasPeucker.getSquareDistance(p, p), 0);
      });

      test('두 점 사이 제곱 거리 계산', () {
        final p1 = Point(0, 0);
        final p2 = Point(3, 4);
        expect(DouglasPeucker.getSquareDistance(p1, p2), 25);
      });
    });

    group('getSquareSegmentDistance', () {
      test('점이 세그먼트 위에 있으면 0', () {
        final p = Point(5, 0);
        final p1 = Point(0, 0);
        final p2 = Point(10, 0);
        expect(DouglasPeucker.getSquareSegmentDistance(p, p1, p2), 0);
      });

      test('점에서 세그먼트까지의 수직 거리', () {
        final p = Point(5, 3);
        final p1 = Point(0, 0);
        final p2 = Point(10, 0);
        expect(DouglasPeucker.getSquareSegmentDistance(p, p1, p2), 9);
      });

      test('세그먼트가 점일 때 (p1 == p2)', () {
        final p = Point(3, 4);
        final p1 = Point(0, 0);
        expect(DouglasPeucker.getSquareSegmentDistance(p, p1, p1), 25);
      });
    });

    group('simplify', () {
      test('빈 리스트 반환', () {
        expect(DouglasPeucker.simplify([], tolerance: 1.0), isEmpty);
      });

      test('1개 포인트는 그대로 반환', () {
        final points = [Point(1, 1)];
        expect(DouglasPeucker.simplify(points, tolerance: 1.0), hasLength(1));
      });

      test('2개 미만은 그대로 반환', () {
        final points = [Point(0, 0)];
        final result = DouglasPeucker.simplify(points, tolerance: 1.0);
        expect(result.length, 1);
      });

      test('직선 위의 포인트들은 크게 단순화', () {
        final points = List.generate(10, (i) => Point(i.toDouble(), 0));
        final result = DouglasPeucker.simplify(points, tolerance: 1.0);
        expect(result.length, lessThanOrEqualTo(3));
        expect(result.first.x, 0);
      });

      test('tolerance가 매우 크면 시작/끝만 남김', () {
        final points = [Point(0, 0), Point(5, 10), Point(10, 0)];
        final result = DouglasPeucker.simplify(points, tolerance: 100);
        expect(result.length, 2);
      });

      test('tolerance가 0이면 모든 포인트 유지', () {
        final points = [Point(0, 0), Point(5, 10), Point(10, 0)];
        final result = DouglasPeucker.simplify(points, tolerance: 0);
        expect(result.length, 3);
      });
    });

    group('simplifyRadialDistance', () {
      test('1개 이하 포인트는 그대로', () {
        expect(
          DouglasPeucker.simplifyRadialDistance([Point(0, 0)], 1),
          hasLength(1),
        );
      });

      test('가까운 포인트 제거', () {
        final points = [Point(0, 0), Point(0.1, 0.1), Point(10, 10)];
        final result = DouglasPeucker.simplifyRadialDistance(points, 1);
        expect(result.length, lessThanOrEqualTo(3));
      });
    });

    group('simplifyDouglasPeucker', () {
      test('삼각형 꼭짓점은 유지', () {
        final points = [Point(0, 0), Point(5, 10), Point(10, 0)];
        final result = DouglasPeucker.simplifyDouglasPeucker(points, 0.1);
        expect(result.length, 3);
      });
    });
  });
}
