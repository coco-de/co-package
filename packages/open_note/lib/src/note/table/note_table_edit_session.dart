import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_range.dart';

/// One open cell editor: the cell it edits and the text being typed.
///
/// Internal to the table module (not exported by the barrel).
class NoteTableEditSession {
  /// Opens an editor on the region of [table] that shows at ([row], [column]),
  /// with the cursor after the existing text.
  factory NoteTableEditSession(NoteTableObject table, int row, int column) {
    final anchor = table.anchorOf(row, column);
    final text = table.cellAt(anchor.row, anchor.column).text;

    return NoteTableEditSession._(
      range: table.rangeAt(anchor.row, anchor.column),
      grid: (rows: table.rowCount, columns: table.columnCount),
      originalText: text,
    );
  }

  NoteTableEditSession._({
    required this.range,
    required this.grid,
    required this.originalText,
  }) : controller = TextEditingController.fromValue(
         TextEditingValue(
           text: originalText,
           selection: TextSelection.collapsed(offset: originalText.length),
         ),
       ),
       focusNode = FocusNode(debugLabel: 'NoteTableCellEditor');

  /// The merged (or single) region being edited.
  final NoteTableRange range;

  /// Row and column counts of the table when the editor opened.
  final ({int rows, int columns}) grid;

  /// The cell text when the editor opened.
  final String originalText;

  /// The text being typed.
  final TextEditingController controller;

  /// Focus of the text field.
  final FocusNode focusNode;

  /// Row of the edited anchor.
  int get row => range.firstRow;

  /// Column of the edited anchor.
  int get column => range.firstColumn;

  /// Whether [cell] is the anchor being edited.
  bool isAt(({int row, int column}) cell) =>
      cell.row == row && cell.column == column;

  /// Whether the typed text can still safely be applied to [table]: the grid
  /// has the same size, the region is unchanged and its stored text is the one
  /// the editor started from (so no one else rewrote the cell).
  bool isValidFor(NoteTableObject table) =>
      table.rowCount == grid.rows &&
      table.columnCount == grid.columns &&
      table.rangeAt(row, column) == range &&
      table.cellAt(row, column).text == originalText;

  /// [table] with the typed text in the edited cell.
  NoteTableObject applyTo(NoteTableObject table) =>
      table.setCellText(row, column, controller.text);

  /// Releases the text controller and focus node.
  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
