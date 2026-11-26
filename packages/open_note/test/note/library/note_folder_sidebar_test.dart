import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

import '../support/note_test_host.dart';
import 'library_test_support.dart';

NoteLibrary _library() => testLibrary(
  folders: [
    folder('s', name: 'School', iconKey: NoteFolderIcons.school),
    folder('m', name: 'Math', parentId: 's', iconKey: NoteFolderIcons.book),
    folder('w', name: 'Work', order: 1, iconKey: NoteFolderIcons.briefcase),
  ],
  notes: [
    summary('1', folderId: 's'),
    summary('2', folderId: 'm'),
    summary('3', folderId: 'm'),
    summary('4'),
  ],
  trash: [summary('5', folderId: 'w')],
);

Widget _host(Widget sidebar) => noteTestHost(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 260, height: 500, child: sidebar),
  ),
);

Finder _row(String? folderId) => find.byKey(NoteFolderSidebar.rowKey(folderId));

Finder _inRow(String? folderId, Finder matching) =>
    find.descendant(of: _row(folderId), matching: matching);

String _countOf(WidgetTester tester, String? folderId) =>
    tester.widgetList<Text>(_inRow(folderId, find.byType(Text))).last.data!;

void main() {
  testWidgets('lists all notes and the folder tree with counts', (
    tester,
  ) async {
    await tester.pumpWidget(_host(NoteFolderSidebar(library: _library())));

    expect(find.text('All notes'), findsOneWidget);
    expect(_countOf(tester, null), '4');
    expect(_countOf(tester, 's'), '1');
    expect(_countOf(tester, 'm'), '2');
    expect(_countOf(tester, 'w'), '0');
    final tops = [
      for (final id in [null, 's', 'm', 'w']) tester.getTopLeft(_row(id)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws each folder icon and indents subfolders', (tester) async {
    await tester.pumpWidget(_host(NoteFolderSidebar(library: _library())));

    NoteFolderIconView iconOf(String id) => tester.widget<NoteFolderIconView>(
      _inRow(id, find.byType(NoteFolderIconView)),
    );
    expect(iconOf('s').iconKey, NoteFolderIcons.school);
    expect(iconOf('m').iconKey, NoteFolderIcons.book);
    expect(iconOf('w').iconKey, NoteFolderIcons.briefcase);
    double leftOf(String id) =>
        tester.getTopLeft(_inRow(id, find.byType(NoteFolderIconView))).dx;
    expect(leftOf('m'), greaterThan(leftOf('s')));
    expect(leftOf('w'), leftOf('s'));
  });

  testWidgets('a tap shows the folder and reports it', (tester) async {
    final library = _library();
    final selected = <String?>[];
    await tester.pumpWidget(
      _host(NoteFolderSidebar(library: library, onSelectFolder: selected.add)),
    );

    await tester.tap(find.text('Math'));
    await tester.pump();
    expect(library.viewState.folderId, 'm');

    await tester.tap(find.text('All notes'));
    await tester.pump();

    expect(library.viewState.folderId, isNull);
    expect(selected, ['m', null]);
  });

  testWidgets('highlights the shown folder', (tester) async {
    final handle = tester.ensureSemantics();
    final library = _library();
    await tester.pumpWidget(_host(NoteFolderSidebar(library: library)));
    ColoredBox highlight(String? id) => tester
        .widgetList<ColoredBox>(_inRow(id, find.byType(ColoredBox)))
        .first;
    const style = NoteLibraryStyle();
    expect(highlight(null).color, style.selectionColor);

    library.showFolder('w');
    await tester.pump();

    expect(highlight('w').color, style.selectionColor);
    expect(highlight(null).color, isNot(style.selectionColor));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Work, 0 notes')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Math, 2 notes')),
      isSemantics(isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('closes and opens folders without selecting them', (
    tester,
  ) async {
    final library = _library();
    final selected = <String?>[];
    await tester.pumpWidget(
      _host(NoteFolderSidebar(library: library, onSelectFolder: selected.add)),
    );
    expect(find.byKey(NoteFolderSidebar.toggleKey('s')), findsOneWidget);
    expect(find.byKey(NoteFolderSidebar.toggleKey('w')), findsNothing);

    await tester.tap(find.byKey(NoteFolderSidebar.toggleKey('s')));
    await tester.pump();
    expect(find.text('Math'), findsNothing);
    expect(find.text('Work'), findsOneWidget);

    await tester.tap(find.byKey(NoteFolderSidebar.toggleKey('s')));
    await tester.pump();
    expect(find.text('Math'), findsOneWidget);
    expect(selected, isEmpty);
    expect(library.viewState.folderId, isNull);
  });

  testWidgets('names the toggle for assistive technology', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(NoteFolderSidebar(library: _library())));

    expect(find.bySemanticsLabel('Collapse folder'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Collapse folder'));
    await tester.pump();

    expect(find.bySemanticsLabel('Expand folder'), findsOneWidget);
    expect(find.text('Math'), findsNothing);
    handle.dispose();
  });

  testWidgets('reports long presses on folders only', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      _host(
        NoteFolderSidebar(
          library: _library(),
          onLongPressFolder: (entry) => pressed.add(entry.id),
        ),
      ),
    );

    await tester.longPress(find.text('Work'));
    await tester.longPress(find.text('All notes'));

    expect(pressed, ['w']);
  });

  testWidgets('follows the library', (tester) async {
    final library = _library();
    await tester.pumpWidget(_host(NoteFolderSidebar(library: library)));

    library
      ..renameFolder('w', 'Office')
      ..createNote(folderId: 'w')
      ..createFolder('', iconKey: NoteFolderIcons.star)
      ..deleteFolder('s');
    await tester.pump();

    expect(find.text('Office'), findsOneWidget);
    expect(_countOf(tester, 'w'), '1');
    expect(_countOf(tester, null), '5');
    expect(find.text('Untitled folder'), findsOneWidget);
    expect(find.text('School'), findsNothing);
    expect(find.text('Math'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the given strings', (tester) async {
    await tester.pumpWidget(
      _host(
        NoteFolderSidebar(
          library: _library(),
          strings: const NoteLibraryStrings(allNotes: '모든 노트'),
        ),
      ),
    );

    expect(find.text('모든 노트'), findsOneWidget);
  });
}
