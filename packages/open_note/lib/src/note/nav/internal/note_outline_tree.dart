import 'package:open_note/src/note/nav/note_outline_entry.dart';
import 'package:open_note/src/note/nav/note_outline_row.dart';

/// Pure operations on an immutable outline forest. Not exported by the barrel.
///
/// Every function returns a new forest and never mutates its argument.
abstract final class NoteOutlineTree {
  /// The chain from a root to the entry [id] (inclusive), or `null`.
  static List<NoteOutlineEntry>? pathTo(
    List<NoteOutlineEntry> forest,
    String id,
  ) {
    for (final entry in forest) {
      if (entry.id == id) return [entry];
      final below = pathTo(entry.children, id);
      if (below != null) return [entry, ...below];
    }

    return null;
  }

  /// The entry [id], or `null`.
  static NoteOutlineEntry? find(List<NoteOutlineEntry> forest, String id) =>
      pathTo(forest, id)?.last;

  /// The forest with the entry [id] replaced by `update(entry)`.
  static List<NoteOutlineEntry> replace(
    List<NoteOutlineEntry> forest,
    String id,
    NoteOutlineEntry Function(NoteOutlineEntry entry) update,
  ) => [
    for (final entry in forest)
      if (entry.id == id)
        update(entry)
      else
        entry.copyWith(children: replace(entry.children, id, update)),
  ];

  /// The forest without the entry [id] and its subtree.
  static List<NoteOutlineEntry> remove(
    List<NoteOutlineEntry> forest,
    String id,
  ) => [
    for (final entry in forest)
      if (entry.id != id) entry.copyWith(children: remove(entry.children, id)),
  ];

  /// The forest with [added] inserted at [index] (clamped) among the children of
  /// [parentId], or among the roots when [parentId] is `null`.
  static List<NoteOutlineEntry> insert(
    List<NoteOutlineEntry> forest,
    NoteOutlineEntry added, {
    required String? parentId,
    required int index,
  }) {
    if (parentId == null) {
      return [...forest]..insert(index.clamp(0, forest.length), added);
    }

    return replace(
      forest,
      parentId,
      (parent) => parent.copyWith(
        children: [...parent.children]
          ..insert(index.clamp(0, parent.children.length), added),
      ),
    );
  }

  /// Depth-first (pre-order) rows of [forest].
  static List<NoteOutlineRow> flatten(List<NoteOutlineEntry> forest) {
    final rows = <NoteOutlineRow>[];
    _walk(forest, 0, null, rows);

    return rows;
  }

  /// [forest] without entries that have an empty or already seen id (their
  /// subtrees are dropped too).
  static List<NoteOutlineEntry> sanitize(
    Iterable<NoteOutlineEntry> forest,
    Set<String> seen,
  ) => [
    for (final entry in forest)
      if (entry.id.isNotEmpty && seen.add(entry.id))
        entry.copyWith(children: sanitize(entry.children, seen)),
  ];

  /// [forest] without the entries targeting [pageId]; the surviving children of
  /// a dropped entry take its place. [dropped] is called once per dropped entry.
  static List<NoteOutlineEntry> prunePage(
    List<NoteOutlineEntry> forest,
    String pageId,
    void Function() dropped,
  ) {
    final kept = <NoteOutlineEntry>[];
    for (final entry in forest) {
      final children = prunePage(entry.children, pageId, dropped);
      if (entry.pageId == pageId) {
        dropped();
        kept.addAll(children);
      } else {
        kept.add(entry.copyWith(children: children));
      }
    }

    return kept;
  }

  static void _walk(
    List<NoteOutlineEntry> forest,
    int depth,
    String? parentId,
    List<NoteOutlineRow> rows,
  ) {
    for (final entry in forest) {
      rows.add(NoteOutlineRow(entry: entry, depth: depth, parentId: parentId));
      _walk(entry.children, depth + 1, entry.id, rows);
    }
  }
}
