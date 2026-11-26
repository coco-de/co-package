import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

void main() {
  late NoteSearchIndex index;
  late List<NoteSearchHit> tapped;

  setUp(() {
    index = NoteSearchIndex()
      ..indexPage('n1', 'p1', ['미분 적분 노트'])
      ..indexPage('n1', 'p2', ['적분의 응용'], kind: NoteSearchHitKind.outline)
      ..indexPage('n2', 'p1', ['영어 단어']);
    tapped = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    String? noteId,
    bool showKindFilters = true,
  }) => pumpPanel(
    tester,
    NoteSearchPanel(
      index: index,
      onHitSelected: tapped.add,
      noteId: noteId,
      showKindFilters: showKindFilters,
      describeHit: (hit) => '${hit.noteId}/${hit.pageId}',
    ),
  );

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(EditableText), query);
    await tester.pump();
  }

  Finder result(int position) => byKeyName('note-search-hit-$position');

  TextSpan snippetSpan(WidgetTester tester, int position) =>
      tester
              .widgetList<Text>(
                find.descendant(
                  of: result(position),
                  matching: find.byType(Text),
                ),
              )
              .first
              .textSpan!
          as TextSpan;

  testWidgets('tapping the search field focuses it', (tester) async {
    await pump(tester);
    final field = find.byType(EditableText);

    await tester.tap(field);
    await tester.pump();

    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
  });

  testWidgets('asks to type before showing anything', (tester) async {
    await pump(tester);

    expect(find.text('Type to search'), findsOneWidget);
    expect(result(0), findsNothing);
  });

  testWidgets('lists ranked results with the match highlighted', (
    tester,
  ) async {
    await pump(tester);

    await type(tester, '적분');

    expect(result(0), findsOneWidget);
    expect(result(1), findsOneWidget);
    expect(result(2), findsNothing);
    expect(snippetSpan(tester, 0).toPlainText(), '적분의 응용');
    expect(snippetSpan(tester, 1).toPlainText(), '미분 적분 노트');
    final match = snippetSpan(tester, 1).children![1] as TextSpan;
    expect(match.text, '적분');
    expect(match.style!.backgroundColor, const NoteNavStyle().highlightColor);
    expect(find.text('Outline · n1/p2'), findsOneWidget);
    expect(find.text('Text · n1/p1'), findsOneWidget);
  });

  testWidgets('reports the tapped result', (tester) async {
    await pump(tester);
    await type(tester, '적분');

    await tester.tap(result(0));

    expect(tapped.single.pageId, 'p2');
    expect(tapped.single.kind, NoteSearchHitKind.outline);
  });

  testWidgets('filters by source with the chips', (tester) async {
    await pump(tester);
    await type(tester, '적분');

    await tester.tap(byKeyName('note-search-kind-text'));
    await tester.pump();
    expect(result(1), findsNothing);
    expect(snippetSpan(tester, 0).toPlainText(), '미분 적분 노트');

    await tester.tap(byKeyName('note-search-kind-all'));
    await tester.pump();
    expect(result(1), findsOneWidget);
  });

  testWidgets('tapping the selected source again shows everything', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, '적분');

    await tester.tap(byKeyName('note-search-kind-text'));
    await tester.pump();
    await tester.tap(byKeyName('note-search-kind-text'));
    await tester.pump();

    expect(result(1), findsOneWidget);
  });

  testWidgets('says when nothing matches', (tester) async {
    await pump(tester);

    await type(tester, '화학');

    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('updates when the index changes', (tester) async {
    await pump(tester);
    await type(tester, '화학');

    index.indexPage('n1', 'p3', ['화학 반응']);
    await tester.pump();

    expect(snippetSpan(tester, 0).toPlainText(), '화학 반응');
  });

  testWidgets('can search one note only', (tester) async {
    await pump(tester, noteId: 'n2');

    await type(tester, '어');

    expect(result(0), findsOneWidget);
    expect(find.text('Text · n2/p1'), findsOneWidget);
  });

  testWidgets('the chips can be hidden', (tester) async {
    await pump(tester, showKindFilters: false);

    expect(byKeyName('note-search-kind-all'), findsNothing);
  });
}
