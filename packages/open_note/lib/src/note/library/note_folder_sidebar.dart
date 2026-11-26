import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/library/note_folder.dart';
import 'package:open_note/src/note/library/note_folder_icon_view.dart';
import 'package:open_note/src/note/library/note_folder_icons.dart';
import 'package:open_note/src/note/library/note_folder_tree.dart';
import 'package:open_note/src/note/library/note_library.dart';
import 'package:open_note/src/note/library/note_library_strings.dart';
import 'package:open_note/src/note/library/note_library_style.dart';

part 'note_folder_sidebar_row.dart';

/// The folders of a [NoteLibrary] as an indented tree, below an "all notes"
/// row. Every row shows the folder's icon and the number of notes directly in
/// it; the folder the library shows is highlighted.
///
/// A tap shows that folder in the library, then calls [onSelectFolder]. Folders
/// with subfolders can be closed and opened. The sidebar needs bounded
/// constraints.
class NoteFolderSidebar extends StatefulWidget {
  /// Creates a sidebar for [library].
  const NoteFolderSidebar({
    required this.library,
    super.key,
    this.onSelectFolder,
    this.onLongPressFolder,
    this.strings = const NoteLibraryStrings(),
    this.style = const NoteLibraryStyle(),
  });

  /// What is listed; the sidebar rebuilds when it changes.
  final NoteLibrary library;

  /// Called after a row was tapped, with `null` for "all notes".
  final ValueChanged<String?>? onSelectFolder;

  /// Called on a long press of a folder, for example to rename or delete it.
  final ValueChanged<NoteFolder>? onLongPressFolder;

  /// The texts.
  final NoteLibraryStrings strings;

  /// The colours and sizes.
  final NoteLibraryStyle style;

  /// The key of the row of [folderId] (`null` for the "all notes" row).
  static Key rowKey(String? folderId) =>
      ValueKey('noteFolderRow:${folderId ?? ''}');

  /// The key of the open/close toggle of [folderId].
  static Key toggleKey(String folderId) =>
      ValueKey('noteFolderToggle:$folderId');

  @override
  State<NoteFolderSidebar> createState() => _NoteFolderSidebarState();
}

class _NoteFolderSidebarState extends State<NoteFolderSidebar> {
  final Set<String> _closed = {};

  void _select(String? folderId) {
    widget.library.showFolder(folderId);
    widget.onSelectFolder?.call(folderId);
  }

  void _toggle(String folderId) => setState(() {
    if (!_closed.remove(folderId)) _closed.add(folderId);
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.library,
    builder: (context, _) => ColoredBox(
      color: widget.style.backgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [_allNotesRow(), ..._folderRows()],
      ),
    ),
  );

  Widget _allNotesRow() => _NoteFolderRow(
    key: NoteFolderSidebar.rowKey(null),
    sidebar: widget,
    iconKey: NoteFolderIcons.book,
    label: widget.strings.allNotes,
    count: widget.library.noteCount(),
    selected: widget.library.viewState.folderId == null,
    onTap: () => _select(null),
  );

  List<Widget> _folderRows() {
    final library = widget.library;
    final folders = library.folders;

    return [
      for (final node in NoteFolderTree.flatten(folders, collapsed: _closed))
        _NoteFolderRow(
          key: NoteFolderSidebar.rowKey(node.folder.id),
          sidebar: widget,
          iconKey: node.folder.iconKey,
          label: node.folder.name.isEmpty
              ? widget.strings.untitledFolder
              : node.folder.name,
          count: library.noteCount(folderId: node.folder.id),
          depth: node.depth,
          selected: library.viewState.folderId == node.folder.id,
          onTap: () => _select(node.folder.id),
          onLongPress: widget.onLongPressFolder == null
              ? null
              : () => widget.onLongPressFolder!(node.folder),
          open: folders.any((entry) => entry.parentId == node.folder.id)
              ? !_closed.contains(node.folder.id)
              : null,
          toggleKey: NoteFolderSidebar.toggleKey(node.folder.id),
          onToggle: () => _toggle(node.folder.id),
        ),
    ];
  }
}
