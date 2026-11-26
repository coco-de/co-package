import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/internal/note_nav_glyph.dart';
import 'package:open_note/src/note/nav/internal/note_nav_icon_button.dart';
import 'package:open_note/src/note/nav/internal/note_nav_rename_field.dart';
import 'package:open_note/src/note/nav/internal/note_nav_row.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';
import 'package:open_note/src/note/nav/note_outline_row.dart';

/// One line of the outline panel: chevron, title (or title editor), page label
/// and, in edit mode, a second line with the edit buttons (so a narrow panel
/// does not overflow). Not exported by the barrel.
class NoteOutlineTile extends StatelessWidget {
  const NoteOutlineTile({
    required this.row,
    required this.strings,
    required this.style,
    required this.onSelect,
    required this.onToggle,
    super.key,
    this.collapsed = false,
    this.selected = false,
    this.pageLabel,
    this.actions,
    this.rename,
  });

  final NoteOutlineRow row;
  final NoteNavStrings strings;
  final NoteNavStyle style;
  final VoidCallback onSelect;
  final VoidCallback onToggle;
  final bool collapsed;
  final bool selected;
  final String? pageLabel;

  /// Edit buttons; `null` outside the edit mode.
  final NoteOutlineRowActions? actions;

  /// Present while the title is being edited.
  final NoteOutlineRowRename? rename;

  @override
  Widget build(BuildContext context) {
    final edit = actions;

    return NoteNavRow(
      style: style,
      indent: row.depth * style.indentWidth,
      selected: selected,
      onTap: rename == null ? onSelect : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NoteOutlineTitleLine(tile: this),
          if (edit != null)
            _NoteOutlineEditLine(
              id: row.entry.id,
              actions: edit,
              strings: strings,
              style: style,
            ),
        ],
      ),
    );
  }
}

/// What a row of the outline panel can do in edit mode; a `null` callback shows
/// a disabled button. Not exported by the barrel.
@immutable
class NoteOutlineRowActions {
  const NoteOutlineRowActions({
    required this.onRename,
    required this.onDelete,
    required this.onAddChild,
    required this.onIndent,
    required this.onOutdent,
  });

  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onAddChild;
  final VoidCallback? onIndent;
  final VoidCallback? onOutdent;
}

/// The rename state of a row. Not exported by the barrel.
@immutable
class NoteOutlineRowRename {
  const NoteOutlineRowRename({
    required this.draft,
    required this.onChanged,
    required this.onCommit,
  });

  final String draft;
  final ValueChanged<String> onChanged;
  final VoidCallback onCommit;
}

class _NoteOutlineTitleLine extends StatelessWidget {
  const _NoteOutlineTitleLine({required this.tile});

  final NoteOutlineTile tile;

  @override
  Widget build(BuildContext context) {
    final entry = tile.row.entry;
    final editor = tile.rename;
    final label = tile.pageLabel;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tile.style.rowHeight - 2),
      child: Row(
        children: [
          if (entry.hasChildren)
            NoteNavIconButton(
              key: ValueKey('note-outline-toggle-${entry.id}'),
              glyph: tile.collapsed
                  ? NoteNavGlyph.chevronRight
                  : NoteNavGlyph.chevronDown,
              label: tile.collapsed
                  ? tile.strings.expand
                  : tile.strings.collapse,
              onPressed: tile.onToggle,
              style: tile.style,
            )
          else
            SizedBox(width: tile.style.iconSize),
          Expanded(
            child: editor == null
                ? Text(
                    entry.title,
                    style: tile.style.textStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : NoteNavRenameField(
                    key: ValueKey('note-outline-field-${entry.id}'),
                    initialText: editor.draft,
                    hintText: entry.title,
                    onChanged: editor.onChanged,
                    onCommit: editor.onCommit,
                    style: tile.style,
                  ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(label, style: tile.style.secondaryTextStyle),
            ),
        ],
      ),
    );
  }
}

class _NoteOutlineEditLine extends StatelessWidget {
  const _NoteOutlineEditLine({
    required this.id,
    required this.actions,
    required this.strings,
    required this.style,
  });

  final String id;
  final NoteOutlineRowActions actions;
  final NoteNavStrings strings;
  final NoteNavStyle style;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Wrap(
      children: [
        NoteNavIconButton(
          key: ValueKey('note-outline-add-child-$id'),
          glyph: NoteNavGlyph.plus,
          label: strings.addChild,
          onPressed: actions.onAddChild,
          style: style,
        ),
        NoteNavIconButton(
          key: ValueKey('note-outline-rename-$id'),
          glyph: NoteNavGlyph.rename,
          label: strings.rename,
          onPressed: actions.onRename,
          style: style,
        ),
        NoteNavIconButton(
          key: ValueKey('note-outline-outdent-$id'),
          glyph: NoteNavGlyph.outdent,
          label: strings.outdent,
          onPressed: actions.onOutdent,
          style: style,
        ),
        NoteNavIconButton(
          key: ValueKey('note-outline-indent-$id'),
          glyph: NoteNavGlyph.indent,
          label: strings.indent,
          onPressed: actions.onIndent,
          style: style,
        ),
        NoteNavIconButton(
          key: ValueKey('note-outline-delete-$id'),
          glyph: NoteNavGlyph.close,
          label: strings.delete,
          onPressed: actions.onDelete,
          style: style,
        ),
      ],
    ),
  );
}
