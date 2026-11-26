// The pure logic behind the toolbar buttons and the shared selection.
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/table/table.dart';

import 'support/table_invariants.dart';

void main() {
  group('NoteTableAction', () {
    final table = labelledTable();
    const middle = NoteTableRange.cell(1, 1);

    test('nothing is enabled without a selection', () {
      for (final action in NoteTableAction.values) {
        expect(action.isEnabled(table, null), isFalse, reason: action.name);
      }
    });

    test('row above keeps the selection on its cells', () {
      final result = NoteTableAction.rowAbove.apply(table, middle);

      expect(result.table, table.insertRow(1));
      expect(result.selection, const NoteTableRange.cell(2, 1));
    });

    test('row below keeps the selection', () {
      final result = NoteTableAction.rowBelow.apply(table, middle);

      expect(result.table, table.insertRow(2));
      expect(result.selection, middle);
    });

    test('column left and right insert beside the selection', () {
      final left = NoteTableAction.columnLeft.apply(table, middle);
      final right = NoteTableAction.columnRight.apply(table, middle);

      expect(left.table, table.insertColumn(1));
      expect(left.selection, const NoteTableRange.cell(1, 2));
      expect(right.table, table.insertColumn(2));
      expect(right.selection, middle);
    });

    test('inserting beside a merged cell does not stretch it', () {
      final merged = table.mergeCells(span(0, 0, 1, 1));
      const covered = NoteTableRange.cell(1, 1);

      final below = NoteTableAction.rowBelow.apply(merged, covered);
      final above = NoteTableAction.rowAbove.apply(merged, covered);

      expect(below.table.rangeAt(0, 0), span(0, 0, 1, 1));
      expect(below.table, merged.insertRow(2));
      expect(above.table.rangeAt(1, 0), span(1, 0, 2, 1));
      expect(above.selection, span(1, 0, 2, 1));
    });

    test('delete removes every selected row or column', () {
      final rows = NoteTableAction.deleteRow.apply(table, span(0, 1, 1, 1));
      final columns = NoteTableAction.deleteColumn.apply(
        table,
        span(1, 1, 1, 2),
      );

      expect(rows.table.rowCount, 1);
      expect(rowTexts(rows.table, 0), ['r2c0', 'r2c1', 'r2c2']);
      expect(rows.selection, const NoteTableRange.cell(0, 1));
      expect(columns.table.columnCount, 1);
      expect(rowTexts(columns.table, 2), ['r2c0']);
      expect(columns.selection, const NoteTableRange.cell(1, 0));
    });

    test('delete selects the last row left when the end goes', () {
      final result = NoteTableAction.deleteRow.apply(
        table,
        const NoteTableRange.cell(2, 0),
      );

      expect(result.selection, const NoteTableRange.cell(1, 0));
    });

    test('delete is disabled for all rows or all columns', () {
      final allRows = span(0, 0, 2, 0);
      final allColumns = span(0, 0, 0, 2);

      expect(NoteTableAction.deleteRow.isEnabled(table, allRows), isFalse);
      expect(NoteTableAction.deleteColumn.isEnabled(table, allRows), isTrue);
      expect(
        NoteTableAction.deleteColumn.isEnabled(table, allColumns),
        isFalse,
      );
      expect(NoteTableAction.deleteRow.apply(table, allRows).table, table);
    });

    test('merge and split enable only when they would act', () {
      final merged = table.mergeCells(span(0, 0, 1, 1));

      expect(NoteTableAction.merge.isEnabled(table, middle), isFalse);
      expect(NoteTableAction.merge.isEnabled(table, span(0, 0, 0, 1)), isTrue);
      expect(NoteTableAction.merge.isEnabled(merged, middle), isFalse);
      expect(NoteTableAction.split.isEnabled(table, span(0, 0, 2, 2)), isFalse);
      expect(NoteTableAction.split.isEnabled(merged, middle), isTrue);
    });

    test('merge selects the merged cell', () {
      final result = NoteTableAction.merge.apply(table, span(1, 1, 2, 2));

      expect(result.table, table.mergeCells(span(1, 1, 2, 2)));
      expect(result.selection, span(1, 1, 2, 2));
    });

    test('split undoes every merge in the selection', () {
      final merged = table
          .mergeCells(span(0, 0, 0, 1))
          .mergeCells(span(1, 2, 2, 2));

      final result = NoteTableAction.split.apply(merged, span(0, 0, 2, 2));

      expect(result.table.cells.any((cell) => cell.covered), isFalse);
      expect(result.selection, span(0, 0, 2, 2));
      expectTableInvariants(result.table);
    });

    test('insert is disabled at the limits', () {
      final tall = table.withSize(NoteTableObject.maxRows, 1);
      final wide = table.withSize(1, NoteTableObject.maxColumns);
      const first = NoteTableRange.cell(0, 0);

      expect(NoteTableAction.rowAbove.isEnabled(tall, first), isFalse);
      expect(NoteTableAction.rowBelow.isEnabled(tall, first), isFalse);
      expect(NoteTableAction.columnRight.isEnabled(tall, first), isTrue);
      expect(NoteTableAction.columnLeft.isEnabled(wide, first), isFalse);
      expect(NoteTableAction.columnRight.isEnabled(wide, first), isFalse);
      expect(NoteTableAction.rowBelow.apply(tall, first).table, same(tall));
    });

    test('a stale selection is clamped before use', () {
      const gone = NoteTableRange.cell(9, 9);

      final result = NoteTableAction.rowAbove.apply(table, gone);

      expect(result.table, table.insertRow(2));
      expect(result.selection, const NoteTableRange.cell(3, 2));
    });
  });

  group('NoteTableSelectionController', () {
    late NoteTableSelectionController controller;
    late int notified;

    setUp(() {
      controller = NoteTableSelectionController();
      notified = 0;
      controller.addListener(() => notified++);
    });

    test('notifies only for real changes', () {
      controller
        ..select('a', const NoteTableRange.cell(0, 0))
        ..select('a', const NoteTableRange.cell(0, 0));
      expect(notified, 1);

      controller.select('b', const NoteTableRange.cell(0, 0));

      expect(notified, 2);
      expect(controller.tableId, 'b');
      expect(controller.rangeFor('a'), isNull);
      expect(controller.rangeFor('b'), const NoteTableRange.cell(0, 0));
    });

    test('clears all or only the named table', () {
      controller.clear();
      controller.select('a', span(0, 0, 1, 1));

      controller.clear('b');
      expect(controller.range, span(0, 0, 1, 1));
      controller.clear('a');

      expect(controller.range, isNull);
      expect(controller.tableId, isNull);
      expect(notified, 2);
    });

    test('flushes through the editor of the same table', () {
      final table = labelledTable();
      NoteTableObject flush(NoteTableObject t) => t.setCellText(0, 0, 'typed');

      expect(controller.flushEditor(table), same(table));
      controller.attachEditor('t', flush);

      expect(controller.flushEditor(table).cellAt(0, 0).text, 'typed');
      expect(
        controller.flushEditor(labelledTable(id: 'u')).cellAt(0, 0).text,
        'r0c0',
      );
      expect(notified, 0);
    });

    test('keeps the latest editor and detaches only that one', () {
      final table = labelledTable();
      NoteTableObject first(NoteTableObject t) => t.setCellText(0, 0, '1');
      NoteTableObject second(NoteTableObject t) => t.setCellText(0, 0, '2');
      controller
        ..attachEditor('t', first)
        ..attachEditor('t', second)
        ..detachEditor(first);
      expect(controller.flushEditor(table).cellAt(0, 0).text, '2');

      controller.detachEditor(second);

      expect(controller.flushEditor(table), same(table));
    });

    test('does nothing after dispose', () {
      final table = labelledTable();
      controller
        ..dispose()
        ..select('t', const NoteTableRange.cell(0, 0))
        ..clear()
        ..attachEditor('t', (t) => t.setCellText(0, 0, 'late'));

      expect(controller.range, isNull);
      expect(controller.flushEditor(table), same(table));
      expect(notified, 0);
    });
  });
}
