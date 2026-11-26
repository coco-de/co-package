import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/nav/internal/note_nav_text.dart';
import 'package:open_note/src/note/nav/note_nav_notifier.dart';
import 'package:open_note/src/note/nav/note_search_hit.dart';
import 'package:open_note/src/note/nav/note_search_hit_kind.dart';

/// An in-memory full-text index over the pages of notes.
///
/// Text is indexed per `(noteId, pageId, kind)`: the host feeds typed text
/// (`NotePageTextExtractor`), excerpt labels, bookmark and outline titles, tags
/// and recognised handwriting with their [NoteSearchHitKind]. Note-wide
/// entries use an empty page id.
///
/// Matching is a case-insensitive plain substring match with no word-boundary
/// assumption, so Hangul and CJK work. Whitespace runs (line breaks included)
/// count as one space on both sides. Jamo decomposed forms are not normalised.
///
/// Results are ranked exact match (the whole text) before prefix before inner
/// substring, then shorter [NoteSearchHit.snippet], then indexing order. Each
/// indexed text yields at most one hit, at its first match.
class NoteSearchIndex extends NoteNavNotifier {
  /// Creates an empty index.
  NoteSearchIndex();

  /// Characters of context kept before a match in a snippet.
  static const int snippetLead = 24;

  /// Characters of context kept after a match in a snippet.
  static const int snippetTail = 48;

  final Map<(String, String), Map<NoteSearchHitKind, List<String>>> _pages = {};

  /// Whether nothing is indexed.
  bool get isEmpty => _pages.isEmpty;

  /// Replaces the texts of [kind] indexed for the page [pageId] of [noteId];
  /// other kinds of the page are kept. Blank texts are ignored, and an empty
  /// list removes that kind. Does nothing for an empty [noteId].
  void indexPage(
    String noteId,
    String pageId,
    List<String> texts, {
    NoteSearchHitKind kind = NoteSearchHitKind.text,
  }) {
    if (isDisposed || noteId.isEmpty) return;
    final cleaned = [
      for (final text in texts.map(noteNavCollapse))
        if (text.isNotEmpty) text,
    ];
    final key = (noteId, pageId);
    final buckets = _pages[key] ?? <NoteSearchHitKind, List<String>>{};
    if (listEquals(buckets[kind] ?? const <String>[], cleaned)) return;
    if (cleaned.isEmpty) {
      buckets.remove(kind);
    } else {
      buckets[kind] = cleaned;
    }
    if (buckets.isEmpty) {
      _pages.remove(key);
    } else {
      _pages[key] = buckets;
    }
    notifyChanged();
  }

  /// Forgets everything indexed for the page [pageId] of [noteId].
  void removePage(String noteId, String pageId) {
    if (isDisposed || _pages.remove((noteId, pageId)) == null) return;
    notifyChanged();
  }

  /// Forgets everything indexed for [noteId].
  void removeNote(String noteId) {
    if (isDisposed) return;
    final before = _pages.length;
    _pages.removeWhere((key, _) => key.$1 == noteId);
    if (_pages.length != before) notifyChanged();
  }

  /// Forgets everything.
  void clear() {
    if (isDisposed || _pages.isEmpty) return;
    _pages.clear();
    notifyChanged();
  }

  /// The best [limit] matches of [query].
  ///
  /// [kinds] restricts the sources (`null` = all, empty = none) and [noteId]
  /// searches one note only. A blank query, or a [limit] below 1, gives no
  /// result.
  List<NoteSearchHit> search(
    String query, {
    int limit = 50,
    Set<NoteSearchHitKind>? kinds,
    String? noteId,
  }) {
    final needle = noteNavKey(query);
    if (needle.isEmpty || limit < 1) return const [];
    final matches = <_NoteSearchMatch>[];
    for (final page in _pages.entries) {
      if (noteId != null && page.key.$1 != noteId) continue;
      _collect(matches, page.key, page.value, needle, kinds);
    }
    mergeSort<_NoteSearchMatch>(matches, compare: _NoteSearchMatch.compare);

    return [for (final match in matches.take(limit)) match.hit];
  }

  void _collect(
    List<_NoteSearchMatch> matches,
    (String, String) page,
    Map<NoteSearchHitKind, List<String>> buckets,
    String needle,
    Set<NoteSearchHitKind>? kinds,
  ) {
    for (final kind in NoteSearchHitKind.values) {
      if (kinds != null && !kinds.contains(kind)) continue;
      for (final text in buckets[kind] ?? const <String>[]) {
        final folded = noteNavFold(text);
        final at = folded.indexOf(needle);
        if (at < 0) continue;
        matches.add(
          _NoteSearchMatch(
            rank: _rank(folded, needle, at),
            hit: _hit(page, kind, text, at, needle.length),
          ),
        );
      }
    }
  }

  /// `0` for an exact match, `1` for a prefix, `2` otherwise.
  int _rank(String folded, String needle, int at) {
    if (folded == needle) return 0;

    return at == 0 ? 1 : 2;
  }

  NoteSearchHit _hit(
    (String, String) page,
    NoteSearchHitKind kind,
    String text,
    int at,
    int length,
  ) {
    var start = math.max(0, at - snippetLead);
    var end = math.min(text.length, at + length + snippetTail);
    // Never cut between the two halves of a surrogate pair.
    if (start > 0 && _isLowSurrogate(text.codeUnitAt(start))) start--;
    if (end < text.length && _isLowSurrogate(text.codeUnitAt(end))) end++;
    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';
    final matchStart = prefix.length + at - start;

    return NoteSearchHit(
      noteId: page.$1,
      pageId: page.$2,
      kind: kind,
      snippet: '$prefix${text.substring(start, end)}$suffix',
      matchStart: matchStart,
      matchEnd: matchStart + length,
    );
  }

  bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}

class _NoteSearchMatch {
  const _NoteSearchMatch({required this.rank, required this.hit});

  final int rank;
  final NoteSearchHit hit;

  /// Ranks by match class, then by shorter snippet. Used with a stable sort, so
  /// ties keep the indexing order.
  static int compare(_NoteSearchMatch a, _NoteSearchMatch b) {
    final byRank = a.rank.compareTo(b.rank);
    if (byRank != 0) return byRank;

    return a.hit.snippet.length.compareTo(b.hit.snippet.length);
  }
}
