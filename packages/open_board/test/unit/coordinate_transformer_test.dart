import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/coordinate_transformer.dart';

void main() {
  group('CoordinateTransformer', () {
    group('null TransformationController 처리', () {
      test('controller가 null이면 scale은 1.0', () {
        const transformer = CoordinateTransformer(null);
        expect(transformer.scale, 1.0);
      });

      test('controller가 null이면 screenToCanvas는 좌표 그대로 반환', () {
        const transformer = CoordinateTransformer(null);
        const point = Offset(100, 200);
        expect(transformer.screenToCanvas(point), point);
      });

      test('controller가 null이면 canvasToScreen은 좌표 그대로 반환', () {
        const transformer = CoordinateTransformer(null);
        const point = Offset(100, 200);
        expect(transformer.canvasToScreen(point), point);
      });

      test('controller가 null이면 canvasToLocal은 좌표 그대로 반환', () {
        const transformer = CoordinateTransformer(null);
        const point = Offset(100, 200);
        expect(transformer.canvasToLocal(point), point);
      });

      test('controller가 null이면 screenToCanvasDistance는 거리 그대로 반환', () {
        const transformer = CoordinateTransformer(null);
        expect(transformer.screenToCanvasDistance(50.0), 50.0);
      });

      test('controller가 null이면 matrix는 identity', () {
        const transformer = CoordinateTransformer(null);
        expect(transformer.matrix, Matrix4.identity());
      });

      test('controller가 null이면 inverseMatrix는 identity', () {
        const transformer = CoordinateTransformer(null);
        expect(transformer.inverseMatrix, Matrix4.identity());
      });
    });

    group('identity matrix (기본 변환)', () {
      late TransformationController controller;
      late CoordinateTransformer transformer;

      setUp(() {
        controller = TransformationController();
        transformer = CoordinateTransformer(controller);
      });

      test('identity일 때 scale은 1.0', () {
        expect(transformer.scale, 1.0);
      });

      test('identity일 때 screenToCanvas는 좌표 그대로', () {
        const point = Offset(150, 250);
        expect(transformer.screenToCanvas(point), point);
      });

      test('identity일 때 canvasToScreen은 좌표 그대로', () {
        const point = Offset(150, 250);
        expect(transformer.canvasToScreen(point), point);
      });

      test('identity일 때 canvasToLocal은 좌표 그대로', () {
        const point = Offset(150, 250);
        expect(transformer.canvasToLocal(point), point);
      });

      test('identity일 때 screenToCanvasDistance는 거리 그대로', () {
        expect(transformer.screenToCanvasDistance(100.0), 100.0);
      });
    });

    group('스케일 적용 시 좌표 변환', () {
      late TransformationController controller;
      late CoordinateTransformer transformer;

      setUp(() {
        controller = TransformationController();
        // 2배 스케일 적용
        controller.value = Matrix4.identity()..scale(2.0);
        transformer = CoordinateTransformer(controller);
      });

      test('scale이 정확히 반영됨', () {
        expect(transformer.scale, 2.0);
      });

      test('screenToCanvas: 스크린 좌표를 캔버스 좌표로 변환 (스케일 역산)', () {
        // 2x 스케일일 때 스크린 (100, 100)은 캔버스 (50, 50)에 해당
        final result = transformer.screenToCanvas(const Offset(100, 100));
        expect(result.dx, closeTo(50.0, 0.01));
        expect(result.dy, closeTo(50.0, 0.01));
      });

      test('canvasToScreen: 캔버스 좌표를 스크린 좌표로 변환 (스케일 적용)', () {
        // 2x 스케일일 때 캔버스 (50, 50)은 스크린 (100, 100)에 해당
        final result = transformer.canvasToScreen(const Offset(50, 50));
        expect(result.dx, closeTo(100.0, 0.01));
        expect(result.dy, closeTo(100.0, 0.01));
      });

      test('screenToCanvas와 canvasToScreen은 역함수 관계', () {
        const original = Offset(100, 200);
        final canvas = transformer.screenToCanvas(original);
        final backToScreen = transformer.canvasToScreen(canvas);
        expect(backToScreen.dx, closeTo(original.dx, 0.01));
        expect(backToScreen.dy, closeTo(original.dy, 0.01));
      });

      test('screenToCanvasDistance: 거리 변환 (스케일 역산)', () {
        // 2x 스케일일 때 스크린 거리 100은 캔버스 거리 50에 해당
        expect(transformer.screenToCanvasDistance(100.0), closeTo(50.0, 0.01));
      });
    });

    group('오프셋 적용 시 좌표 변환', () {
      late TransformationController controller;
      late CoordinateTransformer transformer;

      setUp(() {
        controller = TransformationController();
        // 오프셋 (50, 100) 적용 (translation)
        final matrix = Matrix4.identity()..translate(50.0, 100.0);
        controller.value = matrix;
        transformer = CoordinateTransformer(controller);
      });

      test('오프셋 적용 시 scale은 1.0 유지', () {
        expect(transformer.scale, 1.0);
      });

      test('screenToCanvas: 오프셋이 반영된 캔버스 좌표 반환', () {
        // translate(50, 100)일 때 스크린 (0, 0)은 캔버스 (-50, -100)에 해당
        final result = transformer.screenToCanvas(const Offset(0, 0));
        expect(result.dx, closeTo(-50.0, 0.01));
        expect(result.dy, closeTo(-100.0, 0.01));
      });

      test('canvasToScreen: 캔버스 좌표에 오프셋을 더해 스크린 좌표 반환', () {
        // translate(50, 100)일 때 캔버스 (0, 0)은 스크린 (50, 100)에 해당
        final result = transformer.canvasToScreen(const Offset(0, 0));
        expect(result.dx, closeTo(50.0, 0.01));
        expect(result.dy, closeTo(100.0, 0.01));
      });

      test('screenToCanvas와 canvasToScreen은 역함수 관계', () {
        const original = Offset(200, 300);
        final canvas = transformer.screenToCanvas(original);
        final backToScreen = transformer.canvasToScreen(canvas);
        expect(backToScreen.dx, closeTo(original.dx, 0.01));
        expect(backToScreen.dy, closeTo(original.dy, 0.01));
      });
    });

    group('스케일 + 오프셋 복합 변환', () {
      late TransformationController controller;
      late CoordinateTransformer transformer;

      setUp(() {
        controller = TransformationController();
        // 2배 스케일 + 오프셋 (50, 100)
        final matrix = Matrix4.identity()
          ..translate(50.0, 100.0)
          ..scale(2.0);
        controller.value = matrix;
        transformer = CoordinateTransformer(controller);
      });

      test('복합 변환에서도 screenToCanvas/canvasToScreen은 역함수 관계', () {
        const original = Offset(300, 400);
        final canvas = transformer.screenToCanvas(original);
        final backToScreen = transformer.canvasToScreen(canvas);
        expect(backToScreen.dx, closeTo(original.dx, 0.01));
        expect(backToScreen.dy, closeTo(original.dy, 0.01));
      });

      test('canvasToLocal과 canvasToScreen은 일관된 결과를 제공', () {
        const canvasPoint = Offset(100, 100);
        final local = transformer.canvasToLocal(canvasPoint);
        final screen = transformer.canvasToScreen(canvasPoint);
        // canvasToLocal은 역변환, canvasToScreen은 순변환이므로 다른 결과
        expect(local, isNot(equals(screen)));
      });
    });

    group('거리 변환 정확성', () {
      test('스케일 0.5일 때 거리가 2배로 변환', () {
        final controller = TransformationController();
        controller.value = Matrix4.identity()..scale(0.5);
        final transformer = CoordinateTransformer(controller);

        expect(
          transformer.screenToCanvasDistance(100.0),
          closeTo(200.0, 0.01),
        );
      });

      test('스케일 3.0일 때 거리가 1/3로 변환', () {
        final controller = TransformationController();
        controller.value = Matrix4.identity()..scale(3.0);
        final transformer = CoordinateTransformer(controller);

        expect(
          transformer.screenToCanvasDistance(300.0),
          closeTo(100.0, 0.01),
        );
      });
    });
  });
}
