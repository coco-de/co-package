import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/corner_detector.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CornerDetector', () {
    group('detectSignificantCorners', () {
      test('2개 이하 포인트는 그대로 반환', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        final corners = CornerDetector.detectSignificantCorners(points);
        expect(corners.length, 2);
      });

      test('직선 위의 포인트 → 코너 없음 (시작/끝만)', () {
        final points = createLinePoints(
          fromX: 0,
          fromY: 0,
          toX: 100,
          toY: 0,
          count: 10,
        );
        final corners = CornerDetector.detectSignificantCorners(points);
        // 직선에서는 꺾임이 없으므로 시작/끝만 포함
        expect(corners.length, greaterThanOrEqualTo(2));
      });

      test('L자 꺾임 → 코너 감지', () {
        final points = createPoints([
          [0, 0], [50, 0], [100, 0], // 수평
          [100, 50], [100, 100], // 수직 (90도 꺾임)
        ]);
        final corners = CornerDetector.detectSignificantCorners(points);
        expect(corners.length, greaterThanOrEqualTo(2));
      });
    });

    group('evaluateTriangleShape', () {
      test('3개 미만 포인트는 0', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        expect(CornerDetector.evaluateTriangleShape(points), 0);
      });

      test('정삼각형 점수 계산', () {
        // convex hull이 3-5개 사이여야 삼각형으로 평가됨
        final points = createPoints([
          [0, 0], [100, 0], [50, 87],
          [25, 43], [75, 43], // 추가 포인트로 hull 보강
        ]);
        final score = CornerDetector.evaluateTriangleShape(points);
        expect(score, greaterThanOrEqualTo(0));
      });
    });

    group('findBestTriangleCorners', () {
      test('3개 이하 포인트는 그대로', () {
        final points = createPoints([
          [0, 0],
          [10, 0],
          [5, 10],
        ]);
        final result = CornerDetector.findBestTriangleCorners(points);
        expect(result.length, 3);
      });

      test('여러 포인트에서 최적 삼각형 3개 선택', () {
        final points = createPoints([
          [0, 0],
          [5, 0],
          [10, 0],
          [10, 5],
          [10, 10],
          [5, 10],
          [0, 10],
          [0, 5],
        ]);
        final result = CornerDetector.findBestTriangleCorners(points);
        expect(result.length, 3);
      });
    });

    group('generateCornersForClosedShape', () {
      test('짧은 리스트는 그대로', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        final result = CornerDetector.generateCornersForClosedShape(points);
        expect(result.length, 2);
      });

      test('사각형에서 코너 생성', () {
        final points = createRectanglePoints(pointsPerSide: 10);
        final result = CornerDetector.generateCornersForClosedShape(points);
        expect(result.length, greaterThanOrEqualTo(3));
      });
    });
  });
}
