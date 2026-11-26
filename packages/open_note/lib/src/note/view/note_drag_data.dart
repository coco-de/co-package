import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';

/// The edge of a view on which a dragged note is dropped.
enum NoteDropSide {
  /// The left edge.
  left,

  /// The right edge.
  right,

  /// The top edge.
  top,

  /// The bottom edge.
  bottom;

  /// The split direction a drop on this side asks for: side by side
  /// ([Axis.horizontal]) for left/right, stacked for top/bottom.
  Axis get axis => switch (this) {
    left || right => Axis.horizontal,
    top || bottom => Axis.vertical,
  };

  /// Whether the new pane goes before the existing one (left or top).
  bool get isLeading => this == left || this == top;
}

/// What a `Draggable` carries so a note (from the library, a tab or a
/// thumbnail) can be dropped on a `NoteDropSplitTarget` or reordered in a
/// `NoteTabBar`.
///
/// JSON: `{noteId, pageIndex?}`.
@immutable
class NoteDragData {
  /// A payload for [noteId], optionally at [pageIndex].
  const NoteDragData({required this.noteId, this.pageIndex});

  /// The dragged note.
  final String noteId;

  /// 0-based page to open, or `null` for "wherever the host would open it".
  final int? pageIndex;

  /// A copy with the given fields replaced.
  NoteDragData copyWith({String? noteId, int? pageIndex}) => NoteDragData(
    noteId: noteId ?? this.noteId,
    pageIndex: pageIndex ?? this.pageIndex,
  );

  /// The persisted form `{noteId, pageIndex?}`.
  JsonMap toJson() => {
    'noteId': noteId,
    if (pageIndex != null) 'pageIndex': pageIndex,
  };

  /// Reads [toJson]; `null` when [value] is not an object with a non-empty
  /// `noteId`. A negative page index is dropped.
  static NoteDragData? fromJson(Object? value) {
    final map = NoteJson.asMap(value);
    if (map == null) return null;
    final noteId = NoteJson.string(map, 'noteId');
    if (noteId.isEmpty) return null;
    final page = NoteJson.integer(map, 'pageIndex', -1);

    return NoteDragData(noteId: noteId, pageIndex: page < 0 ? null : page);
  }

  @override
  bool operator ==(Object other) =>
      other is NoteDragData &&
      other.noteId == noteId &&
      other.pageIndex == pageIndex;

  @override
  int get hashCode => Object.hash(noteId, pageIndex);

  @override
  String toString() => 'NoteDragData($noteId, page: $pageIndex)';
}
