import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_selection_controller.dart';
import 'package:open_note/src/note/table/note_table_strings.dart';
import 'package:open_note/src/note/table/note_table_view.dart';
import 'package:open_note/src/note/table/note_table_view_style.dart';

/// Registers the `table` kind in [registry]: decoding with
/// `NoteTableObject.fromPayload` and a `NoteTableView` per object (keyed by its
/// id).
///
/// Pass the [selectionController] that the app's `NoteTableToolbar` listens to;
/// without it each view keeps a private selection. [strings] and [viewStyle]
/// apply to every table view.
void registerNoteTableObject(
  NoteObjectRegistry registry, {
  NoteTableSelectionController? selectionController,
  NoteTableStrings strings = const NoteTableStrings(),
  NoteTableViewStyle viewStyle = const NoteTableViewStyle(),
}) => registry.register(
  NoteTableObject.kindName,
  decoder: NoteTableObject.fromPayload,
  builder: (context, object, scope) => object is NoteTableObject
      ? NoteTableView(
          key: ValueKey<String>('note-table-${object.id}'),
          table: object,
          scope: scope,
          selectionController: selectionController,
          strings: strings,
          style: viewStyle,
        )
      : const SizedBox.shrink(),
);
