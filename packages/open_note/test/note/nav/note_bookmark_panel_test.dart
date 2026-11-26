import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

const List<String> _order = ['p1', 'p2', 'p3'];

void main() {
  late NoteBookmarks bookmarks;
  late List<String> selected;

  setUp(() {
    bookmarks = NoteBookmarks(idFactory: countingIds('b'), clock: frozenClock)
      ..toggle('p3', title: '요약')
      ..toggle('p1');
    selected = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    bool editable = true,
    String? currentPageId = 'p2',
  }) => pumpPanel(
    tester,
    NoteBookmarkPanel(
      bookmarks: bookmarks,
      pageOrder: _order,
      onBookmarkSelected: (bookmark) => selected.add(bookmark.pageId),
      currentPageId: currentPageId,
      editable: editable,
    ),
  );

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(byKeyName(key));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('lists bookmarks in page order and reports taps', (tester) async {
    await pump(tester);

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('요약'), findsOneWidget);
    expect(find.text('Page 3'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Page 1')).dy,
      lessThan(tester.getTopLeft(find.text('요약')).dy),
    );

    await tester.tap(find.text('요약'));
    await tester.tap(find.text('Page 1'));

    expect(selected, ['p3', 'p1']);
  });

  testWidgets('the header button toggles the current page', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(find.bySemanticsLabel('Bookmark this page'), findsOneWidget);

    await tap(tester, 'note-bookmark-toggle');
    expect(bookmarks.isBookmarked('p2'), isTrue);
    expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    await tap(tester, 'note-bookmark-toggle');
    expect(bookmarks.isBookmarked('p2'), isFalse);
    semantics.dispose();
  });

  testWidgets('renames a bookmark', (tester) async {
    await pump(tester);

    await tap(tester, 'note-bookmark-rename-b1');
    final field = find.byType(EditableText);
    expect(tester.widget<EditableText>(field).controller.text, '요약');
    await tester.enterText(field, '정리');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(bookmarks.byId('b1')!.title, '정리');
    expect(find.text('정리'), findsOneWidget);
    expect(field, findsNothing);
  });

  testWidgets('a cleared title falls back to the page number', (tester) async {
    await pump(tester);
    await tap(tester, 'note-bookmark-rename-b1');

    await tester.enterText(find.byType(EditableText), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(bookmarks.byId('b1')!.title, isEmpty);
    expect(find.text('Page 3'), findsOneWidget);
    expect(find.text('요약'), findsNothing);
  });

  testWidgets('deletes a bookmark', (tester) async {
    await pump(tester);

    await tap(tester, 'note-bookmark-delete-b2');

    expect(selected, isEmpty);
    expect(bookmarks.items.single.id, 'b1');
    expect(find.text('Page 1'), findsNothing);
  });

  testWidgets('a read-only panel has no edit buttons', (tester) async {
    await pump(tester, editable: false);

    expect(byKeyName('note-bookmark-toggle'), findsNothing);
    expect(byKeyName('note-bookmark-rename-b1'), findsNothing);
    expect(byKeyName('note-bookmark-delete-b1'), findsNothing);
  });

  testWidgets('shows a message when there is no bookmark', (tester) async {
    bookmarks = NoteBookmarks();

    await pump(tester, currentPageId: null);

    expect(find.text('No bookmarks yet'), findsOneWidget);
    expect(byKeyName('note-bookmark-toggle'), findsNothing);
  });
}
