import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// How the user is looking at the library: layout, zoom, sort order and
/// filters.
///
/// JSON schema (`folderId`, `tag` and `query` are omitted when null):
/// ```json
/// {
///   "layout": "list" | "drawer",
///   "drawerZoom": 1.0,
///   "sortField": "name" | "modified" | "created",
///   "sortOrder": "ascending" | "descending",
///   "folderId": "…",
///   "tag": "…",
///   "query": "…"
/// }
/// ```
@immutable
class NoteLibraryViewState {
  /// Creates a view state. [drawerZoom] must lie within
  /// [minDrawerZoom]..[maxDrawerZoom].
  const NoteLibraryViewState({
    this.layout = NoteLibraryLayout.drawer,
    this.drawerZoom = 1,
    this.sortField = NoteSortField.modified,
    this.sortOrder = NoteSortOrder.descending,
    this.folderId,
    this.tag,
    this.query,
  }) : assert(
         drawerZoom >= minDrawerZoom && drawerZoom <= maxDrawerZoom,
         'drawerZoom out of range',
       );

  /// The smallest drawer zoom.
  static const double minDrawerZoom = 0.5;

  /// The largest drawer zoom.
  static const double maxDrawerZoom = 2;

  /// A grid of covers or a list of rows.
  final NoteLibraryLayout layout;

  /// The size of the drawer's covers relative to the default.
  final double drawerZoom;

  /// What notes are sorted by.
  final NoteSortField sortField;

  /// The sort direction; pinned notes come first in both.
  final NoteSortOrder sortOrder;

  /// Only notes directly in this folder are shown; `null` shows every note.
  final String? folderId;

  /// Only notes carrying this tag (ignoring case) are shown. A blank tag
  /// shows everything.
  final String? tag;

  /// Only notes whose title or tags contain this text (ignoring case) are
  /// shown. A blank query shows everything.
  final String? query;

  /// Limits [zoom] to the allowed range; a value that is not a finite number
  /// becomes 1.
  static double clampZoom(double zoom) =>
      zoom.isFinite ? zoom.clamp(minDrawerZoom, maxDrawerZoom).toDouble() : 1;

  /// Decodes the JSON form. Unknown names fall back to the defaults, the zoom
  /// is clamped and empty strings are `null`.
  factory NoteLibraryViewState.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};
    String? text(String key) {
      final entry = NoteJson.string(json, key);

      return entry.isEmpty ? null : entry;
    }

    return NoteLibraryViewState(
      layout: NoteJson.enumByName(
        NoteLibraryLayout.values,
        json['layout'],
        NoteLibraryLayout.drawer,
      ),
      drawerZoom: clampZoom(NoteJson.number(json, 'drawerZoom', 1)),
      sortField: NoteJson.enumByName(
        NoteSortField.values,
        json['sortField'],
        NoteSortField.modified,
      ),
      sortOrder: NoteJson.enumByName(
        NoteSortOrder.values,
        json['sortOrder'],
        NoteSortOrder.descending,
      ),
      folderId: text('folderId'),
      tag: text('tag'),
      query: text('query'),
    );
  }

  /// A copy with some fields replaced. [drawerZoom] is clamped. Pass
  /// `folderId: () => null` (likewise `tag` and `query`) to remove a filter.
  NoteLibraryViewState copyWith({
    NoteLibraryLayout? layout,
    double? drawerZoom,
    NoteSortField? sortField,
    NoteSortOrder? sortOrder,
    ValueGetter<String?>? folderId,
    ValueGetter<String?>? tag,
    ValueGetter<String?>? query,
  }) => NoteLibraryViewState(
    layout: layout ?? this.layout,
    drawerZoom: drawerZoom == null ? this.drawerZoom : clampZoom(drawerZoom),
    sortField: sortField ?? this.sortField,
    sortOrder: sortOrder ?? this.sortOrder,
    folderId: folderId == null ? this.folderId : folderId(),
    tag: tag == null ? this.tag : tag(),
    query: query == null ? this.query : query(),
  );

  /// The persisted form (see the class documentation).
  JsonMap toJson() => {
    'layout': layout.name,
    'drawerZoom': drawerZoom,
    'sortField': sortField.name,
    'sortOrder': sortOrder.name,
    'folderId': ?folderId,
    'tag': ?tag,
    'query': ?query,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteLibraryViewState &&
      other.layout == layout &&
      other.drawerZoom == drawerZoom &&
      other.sortField == sortField &&
      other.sortOrder == sortOrder &&
      other.folderId == folderId &&
      other.tag == tag &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
    layout,
    drawerZoom,
    sortField,
    sortOrder,
    folderId,
    tag,
    query,
  );

  @override
  String toString() => 'NoteLibraryViewState(${toJson()})';
}

/// How the library shows notes. The names are persisted.
enum NoteLibraryLayout {
  /// One row per note.
  list,

  /// A grid of notebook covers, zoomable with a pinch.
  drawer,
}

/// What notes can be sorted by. The names are persisted.
enum NoteSortField {
  /// The title, in natural order; untitled (empty) titles come first when
  /// ascending.
  name,

  /// When the note was last changed.
  modified,

  /// When the note was created.
  created,
}

/// The direction of a sort. The names are persisted.
enum NoteSortOrder {
  /// A to Z, oldest first.
  ascending,

  /// Z to A, newest first.
  descending,
}
