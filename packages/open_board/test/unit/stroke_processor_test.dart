import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/stroke/stroke_processor.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('StrokeProcessor', () {
    late StrokeProcessor processor;

    setUp(() {
      processor = const StrokeProcessor();
    });

    group('createPointFromEvent', () {
      test('이벤트의 position에서 포인트를 생성한다', () {
        const event = PointerDownEvent(
          position: Offset(50, 75),
        );

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

      test('커스텀 pressureCurve가 적용된다', () {
        final customProcessor = StrokeProcessor(
          pressureCurve: Curves.easeIn,
        );
        const event = PointerDownEvent(
          position: Offset(50, 75),
          pressureMin: 0.0,
          pressureMax: 1.0,
          pressure: 0.5,
        );

        final point = customProcessor.createPointFromEvent(event);

        // easeIn 커브는 0.5 입력에 대해 0.5보다 작은 값을 반환
        expect(point.p, lessThan(0.5));
      });

      test('타임스탬프가 설정된다', () {
        const event = PointerDownEvent(
          position: Offset(50, 75),
        );

        final point = processor.createPointFromEvent(event);

        expect(point.timestamp.toInt(), greaterThan(0));
      });
    });

    group('addPointToStroke', () {
      late ScribbleModeState modeState;

      setUp(() {
        modeState = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(
            selectedInk: InkModes.pencil,
          ),
          scaleFactor: 1.0,
        );
      });

      test('Erasing 상태이면 상태를 그대로 반환한다', () {
        final state = Erasing(scribble: createScribble());

        final result = processor.addPointToStroke(
          const PointerMoveEvent(
            position: Offset(50, 50),
          ),
          state,
          modeState,
        );

        expect(result, same(state));
      });

      test('activeLine이 null이면 상태를 그대로 반환한다', () {
        final state = Drawing(scribble: createScribble());

        final result = processor.addPointToStroke(
          const PointerMoveEvent(
            position: Offset(50, 50),
          ),
          state,
          modeState,
        );

        expect(result, same(state));
      });

      test('활성 라인에 포인트를 추가한다', () {
        final activeLine = createStroke(
          points: [createPoint(x: 0, y: 0)],
        );
        final state = Drawing(
          scribble: createScribble(),
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        final result = processor.addPointToStroke(
          const PointerMoveEvent(
            position: Offset(50, 50),
          ),
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
        final activeLine = createStroke(
          points: [createPoint(x: 50, y: 50)],
        );
        final state = Drawing(
          scribble: createScribble(),
          activeLine: activeLine,
          activePointerIds: const [1],
        );

        // 매우 가까운 위치
        final result = processor.addPointToStroke(
          const PointerMoveEvent(
            position: Offset(50.001, 50.001),
          ),
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

    group('calculateRadius', () {
      test('thinning이 0이면 size의 절반을 반환한다', () {
        final result = processor.calculateRadius(10.0, 0.0, 0.5);
        expect(result, 5.0);
      });

      test('thinning이 높고 pressure가 낮으면 반지름이 작아진다', () {
        final lowPressure = processor.calculateRadius(10.0, 0.7, 0.1);
        final highPressure = processor.calculateRadius(10.0, 0.7, 0.9);

        expect(lowPressure, lessThan(highPressure));
      });

      test('size가 0이면 반지름이 0이다', () {
        final result = processor.calculateRadius(0.0, 0.7, 0.5);
        expect(result, 0.0);
      });

      test('기본 공식을 정확히 따른다: size * (0.5 - thinning * (0.5 - p))', () {
        // size=10, thinning=0.5, p=0.8
        // 10 * (0.5 - 0.5 * (0.5 - 0.8)) = 10 * (0.5 - 0.5 * (-0.3)) = 10 * (0.5 + 0.15) = 10 * 0.65 = 6.5
        final result = processor.calculateRadius(10.0, 0.5, 0.8);
        expect(result, closeTo(6.5, 0.001));
      });
    });
  });
}
