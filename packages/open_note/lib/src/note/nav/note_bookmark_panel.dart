import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/internal/note_nav_frame.dart';
import 'package:open_note/src/note/nav/internal/note_nav_glyph.dart';
import 'package:open_note/src/note/nav/internal/note_nav_icon_button.dart';
import 'package:open_note/src/note/nav/internal/note_nav_message.dart';
import 'package:open_note/src/note/nav/internal/note_nav_rename_field.dart';
import 'package:open_note/src/note/nav/internal/note_nav_row.dart';
import 'package:open_note/src/note/nav/note_bookmark.dart';
import 'package:open_note/src/note/nav/note_bookmarks.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// The bookmarked pages of a note, in page order.
///
/// Tapping a row reports the bookmark. With [editable], rows can be renamed and
/// deleted, and a header button toggles the bookmark of [currentPageId]. A
/// bookmark without a title shows its page number.
///
/// The panel fills its constraints, which must bound the height.
class NoteBookmarkPanel extends StatefulWidget {
  /// Creates the panel.
  const NoteBookmarkPanel({
    required this.bookmarks,
    required this.pageOrder,
    required this.onBookmarkSelected,
    super.key,
    this.currentPageId,
    this.editable = true,
    this.strings = const NoteNavStrings(),
    this.style = const NoteNavStyle(),
  });

  /// The bookmarks shown and edited.
  final NoteBookmarks bookmarks;

  /// The page ids of the note, in order (used for sorting and page numbers).
  final List<String> pageOrder;

  /// A bookmark was tapped: jump to its page.
  final ValueChanged<NoteBookmark> onBookmarkSelected;

  /// The page on screen: its row is highlighted and the header button acts on it.
  final String? currentPageId;

  /// Whether bookmarks can be added, renamed and deleted.
  final bool editable;

  /// User-visible text.
  final NoteNavStrings strings;

  /// Colours and sizes.
  final NoteNavStyle style;

  @override
  State<NoteBookmarkPanel> createState() => _NoteBookmarkPanelState();
}

class _NoteBookmarkPanelState extends State<NoteBookmarkPanel> {
  String? _renamingId;
  String _draft = '';

  @override
  void didUpdateWidget(NoteBookmarkPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookmarks != widget.bookmarks || !widget.editable) {
      _renamingId = null;
    }
  }

  void _startRename(NoteBookmark bookmark) {
    _commitRename();
    setState(() {
      _renamingId = bookmark.id;
      _draft = widget.bookmarks.byId(bookmark.id)?.title ?? '';
    });
  }

  /// Ends the title edit; a blank title goes back to the page number.
  ///
  /// [only] limits it to the edit of that bookmark: a field that is going away
  /// may still report a blur and must not end the next edit.
  void _commitRename([String? only]) {
    final id = _renamingId;
    if (id == null || (only != null && only != id)) return;
    setState(() => _renamingId = null);
    widget.bookmarks.rename(id, _draft);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.bookmarks,
    builder: (context, _) {
      final rows = widget.bookmarks.ordered(widget.pageOrder);
      final page = widget.currentPageId;
      final marked = page != null && widget.bookmarks.isBookmarked(page);

      return NoteNavFrame(
        title: widget.strings.bookmarksTitle,
        style: widget.style,
        actions: [
          if (widget.editable && page != null)
            NoteNavIconButton(
              key: const ValueKey('note-bookmark-toggle'),
              glyph: marked
                  ? NoteNavGlyph.bookmarkFilled
                  : NoteNavGlyph.bookmark,
              label: marked
                  ? widget.strings.removeBookmark
                  : widget.strings.addBookmark,
              onPressed: () => widget.bookmarks.toggle(page),
              style: widget.style,
            ),
        ],
        body: rows.isEmpty
            ? NoteNavMessage(
                message: widget.strings.emptyBookmarks,
                style: widget.style,
              )
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final bookmark = rows[index];

                  return _NoteBookmarkTile(
                    key: ValueKey('note-bookmark-row-${bookmark.id}'),
                    bookmark: bookmark,
                    panel: widget,
                    renaming: _renamingId == bookmark.id,
                    draft: _draft,
                    onDraftChanged: (value) => _draft = value,
                    onCommit: () => _commitRename(bookmark.id),
                    onRename: () => _startRename(bookmark),
                  );
                },
              ),
      );
    },
  );
}

class _NoteBookmarkTile extends StatelessWidget {
  const _NoteBookmarkTile({
    required this.bookmark,
    required this.panel,
    required this.renaming,
    required this.draft,
    required this.onDraftChanged,
    required this.onCommit,
    required this.onRename,
    super.key,
  });

  final NoteBookmark bookmark;
  final NoteBookmarkPanel panel;
  final bool renaming;
  final String draft;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback onCommit;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final style = panel.style;
    final pageLabel = panel.strings.pageLabel(bookmark.pageId, panel.pageOrder);
    final titled = bookmark.title.isNotEmpty;

    return NoteNavRow(
      style: style,
      selected: bookmark.pageId == panel.currentPageId,
      onTap: renaming ? null : () => panel.onBookmarkSelected(bookmark),
      child: Row(
        children: [
          Expanded(
            child: renaming
                ? NoteNavRenameField(
                    initialText: draft,
                    hintText: panel.strings.titleHint,
                    onChanged: onDraftChanged,
                    onCommit: onCommit,
                    style: style,
                  )
                : _NoteBookmarkText(
                    title: titled ? bookmark.title : pageLabel,
                    subtitle: titled ? pageLabel : null,
                    style: style,
                  ),
          ),
          if (panel.editable) ...[
            NoteNavIconButton(
              key: ValueKey('note-bookmark-rename-${bookmark.id}'),
              glyph: NoteNavGlyph.rename,
              label: panel.strings.rename,
              onPressed: onRename,
              style: style,
            ),
            NoteNavIconButton(
              key: ValueKey('note-bookmark-delete-${bookmark.id}'),
              glyph: NoteNavGlyph.close,
              label: panel.strings.delete,
              onPressed: () => panel.bookmarks.remove(bookmark.id),
              style: style,
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteBookmarkText extends StatelessWidget {
  const _NoteBookmarkText({
    required this.title,
    required this.style,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final NoteNavStyle style;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: style.textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (subtitle != null) Text(subtitle!, style: style.secondaryTextStyle),
    ],
  );
}
