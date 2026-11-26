import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

/// a (a1 (a1x), a2), b, c.
NoteLibrary _tree({FakeClock? clock}) => testLibrary(
  clock: clock,
  folders: [
    folder('a'),
    folder('b', order: 1),
    folder('c', order: 2),
    folder('a1', parentId: 'a'),
    folder('a2', parentId: 'a', order: 1),
    folder('a1x', parentId: 'a1'),
  ],
);

List<String> _children(NoteLibrary library, String? parentId) =>
    folderIdsOf(library.childFolders(parentId));

List<int> _orders(NoteLibrary library, String? parentId) => [
  for (final entry in library.childFolders(parentId)) entry.order,
];

void main() {
  group('createFolder', () {
    test('adds a folder after its siblings with the injected id and time', () {
      final clock = FakeClock()..now = day(7);
      final library = testLibrary(clock: clock);

      final first = library.createFolder('  School  ');
      final second = library.createFolder(
        'Work',
        iconKey: NoteFolderIcons.briefcase,
      );

      expect(first.id, 'id-1');
      expect(first.name, 'School');
      expect(first.iconKey, NoteFolderIcons.folder);
      expect(first.createdAt, day(7));
      expect(second.order, 1);
      expect(second.iconKey, NoteFolderIcons.briefcase);
      expect(_children(library, null), ['id-1', 'id-2']);
    });

    test('nests under a known parent and ignores an unknown one', () {
      final library = testLibrary();
      final parent = library.createFolder('Parent');

      final child = library.createFolder('Child', parentId: parent.id);
      final stray = library.createFolder('Stray', parentId: 'nowhere');

      expect(child.parentId, parent.id);
      expect(child.order, 0);
      expect(stray.parentId, isNull);
      expect(stray.order, 1);
      expect(folderIdsOf(library.folders), [parent.id, child.id, stray.id]);
    });

    test('notifies once and accepts a blank name', () {
      final library = testLibrary();
      final count = countNotifications(library);

      final created = library.createFolder('   ', iconKey: '');

      expect(created.name, '');
      expect(created.iconKey, NoteFolderIcons.folder);
      expect(count(), 1);
    });

    test('exposes folders in tree order as an unmodifiable list', () {
      final library = _tree();

      expect(folderIdsOf(library.folders), ['a', 'a1', 'a1x', 'a2', 'b', 'c']);
      expect(() => library.folders.clear(), throwsUnsupportedError);
    });
  });

  group('rename and icon', () {
    test('rename changes the name and notifies only on real changes', () {
      final library = _tree();
      final count = countNotifications(library);

      expect(library.renameFolder('a', '  Alpha '), isTrue);
      expect(library.folderById('a')!.name, 'Alpha');
      expect(library.renameFolder('a', 'Alpha'), isFalse);
      expect(library.renameFolder('a', '   '), isFalse);
      expect(library.renameFolder('zz', 'x'), isFalse);
      expect(count(), 1);
    });

    test('setFolderIcon changes the icon', () {
      final library = _tree();
      final count = countNotifications(library);

      expect(library.setFolderIcon('b', NoteFolderIcons.star), isTrue);
      expect(library.folderById('b')!.iconKey, 'star');
      expect(library.setFolderIcon('b', NoteFolderIcons.star), isFalse);
      expect(library.setFolderIcon('b', ''), isFalse);
      expect(library.setFolderIcon('zz', NoteFolderIcons.star), isFalse);
      expect(count(), 1);
    });
  });

  group('moveFolder', () {
    test('reparents and keeps sibling orders contiguous', () {
      final library = _tree();

      expect(library.moveFolder('a1', 'b'), isTrue);

      expect(_children(library, 'a'), ['a2']);
      expect(_orders(library, 'a'), [0]);
      expect(_children(library, 'b'), ['a1']);
      expect(_children(library, 'a1'), ['a1x']);
    });

    test('can move to the top level at an index', () {
      final library = _tree();

      expect(library.moveFolder('a1x', null, index: 1), isTrue);

      expect(_children(library, null), ['a', 'a1x', 'b', 'c']);
      expect(_orders(library, null), [0, 1, 2, 3]);
      expect(library.folderById('a1x')!.parentId, isNull);
    });

    test('appends when no index is given', () {
      final library = _tree();

      expect(library.moveFolder('b', 'a'), isTrue);

      expect(_children(library, 'a'), ['a1', 'a2', 'b']);
      expect(_children(library, null), ['a', 'c']);
      expect(_orders(library, null), [0, 1]);
    });

    test('refuses cycles, unknown ids and moves that change nothing', () {
      final library = _tree();
      final count = countNotifications(library);

      expect(library.moveFolder('a', 'a'), isFalse);
      expect(library.moveFolder('a', 'a1'), isFalse);
      expect(library.moveFolder('a', 'a1x'), isFalse);
      expect(library.moveFolder('a', 'nowhere'), isFalse);
      expect(library.moveFolder('nowhere', 'a'), isFalse);
      expect(library.moveFolder('a1', 'a'), isFalse);
      expect(library.moveFolder('b', null), isFalse);
      expect(count(), 0);
      expect(folderIdsOf(library.folders), ['a', 'a1', 'a1x', 'a2', 'b', 'c']);
    });
  });

  group('reorderFolder', () {
    test('moves a folder to the final index and clamps', () {
      final library = _tree();

      expect(library.reorderFolder('c', 0), isTrue);
      expect(_children(library, null), ['c', 'a', 'b']);
      expect(library.reorderFolder('c', 99), isTrue);
      expect(_children(library, null), ['a', 'b', 'c']);
      expect(library.reorderFolder('a', -5), isFalse);
      expect(_orders(library, null), [0, 1, 2]);
    });

    test('does nothing for the current position or an unknown id', () {
      final library = _tree();
      final count = countNotifications(library);

      expect(library.reorderFolder('b', 1), isFalse);
      expect(library.reorderFolder('nowhere', 0), isFalse);
      expect(count(), 0);
    });

    test('keeps subfolders with the moved folder', () {
      final library = _tree()..reorderFolder('a', 2);

      expect(folderIdsOf(library.folders), ['b', 'c', 'a', 'a1', 'a1x', 'a2']);
    });
  });

  group('deleteFolder', () {
    NoteLibrary withNotes() => testLibrary(
      folders: _tree().folders.toList(),
      notes: [
        summary('1', folderId: 'a'),
        summary('2', folderId: 'a1'),
        summary('3'),
      ],
      trash: [summary('4', folderId: 'a')],
    );

    test('moves subfolders up into its place', () {
      final library = withNotes();

      expect(library.deleteFolder('a'), isTrue);

      expect(_children(library, null), ['a1', 'a2', 'b', 'c']);
      expect(_orders(library, null), [0, 1, 2, 3]);
      expect(_children(library, 'a1'), ['a1x']);
      expect(library.folderById('a'), isNull);
    });

    test('moves its notes out of every folder by default', () {
      final library = withNotes()..deleteFolder('a');

      expect(library.noteById('1')!.folderId, isNull);
      expect(library.noteById('2')!.folderId, 'a1');
      expect(library.trash.single.folderId, isNull);
    });

    test('moves its notes to the requested folder', () {
      final library = withNotes()..deleteFolder('a', moveNotesTo: 'c');

      expect(library.noteById('1')!.folderId, 'c');
      expect(library.trash.single.folderId, 'c');
    });

    test('may move the notes into a surviving subfolder', () {
      final library = withNotes()..deleteFolder('a', moveNotesTo: 'a2');

      expect(library.noteById('1')!.folderId, 'a2');
    });

    test('ignores an unknown or deleted destination', () {
      final unknown = withNotes()..deleteFolder('a', moveNotesTo: 'zz');
      final itself = withNotes()..deleteFolder('a', moveNotesTo: 'a');

      expect(unknown.noteById('1')!.folderId, isNull);
      expect(itself.noteById('1')!.folderId, isNull);
    });

    test('shows the parent when the shown folder is deleted', () {
      final library = withNotes()..showFolder('a1');

      library.deleteFolder('a1');

      expect(library.viewState.folderId, 'a');
      library
        ..showFolder('b')
        ..deleteFolder('b');
      expect(library.viewState.folderId, isNull);
    });

    test('keeps the view of other folders and notifies once', () {
      final library = withNotes()..showFolder('c');
      final count = countNotifications(library);

      expect(library.deleteFolder('a'), isTrue);

      expect(library.viewState.folderId, 'c');
      expect(count(), 1);
      expect(library.deleteFolder('a'), isFalse);
      expect(count(), 1);
    });
  });

  group('noteCount', () {
    test('counts direct notes, or all of them, but never the trash', () {
      final library = testLibrary(
        folders: [
          folder('a'),
          folder('a1', parentId: 'a'),
        ],
        notes: [
          summary('1', folderId: 'a'),
          summary('2', folderId: 'a1'),
          summary('3'),
        ],
        trash: [summary('4', folderId: 'a')],
      );

      expect(library.noteCount(), 3);
      expect(library.noteCount(folderId: 'a'), 1);
      expect(library.noteCount(folderId: 'a1'), 1);
      expect(library.noteCount(folderId: 'zz'), 0);
    });
  });
}
