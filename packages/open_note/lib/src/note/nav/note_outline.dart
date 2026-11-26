import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_json.dart';
import 'package:open_note/src/note/nav/internal/note_outline_tree.dart';
import 'package:open_note/src/note/nav/note_nav_notifier.dart';
import 'package:open_note/src/note/nav/note_outline_entry.dart';
import 'package:open_note/src/note/nav/note_outline_row.dart';

/// The outline (table of contents) of one note: a forest of
/// [NoteOutlineEntry].
///
/// Entry ids are unique within the outline, and no operation can create a
/// cycle: moving an entry into itself or into one of its descendants is
/// rejected.
///
/// JSON: `{"v": 1, "entries": [NoteOutlineEntry JSON, …]}` (the roots).
class NoteOutline extends NoteNavNotifier {
  /// Creates an outline with the root [entries]. Entries with an empty or
  /// repeated id are dropped with their subtrees. [idFactory] names the entries
  /// created by [add].
  NoteOutline({
    Iterable<NoteOutlineEntry> entries = const [],
    NoteIdFactory idFactory = generateNoteId,
  }) : _idFactory = idFactory,
       _roots = NoteOutlineTree.sanitize(entries, <String>{});

  /// Reads a [toJson] map; malformed input yields an empty outline and bad
  /// entries are skipped.
  factory NoteOutline.fromJson(
    Object? value, {
    NoteIdFactory idFactory = generateNoteId,
  }) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteOutline(
      entries: [
        for (final entry in NoteJson.list(json, 'entries'))
          ?NoteOutlineEntry.fromJson(entry),
      ],
      idFactory: idFactory,
    );
  }

  final NoteIdFactory _idFactory;
  List<NoteOutlineEntry> _roots;

  /// The root entries in display order (unmodifiable snapshot).
  List<NoteOutlineEntry> get entries => List.unmodifiable(_roots);

  /// Whether the outline has no entry.
  bool get isEmpty => _roots.isEmpty;

  /// The entry [id], or `null`.
  NoteOutlineEntry? find(String id) => NoteOutlineTree.find(_roots, id);

  /// The parent of the entry [id], or `null` for a root or an unknown id.
  NoteOutlineEntry? parentOf(String id) {
    final path = NoteOutlineTree.pathTo(_roots, id);

    return path == null || path.length < 2 ? null : path[path.length - 2];
  }

  /// Adds an entry titled [title] (trimmed) targeting [pageId].
  ///
  /// It goes under [parentId], or becomes a root when [parentId] is `null`, at
  /// [index] (clamped; the end when omitted). Returns the new entry, or `null`
  /// when [parentId] is unknown or the outline is disposed.
  NoteOutlineEntry? add(
    String title,
    String pageId, {
    String? parentId,
    int? index,
  }) {
    if (isDisposed || (parentId != null && find(parentId) == null)) {
      return null;
    }
    final entry = NoteOutlineEntry(
      id: _idFactory(),
      title: title.trim(),
      pageId: pageId,
    );
    _roots = NoteOutlineTree.insert(
      _roots,
      entry,
      parentId: parentId,
      index: index ?? _childrenOf(parentId).length,
    );
    notifyChanged();

    return entry;
  }

  /// Removes the entry [id] **with its subtree**. Returns whether it existed.
  bool remove(String id) {
    if (isDisposed || find(id) == null) return false;
    _roots = NoteOutlineTree.remove(_roots, id);
    notifyChanged();

    return true;
  }

  /// Sets the title of [id] to the trimmed [title]. Returns whether anything
  /// changed.
  bool rename(String id, String title) =>
      _update(id, (entry) => entry.copyWith(title: title.trim()));

  /// Points the entry [id] at the page [pageId]. Returns whether anything
  /// changed.
  bool setTarget(String id, String pageId) =>
      _update(id, (entry) => entry.copyWith(pageId: pageId));

  /// Whether [id] may be moved under [newParentId] (`null` = to the roots):
  /// both exist and [newParentId] is not [id] or one of its descendants.
  bool canMove(String id, String? newParentId) {
    final moving = find(id);
    if (moving == null) return false;
    if (newParentId == null) return true;
    if (newParentId == id) return false;
    if (NoteOutlineTree.find(moving.children, newParentId) != null) {
      return false;
    }

    return find(newParentId) != null;
  }

  /// Moves the entry [id] (with its subtree) under [newParentId], or to the
  /// roots when it is `null`.
  ///
  /// [index] is the position among the new siblings **after** the entry has been
  /// taken out of its old place; it is clamped. Returns whether anything
  /// changed: a move that [canMove] rejects (a cycle, unknown ids) or that
  /// leaves the tree as it was returns `false`.
  bool move(String id, String? newParentId, int index) {
    if (isDisposed || !canMove(id, newParentId)) return false;
    final moving = find(id)!;
    final without = NoteOutlineTree.remove(_roots, id);
    final moved = NoteOutlineTree.insert(
      without,
      moving,
      parentId: newParentId,
      index: index,
    );
    if (listEquals(moved, _roots)) return false;
    _roots = moved;
    notifyChanged();

    return true;
  }

  /// Makes [id] the last child of its previous sibling. Returns `false` for the
  /// first sibling or an unknown id.
  bool indent(String id) {
    final siblings = _childrenOf(parentOf(id)?.id);
    final position = siblings.indexWhere((entry) => entry.id == id);
    if (position <= 0) return false;
    final target = siblings[position - 1];

    return move(id, target.id, target.children.length);
  }

  /// Makes [id] the next sibling of its parent; its following siblings stay with
  /// the old parent. Returns `false` for a root or an unknown id.
  bool outdent(String id) {
    final parent = parentOf(id);
    if (parent == null) return false;
    final grandParent = parentOf(parent.id)?.id;
    final position = _childrenOf(
      grandParent,
    ).indexWhere((entry) => entry.id == parent.id);

    return move(id, grandParent, position + 1);
  }

  /// All entries depth-first (pre-order) with their depth.
  List<NoteOutlineRow> flatten() => NoteOutlineTree.flatten(_roots);

  /// The most specific entry targeting [pageId]: the deepest one, and the first
  /// in depth-first order among equally deep ones. `null` when none does.
  NoteOutlineEntry? entryForPage(String pageId) {
    NoteOutlineRow? best;
    for (final row in flatten()) {
      if (row.entry.pageId == pageId &&
          (best == null || row.depth > best.depth)) {
        best = row;
      }
    }

    return best?.entry;
  }

  /// The chain from a root down to [entryForPage] of [pageId]; empty when no
  /// entry targets the page.
  List<NoteOutlineEntry> breadcrumb(String pageId) {
    final entry = entryForPage(pageId);

    return entry == null
        ? const []
        : NoteOutlineTree.pathTo(_roots, entry.id) ?? const [];
  }

  /// Removes every entry targeting [pageId] (call it when a page is deleted).
  /// The surviving children of a removed entry move up into its place, so no
  /// other part of the outline is lost. Returns the number of removed entries.
  int removePage(String pageId) {
    if (isDisposed) return 0;
    var removed = 0;
    final pruned = NoteOutlineTree.prunePage(_roots, pageId, () => removed++);
    if (removed == 0) return 0;
    _roots = pruned;
    notifyChanged();

    return removed;
  }

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'v': noteNavJsonVersion,
    'entries': [for (final entry in _roots) entry.toJson()],
  };

  List<NoteOutlineEntry> _childrenOf(String? parentId) =>
      parentId == null ? _roots : find(parentId)?.children ?? const [];

  bool _update(
    String id,
    NoteOutlineEntry Function(NoteOutlineEntry entry) change,
  ) {
    final entry = find(id);
    if (isDisposed || entry == null) return false;
    final changed = change(entry);
    if (changed == entry) return false;
    _roots = NoteOutlineTree.replace(_roots, id, (_) => changed);
    notifyChanged();

    return true;
  }
}
