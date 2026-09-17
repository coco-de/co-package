import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/stroke/stroke_processor.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('StrokeProcessor', () {
    late StrokeProcessor processor;

    setUp(() {
      processor = const StrokeProcessor(pressureCurve: Curves.linear);
    });

    group('createPointFromEvent', () {
      test('이벤트의 position에서 포인트를 생성한다', () {
        const event = PointerDownEvent(position: Offset(50, 75));

        final point = processor.createPointFromEvent(event);

        expect(point.x, 50.0);
        expect(point.y, 75.0);
      });

      test('압력 범위가 동일하면 기본 압력(0.5)을 사용한다', () {
        const event = PointerDownEvent(
          position: Offset(50, 75),
          pressureMin: 0.0,
          pressureMax: 0.0,
          pressure: 0.0,
        );

        final point = processor.createPointFromEvent(event);

        expect(point.p, 0.5);
      });

      test('압력이 있으면 정규화된 압력값을 사용한다', () {
        const event = PointerDownEvent(
          position: Offset(50, 75),
          pressureMin: 0.0,
          pressureMax: 1.0,
          pressure: 0.75,
        );

        final point = processor.createPointFromEvent(event);

        expect(point.p, closeTo(0.75, 0.01));
      });

      test('pressureMax를 초과하는 압력은 1.0으로 클램프된다 (#보정 어긋난 기기)', () {
        // Android MotionEvent.getPressure()는 보정이 어긋난 기기에서
        // 선언된 범위를 초과할 수 있다. 클램프하지 않으면 Curve.transform의
        // assert(t >= 0 && t <= 1)에 걸려 디버그 빌드가 크래시한다.
        const event = PointerMoveEvent(
          position: Offset(50, 75),
          pressureMin: 0.0,
          pressureMax: 1.0,
          pressure: 1.2,
        );

        final point = processor.createPointFromEvent(event);

        expect(point.p, 1.0);
      });

      test('pressureMin 미만의 압력은 0.0으로 클램프된다', () {
        const event = PointerMoveEvent(
          position: Offset(50, 75),
          pressureMin: 0.5,
          pressureMax: 1.0,
          pressure: 0.2,
        );

        final point = processor.createPointFromEvent(event);

        expect(point.p, 0.0);
      });

      test('커스텀 pressureCurve가 스타일러스 하드웨어 필압에 적용된다', () {
        final customProcessor = StrokeProcessor(pressureCurve: Curves.easeIn);
        const event = PointerDownEvent(
          kind: PointerDeviceKind.stylus,
          position: Offset(50, 75),
          pressureMin: 0.0,
          pressureMax: 1.0,
          pressure: 0.5,
        );

        final point = customProcessor.createPointFromEvent(event);

        // easeIn 커브는 0.5 입력에 대해 0.5보다 작은 값을 반환
        expect(point.p, lessThan(0.5));
      });

      test('손가락 터치 필압에는 pressureCurve 를 적용하지 않는다 (kobic UB-633)', () {
        // 터치 필압은 접촉 면적 기반 값이라 필기 압력이 아니고, 속도 시뮬레이션의
        // 시작값으로만 쓰인다 — 곡선을 태우면 시뮬레이션 시작 두께가 달라진다.
        final customProcessor = StrokeProcessor(pressureCurve: Curves.easeIn);
        const event = PointerDownEvent(
          position: Offset(50, 75),
          pressureMin: 0.0,
          pressureMax: 1.0,
          pressure: 0.5,
        );

        final point = customProcessor.createPointFromEvent(event);

        expect(point.p, closeTo(0.5, 1e-9));
      });

      test('필압 정보가 없는 스타일러스의 중립값 0.5 에는 곡선을 적용하지 않는다', () {
        // 곡선을 태우면 필압 없는 입력이 선택한 굵기보다 두껍게 기록된다
        final customProcessor = StrokeProcessor(pressureCurve: Curves.easeOut);
        const event = PointerDownEvent(
          kind: PointerDeviceKind.stylus,
          position: Offset(50, 75),
        );

        final point = customProcessor.createPointFromEvent(event);

        expect(point.p, 0.5);
      });

      test('타임스탬프가 설정된다', () {
        const event = PointerDownEvent(position: Offset(50, 75));

        final point = processor.createPointFromEvent(event);

        expect(point.timestamp.toInt(), greaterThan(0));
      });
    });

    group('addPointToStroke', () {
      late ScribbleModeState modeState;

      setUp(() {
        modeState = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pencil),
          scaleFactor: 1.0,
        );
      });

      test('Erasing 상태이면 상태를 그대로 반환한다', () {
        final state = Erasing(scribble: createScribble());

        final result = processor.addPointToStroke(
          const PointerMoveEvent(position: Offset(50, 50)),
          state,
          modeState,
        );

        expect(result, same(state));
      });

      test('activeLine이 null이면 상태를 그대로 반환한다', () {
        final state = Drawing(scribble: createScribble());

        final result = processor.addPointToStroke(
          const PointerMoveEvent(position: Offset(50, 50)),
          state,
          modeState,
        );

        expect(result, same(state));
      });

      test('활성 라인에 포인트를 추가한다', () {
        final activeLine = createStroke(points: [createPoint(x: 0, y: 0)]);
        final state = Drawing(
          scribble: createScribble(),
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        final result = processor.addPointToStroke(
          const PointerMoveEvent(position: Offset(50, 50)),
          state,
          modeState,
        );

        expect(result, isA<Drawing>());
        final drawing = result as Drawing;
        expect(drawing.activeLine!.points.length, 2);
        expect(drawing.activeLine!.points.last.x, 50.0);
        expect(drawing.activeLine!.points.last.y, 50.0);
      });

      test('너무 가까운 포인트는 추가하지 않는다', () {
        final activeLine = createStroke(points: [createPoint(x: 50, y: 50)]);
        final state = Drawing(
          scribble: createScribble(),
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        // 매우 가까운 위치
        final result = processor.addPointToStroke(
          const PointerMoveEvent(position: Offset(50.001, 50.001)),
          state,
          modeState,
        );

        expect(result, isA<Drawing>());
        final drawing = result as Drawing;
        expect(drawing.activeLine!.points.length, 1);
      });
    });

    group('finishStroke', () {
      test('Drawing 상태가 아니면 상태를 그대로 반환한다', () {
        final state = Erasing(scribble: createScribble());

        final result = processor.finishStroke(state);

        expect(result, same(state));
      });

      test('activeLine이 null이면 상태를 그대로 반환한다', () {
        final state = Drawing(scribble: createScribble());

        final result = processor.finishStroke(state);

        expect(result, same(state));
      });

      test('activeLine을 strokes에 추가하고 activeLine을 null로 만든다', () {
        final scribble = createScribble();
        final activeLine = createStroke();
        final state = Drawing(
          scribble: scribble,
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        final result = processor.finishStroke(state);

        expect(result, isA<Drawing>());
        final drawing = result as Drawing;
        expect(drawing.activeLine, isNull);
        expect(drawing.scribble.strokes.length, 1);
      });

      test('기존 strokes를 유지하면서 activeLine을 추가한다', () {
        final existingStrokes = [createStroke(), createStroke()];
        final scribble = createScribble(strokes: existingStrokes);
        final activeLine = createStroke();
        final state = Drawing(
          scribble: scribble,
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        final result = processor.finishStroke(state);

        final drawing = result as Drawing;
        expect(drawing.scribble.strokes.length, 3);
      });

      test('textDrawables를 유지한다', () {
        final textDrawables = [createTextDrawable(id: 'text1')];
        final scribble = createScribble(textDrawables: textDrawables);
        final activeLine = createStroke();
        final state = Drawing(
          scribble: scribble,
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        final result = processor.finishStroke(state);

        final drawing = result as Drawing;
        expect(drawing.scribble.textDrawables.length, 1);
        expect(drawing.scribble.textDrawables.first.id, 'text1');
      });
    });
  });
}
