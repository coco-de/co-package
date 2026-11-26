import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

NoteLibraryViewState _state({
  NoteSortField field = NoteSortField.name,
  NoteSortOrder order = NoteSortOrder.ascending,
  String? folderId,
  String? tag,
  String? query,
}) => NoteLibraryViewState(
  sortField: field,
  sortOrder: order,
  folderId: folderId,
  tag: tag,
  query: query,
);

void main() {
  group('NoteLibraryViewState', () {
    test('has the documented defaults', () {
      const state = NoteLibraryViewState();

      expect(state.layout, NoteLibraryLayout.drawer);
      expect(state.drawerZoom, 1);
      expect(state.sortField, NoteSortField.modified);
      expect(state.sortOrder, NoteSortOrder.descending);
      expect(state.folderId, isNull);
      expect(state.tag, isNull);
      expect(state.query, isNull);
    });

    test('round-trips through JSON', () {
      const state = NoteLibraryViewState(
        layout: NoteLibraryLayout.list,
        drawerZoom: 1.75,
        sortField: NoteSortField.created,
        sortOrder: NoteSortOrder.ascending,
        folderId: 'f',
        tag: 'math',
        query: '노트',
      );
      final text = NoteJson.encode(state.toJson());

      expect(NoteLibraryViewState.fromJson(NoteJson.decodeMap(text)), state);
    });

    test('is lenient and clamps the zoom', () {
      expect(NoteLibraryViewState.fromJson(null), const NoteLibraryViewState());
      expect(
        NoteLibraryViewState.fromJson({
          'layout': 'carousel',
          'sortField': 5,
          'sortOrder': 'sideways',
          'drawerZoom': 'big',
          'folderId': '',
          'tag': 4,
        }),
        const NoteLibraryViewState(),
      );
      expect(
        NoteLibraryViewState.fromJson({'drawerZoom': 9}).drawerZoom,
        NoteLibraryViewState.maxDrawerZoom,
      );
      expect(
        NoteLibraryViewState.fromJson({'drawerZoom': 0.1}).drawerZoom,
        NoteLibraryViewState.minDrawerZoom,
      );
      expect(
        NoteLibraryViewState.fromJson({'drawerZoom': double.nan}).drawerZoom,
        1,
      );
    });

    test('copyWith clamps the zoom and can remove filters', () {
      const state = NoteLibraryViewState(folderId: 'f', tag: 't', query: 'q');

      expect(state.copyWith(drawerZoom: 7).drawerZoom, 2);
      expect(state.copyWith(drawerZoom: -1).drawerZoom, 0.5);
      expect(state.copyWith(), state);
      expect(state.copyWith().hashCode, state.hashCode);
      final cleared = state.copyWith(
        folderId: () => null,
        tag: () => null,
        query: () => null,
      );

      expect(cleared, const NoteLibraryViewState());
    });

    test('clampZoom replaces non-finite values with 1', () {
      expect(NoteLibraryViewState.clampZoom(double.infinity), 1);
      expect(NoteLibraryViewState.clampZoom(double.nan), 1);
      expect(NoteLibraryViewState.clampZoom(1.4), 1.4);
    });

    test('asserts a zoom out of range', () {
      expect(
        () => NoteLibraryViewState(drawerZoom: 3),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('NoteLibraryQuery sorting', () {
    final notes = [
      summary('1', title: 'Note 10', createdAt: day(3), modifiedAt: day(4)),
      summary('2', title: 'note 2', createdAt: day(1), modifiedAt: day(9)),
      summary('3', title: '가나다', createdAt: day(2), modifiedAt: day(5)),
      summary(
        '4',
        title: 'Zeta',
        createdAt: day(5),
        modifiedAt: day(6),
        pinned: true,
      ),
      summary(
        '5',
        title: 'Alpha',
        createdAt: day(4),
        modifiedAt: day(7),
        pinned: true,
      ),
    ];

    List<String> sorted(NoteSortField field, NoteSortOrder order) => idsOf(
      NoteLibraryQuery.apply(notes, _state(field: field, order: order)),
    );

    test('lists pinned notes first in both directions', () {
      expect(sorted(NoteSortField.name, NoteSortOrder.ascending), [
        '5',
        '4',
        '2',
        '1',
        '3',
      ]);
      expect(sorted(NoteSortField.name, NoteSortOrder.descending), [
        '4',
        '5',
        '3',
        '1',
        '2',
      ]);
    });

    test('sorts by modification time', () {
      expect(sorted(NoteSortField.modified, NoteSortOrder.ascending), [
        '4',
        '5',
        '1',
        '3',
        '2',
      ]);
      expect(sorted(NoteSortField.modified, NoteSortOrder.descending), [
        '5',
        '4',
        '2',
        '3',
        '1',
      ]);
    });

    test('sorts by creation time', () {
      expect(sorted(NoteSortField.created, NoteSortOrder.ascending), [
        '5',
        '4',
        '2',
        '3',
        '1',
      ]);
      expect(sorted(NoteSortField.created, NoteSortOrder.descending), [
        '4',
        '5',
        '1',
        '3',
        '2',
      ]);
    });

    test('breaks ties by name, creation time and id', () {
      final same = [
        summary('c', title: 'Same', modifiedAt: day(2)),
        summary('b', title: 'Same', modifiedAt: day(2)),
        summary('a', title: 'Item 10', modifiedAt: day(2)),
        summary('d', title: 'Item 2', modifiedAt: day(2)),
      ];
      final state = _state(
        field: NoteSortField.modified,
        order: NoteSortOrder.descending,
      );
      const expected = ['d', 'a', 'b', 'c'];

      expect(idsOf(NoteLibraryQuery.apply(same, state)), expected);
      expect(idsOf(NoteLibraryQuery.apply(same.reversed, state)), expected);
    });
  });

  group('NoteLibraryQuery filtering', () {
    final notes = [
      summary('1', title: '수학 노트', folderId: 'f', tags: ['Exam']),
      summary('2', title: 'Physics', folderId: 'sub', tags: ['기말고사']),
      summary('3', title: 'Journal'),
    ];

    List<String> shown(NoteLibraryViewState state) =>
        idsOf(NoteLibraryQuery.apply(notes, state));

    test('shows only the notes directly in the folder', () {
      expect(shown(_state(folderId: 'f')), ['1']);
      expect(shown(_state(folderId: 'nowhere')), isEmpty);
      expect(shown(_state()), hasLength(3));
    });

    test('filters by tag ignoring case and extra spaces', () {
      expect(shown(_state(tag: 'exam')), ['1']);
      expect(shown(_state(tag: '  EXAM ')), ['1']);
      expect(shown(_state(tag: 'exa')), isEmpty);
    });

    test('searches titles and tags for substrings, Hangul included', () {
      expect(shown(_state(query: '노트')), ['1']);
      expect(shown(_state(query: '학 노')), ['1']);
      expect(shown(_state(query: '말고')), ['2']);
      expect(shown(_state(query: 'PHYS')), ['2']);
      expect(shown(_state(query: 'exa')), ['1']);
      expect(shown(_state(query: 'zzz')), isEmpty);
    });

    test('treats a blank tag as no filter', () {
      expect(shown(_state(tag: '   ')), hasLength(3));
      expect(shown(_state(tag: '')), hasLength(3));
    });

    test('treats a blank query as no filter', () {
      expect(shown(_state(query: '   ')), hasLength(3));
      expect(shown(_state(query: '  journal  ')), ['3']);
    });

    test('combines the filters', () {
      expect(shown(_state(folderId: 'f', query: '노트', tag: 'exam')), ['1']);
      expect(shown(_state(folderId: 'sub', tag: 'exam')), isEmpty);
    });
  });
}
