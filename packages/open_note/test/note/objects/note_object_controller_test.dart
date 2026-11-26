import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

import 'support/objects_test_support.dart';

List<String> ids(NoteObjectController controller) => [
  for (final object in controller.objects) object.id,
];

void main() {
  late NoteUndoStack history;
  late int notifications;

  NoteObjectController make(
    List<NoteObject> objects, {
    NoteObjectRegistry? registry,
    NoteIdFactory? idFactory,
    NoteClock? clock,
  }) {
    final controller = NoteObjectController(
      objects: objects,
      history: history,
      idFactory: idFactory ?? counterIds('copy'),
      clock: clock,
      registry: registry,
    );
    controller.addListener(() => notifications++);

    return controller;
  }

  setUp(() {
    history = NoteUndoStack();
    notifications = 0;
  });

  group('content', () {
    test('keeps order, dropping empty and repeated ids', () {
      final controller = make([
        box('a'),
        box(''),
        box('b'),
        box('a', label: 'second a'),
      ]);

      expect(ids(controller), ['a', 'b']);
      expect((controller.find('a')! as BoxObject).label, '');
      expect(controller.find('nope'), isNull);
    });

    test('objects, selection and ids cannot be modified from outside', () {
      final controller = make([box('a')])..select('a');

      expect(() => controller.objects.add(box('b')), throwsUnsupportedError);
      expect(() => controller.selectedIds.add('b'), throwsUnsupportedError);
      expect(() => controller.selection.clear(), throwsUnsupportedError);
    });

    test('createId uses the injected factory', () {
      final controller = make([], idFactory: counterIds('x'));

      expect(controller.createId(), 'x-1');
      expect(controller.createId(), 'x-2');
    });
  });

  group('selection', () {
    test('select replaces, additive adds, toggle and clear work', () {
      final controller = make([box('a'), box('b'), box('c')])..select('b');
      expect(controller.selectedIds, {'b'});

      controller.select('a', additive: true);
      expect(controller.selectedIds, {'a', 'b'});
      // The selection list follows the stacking order, not the click order.
      expect(controller.selection.map((o) => o.id), ['a', 'b']);

      controller.toggleSelection('b');
      expect(controller.selectedIds, {'a'});
      controller.toggleSelection('c');
      expect(controller.selectedIds, {'a', 'c'});

      controller.select('c');
      expect(controller.selectedIds, {'c'});
      controller.selectAll();
      expect(controller.selectedIds, {'a', 'b', 'c'});
      controller.clearSelection();
      expect(controller.selectedIds, isEmpty);
    });

    test('notifies only on real changes and ignores unknown ids', () {
      final controller = make([box('a')]);

      controller.select('zzz');
      controller.toggleSelection('zzz');
      controller.clearSelection();
      expect(notifications, 0);

      controller.select('a');
      controller.select('a');
      controller.select('a', additive: true);
      controller.selectAll();
      expect(notifications, 1);
    });

    test('selecting is not recorded in the history', () {
      make([box('a')])
        ..select('a')
        ..clearSelection();

      expect(history.undoLength, 0);
    });

    test('selectionBounds covers the rotated selection', () {
      final controller = make([
        box('a', bounds: const Rect.fromLTWH(0, 0, 10, 10)),
        box(
          'b',
          bounds: const Rect.fromLTWH(100, 100, 40, 20),
          rotation: math.pi / 2,
        ),
      ]);
      expect(controller.selectionBounds, isNull);

      controller.select('b');
      // Turned a quarter, 40x20 becomes 20x40 about (120, 110).
      expect(
        controller.selectionBounds,
        rectCloseTo(const Rect.fromLTRB(110, 90, 130, 130)),
      );
      controller.selectAll();
      expect(
        controller.selectionBounds,
        rectCloseTo(const Rect.fromLTRB(0, 0, 130, 130)),
      );
    });
  });

  group('editing', () {
    test(
      'editing selects only that object and ends when it stops being so',
      () {
        final controller = make([box('a'), box('b')])..selectAll();

        expect(controller.beginEditing('zzz'), isFalse);
        expect(controller.beginEditing('a'), isTrue);
        expect(controller.selectedIds, {'a'});
        expect(controller.editingId, 'a');

        controller.select('a');
        expect(controller.editingId, 'a');

        controller.select('b', additive: true);
        expect(controller.editingId, isNull);

        controller
          ..beginEditing('a')
          ..select('b');
        expect(controller.editingId, isNull);

        controller
          ..beginEditing('a')
          ..clearSelection();
        expect(controller.editingId, isNull);
      },
    );

    test('endEditing keeps the selection and is idempotent', () {
      final controller = make([box('a')])..beginEditing('a');
      notifications = 0;

      controller
        ..endEditing()
        ..endEditing();

      expect(controller.editingId, isNull);
      expect(controller.selectedIds, {'a'});
      expect(notifications, 1);
    });

    test('removing the edited object ends editing', () {
      final controller = make([box('a'), box('b')])..beginEditing('a');

      controller.remove(['a']);

      expect(controller.editingId, isNull);
      expect(controller.selectedIds, isEmpty);
    });
  });

  group('add and update', () {
    test('add puts the object on top and selects it', () {
      final controller = make([box('a')])..select('a');

      expect(controller.add(box('b')), isTrue);

      expect(ids(controller), ['a', 'b']);
      expect(controller.selectedIds, {'b'});
      expect(history.undoLength, 1);
    });

    test('add without select keeps the selection', () {
      final controller = make([box('a')])..select('a');

      controller.add(box('b'), select: false);

      expect(controller.selectedIds, {'a'});
    });

    test('add refuses empty and used ids', () {
      final controller = make([box('a')]);
      notifications = 0;

      expect(controller.add(box('')), isFalse);
      expect(controller.add(box('a', label: 'other')), isFalse);

      expect(notifications, 0);
      expect(history.undoLength, 0);
    });

    test('update replaces by id and ignores equal or unknown objects', () {
      final controller = make([box('a')]);
      notifications = 0;

      expect(controller.update(box('a')), isFalse);
      expect(controller.update(box('zzz')), isFalse);
      expect(notifications, 0);
      expect(history.undoLength, 0);

      expect(controller.update(box('a', label: 'new')), isTrue);
      expect((controller.find('a')! as BoxObject).label, 'new');
      expect(notifications, 1);
      expect(history.undoLength, 1);
    });

    test('update applies to a locked object (a locked mask still reveals)', () {
      final controller = make([box('a', locked: true)]);

      expect(
        controller.update(box('a', locked: true, label: 'revealed')),
        isTrue,
      );
    });
  });

  group('transforms', () {
    test('moveBy moves unlocked objects only', () {
      final controller = make([box('a'), box('b', locked: true)]);

      controller.moveBy(['a', 'b', 'zzz'], const Offset(5, -3));

      expect(
        controller.find('a')!.bounds,
        const Rect.fromLTWH(105, 97, 100, 80),
      );
      expect(
        controller.find('b')!.bounds,
        const Rect.fromLTWH(100, 100, 100, 80),
      );
    });

    test('moveBy ignores zero and non-finite deltas', () {
      final controller = make([box('a')]);
      notifications = 0;

      controller
        ..moveBy(['a'], Offset.zero)
        ..moveBy(['a'], const Offset(double.nan, 0))
        ..moveBy(['a'], const Offset(0, double.infinity));

      expect(notifications, 0);
      expect(history.undoLength, 0);
    });

    test('resize mirrors negative sizes and enforces the minimum', () {
      final controller = make([box('a')]);

      controller.resize('a', const Rect.fromLTRB(50, 60, 20, 40));
      expect(controller.find('a')!.bounds, const Rect.fromLTRB(20, 40, 50, 60));

      controller.resize('a', const Rect.fromLTWH(100, 100, 2, 3));
      expect(
        controller.find('a')!.bounds,
        const Rect.fromLTWH(95, 95.5, 12, 12),
      );

      notifications = 0;
      controller
        ..resize('a', const Rect.fromLTWH(double.nan, 0, 20, 20))
        ..resize('a', controller.find('a')!.bounds);
      expect(notifications, 0);
    });

    test('rotate sets (not adds) a wrapped angle', () {
      final controller = make([box('a')]);

      controller.rotate('a', 3 * math.pi / 2);
      expect(controller.find('a')!.rotation, closeTo(-math.pi / 2, 1e-9));
      controller.rotate('a', math.pi / 4);
      expect(controller.find('a')!.rotation, closeTo(math.pi / 4, 1e-9));

      notifications = 0;
      controller
        ..rotate('a', math.pi / 4)
        ..rotate('a', double.nan);
      expect(notifications, 0);
    });

    test('locked objects ignore resize, rotate and remove', () {
      final controller = make([box('a', locked: true)]);
      notifications = 0;

      controller
        ..resize('a', const Rect.fromLTWH(0, 0, 50, 50))
        ..rotate('a', 1)
        ..remove(['a']);

      expect(notifications, 0);
      expect(controller.find('a'), box('a', locked: true));
      expect(history.undoLength, 0);
    });

    test('remove drops the unlocked objects and their selection', () {
      final controller = make([box('a'), box('b', locked: true), box('c')])
        ..selectAll();

      controller.remove(['a', 'b', 'c']);

      expect(ids(controller), ['b']);
      expect(controller.selectedIds, {'b'});
    });

    test('setLocked and setOpacity apply and clamp', () {
      final controller = make([box('a')]);

      controller.setLocked(['a'], true);
      expect(controller.find('a')!.locked, isTrue);
      controller.setOpacity(['a'], 4);
      expect(controller.find('a')!.opacity, 1);
      controller.setOpacity(['a'], -1);
      expect(controller.find('a')!.opacity, 0);

      notifications = 0;
      controller
        ..setOpacity(['a'], double.nan)
        ..setLocked(['a'], true)
        ..setOpacity(['a'], 0);
      expect(notifications, 0);
    });
  });

  group('duplicate', () {
    test('copies on top with new ids, offset, unlocked and selected', () {
      final controller = make([
        const NoteStickyObject(
          id: 's1',
          bounds: Rect.fromLTWH(0, 0, 50, 50),
          text: 'one',
          locked: true,
        ),
        const NoteStickyObject(id: 's2', bounds: Rect.fromLTWH(9, 9, 50, 50)),
      ]);

      final copies = controller.duplicate([
        's1',
        's2',
      ], offset: const Offset(3, 4));

      expect(copies, ['copy-1', 'copy-2']);
      expect(ids(controller), ['s1', 's2', 'copy-1', 'copy-2']);
      final first = controller.find('copy-1')! as NoteStickyObject;
      expect(first.text, 'one');
      expect(first.locked, isFalse);
      expect(first.bounds, const Rect.fromLTWH(3, 4, 50, 50));
      expect(controller.selectedIds, {'copy-1', 'copy-2'});
      expect(history.undoLength, 1);
      history.undo();
      expect(ids(controller), ['s1', 's2']);
    });

    test('copies a foreign kind through the registry', () {
      final controller = make([
        box('a', label: 'x', rotation: 0.5),
      ], registry: testRegistry());

      final copies = controller.duplicate(['a']);

      final copy = controller.find(copies.single)! as BoxObject;
      expect(copy.label, 'x');
      expect(copy.rotation, 0.5);
      expect(
        copy.bounds,
        const Rect.fromLTWH(
          100,
          100,
          100,
          80,
        ).shift(NoteObjectController.defaultDuplicateOffset),
      );
    });

    test('skips a foreign kind it cannot give a new id', () {
      final controller = make([box('a')]);
      notifications = 0;

      expect(controller.duplicate(['a']), isEmpty);
      expect(controller.duplicate(['zzz']), isEmpty);

      expect(ids(controller), ['a']);
      expect(notifications, 0);
    });

    test('keeps the raw data of an unknown kind', () {
      final controller = make([
        const NoteUnknownObject(
          id: 'u',
          bounds: Rect.fromLTWH(0, 0, 10, 10),
          unknownKind: 'future',
          payload: {'magic': 7},
        ),
      ]);

      final copy =
          controller.find(controller.duplicate(['u']).single)!
              as NoteUnknownObject;

      expect(copy.kind, 'future');
      expect(copy.payload, {'magic': 7});
      expect(copy.id, 'copy-1');
    });

    test('asks for another id when the factory repeats one', () {
      final sequence = ['s', 's', 'fresh'].iterator;
      final controller = make([
        const NoteStickyObject(id: 's', bounds: Rect.fromLTWH(0, 0, 20, 20)),
      ], idFactory: () => (sequence..moveNext()).current);

      expect(controller.duplicate(['s']), ['fresh']);
    });
  });

  group('stacking order', () {
    NoteObjectController letters() => make([
      for (final id in ['a', 'b', 'c', 'd', 'e']) box(id),
    ]);

    test('bringToFront and sendToBack keep the group order', () {
      final controller = letters()..bringToFront(['d', 'b']);
      expect(ids(controller), ['a', 'c', 'e', 'b', 'd']);

      controller.sendToBack(['e', 'd']);
      expect(ids(controller), ['e', 'd', 'a', 'c', 'b']);
    });

    test('moveForward steps a block past one neighbour', () {
      final controller = letters()..moveForward(['a', 'b']);
      expect(ids(controller), ['c', 'a', 'b', 'd', 'e']);

      controller.moveForward(['c', 'e']);
      expect(ids(controller), ['a', 'c', 'b', 'd', 'e']);
    });

    test('moveBackward steps a block past one neighbour', () {
      final controller = letters()..moveBackward(['d', 'e']);
      expect(ids(controller), ['a', 'b', 'd', 'e', 'c']);

      controller.moveBackward(['a']);
      expect(ids(controller), ['a', 'b', 'd', 'e', 'c']);
    });

    test('a move that changes nothing records nothing', () {
      final controller = letters();
      notifications = 0;

      controller
        ..bringToFront(['e'])
        ..sendToBack(['a'])
        ..moveForward(['e'])
        ..moveBackward(['a'])
        ..bringToFront(['zzz']);

      expect(notifications, 0);
      expect(history.undoLength, 0);
    });
  });

  group('objectAt', () {
    test('returns the topmost object under the point', () {
      final controller = make([
        box('bottom', bounds: const Rect.fromLTWH(0, 0, 100, 100)),
        box('top', bounds: const Rect.fromLTWH(50, 50, 100, 100)),
      ]);

      expect(controller.objectAt(const Offset(75, 75))!.id, 'top');
      expect(controller.objectAt(const Offset(10, 10))!.id, 'bottom');
      expect(controller.objectAt(const Offset(200, 10)), isNull);
    });

    test('honours rotation', () {
      final controller = make([
        box(
          'r',
          bounds: const Rect.fromLTWH(0, 40, 100, 20),
          rotation: math.pi / 2,
        ),
      ]);

      expect(controller.objectAt(const Offset(50, 5))!.id, 'r');
      expect(controller.objectAt(const Offset(5, 50)), isNull);
    });

    test('skips nothing: locked and invisible objects count', () {
      final controller = make([box('a', opacity: 0, locked: true)]);

      expect(controller.objectAt(const Offset(150, 140))!.id, 'a');
    });
  });

  group('history', () {
    test('undo restores both objects and selection, redo reapplies', () {
      final controller = make([box('a'), box('b')])..select('a');

      controller.remove(['a']);
      expect(controller.selectedIds, isEmpty);

      history.undo();
      expect(ids(controller), ['a', 'b']);
      expect(controller.selectedIds, {'a'});

      history.redo();
      expect(ids(controller), ['b']);
      expect(controller.selectedIds, isEmpty);
    });

    test('every mutation is one labelled step', () {
      final controller = make([box('a'), box('b')]);

      controller.moveBy(['a'], const Offset(1, 1));
      expect(history.undoLabel, 'Move');
      controller.resize('a', const Rect.fromLTWH(0, 0, 20, 20));
      expect(history.undoLabel, 'Resize');
      controller.rotate('a', 1);
      expect(history.undoLabel, 'Rotate');
      controller.add(box('c'));
      expect(history.undoLabel, 'Add');
      controller.update(box('c', label: 'x'));
      expect(history.undoLabel, 'Edit');
      controller.setOpacity(['a'], 0.5);
      expect(history.undoLabel, 'Change opacity');
      controller.setLocked(['a'], true);
      expect(history.undoLabel, 'Lock');
      controller.setLocked(['a'], false);
      expect(history.undoLabel, 'Unlock');
      controller.bringToFront(['a']);
      expect(history.undoLabel, 'Reorder');
      controller.remove(['b']);
      expect(history.undoLabel, 'Delete');
      expect(history.undoLength, 10);

      while (history.canUndo) {
        history.undo();
      }
      expect(controller.objects, [box('a'), box('b')]);
      while (history.canRedo) {
        history.redo();
      }
      expect(ids(controller), ['c', 'a']);
    });

    test('works without a history', () {
      final controller = NoteObjectController(objects: [box('a')]);

      controller.moveBy(['a'], const Offset(1, 0));

      expect(controller.find('a')!.bounds.left, 101);
    });

    test('a gesture is a single step labelled by its changes', () {
      final controller = make([box('a')])..select('a');

      controller.beginGesture();
      expect(controller.isGestureActive, isTrue);
      for (var i = 0; i < 10; i++) {
        controller.moveBy(['a'], const Offset(2, 1));
      }
      controller.endGesture();

      expect(controller.isGestureActive, isFalse);
      expect(history.undoLength, 1);
      expect(history.undoLabel, 'Move');
      history.undo();
      expect(controller.find('a'), box('a'));
      history.redo();
      expect(
        controller.find('a')!.bounds,
        const Rect.fromLTWH(120, 110, 100, 80),
      );
    });

    test('nested gestures merge into the outermost one', () {
      final controller = make([box('a')]);

      controller
        ..beginGesture()
        ..moveBy(['a'], const Offset(1, 0))
        ..beginGesture()
        ..moveBy(['a'], const Offset(1, 0))
        ..endGesture();
      expect(history.undoLength, 0);
      controller.endGesture();

      expect(history.undoLength, 1);
    });

    test('a gesture that changes nothing records nothing', () {
      final controller = make([box('a')]);

      controller
        ..beginGesture()
        ..moveBy(['a'], const Offset(5, 0))
        ..moveBy(['a'], const Offset(-5, 0))
        ..endGesture()
        ..endGesture();

      expect(history.undoLength, 0);
    });

    test('cancelGesture restores objects and selection, records nothing', () {
      final controller = make([box('a'), box('b')])..select('b');

      controller
        ..beginGesture()
        ..select('a')
        ..moveBy(['a'], const Offset(30, 30))
        ..beginGesture()
        ..cancelGesture();

      expect(controller.find('a'), box('a'));
      expect(controller.selectedIds, {'b'});
      expect(controller.isGestureActive, isFalse);
      expect(history.undoLength, 0);
    });

    test('an undo during a gesture moves its starting point', () {
      final controller = make([box('a')])..moveBy(['a'], const Offset(10, 0));

      controller.beginGesture();
      history.undo();
      controller
        ..moveBy(['a'], const Offset(0, 5))
        ..endGesture();

      history.undo();
      expect(controller.find('a'), box('a'));
    });

    test('shares one stack with other commands in order', () {
      final log = <String>[];
      final controller = make([box('a')]);

      controller.moveBy(['a'], const Offset(1, 0));
      history.push(
        NoteCallbackUndoable(
          label: 'Ink',
          onUndo: () => log.add('undo ink'),
          onRedo: () => log.add('redo ink'),
        ),
      );
      history.undo();
      expect(log, ['undo ink']);
      expect(controller.find('a')!.bounds.left, 101);
      history.undo();
      expect(controller.find('a')!.bounds.left, 100);
    });
  });

  group('replaceAll', () {
    test('loads without history and drops selection and editing', () {
      final controller = make([box('a')])..beginEditing('a');
      notifications = 0;

      controller.replaceAll([box('x'), box('x'), box('y')]);

      expect(ids(controller), ['x', 'y']);
      expect(controller.selectedIds, isEmpty);
      expect(controller.editingId, isNull);
      expect(history.undoLength, 0);
      expect(notifications, 1);
    });

    test('earlier undo steps do nothing afterwards', () {
      final controller = make([box('a')])..moveBy(['a'], const Offset(9, 9));
      controller.replaceAll([box('z')]);

      history.undo();

      expect(ids(controller), ['z']);
      history.redo();
      expect(ids(controller), ['z']);
    });

    test('does not notify when nothing differs', () {
      final controller = make([box('a')]);
      notifications = 0;

      controller.replaceAll([box('a')]);

      expect(notifications, 0);
    });

    test('abandons an open gesture', () {
      final controller = make([box('a')])..beginGesture();

      controller.replaceAll([box('b')]);
      controller
        ..moveBy(['b'], const Offset(1, 0))
        ..endGesture();

      expect(history.undoLength, 1);
    });
  });

  group('pending editor input', () {
    /// Registers input that relabels the box to [typed].
    NotePendingEditRegistration typing(
      NoteObjectController controller,
      String id,
      String typed,
    ) => controller.registerPendingEdit(id, (current) {
      final source = current as BoxObject;

      return source.label == typed ? null : source.relabel(typed);
    });

    test('flush commits it as its own step, once', () {
      final controller = make([box('a')])..beginEditing('a');
      typing(controller, 'a', 'typed');

      controller
        ..flushPendingEdits()
        ..flushPendingEdits();

      expect((controller.find('a')! as BoxObject).label, 'typed');
      expect(history.undoLength, 1);
      expect(controller.editingId, 'a');
    });

    test('is committed before editing ends, and before a gesture', () {
      final controller = make([box('a'), box('b')])..beginEditing('a');
      typing(controller, 'a', 'first');

      controller.beginGesture();
      controller
        ..moveBy(['b'], const Offset(4, 0))
        ..endGesture();

      expect(history.undoLength, 2);
      history.undo();
      expect((controller.find('a')! as BoxObject).label, 'first');
      history.undo();
      expect((controller.find('a')! as BoxObject).label, '');
    });

    for (final (name, action)
        in <(String, void Function(NoteObjectController))>[
          ('select another', (c) => c.select('b')),
          ('clearSelection', (c) => c.clearSelection()),
          ('selectAll', (c) => c.selectAll()),
          ('endEditing', (c) => c.endEditing()),
          ('beginEditing another', (c) => c.beginEditing('b')),
          ('add and select', (c) => c.add(box('n'))),
          ('duplicate', (c) => c.duplicate(['a'])),
          ('remove the edited object', (c) => c.remove(['a'])),
        ]) {
      test('is committed first by $name', () {
        final controller = make([box('a'), box('b')], registry: testRegistry())
          ..beginEditing('a');
        typing(controller, 'a', 'kept');

        action(controller);

        // The input became a separate step before whatever followed.
        while (history.undoLength > 1) {
          history.undo();
        }
        expect((controller.find('a')! as BoxObject).label, 'kept');
      });
    }

    test('actions that keep the session do not commit it', () {
      final controller = make([box('a'), box('b')])..beginEditing('a');
      typing(controller, 'a', 'draft');

      controller
        ..select('a')
        ..add(box('c'), select: false)
        ..setOpacity(['b'], 0.5);

      expect((controller.find('a')! as BoxObject).label, '');
    });

    test('a cancelled registration is not committed', () {
      final controller = make([box('a')])..beginEditing('a');
      final registration = typing(controller, 'a', 'gone');
      expect(registration.isActive, isTrue);

      registration.cancel();
      controller.endEditing();

      expect(registration.isActive, isFalse);
      expect((controller.find('a')! as BoxObject).label, '');
    });

    test('commit applies to the current object, not a stale one', () {
      final controller = make([box('a')]);
      final registration = typing(controller, 'a', 'typed');
      controller.moveBy(['a'], const Offset(7, 0));

      registration.commit();

      expect(controller.find('a')!.bounds.left, 107);
      expect((controller.find('a')! as BoxObject).label, 'typed');
    });

    test('replaceAll drops it', () {
      final controller = make([box('a')])..beginEditing('a');
      final registration = typing(controller, 'a', 'typed');

      controller.replaceAll([box('a')]);
      registration.commit();

      expect(registration.isActive, isFalse);
      expect((controller.find('a')! as BoxObject).label, '');
    });

    test('nothing is committed while an undo is running', () {
      final controller = make([box('a')])..moveBy(['a'], const Offset(1, 0));
      typing(controller, 'a', 'typed');
      history.push(
        NoteCallbackUndoable(
          label: 'probe',
          onUndo: controller.flushPendingEdits,
          onRedo: () {},
        ),
      );

      history.undo();

      expect((controller.find('a')! as BoxObject).label, '');
    });
  });

  group('clock and disposal', () {
    test('modifiedAt follows the injected clock', () {
      var now = DateTime(2030);
      final controller = make([box('a')], clock: () => now);
      expect(controller.modifiedAt, isNull);

      controller.moveBy(['a'], const Offset(1, 0));
      expect(controller.modifiedAt, DateTime(2030));

      now = DateTime(2031);
      history.undo();
      expect(controller.modifiedAt, DateTime(2031));

      controller.replaceAll([box('b')]);
      expect(controller.modifiedAt, isNull);
    });

    test('every method is a harmless no-op after dispose', () {
      final controller = NoteObjectController(
        objects: [box('a')],
        history: history,
        registry: testRegistry(),
      )..moveBy(['a'], const Offset(1, 0));
      final steps = history.undoLength;
      controller.dispose();

      controller
        ..select('a')
        ..toggleSelection('a')
        ..selectAll()
        ..clearSelection()
        ..endEditing()
        ..moveBy(['a'], const Offset(9, 9))
        ..resize('a', const Rect.fromLTWH(0, 0, 20, 20))
        ..rotate('a', 1)
        ..remove(['a'])
        ..bringToFront(['a'])
        ..sendToBack(['a'])
        ..moveForward(['a'])
        ..moveBackward(['a'])
        ..setLocked(['a'], true)
        ..setOpacity(['a'], 0)
        ..replaceAll([box('b')])
        ..beginGesture()
        ..endGesture()
        ..cancelGesture()
        ..flushPendingEdits();
      expect(controller.add(box('b')), isFalse);
      expect(controller.update(box('a', label: 'x')), isFalse);
      expect(controller.beginEditing('a'), isFalse);
      expect(controller.duplicate(['a']), isEmpty);
      expect(
        controller.registerPendingEdit('a', (current) => null).isActive,
        isFalse,
      );

      // A step recorded before disposal can still be undone safely.
      history.undo();
      expect(history.undoLength, steps - 1);
    });
  });
}
