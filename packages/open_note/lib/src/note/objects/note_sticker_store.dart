import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_store.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';
import 'package:open_note/src/note/objects/note_sticker_collection.dart';
import 'package:open_note/src/note/objects/note_sticker_item.dart';

/// The user's sticker collections.
///
/// Sources are opaque strings compared exactly; within one collection each
/// source appears once. Every method that finds nothing to change returns
/// `false`, `null` or an empty list and does not notify. After [dispose] every
/// method is a no-op.
///
/// Persisted at [storeKey] as
/// `{"v": 1, "collections": [NoteStickerCollection…]}`.
class NoteStickerStore extends ChangeNotifier {
  /// Where [load] and [save] keep the collections.
  static const String storeKey = 'stickers/collections.json';

  /// Where [load] keeps a copy of a document it could not read.
  static const String corruptStoreKey = 'stickers/collections.corrupt.json';

  static const int _version = 1;

  /// Provides the name of a collection created with a blank name.
  final NoteObjectsStrings strings;

  final NoteIdFactory _idFactory;

  List<NoteStickerCollection> _collections;
  bool _disposed = false;
  NoteStickerStore({
    List<NoteStickerCollection> collections = const [],
    NoteIdFactory? idFactory,
    this.strings = const NoteObjectsStrings(),
  }) : _idFactory = idFactory ?? generateNoteId,
       _collections = _uniqueById(collections);

  /// The collections in creation order. The list cannot be modified.
  List<NoteStickerCollection> get collections => _collections;

  /// The collection with [collectionId], or `null`.
  NoteStickerCollection? find(String collectionId) {
    final index = _indexOf(collectionId);

    return index < 0 ? null : _collections[index];
  }

  /// Adds an empty collection at the end. [name] is trimmed; a blank one takes
  /// [NoteObjectsStrings.untitledCollectionName]. After [dispose] the returned
  /// collection is not stored.
  NoteStickerCollection createCollection(String name) {
    final trimmed = name.trim();
    final collection = NoteStickerCollection(
      id: _idFactory(),
      name: trimmed.isEmpty ? strings.untitledCollectionName : trimmed,
    );
    if (!_disposed) _replaceAll([..._collections, collection]);

    return collection;
  }

  /// Renames a collection. Returns `false` for an unknown id or a blank or
  /// unchanged (after trimming) name.
  bool rename(String collectionId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    return _change(
      collectionId,
      (collection) => collection.copyWith(name: trimmed),
    );
  }

  /// Deletes a collection with its items. Returns whether it existed.
  bool delete(String collectionId) {
    final index = _indexOf(collectionId);
    if (_disposed || index < 0) return false;
    _replaceAll([..._collections]..removeAt(index));

    return true;
  }

  /// Adds a sticker to the end of a collection and returns it. When the
  /// collection already has this [source], returns that item unchanged. Returns
  /// `null` for an unknown collection or a blank source.
  NoteStickerItem? addItem(String collectionId, String source, {String? name}) {
    final collection = find(collectionId);
    if (_disposed || collection == null || source.trim().isEmpty) return null;
    final existing = collection.itemWithSource(source);
    if (existing != null) return existing;
    final item = NoteStickerItem(id: _idFactory(), source: source, name: name);
    _change(
      collectionId,
      (target) => target.copyWith(items: [...target.items, item]),
    );

    return item;
  }

  /// Adds many sources at once, in order, skipping blank ones, ones the
  /// collection already has and repeats within [sources]. Returns the added
  /// items and notifies once.
  List<NoteStickerItem> importAll(String collectionId, List<String> sources) {
    final collection = find(collectionId);
    if (_disposed || collection == null) return const [];
    final known = {for (final item in collection.items) item.source};
    final added = [
      for (final source in sources)
        if (source.trim().isNotEmpty && known.add(source))
          NoteStickerItem(id: _idFactory(), source: source),
    ];
    if (added.isEmpty) return const [];
    _change(
      collectionId,
      (target) => target.copyWith(items: [...target.items, ...added]),
    );

    return List.unmodifiable(added);
  }

  /// Removes one sticker. Returns whether it existed.
  bool removeItem(String collectionId, String itemId) => _change(
    collectionId,
    (collection) => collection.copyWith(
      items: [
        for (final item in collection.items)
          if (item.id != itemId) item,
      ],
    ),
  );

  /// Moves the sticker at [oldIndex] so that it ends up at [newIndex] (the
  /// index in the finished list, not a `ReorderableList` insertion index).
  /// [newIndex] is clamped into range; an unknown collection or [oldIndex] out
  /// of range does nothing. Returns whether the order changed.
  bool moveItem(String collectionId, int oldIndex, int newIndex) =>
      _change(collectionId, (collection) {
        final count = collection.items.length;
        if (oldIndex < 0 || oldIndex >= count) return collection;
        final items = [...collection.items];
        final item = items.removeAt(oldIndex);
        items.insert(newIndex.clamp(0, count - 1), item);

        return collection.copyWith(items: items);
      });

  /// Replaces the collections with the stored ones.
  ///
  /// With nothing stored the current collections stay. A document that cannot
  /// be read also leaves them, and its text is copied to [corruptStoreKey] so a
  /// later [save] does not destroy it. Broken entries inside a readable
  /// document are skipped.
  Future<void> load(NoteStore store) async {
    final raw = await store.readString(storeKey);
    if (_disposed || raw == null) return;
    final decoded = _decode(raw);
    if (decoded == null) {
      await store.writeString(corruptStoreKey, raw);

      return;
    }
    if (_disposed) return;
    _replaceAll(decoded);
  }

  /// Writes the collections to [store].
  Future<void> save(NoteStore store) async {
    if (_disposed) return;
    await store.writeString(
      storeKey,
      NoteJson.encode({
        'v': _version,
        'collections': [
          for (final collection in _collections) collection.toJson(),
        ],
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static List<NoteStickerCollection> _uniqueById(
    Iterable<NoteStickerCollection> collections,
  ) {
    final seen = <String>{};

    return List.unmodifiable([
      for (final collection in collections)
        if (seen.add(collection.id)) collection,
    ]);
  }

  static List<NoteStickerCollection>? _decode(String raw) {
    final json = NoteJson.decodeMap(raw);
    if (json == null || json['collections'] is! List) return null;

    return _uniqueById([
      for (final entry in NoteJson.list(json, 'collections'))
        ?NoteStickerCollection.fromJson(entry),
    ]);
  }

  int _indexOf(String collectionId) =>
      _collections.indexWhere((collection) => collection.id == collectionId);

  /// Replaces one collection with [change] of it; `false` when nothing changed.
  bool _change(
    String collectionId,
    NoteStickerCollection Function(NoteStickerCollection collection) change,
  ) {
    final index = _indexOf(collectionId);
    if (_disposed || index < 0) return false;
    final next = change(_collections[index]);
    if (next == _collections[index]) return false;
    _replaceAll([..._collections]..[index] = next);

    return true;
  }

  void _replaceAll(List<NoteStickerCollection> next) {
    if (listEquals(next, _collections)) return;
    _collections = List.unmodifiable(next);
    notifyListeners();
  }
}
