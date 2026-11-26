import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_range.dart';

/// The table after a toolbar action, and the cells to select in it.
typedef NoteTableActionResult = ({
  NoteTableObject table,
  NoteTableRange selection,
});

/// One command of the table toolbar, as pure logic on a table and a selection.
///
/// A selection is first clamped to the grid and grown over the merges it cuts
/// (see `NoteTableObject.expandToMerges`), so every selection is valid.
enum NoteTableAction {
  /// Inserts a row above the selection; the selection stays on the same cells.
  rowAbove,

  /// Inserts a row below the selection.
  rowBelow,

  /// Inserts a column before the selection; the selection stays on the same
  /// cells.
  columnLeft,

  /// Inserts a column after the selection.
  columnRight,

  /// Deletes every selected row (disabled when that would leave no row); the
  /// cell now at the first deleted row becomes selected.
  deleteRow,

  /// Deletes every selected column; the column counterpart of [deleteRow].
  deleteColumn,

  /// Merges the selected cells into one, which stays selected.
  merge,

  /// Splits every merged cell inside the selection; the same cells stay
  /// selected.
  split;

  /// Whether the action would do something for [selection] (never without one).
  bool isEnabled(NoteTableObject table, NoteTableRange? selection) {
    if (selection == null) return false;
    final range = table.expandToMerges(selection);

    return switch (this) {
      rowAbove || rowBelow => table.rowCount < NoteTableObject.maxRows,
      columnLeft ||
      columnRight => table.columnCount < NoteTableObject.maxColumns,
      deleteRow => range.rowCount < table.rowCount,
      deleteColumn => range.columnCount < table.columnCount,
      merge => table.canMerge(range),
      split => _mergedAnchors(table, range).isNotEmpty,
    };
  }

  /// Applies the action. When [isEnabled] is `false` the table is returned
  /// unchanged.
  NoteTableActionResult apply(NoteTableObject table, NoteTableRange selection) {
    final range = table.expandToMerges(selection);
    if (!isEnabled(table, range)) return (table: table, selection: range);

    return switch (this) {
      rowAbove => (
        table: table.insertRow(range.firstRow),
        selection: range.shift(rows: 1),
      ),
      rowBelow => (table: table.insertRow(range.lastRow + 1), selection: range),
      columnLeft => (
        table: table.insertColumn(range.firstColumn),
        selection: range.shift(columns: 1),
      ),
      columnRight => (
        table: table.insertColumn(range.lastColumn + 1),
        selection: range,
      ),
      deleteRow => _deleteRows(table, range),
      deleteColumn => _deleteColumns(table, range),
      merge => _mergeRange(table, range),
      split => _splitRange(table, range),
    };
  }

  static NoteTableActionResult _deleteRows(
    NoteTableObject table,
    NoteTableRange range,
  ) {
    var result = table;
    for (var row = range.lastRow; row >= range.firstRow; row--) {
      result = result.deleteRow(row);
    }
    final next = NoteTableRange.cell(range.firstRow, range.firstColumn);

    return (table: result, selection: result.expandToMerges(next));
  }

  static NoteTableActionResult _deleteColumns(
    NoteTableObject table,
    NoteTableRange range,
  ) {
    var result = table;
    for (var c = range.lastColumn; c >= range.firstColumn; c--) {
      result = result.deleteColumn(c);
    }
    final next = NoteTableRange.cell(range.firstRow, range.firstColumn);

    return (table: result, selection: result.expandToMerges(next));
  }

  static NoteTableActionResult _mergeRange(
    NoteTableObject table,
    NoteTableRange range,
  ) {
    final result = table.mergeCells(range);

    return (table: result, selection: result.expandToMerges(range));
  }

  static NoteTableActionResult _splitRange(
    NoteTableObject table,
    NoteTableRange range,
  ) {
    var result = table;
    for (final anchor in _mergedAnchors(table, range)) {
      result = result.splitCell(anchor.row, anchor.column);
    }

    return (table: result, selection: range);
  }

  static Set<({int row, int column})> _mergedAnchors(
    NoteTableObject table,
    NoteTableRange range,
  ) => {
    for (var row = range.firstRow; row <= range.lastRow; row++)
      for (var column = range.firstColumn; column <= range.lastColumn; column++)
        if (!table.rangeAt(row, column).isSingleCell)
          table.anchorOf(row, column),
  };
}
