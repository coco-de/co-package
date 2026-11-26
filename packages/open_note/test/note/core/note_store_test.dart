import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/file_note_store.dart';
import 'package:open_note/src/note/core/memory_note_store.dart';
import 'package:open_note/src/note/core/note_store.dart';

/// The contract every [NoteStore] must satisfy.
void _storeContract(String name, Future<NoteStore> Function() create) {
  group('$name contract', () {
    late NoteStore store;

    setUp(() async => store = await create());

    test('string and bytes round-trip, missing key is null', () async {
      expect(await store.readString('a.json'), isNull);
      expect(await store.exists('a.json'), isFalse);

      await store.writeString('a.json', '{"한글":1}');
      expect(await store.readString('a.json'), '{"한글":1}');
      expect(await store.exists('a.json'), isTrue);

      await store.writeBytes('b.bin', Uint8List.fromList([0, 1, 255]));
      expect(await store.readBytes('b.bin'), [0, 1, 255]);
    });

    test('writes replace and nested keys work', () async {
      await store.writeString('notes/n1/note.json', 'one');
      await store.writeString('notes/n1/note.json', 'two');

      expect(await store.readString('notes/n1/note.json'), 'two');
    });

    test('list returns sorted keys under a prefix', () async {
      await store.writeString('notes/b/note.json', '1');
      await store.writeString('notes/a/note.json', '1');
      await store.writeString('notes/a/pages/p1.json', '1');
      await store.writeString('library.json', '1');

      expect(await store.list('notes/'), [
        'notes/a/note.json',
        'notes/a/pages/p1.json',
        'notes/b/note.json',
      ]);
      expect(await store.list(''), hasLength(4));
      expect(await store.list('nothing/'), isEmpty);
    });

    test('delete and deletePrefix', () async {
      await store.writeString('notes/a/note.json', '1');
      await store.writeString('notes/a/pages/p1.json', '1');
      await store.writeString('notes/b/note.json', '1');

      await store.delete('notes/b/note.json');
      await store.delete('never-existed.json');
      expect(await store.exists('notes/b/note.json'), isFalse);

      await store.deletePrefix('notes/a/');
      expect(await store.list('notes/'), isEmpty);
    });

    test('rejects keys that could escape the root', () async {
      for (final key in [
        '',
        '/abs',
        '../x',
        'a/../b',
        'a//b',
        r'a\b',
        'a/./b',
      ]) {
        expect(
          () => store.writeString(key, 'x'),
          throwsA(isA<NoteStoreException>()),
          reason: 'key "$key"',
        );
      }
    });
  });
}

void main() {
  _storeContract('MemoryNoteStore', () async => MemoryNoteStore());

  late Directory temp;
  _storeContract('FileNoteStore', () async {
    temp = Directory.systemTemp.createTempSync('note_store_test');
    addTearDown(() => temp.deleteSync(recursive: true));

    return FileNoteStore(temp);
  });

  test('FileNoteStore leaves no .tmp file behind', () async {
    final dir = Directory.systemTemp.createTempSync('note_store_tmp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = FileNoteStore(dir);

    await store.writeString('x/y.json', 'hello');

    expect(await store.list(''), ['x/y.json']);
    expect(
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp')),
      isEmpty,
    );
  });
}
