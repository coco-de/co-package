import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// An open note in the tab strip.
///
/// JSON: `{noteId, title}`.
@immutable
class NoteTab {
  /// A tab for [noteId].
  const NoteTab({required this.noteId, this.title = ''});

  /// The note the tab shows; unique within a strip.
  final String noteId;

  /// Name printed on the tab.
  final String title;

  /// A copy with the given fields replaced.
  NoteTab copyWith({String? noteId, String? title}) =>
      NoteTab(noteId: noteId ?? this.noteId, title: title ?? this.title);

  /// The persisted form `{noteId, title}`.
  JsonMap toJson() => {'noteId': noteId, 'title': title};

  /// Reads [toJson]; `null` when [value] is not an object with a non-empty
  /// `noteId`.
  static NoteTab? fromJson(Object? value) {
    final map = NoteJson.asMap(value);
    if (map == null) return null;
    final noteId = NoteJson.string(map, 'noteId');
    if (noteId.isEmpty) return null;

    return NoteTab(noteId: noteId, title: NoteJson.string(map, 'title'));
  }

  @override
  bool operator ==(Object other) =>
      other is NoteTab && other.noteId == noteId && other.title == title;

  @override
  int get hashCode => Object.hash(noteId, title);

  @override
  String toString() => 'NoteTab($noteId, "$title")';
}
