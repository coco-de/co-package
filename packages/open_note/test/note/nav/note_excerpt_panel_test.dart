import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

const Rect _rect = Rect.fromLTRB(0.1, 0.1, 0.5, 0.3);

void main() {
  late NoteExcerpts excerpts;
  late List<String> selected;

  setUp(() {
    excerpts = NoteExcerpts(idFactory: countingIds('x'), clock: frozenClock)
      ..add(pageId: 'p2', rect: _rect, label: 'Math', note: '미분 정의')
      ..add(pageId: 'p1', rect: _rect, label: 'Physics')
      ..add(pageId: 'p1', rect: _rect, note: '적분 노트')
      ..add(pageId: 'p3', rect: _rect, label: 'math', note: '급수');
    selected = [];
  });

  Future<void> pump(WidgetTester tester, {bool editable = true}) => pumpPanel(
    tester,
    NoteExcerptPanel(
      excerpts: excerpts,
      pageOrder: const ['p1', 'p2', 'p3'],
      onExcerptSelected: (excerpt) => selected.add(excerpt.id),
      editable: editable,
    ),
  );

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(byKeyName(key));
    await tester.tap(byKeyName(key));
    await tester.pump();
  }

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  Finder row(String id) => byKeyName('note-excerpt-row-$id');

  testWidgets('groups by label in label order, unlabeled last', (tester) async {
    await pump(tester);

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Unlabeled'), findsOneWidget);
    expect(
      top(tester, find.text('Math')),
      lessThan(top(tester, find.text('Physics'))),
    );
    expect(
      top(tester, find.text('Physics')),
      lessThan(top(tester, find.text('Unlabeled'))),
    );
    // In page order inside a group.
    expect(top(tester, row('x1')), lessThan(top(tester, row('x4'))));
    expect(find.text('Math (2)'), findsOneWidget);
    expect(find.text('Physics (1)'), findsOneWidget);
    expect(find.text('Unlabeled (1)'), findsOneWidget);
  });

  testWidgets('shows the note, or the page number without one', (tester) async {
    await pump(tester);

    expect(find.text('미분 정의'), findsOneWidget);
    expect(
      find.descendant(of: row('x2'), matching: find.text('Page 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('x1'), matching: find.text('Page 2')),
      findsOneWidget,
    );
  });

  testWidgets('reports the tapped excerpt', (tester) async {
    await pump(tester);

    await tester.tap(find.text('미분 정의'));

    expect(selected, ['x1']);
  });

  testWidgets('searches notes with Hangul substrings', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(EditableText), '적분');
    await tester.pump();

    expect(row('x3'), findsOneWidget);
    expect(row('x1'), findsNothing);
    expect(row('x2'), findsNothing);
    expect(find.text('Math'), findsNothing);

    await tester.enterText(find.byType(EditableText), '없는 말');
    await tester.pump();
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('searches labels too', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(EditableText), 'phys');
    await tester.pump();

    expect(row('x2'), findsOneWidget);
    expect(row('x1'), findsNothing);
  });

  testWidgets('a chip filters by label and a second tap clears it', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, 'note-excerpt-chip-math');
    expect(row('x1'), findsOneWidget);
    expect(row('x4'), findsOneWidget);
    expect(row('x2'), findsNothing);
    expect(row('x3'), findsNothing);

    await tap(tester, 'note-excerpt-chip-math');
    expect(row('x2'), findsOneWidget);
    expect(row('x3'), findsOneWidget);
  });

  testWidgets('the unlabeled and all chips', (tester) async {
    await pump(tester);

    await tap(tester, 'note-excerpt-chip-');
    expect(row('x3'), findsOneWidget);
    expect(row('x1'), findsNothing);

    await tap(tester, 'note-excerpt-chips-all');
    expect(row('x1'), findsOneWidget);
    expect(row('x2'), findsOneWidget);
  });

  testWidgets('deleting the last excerpt of the filtered label shows all', (
    tester,
  ) async {
    await pump(tester);
    await tap(tester, 'note-excerpt-chip-physics');

    await tap(tester, 'note-excerpt-delete-x2');

    expect(selected, isEmpty);
    expect(excerpts.byId('x2'), isNull);
    expect(row('x1'), findsOneWidget);
    expect(row('x3'), findsOneWidget);
    expect(byKeyName('note-excerpt-chip-physics'), findsNothing);
  });

  testWidgets('a read-only panel cannot delete', (tester) async {
    await pump(tester, editable: false);

    expect(byKeyName('note-excerpt-delete-x1'), findsNothing);
  });

  testWidgets('any label text gives its own chip', (tester) async {
    excerpts
      ..add(pageId: 'p1', rect: _rect, label: '*')
      ..add(pageId: 'p1', rect: _rect, label: 'all');

    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('* (1)'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('hides the chips while nothing is labelled', (tester) async {
    excerpts = NoteExcerpts(idFactory: countingIds('x'), clock: frozenClock)
      ..add(pageId: 'p1', rect: _rect);

    await pump(tester);

    expect(byKeyName('note-excerpt-chips-all'), findsNothing);
    expect(row('x1'), findsOneWidget);
  });

  testWidgets('shows a message without excerpts and follows changes', (
    tester,
  ) async {
    excerpts = NoteExcerpts(idFactory: countingIds('x'), clock: frozenClock);
    await pump(tester);
    expect(find.text('No excerpts yet'), findsOneWidget);

    excerpts.add(pageId: 'p1', rect: _rect, note: 'new one');
    await tester.pump();

    expect(find.text('new one'), findsOneWidget);
  });
}
