import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/objects/note_sticker_item.dart';

/// A named, ordered set of stickers.
///
/// JSON: `{"id": String, "name": String, "items": [NoteStickerItem…]}`. `id` is
/// required. Invalid items are skipped, and of items repeating an id or a
/// source only the first is kept. [items] must not be modified after it was
/// passed in (build a new list with [copyWith]).
@immutable
class NoteStickerCollection {
  /// Stable identifier.
  final String id;

  /// Display name.
  final String name;

  /// The stickers, in display order.
  final List<NoteStickerItem> items;

  const NoteStickerCollection({
    required this.id,
    required this.name,
    this.items = const [],
  });

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(items));

  /// Reads a collection; `null` when [value] is not an object with a non-empty
  /// `id`.
  static NoteStickerCollection? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final id = NoteJson.string(json, 'id');
    if (id.isEmpty) return null;

    return NoteStickerCollection(
      id: id,
      name: NoteJson.string(json, 'name'),
      items: _readItems(NoteJson.list(json, 'items')),
    );
  }

  /// The item showing [source], or `null`.
  NoteStickerItem? itemWithSource(String source) {
    for (final item in items) {
      if (item.source == source) return item;
    }

    return null;
  }

  /// A copy with the given fields replaced; the [id] is kept.
  NoteStickerCollection copyWith({
    String? name,
    List<NoteStickerItem>? items,
  }) => NoteStickerCollection(
    id: id,
    name: name ?? this.name,
    items: items == null ? this.items : List.unmodifiable(items),
  );

  /// The persisted form.
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'items': [for (final item in items) item.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is NoteStickerCollection &&
      other.id == id &&
      other.name == name &&
      listEquals(other.items, items);

  @override
  String toString() =>
      'NoteStickerCollection($id, $name, ${items.length} items)';

  static List<NoteStickerItem> _readItems(List<Object?> values) {
    final ids = <String>{};
    final sources = <String>{};
    final items = <NoteStickerItem>[];
    for (final value in values) {
      final item = NoteStickerItem.fromJson(value);
      if (item == null || ids.contains(item.id)) continue;
      if (!sources.add(item.source)) continue;
      ids.add(item.id);
      items.add(item);
    }

    return List.unmodifiable(items);
  }
}
