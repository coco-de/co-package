import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

class _RecordingActions implements NoteToolActions {
  final List<String> log = [];

  @override
  String get currentTool => 'pen';

  @override
  void selectTool(String ink) => log.add('selectTool $ink');

  @override
  void previousTool() => log.add('previousTool');

  @override
  void toggleEraser() => log.add('toggleEraser');

  @override
  void undo() => log.add('undo');

  @override
  void redo() => log.add('redo');

  @override
  void showToolPalette() => log.add('showToolPalette');

  @override
  void cyclePreset() => log.add('cyclePreset');
}

void main() {
  group('NotePencilGestureMap', () {
    test('defaults to previous tool and tool palette', () {
      const map = NotePencilGestureMap();

      expect(
        map.actionFor(NotePencilGesture.doubleTap),
        NotePencilAction.switchPreviousTool,
      );
      expect(
        map.actionFor(NotePencilGesture.squeeze),
        NotePencilAction.showToolPalette,
      );
    });

    test('keeps the persisted names', () {
      expect(NotePencilGesture.values.map((gesture) => gesture.name), [
        'doubleTap',
        'squeeze',
      ]);
      expect(NotePencilAction.values.map((action) => action.name), [
        'none',
        'switchPreviousTool',
        'toggleEraser',
        'undo',
        'redo',
        'showToolPalette',
        'cyclePreset',
      ]);
    });

    test('withAction changes one gesture', () {
      const map = NotePencilGestureMap();
      final changed = map.withAction(
        NotePencilGesture.squeeze,
        NotePencilAction.undo,
      );

      expect(changed.squeeze, NotePencilAction.undo);
      expect(changed.doubleTap, map.doubleTap);
      expect(
        changed.withAction(NotePencilGesture.doubleTap, NotePencilAction.none),
        const NotePencilGestureMap(
          doubleTap: NotePencilAction.none,
          squeeze: NotePencilAction.undo,
        ),
      );
      expect(map.copyWith(), map);
      expect(map.copyWith().hashCode, map.hashCode);
    });

    test('round trips through JSON', () {
      const map = NotePencilGestureMap(
        doubleTap: NotePencilAction.toggleEraser,
        squeeze: NotePencilAction.cyclePreset,
      );
      final json = NoteJson.decodeMap(NoteJson.encode(map.toJson()));

      expect(NotePencilGestureMap.fromJson(json), map);
      expect(map.toJson(), {
        'doubleTap': 'toggleEraser',
        'squeeze': 'cyclePreset',
      });
      expect(map.toString(), contains('cyclePreset'));
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 3, 'x', <Object?>[], {}]) {
        expect(
          NotePencilGestureMap.fromJson(json),
          const NotePencilGestureMap(),
        );
      }
      expect(
        NotePencilGestureMap.fromJson({'doubleTap': 'fly', 'squeeze': 'undo'}),
        const NotePencilGestureMap(squeeze: NotePencilAction.undo),
      );
    });
  });

  group('NotePencilGestureDispatcher', () {
    const calls = {
      NotePencilAction.none: <String>[],
      NotePencilAction.switchPreviousTool: ['previousTool'],
      NotePencilAction.toggleEraser: ['toggleEraser'],
      NotePencilAction.undo: ['undo'],
      NotePencilAction.redo: ['redo'],
      NotePencilAction.showToolPalette: ['showToolPalette'],
      NotePencilAction.cyclePreset: ['cyclePreset'],
    };

    test('covers every action', () {
      expect(calls.keys, containsAll(NotePencilAction.values));
    });

    for (final MapEntry(key: action, value: expected) in calls.entries) {
      test('runs ${action.name}', () {
        for (final gesture in NotePencilGesture.values) {
          final actions = _RecordingActions();
          final dispatcher = NotePencilGestureDispatcher(
            const NotePencilGestureMap().withAction(gesture, action),
            actions,
          );

          expect(dispatcher.dispatch(gesture), action);
          expect(actions.log, expected);
        }
      });
    }

    test('uses the map assigned last', () {
      final actions = _RecordingActions();
      final dispatcher = NotePencilGestureDispatcher(
        const NotePencilGestureMap(),
        actions,
      );

      dispatcher.dispatch(NotePencilGesture.doubleTap);
      dispatcher.map = const NotePencilGestureMap(
        doubleTap: NotePencilAction.redo,
      );
      dispatcher.dispatch(NotePencilGesture.doubleTap);

      expect(actions.log, ['previousTool', 'redo']);
      expect(dispatcher.actions, same(actions));
    });
  });
}
