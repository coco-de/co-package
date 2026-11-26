// Cell editing in NoteTableView: how a session opens, how text is committed and
// when it is discarded.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import '../support/note_test_host.dart';
import 'support/table_invariants.dart';
import 'support/table_probe.dart';

Future<TableProbe> _pumpProbe(
  WidgetTester tester, {
  NoteTableObject? table,
  bool editing = false,
}) async {
  final probe = TableProbe(table: table)..editing = editing;
  await probe.pump(tester);
  await tester.pump();

  return probe;
}

void main() {
  group('opening', () {
    testWidgets('double tap edits the cell and asks the host', (tester) async {
      final probe = await _pumpProbe(tester);

      await probe.doubleTap(1, 1);

      expect(find.byType(NoteTextField), findsOneWidget);
      expect(probe.editorText, 'r1c1');
      expect(probe.editorHasFocus, isTrue);
      expect(probe.editRequests, 1);
      expect(probe.range, const NoteTableRange.cell(1, 1));
      expect(probe.changes, isEmpty);
    });

    testWidgets('a host that grants the request keeps the same cell', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester)
        ..grantsEditing = true;

      await probe.doubleTap(2, 1);

      expect(probe.editing, isTrue);
      expect(probe.editorText, 'r2c1');
      expect(probe.editorHasFocus, isTrue);
      await probe.type('granted');
      await probe.update(() => probe.editing = false);
      expect(probe.changes.single.cellAt(2, 1).text, 'granted');
      expect(probe.editRequests, 1);
    });

    testWidgets('quick taps on two cells are not a double tap', (tester) async {
      final probe = await _pumpProbe(tester, table: labelledTable(columns: 6));

      // Neighbouring cells 50 px wide: close enough to be one tap series.
      final origin = tester.getTopLeft(find.byType(NoteTableView));
      await tester.tapAt(origin + const Offset(25, 20));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(origin + const Offset(75, 20));
      await tester.pump(const Duration(milliseconds: 400));

      expect(probe.range, const NoteTableRange.cell(0, 1));
      expect(probe.editorText, isNull);
    });

    testWidgets('slow taps on one cell are not a double tap', (tester) async {
      final probe = await _pumpProbe(tester);

      await probe.tap(0, 0);
      await probe.tap(0, 0);

      expect(probe.editorText, isNull);
    });

    testWidgets('the editor covers a merged region', (tester) async {
      final probe = await _pumpProbe(
        tester,
        table: labelledTable().mergeCells(span(0, 0, 1, 1)),
      );

      await probe.doubleTap(1, 1);

      final layout = NoteTableLayout(probe.table, Offset.zero & probe.size);
      final field = tester
          .getRect(find.byType(NoteTextField))
          .shift(-tester.getTopLeft(find.byType(NoteTableView)));
      expect(field, layout.cellRect(0, 0));
      expect(probe.editorText, 'r0c0\nr0c1\nr1c0\nr1c1');
      expect(find.byKey(NoteTableView.selectionKey), findsNothing);
    });

    testWidgets('the editor matches the painted text style', (tester) async {
      final probe = await _pumpProbe(
        tester,
        table:
            labelledTable(
              style: const NoteTableStyle(fontSize: 18, cellPadding: 6),
            ).setCell(
              0,
              0,
              const NoteTableCell(
                text: 'x',
                bold: true,
                align: NoteTableCellAlign.center,
              ),
            ),
      );

      await probe.doubleTap(0, 0);

      final field = tester.widget<NoteTextField>(find.byType(NoteTextField));
      expect(field.style.fontSize, 18);
      expect(field.style.fontWeight, FontWeight.w700);
      expect(field.textAlign, TextAlign.center);
      expect(field.padding, const EdgeInsets.all(6));
      expect(field.maxLines, isNull);
    });

    testWidgets('the editor ignores the platform text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final probe = await _pumpProbe(tester);

      await probe.doubleTap(0, 0);

      final editable = tester.element(find.byType(EditableText));
      expect(MediaQuery.textScalerOf(editable), TextScaler.noScaling);
    });

    testWidgets('scope.editing at start edits the top-left cell', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester, editing: true);

      expect(probe.editorText, 'r0c0');
      expect(probe.editorHasFocus, isTrue);
      expect(probe.range, const NoteTableRange.cell(0, 0));
      expect(probe.editRequests, 0);
    });

    testWidgets('scope.editing turning on edits the selected cell', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.tap(2, 1);

      await probe.update(() => probe.editing = true);

      expect(probe.editorText, 'r2c1');
      expect(probe.editorHasFocus, isTrue);
    });

    testWidgets('while editing, one tap moves the editor', (tester) async {
      final probe = await _pumpProbe(tester, editing: true);
      await probe.type('first');

      await probe.tap(1, 2);

      expect(probe.changes.single.cellAt(0, 0).text, 'first');
      expect(probe.editorText, 'r1c2');
      expect(probe.range, const NoteTableRange.cell(1, 2));
    });

    testWidgets('a double tap while editing does not ask again', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester, editing: true);

      await probe.doubleTap(1, 1);

      expect(probe.editorText, 'r1c1');
      expect(probe.editRequests, 0);
    });
  });

  group('committing', () {
    testWidgets('tapping another cell commits the typed text', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('Hello');

      await probe.tap(2, 2);

      expect(probe.changes.single.cellAt(0, 0).text, 'Hello');
      expect(probe.table.cellAt(0, 0).text, 'Hello');
      expect(probe.editorText, isNull);
      expect(probe.range, const NoteTableRange.cell(2, 2));
    });

    testWidgets('dragging other cells commits first', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('Dragged');

      await probe.drag((1, 0), (2, 1));

      expect(probe.changes.single.cellAt(0, 0).text, 'Dragged');
      expect(probe.range, span(1, 0, 2, 1));
      expect(probe.editorText, isNull);
    });

    testWidgets('taps and drags inside the editor keep it open', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 1);
      await probe.type('typing');

      await probe.tap(1, 1);
      await probe.drag((1, 1), (1, 1));

      expect(probe.editorText, 'typing');
      expect(probe.changes, isEmpty);
    });

    testWidgets('a long drag within the edited cell selects nothing', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 1);
      await probe.type('typing');

      final gesture = await tester.startGesture(
        probe.center(1, 1) - const Offset(45, 0),
      );
      await gesture.moveTo(probe.center(1, 1) + const Offset(45, 0));
      await tester.pump();
      await gesture.moveTo(probe.center(2, 2));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 400));

      expect(probe.range, const NoteTableRange.cell(1, 1));
      expect(probe.editorText, 'typing');
      expect(probe.changes, isEmpty);
    });

    testWidgets('a mouse press outside the table commits', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 1);
      await probe.type('left');

      await tester.tapAt(const Offset(700, 500), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 400));

      expect(probe.changes.single.cellAt(1, 1).text, 'left');
      expect(probe.editorText, isNull);
    });

    testWidgets('losing focus commits', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 0);
      await probe.type('blurred');

      await probe.blur();

      expect(probe.changes.single.cellAt(1, 0).text, 'blurred');
      expect(probe.editorText, isNull);
    });

    testWidgets('keeps line breaks', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('one\ntwo');

      await probe.blur();

      expect(probe.table.cellAt(0, 0).text, 'one\ntwo');
    });

    testWidgets('reports nothing when the text is unchanged', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);

      await probe.blur();

      expect(probe.changes, isEmpty);
      expect(probe.editorText, isNull);
    });

    testWidgets('Escape discards the typed text', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('oops');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();

      expect(probe.editorText, isNull);
      expect(probe.changes, isEmpty);
    });

    testWidgets('scope.editing turning off commits once', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.update(() => probe.editing = true);
      await probe.type('done');

      await probe.update(() => probe.editing = false);

      expect(probe.changes.single.cellAt(0, 0).text, 'done');
      expect(probe.editorText, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('turning interactive off commits', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 1);
      await probe.type('kept');

      await probe.update(() => probe.interactive = false);

      expect(probe.changes.single.cellAt(0, 1).text, 'kept');
      expect(probe.editorText, isNull);
    });

    testWidgets('losing onChanged commits through the old one', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 1);
      await probe.type('kept');

      await probe.update(() => probe.writable = false);

      expect(probe.changes.single.cellAt(0, 1).text, 'kept');
    });

    testWidgets('deselecting the object commits', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.update(() => probe.selected = true);
      await probe.doubleTap(2, 0);
      await probe.type('bye');

      await probe.update(() => probe.selected = false);

      expect(probe.changes.single.cellAt(2, 0).text, 'bye');
      expect(probe.editorText, isNull);
      expect(probe.range, isNull);
    });

    testWidgets('removing the view commits the typed text', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(2, 2);
      await probe.type('last words');

      await probe.update(() => probe.shown = false);

      expect(probe.changes.single.cellAt(2, 2).text, 'last words');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a view torn down with its whole app reports nothing', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('too late');

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(probe.changes, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a mouse tap on another cell commits exactly once', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('once');

      await tester.tapAt(probe.center(1, 1), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 400));

      expect(probe.changes.single.cellAt(0, 0).text, 'once');
    });
  });

  group('outside changes while editing', () {
    testWidgets('to other cells keep the editor and merge', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('mine');

      await probe.update(
        () => probe.table = probe.table
            .setCellText(2, 2, 'theirs')
            .withBase(opacity: 0.5),
      );
      expect(probe.editorText, 'mine');
      await probe.blur();

      expect(probe.table.cellAt(0, 0).text, 'mine');
      expect(probe.table.cellAt(2, 2).text, 'theirs');
      expect(probe.table.opacity, 0.5);
    });

    testWidgets('to the edited text win over the typing', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('mine');

      await probe.update(
        () => probe.table = probe.table.setCellText(0, 0, 'undone'),
      );

      expect(probe.editorText, isNull);
      expect(probe.changes, isEmpty);
      expect(probe.table.cellAt(0, 0).text, 'undone');
    });

    testWidgets('that resize the grid discard the typing', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 1);
      await probe.type('mine');

      await probe.update(() => probe.table = probe.table.insertRow(0));

      expect(probe.editorText, isNull);
      expect(probe.changes, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('that re-merge the cell discard the typing', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 1);

      await probe.update(
        () => probe.table = probe.table.mergeCells(span(0, 0, 1, 1)),
      );

      expect(probe.editorText, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('that swap in another table commit to the old one', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('old table');

      await probe.update(() => probe.table = labelledTable(id: 'second'));

      expect(probe.changes.single.id, 't');
      expect(probe.changes.single.cellAt(0, 0).text, 'old table');
      expect(probe.editorText, isNull);
    });
  });

  testWidgets('a tap inside the editor places the cursor', (tester) async {
    final probe = await _pumpProbe(tester);
    await probe.doubleTap(1, 1);
    // Short enough to stay on one line of a 100 px cell.
    await probe.type('abcdef');
    final controller = tester
        .widget<EditableText>(find.byType(EditableText))
        .controller;
    expect(controller.selection.baseOffset, 6);
    final text = tester.getRect(find.byType(EditableText));

    await tester.tapAt(Offset(text.left + 2, text.center.dy));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.selection.baseOffset, lessThan(2));
    expect(probe.editorText, 'abcdef');
  });

  testWidgets(
    'with a shared controller, editing a second table commits the first',
    (tester) async {
      final selection = NoteTableSelectionController();
      addTearDown(selection.dispose);
      final changes = <NoteTableObject>[];
      Widget table(String id) => SizedBox(
        width: 300,
        height: 120,
        child: NoteTableView(
          table: labelledTable(id: id),
          selectionController: selection,
          scope: NoteObjectViewScope(
            onChanged: (object) => changes.add(object as NoteTableObject),
          ),
        ),
      );
      await tester.pumpWidget(
        noteTestHost(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [table('a'), table('b')],
          ),
        ),
      );
      Future<void> doubleTap(Offset at) async {
        await tester.tapAt(at);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(at);
        await tester.pump(const Duration(milliseconds: 400));
      }

      // A touch outside a field does not blur it; moving the focus does.
      await doubleTap(const Offset(50, 20));
      await tester.enterText(find.byType(EditableText), 'from a');
      await doubleTap(const Offset(150, 180));
      // The first table closes its field in the frame after the focus moved.
      await tester.pump();

      expect(changes.single.id, 'a');
      expect(changes.single.cellAt(0, 0).text, 'from a');
      expect(find.byType(EditableText), findsOneWidget);
      expect(selection.tableId, 'b');
      await tester.enterText(find.byType(EditableText), 'from b');
      final other = labelledTable(id: 'a');
      expect(selection.flushEditor(other), same(other));
      final flushed = selection.flushEditor(labelledTable(id: 'b'));
      expect(flushed.cellAt(1, 1).text, 'from b');
      await tester.pump();
    },
  );

  testWidgets('a highlight appearing keeps the same text field', (
    tester,
  ) async {
    final probe = await _pumpProbe(tester);
    await probe.doubleTap(1, 1);
    await probe.type('keep me');
    final before = tester.state(find.byType(EditableText));

    probe.selection.select('t', span(0, 0, 0, 2));
    await tester.pump();

    expect(find.byKey(NoteTableView.selectionKey), findsOneWidget);
    expect(tester.state(find.byType(EditableText)), same(before));
    expect(probe.editorHasFocus, isTrue);

    probe.selection.clear();
    await tester.pump();

    expect(tester.state(find.byType(EditableText)), same(before));
    expect(probe.editorText, 'keep me');
    expect(probe.changes, isEmpty);
  });

  testWidgets('clicking an idle table blurs a text field elsewhere', (
    tester,
  ) async {
    final elsewhere = FocusNode();
    addTearDown(elsewhere.dispose);
    await tester.pumpWidget(
      noteTestHost(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              height: 120,
              child: NoteTableView(
                table: labelledTable(),
                scope: const NoteObjectViewScope(),
              ),
            ),
            SizedBox(width: 200, child: NoteTextField(focusNode: elsewhere)),
          ],
        ),
      ),
    );
    elsewhere.requestFocus();
    await tester.pump();
    expect(elsewhere.hasFocus, isTrue);

    await tester.tapAt(const Offset(150, 60), kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 400));

    expect(elsewhere.hasFocus, isFalse);
  });

  group('flushing', () {
    testWidgets('hands the typed text to the caller and closes', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('flushed');

      final flushed = probe.selection.flushEditor(probe.table);
      await tester.pump();

      expect(flushed.cellAt(0, 0).text, 'flushed');
      expect(probe.editorText, isNull);
      expect(probe.changes, isEmpty);
    });

    testWidgets('leaves other and ill-fitting tables alone', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(2, 2);
      await probe.type('pending');
      final other = labelledTable(id: 'other');
      final smaller = probe.table.withSize(2, 2);

      expect(probe.selection.flushEditor(other), same(other));
      expect(probe.selection.flushEditor(smaller), same(smaller));
      await tester.pump();

      expect(probe.editorText, 'pending');
    });

    testWidgets('does nothing once the editor is closed', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('x');
      await probe.blur();

      expect(probe.selection.flushEditor(probe.table), same(probe.table));
    });

    testWidgets('follows the view to a new controller', (tester) async {
      final probe = await _pumpProbe(tester);
      final other = NoteTableSelectionController();
      addTearDown(other.dispose);
      await probe.doubleTap(0, 0);
      await probe.type('moved');

      await probe.update(() => probe.otherSelection = other);

      expect(probe.selection.flushEditor(probe.table), same(probe.table));
      expect(other.flushEditor(probe.table).cellAt(0, 0).text, 'moved');
      await tester.pump();
    });
  });
}
