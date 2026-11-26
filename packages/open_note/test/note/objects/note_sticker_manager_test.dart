import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/objects/objects.dart';

import '../support/note_test_host.dart';
import 'support/objects_test_support.dart';

/// A 1 × 1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late NoteStickerStore store;
  late List<NoteStickerItem> picked;

  setUp(() {
    store = NoteStickerStore(idFactory: counterIds('st'));
    picked = [];
  });

  tearDown(() => store.dispose());

  Future<void> pump(
    WidgetTester tester, {
    Future<List<String>> Function()? onPickPictures,
  }) async {
    await tester.pumpWidget(
      noteTestHost(
        NoteStickerManager(
          store: store,
          imageProviderResolver: (_) => MemoryImage(_png),
          onSelected: picked.add,
          onPickPictures: onPickPictures,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder key(String name) => find.byKey(ValueKey('note-sticker-$name'));

  Future<void> tap(WidgetTester tester, String name) async {
    await tester.tap(key(name));
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.byType(EditableText);

  Future<void> submitName(WidgetTester tester, String name) async {
    await tester.enterText(nameField(), name);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  List<String> sources(String id) => [
    for (final item in store.find(id)!.items) item.source,
  ];

  testWidgets('filters by collection and reports a tapped sticker', (
    tester,
  ) async {
    final cats = store.createCollection('Cats');
    final dogs = store.createCollection('Dogs');
    final cat = store.addItem(cats.id, 'cat.png')!;
    final dog = store.addItem(dogs.id, 'dog.png')!;
    await pump(tester);

    expect(key(cat.id), findsOneWidget);
    expect(key(dog.id), findsOneWidget);
    await tap(tester, 'collection-${dogs.id}');
    expect(key(cat.id), findsNothing);

    await tap(tester, dog.id);
    expect(picked, [dog]);
    await tap(tester, 'all');
    expect(key(cat.id), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('makes, names and fills a collection', (tester) async {
    await pump(tester, onPickPictures: () async => ['a.png', 'b.png', 'a.png']);
    expect(find.text('No stickers yet'), findsOneWidget);

    await tap(tester, 'manage');
    await tap(tester, 'new-collection');
    final id = store.collections.single.id;
    await submitName(tester, 'Travel');
    expect(store.find(id)!.name, 'Travel');

    // 빈 이름은 받지 않고 입력 칸도 돌려놓는다.
    await submitName(tester, '   ');
    expect(store.find(id)!.name, 'Travel');
    expect(tester.widget<EditableText>(nameField()).controller.text, 'Travel');

    await tap(tester, 'add-pictures');
    expect(sources(id), ['a.png', 'b.png']);
    expect(picked, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reorders and removes stickers while editing', (tester) async {
    final collection = store.createCollection('Shapes');
    final items = store.importAll(collection.id, ['1.png', '2.png', '3.png']);
    await pump(tester);
    await tap(tester, 'manage');
    expect(key('move-earlier'), findsNothing);

    await tap(tester, items[2].id);
    await tap(tester, 'move-earlier');
    expect(sources(collection.id), ['1.png', '3.png', '2.png']);
    await tap(tester, 'move-earlier');
    await tap(tester, 'move-later');
    expect(sources(collection.id), ['1.png', '3.png', '2.png']);

    await tap(tester, 'remove');
    expect(sources(collection.id), ['1.png', '2.png']);
    // 편집 중에 누른 스티커는 쓰이지 않는다.
    expect(picked, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletes a collection after a second tap', (tester) async {
    final keep = store.createCollection('Keep');
    final drop = store.createCollection('Drop');
    await pump(tester);
    await tap(tester, 'manage');
    await tap(tester, 'collection-${drop.id}');

    await tap(tester, 'delete-collection');
    expect(store.collections, hasLength(2));
    expect(find.text('Tap again to delete'), findsOneWidget);
    // 다른 것을 누르면 확인은 풀린다.
    await tap(tester, 'collection-${keep.id}');
    expect(find.text('Delete collection'), findsOneWidget);

    await tap(tester, 'collection-${drop.id}');
    await tap(tester, 'delete-collection');
    await tap(tester, 'delete-collection');

    expect(store.collections.map((c) => c.id), [keep.id]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing picture picker is reported, not thrown', (
    tester,
  ) async {
    final collection = store.createCollection('Broken');
    await pump(tester, onPickPictures: () async => throw StateError('denied'));
    await tap(tester, 'manage');

    await tap(tester, 'add-pictures');

    expect(tester.takeException(), isStateError);
    expect(sources(collection.id), isEmpty);
    // 다시 누를 수 있다.
    await tap(tester, 'add-pictures');
    expect(tester.takeException(), isStateError);
  });
}
