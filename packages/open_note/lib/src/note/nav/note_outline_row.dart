import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/nav/note_outline_entry.dart';

/// One line of a flattened outline: an [entry] with its position in the tree.
@immutable
class NoteOutlineRow {
  /// Creates a row.
  const NoteOutlineRow({
    required this.entry,
    required this.depth,
    this.parentId,
  });

  /// The entry shown on this line.
  final NoteOutlineEntry entry;

  /// Nesting level: `0` for a root entry.
  final int depth;

  /// Id of the parent entry, or `null` for a root entry.
  final String? parentId;

  @override
  bool operator ==(Object other) =>
      other is NoteOutlineRow &&
      other.entry == entry &&
      other.depth == depth &&
      other.parentId == parentId;

  @override
  int get hashCode => Object.hash(entry, depth, parentId);

  @override
  String toString() => 'NoteOutlineRow(${entry.id}, depth: $depth)';
}
