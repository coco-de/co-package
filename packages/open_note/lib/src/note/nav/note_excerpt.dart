import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_text.dart';

/// A clipped region of a page that the reader saved to come back to.
///
/// [rect] is stored in **fractions of the page** (`0`–`1`, origin top-left), so
/// it survives a page-size change; see [rectIn] and [fractionsOf].
///
/// JSON: `{"id": String, "pageId": String, "rect": {"x","y","w","h"},
/// "label": String?, "note": String?, "color": int (ARGB32)?,
/// "createdAt": String (ISO-8601 UTC)}`; absent optional values are omitted.
@immutable
class NoteExcerpt {
  /// Creates an excerpt.
  ///
  /// [rect] is normalised by [normalizeRect]. [label] has its whitespace
  /// collapsed and [note] is trimmed; both become `null` when blank. [color]
  /// is kept as 8-bit ARGB, the precision it is stored with, and [createdAt] in
  /// UTC.
  NoteExcerpt({
    required this.id,
    required this.pageId,
    required Rect rect,
    required DateTime createdAt,
    String? label,
    String? note,
    Color? color,
  }) : rect = normalizeRect(rect),
       label = _nonBlank(noteNavCollapse(label ?? '')),
       note = _nonBlank((note ?? '').trim()),
       color = color == null ? null : Color(color.toARGB32()),
       createdAt = createdAt.toUtc();

  static const double _grid = 1e9;

  /// Stable id, unique among the excerpts of a note.
  final String id;

  /// Id of the page the region is on (stable across page reordering).
  final String pageId;

  /// The region as fractions of the page, `0 ≤ left ≤ right ≤ 1` and
  /// `0 ≤ top ≤ bottom ≤ 1`.
  final Rect rect;

  /// Group label, or `null`.
  final String? label;

  /// The reader's own remark, or `null`.
  final String? note;

  /// Highlight colour, or `null` to use the default of the view.
  final Color? color;

  /// Creation time, in UTC.
  final DateTime createdAt;

  /// Whether [rect] covers a non-empty area.
  bool get hasArea => rect.width > 0 && rect.height > 0;

  /// Orders the edges, clamps them into `0`–`1` and rounds them to 1e-9 (so a
  /// JSON round trip gives back an equal rect). A non-finite rect becomes
  /// [Rect.zero].
  static Rect normalizeRect(Rect rect) {
    if (!rect.isFinite) return Rect.zero;

    return Rect.fromLTRB(
      _unit(math.min(rect.left, rect.right)),
      _unit(math.min(rect.top, rect.bottom)),
      _unit(math.max(rect.left, rect.right)),
      _unit(math.max(rect.top, rect.bottom)),
    );
  }

  /// [pageRect] (page coordinates) as fractions of a page of [pageSize];
  /// [Rect.zero] when the page has no size.
  static Rect fractionsOf(Rect pageRect, Size pageSize) {
    if (pageSize.width <= 0 || pageSize.height <= 0) return Rect.zero;

    return normalizeRect(
      Rect.fromLTRB(
        pageRect.left / pageSize.width,
        pageRect.top / pageSize.height,
        pageRect.right / pageSize.width,
        pageRect.bottom / pageSize.height,
      ),
    );
  }

  /// [rect] in the page coordinates of a page of [pageSize].
  Rect rectIn(Size pageSize) => Rect.fromLTRB(
    rect.left * pageSize.width,
    rect.top * pageSize.height,
    rect.right * pageSize.width,
    rect.bottom * pageSize.height,
  );

  /// Reads a [toJson] map.
  ///
  /// Returns `null` when [value] is not a map, lacks a non-empty `id` or
  /// `pageId`, or has no rect with an area after normalisation. Optional fields
  /// of the wrong type are ignored; a bad `createdAt` becomes the Unix epoch.
  static NoteExcerpt? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final rawColor = json['color'];
    final excerpt = NoteExcerpt(
      id: NoteJson.string(json, 'id'),
      pageId: NoteJson.string(json, 'pageId'),
      rect: NoteJson.rect(json, 'rect'),
      label: NoteJson.stringOrNull(json, 'label'),
      note: NoteJson.stringOrNull(json, 'note'),
      color: rawColor is num
          ? NoteJson.colorFromJson(rawColor, const Color(0x00000000))
          : null,
      createdAt: noteNavDateFromJson(json['createdAt']),
    );
    final usable =
        excerpt.id.isNotEmpty && excerpt.pageId.isNotEmpty && excerpt.hasArea;

    return usable ? excerpt : null;
  }

  /// A copy with the given fields replaced; the `clear…` flags set the optional
  /// fields back to `null` (and win over a new value).
  NoteExcerpt copyWith({
    String? id,
    String? pageId,
    Rect? rect,
    String? label,
    String? note,
    Color? color,
    DateTime? createdAt,
    bool clearLabel = false,
    bool clearNote = false,
    bool clearColor = false,
  }) => NoteExcerpt(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    rect: rect ?? this.rect,
    label: clearLabel ? null : label ?? this.label,
    note: clearNote ? null : note ?? this.note,
    color: clearColor ? null : color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'id': id,
    'pageId': pageId,
    'rect': NoteJson.rectToJson(rect),
    'label': ?label,
    'note': ?note,
    if (color case final value?) 'color': NoteJson.colorToJson(value),
    'createdAt': noteNavDateToJson(createdAt),
  };

  static double _unit(double value) =>
      (value.clamp(0.0, 1.0) * _grid).roundToDouble() / _grid;

  static String? _nonBlank(String value) => value.isEmpty ? null : value;

  @override
  bool operator ==(Object other) =>
      other is NoteExcerpt &&
      other.id == id &&
      other.pageId == pageId &&
      other.rect == rect &&
      other.label == label &&
      other.note == note &&
      other.color == color &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, pageId, rect, label, note, color, createdAt);

  @override
  String toString() => 'NoteExcerpt($id, page: $pageId, label: $label)';
}
