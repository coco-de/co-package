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

      test('identity일 때 canvasToScreen은 좌표 그대로', () {
        const point = Offset(150, 250);
        expect(transformer.canvasToScreen(point), point);
      });

      test('identity일 때 canvasToLocal은 좌표 그대로', () {
        const point = Offset(150, 250);
        expect(transformer.canvasToLocal(point), point);
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

      test('canvasToScreen: 캔버스 좌표를 스크린 좌표로 변환 (스케일 적용)', () {
        // 2x 스케일일 때 캔버스 (50, 50)은 스크린 (100, 100)에 해당
        final result = transformer.canvasToScreen(const Offset(50, 50));
        expect(result.dx, closeTo(100.0, 0.01));
        expect(result.dy, closeTo(100.0, 0.01));
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

      test('canvasToScreen: 캔버스 좌표에 오프셋을 더해 스크린 좌표 반환', () {
        // translate(50, 100)일 때 캔버스 (0, 0)은 스크린 (50, 100)에 해당
        final result = transformer.canvasToScreen(const Offset(0, 0));
        expect(result.dx, closeTo(50.0, 0.01));
        expect(result.dy, closeTo(100.0, 0.01));
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

      test('canvasToLocal과 canvasToScreen은 일관된 결과를 제공', () {
        const canvasPoint = Offset(100, 100);
        final local = transformer.canvasToLocal(canvasPoint);
        final screen = transformer.canvasToScreen(canvasPoint);
        // canvasToLocal은 역변환, canvasToScreen은 순변환이므로 다른 결과
        expect(local, isNot(equals(screen)));
      });
    });
  });
}
