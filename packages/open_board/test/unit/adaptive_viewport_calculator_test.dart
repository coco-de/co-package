import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';
import 'package:open_board/src/module/live/presentation/adaptive_viewport_calculator.dart';

void main() {
  group('AdaptiveViewportCalculator', () {
    test('동일 비율 디바이스에서 scale 동일', () {
      final result = AdaptiveViewportCalculator.calculate(
        teacherViewport: ViewportMessage(
          pageId: 'p1',
          scale: 2.0,
          centerX: 500,
          centerY: 300,
          viewportWidth: 1024,
          viewportHeight: 768,
          timestampMicros: 0,
        ),
        studentScreenSize: const Size(1024, 768),
      );

      expect(result.center, const Offset(500, 300));
      expect(result.scale, closeTo(2.0, 0.01));
    });

    test('학생이 더 넓은 화면 (높이 기준, 좌우 여백)', () {
      // 선생님: iPad 4:3 (1024x768), scale 2.0
      // → 가시 영역: 512 x 384
      final result = AdaptiveViewportCalculator.calculate(
        teacherViewport: ViewportMessage(
          pageId: 'p1',
          scale: 2.0,
          centerX: 500,
          centerY: 300,
          viewportWidth: 1024,
          viewportHeight: 768,
          timestampMicros: 0,
        ),
        // 학생: 넓은 화면 (16:9 가로)
        studentScreenSize: const Size(844, 390),
      );

      // 중심점은 동일
      expect(result.center, const Offset(500, 300));
      // 학생이 더 넓으므로 scale은 선생님보다 낮아야 함
      expect(result.scale, lessThan(2.0));
      // 선생님 가시 높이 384와 같은 높이 기준
      // studentVisibleWidth = 384 * (844/390) ≈ 831
      // scale = 844 / 831 ≈ 1.016
      expect(result.scale, closeTo(1.016, 0.01));
    });

    test('학생이 더 좁은 화면 (너비 기준, 상하 여백)', () {
      // 선생님: 넓은 화면 16:9
      final result = AdaptiveViewportCalculator.calculate(
        teacherViewport: ViewportMessage(
          pageId: 'p1',
          scale: 1.0,
          centerX: 400,
          centerY: 300,
          viewportWidth: 1600,
          viewportHeight: 900,
          timestampMicros: 0,
        ),
        // 학생: 좁은 화면 3:4 세로
        studentScreenSize: const Size(600, 800),
      );

      expect(result.center, const Offset(400, 300));
      // 학생이 더 좁음 → 너비 기준
      // studentVisibleWidth = 1600 (선생님 가시 너비)
      // scale = 600 / 1600 = 0.375
      expect(result.scale, closeTo(0.375, 0.01));
    });

    test('중심점이 항상 선생님과 동일', () {
      for (final center in [
        const Offset(0, 0),
        const Offset(1000, 500),
        const Offset(-100, -200),
      ]) {
        final result = AdaptiveViewportCalculator.calculate(
          teacherViewport: ViewportMessage(
            pageId: 'p1',
            scale: 1.5,
            centerX: center.dx,
            centerY: center.dy,
            viewportWidth: 800,
            viewportHeight: 600,
            timestampMicros: 0,
          ),
          studentScreenSize: const Size(400, 700),
        );

        expect(result.center, center);
      }
    });
  });
}
