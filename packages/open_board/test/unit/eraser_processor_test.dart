import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/stroke/eraser_processor.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('EraserProcessor', () {
    late EraserProcessor processor;

    setUp(() {
      processor = const EraserProcessor();
    });

    group('findIntersection', () {
      test('수직 선분에 대한 교점을 계산한다', () {
        // 수직 선분: x=100 (preLocalPosition=(100,0), event=(100,200))
        // 포인트: (50, 80)
        const event = PointerMoveEvent(position: Offset(100, 200));
        final point = createPoint(x: 50, y: 80);
        const preLocalPosition = Offset(100, 0);

        final result = processor.findIntersection(
          event,
          point,
          preLocalPosition,
        );

        // 수직 선분이므로 교점의 x는 선분의 x(100), y는 포인트의 y(80)
        expect(result.dx, closeTo(100.0, 0.01));
        expect(result.dy, closeTo(80.0, 0.01));
      });

      test('수평 선분에 대한 교점을 계산한다', () {
        // 수평 선분: y=100 (preLocalPosition=(0,100), event=(200,100))
        // 포인트: (80, 50)
        const event = PointerMoveEvent(position: Offset(200, 100));
        final point = createPoint(x: 80, y: 50);
        const preLocalPosition = Offset(0, 100);

        final result = processor.findIntersection(
          event,
          point,
          preLocalPosition,
        );

        // 수평 선분이므로 교점의 x는 포인트의 x(80), y는 선분의 y(100)
        expect(result.dx, closeTo(80.0, 0.01));
        expect(result.dy, closeTo(100.0, 0.01));
      });

      test('대각선 선분에 대한 교점을 계산한다', () {
        // 대각선 선분: (0,0) → (100,100), 기울기 1
        // 포인트: (0, 100) → 수선의 발은 (50, 50)
        const event = PointerMoveEvent(position: Offset(100, 100));
        final point = createPoint(x: 0, y: 100);
        const preLocalPosition = Offset(0, 0);

        final result = processor.findIntersection(
          event,
          point,
          preLocalPosition,
        );

        expect(result.dx, closeTo(50.0, 0.01));
        expect(result.dy, closeTo(50.0, 0.01));
      });
    });

    group('eraseAtPoint', () {
      late ScribbleModeState modeState;

      setUp(() {
        modeState = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.erase),
          scaleFactor: 1.0,
        );
      });

      test('지우개 근처의 스트로크를 제거한다', () {
        // 스트로크가 (50, 50) 근처에 있음
        final stroke = createStroke(
          points: [createPoint(x: 50, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(strokes: [stroke]);
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        // 지우개를 (50, 50) 위로 이동
        const event = PointerMoveEvent(position: Offset(50, 50));
        const preLocalPosition = Offset(48, 48);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result, isA<Erasing>());
        expect(result.scribble.strokes, isEmpty);
      });

      test('점이 희소한 직선 스트로크의 변 중간을 가로지르면 지워진다', () {
        // 정지 직선화/도형 변환 스트로크는 점이 양 끝 2개뿐이다
        final stroke = createStroke(
          points: [createPoint(x: 0, y: 50), createPoint(x: 200, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(strokes: [stroke]);
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        // 직선 중간(100, 50)을 세로로 가로지르는 지우개 스와이프
        const event = PointerMoveEvent(position: Offset(100, 70));
        const preLocalPosition = Offset(100, 30);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result.scribble.strokes, isEmpty);
      });

      test('점이 희소한 직선에서 멀리 떨어진 스와이프는 지우지 않는다', () {
        final stroke = createStroke(
          points: [createPoint(x: 0, y: 50), createPoint(x: 200, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(strokes: [stroke]);
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        const event = PointerMoveEvent(position: Offset(100, 200));
        const preLocalPosition = Offset(100, 160);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result.scribble.strokes.length, 1);
      });

      test('멀리 있는 스트로크는 유지한다', () {
        // 스트로크가 (500, 500) 근처에 있음
        final stroke = createStroke(
          points: [createPoint(x: 500, y: 500)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(strokes: [stroke]);
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        // 지우개는 (50, 50) 근처
        const event = PointerMoveEvent(position: Offset(50, 50));
        const preLocalPosition = Offset(48, 48);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result, isA<Erasing>());
        expect(result.scribble.strokes.length, 1);
      });

      test('Drawing 상태에서도 동작한다', () {
        final stroke = createStroke(
          points: [createPoint(x: 50, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(strokes: [stroke]);
        final state = Drawing(scribble: scribble, activePointerIds: const [1]);

        const event = PointerMoveEvent(position: Offset(50, 50));
        const preLocalPosition = Offset(48, 48);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result, isA<Drawing>());
        expect(result.scribble.strokes, isEmpty);
      });

      test('textDrawables를 유지한다', () {
        final stroke = createStroke(
          points: [createPoint(x: 50, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final textDrawable = createTextDrawable(id: 'text1');
        final scribble = createScribble(
          strokes: [stroke],
          textDrawables: [textDrawable],
        );
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        const event = PointerMoveEvent(position: Offset(50, 50));
        const preLocalPosition = Offset(48, 48);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result.scribble.textDrawables.length, 1);
        expect(result.scribble.textDrawables.first.id, 'text1');
      });

      test('여러 스트로크 중 근처에 있는 것만 제거한다', () {
        final nearStroke = createStroke(
          points: [createPoint(x: 50, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final farStroke = createStroke(
          points: [createPoint(x: 500, y: 500)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(strokes: [nearStroke, farStroke]);
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        const event = PointerMoveEvent(position: Offset(50, 50));
        const preLocalPosition = Offset(48, 48);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result.scribble.strokes.length, 1);
        expect(result.scribble.strokes.first.points.first.x, 500.0);
      });

      test('프레임 드롭으로 현이 비정상적으로 길어져도 무관한 스트로크는 유지한다 (#9006)', () {
        // 사용자가 실제로 지우려는 스트로크는 지우개의 "현재" 위치 바로
        // 위에 있고, 관계없는 스트로크는 (프레임 드롭 전) "이전" 위치
        // 근처에 있다. 두 위치를 잇는 원본 현은 두 스트로크를 모두
        // 관통하지만, 무관한 스트로크는 지워지면 안 된다.
        final unrelatedStroke = createStroke(
          points: [createPoint(x: 50, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final intendedStroke = createStroke(
          points: [createPoint(x: 340, y: 50)],
          options: createStrokeOptions(size: 2.0, thinning: 0.0),
        );
        final scribble = createScribble(
          strokes: [unrelatedStroke, intendedStroke],
        );
        final state = Erasing(scribble: scribble, activePointerIds: const [1]);

        // 프레임 드롭으로 이전 위치(10,50)와 현재 위치(340,50) 사이의
        // 간격이 330px 로 크게 벌어진 상황을 시뮬레이션한다.
        const event = PointerMoveEvent(position: Offset(340, 50));
        const preLocalPosition = Offset(10, 50);

        final result = processor.eraseAtPoint(
          event,
          modeState,
          state,
          preLocalPosition,
        );

        expect(result.scribble.strokes.length, 1);
        expect(result.scribble.strokes.first.points.first.x, 50.0);
      });
    });
  });
}
