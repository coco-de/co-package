import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// One node of a note outline (table of contents): a title that jumps to a page,
/// with nested [children].
///
/// JSON: `{"id": String, "title": String, "pageId": String,
/// "children": [NoteOutlineEntry JSON, …]}`.
@immutable
class NoteOutlineEntry {
  /// Creates an entry; [children] is copied into an unmodifiable list.
  NoteOutlineEntry({
    required this.id,
    required this.title,
    required this.pageId,
    Iterable<NoteOutlineEntry> children = const [],
  }) : children = List<NoteOutlineEntry>.unmodifiable(children);

  /// [fromJson] drops entries nested deeper than this (a corrupt or hostile
  /// document must not exhaust the stack).
  static const int maxDecodeDepth = 256;

  /// Stable id, unique within one outline.
  final String id;

  /// Displayed title.
  final String title;

  /// Id of the target page (stable across page reordering).
  final String pageId;

  /// Sub-entries in display order (unmodifiable).
  final List<NoteOutlineEntry> children;

  /// Whether the entry has sub-entries.
  bool get hasChildren => children.isNotEmpty;

  /// Reads a [toJson] map.
  ///
  /// Returns `null` when [value] is not a map or has no non-empty `id`. Missing
  /// titles and page ids are empty; malformed children (and their subtrees) are
  /// skipped, as is everything nested deeper than [maxDecodeDepth].
  static NoteOutlineEntry? fromJson(Object? value) => _decode(value, 1);

  /// A copy with the given fields replaced.
  NoteOutlineEntry copyWith({
    String? id,
    String? title,
    String? pageId,
    Iterable<NoteOutlineEntry>? children,
  }) => NoteOutlineEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    pageId: pageId ?? this.pageId,
    children: children ?? this.children,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'id': id,
    'title': title,
    'pageId': pageId,
    'children': [for (final child in children) child.toJson()],
  };

  static NoteOutlineEntry? _decode(Object? value, int depth) {
    final json = NoteJson.asMap(value);
    if (json == null || depth > maxDecodeDepth) return null;
    final id = NoteJson.string(json, 'id');
    if (id.isEmpty) return null;

    return NoteOutlineEntry(
      id: id,
      title: NoteJson.string(json, 'title'),
      pageId: NoteJson.string(json, 'pageId'),
      children: [
        for (final child in NoteJson.list(json, 'children'))
          ?_decode(child, depth + 1),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NoteOutlineEntry &&
      other.id == id &&
      other.title == title &&
      other.pageId == pageId &&
      listEquals(other.children, children);

  @override
  int get hashCode => Object.hash(id, title, pageId, Object.hashAll(children));

  @override
  String toString() =>
      'NoteOutlineEntry($id, "$title", page: $pageId, '
      '${children.length} children)';
}
