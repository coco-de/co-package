import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/internal/note_nav_icon_button.dart';
import 'package:open_note/src/note/nav/internal/note_nav_row.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

NoteOutline _sample() => NoteOutline(
  entries: [
    NoteOutlineEntry(
      id: 'ch1',
      title: '1장 미분',
      pageId: 'p1',
      children: [NoteOutlineEntry(id: 's1', title: '1.1 극한', pageId: 'p2')],
    ),
    NoteOutlineEntry(id: 'ch2', title: '2장 적분', pageId: 'p3'),
  ],
  idFactory: countingIds('n'),
);

void main() {
  late NoteOutline outline;
  late List<String> tapped;

  setUp(() {
    outline = _sample();
    tapped = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    String? currentPageId = 'p9',
    bool editable = true,
    String? Function(String pageId)? pageLabelOf,
  }) => pumpPanel(
    tester,
    NoteOutlinePanel(
      outline: outline,
      onEntrySelected: (entry) => tapped.add(entry.pageId),
      currentPageId: currentPageId,
      editable: editable,
      pageLabelOf: pageLabelOf,
    ),
  );

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(byKeyName(key));
    await tester.pump();
    await tester.pump();
  }

  Future<void> edit(WidgetTester tester) => tap(tester, 'note-outline-edit');

  bool isEnabled(WidgetTester tester, String key) =>
      tester.widget<NoteNavIconButton>(byKeyName(key)).onPressed != null;

  final field = find.byType(EditableText);

  testWidgets('shows the tree, page labels and reports taps', (tester) async {
    await pump(tester, pageLabelOf: (page) => page.toUpperCase());

    expect(find.text('1장 미분'), findsOneWidget);
    expect(find.text('1.1 극한'), findsOneWidget);
    expect(find.text('P2'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('1.1 극한')).dx,
      greaterThan(tester.getTopLeft(find.text('1장 미분')).dx),
    );

    await tester.tap(find.text('1.1 극한'));
    await tester.tap(find.text('2장 적분'));

    expect(tapped, ['p2', 'p3']);
  });

  testWidgets('collapses and expands entries', (tester) async {
    await pump(tester);

    await tap(tester, 'note-outline-toggle-ch1');
    expect(find.text('1.1 극한'), findsNothing);
    expect(find.text('2장 적분'), findsOneWidget);

    await tap(tester, 'note-outline-toggle-ch1');
    expect(find.text('1.1 극한'), findsOneWidget);
    expect(tapped, isEmpty);
  });

  testWidgets('highlights the most specific entry of the current page', (
    tester,
  ) async {
    await pump(tester, currentPageId: 'p2');

    final selected = tester
        .widgetList<NoteNavRow>(find.byType(NoteNavRow))
        .map((row) => row.selected);

    expect(selected, [false, true, false]);
  });

  testWidgets('adds a root entry and names it', (tester) async {
    await pump(tester);
    await edit(tester);

    await tap(tester, 'note-outline-add');

    expect(field, findsOneWidget);
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
    await tester.enterText(field, '3장 급수');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final added = outline.entries.last;
    expect(added.title, '3장 급수');
    expect(added.pageId, 'p9');
    expect(field, findsNothing);
    expect(find.text('3장 급수'), findsOneWidget);
  });

  testWidgets('keeps the default title when a new entry is left blank', (
    tester,
  ) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-add-child-ch2');

    expect(field, findsOneWidget);
    await edit(tester);

    final added = outline.find('ch2')!.children.single;
    expect(added.title, 'New entry');
    expect(added.pageId, 'p9');
    expect(field, findsNothing);
  });

  testWidgets('adding a sub-entry expands a collapsed parent', (tester) async {
    await pump(tester);
    await tap(tester, 'note-outline-toggle-ch1');
    await edit(tester);

    await tap(tester, 'note-outline-add-child-ch1');

    expect(find.text('1.1 극한'), findsOneWidget);
    expect(outline.find('ch1')!.children.length, 2);
  });

  testWidgets('Done commits a pending rename', (tester) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-rename-ch2');
    expect(tester.widget<EditableText>(field).controller.text, '2장 적분');

    await tester.enterText(field, '정적분');
    await edit(tester);

    expect(outline.find('ch2')!.title, '정적분');
    expect(field, findsNothing);
  });

  testWidgets('renaming another row commits the first rename', (tester) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-rename-ch1');
    await tester.enterText(field, '미분법');

    await tap(tester, 'note-outline-rename-ch2');

    expect(outline.find('ch1')!.title, '미분법');
    expect(field, findsOneWidget);
    expect(tester.widget<EditableText>(field).controller.text, '2장 적분');
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
  });

  testWidgets('a field that is going away cannot end the next rename', (
    tester,
  ) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-rename-ch1');

    await tester.tap(byKeyName('note-outline-rename-ch2'));
    // The first field loses the focus before the rebuild removes it.
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    await tester.pump();

    expect(byKeyName('note-outline-field-ch2'), findsOneWidget);
  });

  testWidgets('losing the focus commits the rename', (tester) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-rename-ch2');
    await tester.enterText(field, '적분법');

    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    await tester.pump();

    expect(outline.find('ch2')!.title, '적분법');
    expect(field, findsNothing);
  });

  testWidgets('a blank rename keeps the old title', (tester) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-rename-ch2');

    await tester.enterText(field, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(outline.find('ch2')!.title, '2장 적분');
  });

  testWidgets('indents and outdents where the tree allows it', (tester) async {
    await pump(tester);
    await edit(tester);

    expect(isEnabled(tester, 'note-outline-indent-ch1'), isFalse);
    expect(isEnabled(tester, 'note-outline-outdent-ch1'), isFalse);
    expect(isEnabled(tester, 'note-outline-indent-s1'), isFalse);
    expect(isEnabled(tester, 'note-outline-outdent-s1'), isTrue);

    await tap(tester, 'note-outline-indent-ch2');
    expect(outline.parentOf('ch2')!.id, 'ch1');
    await tap(tester, 'note-outline-outdent-ch2');
    expect(outline.parentOf('ch2'), isNull);
  });

  testWidgets('indenting under a collapsed entry expands it', (tester) async {
    await pump(tester);
    await tap(tester, 'note-outline-toggle-ch1');
    await edit(tester);

    await tap(tester, 'note-outline-indent-ch2');

    expect(find.text('2장 적분'), findsOneWidget);
    expect(find.text('1.1 극한'), findsOneWidget);
  });

  testWidgets('tapping a disabled button does not jump to the entry', (
    tester,
  ) async {
    await pump(tester);
    await edit(tester);

    await tap(tester, 'note-outline-indent-ch1');

    expect(tapped, isEmpty);
  });

  testWidgets('delete removes the entry with its sub-entries', (tester) async {
    await pump(tester);
    await edit(tester);

    await tap(tester, 'note-outline-delete-ch1');

    expect(outline.entries.single.id, 'ch2');
    expect(find.text('1.1 극한'), findsNothing);
  });

  testWidgets('deleting the entry being renamed is safe', (tester) async {
    await pump(tester);
    await edit(tester);
    await tap(tester, 'note-outline-rename-ch2');

    await tap(tester, 'note-outline-delete-ch2');
    await edit(tester);

    expect(outline.find('ch2'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding needs a current page', (tester) async {
    await pump(tester, currentPageId: null);
    await edit(tester);

    expect(isEnabled(tester, 'note-outline-add'), isFalse);
    expect(isEnabled(tester, 'note-outline-add-child-ch1'), isFalse);
    await tap(tester, 'note-outline-add');
    expect(outline.flatten().length, 3);
  });

  testWidgets('a read-only panel has no edit mode', (tester) async {
    await pump(tester, editable: false);

    expect(byKeyName('note-outline-edit'), findsNothing);
    expect(byKeyName('note-outline-delete-ch1'), findsNothing);
  });

  testWidgets('shows a message and follows changes of the outline', (
    tester,
  ) async {
    outline = NoteOutline(idFactory: countingIds());
    await pump(tester);
    expect(find.text('No outline entries'), findsOneWidget);

    outline.add('Chapter', 'p1');
    await tester.pump();

    expect(find.text('Chapter'), findsOneWidget);
    expect(find.text('No outline entries'), findsNothing);
  });

  testWidgets('does not overflow in a narrow edit mode', (tester) async {
    await pumpPanel(
      tester,
      NoteOutlinePanel(
        outline: outline,
        onEntrySelected: (_) {},
        currentPageId: 'p1',
      ),
      width: 180,
    );
    await edit(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('labels its buttons for accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(find.bySemanticsLabel('Collapse'), findsOneWidget);

    await edit(tester);

    expect(find.bySemanticsLabel('Rename'), findsNWidgets(3));
    expect(find.bySemanticsLabel('Add sub-entry'), findsNWidgets(3));
    expect(find.bySemanticsLabel('Add entry'), findsOneWidget);
    semantics.dispose();
  });
}
