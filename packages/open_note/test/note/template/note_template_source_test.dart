import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/template/template.dart';

void main() {
  NotePaperTemplate paper(String id, String name) =>
      NotePaperTemplate.lined(id: id, name: name);

  late MemoryNoteTemplateSource source;

  setUp(() {
    source = MemoryNoteTemplateSource()
      ..add(paper('a', 'Meeting notes'), tags: const ['work', 'Minutes'])
      ..add(paper('b', 'Diary'), thumbnailSource: 'thumb:b')
      ..add(paper('c', 'Music staff'), tags: const ['school'])
      ..add(paper('d', 'Weekly plan'), tags: const ['work']);
  });

  Future<List<String>> ids({
    String? query,
    int offset = 0,
    int limit = 50,
  }) async => [
    for (final d in await source.list(
      query: query,
      offset: offset,
      limit: limit,
    ))
      d.id,
  ];

  test('lists in insertion order', () async {
    expect(await ids(), ['a', 'b', 'c', 'd']);
    expect(source.length, 4);
  });

  test('filters by name or tag, ignoring case', () async {
    expect(await ids(query: 'WORK'), ['a', 'd']);
    expect(await ids(query: 'minutes'), ['a']);
    expect(await ids(query: '  diary '), ['b']);
    expect(await ids(query: 'notes'), ['a']);
    expect(await ids(query: '   '), ['a', 'b', 'c', 'd']);
    expect(await ids(query: 'zzz'), isEmpty);
  });

  test('pages with offset and limit', () async {
    expect(await ids(offset: 1, limit: 2), ['b', 'c']);
    expect(await ids(offset: 3, limit: 10), ['d']);
    expect(await ids(offset: 9), isEmpty);
    expect(await ids(offset: -3, limit: 1), ['a']);
    expect(await ids(limit: 0), isEmpty);
    expect(await ids(limit: -2), isEmpty);
    expect(await ids(query: 'work', offset: 1), ['d']);
  });

  test('descriptors carry the preview and tags', () async {
    final descriptors = await source.list();
    expect(descriptors[1].thumbnailSource, 'thumb:b');
    expect(descriptors.first.tags, ['work', 'Minutes']);
    expect(descriptors.first.kind, NotePaperKind.lined);
  });

  test('fetch returns the template or null', () async {
    expect(await source.fetch('c'), paper('c', 'Music staff'));
    expect(await source.fetch('zzz'), isNull);
  });

  test(
    'add replaces in place, remove deletes, empty ids are ignored',
    () async {
      source
        ..add(paper('a', 'Renamed'))
        ..add(paper('', 'Nameless'));
      expect(await ids(), ['a', 'b', 'c', 'd']);
      expect((await source.fetch('a'))!.name, 'Renamed');
      expect(source.remove('b'), isTrue);
      expect(source.remove('b'), isFalse);
      expect(await ids(), ['a', 'c', 'd']);
      expect(MemoryNoteTemplateSource([paper('z', 'Z')]).length, 1);
    },
  );

  group('NoteTemplateDescriptor', () {
    final descriptor = NoteTemplateDescriptor(
      id: 'x',
      name: 'X',
      kind: NotePaperKind.dotted,
      thumbnailSource: 'thumb',
      tags: const ['one', 'two'],
    );

    test('JSON round trip', () {
      expect(NoteTemplateDescriptor.fromJson(descriptor.toJson()), descriptor);
      final bare = NoteTemplateDescriptor(
        id: 'y',
        name: 'Y',
        kind: NotePaperKind.blank,
      );
      expect(NoteTemplateDescriptor.fromJson(bare.toJson()), bare);
      expect(bare.toJson().containsKey('thumbnailSource'), isFalse);
    });

    test('fromJson is lenient', () {
      for (final bad in <Object?>[null, 3, 'x', <Object?>[]]) {
        final read = NoteTemplateDescriptor.fromJson(bad);
        expect(read.id, '');
        expect(read.kind, NotePaperKind.blank);
        expect(read.tags, isEmpty);
      }
      final odd = NoteTemplateDescriptor.fromJson({
        'id': 'q',
        'kind': 'laser',
        'tags': ['ok', 5, null, 'also'],
      });
      expect(odd.kind, NotePaperKind.blank);
      expect(odd.tags, ['ok', 'also']);
    });

    test('is immutable, copyable and comparable', () {
      final tags = ['a'];
      final kept = NoteTemplateDescriptor(
        id: 'i',
        name: 'n',
        kind: NotePaperKind.grid,
        tags: tags,
      );
      tags.add('b');
      expect(kept.tags, ['a']);
      expect(() => kept.tags.add('c'), throwsUnsupportedError);
      expect(descriptor.copyWith(), descriptor);
      expect(descriptor.copyWith().hashCode, descriptor.hashCode);
      expect(
        descriptor.copyWith(clearThumbnailSource: true).thumbnailSource,
        isNull,
      );
      expect(descriptor.copyWith(name: 'Z'), isNot(descriptor));
    });
  });
}
