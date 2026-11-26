import 'package:open_note/src/note/library/note_library_view_state.dart';
import 'package:open_note/src/note/library/note_natural_order.dart';
import 'package:open_note/src/note/library/note_summary.dart';

/// Filtering and sorting of notes according to a [NoteLibraryViewState].
abstract final class NoteLibraryQuery {
  /// The notes that pass the filters of [state], pinned notes first, sorted by
  /// its sort field and order. Ties are broken by name (natural order), then
  /// creation time, then id, so the result never depends on the input order.
  static List<NoteSummary> apply(
    Iterable<NoteSummary> notes,
    NoteLibraryViewState state,
  ) => [
    for (final note in notes)
      if (matches(note, state)) note,
  ]..sort((a, b) => compare(a, b, state));

  /// Whether [note] passes the folder, tag and query filters of [state].
  static bool matches(NoteSummary note, NoteLibraryViewState state) {
    final folderId = state.folderId;
    if (folderId != null && note.folderId != folderId) return false;
    final tag = NoteSummary.normalizeTag(state.tag ?? '').toLowerCase();
    if (tag.isNotEmpty && !_hasTag(note, tag)) return false;
    final query = state.query?.trim().toLowerCase() ?? '';
    if (query.isEmpty) return true;

    return note.title.toLowerCase().contains(query) ||
        note.tags.any((entry) => entry.toLowerCase().contains(query));
  }

  /// Compares two notes the way [apply] sorts them.
  static int compare(NoteSummary a, NoteSummary b, NoteLibraryViewState state) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final byField = _compareField(a, b, state.sortField);
    if (byField != 0) {
      return state.sortOrder == NoteSortOrder.ascending ? byField : -byField;
    }

    return _tieBreak(a, b);
  }

  /// Whether [note] has the lower-case, normalised tag [wanted].
  static bool _hasTag(NoteSummary note, String wanted) =>
      note.tags.any((entry) => entry.toLowerCase() == wanted);

  static int _compareField(NoteSummary a, NoteSummary b, NoteSortField field) =>
      switch (field) {
        NoteSortField.name => NoteNaturalOrder.compare(a.title, b.title),
        NoteSortField.modified => a.modifiedAt.compareTo(b.modifiedAt),
        NoteSortField.created => a.createdAt.compareTo(b.createdAt),
      };

  static int _tieBreak(NoteSummary a, NoteSummary b) {
    final byName = NoteNaturalOrder.compare(a.title, b.title);
    if (byName != 0) return byName;
    final byDate = a.createdAt.compareTo(b.createdAt);

    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }
}
