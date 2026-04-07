import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Protobuf 팩토리 헬퍼', () {
    test('createPoint - 기본값으로 생성', () {
      final point = createPoint();
      expect(point.x, 0);
      expect(point.y, 0);
      expect(point.p, 0.5);
    });

    test('createPoint - 커스텀 값으로 생성', () {
      final point = createPoint(x: 10, y: 20, p: 0.8);
      expect(point.x, 10);
      expect(point.y, 20);
      expect(point.p, 0.8);
    });

    test('createPoints - 좌표 쌍에서 포인트 리스트 생성', () {
      final points = createPoints([
        [0, 0],
        [10, 20],
        [30, 40, 0.9],
      ]);
      expect(points.length, 3);
      expect(points[0].x, 0);
      expect(points[2].p, 0.9);
    });

    test('createLinePoints - 직선 포인트 생성', () {
      final points = createLinePoints(
        fromX: 0,
        fromY: 0,
        toX: 100,
        toY: 0,
        count: 5,
      );
      expect(points.length, 5);
      expect(points.first.x, 0);
      expect(points.last.x, 100);
    });

    test('createStroke - 기본 스트로크 생성', () {
      final stroke = createStroke();
      expect(stroke.points.isNotEmpty, true);
      expect(stroke.ink, 'pencil');
      expect(stroke.color, 0xFF000000);
    });

    test('createScribble - 빈 스크리블 생성', () {
      final scribble = createScribble();
      expect(scribble.width, 400);
      expect(scribble.height, 600);
      expect(scribble.strokes.isEmpty, true);
    });

    test('createScribbleWithStrokes - 여러 스트로크 포함', () {
      final scribble = createScribbleWithStrokes(strokeCount: 5);
      expect(scribble.strokes.length, 5);
    });

    test('createRectanglePoints - 사각형 포인트 생성', () {
      final points = createRectanglePoints();
      expect(points.isNotEmpty, true);
      // 첫 포인트는 좌상단
      expect(points.first.x, 0);
      expect(points.first.y, 0);
    });

    test('createTextDrawable - 기본 텍스트 생성', () {
      final text = createTextDrawable();
      expect(text.text, 'Test Text');
      expect(text.fontSize, 16);
    });
  });
}
