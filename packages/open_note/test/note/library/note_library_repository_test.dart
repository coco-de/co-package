import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show VoidCallback;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

/// Holds the scheduled saves until a test runs them.
class _FakeScheduler {
  final List<_Task> tasks = [];

  VoidCallback call(Duration delay, VoidCallback task) {
    final entry = _Task(delay, task);
    tasks.add(entry);

    return () => entry.cancelled = true;
  }

  Iterable<_Task> get waiting =>
      tasks.where((task) => !task.cancelled && !task.done);

  void runPending() {
    for (final task in waiting.toList()) {
      task.done = true;
      task.run();
    }
  }
}

class _Task {
  _Task(this.delay, this.run);

  final Duration delay;
  final VoidCallback run;
  bool cancelled = false;
  bool done = false;
}

/// A memory store that records and can break its writes.
class _SpyStore extends MemoryNoteStore {
  final List<String> written = [];
  bool failWrites = false;
  bool failReads = false;
  Completer<void>? gate;

  @override
  Future<Uint8List?> readBytes(String key) {
    if (failReads) throw const NoteStoreException('read failed');

    return super.readBytes(key);
  }

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    if (failWrites) throw const NoteStoreException('write failed');

    await super.writeBytes(key, bytes);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final waitFor = gate;
    if (waitFor != null) await waitFor.future;
    if (failWrites) throw const NoteStoreException('write failed');
    written.add(value);

    await super.writeString(key, value);
  }
}

void main() {
  late _SpyStore store;
  late _FakeScheduler scheduler;
  late List<Object> errors;
  late NoteLibraryRepository repository;

  setUp(() {
    store = _SpyStore();
    scheduler = _FakeScheduler();
    errors = [];
    repository = NoteLibraryRepository(
      store,
      scheduler: scheduler.call,
      onError: (error, stack) => errors.add(error),
    );
  });

  Future<NoteLibrary> boundLibrary() async {
    final library = await repository.load(
      idFactory: sequentialIds(),
      clock: () => day(2),
    );
    repository.bind(library);

    return library;
  }

  Future<String?> stored() => store.readString(NoteLibraryRepository.key);

  group('load', () {
    test('gives an empty library when nothing is stored', () async {
      final library = await repository.load();

      expect(library.notes, isEmpty);
      expect(library.folders, isEmpty);
      expect(await store.exists(NoteLibraryRepository.corruptKey), isFalse);
    });

    test('reads back what save wrote', () async {
      final original = testLibrary(
        folders: [folder('f')],
        notes: [summary('a', folderId: 'f')],
        trash: [summary('b')],
      );
      await repository.save(original);

      final loaded = await repository.load();

      expect(loaded.folders, original.folders);
      expect(loaded.notes, original.notes);
      expect(loaded.trash, original.trash);
    });

    test('passes callbacks and factories to the library', () async {
      final removed = <List<String>>[];
      final library = await repository.load(
        idFactory: sequentialIds('n'),
        clock: () => day(8),
        onNotesRemoved: removed.add,
      );

      final note = library.createNote();
      library
        ..deleteNotes([note.id])
        ..emptyTrash();

      expect(note.createdAt, day(8));
      expect(removed, [
        ['n-1'],
      ]);
    });

    for (final (description, text) in [
      ('broken JSON', '{"notes": ['),
      ('a JSON array', '[1, 2]'),
      ('a JSON string', '"library"'),
      ('an empty file', ''),
      ('binary noise', '\u0000\u0001\u0002'),
    ]) {
      test('treats $description as empty and keeps a copy', () async {
        await store.writeString(NoteLibraryRepository.key, text);

        final library = await repository.load();

        expect(library.notes, isEmpty);
        expect(await store.readString(NoteLibraryRepository.corruptKey), text);
        expect(await stored(), text, reason: 'not overwritten by loading');
      });
    }

    test('copies the exact bytes, even invalid UTF-8', () async {
      final bytes = Uint8List.fromList([0xFF, 0xFE, 0x7B, 0x00, 0x80]);
      await store.writeBytes(NoteLibraryRepository.key, bytes);

      await repository.load();

      expect(await store.readBytes(NoteLibraryRepository.corruptKey), bytes);
    });

    test('keeps a copy when some entries cannot be read', () async {
      const text = '{"v":1,"folders":[],"notes":[{"id":"a"},{"title":"lost"}]}';
      await store.writeString(NoteLibraryRepository.key, text);

      final library = await repository.load();

      expect(idsOf(library.notes), ['a']);
      expect(await store.readString(NoteLibraryRepository.corruptKey), text);
    });

    test('keeps a copy when a list is not a list', () async {
      await store.writeString(NoteLibraryRepository.key, '{"notes": 7}');

      await repository.load();

      expect(await store.exists(NoteLibraryRepository.corruptKey), isTrue);
    });

    test('needs no copy for a healthy file', () async {
      await repository.save(testLibrary(notes: [summary('a')]));

      await repository.load();

      expect(await store.exists(NoteLibraryRepository.corruptKey), isFalse);
    });

    test('does not hide a failing store', () async {
      store.failReads = true;

      await expectLater(repository.load(), throwsA(isA<NoteStoreException>()));
    });

    test('fails when the copy of a broken file cannot be written', () async {
      await store.writeString(NoteLibraryRepository.key, 'broken');
      store.failWrites = true;

      await expectLater(repository.load(), throwsA(isA<NoteStoreException>()));
    });
  });

  group('save', () {
    test('writes the given library as JSON', () async {
      final library = testLibrary(notes: [summary('a')]);

      await repository.save(library);

      expect(await stored(), NoteJson.encode(library.toJson()));
    });

    test('writes the loaded or bound library by default', () async {
      final loaded = await repository.load();
      loaded.createNote(title: 'x');

      await repository.save();

      expect(await stored(), contains('"x"'));
    });

    test('writes even when nothing changed', () async {
      await repository.load();

      await repository.save();
      await repository.save();

      expect(store.written, hasLength(2));
    });

    test('needs a library', () {
      expect(repository.save, throwsStateError);
    });

    test('keeps writes in the order they were asked for', () async {
      final library = testLibrary();
      store.gate = Completer<void>();
      final first = repository.save(library);
      library.createNote(title: 'second');
      final second = repository.save(library);
      store.gate!.complete();
      store.gate = null;

      await Future.wait([first, second]);

      expect(store.written, hasLength(2));
      expect(store.written.last, contains('second'));
      expect(await stored(), contains('second'));
    });

    test('reports its own failure and later writes still work', () async {
      final library = testLibrary();
      store.failWrites = true;
      await expectLater(
        repository.save(library),
        throwsA(isA<NoteStoreException>()),
      );
      store.failWrites = false;

      await repository.save(library);

      expect(await stored(), isNotNull);
    });
  });

  group('bind', () {
    test('does not write a library that was just loaded', () async {
      await boundLibrary();

      expect(scheduler.waiting, isEmpty);
      expect(repository.hasPendingSave, isFalse);
    });

    test('binding alone cannot overwrite what is stored', () async {
      await store.writeString(NoteLibraryRepository.key, '{"keep":true}');
      final fresh = testLibrary();

      repository.bind(fresh);

      expect(scheduler.waiting, isEmpty);
      fresh.createNote(title: 'first change');
      scheduler.runPending();
      await repository.flush();
      expect(await stored(), contains('first change'));
    });

    test('saves changes made between load and bind', () async {
      final library = await repository.load();
      library.createNote(title: 'early');

      repository.bind(library);
      scheduler.runPending();
      await repository.flush();

      expect(await stored(), contains('early'));
    });

    test('waits for the debounce before writing', () async {
      repository = NoteLibraryRepository(
        store,
        debounce: const Duration(seconds: 3),
        scheduler: scheduler.call,
      );
      final library = await boundLibrary();

      library.createNote(title: 'one');

      expect(scheduler.waiting.single.delay, const Duration(seconds: 3));
      expect(repository.hasPendingSave, isTrue);
      expect(store.written, isEmpty);
      scheduler.runPending();
      await repository.flush();
      expect(store.written, hasLength(1));
      expect(repository.hasPendingSave, isFalse);
    });

    test('coalesces a burst of changes into one write', () async {
      final library = await boundLibrary();

      library
        ..createNote(title: 'one')
        ..createNote(title: 'two')
        ..createFolder('three');

      expect(scheduler.tasks, hasLength(3));
      expect(scheduler.waiting, hasLength(1));
      scheduler.runPending();
      await repository.flush();
      expect(store.written, hasLength(1));
      expect(store.written.single, contains('three'));
    });

    test('skips changes that are not persisted', () async {
      final library = await boundLibrary()
        ..createNote(title: 'a');
      scheduler.runPending();
      await repository.flush();
      store.written.clear();

      library
        ..selectAll()
        ..viewState = library.viewState.copyWith(query: () => 'a')
        ..clearSelection();
      scheduler.runPending();
      await repository.flush();

      expect(store.written, isEmpty);
    });

    test('writes a view change', () async {
      final library = await boundLibrary()
        ..zoomDrawer(1.5);

      scheduler.runPending();
      await repository.flush();

      expect(await stored(), contains('"drawerZoom":1.5'));
      expect(library.viewState.drawerZoom, 1.5);
    });

    test('flush writes a pending change at once', () async {
      final library = await boundLibrary()
        ..createNote(title: 'now');

      await repository.flush();

      expect(await stored(), contains('now'));
      expect(scheduler.waiting, isEmpty);
      expect(repository.hasPendingSave, isFalse);
      expect(library.notes, hasLength(1));
    });

    test('flush without a pending change writes nothing', () async {
      await boundLibrary();

      await repository.flush();

      expect(store.written, isEmpty);
    });

    test('flush fails when the pending change cannot be written', () async {
      (await boundLibrary()).createNote();
      store.failWrites = true;

      await expectLater(repository.flush(), throwsA(isA<NoteStoreException>()));
    });

    test('reports a failed automatic save and retries it', () async {
      final library = await boundLibrary();
      store.failWrites = true;
      library.createNote(title: 'kept');
      scheduler.runPending();
      await pumpEventQueue();

      expect(errors.single, isA<NoteStoreException>());
      expect(await stored(), isNull);

      store.failWrites = false;
      library.zoomDrawer(1.2);
      scheduler.runPending();
      await repository.flush();

      expect(await stored(), contains('kept'));
    });

    test('unbind saves what is pending and stops watching', () async {
      final library = await boundLibrary()
        ..createNote(title: 'last');

      await repository.unbind();

      expect(await stored(), contains('last'));
      expect(repository.boundLibrary, isNull);
      store.written.clear();
      library.createNote(title: 'ignored');
      expect(scheduler.waiting, isEmpty);
      expect(store.written, isEmpty);
    });

    test('binding another library saves the previous one first', () async {
      final first = await boundLibrary()
        ..createNote(title: 'from first');
      final second = testLibrary(notes: [summary('z', title: 'second')]);

      repository.bind(second);
      await pumpEventQueue();

      expect(store.written.first, contains('from first'));
      first.createNote(title: 'not saved');
      scheduler.runPending();
      await repository.flush();
      expect(await stored(), contains('second'));
      expect(await stored(), isNot(contains('not saved')));
    });

    test('binding the same library twice listens once', () async {
      final library = await boundLibrary();

      repository.bind(library);
      library.createNote();

      expect(scheduler.tasks, hasLength(1));
    });

    test(
      'a disposed repository saves what is pending and stays still',
      () async {
        final library = await boundLibrary()
          ..createNote(title: 'final');

        await repository.dispose();
        repository.bind(library);
        library.createNote(title: 'late');

        expect(await stored(), contains('final'));
        expect(await stored(), isNot(contains('late')));
        expect(repository.boundLibrary, isNull);
        expect(scheduler.waiting, isEmpty);
      },
    );

    test('a disposed library can still be unbound', () async {
      final library = await boundLibrary()
        ..createNote(title: 'x');
      library.dispose();

      await repository.dispose();

      expect(await stored(), contains('x'));
    });

    testWidgets('uses a real timer by default', (tester) async {
      final timed = NoteLibraryRepository(
        store,
        debounce: const Duration(milliseconds: 200),
      );
      final library = await timed.load();
      timed.bind(library);
      library.createNote(title: 'timed');

      await tester.pump(const Duration(milliseconds: 100));
      expect(store.written, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(store.written, hasLength(1));
      await timed.dispose();
    });
  });
}
