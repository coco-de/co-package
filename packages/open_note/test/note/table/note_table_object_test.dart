import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/table/table.dart';

import 'support/table_invariants.dart';

const _bounds = Rect.fromLTWH(10, 20, 300, 120);
const _fill = Color(0xFFFFEE00);

NoteTableObject _grid(int rows, int columns) => NoteTableObject.grid(
  id: 't',
  bounds: _bounds,
  rows: rows,
  columns: columns,
);

void main() {
  group('construction', () {
    test('grid makes blank cells with equal fractions', () {
      final table = _grid(2, 4);

      expect(table.kind, 'table');
      expect(table.rowCount, 2);
      expect(table.columnCount, 4);
      expect(table.rowHeights, [0.5, 0.5]);
      expect(table.columnWidths, everyElement(0.25));
      expect(table.cells, everyElement(NoteTableCell.empty));
      expectTableInvariants(table);
    });

    test('grid clamps its size', () {
      final tiny = _grid(0, -3);
      final huge = _grid(1000, 1000);

      expect((tiny.rowCount, tiny.columnCount), (1, 1));
      expect((huge.rowCount, huge.columnCount), (100, 50));
      expectTableInvariants(huge);
    });

    test('repairs overlapping, escaping and stray spans', () {
      final table = NoteTableObject(
        id: 't',
        bounds: _bounds,
        rowHeights: const [0.5, 0.5],
        columnWidths: const [0.5, 0.5],
        cells: const [
          NoteTableCell(text: 'a', rowSpan: 9, columnSpan: 9),
          NoteTableCell(text: 'b', rowSpan: 2),
        ],
      );

      expect(table.rangeAt(0, 0), span(0, 0, 1, 1));
      expect(table.cellAt(0, 1), NoteTableCell.coveredCell);
      expectTableInvariants(table);
    });

    test('earlier regions win where spans overlap', () {
      final table = NoteTableObject(
        id: 't',
        bounds: _bounds,
        rowHeights: const [0.5, 0.5],
        columnWidths: const [1 / 3, 1 / 3, 1 / 3],
        cells: const [
          NoteTableCell(),
          NoteTableCell(text: 'tall', rowSpan: 2),
          NoteTableCell(),
          // Wants three columns but column 1 is already taken.
          NoteTableCell(text: 'wide', columnSpan: 3),
        ],
      );

      expect(table.rangeAt(0, 1), span(0, 1, 1, 1));
      expect(table.rangeAt(1, 0), const NoteTableRange.cell(1, 0));
      expectTableInvariants(table);
    });

    test('uncovers a cell no region claims and drops its spans', () {
      final table = NoteTableObject(
        id: 't',
        bounds: _bounds,
        rowHeights: const [1],
        columnWidths: const [0.5, 0.5],
        cells: const [NoteTableCell(text: 'a', covered: true, columnSpan: 2)],
      );

      expect(table.cellAt(0, 0).covered, isFalse);
      expect(table.cellAt(0, 0).text, 'a');
      expect(table.rangeAt(0, 0).isSingleCell, isTrue);
      expectTableInvariants(table);
    });

    test('has at least one cell even with empty lists', () {
      final table = NoteTableObject(
        id: 't',
        bounds: _bounds,
        rowHeights: const [],
        columnWidths: const [],
      );

      expect((table.rowCount, table.columnCount), (1, 1));
      expectTableInvariants(table);
    });

    test('exposes unmodifiable lists', () {
      final table = _grid(2, 2);

      expect(
        () => table.cells.add(NoteTableCell.empty),
        throwsUnsupportedError,
      );
      expect(() => table.rowHeights[0] = 1, throwsUnsupportedError);
      expect(() => table.columnWidths.clear(), throwsUnsupportedError);
    });

    test('accessors throw outside the grid', () {
      final table = _grid(2, 2);

      expect(() => table.cellAt(2, 0), throwsRangeError);
      expect(() => table.cellAt(0, -1), throwsRangeError);
      expect(() => table.anchorOf(-1, 0), throwsRangeError);
      expect(() => table.rangeAt(0, 2), throwsRangeError);
    });
  });

  group('insertRow', () {
    test('adds a blank row and rescales the heights', () {
      final table = labelledTable(rows: 2, columns: 2);

      final result = table.insertRow(1);

      expect(result.rowCount, 3);
      expect(rowTexts(result, 0), ['r0c0', 'r0c1']);
      expect(rowTexts(result, 1), ['', '']);
      expect(rowTexts(result, 2), ['r1c0', 'r1c1']);
      expect(result.rowHeights, everyElement(closeTo(1 / 3, 1e-12)));
      expect(result.bounds, table.bounds);
      expect(table.rowCount, 2, reason: 'the original is untouched');
      expectTableInvariants(result);
    });

    test('appends at the end and clamps the index', () {
      final table = labelledTable(rows: 2, columns: 1);

      expect(rowTexts(table.insertRow(2), 2), ['']);
      expect(table.insertRow(99), table.insertRow(2));
      expect(table.insertRow(-5), table.insertRow(0));
      expect(rowTexts(table.insertRow(0), 0), ['']);
    });

    test('grows a merge that crosses the insertion line', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 1));

      final result = table.insertRow(1);

      expect(result.rangeAt(0, 0), span(0, 0, 2, 1));
      expect(result.cellAt(1, 0).covered, isTrue);
      expect(rowTexts(result, 1), ['^', '^', '']);
      expectTableInvariants(result);
    });

    test('does not grow a merge beside the insertion line', () {
      final table = labelledTable().mergeCells(span(1, 0, 2, 0));

      expect(table.insertRow(1).rangeAt(2, 0), span(2, 0, 3, 0));
      expect(table.insertRow(3).rangeAt(1, 0), span(1, 0, 2, 0));
      expectTableInvariants(table.insertRow(1));
    });

    test('is a no-op at the row limit', () {
      final table = _grid(NoteTableObject.maxRows, 1);

      expect(table.insertRow(0), same(table));
    });

    test('keeps the minimum height', () {
      var table = _grid(2, 1).setRowHeight(0, 0.05);
      table = table.insertRow(0);

      expectTableInvariants(table);
    });
  });

  group('insertColumn', () {
    test('adds a blank column and rescales the widths', () {
      final table = labelledTable(rows: 2, columns: 2);

      final result = table.insertColumn(1);

      expect(rowTexts(result, 0), ['r0c0', '', 'r0c1']);
      expect(rowTexts(result, 1), ['r1c0', '', 'r1c1']);
      expect(result.columnWidths, everyElement(closeTo(1 / 3, 1e-12)));
      expectTableInvariants(result);
    });

    test('grows a merge that crosses the insertion line', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 1));

      final result = table.insertColumn(1);

      expect(result.rangeAt(0, 0), span(0, 0, 1, 2));
      expectTableInvariants(result);
    });

    test('is a no-op at the column limit', () {
      final table = _grid(1, NoteTableObject.maxColumns);

      expect(table.insertColumn(0), same(table));
    });
  });

  group('deleteRow', () {
    test('removes the row and its text', () {
      final table = labelledTable();

      final result = table.deleteRow(1);

      expect(rowTexts(result, 0), ['r0c0', 'r0c1', 'r0c2']);
      expect(rowTexts(result, 1), ['r2c0', 'r2c1', 'r2c2']);
      expect(result.rowHeights, [0.5, 0.5]);
      expectTableInvariants(result);
    });

    test('moves the content of a merge anchored on the row downwards', () {
      final table = labelledTable().mergeCells(span(0, 0, 2, 1));
      final merged = table.cellAt(0, 0).text;

      final result = table.deleteRow(0);

      expect(result.rangeAt(0, 0), span(0, 0, 1, 1));
      expect(result.cellAt(0, 0).text, merged);
      expectTableInvariants(result);
    });

    test('shrinks a merge passing through the row', () {
      final table = labelledTable().mergeCells(span(0, 0, 2, 0));

      expect(table.deleteRow(1).rangeAt(0, 0), span(0, 0, 1, 0));
      expect(table.deleteRow(2).rangeAt(0, 0), span(0, 0, 1, 0));
      expectTableInvariants(table.deleteRow(1));
    });

    test('leaves a single cell when a two-row merge loses a row', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 0));

      final result = table.deleteRow(1);

      expect(result.rangeAt(0, 0).isSingleCell, isTrue);
      expectTableInvariants(result);
    });

    test('never removes the last row or an unknown one', () {
      final one = _grid(1, 2);
      final two = _grid(2, 2);

      expect(one.deleteRow(0), same(one));
      expect(two.deleteRow(2), same(two));
      expect(two.deleteRow(-1), same(two));
    });
  });

  group('deleteColumn', () {
    test('removes the column and keeps merges consistent', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 2));

      final result = table.deleteColumn(0);

      expect(result.columnCount, 2);
      expect(result.rangeAt(0, 0), span(0, 0, 1, 1));
      expect(result.cellAt(0, 0).text, table.cellAt(0, 0).text);
      expect(rowTexts(result, 2), ['r2c1', 'r2c2']);
      expectTableInvariants(result);
    });

    test('never removes the last column or an unknown one', () {
      final one = _grid(2, 1);

      expect(one.deleteColumn(0), same(one));
      expect(_grid(2, 2).deleteColumn(7), _grid(2, 2));
    });
  });

  group('mergeCells', () {
    test('joins the texts in reading order into the top-left cell', () {
      final table = labelledTable();

      final result = table.mergeCells(span(0, 0, 1, 1));

      expect(result.cellAt(0, 0).text, 'r0c0\nr0c1\nr1c0\nr1c1');
      expect(result.cellAt(0, 0).rowSpan, 2);
      expect(result.cellAt(0, 0).columnSpan, 2);
      expect(result.cellAt(1, 1), NoteTableCell.coveredCell);
      expect(result.anchorOf(1, 1), (row: 0, column: 0));
      expect(textFragments(result), textFragments(table));
      expectTableInvariants(result);
    });

    test('skips empty texts and keeps the top-left formatting', () {
      const styled = NoteTableCell(
        bold: true,
        fillColor: Color(0xFF112233),
        align: NoteTableCellAlign.center,
      );
      final table = _grid(2, 2).setCell(0, 0, styled).setCellText(1, 1, 'only');

      final result = table.mergeCells(span(1, 1, 0, 0));
      final anchor = result.cellAt(0, 0);

      expect(anchor.text, 'only');
      expect(anchor.bold, isTrue);
      expect(anchor.fillColor, styled.fillColor);
      expect(anchor.align, NoteTableCellAlign.center);
    });

    test('grows over merges that it cuts', () {
      final table = labelledTable(
        rows: 4,
        columns: 4,
      ).mergeCells(span(1, 1, 2, 2));

      final result = table.mergeCells(span(0, 0, 1, 1));

      expect(result.rangeAt(0, 0), span(0, 0, 2, 2));
      expect(textFragments(result), textFragments(table));
      expectTableInvariants(result);
    });

    test('clamps a range that leaves the grid', () {
      final result = _grid(2, 2).mergeCells(span(0, 0, 50, 50));

      expect(result.rangeAt(1, 1), span(0, 0, 1, 1));
      expectTableInvariants(result);
    });

    test('is a no-op for one cell or an existing merge', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 1));

      expect(table.mergeCells(const NoteTableRange.cell(2, 2)), same(table));
      expect(table.mergeCells(span(0, 0, 1, 1)), same(table));
      // A range inside the merge grows to exactly the merge.
      expect(table.mergeCells(const NoteTableRange.cell(1, 1)), same(table));
      expect(table.mergeCells(span(9, 9, 9, 9)), same(table));
      expect(table.canMerge(span(0, 0, 1, 1)), isFalse);
      expect(table.canMerge(span(0, 0, 2, 1)), isTrue);
    });

    test('expandToMerges describes the selection', () {
      final table = labelledTable().mergeCells(span(1, 1, 2, 2));

      expect(table.expandToMerges(span(2, 2, 2, 2)), span(1, 1, 2, 2));
      expect(table.expandToMerges(span(0, 0, 1, 1)), span(0, 0, 2, 2));
      expect(table.expandToMerges(span(0, 0, 0, 2)), span(0, 0, 0, 2));
      expect(table.expandToMerges(span(8, 8, 9, 9)), span(1, 1, 2, 2));
    });
  });

  group('splitCell', () {
    test('keeps the content top-left and copies the formatting', () {
      final table = labelledTable()
          .setCell(
            0,
            0,
            const NoteTableCell(text: 'x', bold: true, fillColor: _fill),
          )
          .mergeCells(span(0, 0, 1, 1));

      final result = table.splitCell(1, 1);

      expect(result.cellAt(0, 0).text, table.cellAt(0, 0).text);
      for (final (row, column) in [(0, 1), (1, 0), (1, 1)]) {
        final cell = result.cellAt(row, column);
        expect(cell.covered, isFalse);
        expect(cell.text, isEmpty);
        expect(cell.bold, isTrue);
        expect(cell.fillColor, _fill);
      }
      expectTableInvariants(result);
    });

    test('is a no-op for a plain cell or outside the grid', () {
      final table = labelledTable();

      expect(table.splitCell(0, 0), same(table));
      expect(table.splitCell(9, 0), same(table));
      expect(table.splitCell(0, -1), same(table));
    });
  });

  group('cell edits', () {
    test('setCellText edits the anchor of a covered position', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 1));

      final result = table.setCellText(1, 1, 'new');

      expect(result.cellAt(0, 0).text, 'new');
      expect(result.rangeAt(0, 0), span(0, 0, 1, 1));
      expectTableInvariants(result);
    });

    test('setCellText returns this when nothing changes', () {
      final table = labelledTable();

      expect(table.setCellText(0, 0, 'r0c0'), same(table));
      expect(table.setCellText(5, 0, 'x'), same(table));
      expect(table.setCellText(0, 5, 'x'), same(table));
    });

    test('setCell ignores the spans of the given cell', () {
      final table = labelledTable();

      final result = table.setCell(
        1,
        1,
        const NoteTableCell(
          text: 'z',
          rowSpan: 3,
          columnSpan: 3,
          covered: true,
          bold: true,
        ),
      );

      expect(result.cellAt(1, 1).text, 'z');
      expect(result.cellAt(1, 1).bold, isTrue);
      expect(result.cellAt(1, 1).rowSpan, 1);
      expect(result.cellAt(1, 1).covered, isFalse);
      expect(rowTexts(result, 2), ['r2c0', 'r2c1', 'r2c2']);
      expectTableInvariants(result);
    });

    test('setCell returns this for an equal cell or outside the grid', () {
      final table = labelledTable();

      expect(table.setCell(0, 0, table.cellAt(0, 0)), same(table));
      expect(table.setCell(9, 9, NoteTableCell.empty), same(table));
    });
  });

  group('sizes', () {
    test('setColumnWidth lets the neighbour absorb the change', () {
      final table = _grid(1, 4);

      final result = table.setColumnWidth(1, 0.4);

      expect(result.columnWidths, [0.25, 0.4, closeTo(0.1, 1e-12), 0.25]);
      expect(result.setColumnWidth(3, 0.3).columnWidths.last, 0.3);
      expectTableInvariants(result);
    });

    test('setColumnWidth keeps the minimum and ignores bad input', () {
      final table = _grid(1, 2);

      expect(
        table.setColumnWidth(0, 0).columnWidths.first,
        NoteTableObject.minFraction,
      );
      expect(table.setColumnWidth(0, 0.5), same(table));
      expect(table.setColumnWidth(2, 0.3), same(table));
      expect(table.setColumnWidth(0, double.infinity), same(table));
      expect(_grid(1, 1).setColumnWidth(0, 0.3), _grid(1, 1));
    });

    test('setRowHeight mirrors setColumnWidth', () {
      final result = _grid(3, 1).setRowHeight(2, 0.5);

      expect(result.rowHeights, [
        closeTo(1 / 3, 1e-12),
        closeTo(1 / 6, 1e-12),
        0.5,
      ]);
      expectTableInvariants(result);
    });

    test('withSize grows and shrinks from the end', () {
      final table = labelledTable(rows: 2, columns: 2);

      final grown = table.withSize(4, 3);
      final shrunk = grown.withSize(1, 1);

      expect((grown.rowCount, grown.columnCount), (4, 3));
      expect(rowTexts(grown, 1), ['r1c0', 'r1c1', '']);
      expect(rowTexts(grown, 3), ['', '', '']);
      expect(rowTexts(shrunk, 0), ['r0c0']);
      expectTableInvariants(grown);
      expectTableInvariants(shrunk);
    });

    test('withSize clamps and returns this for the same size', () {
      final table = _grid(2, 2);

      expect(table.withSize(2, 2), same(table));
      expect(table.withSize(0, -1).rowCount, 1);
      expect(table.withSize(500, 2).rowCount, NoteTableObject.maxRows);
    });

    test('many columns still satisfy the rules', () {
      var table = _grid(1, 20);
      for (var i = 0; i < 20; i++) {
        table = table.insertColumn(table.columnCount);
        expectTableInvariants(table, reason: '${table.columnCount} columns');
      }
      expect(table.columnCount, 40);
      expect(NoteTableObject.minimumFractionFor(40), closeTo(0.0125, 1e-12));
    });
  });

  group('value semantics', () {
    test('equal content is equal', () {
      expect(labelledTable(), labelledTable());
      expect(labelledTable().hashCode, labelledTable().hashCode);
      expect(labelledTable().setCellText(0, 0, 'x'), isNot(labelledTable()));
      expect(labelledTable().setRowHeight(0, 0.5), isNot(labelledTable()));
    });

    test('withBase changes only the shared fields', () {
      final table = labelledTable().mergeCells(span(0, 0, 1, 1));

      final moved = table.withBase(
        bounds: const Rect.fromLTWH(1, 2, 3, 4),
        rotation: 0.5,
        opacity: 0.25,
        locked: true,
      );

      expect(moved.id, table.id);
      expect(moved.cells, table.cells);
      expect(moved.rotation, 0.5);
      expect(moved.opacity, 0.25);
      expect(moved.locked, isTrue);
      expect(moved.bounds, const Rect.fromLTWH(1, 2, 3, 4));
      expect(table.withBase(), table);
    });

    test('copyWith replaces fields but never the shape', () {
      final table = labelledTable(rows: 2, columns: 2);

      final renamed = table.copyWith(id: 'other');
      final widened = table.copyWith(columnWidths: [0.8, 0.2]);
      final ignored = table.copyWith(columnWidths: [1], rowHeights: [1]);
      final styled = table.copyWith(
        style: const NoteTableStyle(headerRow: true),
      );

      expect(renamed.id, 'other');
      expect(widened.columnWidths, [0.8, 0.2]);
      expect(ignored, table);
      expect(styled.style.headerRow, isTrue);
      expect(styled.cells, table.cells);
      expect(table.copyWith(), table);
    });

    test('toString names the size', () {
      expect(_grid(2, 3).toString(), contains('2 x 3'));
    });
  });
}
