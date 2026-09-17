import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ScribblePointerMode', () {
    test('모든 모드 존재', () {
      expect(ScribblePointerMode.values.length, 4);
      expect(ScribblePointerMode.values, contains(ScribblePointerMode.all));
      expect(
        ScribblePointerMode.values,
        contains(ScribblePointerMode.penOnly),
      );
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
      expect(
        Drawing(scribble: scribble, activePointerIds: [1, 2]).active,
        false,
      );
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

    test('copyWith', () {
      final scribble = createScribble();
      final state = Erasing(scribble: scribble);
      final copied = state.copyWith(activePointerIds: [1]);
      expect(copied.activePointerIds, [1]);
    });
  });

  group('copyWith pointerPosition sentinel (#커서 잔상 회귀)', () {
    // `pointerPosition ?? this.pointerPosition` 병합은 null 전달(커서 제거)을
    // 침묵 무시하여 터치/펜 지우개 사용 후 회색 커서 잔상이 남는 버그를 만들었다.
    test('Drawing.copyWith(pointerPosition: null)은 실제로 null을 설정한다', () {
      final state = Drawing(
        scribble: createScribble(),
        pointerPosition: createPoint(x: 10, y: 20),
      );
      final copied = state.copyWith(pointerPosition: null);
      expect(copied.pointerPosition, isNull);
    });

    test('Drawing.copyWith 미전달 시 기존 pointerPosition 유지', () {
      final state = Drawing(
        scribble: createScribble(),
        pointerPosition: createPoint(x: 10, y: 20),
      );
      final copied = state.copyWith(activePointerIds: [1]);
      expect(copied.pointerPosition, isNotNull);
      expect(copied.pointerPosition!.x, 10);
    });

    test('Erasing.copyWith(pointerPosition: null)은 실제로 null을 설정한다', () {
      final state = Erasing(
        scribble: createScribble(),
        pointerPosition: createPoint(x: 10, y: 20),
      );
      final copied = state.copyWith(pointerPosition: null);
      expect(copied.pointerPosition, isNull);
    });

    test('Erasing.copyWith 미전달 시 기존 pointerPosition 유지', () {
      final state = Erasing(
        scribble: createScribble(),
        pointerPosition: createPoint(x: 10, y: 20),
      );
      final copied = state.copyWith(scribble: createScribble(width: 1));
      expect(copied.pointerPosition, isNotNull);
      expect(copied.pointerPosition!.y, 20);
    });

    test('Erasing.copyWith에 새 pointerPosition 전달 시 교체', () {
      final state = Erasing(
        scribble: createScribble(),
        pointerPosition: createPoint(x: 10, y: 20),
      );
      final copied = state.copyWith(pointerPosition: createPoint(x: 5, y: 5));
      expect(copied.pointerPosition!.x, 5);
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
