import 'package:open_note/src/note/library/note_folder.dart';

/// A folder with its depth in the tree (0 for a top-level folder).
typedef NoteFolderNode = ({NoteFolder folder, int depth});

/// Pure helpers over a flat list of folders linked by [NoteFolder.parentId].
///
/// They expect a well-formed list (see [sanitize]): unique ids, parents that
/// exist and no cycles.
abstract final class NoteFolderTree {
  /// Orders siblings by [NoteFolder.order], then creation time, then id.
  static int compareSiblings(NoteFolder a, NoteFolder b) {
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    final byDate = a.createdAt.compareTo(b.createdAt);

    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  /// The direct children of [parentId] (`null` for the top level), in order.
  static List<NoteFolder> childrenOf(
    Iterable<NoteFolder> folders,
    String? parentId,
  ) => [
    for (final folder in folders)
      if (folder.parentId == parentId) folder,
  ]..sort(compareSiblings);

  /// The tree in depth-first order (a folder right before its children),
  /// skipping the children of the folders in [collapsed].
  static List<NoteFolderNode> flatten(
    Iterable<NoteFolder> folders, {
    Set<String> collapsed = const {},
  }) {
    final all = folders.toList();
    final nodes = <NoteFolderNode>[];
    void visit(String? parentId, int depth) {
      for (final folder in childrenOf(all, parentId)) {
        nodes.add((folder: folder, depth: depth));
        if (!collapsed.contains(folder.id)) visit(folder.id, depth + 1);
      }
    }

    visit(null, 0);

    return nodes;
  }

  /// The ids of every folder below [id], not including [id].
  static Set<String> descendantsOf(Iterable<NoteFolder> folders, String id) {
    final all = folders.toList();
    final found = <String>{};
    final queue = [id];
    while (queue.isNotEmpty) {
      final parentId = queue.removeLast();
      for (final folder in all) {
        if (folder.parentId == parentId && found.add(folder.id)) {
          queue.add(folder.id);
        }
      }
    }

    return found..remove(id);
  }

  /// Repairs a list read from storage: later folders with a repeated id are
  /// dropped, a parent that does not exist or forms a cycle is removed, and
  /// sibling orders are renumbered from 0. The result is in [flatten] order.
  static List<NoteFolder> sanitize(Iterable<NoteFolder> folders) {
    final byId = <String, NoteFolder>{};
    for (final folder in folders) {
      byId.putIfAbsent(folder.id, () => folder);
    }
    _detachDanglingParents(byId);
    _breakCycles(byId);
    final renumbered = [
      for (final parentId in {for (final f in byId.values) f.parentId})
        ..._renumber(childrenOf(byId.values, parentId)),
    ];

    return [for (final node in flatten(renumbered)) node.folder];
  }

  static void _detachDanglingParents(Map<String, NoteFolder> byId) {
    for (final folder in byId.values.toList()) {
      final parentId = folder.parentId;
      if (parentId != null && !byId.containsKey(parentId)) {
        byId[folder.id] = folder.copyWith(parentId: () => null);
      }
    }
  }

  static void _breakCycles(Map<String, NoteFolder> byId) {
    for (final start in byId.keys.toList()) {
      final seen = <String>{};
      String? current = start;
      while (current != null) {
        if (!seen.add(current)) {
          byId[current] = byId[current]!.copyWith(parentId: () => null);
          break;
        }
        current = byId[current]!.parentId;
      }
    }
  }

  static List<NoteFolder> _renumber(List<NoteFolder> siblings) => [
    for (final (index, folder) in siblings.indexed)
      folder.order == index ? folder : folder.copyWith(order: index),
  ];
}
