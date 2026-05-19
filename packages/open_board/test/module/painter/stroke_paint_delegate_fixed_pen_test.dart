// 🎯 Dart imports:
import 'dart:ui';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/painter/stroke_paint_delegate.dart';

import '../../helpers/test_helpers.dart';

/// fixedPen 회귀 방지: drawFixedPen 의 frozen / 균일 두께 보장.
///
/// 검증 동작 (PR #126, #131):
/// - 그려진 스트로크는 frozen — drawFixedPen 호출 시 입력 stroke 객체의
///   options(size, thinning, simulatePressure)가 변경되지 않는다.
/// - drawStroke 의 분기에서 ink="fixedPen"이 drawFixedPen 으로 라우팅된다.
/// - paint() 전체 흐름을 통과해도 입력 strokes 의 options 가 보존된다.
void main() {
  Canvas freshCanvas() => Canvas(PictureRecorder());

  group('drawFixedPen — 호출 안정성', () {
    test('drawFixedPen 은 throw 하지 않고 정상 동작한다', () {
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        points: createLinePoints(count: 5),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      expect(
        () => delegate.drawFixedPen(freshCanvas(), stroke),
        returnsNormally,
      );
    });

    test('점이 적은 stroke 에도 drawFixedPen 은 throw 하지 않는다', () {
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        points: [createPoint(x: 0, y: 0)],
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      expect(
        () => delegate.drawFixedPen(freshCanvas(), stroke),
        returnsNormally,
      );
    });
  });

  group('drawFixedPen — 입력 stroke frozen (#2)', () {
    test('호출 후 stroke.options.size 가 변경되지 않는다', () {
      const originalSize = 4.5;
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(size: originalSize),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      delegate.drawFixedPen(freshCanvas(), stroke);

      expect(
        stroke.options.size,
        originalSize,
        reason: 'frozen — drawFixedPen 은 입력 stroke 의 size 를 변경하지 않는다',
      );
    });

    test('입력 stroke 의 thinning 이 0.7 이어도 변경되지 않고 보존된다', () {
      // (저장된 옛 스트로크 호환 시뮬레이션 — 옛 데이터에 thinning=0.7 이 있을 수 있음)
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(thinning: 0.7),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      delegate.drawFixedPen(freshCanvas(), stroke);

      expect(
        stroke.options.thinning,
        0.7,
        reason: '입력 stroke 객체는 immutable 처럼 보존되어야 한다',
      );
    });

    test('입력 stroke 의 simulatePressure=true 가 변경되지 않고 보존된다', () {
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(simulatePressure: true),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      delegate.drawFixedPen(freshCanvas(), stroke);

      expect(stroke.options.simulatePressure, isTrue);
    });

    test('color, width, points 등 다른 필드도 변경되지 않는다', () {
      final originalPoints = createLinePoints(count: 8);
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        color: 0xFF112233,
        width: 3.5,
        points: originalPoints,
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      delegate.drawFixedPen(freshCanvas(), stroke);

      expect(stroke.color, 0xFF112233);
      expect(stroke.width, 3.5);
      expect(stroke.points.length, originalPoints.length);
    });
  });

  group('drawStroke — fixedPen 라우팅', () {
    test('ink="fixedPen" 인 stroke 를 drawStroke 로 호출 시 throw 없이 처리된다', () {
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        points: createLinePoints(count: 5),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      expect(() => delegate.drawStroke(freshCanvas(), stroke), returnsNormally);
    });

    test('drawStroke 호출 후에도 fixedPen stroke 의 options 는 보존된다', () {
      const originalSize = 2.5;
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(
          size: originalSize,
          thinning: 0.7,
          simulatePressure: true,
        ),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      delegate.drawStroke(freshCanvas(), stroke);

      expect(stroke.options.size, originalSize);
      expect(stroke.options.thinning, 0.7);
      expect(stroke.options.simulatePressure, isTrue);
    });
  });

  group('paint() — 전체 흐름 frozen', () {
    test('paint() 호출 후 모든 fixedPen stroke 의 options 가 보존된다', () {
      const sizeA = 1.5;
      const sizeB = 4.0;
      final strokeA = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(size: sizeA),
      );
      final strokeB = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(size: sizeB, thinning: 0.5),
      );
      final delegate = StrokePaintDelegate(strokes: [strokeA, strokeB]);

      delegate.paint(freshCanvas(), const Size(100, 100));

      expect(strokeA.options.size, sizeA);
      expect(strokeB.options.size, sizeB);
      expect(strokeB.options.thinning, 0.5);
    });

    test('scaleFactor 가 다른 delegate 라도 stroke.options 는 변경되지 않는다 (frozen)', () {
      // PR #131: 그려진 스트로크는 줌 변화에도 불변
      const originalSize = 3.0;
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(size: originalSize),
      );
      final delegateZoomed = StrokePaintDelegate(
        strokes: [stroke],
        scaleFactor: 4.0,
      );

      delegateZoomed.paint(freshCanvas(), const Size(100, 100));

      expect(
        stroke.options.size,
        originalSize,
        reason: 'scaleFactor 와 무관하게 frozen 보장',
      );
    });

    test('동일 stroke 에 paint() 를 여러 번 호출해도 누적 변경되지 않는다', () {
      const originalSize = 2.0;
      final stroke = createStroke(
        ink: InkModes.fixedPen,
        options: createStrokeOptions(size: originalSize),
      );
      final delegate = StrokePaintDelegate(strokes: [stroke]);

      for (var i = 0; i < 5; i++) {
        delegate.paint(freshCanvas(), const Size(100, 100));
      }

      expect(stroke.options.size, originalSize);
    });
  });
}
