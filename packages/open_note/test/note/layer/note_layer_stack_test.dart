import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/state/scribble_mode.state.dart';
import 'package:open_note/src/note/core/note_undo_stack.dart';
import 'package:open_note/src/note/layer/note_layer.dart';
import 'package:open_note/src/note/layer/note_layer_content.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';

void main() {
  late int ids;
  late int strokeIds;

  NoteLayerStack stack({
    Iterable<NoteLayerContent> layers = const [],
    String? activeLayerId,
    NoteUndoStack? history,
  }) => NoteLayerStack(
    layers: layers,
    activeLayerId: activeLayerId,
    history: history,
    idFactory: () => 'layer-${ids++}',
    strokeIdFactory: () => 'stroke-${strokeIds++}',
  );

  setUp(() {
    ids = 0;
    strokeIds = 0;
  });

  final mode = ScribbleModeState(
    inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
  );

  /// 사용자의 펜 한 획 — 활성 레이어의 노티파이어에 포인터 이벤트를 보낸다.
  void draw(NoteLayerStack layers, double y) {
    final notifier = layers.activeNotifier;
    notifier
      ..onPointerDown(
        PointerDownEvent(
          position: Offset(0, y),
          kind: PointerDeviceKind.stylus,
        ),
        mode,
      )
      ..onPointerUpdate(
        PointerMoveEvent(
          position: Offset(40, y),
          kind: PointerDeviceKind.stylus,
        ),
        mode,
      )
      ..onPointerUp(
        PointerUpEvent(position: Offset(80, y), kind: PointerDeviceKind.stylus),
        mode,
      );
  }

  /// 각 레이어의 스트로크 y 좌표 — 내용 비교용.
  Map<String, List<double>> ink(NoteLayerStack layers) => {
    for (final content in layers.contents)
      content.layer.name: [
        for (final stroke in content.scribble.strokes) stroke.points.first.y,
      ],
  };

  group('시작 상태', () {
    test('레이어 없이 만들면 빈 레이어 하나로 시작한다', () {
      final layers = stack();

      expect(layers.layers.single.name, 'Layer 1');
      expect(layers.activeLayerId, 'layer-0');
      expect(layers.canDrawOnActive, isTrue);
      expect(layers.canUndo, isFalse);
      expect(layers.isEmpty, isTrue);
      expect(layers.revision, 0);
    });

    test('주어진 레이어를 쓰고, 활성 레이어 기본값은 맨 위다', () {
      final layers = stack(
        layers: [
          NoteLayerContent(
            layer: const NoteLayer(id: 'a', name: 'A'),
          ),
          NoteLayerContent(
            layer: const NoteLayer(id: 'b', name: 'B'),
          ),
        ],
      );

      expect(layers.layers.map((l) => l.id), ['a', 'b']);
      expect(layers.activeLayerId, 'b');
    });

    test('없는 id 를 활성으로 주면 맨 위, 중복 id 는 한 번만 담는다', () {
      final layers = stack(
        layers: [
          NoteLayerContent(
            layer: const NoteLayer(id: 'a', name: 'A'),
          ),
          NoteLayerContent(
            layer: const NoteLayer(id: 'a', name: 'dup'),
          ),
        ],
        activeLayerId: 'nope',
      );

      expect(layers.length, 1);
      expect(layers.activeLayerId, 'a');
    });

    test('모르는 id 로 조회 · 조작하면 ArgumentError', () {
      final layers = stack();

      expect(() => layers.setActive('x'), throwsArgumentError);
      expect(() => layers.notifierOf('x'), throwsArgumentError);
      expect(() => layers.removeLayer('x'), throwsArgumentError);
      expect(layers.layerById('x'), isNull);
      expect(layers.indexOf('x'), -1);
    });
  });

  group('레이어를 넘나드는 실행 취소', () {
    test('필기는 그린 순서대로 되돌리고 다시 실행한다', () {
      final layers = stack();
      final bottom = layers.activeLayerId;
      draw(layers, 10);
      final top = layers.addLayer().id;
      draw(layers, 20);
      layers.setActive(bottom);
      draw(layers, 30);

      expect(ink(layers), {
        'Layer 1': [10, 30],
        'Layer 2': [20],
      });

      layers.undo(); // 30 (bottom)
      expect(ink(layers)['Layer 1'], [10]);
      layers.undo(); // 20 (top)
      expect(ink(layers)['Layer 2'], isEmpty);
      layers.undo(); // add layer
      expect(layers.layers.map((l) => l.id), [bottom]);
      layers.undo(); // 10
      expect(ink(layers)['Layer 1'], isEmpty);
      expect(layers.canUndo, isFalse);

      layers
        ..redo()
        ..redo()
        ..redo()
        ..redo();
      expect(ink(layers), {
        'Layer 1': [10, 30],
        'Layer 2': [20],
      });
      expect(layers.layerById(top), isNotNull);
      expect(layers.canRedo, isFalse);
    });

    test('새 편집은 다시 실행 목록을 비운다', () {
      final layers = stack();
      draw(layers, 10);
      layers.undo();
      draw(layers, 20);

      expect(layers.canRedo, isFalse);
      expect(ink(layers)['Layer 1'], [20]);
    });

    test('같은 history 의 다른 컨트롤러 명령과 시간순으로 섞인다', () {
      final history = NoteUndoStack();
      final log = <String>[];
      final layers = stack(history: history);
      draw(layers, 10);
      history.push(
        NoteCallbackUndoable(
          label: 'object',
          onUndo: () => log.add('undo object'),
          onRedo: () => log.add('redo object'),
        ),
      );
      draw(layers, 20);

      layers.undo();
      expect(ink(layers)['Layer 1'], [10]);
      layers.undo();
      expect(log, ['undo object']);
      expect(ink(layers)['Layer 1'], [10]);
      layers.undo();
      expect(ink(layers)['Layer 1'], isEmpty);
    });

    test('revision 은 커밋마다 늘고 진행 중 프레임에는 그대로다', () {
      final layers = stack();
      var notified = 0;
      layers.addListener(() => notified++);
      final notifier = layers.activeNotifier;

      notifier.onPointerDown(
        const PointerDownEvent(
          position: Offset(0, 0),
          kind: PointerDeviceKind.stylus,
        ),
        mode,
      );
      notifier.onPointerUpdate(
        const PointerMoveEvent(
          position: Offset(40, 0),
          kind: PointerDeviceKind.stylus,
        ),
        mode,
      );
      expect(layers.revision, 0);
      expect(notified, 0);

      notifier.onPointerUp(
        const PointerUpEvent(
          position: Offset(80, 0),
          kind: PointerDeviceKind.stylus,
        ),
        mode,
      );
      expect(layers.revision, 1);
      expect(notified, 1);
    });
  });

  group('레이어 조작', () {
    test('추가는 지정 레이어 위에 놓고 활성화하며 undo 로 활성을 되돌린다', () {
      final layers = stack();
      final first = layers.activeLayerId;
      final top = layers.addLayer(name: 'Top').id;
      final middle = layers.addLayer(name: 'Middle', aboveId: first).id;

      expect(layers.layers.map((l) => l.id), [first, middle, top]);
      expect(layers.activeLayerId, middle);

      layers.undo();
      expect(layers.layers.map((l) => l.id), [first, top]);
      expect(layers.activeLayerId, top);
    });

    test('삭제는 아래 레이어를 활성화하고 undo 로 자리와 내용을 복구한다', () {
      final layers = stack();
      draw(layers, 10);
      final first = layers.activeLayerId;
      final second = layers.addLayer().id;
      draw(layers, 20);
      layers.addLayer();
      layers.setActive(second);

      expect(layers.removeLayer(second), isTrue);
      expect(layers.activeLayerId, first);
      expect(layers.length, 2);

      layers.undo();
      expect(layers.indexOf(second), 1);
      expect(layers.activeLayerId, second);
      expect(ink(layers)['Layer 2'], [20]);

      layers.redo();
      expect(layers.indexOf(second), -1);
    });

    test('마지막 한 레이어는 삭제할 수 없다', () {
      final layers = stack();

      expect(layers.removeLayer(layers.activeLayerId), isFalse);
      expect(layers.length, 1);
      expect(layers.canUndo, isFalse);
    });

    test('이름 · 표시 · 잠금 변경은 undo 되고, 같은 값은 기록하지 않는다', () {
      final layers = stack();
      final id = layers.activeLayerId;

      layers
        ..renameLayer(id, '  풀이  ')
        ..renameLayer(id, '   ')
        ..setVisible(id, false)
        ..setVisible(id, false)
        ..setLocked(id, true);

      expect(layers.activeLayer.name, '풀이');
      expect(layers.canDrawOnActive, isFalse);
      expect(layers.history.undoLength, 3);

      layers
        ..undo()
        ..undo()
        ..undo();
      expect(
        layers.activeLayer,
        const NoteLayer(id: 'layer-0', name: 'Layer 1'),
      );
    });

    test('불투명도 드래그는 미리보기 후 드래그 전 값으로 되돌릴 수 있다', () {
      final layers = stack();
      final id = layers.activeLayerId;

      layers
        ..previewOpacity(id, 0.7)
        ..previewOpacity(id, 0.4);
      expect(layers.history.undoLength, 0);

      layers.setOpacity(id, 0.3, from: 1);
      expect(layers.activeLayer.opacity, 0.3);
      layers.undo();
      expect(layers.activeLayer.opacity, 1);
      layers.redo();
      expect(layers.activeLayer.opacity, 0.3);
    });

    test('불투명도는 0..1 로 자르고 변화가 없으면 기록하지 않는다', () {
      final layers = stack();
      final id = layers.activeLayerId;

      layers
        ..setOpacity(id, 7)
        ..setOpacity(id, 1);

      expect(layers.activeLayer.opacity, 1);
      expect(layers.canUndo, isFalse);
    });

    test('순서 바꾸기는 자르고 undo 된다', () {
      final layers = stack();
      final a = layers.activeLayerId;
      final b = layers.addLayer().id;
      final c = layers.addLayer().id;

      layers.moveLayer(a, 99);
      expect(layers.layers.map((l) => l.id), [b, c, a]);
      layers.undo();
      expect(layers.layers.map((l) => l.id), [a, b, c]);
      layers.moveLayer(a, 0);
      expect(layers.history.undoLabel, isNot('move layer'));
    });

    test('복제는 바로 위에 새 id 의 사본을 만든다', () {
      final layers = stack();
      final id = layers.activeLayerId;
      draw(layers, 10);
      layers.setOpacity(id, 0.5);
      final original = layers.scribbleOf(id).strokes.single;

      final copy = layers.duplicateLayer(id);

      expect(layers.indexOf(copy.id), 1);
      expect(copy.name, 'Layer 1 copy');
      expect(copy.opacity, 0.5);
      final cloned = layers.scribbleOf(copy.id).strokes.single;
      expect(cloned.points, original.points);
      expect(cloned.id, isNot(original.id));

      // 사본을 지워도 원본은 그대로다.
      layers.clearLayer(copy.id);
      expect(layers.scribbleOf(id).strokes, hasLength(1));
    });

    test('아래로 병합한 뒤의 필기를 undo 해도 병합 내용이 유지된다', () {
      final layers = stack();
      final bottom = layers.activeLayerId;
      draw(layers, 10);
      final top = layers.addLayer().id;
      draw(layers, 20);

      expect(layers.mergeDown(bottom), isFalse);
      expect(layers.mergeDown(top), isTrue);
      expect(layers.length, 1);
      expect(layers.activeLayerId, bottom);
      expect(ink(layers)['Layer 1'], [10, 20]);

      draw(layers, 30);
      layers.undo(); // 병합 뒤의 필기만
      expect(ink(layers)['Layer 1'], [10, 20]);
      layers.undo(); // 병합
      expect(ink(layers), {
        'Layer 1': [10],
        'Layer 2': [20],
      });
      expect(layers.activeLayerId, top);
      layers.undo(); // top 필기
      expect(ink(layers)['Layer 2'], isEmpty);
      layers
        ..redo()
        ..redo()
        ..redo();
      expect(ink(layers)['Layer 1'], [10, 20, 30]);
      expect(layers.length, 1);
    });

    test('보이는 레이어 병합은 숨긴 레이어를 남긴다', () {
      final layers = stack();
      draw(layers, 10);
      final hidden = layers.addLayer().id;
      draw(layers, 20);
      layers.setVisible(hidden, false);
      layers.addLayer();
      draw(layers, 30);

      expect(layers.mergeVisible(), isTrue);

      expect(layers.length, 2);
      expect(ink(layers)['Layer 1'], [10, 30]);
      expect(layers.layerById(hidden), isNotNull);

      layers.undo();
      expect(layers.length, 3);
      expect(ink(layers)['Layer 1'], [10]);
      expect(ink(layers)['Layer 3'], [30]);
    });

    test('보이는 레이어가 하나면 병합하지 않는다', () {
      expect(stack().mergeVisible(), isFalse);
    });

    test('선택한 항목을 다른 레이어로 옮기고 한 번에 되돌린다', () {
      final layers = stack();
      final a = layers.activeLayerId;
      draw(layers, 10);
      draw(layers, 20);
      final b = layers.addLayer().id;
      draw(layers, 30);

      expect(
        layers.moveToLayer(fromId: a, toId: b, strokeIndexes: {0}),
        isTrue,
      );
      expect(ink(layers), {
        'Layer 1': [20],
        'Layer 2': [30, 10],
      });

      layers.undo();
      expect(ink(layers), {
        'Layer 1': [10, 20],
        'Layer 2': [30],
      });
      layers.redo();
      expect(ink(layers)['Layer 2'], [30, 10]);

      expect(
        layers.moveToLayer(fromId: a, toId: a, strokeIndexes: {0}),
        isFalse,
      );
      expect(
        layers.moveToLayer(fromId: a, toId: b, strokeIndexes: {9}),
        isFalse,
      );
    });

    test('텍스트와 이미지도 id 로 옮긴다', () {
      final layers = stack(
        layers: [
          NoteLayerContent(
            layer: const NoteLayer(id: 'a', name: 'A'),
            scribble: Scribble(
              textDrawables: [TextDrawable(id: 't', text: 'x')],
              imageDrawables: [ImageDrawable(id: 'i', source: 's')],
            ),
          ),
          NoteLayerContent(
            layer: const NoteLayer(id: 'b', name: 'B'),
          ),
        ],
      );

      layers.moveToLayer(
        fromId: 'a',
        toId: 'b',
        textIds: {'t'},
        imageIds: {'i'},
      );

      expect(layers.scribbleOf('a').textDrawables, isEmpty);
      expect(layers.scribbleOf('b').textDrawables.single.id, 't');
      expect(layers.scribbleOf('b').imageDrawables.single.id, 'i');
      layers.undo();
      expect(layers.scribbleOf('a').imageDrawables.single.id, 'i');
      expect(layers.scribbleOf('b').imageDrawables, isEmpty);
    });

    test('transformAll 은 바뀐 레이어만 한 번의 undo 로 묶는다', () {
      final layers = stack();
      draw(layers, 10);
      layers.addLayer();
      draw(layers, 20);
      layers.addLayer(); // 빈 레이어 — 변환 대상 아님

      layers.transformAll('shift', (scribble) {
        if (scribble.strokes.isEmpty) return scribble;
        final shifted = scribble.deepCopy();
        for (final stroke in shifted.strokes) {
          for (final point in stroke.points) {
            point.y += 100;
          }
        }

        return shifted;
      });
      expect(ink(layers)['Layer 1'], [110]);
      expect(ink(layers)['Layer 2'], [120]);

      layers.undo();
      expect(ink(layers)['Layer 1'], [10]);
      expect(ink(layers)['Layer 2'], [20]);
      layers.redo();
      expect(ink(layers)['Layer 2'], [120]);
    });

    test('dispose 뒤에는 명령이 아무것도 하지 않는다', () {
      final history = NoteUndoStack();
      final layers = stack(history: history);
      draw(layers, 10);
      layers.addLayer();

      layers.dispose();
      layers.dispose();

      expect(() => history.undo(), returnsNormally);
      expect(() => history.undo(), returnsNormally);
    });
  });
}
