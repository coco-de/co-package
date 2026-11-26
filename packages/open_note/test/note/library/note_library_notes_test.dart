import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

NoteLibrary _library(FakeClock clock) => testLibrary(
  clock: clock,
  folders: [folder('f'), folder('g', order: 1)],
  notes: [
    summary('a', title: 'Alpha', folderId: 'f', tags: ['Work'], pageCount: 3),
    summary('b', title: 'Beta', pinned: true),
    summary('c', title: ''),
  ],
);

void main() {
  late FakeClock clock;
  late NoteLibrary library;

  setUp(() {
    clock = FakeClock()..now = day(10);
    library = _library(clock);
  });

  group('createNote', () {
    test('adds a one-page note with injected id and time', () {
      final note = library.createNote(title: '  New  ', folderId: 'g');

      expect(note.id, 'id-1');
      expect(note.title, 'New');
      expect(note.cover, NoteCover.standard);
      expect(note.folderId, 'g');
      expect(note.pageCount, 1);
      expect(note.pinned, isFalse);
      expect(note.tags, isEmpty);
      expect(note.createdAt, day(10));
      expect(note.modifiedAt, day(10));
      expect(library.notes.last, note);
    });

    test('takes a cover, ignores an unknown folder and allows no title', () {
      final note = library.createNote(
        cover: const NoteCover.builtIn('plum'),
        folderId: 'nowhere',
      );

      expect(note.title, '');
      expect(note.cover, const NoteCover.builtIn('plum'));
      expect(note.folderId, isNull);
    });

    test('exposes notes and trash as unmodifiable lists', () {
      expect(() => library.notes.clear(), throwsUnsupportedError);
      expect(() => library.trash.add(summary('x')), throwsUnsupportedError);
    });
  });

  group('renameNote and setCover', () {
    test('update the modification time', () {
      expect(library.renameNote('a', ' Gamma '), isTrue);
      expect(library.noteById('a')!.title, 'Gamma');
      expect(library.noteById('a')!.modifiedAt, day(10));
      clock.now = day(11);

      expect(library.setCover('b', const NoteCover.builtIn('sand')), isTrue);
      expect(library.noteById('b')!.modifiedAt, day(11));
    });

    test('ignore no-ops without notifying', () {
      final count = countNotifications(library);

      expect(library.renameNote('a', 'Alpha'), isFalse);
      expect(library.renameNote('a', '   '), isFalse);
      expect(library.renameNote('nope', 'x'), isFalse);
      expect(library.setCover('a', NoteCover.standard), isFalse);
      expect(library.setCover('nope', NoteCover.standard), isFalse);
      expect(count(), 0);
    });
  });

  group('moveNotes', () {
    test('moves several notes in one notification', () {
      final count = countNotifications(library);

      expect(library.moveNotes(['a', 'b', 'a', 'nope'], 'g'), 2);

      expect(library.noteById('a')!.folderId, 'g');
      expect(library.noteById('b')!.folderId, 'g');
      expect(count(), 1);
    });

    test('moves out of every folder with null, without touching dates', () {
      final before = library.noteById('a')!;

      expect(library.moveNotes(['a'], null), 1);

      expect(library.noteById('a')!.folderId, isNull);
      expect(library.noteById('a')!.modifiedAt, before.modifiedAt);
    });

    test('ignores unknown folders and unchanged notes', () {
      final count = countNotifications(library);

      expect(library.moveNotes(['a'], 'nowhere'), 0);
      expect(library.moveNotes(['a'], 'f'), 0);
      expect(count(), 0);
    });
  });

  group('duplicateNotes', () {
    test('copies with new ids, a copy suffix and no pin', () {
      Map<String, String>? reported;
      library.onNotesDuplicated = (ids) => reported = ids;

      final copies = library.duplicateNotes(['b', 'a']);

      expect(idsOf(copies), ['id-1', 'id-2']);
      expect(
        [for (final note in copies) note.title],
        ['Alpha copy', 'Beta copy'],
      );
      expect(copies.every((note) => !note.pinned), isTrue);
      final first = copies.first;
      expect(first.folderId, 'f');
      expect(first.tags, ['Work']);
      expect(first.pageCount, 3);
      expect(first.cover, library.noteById('a')!.cover);
      expect(first.createdAt, day(10));
      expect(first.modifiedAt, day(10));
      expect(reported, {'a': 'id-1', 'b': 'id-2'});
      expect(library.notes, hasLength(5));
      expect(library.noteById('b')!.pinned, isTrue);
    });

    test('names an untitled copy with the suffix and takes another', () {
      expect(library.duplicateNotes(['c']).single.title, 'copy');
      expect(
        library.duplicateNotes(['a'], suffix: '사본').single.title,
        'Alpha 사본',
      );
    });

    test('does nothing for unknown ids', () {
      var calls = 0;
      library.onNotesDuplicated = (_) => calls++;
      final count = countNotifications(library);

      expect(library.duplicateNotes(['nope']), isEmpty);
      expect(calls, 0);
      expect(count(), 0);
    });
  });

  group('trash', () {
    late List<List<String>> removed;

    setUp(() {
      removed = [];
      library.onNotesRemoved = removed.add;
    });

    test('deleting keeps the data and does not call back', () {
      expect(library.deleteNotes(['a', 'c', 'nope']), 2);

      expect(idsOf(library.notes), ['b']);
      expect(idsOf(library.trash), ['a', 'c']);
      expect(library.noteById('a'), isNull);
      expect(removed, isEmpty);
    });

    test('restoring brings notes back as they were', () {
      final original = library.noteById('a')!;
      library.deleteNotes(['a']);

      expect(library.restoreNotes(['a', 'b']), 1);

      expect(library.noteById('a'), original);
      expect(library.trash, isEmpty);
    });

    test('restoring a note of a deleted folder drops the folder', () {
      library
        ..deleteNotes(['a'])
        ..deleteFolder('f', moveNotesTo: 'g');

      expect(library.trash.single.folderId, 'g');
      library
        ..deleteFolder('g')
        ..restoreNotes(['a']);

      expect(library.noteById('a')!.folderId, isNull);
    });

    test('emptying the trash reports the removed ids', () {
      library.deleteNotes(['a', 'b']);

      expect(library.emptyTrash(), ['a', 'b']);

      expect(library.trash, isEmpty);
      expect(removed, [
        ['a', 'b'],
      ]);
    });

    test('emptying an empty trash does not call back or notify', () {
      final count = countNotifications(library);

      expect(library.emptyTrash(), isEmpty);

      expect(removed, isEmpty);
      expect(count(), 0);
    });

    test('purging removes only trashed notes', () {
      library.deleteNotes(['a', 'b']);

      expect(library.purgeNotes(['b', 'c', 'nope']), ['b']);

      expect(idsOf(library.trash), ['a']);
      expect(idsOf(library.notes), ['c']);
      expect(removed, [
        ['b'],
      ]);
      expect(library.purgeNotes(['c']), isEmpty);
      expect(removed, hasLength(1));
    });

    test('calls back after the library is updated', () {
      library
        ..deleteNotes(['a'])
        ..onNotesRemoved = (ids) => expect(library.trash, isEmpty);

      library.emptyTrash();
    });

    test('trashed notes cannot be edited', () {
      library.deleteNotes(['a']);

      expect(library.renameNote('a', 'x'), isFalse);
      expect(library.pin(['a']), 0);
      expect(library.addTag('a', 't'), isFalse);
      expect(library.touch('a'), isFalse);
      expect(library.moveNotes(['a'], 'g'), 0);
    });
  });

  group('pinning', () {
    test('pins and unpins, counting real changes', () {
      expect(library.pin(['a', 'b']), 1);
      expect(library.noteById('a')!.pinned, isTrue);
      expect(library.unpin(['a', 'b', 'c']), 2);
      expect(library.notes.any((note) => note.pinned), isFalse);
    });

    test('does not notify without a change or touch dates', () {
      final count = countNotifications(library);
      final before = library.noteById('b')!.modifiedAt;

      expect(library.pin(['b']), 0);
      expect(library.unpin(['a']), 0);

      expect(count(), 0);
      expect(library.noteById('b')!.modifiedAt, before);
    });

    test('lists pinned notes first', () {
      library.pin(['c']);

      expect(idsOf(library.visibleNotes()).take(2), contains('c'));
      expect(library.visibleNotes().take(2).every((n) => n.pinned), isTrue);
    });
  });

  group('tags', () {
    test('adds a normalised tag once', () {
      expect(library.addTag('b', '  Due   soon '), isTrue);
      expect(library.noteById('b')!.tags, ['Due soon']);
      expect(library.addTag('b', 'due soon'), isFalse);
      expect(library.addTag('b', '   '), isFalse);
      expect(library.addTag('nope', 'x'), isFalse);
    });

    test('reuses the spelling another note already uses', () {
      expect(library.addTag('b', 'WORK'), isTrue);

      expect(library.noteById('b')!.tags, ['Work']);
    });

    test('removes ignoring case', () {
      expect(library.removeTag('a', ' work '), isTrue);

      expect(library.noteById('a')!.tags, isEmpty);
      expect(library.removeTag('a', 'work'), isFalse);
      expect(library.removeTag('nope', 'work'), isFalse);
    });

    test('does not change the modification time', () {
      final before = library.noteById('b')!.modifiedAt;
      library.addTag('b', 'x');

      expect(library.noteById('b')!.modifiedAt, before);
    });
  });

  group('touch', () {
    test('sets the modification time and page count', () {
      expect(library.touch('a', pageCount: 9), isTrue);

      expect(library.noteById('a')!.modifiedAt, day(10));
      expect(library.noteById('a')!.pageCount, 9);
    });

    test('keeps the page count when not given and clamps negatives', () {
      expect(library.touch('a'), isTrue);
      expect(library.noteById('a')!.pageCount, 3);
      clock.now = day(12);
      library.touch('a', pageCount: -1);
      expect(library.noteById('a')!.pageCount, 0);
    });

    test('ignores unknown notes and an unchanged result', () {
      library.touch('a');
      final count = countNotifications(library);

      expect(library.touch('a'), isFalse);
      expect(library.touch('nope'), isFalse);
      expect(count(), 0);
    });
  });

  group('dispose', () {
    test('makes later changes fail in debug builds', () {
      library.dispose();

      // ChangeNotifier's disposed check (a StateError in recent Flutter).
      expect(() => library.createNote(title: 'late'), throwsA(isA<Error>()));
    });
  });
}
