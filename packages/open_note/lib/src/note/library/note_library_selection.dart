part of 'note_library.dart';

/// Multi-selection of a [NoteLibrary].
///
/// Only notes that the current view shows can be selected: changes that hide a
/// selected note (a new filter, moving or deleting it) deselect it, so a bulk
/// action never touches a note the user cannot see.
mixin _NoteLibrarySelection on _NoteLibraryBase {
  /// Whether the user is selecting notes.
  bool get selectionMode => _selectionMode;

  /// Starts or ends selecting; ending clears the selection.
  set selectionMode(bool value) {
    if (value == _selectionMode) return;
    _selectionMode = value;
    if (!value) _selection.clear();
    notifyListeners();
  }

  /// The ids of the selected notes (a copy that does not change later).
  Set<String> get selection => Set.unmodifiable(_selection);

  /// The selected notes in display order.
  List<NoteSummary> get selectedNotes => [
    for (final note in NoteLibraryQuery.apply(_notes, _viewState))
      if (_selection.contains(note.id)) note,
  ];

  /// Whether the note [id] is selected.
  bool isSelected(String id) => _selection.contains(id);

  /// Selects or deselects a note and starts [selectionMode]. Returns `false`
  /// for a note that is unknown or hidden by the current view.
  bool toggleSelect(String id) {
    if (!_selection.remove(id)) {
      final note = noteById(id);
      if (note == null || !_isVisible(note)) return false;
      _selection.add(id);
    }
    _selectionMode = true;
    notifyListeners();

    return true;
  }

  /// Selects every note the current view shows and starts [selectionMode].
  void selectAll() {
    final shown = [
      for (final note in _notes)
        if (_isVisible(note)) note.id,
    ];
    final grows = shown.any((id) => !_selection.contains(id));
    if (_selectionMode && !grows) return;
    _selection.addAll(shown);
    _selectionMode = true;
    notifyListeners();
  }

  /// Deselects everything; [selectionMode] stays as it is.
  void clearSelection() {
    if (_selection.isEmpty) return;
    _selection.clear();
    notifyListeners();
  }
}
