import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ScribblePointerMode', () {
    test('모든 모드 존재', () {
      expect(ScribblePointerMode.values.length, 4);
      expect(ScribblePointerMode.values, contains(ScribblePointerMode.all));
      expect(ScribblePointerMode.values, contains(ScribblePointerMode.penOnly));
    });
  });

  group('Drawing', () {
    test('기본 생성', () {
      final scribble = createScribble();
      final state = Drawing(scribble: scribble);
      expect(state.scribble, scribble);
      expect(state.activePointerIds, isEmpty);
      expect(state.activeLine, isNull);
      expect(state.selectedStrokeIds, isEmpty);
      expect(state.pointerPosition, isNull);
    });

    test('active는 포인터 1개 이하일 때 true', () {
      final scribble = createScribble();
      expect(Drawing(scribble: scribble).active, true);
      expect(Drawing(scribble: scribble, activePointerIds: [1]).active, true);
      expect(Drawing(scribble: scribble, activePointerIds: [1, 2]).active, false);
    });

    test('lines — activeLine 없으면 strokes만', () {
      final stroke = createStroke();
      final scribble = createScribble(strokes: [stroke]);
      final state = Drawing(scribble: scribble);
      expect(state.lines.length, 1);
    });

    test('lines — activeLine 있으면 strokes + activeLine', () {
      final stroke = createStroke();
      final activeLine = createStroke();
      final scribble = createScribble(strokes: [stroke]);
      final state = Drawing(scribble: scribble, activeLine: activeLine);
      expect(state.lines.length, 2);
    });

    test('copyWith', () {
      final scribble = createScribble();
      final state = Drawing(scribble: scribble);
      final newScribble = createScribble(width: 999);
      final copied = state.copyWith(scribble: newScribble);
      expect(copied.scribble.width, 999);
      expect(copied.activePointerIds, isEmpty);
    });

    test('copyWith 부분 변경', () {
      final state = Drawing(scribble: createScribble());
      final copied = state.copyWith(activePointerIds: [1, 2]);
      expect(copied.activePointerIds, [1, 2]);
      expect(copied.activeLine, isNull);
    });
  });

  group('Erasing', () {
    test('기본 생성', () {
      final scribble = createScribble();
      final state = Erasing(scribble: scribble);
      expect(state.scribble, scribble);
      expect(state.activePointerIds, isEmpty);
    });

    test('lines는 strokes만', () {
      final stroke = createStroke();
      final scribble = createScribble(strokes: [stroke]);
      final state = Erasing(scribble: scribble);
      expect(state.lines.length, 1);
    });

    test('copyWith', () {
      final scribble = createScribble();
      final state = Erasing(scribble: scribble);
      final copied = state.copyWith(activePointerIds: [1]);
      expect(copied.activePointerIds, [1]);
    });
  });

  group('ScribbleState sealed class', () {
    test('Drawing은 ScribbleState', () {
      final state = Drawing(scribble: createScribble());
      expect(state, isA<ScribbleState>());
    });

    test('Erasing은 ScribbleState', () {
      final state = Erasing(scribble: createScribble());
      expect(state, isA<ScribbleState>());
    });

    test('switch 패턴 매칭', () {
      final ScribbleState state = Drawing(scribble: createScribble());
      final result = switch (state) {
        Drawing() => 'drawing',
        Erasing() => 'erasing',
      };
      expect(result, 'drawing');
    });
  });
}
