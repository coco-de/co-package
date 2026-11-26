part of 'note_library.dart';

/// Folder operations of a [NoteLibrary].
///
/// Sibling folders always have the orders 0, 1, 2…
mixin _NoteLibraryFolders on _NoteLibraryBase {
  /// Every folder in tree order: each folder is followed by its subfolders.
  List<NoteFolder> get folders => List.unmodifiable(_folders);

  /// The direct subfolders of [parentId] (`null` for the top level), in order.
  List<NoteFolder> childFolders(String? parentId) =>
      NoteFolderTree.childrenOf(_folders, parentId);

  /// How many notes are directly in [folderId]; every note when it is `null`.
  /// The trash is not counted.
  int noteCount({String? folderId}) => folderId == null
      ? _notes.length
      : _notes.where((note) => note.folderId == folderId).length;

  /// Adds a folder after the other children of [parentId] (the top level when
  /// it is `null` or unknown). The name is trimmed and may be empty.
  NoteFolder createFolder(
    String name, {
    String iconKey = NoteFolderIcons.folder,
    String? parentId,
  }) {
    final parent = _hasFolder(parentId) ? parentId : null;
    final folder = NoteFolder(
      id: _newId(),
      name: name.trim(),
      iconKey: iconKey.isEmpty ? NoteFolderIcons.folder : iconKey,
      parentId: parent,
      order: childFolders(parent).length,
      createdAt: _now(),
    );
    _setFolders([..._folders, folder]);

    return folder;
  }

  /// Renames a folder. Returns `false` for an unknown id, a blank name or the
  /// current name.
  bool renameFolder(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    return _updateFolder(id, (folder) => folder.copyWith(name: trimmed));
  }

  /// Changes a folder's icon (see [NoteFolderIcons]). Returns whether it
  /// changed.
  bool setFolderIcon(String id, String iconKey) =>
      iconKey.isNotEmpty &&
      _updateFolder(id, (folder) => folder.copyWith(iconKey: iconKey));

  /// Moves a folder under [newParentId] (`null` for the top level), at [index]
  /// among its new siblings, or last when [index] is `null`.
  ///
  /// Returns `false` without changes for an unknown folder or parent, a parent
  /// that is the folder itself or one of its subfolders, or a move that changes
  /// nothing.
  bool moveFolder(String id, String? newParentId, {int? index}) {
    final folder = folderById(id);
    if (folder == null || !_canMoveInto(id, newParentId)) return false;
    if (newParentId == folder.parentId && index == null) return false;

    return _placeFolder(folder, newParentId, index);
  }

  /// Moves a folder to position [newIndex] among its siblings. The index is the
  /// folder's position afterwards and is clamped. Returns whether it moved.
  bool reorderFolder(String id, int newIndex) {
    final folder = folderById(id);

    return folder != null && _placeFolder(folder, folder.parentId, newIndex);
  }

  /// Deletes one folder. Its subfolders move up into its parent, taking its
  /// place, and its notes (trashed ones too) move to [moveNotesTo], or out of
  /// every folder when that is `null`, unknown or the deleted folder. A view of
  /// the deleted folder switches to its parent. Returns whether it existed.
  bool deleteFolder(String id, {String? moveNotesTo}) {
    final folder = folderById(id);
    if (folder == null) return false;
    final destination = moveNotesTo != id && _hasFolder(moveNotesTo)
        ? moveNotesTo
        : null;
    final siblings = childFolders(folder.parentId);
    final position = siblings.indexWhere((entry) => entry.id == id);
    siblings.replaceRange(position, position + 1, [
      for (final child in childFolders(id))
        child.copyWith(parentId: () => folder.parentId),
    ]);
    final moved = _numbered(siblings);
    _reassignNotes(id, destination);
    if (_viewState.folderId == id) {
      _viewState = _viewState.copyWith(folderId: () => folder.parentId);
    }
    _setFolders([
      for (final entry in _folders)
        if (entry.id != id) moved[entry.id] ?? entry,
    ]);

    return true;
  }

  bool _canMoveInto(String id, String? parentId) =>
      parentId == null ||
      (parentId != id &&
          _hasFolder(parentId) &&
          !NoteFolderTree.descendantsOf(_folders, id).contains(parentId));

  /// Puts [folder] under [parentId] at [index] (last when `null`).
  bool _placeFolder(NoteFolder folder, String? parentId, int? index) {
    final siblings = childFolders(parentId)
      ..removeWhere((entry) => entry.id == folder.id);
    final target = (index ?? siblings.length).clamp(0, siblings.length);
    if (parentId == folder.parentId && target == folder.order) return false;
    siblings.insert(target, folder.copyWith(parentId: () => parentId));
    final moved = _numbered(siblings);
    _setFolders([for (final entry in _folders) moved[entry.id] ?? entry]);

    return true;
  }

  Map<String, NoteFolder> _numbered(List<NoteFolder> siblings) => {
    for (final (index, folder) in siblings.indexed)
      folder.id: folder.copyWith(order: index),
  };

  void _reassignNotes(String folderId, String? destination) {
    for (final list in [_notes, _trash]) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].folderId == folderId) {
          list[i] = list[i].copyWith(folderId: () => destination);
        }
      }
    }
  }

  bool _updateFolder(String id, NoteFolder Function(NoteFolder) change) {
    final index = _folders.indexWhere((folder) => folder.id == id);
    if (index < 0) return false;
    final next = change(_folders[index]);
    if (next == _folders[index]) return false;
    _folders[index] = next;
    _commit();

    return true;
  }

  void _setFolders(List<NoteFolder> next) {
    final sanitized = NoteFolderTree.sanitize(next);
    _folders
      ..clear()
      ..addAll(sanitized);
    _commit();
  }
}
