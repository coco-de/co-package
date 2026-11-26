import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_json.dart';

/// A bookmarked page of a note.
///
/// JSON: `{"id": String, "pageId": String, "title": String,
/// "createdAt": String}` (`createdAt` is ISO-8601 UTC).
@immutable
class NoteBookmark {
  /// Creates a bookmark of the page [pageId]; [createdAt] is kept in UTC.
  NoteBookmark({
    required this.id,
    required this.pageId,
    required DateTime createdAt,
    this.title = '',
  }) : createdAt = createdAt.toUtc();

  /// Stable id, unique among the bookmarks of a note.
  final String id;

  /// Id of the bookmarked page (stable across page reordering).
  final String pageId;

  /// User title; empty means "show the page number instead".
  final String title;

  /// Creation time, in UTC.
  final DateTime createdAt;

  /// Reads a [toJson] map.
  ///
  /// Returns `null` when [value] is not a map or lacks a non-empty `id` and
  /// `pageId`. A missing title is empty; a missing or malformed `createdAt`
  /// becomes the Unix epoch.
  static NoteBookmark? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final id = NoteJson.string(json, 'id');
    final pageId = NoteJson.string(json, 'pageId');
    if (id.isEmpty || pageId.isEmpty) return null;

    return NoteBookmark(
      id: id,
      pageId: pageId,
      title: NoteJson.string(json, 'title'),
      createdAt: noteNavDateFromJson(json['createdAt']),
    );
  }

  /// A copy with the given fields replaced.
  NoteBookmark copyWith({
    String? id,
    String? pageId,
    String? title,
    DateTime? createdAt,
  }) => NoteBookmark(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'id': id,
    'pageId': pageId,
    'title': title,
    'createdAt': noteNavDateToJson(createdAt),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteBookmark &&
      other.id == id &&
      other.pageId == pageId &&
      other.title == title &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, pageId, title, createdAt);

  @override
  String toString() => 'NoteBookmark($id, page: $pageId, "$title")';
}
