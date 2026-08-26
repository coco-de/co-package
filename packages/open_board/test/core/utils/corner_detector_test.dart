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

      test('한 모서리 주변의 여러 점은 minDistanceThreshold 안에서 하나로 뭉친다 (UB-555)', () {
        // (100,0) 근방에 예각을 만드는 점 3개를 흩뿌려, 손그림의 둥근
        // 모서리가 여러 점으로 쪼개지는 상황을 재현한다.
        final points = createPoints([
          [0, 0],
          [50, 0],
          [96, 2],
          [100, 0],
          [104, 3],
          [100, 50],
          [100, 100],
        ]);
        final corners = CornerDetector.detectSignificantCorners(
          points,
          minDistanceThreshold: 20,
        );

        // 시작점 + (100,0) 부근 대표 코너 1개 + 끝점 = 3개.
        // 예전 구현이라면 (96,2)/(100,0)/(104,3) 이 각각 코너로 잡혀
        // 4개 이상이 됐을 것이다.
        expect(corners.length, 3);
      });

      test('서로 멀리 떨어진 진짜 코너는 여전히 각각 별도로 감지된다', () {
        // 단순화된 사각형의 세 중간 코너는 서로 40px 이상 떨어져 있어,
        // minDistanceThreshold(10) 안에서 뭉쳐서는 안 된다.
        final points = createRectanglePoints(
          left: 0,
          top: 0,
          right: 200,
          bottom: 140,
          pointsPerSide: 2,
        );
        final corners = CornerDetector.detectSignificantCorners(points);
        expect(corners.length, 4);
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
