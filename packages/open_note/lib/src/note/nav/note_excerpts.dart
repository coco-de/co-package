import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_order.dart';
import 'package:open_note/src/note/nav/internal/note_nav_text.dart';
import 'package:open_note/src/note/nav/note_excerpt.dart';
import 'package:open_note/src/note/nav/note_nav_notifier.dart';

/// The excerpts of one note.
///
/// Labels are compared case-insensitively with collapsed whitespace; the first
/// spelling is the one [labels] reports.
///
/// JSON: `{"v": 1, "excerpts": [NoteExcerpt JSON, …]}` in insertion order.
class NoteExcerpts extends NoteNavNotifier {
  /// Creates a controller with [excerpts]; entries without an id, a page or an
  /// area, and later entries repeating an id, are dropped. [idFactory] and
  /// [clock] are used by [add].
  NoteExcerpts({
    Iterable<NoteExcerpt> excerpts = const [],
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
  }) : _idFactory = idFactory,
       _clock = clock {
    final ids = <String>{};
    _items.addAll(
      excerpts.where((excerpt) => _isUsable(excerpt) && ids.add(excerpt.id)),
    );
  }

  /// Reads a [toJson] map; malformed input yields an empty controller and bad
  /// entries are skipped.
  factory NoteExcerpts.fromJson(
    Object? value, {
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
  }) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteExcerpts(
      excerpts: [
        for (final entry in NoteJson.list(json, 'excerpts'))
          ?NoteExcerpt.fromJson(entry),
      ],
      idFactory: idFactory,
      clock: clock,
    );
  }

  final NoteIdFactory _idFactory;
  final NoteClock _clock;
  final List<NoteExcerpt> _items = [];

  /// Every excerpt in the order it was added (unmodifiable snapshot).
  List<NoteExcerpt> get items => List.unmodifiable(_items);

  /// Number of excerpts.
  int get length => _items.length;

  /// Whether there is no excerpt.
  bool get isEmpty => _items.isEmpty;

  /// The distinct labels with the number of excerpts carrying each, sorted
  /// case-insensitively. Unlabeled excerpts are not counted.
  Map<String, int> get labels {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final excerpt in _items) {
      final label = excerpt.label;
      if (label == null) continue;
      final key = noteNavKey(label);
      names.putIfAbsent(key, () => label);
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    final keys = names.keys.toList()..sort();

    return Map.unmodifiable({
      for (final key in keys) names[key]!: counts[key]!,
    });
  }

  /// The excerpt [id], or `null`.
  NoteExcerpt? byId(String id) {
    final index = _indexOf(id);

    return index < 0 ? null : _items[index];
  }

  /// Adds an excerpt of [rect] (page fractions) on [pageId].
  ///
  /// Returns it, or `null` when the page id is empty, the rect has no area or
  /// the controller is disposed. See [NoteExcerpt] for how the values are
  /// cleaned up.
  NoteExcerpt? add({
    required String pageId,
    required Rect rect,
    String? label,
    String? note,
    Color? color,
  }) {
    if (isDisposed) return null;
    final excerpt = NoteExcerpt(
      id: _idFactory(),
      pageId: pageId,
      rect: rect,
      label: label,
      note: note,
      color: color,
      createdAt: _clock(),
    );
    if (!_isUsable(excerpt)) return null;
    _items.add(excerpt);
    notifyChanged();

    return excerpt;
  }

  /// Replaces the excerpt with the id of [excerpt]. Returns `false` when it is
  /// unknown, unchanged, or the new value has no page or area.
  bool update(NoteExcerpt excerpt) {
    final index = _indexOf(excerpt.id);
    if (isDisposed || index < 0 || !_isUsable(excerpt)) return false;
    if (_items[index] == excerpt) return false;
    _items[index] = excerpt;
    notifyChanged();

    return true;
  }

  /// Removes the excerpt [id]. Returns whether it existed.
  bool remove(String id) {
    final index = _indexOf(id);
    if (isDisposed || index < 0) return false;
    _items.removeAt(index);
    notifyChanged();

    return true;
  }

  /// Removes every excerpt of the page [pageId] (call it when a page is
  /// deleted). Returns how many were removed.
  int removePage(String pageId) {
    if (isDisposed) return 0;
    final before = _items.length;
    _items.removeWhere((excerpt) => excerpt.pageId == pageId);
    final removed = before - _items.length;
    if (removed > 0) notifyChanged();

    return removed;
  }

  /// The excerpts of [pageId], in the order they were added.
  List<NoteExcerpt> byPage(String pageId) => [
    for (final excerpt in _items)
      if (excerpt.pageId == pageId) excerpt,
  ];

  /// The excerpts labelled [label] (case-insensitive); a `null` or blank
  /// [label] gives the unlabeled ones.
  List<NoteExcerpt> byLabel(String? label) {
    final key = noteNavKey(label ?? '');

    return [
      for (final excerpt in _items)
        if (noteNavKey(excerpt.label ?? '') == key) excerpt,
    ];
  }

  /// The excerpts whose label or note contains [query] (case-insensitive plain
  /// substring, so Hangul and CJK work). A blank query returns every excerpt.
  List<NoteExcerpt> search(String query) {
    final needle = noteNavKey(query);
    if (needle.isEmpty) return items;

    return [
      for (final excerpt in _items)
        if (noteNavKey(excerpt.label ?? '').contains(needle) ||
            noteNavKey(excerpt.note ?? '').contains(needle))
          excerpt,
    ];
  }

  /// The excerpts in reading order: by page position in [pageOrder] (unknown
  /// pages last), then top to bottom, then left to right on the page.
  List<NoteExcerpt> ordered(List<String> pageOrder) =>
      noteNavSortByPage<NoteExcerpt>(
        _items,
        pageOrder,
        pageIdOf: (excerpt) => excerpt.pageId,
        then: (a, b) {
          final vertical = a.rect.top.compareTo(b.rect.top);

          return vertical != 0 ? vertical : a.rect.left.compareTo(b.rect.left);
        },
      );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'v': noteNavJsonVersion,
    'excerpts': [for (final excerpt in _items) excerpt.toJson()],
  };

  bool _isUsable(NoteExcerpt excerpt) =>
      excerpt.id.isNotEmpty && excerpt.pageId.isNotEmpty && excerpt.hasArea;

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);
}
