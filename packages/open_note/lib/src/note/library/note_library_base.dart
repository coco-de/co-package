part of 'note_library.dart';

/// The state of a [NoteLibrary] and the lookups its parts share.
abstract class _NoteLibraryBase extends ChangeNotifier {
  _NoteLibraryBase(this._newId, this._now);

  final NoteIdFactory _newId;
  final NoteClock _now;
  final List<NoteFolder> _folders = [];
  final List<NoteSummary> _notes = [];
  final List<NoteSummary> _trash = [];
  final Set<String> _selection = <String>{};
  bool _selectionMode = false;
  NoteLibraryViewState _viewState = const NoteLibraryViewState();

  /// The folder with [id], or `null`.
  NoteFolder? folderById(String? id) {
    if (id == null) return null;
    for (final folder in _folders) {
      if (folder.id == id) return folder;
    }

    return null;
  }

  /// The note with [id], or `null`. The trash is not searched.
  NoteSummary? noteById(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }

    return null;
  }

  bool _hasFolder(String? id) => folderById(id) != null;

  /// [note] without a folder reference that points nowhere.
  NoteSummary _withKnownFolder(NoteSummary note) =>
      note.folderId == null || _hasFolder(note.folderId)
      ? note
      : note.copyWith(folderId: () => null);

  bool _isVisible(NoteSummary note) =>
      NoteLibraryQuery.matches(note, _viewState);

  /// Keeps the selection to notes that are still shown, then notifies.
  void _commit() {
    if (_selection.isNotEmpty) {
      final shown = {
        for (final note in _notes)
          if (_isVisible(note)) note.id,
      };
      _selection.retainWhere(shown.contains);
    }
    notifyListeners();
  }

  /// Replaces each note in [ids] with `change(note)` and returns how many
  /// actually differ. [change] returns its argument to leave a note alone.
  int _updateNotes(
    Iterable<String> ids,
    NoteSummary Function(NoteSummary note) change,
  ) {
    final wanted = ids.toSet();
    var changed = 0;
    for (var i = 0; i < _notes.length; i++) {
      if (!wanted.contains(_notes[i].id)) continue;
      final next = change(_notes[i]);
      if (next == _notes[i]) continue;
      _notes[i] = next;
      changed++;
    }
    if (changed > 0) _commit();

    return changed;
  }

  bool _updateNote(String id, NoteSummary Function(NoteSummary note) change) =>
      _updateNotes([id], change) > 0;
}
