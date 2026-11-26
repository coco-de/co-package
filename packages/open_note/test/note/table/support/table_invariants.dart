import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/table/table.dart';

/// Every way [table] breaks the structural rules; empty for a sound table.
/// Collected as strings so thousands of checks stay fast.
List<String> tableProblems(NoteTableObject table) => [
  ..._shapeProblems(table),
  ..._fractionProblems('row heights', table.rowHeights),
  ..._fractionProblems('column widths', table.columnWidths),
  ..._regionProblems(table),
];

/// Fails unless [table] satisfies every structural rule.
void expectTableInvariants(NoteTableObject table, {String? reason}) =>
    expect(tableProblems(table), isEmpty, reason: reason);

/// Every non-empty line of text in the table, sorted: merging and splitting
/// keep this multiset.
List<String> textFragments(NoteTableObject table) => [
  for (final cell in table.cells)
    for (final line in cell.text.split('\n'))
      if (line.isNotEmpty) line,
]..sort();

/// A table of [rows] x [columns] whose cell texts are `r<row>c<column>`.
NoteTableObject labelledTable({
  String id = 't',
  int rows = 3,
  int columns = 3,
  Rect bounds = const Rect.fromLTWH(0, 0, 300, 120),
  NoteTableStyle style = const NoteTableStyle(),
}) {
  var table = NoteTableObject.grid(
    id: id,
    bounds: bounds,
    rows: rows,
    columns: columns,
    style: style,
  );
  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      table = table.setCellText(row, column, 'r${row}c$column');
    }
  }

  return table;
}

/// A range from two corners.
NoteTableRange span(
  int firstRow,
  int firstColumn,
  int lastRow,
  int lastColumn,
) => NoteTableRange(
  firstRow: firstRow,
  firstColumn: firstColumn,
  lastRow: lastRow,
  lastColumn: lastColumn,
);

/// The texts of one row, with `^` for positions hidden by a merge.
List<String> rowTexts(NoteTableObject table, int row) => [
  for (var column = 0; column < table.columnCount; column++)
    table.cellAt(row, column).covered ? '^' : table.cellAt(row, column).text,
];

List<String> _shapeProblems(NoteTableObject table) {
  final rows = table.rowCount;
  final columns = table.columnCount;

  return [
    if (rows < 1 || rows > NoteTableObject.maxRows) 'bad row count $rows',
    if (columns < 1 || columns > NoteTableObject.maxColumns)
      'bad column count $columns',
    if (table.rowHeights.length != rows) 'row heights length',
    if (table.columnWidths.length != columns) 'column widths length',
    if (table.cells.length != rows * columns) 'not rectangular',
  ];
}

List<String> _fractionProblems(String name, List<double> values) {
  final minimum = NoteTableObject.minimumFractionFor(values.length);
  final total = values.fold(0.0, (sum, value) => sum + value);

  return [
    for (final value in values)
      if (!value.isFinite || value < minimum - 1e-9)
        '$name: $value below $minimum',
    if ((total - 1).abs() > 1e-9) '$name sum to $total',
  ];
}

List<String> _regionProblems(NoteTableObject table) {
  final problems = <String>[];
  final owners = List<int>.filled(table.rowCount * table.columnCount, 0);
  for (var row = 0; row < table.rowCount; row++) {
    for (var column = 0; column < table.columnCount; column++) {
      final cell = table.cellAt(row, column);
      if (cell.covered) continue;
      if (row + cell.rowSpan > table.rowCount ||
          column + cell.columnSpan > table.columnCount) {
        problems.add('span leaves the grid at $row,$column');
        continue;
      }
      problems.addAll(_claim(table, (row: row, column: column), cell, owners));
    }
  }
  if (owners.any((count) => count != 1)) {
    problems.add('positions not owned exactly once: $owners');
  }

  return problems;
}

List<String> _claim(
  NoteTableObject table,
  ({int row, int column}) anchor,
  NoteTableCell cell,
  List<int> owners,
) {
  final (:row, :column) = anchor;
  final region = span(
    row,
    column,
    row + cell.rowSpan - 1,
    column + cell.columnSpan - 1,
  );
  final problems = <String>[];
  for (var r = region.firstRow; r <= region.lastRow; r++) {
    for (var c = region.firstColumn; c <= region.lastColumn; c++) {
      owners[r * table.columnCount + c]++;
      final stored = table.cellAt(r, c);
      if ((r != row || c != column) && stored != NoteTableCell.coveredCell) {
        problems.add('position $r,$c is not the canonical covered cell');
      }
      if (table.rangeAt(r, c) != region || table.anchorOf(r, c) != anchor) {
        problems.add('accessors disagree at $r,$c');
      }
    }
  }

  return problems;
}
