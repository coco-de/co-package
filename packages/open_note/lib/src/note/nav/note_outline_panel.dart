import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/internal/note_nav_frame.dart';
import 'package:open_note/src/note/nav/internal/note_nav_glyph.dart';
import 'package:open_note/src/note/nav/internal/note_nav_icon_button.dart';
import 'package:open_note/src/note/nav/internal/note_nav_message.dart';
import 'package:open_note/src/note/nav/internal/note_nav_text_button.dart';
import 'package:open_note/src/note/nav/internal/note_outline_tile.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';
import 'package:open_note/src/note/nav/note_outline.dart';
import 'package:open_note/src/note/nav/note_outline_entry.dart';
import 'package:open_note/src/note/nav/note_outline_row.dart';

/// The table of contents of a note: an expandable tree; tapping an entry jumps
/// to its page.
///
/// With [editable], an edit mode adds, renames, deletes, indents and outdents
/// entries (the changes go straight to [outline]). New entries target
/// [currentPageId], so adding is disabled without one. Deleting an entry also
/// deletes its sub-entries. Expand/collapse state belongs to the widget (all
/// expanded at first).
///
/// The panel fills its constraints, which must bound the height.
class NoteOutlinePanel extends StatefulWidget {
  /// Creates the panel.
  const NoteOutlinePanel({
    required this.outline,
    required this.onEntrySelected,
    super.key,
    this.currentPageId,
    this.pageLabelOf,
    this.editable = true,
    this.strings = const NoteNavStrings(),
    this.style = const NoteNavStyle(),
  });

  /// The outline shown and edited.
  final NoteOutline outline;

  /// An entry was tapped: jump to its page.
  final ValueChanged<NoteOutlineEntry> onEntrySelected;

  /// The page on screen: its entry is highlighted and new entries target it.
  final String? currentPageId;

  /// Optional label shown at the end of a row (for example the page number).
  final String? Function(String pageId)? pageLabelOf;

  /// Whether the edit mode is offered.
  final bool editable;

  /// User-visible text.
  final NoteNavStrings strings;

  /// Colours and sizes.
  final NoteNavStyle style;

  @override
  State<NoteOutlinePanel> createState() => _NoteOutlinePanelState();
}

class _NoteOutlinePanelState extends State<NoteOutlinePanel> {
  final Set<String> _collapsed = {};
  bool _editing = false;
  String? _renamingId;
  String _draft = '';

  @override
  void didUpdateWidget(NoteOutlinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outline != widget.outline) {
      _collapsed.clear();
      _renamingId = null;
    }
    if (!widget.editable) {
      _editing = false;
      _renamingId = null;
    }
  }

  void _toggleEditing() {
    _commitRename();
    setState(() => _editing = !_editing);
  }

  void _toggleCollapsed(String id) => setState(() {
    if (!_collapsed.remove(id)) _collapsed.add(id);
  });

  void _startRename(String id) {
    _commitRename();
    setState(() {
      _renamingId = id;
      _draft = widget.outline.find(id)?.title ?? '';
    });
  }

  /// Ends the title edit, keeping the old title when the new one is blank.
  ///
  /// [only] limits it to the edit of that entry: a field that is going away may
  /// still report a blur and must not end the next edit.
  void _commitRename([String? only]) {
    final id = _renamingId;
    if (id == null || (only != null && only != id)) return;
    setState(() => _renamingId = null);
    if (_draft.trim().isNotEmpty) widget.outline.rename(id, _draft);
  }

  void _addEntry(String? parentId) {
    final pageId = widget.currentPageId;
    if (pageId == null) return;
    _commitRename();
    final entry = widget.outline.add(
      widget.strings.newEntryTitle,
      pageId,
      parentId: parentId,
    );
    if (entry == null) return;
    setState(() {
      _collapsed.remove(parentId);
      _renamingId = entry.id;
      _draft = '';
    });
  }

  void _indent(String id) {
    if (!widget.outline.indent(id)) return;
    final parent = widget.outline.parentOf(id);
    setState(() => _collapsed.remove(parent?.id));
  }

  /// The rows not hidden below a collapsed entry, each with whether it has a
  /// previous sibling (and so can be indented).
  List<(NoteOutlineRow, bool)> _visibleRows() {
    final seenParents = <String?>{};
    final visible = <(NoteOutlineRow, bool)>[];
    int? hiddenBelow;
    for (final row in widget.outline.flatten()) {
      final hasPrevious = !seenParents.add(row.parentId);
      if (hiddenBelow != null && row.depth > hiddenBelow) continue;
      hiddenBelow = _collapsed.contains(row.entry.id) ? row.depth : null;
      visible.add((row, hasPrevious));
    }

    return visible;
  }

  NoteOutlineRowActions _actionsFor(NoteOutlineRow row, bool hasPrevious) {
    final id = row.entry.id;

    return NoteOutlineRowActions(
      onRename: () => _startRename(id),
      onDelete: () => widget.outline.remove(id),
      onAddChild: widget.currentPageId == null ? null : () => _addEntry(id),
      onIndent: hasPrevious ? () => _indent(id) : null,
      onOutdent: row.depth > 0 ? () => widget.outline.outdent(id) : null,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.outline,
    builder: (context, _) {
      final rows = _visibleRows();
      final page = widget.currentPageId;
      final current = page == null ? null : widget.outline.entryForPage(page);

      return NoteNavFrame(
        title: widget.strings.outlineTitle,
        style: widget.style,
        actions: [
          if (_editing)
            NoteNavIconButton(
              key: const ValueKey('note-outline-add'),
              glyph: NoteNavGlyph.plus,
              label: widget.strings.add,
              onPressed: page == null ? null : () => _addEntry(null),
              style: widget.style,
            ),
          if (widget.editable)
            NoteNavTextButton(
              key: const ValueKey('note-outline-edit'),
              label: _editing ? widget.strings.done : widget.strings.edit,
              onPressed: _toggleEditing,
              style: widget.style,
            ),
        ],
        body: rows.isEmpty
            ? NoteNavMessage(
                message: widget.strings.emptyOutline,
                style: widget.style,
              )
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final (row, hasPrevious) = rows[index];
                  final entry = row.entry;

                  return NoteOutlineTile(
                    key: ValueKey('note-outline-row-${entry.id}'),
                    row: row,
                    strings: widget.strings,
                    style: widget.style,
                    onSelect: () => widget.onEntrySelected(entry),
                    onToggle: () => _toggleCollapsed(entry.id),
                    collapsed: _collapsed.contains(entry.id),
                    selected: entry.id == current?.id,
                    pageLabel: widget.pageLabelOf?.call(entry.pageId),
                    actions: _editing ? _actionsFor(row, hasPrevious) : null,
                    rename: _renamingId == entry.id
                        ? NoteOutlineRowRename(
                            draft: _draft,
                            onChanged: (value) => _draft = value,
                            onCommit: () => _commitRename(entry.id),
                          )
                        : null,
                  );
                },
              ),
      );
    },
  );
}
