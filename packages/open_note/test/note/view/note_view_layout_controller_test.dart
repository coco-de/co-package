import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import 'note_view_test_support.dart';

void main() {
  NoteViewLayoutController controller({
    NoteViewMode mode = NoteViewMode.single,
    List<NoteViewPane>? panes,
    int maxPanes = 2,
    double ratio = 0.5,
    Axis axis = Axis.horizontal,
  }) => NoteViewLayoutController(
    mode: mode,
    panes: panes ?? const [NoteViewPane(id: 'a', noteId: 'note', pageIndex: 3)],
    idFactory: counterIds(),
    maxPanes: maxPanes,
    ratio: ratio,
    axis: axis,
  );

  /// A real two-page spread starting at page 3.
  NoteViewLayoutController spreadLayout() =>
      controller()..setMode(NoteViewMode.twoPage);

  const two = [
    NoteViewPane(id: 'a', noteId: 'first', pageIndex: 1),
    NoteViewPane(id: 'b', noteId: 'second', pageIndex: 5),
  ];

  group('construction', () {
    test('starts with one empty pane', () {
      final layout = NoteViewLayoutController(idFactory: counterIds());

      expect(layout.mode, NoteViewMode.single);
      expect(layout.panes, [const NoteViewPane(id: 'p1')]);
      expect(layout.ratio, 0.5);
      expect(layout.axis, Axis.horizontal);
      expect(layout.fractions, [1]);
    });

    test('repairs a multi-pane mode with one pane to single', () {
      final layout = controller(mode: NoteViewMode.dualDocument);

      expect(layout.mode, NoteViewMode.single);
      expect(layout.panes, hasLength(1));
    });

    test('single keeps only the first pane', () {
      final layout = controller(panes: two);

      expect(layout.panes, [two.first]);
    });

    test(
      'twoPage forces the second pane to the next page of the same note',
      () {
        final layout = controller(mode: NoteViewMode.twoPage, panes: two);

        expect(layout.panes[1].noteId, 'first');
        expect(layout.panes[1].pageIndex, 2);
        expect(layout.panes[1].id, 'b');
      },
    );

    test('doubleReading shares the note but not the page', () {
      final layout = controller(mode: NoteViewMode.doubleReading, panes: two);

      expect(layout.panes[1].noteId, 'first');
      expect(layout.panes[1].pageIndex, 5);
    });

    test('replaces duplicate ids', () {
      final layout = controller(
        mode: NoteViewMode.split,
        panes: const [
          NoteViewPane(id: 'x'),
          NoteViewPane(id: 'x'),
        ],
      );

      expect(layout.panes.map((pane) => pane.id), ['x', 'p1']);
    });

    test('clamps the ratio and ignores a non-finite one', () {
      expect(controller(ratio: 0.95).ratio, 0.8);
      expect(controller(ratio: 0).ratio, 0.2);
      expect(controller(ratio: double.nan).ratio, 0.5);
    });

    test('clamps maxPanes to 2–4', () {
      expect(controller(maxPanes: 1).maxPanes, 2);
      expect(controller(maxPanes: 9).maxPanes, 4);
    });

    test('panes cannot be edited from outside', () {
      final layout = controller();

      expect(
        () => layout.panes.add(const NoteViewPane(id: 'z')),
        throwsUnsupportedError,
      );
    });
  });

  group('setMode', () {
    test('twoPage adds the following page side by side', () {
      final layout = controller(axis: Axis.vertical);

      layout.setMode(NoteViewMode.twoPage);

      expect(layout.mode, NoteViewMode.twoPage);
      expect(layout.axis, Axis.horizontal);
      expect(layout.panes[1].noteId, 'note');
      expect(layout.panes[1].pageIndex, 4);
    });

    test('doubleReading and split copy note and page', () {
      for (final mode in [NoteViewMode.doubleReading, NoteViewMode.split]) {
        final layout = controller();

        layout.setMode(mode);

        expect(layout.panes[1].noteId, 'note');
        expect(layout.panes[1].pageIndex, 3);
        expect(layout.panes[1].id, isNot(layout.panes[0].id));
      }
    });

    test('dualDocument adds an empty pane', () {
      final layout = controller();

      layout.setMode(NoteViewMode.dualDocument);

      expect(layout.panes[1].noteId, isNull);
      expect(layout.panes[1].pageIndex, 0);
    });

    test('single keeps the requested pane, else the first', () {
      final layout = controller(mode: NoteViewMode.split, panes: two);

      layout.setMode(NoteViewMode.single, keepPaneId: 'b');
      expect(layout.panes, [two[1]]);

      final other = controller(mode: NoteViewMode.split, panes: two);
      other.setMode(NoteViewMode.single, keepPaneId: 'nope');
      expect(other.panes, [two.first]);
    });

    test('switching between modes re-applies their rules', () {
      final layout = controller();
      layout.setMode(NoteViewMode.dualDocument);

      layout.setMode(NoteViewMode.twoPage);

      expect(layout.panes[1].noteId, 'note');
      expect(layout.panes[1].pageIndex, 4);
    });

    test('drops panes the new mode cannot hold', () {
      final layout = controller(
        mode: NoteViewMode.split,
        maxPanes: 3,
        panes: const [
          ...two,
          NoteViewPane(id: 'c'),
        ],
      );

      layout.setMode(NoteViewMode.dualDocument);

      expect(layout.panes.map((pane) => pane.id), ['a', 'b']);
    });

    test('notifies once and not for the same mode', () {
      final layout = controller();
      final counter = NotifyCounter(layout);

      layout.setMode(NoteViewMode.split);
      layout.setMode(NoteViewMode.split);

      expect(counter.count, 1);
    });
  });

  group('add and remove panes', () {
    test('adding to a single view splits it', () {
      final layout = controller();

      final added = layout.addPane(noteId: 'other', pageIndex: 2);

      expect(layout.mode, NoteViewMode.split);
      expect(layout.panes, [layout.panes.first, added]);
      expect(added!.noteId, 'other');
      expect(added.pageIndex, 2);
    });

    test('inserts at an index and clamps negative pages', () {
      final layout = controller();

      final added = layout.addPane(index: 0, pageIndex: -4);

      expect(layout.panes.first, added);
      expect(added!.pageIndex, 0);
    });

    test('refuses beyond maxPanes', () {
      final layout = controller(mode: NoteViewMode.split, panes: two);
      final counter = NotifyCounter(layout);

      expect(layout.addPane(), isNull);
      expect(counter.count, 0);
    });

    test('allows more panes when maxPanes says so', () {
      final layout = controller(maxPanes: 3);
      layout.addPane();
      layout.addPane();

      expect(layout.panes, hasLength(3));
      expect(layout.fractions, [0.5, 0.25, 0.25]);
      expect(layout.addPane(), isNull);
    });

    test('removing down to one pane returns to single', () {
      final layout = controller(mode: NoteViewMode.twoPage, panes: two);

      expect(layout.removePane('a'), isTrue);

      expect(layout.mode, NoteViewMode.single);
      expect(layout.panes.single.id, 'b');
    });

    test('keeps split with two of three panes left', () {
      final layout = controller(
        mode: NoteViewMode.split,
        maxPanes: 3,
        panes: const [
          ...two,
          NoteViewPane(id: 'c'),
        ],
      );

      layout.removePane('b');

      expect(layout.mode, NoteViewMode.split);
      expect(layout.panes.map((pane) => pane.id), ['a', 'c']);
    });

    test('never removes the last pane or an unknown one', () {
      final layout = controller();

      expect(layout.removePane('a'), isFalse);
      expect(layout.removePane('zzz'), isFalse);
    });
  });

  group('pages and notes', () {
    test('setPage clamps negatives and ignores unknown panes', () {
      final layout = controller(mode: NoteViewMode.split, panes: two);
      final counter = NotifyCounter(layout);

      layout.setPage('a', -3);
      layout.setPage('nope', 8);

      expect(layout.pane('a')!.pageIndex, 0);
      expect(layout.pane('b')!.pageIndex, 5);
      expect(counter.count, 1);
    });

    test('setPage keeps a spread consecutive from either side', () {
      final layout = spreadLayout();

      layout.setPage(layout.panes[0].id, 10);
      expect(layout.panes.map((p) => p.pageIndex), [10, 11]);

      layout.setPage(layout.panes[1].id, 6);
      expect(layout.panes.map((p) => p.pageIndex), [5, 6]);

      layout.setPage(layout.panes[1].id, 0);
      expect(layout.panes.map((p) => p.pageIndex), [0, 1]);
    });

    test('setNote changes both panes where they share a note', () {
      final reading = controller(mode: NoteViewMode.doubleReading, panes: two);
      reading.setNote('b', 'new', pageIndex: 2);
      expect(reading.panes.map((p) => p.noteId), ['new', 'new']);
      expect(reading.panes.map((p) => p.pageIndex), [2, 2]);

      final spread = controller(mode: NoteViewMode.twoPage, panes: two);
      spread.setNote('b', 'new', pageIndex: 4);
      expect(spread.panes.map((p) => p.pageIndex), [3, 4]);

      final dual = controller(mode: NoteViewMode.dualDocument, panes: two);
      dual.setNote('b', null);
      expect(dual.panes.map((p) => p.noteId), ['first', null]);
    });

    test('swapPanes exchanges the two panes', () {
      final layout = controller(mode: NoteViewMode.split, panes: two);

      layout.swapPanes();

      expect(layout.panes.map((p) => p.id), ['b', 'a']);
    });

    test('swapPanes takes explicit ids and ignores unknown ones', () {
      final layout = controller(
        mode: NoteViewMode.split,
        maxPanes: 3,
        panes: const [
          ...two,
          NoteViewPane(id: 'c'),
        ],
      );

      layout.swapPanes('a', 'c');
      expect(layout.panes.map((p) => p.id), ['c', 'b', 'a']);

      layout.swapPanes('a', 'nope');
      expect(layout.panes.map((p) => p.id), ['c', 'b', 'a']);
    });

    test('swapPanes does nothing to a spread', () {
      final layout = spreadLayout();
      final before = layout.panes;

      layout.swapPanes();

      expect(layout.panes, before);
    });
  });

  group('ratio and axis', () {
    test('setRatio clamps and notifies only on change', () {
      final layout = controller(mode: NoteViewMode.split, panes: two);
      final counter = NotifyCounter(layout);

      layout.setRatio(0.7);
      layout.setRatio(0.7);
      layout.setRatio(2);
      layout.setRatio(0.9);
      layout.setRatio(double.infinity);

      expect(layout.ratio, 0.8);
      expect(layout.fractions[0], 0.8);
      expect(layout.fractions[1], closeTo(0.2, 1e-9));
      expect(counter.count, 2);
    });

    test('setAxis notifies once', () {
      final layout = controller();
      final counter = NotifyCounter(layout);

      layout.setAxis(Axis.vertical);
      layout.setAxis(Axis.vertical);

      expect(layout.axis, Axis.vertical);
      expect(counter.count, 1);
    });
  });

  group('openBeside', () {
    test('right drop splits with the new note second', () {
      final layout = controller();

      final added = layout.openBeside('x', 2);

      expect(layout.mode, NoteViewMode.split);
      expect(layout.axis, Axis.horizontal);
      expect(layout.panes.map((p) => p.noteId), ['note', 'x']);
      expect(added!.pageIndex, 2);
    });

    test('each side picks the axis and order', () {
      final expected = {
        NoteDropSide.left: (Axis.horizontal, ['x', 'note']),
        NoteDropSide.right: (Axis.horizontal, ['note', 'x']),
        NoteDropSide.top: (Axis.vertical, ['x', 'note']),
        NoteDropSide.bottom: (Axis.vertical, ['note', 'x']),
      };
      for (final MapEntry(key: side, value: (axis, notes))
          in expected.entries) {
        final layout = controller();

        layout.openBeside('x', 0, side: side);

        expect(layout.axis, axis, reason: side.name);
        expect(layout.panes.map((p) => p.noteId), notes, reason: side.name);
      }
    });

    test('at maxPanes replaces the pane on that side', () {
      final layout = controller(mode: NoteViewMode.split, panes: two);

      layout.openBeside('x', 0, side: NoteDropSide.top);

      expect(layout.panes.map((p) => p.noteId), ['x', 'second']);
      expect(layout.axis, Axis.vertical);
      expect(layout.panes.first.id, isNot('a'));

      layout.openBeside('y', 1, side: NoteDropSide.bottom);

      expect(layout.panes.map((p) => p.noteId), ['x', 'y']);
    });

    test('a dual document stays dual, a spread becomes a split', () {
      final dual = controller(mode: NoteViewMode.dualDocument, panes: two);
      dual.openBeside('x', 0);
      expect(dual.mode, NoteViewMode.dualDocument);

      final spread = spreadLayout();
      spread.openBeside('x', 7);
      expect(spread.mode, NoteViewMode.split);
      expect(spread.panes[1].pageIndex, 7);
    });

    test('while there is room it adds instead of replacing', () {
      final layout = controller(
        mode: NoteViewMode.split,
        maxPanes: 3,
        panes: two,
      );

      layout.openBeside('x', 0, side: NoteDropSide.left);

      expect(layout.panes.map((p) => p.noteId), ['x', 'first', 'second']);
    });
  });

  group('json', () {
    test('round-trips', () {
      final layout = controller(
        mode: NoteViewMode.dualDocument,
        panes: two,
        ratio: 0.3,
        axis: Axis.vertical,
      );

      final restored = NoteViewLayoutController.fromJson(layout.toJson());

      expect(restored.mode, NoteViewMode.dualDocument);
      expect(restored.panes, two);
      expect(restored.ratio, 0.3);
      expect(restored.axis, Axis.vertical);
      expect(restored.toJson(), layout.toJson());
    });

    test('writes the documented shape', () {
      final layout = controller();

      expect(layout.toJson(), {
        'mode': 'single',
        'axis': 'horizontal',
        'ratio': 0.5,
        'panes': [
          {'id': 'a', 'noteId': 'note', 'pageIndex': 3},
        ],
      });
    });

    test('never throws on junk', () {
      for (final junk in <Object?>[
        null,
        42,
        'x',
        <Object?>[],
        <String, Object?>{},
      ]) {
        final layout = NoteViewLayoutController.fromJson(
          junk,
          idFactory: counterIds(),
        );

        expect(layout.mode, NoteViewMode.single);
        expect(layout.panes, hasLength(1));
      }
    });

    test('repairs hostile values', () {
      final layout = NoteViewLayoutController.fromJson({
        'mode': 'wat',
        'axis': 'diagonal',
        'ratio': 7,
        'panes': [
          1,
          <String, Object?>{},
          {'id': 'x', 'pageIndex': -3},
        ],
      }, idFactory: counterIds());

      expect(layout.mode, NoteViewMode.single);
      expect(layout.axis, Axis.horizontal);
      expect(layout.ratio, 0.8);
      expect(layout.panes, [const NoteViewPane(id: 'x')]);
    });

    test('truncates more panes than allowed', () {
      final layout = NoteViewLayoutController.fromJson({
        'mode': 'split',
        'panes': [
          {'id': 'a'},
          {'id': 'b'},
          {'id': 'c'},
        ],
      });

      expect(layout.panes.map((p) => p.id), ['a', 'b']);
    });
  });

  group('NoteViewPane', () {
    test('round-trips and compares by value', () {
      const pane = NoteViewPane(id: 'a', noteId: 'n', pageIndex: 2);

      expect(NoteViewPane.fromJson(pane.toJson()), pane);
      expect(pane.hashCode, pane.copyWith().hashCode);
      expect(pane.copyWith(clearNoteId: true).noteId, isNull);
      expect(pane.copyWith(pageIndex: 3), isNot(pane));
    });

    test('rejects entries without an id and cleans values', () {
      expect(NoteViewPane.fromJson(const {'noteId': 'n'}), isNull);
      expect(NoteViewPane.fromJson('pane'), isNull);
      expect(
        NoteViewPane.fromJson(const {'id': 'a', 'noteId': '', 'pageIndex': -1}),
        const NoteViewPane(id: 'a'),
      );
    });
  });

  test('does nothing after dispose', () {
    final layout = controller();
    layout.dispose();

    layout.setMode(NoteViewMode.split);
    layout.setRatio(0.7);
    layout.setAxis(Axis.vertical);
    layout.swapPanes();
    layout.setPage('a', 1);
    layout.setNote('a', 'x');

    expect(layout.addPane(), isNull);
    expect(layout.removePane('a'), isFalse);
    expect(layout.openBeside('x', 0), isNull);
    expect(layout.isDisposed, isTrue);
    expect(layout.mode, NoteViewMode.single);
    layout.dispose();
  });
}
