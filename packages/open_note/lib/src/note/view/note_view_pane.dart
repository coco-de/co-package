import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// One pane of a note view: which note it shows and on which page.
///
/// JSON: `{id, noteId?, pageIndex}`.
@immutable
class NoteViewPane {
  /// A pane with the unique [id].
  const NoteViewPane({required this.id, this.noteId, this.pageIndex = 0})
    : assert(pageIndex >= 0, 'pageIndex is 0-based');

  /// Stable identifier, unique within one layout.
  final String id;

  /// The note shown, or `null` when none is assigned yet — the host shows its
  /// default note or a note picker.
  final String? noteId;

  /// 0-based page index. The layout does not know page counts; the host clamps.
  final int pageIndex;

  /// A copy with the given fields replaced. Set [clearNoteId] to remove the
  /// note.
  NoteViewPane copyWith({
    String? id,
    String? noteId,
    int? pageIndex,
    bool clearNoteId = false,
  }) => NoteViewPane(
    id: id ?? this.id,
    noteId: clearNoteId ? null : noteId ?? this.noteId,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  /// The persisted form `{id, noteId?, pageIndex}`.
  JsonMap toJson() => {
    'id': id,
    if (noteId != null) 'noteId': noteId,
    'pageIndex': pageIndex,
  };

  /// Reads [toJson]; `null` when [value] is not an object with a non-empty
  /// `id`. A negative page index becomes 0 and an empty note id becomes `null`.
  static NoteViewPane? fromJson(Object? value) {
    final map = NoteJson.asMap(value);
    if (map == null) return null;
    final id = NoteJson.string(map, 'id');
    if (id.isEmpty) return null;
    final noteId = NoteJson.stringOrNull(map, 'noteId');
    final page = NoteJson.integer(map, 'pageIndex');

    return NoteViewPane(
      id: id,
      noteId: noteId == null || noteId.isEmpty ? null : noteId,
      pageIndex: page < 0 ? 0 : page,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteViewPane &&
      other.id == id &&
      other.noteId == noteId &&
      other.pageIndex == pageIndex;

  @override
  int get hashCode => Object.hash(id, noteId, pageIndex);

  @override
  String toString() => 'NoteViewPane($id, note: $noteId, page: $pageIndex)';
}
