import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// One entry of the toolbar: an id (see `NoteToolbarItemIds`) and whether it
/// is shown.
///
/// JSON: `{"id": String, "visible": bool}`.
@immutable
class NoteToolbarItem {
  /// What the item is.
  final String id;

  /// Whether the item is shown.
  final bool visible;

  /// Creates an item.
  const NoteToolbarItem({required this.id, this.visible = true});

  /// Reads the JSON form; never throws. A missing id reads as `''` (a layout
  /// skips such an item) and a missing `visible` as `true`.
  factory NoteToolbarItem.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteToolbarItem(
      id: NoteJson.string(map, 'id'),
      visible: NoteJson.boolean(map, 'visible', true),
    );
  }

  @override
  int get hashCode => Object.hash(id, visible);

  /// A copy with the given values replaced.
  NoteToolbarItem copyWith({String? id, bool? visible}) =>
      NoteToolbarItem(id: id ?? this.id, visible: visible ?? this.visible);

  /// The JSON form described on the class.
  JsonMap toJson() => {'id': id, 'visible': visible};

  @override
  bool operator ==(Object other) =>
      other is NoteToolbarItem && other.id == id && other.visible == visible;

  @override
  String toString() => 'NoteToolbarItem($id, visible: $visible)';
}
