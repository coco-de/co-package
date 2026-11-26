import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/core/memory_note_store.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/nav/nav.dart';
import 'package:open_note/src/note/objects/objects.dart';

import 'support/document_fixtures.dart';

/// Records which keys were written. [onWrite] runs before a write, as an edit
/// made while a save is in progress would.
class _SpyStore extends MemoryNoteStore {
  final List<String> written = [];
  void Function(String key)? onWrite;

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    written.add(key);
    onWrite?.call(key);
    await super.writeBytes(key, bytes);
  }

  @override
  Future<void> writeString(String key, String value) async {
    written.add(key);
    onWrite?.call(key);
    await super.writeString(key, value);
  }
}

void main() {
  late _SpyStore store;
  late NoteDocumentRepository repository;
  late NoteDocument document;

  setUp(() {
    store = _SpyStore();
    repository = NoteDocumentRepository(
      store,
      registry: documentRegistry(),
      idFactory: counterIds('repo'),
      clock: fixedClock,
    );
    document = newDocument()..title = 'Lecture';
    final first = document.pageIds.single;
    final second = document.addPage();
    document
      ..replacePage(
        withStroke(
          second,
          const Offset(1, 2),
          const Offset(3, 4),
        ).copyWith(objects: [linkTo('pageid:$first')]),
      )
      ..bookmarks.toggle(second.id, title: 'Key')
      ..tags.add('exam', NoteTagRef(noteId: 'note', pageId: second.id))
      ..numbering = NotePageNumbering(startsAtPageId: second.id)
      ..recordings = {
        'recordings': [
          {'id': 'r', 'source': 'a.m4a', 'pageNumber': 2},
        ],
      };
  });

  tearDown(() => document.dispose());

  test('a note round-trips', () async {
    await repository.save(document);

    final loaded = (await repository.load('note'))!;
    addTearDown(loaded.document.dispose);

    expect(loaded.damagedKeys, isEmpty);
    expect(loaded.document.metadataToJson(), document.metadataToJson());
    for (final page in document.pages) {
      final copy = loaded.document.page(page.id)!;
      expect(copy.toJson(), page.toJson());
      expect(copy.layers.last.scribble, page.layers.last.scribble);
    }
    expect(await repository.noteIds(), ['note']);
    expect(await repository.exists('note'), isTrue);
  });

  test('only changed pages are rewritten', () async {
    await repository.save(document);
    store.written.clear();
    final first = document.pageIds.first;

    document.rotatePage(first);
    await repository.save(document);

    final pageWrites = store.written.where((key) => key.contains('/pages/'));
    expect(pageWrites, isNotEmpty);
    expect(pageWrites, everyElement(contains('/pages/$first/')));
    expect(store.written.last, 'notes/note/note.json');
  });

  test('purged pages and removed layers are deleted from the store', () async {
    await repository.save(document);
    final second = document.pageIds.last;

    document
      ..removePage(second)
      ..purgePage(second);
    await repository.save(document);

    final stored = await store.list('notes/note/pages/');
    expect(stored, isNotEmpty);
    expect(stored, everyElement(isNot(contains('/pages/$second/'))));
  });

  test('a removed (not purged) page is kept', () async {
    final second = document.pageIds.last;
    document.removePage(second);

    await repository.save(document);
    final loaded = (await repository.load('note'))!;
    addTearDown(loaded.document.dispose);

    expect(loaded.document.trashedPages.single.page.id, second);
    expect(loaded.document.recordingPageIds, {'r': second});
  });

  test('damaged files are reported and kept aside', () async {
    await repository.save(document);
    final layerKey = (await store.list('notes/note/pages/')).firstWhere(
      (key) => key.endsWith('.pb') && key.contains(document.pageIds.last),
    );
    await store.writeBytes(layerKey, Uint8List.fromList([0xFF, 0xFF, 0xFF]));

    final loaded = (await repository.load('note'))!;
    addTearDown(loaded.document.dispose);

    expect(loaded.damagedKeys, [layerKey]);
    expect(await store.exists('$layerKey.corrupt'), isTrue);
    await repository.save(loaded.document, everything: true);
    expect(await store.exists('$layerKey.corrupt'), isTrue);
  });

  test('a missing or broken note.json gives null', () async {
    expect(await repository.load('absent'), isNull);
    await store.writeString('notes/broken/note.json', '{not json');
    expect(await repository.load('broken'), isNull);
  });

  test('duplicate points everything at the copied pages', () async {
    await repository.save(document);

    expect(await repository.duplicate('note', 'copy'), isTrue);
    expect(await repository.duplicate('absent', 'other'), isFalse);

    final copy = (await repository.load('copy'))!.document;
    addTearDown(copy.dispose);
    final first = copy.pageIds.first;
    final second = copy.pageIds.last;
    expect(copy.pageIds.toSet(), isNot(containsAll(document.pageIds)));
    expect(copy.bookmarks.isBookmarked(second), isTrue);
    expect(
      copy.tags.refsOf('exam').single,
      NoteTagRef(noteId: 'copy', pageId: second),
    );
    expect(copy.numbering.startsAtPageId, second);
    expect(copy.recordingPageIds, {'r': second});
    expect(
      (copy.page(second)!.objects.single as NoteLinkObject).target,
      'pageid:$first',
    );
  });

  test('a page edited while it is being saved is saved again', () async {
    await repository.save(document);
    final first = document.pageIds.first;
    document.rotatePage(first);
    var edited = false;
    store.onWrite = (key) {
      if (!edited && key.contains('/pages/$first/')) {
        edited = true;
        document.rotatePage(first);
      }
    };

    await repository.save(document);
    expect(edited, isTrue);
    expect(document.dirtyPageIds, contains(first));

    store.onWrite = null;
    await repository.save(document);
    final loaded = (await repository.load('note'))!;
    addTearDown(loaded.document.dispose);
    expect(loaded.document.page(first)!.paperTurns, 2);
    expect(document.dirtyPageIds, isEmpty);
  });

  test('overlapping saves run one after another', () async {
    final order = <String>[];
    store.onWrite = order.add;

    final one = repository.save(document, everything: true);
    final two = repository.save(document, everything: true);
    await Future.wait([one, two]);

    final noteWrites = [
      for (var i = 0; i < order.length; i++)
        if (order[i] == 'notes/note/note.json') i,
    ];
    // Each save ends with note.json: the second starts after the first ends.
    expect(noteWrites, [order.length ~/ 2 - 1, order.length - 1]);
  });

  test('note ids cannot escape the notes folder', () {
    expect(NoteDocumentRepository.notePrefix('..'), 'notes/%2E%2E/');
    expect(NoteDocumentRepository.notePrefix('a/b'), 'notes/a%2Fb/');
  });
}
