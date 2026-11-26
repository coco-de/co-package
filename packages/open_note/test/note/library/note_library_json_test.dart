import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

NoteLibrary _sample() => testLibrary(
  folders: [
    folder('f', name: 'School', iconKey: NoteFolderIcons.school),
    folder('s', parentId: 'f'),
  ],
  notes: [
    summary('a', folderId: 's', tags: ['x'], pinned: true, pageCount: 4),
    summary('b'),
  ],
  trash: [summary('c', folderId: 'f')],
  viewState: const NoteLibraryViewState(
    layout: NoteLibraryLayout.list,
    drawerZoom: 1.5,
    sortField: NoteSortField.name,
    sortOrder: NoteSortOrder.ascending,
    folderId: 'f',
    tag: 'x',
  ),
);

NoteLibrary _decode(JsonMap json) =>
    NoteLibrary.fromJson(NoteJson.decodeMap(NoteJson.encode(json)));

void main() {
  group('NoteLibrary JSON', () {
    test('round-trips folders, notes, trash and view', () {
      final library = _sample();

      final copy = _decode(library.toJson());

      expect(copy.folders, library.folders);
      expect(copy.notes, library.notes);
      expect(copy.trash, library.trash);
      expect(copy.viewState, library.viewState);
      expect(copy.toJson(), library.toJson());
      expect(copy.toJson()['v'], NoteLibrary.schemaVersion);
    });

    test('does not persist the query or the selection', () {
      final library = _sample()
        ..showFolder(null)
        ..viewState = const NoteLibraryViewState(query: 'abc')
        ..selectAll();

      final copy = _decode(library.toJson());

      expect(copy.viewState.query, isNull);
      expect(copy.selection, isEmpty);
      expect(copy.selectionMode, isFalse);
    });

    test('gives an empty library for anything that is not an object', () {
      for (final value in [null, 3, 'x', <Object?>[]]) {
        final library = NoteLibrary.fromJson(value);

        expect(library.folders, isEmpty);
        expect(library.notes, isEmpty);
        expect(library.trash, isEmpty);
        expect(library.viewState, const NoteLibraryViewState());
      }
    });

    test('skips entries that cannot be read', () {
      final library = NoteLibrary.fromJson({
        'folders': [
          {'id': 'f', 'name': 'ok'},
          'junk',
          {'name': 'no id'},
        ],
        'notes': [
          {'id': 'a'},
          null,
          7,
        ],
        'trash': 'nothing',
        'view': 'wide',
      });

      expect(folderIdsOf(library.folders), ['f']);
      expect(idsOf(library.notes), ['a']);
      expect(library.trash, isEmpty);
      expect(library.viewState, const NoteLibraryViewState());
    });

    test('repairs repeated ids and broken references', () {
      final library = NoteLibrary.fromJson({
        'folders': [
          {'id': 'f', 'parentId': 'g'},
          {'id': 'g', 'parentId': 'f'},
          {'id': 'f'},
          {'id': 'o', 'parentId': 'missing'},
        ],
        'notes': [
          {'id': 'a', 'folderId': 'missing'},
          {'id': 'a', 'title': 'twin'},
          {'id': 'b', 'folderId': 'f'},
        ],
        'trash': [
          {'id': 'a'},
          {'id': 'c', 'folderId': 'missing'},
        ],
        'view': {'folderId': 'missing'},
      });

      expect(library.folders, hasLength(3));
      expect(library.folderById('o')!.parentId, isNull);
      expect(idsOf(library.notes), ['a', 'b']);
      expect(library.noteById('a')!.folderId, isNull);
      expect(library.noteById('a')!.title, '');
      expect(library.noteById('b')!.folderId, 'f');
      expect(idsOf(library.trash), ['c']);
      expect(library.trash.single.folderId, isNull);
      expect(library.viewState.folderId, isNull);
    });

    test('passes the factories and callbacks on', () {
      final removed = <List<String>>[];
      final library = NoteLibrary.fromJson(
        null,
        idFactory: sequentialIds('x'),
        clock: () => day(3),
        onNotesRemoved: removed.add,
      );

      final note = library.createNote();
      library
        ..deleteNotes([note.id])
        ..emptyTrash();

      expect(note.id, 'x-1');
      expect(note.createdAt, day(3));
      expect(removed, [
        ['x-1'],
      ]);
    });
  });

  group('view state', () {
    test('changes notify only when something differs', () {
      final library = _sample();
      final count = countNotifications(library);

      library
        ..viewState = library.viewState
        ..showFolder('f');
      expect(count(), 0);

      library.showFolder('s');
      expect(count(), 1);
    });

    test('normalises an unknown folder to all notes', () {
      final library = _sample()..showFolder('nowhere');

      expect(library.viewState.folderId, isNull);
    });

    test('visibleNotes follows the view and never shows the trash', () {
      final library = _sample()
        ..viewState = const NoteLibraryViewState(
          sortField: NoteSortField.name,
          sortOrder: NoteSortOrder.ascending,
        );

      expect(idsOf(library.visibleNotes()), ['a', 'b']);
      library.showFolder('s');
      expect(idsOf(library.visibleNotes()), ['a']);
    });
  });

  group('zoomDrawer', () {
    test('multiplies and clamps', () {
      final library = testLibrary()..zoomDrawer(1.5);

      expect(library.viewState.drawerZoom, 1.5);
      library.zoomDrawer(4);
      expect(library.viewState.drawerZoom, 2);
      library.zoomDrawer(0.1);
      expect(library.viewState.drawerZoom, 0.5);
      library.zoomDrawer(1.2);
      expect(library.viewState.drawerZoom, closeTo(0.6, 1e-9));
    });

    test('clamps even a huge factor to the maximum', () {
      final library = testLibrary()..zoomDrawer(1e308);

      expect(library.viewState.drawerZoom, 2);
    });

    test('ignores factors that make no sense', () {
      final library = testLibrary();
      final count = countNotifications(library);

      library
        ..zoomDrawer(0)
        ..zoomDrawer(-2)
        ..zoomDrawer(double.nan)
        ..zoomDrawer(double.infinity)
        ..zoomDrawer(1);

      expect(library.viewState.drawerZoom, 1);
      expect(count(), 0);
    });

    test('does not notify once a limit is reached', () {
      final library = testLibrary()..zoomDrawer(10);
      final count = countNotifications(library);

      library.zoomDrawer(2);

      expect(count(), 0);
    });
  });
}
