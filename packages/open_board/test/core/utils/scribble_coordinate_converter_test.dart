import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/scribble_coordinate_converter.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ScribbleCoordinateConverter', () {
    test('빈 스트로크는 identity 카메라', () {
      const viewport = Size(400, 300);
      final fit = ScribbleCoordinateConverter.fitHandwriting(
        strokes: const [],
        viewportSize: viewport,
      );

      expect(fit.center, const Offset(200, 150));
      expect(fit.scale, 1);
      expect(fit.bounds, Rect.zero);
      expect(
        ScribbleCoordinateConverter.fitHandwritingToViewport(
          strokes: const [],
          contentLogicalSize: const Size(800, 600),
          viewportSize: viewport,
        ),
        Matrix4.identity(),
      );
    });

    test('centroid는 포인트 평균이다', () {
      final stroke = createStroke(
        points: createPoints([
          [100, 100],
          [300, 100],
          [300, 300],
          [100, 300],
        ]),
      );
      final fit = ScribbleCoordinateConverter.fitHandwriting(
        strokes: [stroke],
        viewportSize: const Size(400, 400),
        paddingFraction: 0,
      );

      expect(fit.center, closeTo2D(200, 200));
    });

    test('가로로 좁은 뷰포트는 너비 기준 contain-fit', () {
      final stroke = createStroke(
        points: createPoints([
          [0, 0],
          [200, 0],
          [200, 100],
          [0, 100],
        ]),
      );
      final fit = ScribbleCoordinateConverter.fitHandwriting(
        strokes: [stroke],
        viewportSize: const Size(100, 400),
        paddingFraction: 0,
      );

      expect(fit.scale, closeTo(0.5, 0.01));
      expect(fit.center, closeTo2D(100, 50));
    });

    test('세로로 좁은 뷰포트는 높이 기준 contain-fit', () {
      final stroke = createStroke(
        points: createPoints([
          [0, 0],
          [200, 0],
          [200, 100],
          [0, 100],
        ]),
      );
      final fit = ScribbleCoordinateConverter.fitHandwriting(
        strokes: [stroke],
        viewportSize: const Size(400, 50),
        paddingFraction: 0,
      );

      expect(fit.scale, closeTo(0.5, 0.01));
    });

    test('리사이즈 후에도 centroid가 화면 중심에 온다', () {
      final stroke = createStroke(
        points: createPoints([
          [100, 80],
          [300, 80],
          [300, 220],
          [100, 220],
        ]),
      );
      const content = Size(800, 600);

      for (final viewport in const [
        Size(800, 600),
        Size(400, 300),
        Size(390, 844),
        Size(1280, 720),
      ]) {
        final matrix = ScribbleCoordinateConverter.fitHandwritingToViewport(
          strokes: [stroke],
          contentLogicalSize: content,
          viewportSize: viewport,
          paddingFraction: 0,
        );
        final mapped = _mapLogicalCenter(
          matrix: matrix,
          logicalCenter: const Offset(200, 150),
          contentLogicalSize: content,
          viewportSize: viewport,
        );
        expect(
          mapped,
          closeTo2D(viewport.width / 2, viewport.height / 2, delta: 0.5),
          reason: 'viewport $viewport',
        );
      }
    });

    test('작은 필기는 줌인되어 페이지 fit보다 큰 InteractiveViewer scale을 갖는다', () {
      final stroke = createStroke(
        points: createPoints([
          [390, 290],
          [410, 290],
          [410, 310],
          [390, 310],
        ]),
      );
      final matrix = ScribbleCoordinateConverter.fitHandwritingToViewport(
        strokes: [stroke],
        contentLogicalSize: const Size(800, 600),
        viewportSize: const Size(800, 600),
        paddingFraction: 0,
      );

      expect(matrix.getMaxScaleOnAxis(), greaterThan(1));
    });

    test('maxScale clamp 시에도 centroid 정렬은 유지한다', () {
      final stroke = createStroke(
        points: createPoints([
          [395, 295],
          [405, 295],
          [405, 305],
          [395, 305],
        ]),
      );
      const content = Size(800, 600);
      const viewport = Size(400, 300);
      final matrix = ScribbleCoordinateConverter.fitHandwritingToViewport(
        strokes: [stroke],
        contentLogicalSize: content,
        viewportSize: viewport,
        paddingFraction: 0,
        maxScale: 2,
      );

      expect(matrix.getMaxScaleOnAxis(), closeTo(2, 0.01));
      final mapped = _mapLogicalCenter(
        matrix: matrix,
        logicalCenter: const Offset(400, 300),
        contentLogicalSize: content,
        viewportSize: viewport,
      );
      expect(mapped, closeTo2D(200, 150, delta: 0.5));
    });
  });
}

Offset _mapLogicalCenter({
  required Matrix4 matrix,
  required Offset logicalCenter,
  required Size contentLogicalSize,
  required Size viewportSize,
}) {
  final pageFitScale = math.min(
    viewportSize.width / contentLogicalSize.width,
    viewportSize.height / contentLogicalSize.height,
  );
  final displaySize = Size(
    contentLogicalSize.width * pageFitScale,
    contentLogicalSize.height * pageFitScale,
  );
  final letterbox = Offset(
    (viewportSize.width - displaySize.width) / 2,
    (viewportSize.height - displaySize.height) / 2,
  );
  final display = Offset(
    logicalCenter.dx * pageFitScale + letterbox.dx,
    logicalCenter.dy * pageFitScale + letterbox.dy,
  );
  return MatrixUtils.transformPoint(matrix, display);
}
