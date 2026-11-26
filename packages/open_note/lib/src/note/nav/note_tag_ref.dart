import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// What a tag is attached to: a whole note ([pageId] `null`) or one of its
/// pages.
///
/// JSON: `{"noteId": String, "pageId": String?}` (`pageId` omitted for a note).
@immutable
class NoteTagRef {
  /// A reference to the note [noteId], or to its page [pageId]; a blank
  /// [pageId] means the note itself.
  const NoteTagRef({required this.noteId, String? pageId})
    : pageId = pageId == '' ? null : pageId;

  /// Id of the note.
  final String noteId;

  /// Id of the page, or `null` for the note as a whole.
  final String? pageId;

  /// Whether the reference is to a whole note.
  bool get isNote => pageId == null;

  /// Reads a [toJson] map; `null` when [value] is not a map or has no non-empty
  /// `noteId`.
  static NoteTagRef? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final noteId = NoteJson.string(json, 'noteId');
    if (noteId.isEmpty) return null;

    return NoteTagRef(
      noteId: noteId,
      pageId: NoteJson.stringOrNull(json, 'pageId'),
    );
  }

  /// A copy with the given fields replaced; [clearPageId] turns it into a
  /// reference to the note itself (and wins over [pageId]).
  NoteTagRef copyWith({
    String? noteId,
    String? pageId,
    bool clearPageId = false,
  }) => NoteTagRef(
    noteId: noteId ?? this.noteId,
    pageId: clearPageId ? null : pageId ?? this.pageId,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {'noteId': noteId, 'pageId': ?pageId};

  @override
  bool operator ==(Object other) =>
      other is NoteTagRef && other.noteId == noteId && other.pageId == pageId;

  @override
  int get hashCode => Object.hash(noteId, pageId);

  @override
  String toString() => 'NoteTagRef($noteId, page: $pageId)';
}
