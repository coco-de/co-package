// The NoteTableToolbar widget and the object-registry wiring.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import '../support/note_test_host.dart';
import 'support/table_invariants.dart';
import 'support/table_probe.dart';

Finder _button(NoteTableAction action) =>
    find.byKey(NoteTableToolbar.actionKey(action));

bool _isEnabled(WidgetTester tester, NoteTableAction action) {
  final node = tester.getSemantics(_button(action));

  return node.flagsCollection.isEnabled.toBoolOrNull() ?? false;
}

Future<void> _press(WidgetTester tester, NoteTableAction action) async {
  await tester.tap(_button(action));
  await tester.pump();
  await tester.pump();
}

Future<TableProbe> _pumpProbe(
  WidgetTester tester, {
  NoteTableObject? table,
  NoteTableRange? selected,
}) async {
  final probe = TableProbe(table: table, toolbar: true);
  await probe.pump(tester);
  if (selected != null) {
    probe.selection.select(probe.table.id, selected);
    await tester.pump();
  }

  return probe;
}

void main() {
  group('NoteTableToolbar', () {
    testWidgets('shows a button for every action', (tester) async {
      await _pumpProbe(tester);

      for (final action in NoteTableAction.values) {
        expect(_button(action), findsOneWidget, reason: action.name);
      }
      expect(find.text('Merge cells'), findsOneWidget);
    });

    testWidgets('disables everything without a selection', (tester) async {
      final handle = tester.ensureSemantics();
      final probe = await _pumpProbe(tester);

      for (final action in NoteTableAction.values) {
        expect(_isEnabled(tester, action), isFalse, reason: action.name);
        await _press(tester, action);
      }

      expect(probe.changes, isEmpty);
      handle.dispose();
    });

    testWidgets('enables what fits the selection', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpProbe(tester, selected: const NoteTableRange.cell(0, 0));

      expect(_isEnabled(tester, NoteTableAction.rowAbove), isTrue);
      expect(_isEnabled(tester, NoteTableAction.deleteColumn), isTrue);
      expect(_isEnabled(tester, NoteTableAction.merge), isFalse);
      expect(_isEnabled(tester, NoteTableAction.split), isFalse);
      handle.dispose();
    });

    testWidgets('follows the selection made in the view', (tester) async {
      final handle = tester.ensureSemantics();
      final probe = await _pumpProbe(tester);

      await probe.drag((0, 0), (1, 1));

      expect(_isEnabled(tester, NoteTableAction.merge), isTrue);
      handle.dispose();
    });

    final expected = <NoteTableAction, NoteTableObject Function()>{
      NoteTableAction.rowAbove: () => labelledTable().insertRow(1),
      NoteTableAction.rowBelow: () => labelledTable().insertRow(2),
      NoteTableAction.columnLeft: () => labelledTable().insertColumn(1),
      NoteTableAction.columnRight: () => labelledTable().insertColumn(2),
      NoteTableAction.deleteRow: () => labelledTable().deleteRow(1),
      NoteTableAction.deleteColumn: () => labelledTable().deleteColumn(1),
    };
    for (final MapEntry(key: action, value: result) in expected.entries) {
      testWidgets('${action.name} reports the new table', (tester) async {
        final probe = await _pumpProbe(
          tester,
          selected: const NoteTableRange.cell(1, 1),
        );

        await _press(tester, action);

        expect(probe.changes, [result()]);
        expectTableInvariants(probe.table);
      });
    }

    testWidgets('moves the selection with the cells', (tester) async {
      final probe = await _pumpProbe(
        tester,
        selected: const NoteTableRange.cell(1, 1),
      );

      await _press(tester, NoteTableAction.rowAbove);
      await _press(tester, NoteTableAction.columnLeft);

      expect(probe.range, const NoteTableRange.cell(2, 2));
    });

    testWidgets('merges and splits the selected cells', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.drag((0, 0), (1, 1));

      await _press(tester, NoteTableAction.merge);
      expect(probe.table.rangeAt(0, 0), span(0, 0, 1, 1));
      expect(probe.range, span(0, 0, 1, 1));

      await _press(tester, NoteTableAction.split);

      expect(probe.table.cells.any((cell) => cell.covered), isFalse);
      expect(probe.changes, hasLength(2));
      expect(probe.range, span(0, 0, 1, 1));
    });

    testWidgets('applies the text being typed before the action', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(1, 1);
      await probe.type('half typed');

      await _press(tester, NoteTableAction.rowAbove);

      expect(probe.changes, hasLength(1));
      expect(probe.table.rowCount, 4);
      expect(probe.table.cellAt(2, 1).text, 'half typed');
      expect(probe.editorText, isNull);
      expect(probe.range, const NoteTableRange.cell(2, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('merging keeps the typed text', (tester) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('typed');
      // A selection set from outside, as a host's "select row" command would.
      probe.selection.select('t', span(0, 0, 0, 1));
      await tester.pump();

      await _press(tester, NoteTableAction.merge);

      expect(probe.table.cellAt(0, 0).text, 'typed\nr0c1');
      expect(probe.changes, hasLength(1));
    });

    testWidgets('a mouse press does not steal the editor focus', (
      tester,
    ) async {
      final probe = await _pumpProbe(tester);
      await probe.doubleTap(0, 0);
      await probe.type('still typing');

      // Merge is disabled for one cell: pressing it must change nothing.
      await tester.tap(
        _button(NoteTableAction.merge),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      expect(probe.editorHasFocus, isTrue);
      expect(probe.editorText, 'still typing');
      expect(probe.changes, isEmpty);
    });

    testWidgets('shows only the requested actions with custom labels', (
      tester,
    ) async {
      final selection = NoteTableSelectionController();
      addTearDown(selection.dispose);
      await tester.pumpWidget(
        noteTestHost(
          NoteTableToolbar(
            table: labelledTable(),
            selectionController: selection,
            onChanged: (_) {},
            actions: const [NoteTableAction.merge],
            strings: const NoteTableStrings(merge: '병합'),
          ),
        ),
      );

      expect(find.text('병합'), findsOneWidget);
      expect(_button(NoteTableAction.split), findsNothing);
    });

    testWidgets('wraps on a narrow screen without overflowing', (tester) async {
      final selection = NoteTableSelectionController();
      addTearDown(selection.dispose);
      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: SizedBox(
              width: 220,
              child: NoteTableToolbar(
                table: labelledTable(),
                selectionController: selection,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('registerNoteTableObject', () {
    testWidgets('decodes tables and builds their view', (tester) async {
      final selection = NoteTableSelectionController();
      addTearDown(selection.dispose);
      final registry = NoteObjectRegistry();
      const strings = NoteTableStrings(merge: 'M');
      const viewStyle = NoteTableViewStyle(selectionColor: Color(0xFF00FF00));
      registerNoteTableObject(
        registry,
        selectionController: selection,
        strings: strings,
        viewStyle: viewStyle,
      );
      final table = labelledTable();
      final decoded = registry.decode(table.toJson())!;
      await tester.pumpWidget(
        noteTestHost(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 120,
              child: Builder(
                builder: (context) => registry.buildView(
                  context,
                  decoded,
                  const NoteObjectViewScope(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(250, 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(registry.isRegistered(NoteTableObject.kindName), isTrue);
      expect(decoded, table);
      final view = tester.widget<NoteTableView>(find.byType(NoteTableView));
      expect(view.key, const ValueKey<String>('note-table-t'));
      expect(view.strings, same(strings));
      expect(view.style, viewStyle);
      expect(selection.rangeFor('t'), const NoteTableRange.cell(2, 2));
    });

    testWidgets('draws nothing for an object of another class', (tester) async {
      final registry = NoteObjectRegistry();
      registerNoteTableObject(registry);
      const impostor = NoteUnknownObject(
        id: 'x',
        bounds: Rect.fromLTWH(0, 0, 10, 10),
        unknownKind: 'table',
        payload: {},
      );
      await tester.pumpWidget(
        noteTestHost(
          Builder(
            builder: (context) => registry.buildView(
              context,
              impostor,
              const NoteObjectViewScope(),
            ),
          ),
        ),
      );

      expect(find.byType(NoteTableView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
