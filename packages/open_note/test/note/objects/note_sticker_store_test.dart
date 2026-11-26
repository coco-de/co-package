import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

import 'support/objects_test_support.dart';

void main() {
  late NoteStickerStore stickers;
  late int notifications;

  setUp(() {
    stickers = NoteStickerStore(idFactory: counterIds('st'));
    notifications = 0;
    stickers.addListener(() => notifications++);
  });

  List<String> sourcesOf(String collectionId) => [
    for (final item in stickers.find(collectionId)!.items) item.source,
  ];

  group('collections', () {
    test('are created in order with trimmed names', () {
      final animals = stickers.createCollection('  Animals ');
      final unnamed = stickers.createCollection('   ');

      expect(animals.name, 'Animals');
      expect(unnamed.name, 'Untitled');
      expect(stickers.collections.map((c) => c.id), ['st-1', 'st-2']);
      expect(notifications, 2);
      expect(() => stickers.collections.add(animals), throwsUnsupportedError);
    });

    test('the untitled name is translatable', () {
      final localized = NoteStickerStore(
        strings: const NoteObjectsStrings(untitledCollectionName: '제목 없음'),
      );

      expect(localized.createCollection('').name, '제목 없음');
    });

    test('rename refuses unknown ids and blank or same names', () {
      final id = stickers.createCollection('A').id;
      notifications = 0;

      expect(stickers.rename('zzz', 'B'), isFalse);
      expect(stickers.rename(id, '  '), isFalse);
      expect(stickers.rename(id, ' A '), isFalse);
      expect(notifications, 0);

      expect(stickers.rename(id, ' B '), isTrue);
      expect(stickers.find(id)!.name, 'B');
      expect(notifications, 1);
    });

    test('delete removes once', () {
      final id = stickers.createCollection('A').id;
      notifications = 0;

      expect(stickers.delete(id), isTrue);
      expect(stickers.delete(id), isFalse);
      expect(stickers.collections, isEmpty);
      expect(notifications, 1);
    });
  });

  group('items', () {
    late String set;

    setUp(() {
      set = stickers.createCollection('Set').id;
      notifications = 0;
    });

    test('addItem appends once per source', () {
      final first = stickers.addItem(set, 'a.png', name: 'A')!;
      final again = stickers.addItem(set, 'a.png', name: 'other');

      expect(again, same(first));
      expect(first.name, 'A');
      expect(sourcesOf(set), ['a.png']);
      expect(notifications, 1);
    });

    test('addItem refuses unknown collections and blank sources', () {
      expect(stickers.addItem('zzz', 'a.png'), isNull);
      expect(stickers.addItem(set, ' '), isNull);
      expect(notifications, 0);
    });

    test('importAll skips duplicates and blanks and notifies once', () {
      stickers.addItem(set, 'a.png');
      notifications = 0;

      final added = stickers.importAll(set, [
        'b.png',
        'a.png',
        '',
        'c.png',
        'b.png',
      ]);

      expect(added.map((item) => item.source), ['b.png', 'c.png']);
      expect(sourcesOf(set), ['a.png', 'b.png', 'c.png']);
      expect(notifications, 1);
      expect(stickers.importAll(set, ['a.png']), isEmpty);
      expect(stickers.importAll('zzz', ['d.png']), isEmpty);
      expect(notifications, 1);
    });

    test('the same source may live in two collections', () {
      final other = stickers.createCollection('Other').id;

      stickers
        ..addItem(set, 'a.png')
        ..addItem(other, 'a.png');

      expect(sourcesOf(set), ['a.png']);
      expect(sourcesOf(other), ['a.png']);
    });

    test('removeItem removes by id', () {
      final item = stickers.addItem(set, 'a.png')!;
      notifications = 0;

      expect(stickers.removeItem(set, 'zzz'), isFalse);
      expect(stickers.removeItem('zzz', item.id), isFalse);
      expect(notifications, 0);
      expect(stickers.removeItem(set, item.id), isTrue);
      expect(sourcesOf(set), isEmpty);
    });

    test('moveItem puts the item at the final index, clamped', () {
      stickers.importAll(set, ['a', 'b', 'c', 'd']);
      notifications = 0;

      expect(stickers.moveItem(set, 0, 2), isTrue);
      expect(sourcesOf(set), ['b', 'c', 'a', 'd']);
      expect(stickers.moveItem(set, 3, 0), isTrue);
      expect(sourcesOf(set), ['d', 'b', 'c', 'a']);
      expect(stickers.moveItem(set, 0, 99), isTrue);
      expect(sourcesOf(set), ['b', 'c', 'a', 'd']);
      expect(notifications, 3);

      expect(stickers.moveItem(set, 1, 1), isFalse);
      expect(stickers.moveItem(set, -1, 0), isFalse);
      expect(stickers.moveItem(set, 4, 0), isFalse);
      expect(stickers.moveItem('zzz', 0, 1), isFalse);
      expect(notifications, 3);
    });
  });

  group('persistence', () {
    test('saves the documented schema and loads it back', () async {
      final store = MemoryNoteStore();
      final id = stickers.createCollection('Set').id;
      stickers
        ..addItem(id, 'a.png', name: 'A')
        ..addItem(id, 'b.png');

      await stickers.save(store);

      expect(NoteStickerStore.storeKey, 'stickers/collections.json');
      expect(jsonDecode((await store.readString(NoteStickerStore.storeKey))!), {
        'v': 1,
        'collections': [
          {
            'id': 'st-1',
            'name': 'Set',
            'items': [
              {'id': 'st-2', 'source': 'a.png', 'name': 'A'},
              {'id': 'st-3', 'source': 'b.png'},
            ],
          },
        ],
      });
      final loaded = NoteStickerStore();
      var loads = 0;
      loaded.addListener(() => loads++);
      await loaded.load(store);
      expect(loaded.collections, stickers.collections);
      expect(loads, 1);
      await loaded.load(store);
      expect(loads, 1);
    });

    test('keeps the current collections when nothing is stored', () async {
      stickers.createCollection('Kept');
      notifications = 0;

      await stickers.load(MemoryNoteStore());

      expect(stickers.collections.single.name, 'Kept');
      expect(notifications, 0);
    });

    for (final (name, document) in const [
      ('not JSON', '{oops'),
      ('not an object', '[1, 2]'),
      ('without a collection list', '{"v": 1}'),
    ]) {
      test('keeps its state and backs up a document $name', () async {
        final store = MemoryNoteStore();
        await store.writeString(NoteStickerStore.storeKey, document);
        stickers.createCollection('Kept');
        notifications = 0;

        await stickers.load(store);

        expect(stickers.collections.single.name, 'Kept');
        expect(notifications, 0);
        expect(
          await store.readString(NoteStickerStore.corruptStoreKey),
          document,
        );
      });
    }

    test('skips broken entries and repeats', () async {
      final store = MemoryNoteStore();
      await store.writeString(
        NoteStickerStore.storeKey,
        jsonEncode({
          'collections': [
            null,
            7,
            {'name': 'no id'},
            {
              'id': 'c',
              'name': 12,
              'items': [
                {'id': 'i1', 'source': 'a'},
                {'id': 'i1', 'source': 'b'},
                {'id': 'i2', 'source': 'a'},
                {'id': 'i3', 'source': ''},
                {'source': 'c'},
                'junk',
                {'id': 'i4', 'source': 'd', 'name': false},
              ],
            },
            {'id': 'c', 'name': 'repeat'},
            {'id': 'd'},
          ],
        }),
      );

      await stickers.load(store);

      expect(stickers.collections.map((c) => c.id), ['c', 'd']);
      expect(stickers.find('c')!.name, '');
      expect(stickers.find('c')!.items, const [
        NoteStickerItem(id: 'i1', source: 'a'),
        NoteStickerItem(id: 'i4', source: 'd'),
      ]);
      expect(stickers.find('d')!.items, isEmpty);
    });

    test('an empty list is a valid, empty library', () async {
      final store = MemoryNoteStore();
      await store.writeString(
        NoteStickerStore.storeKey,
        '{"v": 1, "collections": []}',
      );
      stickers.createCollection('Old');

      await stickers.load(store);

      expect(stickers.collections, isEmpty);
    });
  });

  test('drops repeated collection ids given to the constructor', () {
    final loaded = NoteStickerStore(
      collections: const [
        NoteStickerCollection(id: 'a', name: 'first'),
        NoteStickerCollection(id: 'a', name: 'second'),
      ],
    );

    expect(loaded.collections.single.name, 'first');
  });

  test('every method is a harmless no-op after dispose', () async {
    final disposed = NoteStickerStore(idFactory: counterIds('z'))
      ..createCollection('A');
    disposed.dispose();
    final store = MemoryNoteStore();

    expect(disposed.createCollection('B').name, 'B');
    expect(disposed.rename('z-1', 'C'), isFalse);
    expect(disposed.delete('z-1'), isFalse);
    expect(disposed.addItem('z-1', 'x'), isNull);
    expect(disposed.importAll('z-1', ['x']), isEmpty);
    expect(disposed.removeItem('z-1', 'x'), isFalse);
    expect(disposed.moveItem('z-1', 0, 1), isFalse);
    await disposed.save(store);
    await disposed.load(store);

    expect(disposed.collections.map((c) => c.name), ['A']);
    expect(store.length, 0);
  });

  group('models', () {
    const item = NoteStickerItem(id: 'i', source: 's', name: 'n');

    test('item round trip, copyWith and equality', () {
      expect(NoteStickerItem.fromJson(item.toJson()), item);
      expect(NoteStickerItem.fromJson(item.toJson())!.hashCode, item.hashCode);
      expect(item.copyWith(clearName: true).name, isNull);
      expect(item.copyWith(source: 't').name, 'n');
      expect(item.copyWith(name: 'm'), isNot(item));
      expect(NoteStickerItem.fromJson(null), isNull);
      expect(NoteStickerItem.fromJson({'id': 'i', 'source': 5}), isNull);
    });

    test('collection round trip, lookup and immutability', () {
      const collection = NoteStickerCollection(
        id: 'c',
        name: 'n',
        items: [item],
      );
      final loaded = NoteStickerCollection.fromJson(collection.toJson())!;

      expect(loaded, collection);
      expect(loaded.hashCode, collection.hashCode);
      expect(loaded.itemWithSource('s'), item);
      expect(loaded.itemWithSource('t'), isNull);
      expect(() => loaded.items.add(item), throwsUnsupportedError);
      expect(
        () => collection.copyWith(items: [item]).items.add(item),
        throwsUnsupportedError,
      );
      expect(collection.copyWith(name: 'm'), isNot(collection));
      expect(NoteStickerCollection.fromJson('x'), isNull);
      expect(NoteStickerCollection.fromJson({'name': 'n'}), isNull);
    });
  });
}
