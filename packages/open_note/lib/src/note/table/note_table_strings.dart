import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/table/note_table_action.dart';

/// All user-visible and accessibility text of the table widgets, in English by
/// default. Pass a translated instance as `strings:`.
@immutable
class NoteTableStrings {
  /// Creates the strings; every argument has an English default.
  const NoteTableStrings({
    this.toolbarLabel = 'Table tools',
    this.rowAbove = 'Row above',
    this.rowBelow = 'Row below',
    this.columnLeft = 'Column left',
    this.columnRight = 'Column right',
    this.deleteRow = 'Delete row',
    this.deleteColumn = 'Delete column',
    this.merge = 'Merge cells',
    this.split = 'Split cell',
    this.cellEditorLabel = 'Cell text',
    this.tableLabel = _defaultTableLabel,
    this.cellLabel = _defaultCellLabel,
  });

  /// Accessibility label of the toolbar.
  final String toolbarLabel;

  /// Button that inserts a row above the selection.
  final String rowAbove;

  /// Button that inserts a row below the selection.
  final String rowBelow;

  /// Button that inserts a column before the selection.
  final String columnLeft;

  /// Button that inserts a column after the selection.
  final String columnRight;

  /// Button that deletes the selected rows.
  final String deleteRow;

  /// Button that deletes the selected columns.
  final String deleteColumn;

  /// Button that merges the selected cells.
  final String merge;

  /// Button that splits the merged cells in the selection.
  final String split;

  /// Accessibility label of the cell text field.
  final String cellEditorLabel;

  /// Accessibility label of a table with `rows` rows and `columns` columns.
  final String Function(int rows, int columns) tableLabel;

  /// Accessibility label of a cell; `row` and `column` are 1-based.
  final String Function(int row, int column) cellLabel;

  /// The button text of [action].
  String labelFor(NoteTableAction action) => switch (action) {
    NoteTableAction.rowAbove => rowAbove,
    NoteTableAction.rowBelow => rowBelow,
    NoteTableAction.columnLeft => columnLeft,
    NoteTableAction.columnRight => columnRight,
    NoteTableAction.deleteRow => deleteRow,
    NoteTableAction.deleteColumn => deleteColumn,
    NoteTableAction.merge => merge,
    NoteTableAction.split => split,
  };

  static String _defaultTableLabel(int rows, int columns) =>
      'Table, $rows rows, $columns columns';

  static String _defaultCellLabel(int row, int column) =>
      'Row $row, column $column';
}
