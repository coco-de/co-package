import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_order.dart';
import 'package:open_note/src/note/nav/note_bookmark.dart';
import 'package:open_note/src/note/nav/note_nav_notifier.dart';

/// The bookmarks of one note. A page has at most one bookmark.
///
/// JSON: `{"v": 1, "bookmarks": [NoteBookmark JSON, …]}` in insertion order.
class NoteBookmarks extends NoteNavNotifier {
  /// Creates a controller with [bookmarks]; later entries that repeat an id or
  /// a page of an earlier one (and entries with an empty id or page) are
  /// dropped. [idFactory] and [clock] are used by [toggle].
  NoteBookmarks({
    Iterable<NoteBookmark> bookmarks = const [],
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
  }) : _idFactory = idFactory,
       _clock = clock {
    final ids = <String>{};
    final pages = <String>{};
    for (final bookmark in bookmarks) {
      if (bookmark.id.isEmpty || bookmark.pageId.isEmpty) continue;
      if (ids.add(bookmark.id) && pages.add(bookmark.pageId)) {
        _items.add(bookmark);
      }
    }
  }

  /// Reads a [toJson] map; malformed input yields an empty controller and bad
  /// entries are skipped.
  factory NoteBookmarks.fromJson(
    Object? value, {
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
  }) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteBookmarks(
      bookmarks: [
        for (final entry in NoteJson.list(json, 'bookmarks'))
          ?NoteBookmark.fromJson(entry),
      ],
      idFactory: idFactory,
      clock: clock,
    );
  }

  final NoteIdFactory _idFactory;
  final NoteClock _clock;
  final List<NoteBookmark> _items = [];

  /// Every bookmark in the order it was added (unmodifiable snapshot).
  List<NoteBookmark> get items => List.unmodifiable(_items);

  /// Number of bookmarks.
  int get length => _items.length;

  /// Whether there is no bookmark.
  bool get isEmpty => _items.isEmpty;

  /// Whether the page [pageId] is bookmarked.
  bool isBookmarked(String pageId) => bookmarkFor(pageId) != null;

  /// The bookmark of [pageId], or `null`.
  NoteBookmark? bookmarkFor(String pageId) {
    for (final bookmark in _items) {
      if (bookmark.pageId == pageId) return bookmark;
    }

    return null;
  }

  /// The bookmark with [id], or `null`.
  NoteBookmark? byId(String id) {
    final index = _indexOf(id);

    return index < 0 ? null : _items[index];
  }

  /// Adds a bookmark to [pageId], or removes the existing one.
  ///
  /// Returns the new bookmark, or `null` when the bookmark was removed (or
  /// nothing happened: empty [pageId], or disposed). [title] is trimmed and
  /// only used when adding.
  NoteBookmark? toggle(String pageId, {String title = ''}) {
    if (isDisposed || pageId.isEmpty) return null;
    if (removePage(pageId)) return null;
    final bookmark = NoteBookmark(
      id: _idFactory(),
      pageId: pageId,
      title: title.trim(),
      createdAt: _clock(),
    );
    _items.add(bookmark);
    notifyChanged();

    return bookmark;
  }

  /// Renames the bookmark [id] to the trimmed [title] (empty is allowed).
  /// Returns whether anything changed.
  bool rename(String id, String title) {
    final index = _indexOf(id);
    final trimmed = title.trim();
    if (isDisposed || index < 0 || _items[index].title == trimmed) {
      return false;
    }
    _items[index] = _items[index].copyWith(title: trimmed);
    notifyChanged();

    return true;
  }

  /// Removes the bookmark [id]. Returns whether it existed.
  bool remove(String id) {
    final index = _indexOf(id);
    if (isDisposed || index < 0) return false;
    _items.removeAt(index);
    notifyChanged();

    return true;
  }

  /// Removes the bookmark of the page [pageId] (call it when a page is
  /// deleted). Returns whether one existed.
  bool removePage(String pageId) {
    final bookmark = bookmarkFor(pageId);

    return bookmark != null && remove(bookmark.id);
  }

  /// The bookmarks in the order of their pages in [pageOrder]; bookmarks of
  /// pages missing from [pageOrder] come last, in insertion order.
  List<NoteBookmark> ordered(List<String> pageOrder) =>
      noteNavSortByPage<NoteBookmark>(
        _items,
        pageOrder,
        pageIdOf: (bookmark) => bookmark.pageId,
      );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'v': noteNavJsonVersion,
    'bookmarks': [for (final bookmark in _items) bookmark.toJson()],
  };

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);
}
