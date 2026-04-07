import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ShapeDetector', () {
    late ShapeDetector detector;

    setUp(() {
      detector = ShapeDetector.instance;
    });

    group('detectAndTransform', () {
      test('포인트 5개 미만이면 polyline 반환', () {
        final stroke = createStroke(
          points: createPoints([[0, 0], [10, 10], [20, 0]]),
        );
        final result = detector.detectAndTransform(stroke);
        expect(result.shapeType, ShapeType.polyline);
      });

      test('직선 감지', () {
        final stroke = createStroke(
          points: createLinePoints(fromX: 0, fromY: 0, toX: 200, toY: 0, count: 20),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        // 직선이거나 polyline
        expect(result.shapeType, isIn([ShapeType.line, ShapeType.polyline, ShapeType.connector]));
      });

      test('사각형 감지 시도', () {
        final stroke = createStroke(
          points: createRectanglePoints(
            left: 0, top: 0, right: 100, bottom: 100, pointsPerSide: 10,
          ),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        // 어떤 도형이든 감지되어야 함
        expect(result.shapeType, isNot(ShapeType.none));
      });

      test('원본 스트로크 보존', () {
        final stroke = createStroke(
          points: createLinePoints(count: 20),
          ink: 'shape',
        );
        final result = detector.detectAndTransform(stroke);
        expect(result.transformedStroke, isNotNull);
      });
    });

    group('ShapeDetectionResult', () {
      test('shapeTypeString 변환', () {
        final stroke = createStroke();
        final result = ShapeDetectionResult(ShapeType.line, stroke);
        expect(result.shapeTypeString, 'line');
      });

      test('none은 빈 문자열', () {
        final stroke = createStroke();
        final result = ShapeDetectionResult(ShapeType.none, stroke);
        expect(result.shapeTypeString, '');
      });

      test('confidence 기본값', () {
        final stroke = createStroke();
        final result = ShapeDetectionResult(ShapeType.circle, stroke);
        expect(result.confidence, 1.0);
      });
    });

    group('ShapeType enum', () {
      test('모든 타입 존재', () {
        expect(ShapeType.values.length, greaterThan(10));
        expect(ShapeType.values, contains(ShapeType.rectangle));
        expect(ShapeType.values, contains(ShapeType.circle));
        expect(ShapeType.values, contains(ShapeType.triangle));
      });
    });
  });
}
