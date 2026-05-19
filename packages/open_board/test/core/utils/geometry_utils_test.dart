
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/geometry_utils.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GeometryUtils', () {
    group('calculateDistance', () {
      test('동일 점 사이 거리는 0', () {
        final p = createPoint(x: 5, y: 5);
        expect(GeometryUtils.calculateDistance(p, p), 0);
      });

      test('3-4-5 삼각형 거리 계산', () {
        final p1 = createPoint(x: 0, y: 0);
        final p2 = createPoint(x: 3, y: 4);
        expect(GeometryUtils.calculateDistance(p1, p2), 5);
      });

      test('수평 거리', () {
        final p1 = createPoint(x: 0, y: 0);
        final p2 = createPoint(x: 10, y: 0);
        expect(GeometryUtils.calculateDistance(p1, p2), 10);
      });
    });

    group('calculateCornerAngle', () {
      test('직각(90도)', () {
        final prev = createPoint(x: 0, y: 0);
        final mid = createPoint(x: 0, y: 5);
        final next = createPoint(x: 5, y: 5);
        expect(
          GeometryUtils.calculateCornerAngle(prev, mid, next),
          closeTo(90, 0.1),
        );
      });

      test('일직선(180도)', () {
        final prev = createPoint(x: 0, y: 0);
        final mid = createPoint(x: 5, y: 0);
        final next = createPoint(x: 10, y: 0);
        expect(
          GeometryUtils.calculateCornerAngle(prev, mid, next),
          closeTo(180, 0.1),
        );
      });

      test('영벡터 시 180도 반환', () {
        final p = createPoint(x: 5, y: 5);
        expect(GeometryUtils.calculateCornerAngle(p, p, p), 180.0);
      });
    });

    group('calculateCentroid', () {
      test('빈 리스트는 (0,0)', () {
        final centroid = GeometryUtils.calculateCentroid([]);
        expect(centroid.x, 0);
        expect(centroid.y, 0);
      });

      test('단일 점은 그 점 자체', () {
        final p = createPoint(x: 10, y: 20);
        final centroid = GeometryUtils.calculateCentroid([p]);
        expect(centroid.x, 10);
        expect(centroid.y, 20);
      });

      test('정사각형의 중심', () {
        final points = createPoints([
          [0, 0],
          [10, 0],
          [10, 10],
          [0, 10],
        ]);
        final centroid = GeometryUtils.calculateCentroid(points);
        expect(centroid.x, 5);
        expect(centroid.y, 5);
      });
    });

    group('calculatePolygonPerimeter', () {
      test('1개 이하 포인트는 0', () {
        expect(GeometryUtils.calculatePolygonPerimeter([]), 0);
        expect(GeometryUtils.calculatePolygonPerimeter([createPoint()]), 0);
      });

      test('정사각형 둘레 계산', () {
        final points = createPoints([
          [0, 0],
          [10, 0],
          [10, 10],
          [0, 10],
        ]);
        expect(
          GeometryUtils.calculatePolygonPerimeter(points),
          closeTo(40, 0.1),
        );
      });
    });

    group('calculateBoundingBox', () {
      test('빈 리스트는 Rect.zero', () {
        expect(GeometryUtils.calculateBoundingBox([]), Rect.zero);
      });

      test('여러 포인트의 바운딩 박스', () {
        final points = createPoints([
          [5, 10],
          [15, 3],
          [2, 20],
        ]);
        final rect = GeometryUtils.calculateBoundingBox(points);
        expect(rect.left, 2);
        expect(rect.top, 3);
        expect(rect.right, 15);
        expect(rect.bottom, 20);
      });
    });

    group('findClosestPointIndex', () {
      test('빈 리스트는 -1', () {
        expect(GeometryUtils.findClosestPointIndex([], createPoint()), -1);
      });

      test('가장 가까운 점 찾기', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
          [5, 5],
        ]);
        final target = createPoint(x: 4, y: 4);
        expect(GeometryUtils.findClosestPointIndex(points, target), 2);
      });
    });

    group('orderPointsClockwise', () {
      test('2개 이하는 그대로', () {
        final points = [createPoint(x: 1, y: 1)];
        expect(GeometryUtils.orderPointsClockwise(points), hasLength(1));
      });

      test('정렬 후 원본 길이 유지', () {
        final points = createPoints([
          [0, 0],
          [10, 0],
          [10, 10],
          [0, 10],
        ]);
        final ordered = GeometryUtils.orderPointsClockwise(points);
        expect(ordered.length, 4);
      });
    });

    group('calculatePathDirection', () {
      test('잘못된 인덱스는 (0,0) 반환', () {
        final points = createPoints([
          [0, 0],
          [10, 10],
        ]);
        final dir = GeometryUtils.calculatePathDirection(points, 1, 0);
        expect(dir.x, 0);
        expect(dir.y, 0);
      });

      test('방향 벡터 계산', () {
        final points = createPoints([
          [0, 0],
          [10, 5],
        ]);
        final dir = GeometryUtils.calculatePathDirection(points, 0, 1);
        expect(dir.x, 10);
        expect(dir.y, 5);
      });
    });

    group('crossProduct', () {
      test('일직선은 0', () {
        final p1 = createPoint(x: 0, y: 0);
        final p2 = createPoint(x: 5, y: 0);
        final p3 = createPoint(x: 10, y: 0);
        expect(GeometryUtils.crossProduct(p1, p2, p3), 0);
      });

      test('반시계 방향 양수', () {
        final p1 = createPoint(x: 0, y: 0);
        final p2 = createPoint(x: 10, y: 0);
        final p3 = createPoint(x: 10, y: 10);
        expect(GeometryUtils.crossProduct(p1, p2, p3), greaterThan(0));
      });
    });

    group('calculateOrientation', () {
      test('일직선은 0', () {
        final p = createPoint(x: 0, y: 0);
        final q = createPoint(x: 5, y: 0);
        final r = createPoint(x: 10, y: 0);
        expect(GeometryUtils.calculateOrientation(p, q, r), 0);
      });

      test('시계/반시계 방향 구분', () {
        final p = createPoint(x: 0, y: 0);
        final q = createPoint(x: 5, y: 0);
        final r = createPoint(x: 5, y: 5);
        final orientation = GeometryUtils.calculateOrientation(p, q, r);
        expect(orientation, isIn([1, 2]));
      });
    });
  });
}
