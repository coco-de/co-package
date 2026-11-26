import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/table/note_table_edit_session.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_painter.dart';
import 'package:open_note/src/note/table/note_table_strings.dart';
import 'package:open_note/src/note/table/note_table_view_style.dart';

/// The text field laid over the cell of an edit session, styled like the cell's
/// painted text. Escape cancels; losing focus or the keyboard's done action
/// submits.
///
/// Internal to the table module (not exported by the barrel).
class NoteTableCellEditor extends StatelessWidget {
  /// Creates the editor of [session] for a cell of size [cellSize].
  const NoteTableCellEditor({
    required this.session,
    required this.table,
    required this.cellSize,
    required this.viewStyle,
    required this.strings,
    required this.onSubmitted,
    required this.onCancel,
    super.key,
  });

  /// The open editing session.
  final NoteTableEditSession session;

  /// The table being edited.
  final NoteTableObject table;

  /// Size of the edited cell or merged region.
  final Size cellSize;

  /// Colours of the editor.
  final NoteTableViewStyle viewStyle;

  /// Accessibility text.
  final NoteTableStrings strings;

  /// Called when the field submits or loses focus.
  final VoidCallback onSubmitted;

  /// Called when the user presses Escape.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final field = CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
      child: _buildTextField(),
    );
    final labelled = Semantics(label: strings.cellEditorLabel, child: field);

    // The painted text ignores the platform text scale, so the editor must too.
    return MediaQuery.maybeOf(context) == null
        ? labelled
        : MediaQuery.withNoTextScaling(child: labelled);
  }

  NoteTextField _buildTextField() {
    final cell = table.cellAt(session.row, session.column);
    final padding = NoteTablePainter.paddingFor(
      Offset.zero & cellSize,
      table.style.cellPadding,
    );

    return NoteTextField(
      key: ObjectKey(session),
      controller: session.controller,
      focusNode: session.focusNode,
      onSubmitted: (_) => onSubmitted(),
      submitOnBlur: true,
      maxLines: null,
      textAlign: NoteTablePainter.textAlignFor(cell.align),
      style: NoteTablePainter.textStyleFor(table.style, cell),
      cursorColor: viewStyle.cursorColor,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: viewStyle.editorColor,
        border: Border.all(
          color: viewStyle.selectionColor,
          width: viewStyle.selectionBorderWidth,
        ),
      ),
    );
  }
}
