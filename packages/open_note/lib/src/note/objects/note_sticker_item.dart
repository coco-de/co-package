import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// One saved sticker: a picture [source] with an optional [name].
///
/// JSON: `{"id": String, "source": String, "name": String?}`. `id` and
/// `source` are required; an entry without them is rejected.
@immutable
class NoteStickerItem {
  /// Stable identifier, unique within its collection.
  final String id;

  /// Opaque picture source, as for a sticker object.
  final String source;

  /// Display name, or `null`.
  final String? name;

  const NoteStickerItem({required this.id, required this.source, this.name});

  @override
  int get hashCode => Object.hash(id, source, name);

  /// Reads an item; `null` when [value] is not an object with a non-empty `id`
  /// and a non-blank `source`.
  static NoteStickerItem? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final id = NoteJson.string(json, 'id');
    final source = NoteJson.string(json, 'source');
    if (id.isEmpty || source.trim().isEmpty) return null;

    return NoteStickerItem(
      id: id,
      source: source,
      name: NoteJson.stringOrNull(json, 'name'),
    );
  }

  /// A copy with the given fields replaced; [clearName] removes the name.
  NoteStickerItem copyWith({
    String? id,
    String? source,
    String? name,
    bool clearName = false,
  }) => NoteStickerItem(
    id: id ?? this.id,
    source: source ?? this.source,
    name: clearName ? null : name ?? this.name,
  );

  /// The persisted form.
  JsonMap toJson() => {'id': id, 'source': source, 'name': ?name};

  @override
  bool operator ==(Object other) =>
      other is NoteStickerItem &&
      other.id == id &&
      other.source == source &&
      other.name == name;

  @override
  String toString() => 'NoteStickerItem($id, $source, $name)';
}
