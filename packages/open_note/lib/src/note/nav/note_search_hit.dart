import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/note_search_hit_kind.dart';

/// One result of a `NoteSearchIndex.search`.
///
/// JSON: `{"noteId": String, "pageId": String, "kind": NoteSearchHitKind name,
/// "snippet": String, "matchStart": int, "matchEnd": int}`.
@immutable
class NoteSearchHit {
  /// Creates a hit.
  const NoteSearchHit({
    required this.noteId,
    required this.pageId,
    required this.kind,
    required this.snippet,
    required this.matchStart,
    required this.matchEnd,
  });

  /// The note the text belongs to.
  final String noteId;

  /// The page the text belongs to; empty when it belongs to the note as a whole.
  final String pageId;

  /// Where the text comes from.
  final NoteSearchHitKind kind;

  /// One line of the matched text around the match (whitespace collapsed, cut
  /// ends marked with `…`).
  final String snippet;

  /// First matched position in [snippet], in UTF-16 code units.
  final int matchStart;

  /// One past the last matched position in [snippet].
  final int matchEnd;

  /// The matched part of [snippet].
  String get matchedText => snippet.substring(matchStart, matchEnd);

  /// Reads a [toJson] map.
  ///
  /// Returns `null` when [value] is not a map or has no note id. An unknown kind
  /// becomes [NoteSearchHitKind.text] and the match range is clamped into the
  /// snippet.
  static NoteSearchHit? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final noteId = NoteJson.string(json, 'noteId');
    if (noteId.isEmpty) return null;
    final snippet = NoteJson.string(json, 'snippet');
    final start = NoteJson.integer(json, 'matchStart').clamp(0, snippet.length);

    return NoteSearchHit(
      noteId: noteId,
      pageId: NoteJson.string(json, 'pageId'),
      kind: NoteJson.enumByName(
        NoteSearchHitKind.values,
        json['kind'],
        NoteSearchHitKind.text,
      ),
      snippet: snippet,
      matchStart: start,
      matchEnd: NoteJson.integer(json, 'matchEnd').clamp(start, snippet.length),
    );
  }

  /// A copy with the given fields replaced.
  NoteSearchHit copyWith({
    String? noteId,
    String? pageId,
    NoteSearchHitKind? kind,
    String? snippet,
    int? matchStart,
    int? matchEnd,
  }) => NoteSearchHit(
    noteId: noteId ?? this.noteId,
    pageId: pageId ?? this.pageId,
    kind: kind ?? this.kind,
    snippet: snippet ?? this.snippet,
    matchStart: matchStart ?? this.matchStart,
    matchEnd: matchEnd ?? this.matchEnd,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'noteId': noteId,
    'pageId': pageId,
    'kind': kind.name,
    'snippet': snippet,
    'matchStart': matchStart,
    'matchEnd': matchEnd,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteSearchHit &&
      other.noteId == noteId &&
      other.pageId == pageId &&
      other.kind == kind &&
      other.snippet == snippet &&
      other.matchStart == matchStart &&
      other.matchEnd == matchEnd;

  @override
  int get hashCode =>
      Object.hash(noteId, pageId, kind, snippet, matchStart, matchEnd);

  @override
  String toString() =>
      'NoteSearchHit($noteId/$pageId, ${kind.name}, "$snippet" '
      '[$matchStart, $matchEnd])';
}
