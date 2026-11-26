part of 'note_library.dart';

/// Note and trash operations of a [NoteLibrary].
///
/// Operations that take several ids ignore unknown ones and repeats, apply
/// everything as one change (one notification) and return how many notes
/// changed. Passing [NoteLibrary.selection] to them is safe.
mixin _NoteLibraryNotes on _NoteLibraryBase {
  /// Called after notes were removed for good ([emptyTrash], [purgeNotes]), so
  /// that the document layer can delete their data.
  ValueChanged<List<String>>? onNotesRemoved;

  /// Called after [duplicateNotes] with the id of each source note mapped to
  /// the id of its copy, so that the document layer can copy their data.
  ValueChanged<Map<String, String>>? onNotesDuplicated;

  /// The notes outside the trash, in the order they were added.
  List<NoteSummary> get notes => List.unmodifiable(_notes);

  /// The deleted notes, the most recently deleted last.
  List<NoteSummary> get trash => List.unmodifiable(_trash);

  /// Adds a note with one page. The [title] is trimmed and may be empty, the
  /// [cover] defaults to [NoteCover.standard] and an unknown [folderId] is
  /// ignored. Both timestamps are the current time.
  NoteSummary createNote({
    String title = '',
    NoteCover? cover,
    String? folderId,
  }) {
    final now = _now();
    final note = NoteSummary(
      id: _newId(),
      title: title.trim(),
      cover: cover ?? NoteCover.standard,
      folderId: _hasFolder(folderId) ? folderId : null,
      createdAt: now,
      modifiedAt: now,
    );
    _notes.add(note);
    _commit();

    return note;
  }

  /// Renames a note and updates its modification time. Returns `false` for an
  /// unknown id, a blank title or the current title.
  bool renameNote(String id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;

    return _updateNote(
      id,
      (note) => note.title == trimmed
          ? note
          : note.copyWith(title: trimmed, modifiedAt: _now()),
    );
  }

  /// Changes a note's cover and updates its modification time. Returns whether
  /// it changed.
  bool setCover(String id, NoteCover cover) => _updateNote(
    id,
    (note) => note.cover == cover
        ? note
        : note.copyWith(cover: cover, modifiedAt: _now()),
  );

  /// Moves notes into [folderId], or out of every folder when it is `null`.
  /// An unknown folder moves nothing.
  int moveNotes(Iterable<String> ids, String? folderId) {
    if (folderId != null && !_hasFolder(folderId)) return 0;

    return _updateNotes(
      ids,
      (note) => note.folderId == folderId
          ? note
          : note.copyWith(folderId: () => folderId),
    );
  }

  /// Copies notes under new ids with the title followed by [suffix] (just
  /// [suffix] for an untitled note). Copies are not pinned, keep the cover,
  /// tags, folder and page count, and are created now. Returns them in the
  /// order of the originals in [notes].
  List<NoteSummary> duplicateNotes(
    Iterable<String> ids, {
    String suffix = 'copy',
  }) {
    final wanted = ids.toSet();
    final now = _now();
    final copies = {
      for (final note in _notes)
        if (wanted.contains(note.id))
          note.id: note.copyWith(
            id: _newId(),
            title: note.title.isEmpty ? suffix : '${note.title} $suffix',
            pinned: false,
            createdAt: now,
            modifiedAt: now,
          ),
    };
    if (copies.isEmpty) return const [];
    _notes.addAll(copies.values);
    _commit();
    onNotesDuplicated?.call(
      Map.unmodifiable({
        for (final entry in copies.entries) entry.key: entry.value.id,
      }),
    );

    return List.unmodifiable(copies.values);
  }

  /// Moves notes to the [trash]. Their data is kept until they are removed for
  /// good, so no callback fires.
  int deleteNotes(Iterable<String> ids) =>
      _transfer(ids, from: _notes, to: _trash);

  /// Brings notes back from the [trash]; a note whose folder is gone comes back
  /// outside every folder.
  int restoreNotes(Iterable<String> ids) =>
      _transfer(ids, from: _trash, to: _notes);

  /// Removes trashed notes for good and calls [onNotesRemoved] with the ids
  /// removed. Notes outside the trash are ignored.
  List<String> purgeNotes(Iterable<String> ids) {
    final wanted = ids.toSet();
    final removed = [
      for (final note in _trash)
        if (wanted.contains(note.id)) note.id,
    ];
    if (removed.isEmpty) return const [];
    _trash.removeWhere((note) => wanted.contains(note.id));
    _commit();
    onNotesRemoved?.call(List.unmodifiable(removed));

    return List.unmodifiable(removed);
  }

  /// Removes everything in the trash for good (see [purgeNotes]).
  List<String> emptyTrash() => purgeNotes([for (final note in _trash) note.id]);

  /// Pins notes so they are listed first.
  int pin(Iterable<String> ids) => _setPinned(ids, pinned: true);

  /// Removes the pin of notes.
  int unpin(Iterable<String> ids) => _setPinned(ids, pinned: false);

  /// Adds a tag, normalised with [NoteSummary.normalizeTag]. A tag that
  /// another note already has keeps that spelling. Returns `false` for an
  /// unknown id, a blank tag or a tag the note already has (ignoring case).
  bool addTag(String id, String tag) {
    final normalized = NoteSummary.normalizeTag(tag);
    if (normalized.isEmpty) return false;
    final spelled = _knownSpelling(normalized);

    return _updateNote(
      id,
      (note) => _indexOfTag(note, spelled) >= 0
          ? note
          : note.copyWith(tags: [...note.tags, spelled]),
    );
  }

  /// Removes a tag, ignoring case. Returns whether the note had it.
  bool removeTag(String id, String tag) {
    final normalized = NoteSummary.normalizeTag(tag);

    return _updateNote(id, (note) {
      final index = _indexOfTag(note, normalized);

      return index < 0
          ? note
          : note.copyWith(tags: [...note.tags]..removeAt(index));
    });
  }

  /// Marks a note as changed now, for the document layer to call after content
  /// edits, optionally recording the new [pageCount] (negative values are 0).
  bool touch(String id, {int? pageCount}) => _updateNote(
    id,
    (note) => note.copyWith(
      modifiedAt: _now(),
      pageCount: pageCount == null ? null : math.max(0, pageCount),
    ),
  );

  int _setPinned(Iterable<String> ids, {required bool pinned}) => _updateNotes(
    ids,
    (note) => note.pinned == pinned ? note : note.copyWith(pinned: pinned),
  );

  int _transfer(
    Iterable<String> ids, {
    required List<NoteSummary> from,
    required List<NoteSummary> to,
  }) {
    final wanted = ids.toSet();
    final moved = [
      for (final note in from)
        if (wanted.contains(note.id)) _withKnownFolder(note),
    ];
    if (moved.isEmpty) return 0;
    from.removeWhere((note) => wanted.contains(note.id));
    to.addAll(moved);
    _commit();

    return moved.length;
  }

  int _indexOfTag(NoteSummary note, String tag) {
    final lower = tag.toLowerCase();

    return note.tags.indexWhere((entry) => entry.toLowerCase() == lower);
  }

  String _knownSpelling(String tag) {
    final lower = tag.toLowerCase();
    for (final note in _notes) {
      for (final entry in note.tags) {
        if (entry.toLowerCase() == lower) return entry;
      }
    }

    return tag;
  }
}
