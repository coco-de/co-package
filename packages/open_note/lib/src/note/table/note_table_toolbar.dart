import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/table/note_table_action.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_selection_controller.dart';
import 'package:open_note/src/note/table/note_table_strings.dart';
import 'package:open_note/src/note/table/note_table_toolbar_style.dart';

/// Buttons that change the structure of [table] around the cells selected in
/// [selectionController]: insert and delete rows and columns, merge and split.
///
/// A button is enabled only when it would do something for the selection (all
/// are disabled without one). Pressing one first applies any text still being
/// typed in a cell editor of the table, then calls [onChanged] with the new
/// table — the host commits it and passes it back as [table] — and moves the
/// selection to match. Pressing the toolbar does not take the focus away from a
/// cell editor.
class NoteTableToolbar extends StatelessWidget {
  /// Creates a toolbar for [table].
  const NoteTableToolbar({
    required this.table,
    required this.selectionController,
    required this.onChanged,
    super.key,
    this.actions = NoteTableAction.values,
    this.strings = const NoteTableStrings(),
    this.style = const NoteTableToolbarStyle(),
  });

  /// The key of the button for [action].
  static Key actionKey(NoteTableAction action) =>
      ValueKey<String>('note-table-action-${action.name}');

  /// The table the buttons act on.
  final NoteTableObject table;

  /// Holds the selected cells; give the same controller to the table view.
  final NoteTableSelectionController selectionController;

  /// Called with the changed table.
  final ValueChanged<NoteTableObject> onChanged;

  /// The buttons to show, in order.
  final List<NoteTableAction> actions;

  /// Button labels.
  final NoteTableStrings strings;

  /// Colours and sizes.
  final NoteTableToolbarStyle style;

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      label: strings.toolbarLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          border: Border.all(color: style.borderColor),
          borderRadius: BorderRadius.circular(style.radius),
        ),
        child: Padding(
          padding: EdgeInsets.all(style.spacing),
          child: ListenableBuilder(
            listenable: selectionController,
            builder: (context, _) => _buttons(),
          ),
        ),
      ),
    ),
  );

  Widget _buttons() {
    final selection = selectionController.rangeFor(table.id);

    return Wrap(
      spacing: style.spacing,
      runSpacing: style.spacing,
      children: [
        for (final action in actions)
          _NoteTableToolbarButton(
            key: actionKey(action),
            label: strings.labelFor(action),
            style: style,
            onPressed: action.isEnabled(table, selection)
                ? () => _perform(action)
                : null,
          ),
      ],
    );
  }

  void _perform(NoteTableAction action) {
    final base = selectionController.flushEditor(table);
    final selection = selectionController.rangeFor(table.id);
    if (selection == null) return;
    final result = action.apply(base, selection);
    if (result.table != table) onChanged(result.table);
    selectionController.select(table.id, result.selection);
  }
}

class _NoteTableToolbarButton extends StatelessWidget {
  const _NoteTableToolbarButton({
    required this.label,
    required this.style,
    required this.onPressed,
    super.key,
  });

  final String label;
  final NoteTableToolbarStyle style;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.buttonColor,
              borderRadius: BorderRadius.circular(style.radius),
            ),
            child: Padding(
              padding: style.buttonPadding,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? style.foregroundColor : style.disabledColor,
                  fontSize: style.fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
