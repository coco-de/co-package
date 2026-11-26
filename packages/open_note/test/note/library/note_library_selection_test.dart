import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import 'library_test_support.dart';

NoteLibrary _library() => testLibrary(
  folders: [folder('f'), folder('g', order: 1)],
  notes: [
    summary('a', title: 'Apple', folderId: 'f', modifiedAt: day(1)),
    summary('b', title: 'Banana', folderId: 'g', modifiedAt: day(2)),
    summary('c', title: 'Cherry', modifiedAt: day(3)),
  ],
);

void main() {
  late NoteLibrary library;

  setUp(() => library = _library());

  test('starts with no selection', () {
    expect(library.selectionMode, isFalse);
    expect(library.selection, isEmpty);
    expect(library.selectedNotes, isEmpty);
  });

  test('toggleSelect starts selecting and toggles one note', () {
    expect(library.toggleSelect('a'), isTrue);
    expect(library.selectionMode, isTrue);
    expect(library.selection, {'a'});
    expect(library.isSelected('a'), isTrue);

    expect(library.toggleSelect('a'), isTrue);
    expect(library.selection, isEmpty);
    expect(library.selectionMode, isTrue, reason: 'stays on until ended');
  });

  test('cannot select unknown, hidden or trashed notes', () {
    final count = countNotifications(library);

    expect(library.toggleSelect('nope'), isFalse);
    expect(library.selectionMode, isFalse);
    library
      ..showFolder('f')
      ..deleteNotes(['a']);
    final before = count();

    expect(library.toggleSelect('b'), isFalse);
    expect(library.toggleSelect('a'), isFalse);
    expect(count(), before);
  });

  test('selectAll selects only what the view shows', () {
    library
      ..showFolder('g')
      ..selectAll();

    expect(library.selection, {'b'});
    expect(library.selectionMode, isTrue);
  });

  test('selectAll notifies only when it adds something', () {
    library.selectAll();
    final count = countNotifications(library);

    library.selectAll();

    expect(count(), 0);
    expect(library.selection, {'a', 'b', 'c'});
  });

  test('clearSelection deselects but keeps selecting', () {
    library.selectAll();
    final count = countNotifications(library);

    library
      ..clearSelection()
      ..clearSelection();

    expect(library.selection, isEmpty);
    expect(library.selectionMode, isTrue);
    expect(count(), 1);
  });

  test('ending selection mode clears and notifies once per change', () {
    library.selectAll();
    final count = countNotifications(library);

    library.selectionMode = false;
    library.selectionMode = false;

    expect(library.selection, isEmpty);
    expect(library.selectionMode, isFalse);
    expect(count(), 1);

    library.selectionMode = true;
    expect(count(), 2);
  });

  test('a new filter deselects hidden notes', () {
    library
      ..selectAll()
      ..viewState = library.viewState.copyWith(query: () => 'an');

    expect(library.selection, {'b'});
    library.viewState = library.viewState.copyWith(query: () => null);
    expect(library.selection, {'b'}, reason: 'nothing comes back');
  });

  test('moving notes out of the shown folder deselects them', () {
    library
      ..showFolder('f')
      ..selectAll()
      ..moveNotes(['a'], 'g');

    expect(library.selection, isEmpty);
  });

  test('deleting notes deselects them', () {
    library
      ..selectAll()
      ..deleteNotes(['a']);

    expect(library.selection, {'b', 'c'});
  });

  test('the live selection can drive bulk operations', () {
    library.selectAll();

    expect(library.deleteNotes(library.selection), 3);

    expect(library.notes, isEmpty);
    expect(library.trash, hasLength(3));
    expect(library.selection, isEmpty);
  });

  test('bulk operations on a selection snapshot keep working', () {
    library.selectAll();
    final selection = library.selection;

    library.moveNotes(selection, 'f');

    expect(selection, {'a', 'b', 'c'}, reason: 'a copy');
    expect(library.selection, {'a', 'b', 'c'});
    expect(library.notes.every((note) => note.folderId == 'f'), isTrue);
  });

  test('selectedNotes follow the display order', () {
    library
      ..selectAll()
      ..toggleSelect('b')
      ..pin(['a']);

    expect(idsOf(library.selectedNotes), ['a', 'c']);
  });

  test('selection is returned as an unmodifiable copy', () {
    library.toggleSelect('a');
    final selection = library.selection;

    expect(() => selection.add('b'), throwsUnsupportedError);
    library.toggleSelect('a');
    expect(selection, {'a'});
  });
}
