import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/state/drawing_state.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/editor/editor.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';

void main() {
  late Map<String, NoteDocument> documents;
  late List<String> closed;
  late List<Object> errors;
  late NoteWorkspaceController workspace;
  late DrawingTool previousTool;
  var nextId = 0;

  String id() => 'id${++nextId}';

  NoteDocument newDocument(String noteId, {int pages = 3}) {
    final document = NoteDocument(
      id: noteId,
      registry: standardNoteObjectRegistry(),
      defaultTemplate: NotePaperTemplate.grid(),
      idFactory: id,
    );
    for (var i = 1; i < pages; i++) {
      document.addPage();
    }

    return document;
  }

  NoteEditorController newEditor(
    NoteDocument document,
    NoteToolController tools,
    String pageId,
  ) => NoteEditorController(
    document: document,
    tools: tools,
    initialPageId: pageId,
    autoSaveDelay: null,
    idFactory: id,
  );

  setUp(() {
    previousTool = DrawingState().selectedTool.value;
    documents = {'a': newDocument('a'), 'b': newDocument('b')};
    closed = [];
    errors = [];
    workspace = NoteWorkspaceController(
      openDocument: (noteId) async => documents[noteId],
      createEditor: newEditor,
      onDocumentClosed: (noteId, _) => closed.add(noteId),
      onError: (error, _) => errors.add(error),
    );
  });

  tearDown(() {
    DrawingState().selectedTool.value = previousTool;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() {
      workspace.dispose();
      for (final document in documents.values) {
        document.dispose();
      }
    });
    await tester.pumpWidget(
      noteTestHost(NoteWorkspaceView(controller: workspace)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    String noteId, {
    String? paneId,
  }) async {
    workspace.open(noteId, title: noteId.toUpperCase(), paneId: paneId);
    await tester.pumpAndSettle();
  }

  Future<void> mode(WidgetTester tester, NoteViewMode mode) async {
    workspace.setMode(mode);
    await tester.pumpAndSettle();
  }

  String paneId(int index) => workspace.layout.panes[index].id;

  NoteEditorController editor(int index) => workspace.editorOf(paneId(index))!;

  Finder inPane(int index, Finder matching) => find.descendant(
    of: find.byKey(ValueKey('note-workspace-pane-${paneId(index)}')),
    matching: matching,
  );

  /// A page point of pane [index] on screen.
  Offset onPane(WidgetTester tester, int index, Offset page) {
    final rect = tester.getRect(
      inPane(index, find.byType(NotePageBackground)).last,
    );
    final size = editor(index).page.size;

    return rect.topLeft +
        Offset(
          page.dx * rect.width / size.width,
          page.dy * rect.height / size.height,
        );
  }

  Future<void> draw(
    WidgetTester tester,
    int index, {
    double y = 200,
    PointerDeviceKind kind = PointerDeviceKind.stylus,
  }) async {
    final gesture = await tester.startGesture(
      onPane(tester, index, Offset(150, y)),
      kind: kind,
    );
    for (var step = 1; step <= 5; step++) {
      await gesture.moveTo(onPane(tester, index, Offset(150 + step * 30, y)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  int strokes(NotePage page) =>
      [for (final content in page.layers) ...content.scribble.strokes].length;

  Future<void> tapKey(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('tabs switch notes and come back to the page they showed', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    final first = editor(0);
    first.goToPage(documents['a']!.pageIds[2]);
    await tester.pumpAndSettle();
    await draw(tester, 0);

    await open(tester, 'b');
    expect(editor(0).document, same(documents['b']));
    expect(editor(0).pageIndex, 0);

    await tapKey(tester, find.byKey(NoteTabBar.tabKey('a')));
    expect(editor(0), same(first));
    expect(editor(0).pageIndex, 2);
    expect(strokes(editor(0).page), 1);
    // 화면을 떠난 편집기의 필기는 문서에 넘어가 있다.
    expect(strokes(documents['a']!.pageAt(2)), 1);
    expect(closed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a note opens on a page asked for by id', (tester) async {
    await pump(tester);
    final wanted = documents['b']!.pageIds[2];

    await open(tester, 'a');
    workspace.open('b', pageId: wanted);
    await tester.pumpAndSettle();
    expect(editor(0).pageId, wanted);
    expect(workspace.layout.panes.single.pageIndex, 2);

    // 이미 열린 노트도 그 쪽으로 간다.
    final first = documents['a']!.pageIds[1];
    workspace.open('a', pageId: first);
    await tester.pumpAndSettle();
    expect(editor(0).pageId, first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing a tab saves the note, then releases it', (tester) async {
    await pump(tester);
    await open(tester, 'a');
    await open(tester, 'b');
    await draw(tester, 0);
    final closing = editor(0);

    await tapKey(tester, find.byKey(NoteTabBar.closeKey('b')));

    expect(closed, ['b']);
    expect(strokes(documents['b']!.pageAt(0)), 1);
    expect(editor(0), isNot(same(closing)));
    expect(editor(0).document, same(documents['a']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('two pages turn together; past the end offers a new page', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    await mode(tester, NoteViewMode.twoPage);
    final pages = documents['a']!.pageIds;

    expect(editor(0).pageId, pages[0]);
    expect(editor(1).pageId, pages[1]);

    editor(0).nextPage();
    await tester.pumpAndSettle();
    expect(editor(0).pageId, pages[1]);
    expect(editor(1).pageId, pages[2]);

    editor(1).previousPage();
    await tester.pumpAndSettle();
    expect(editor(0).pageId, pages[0]);
    expect(editor(1).pageId, pages[1]);

    editor(0)
      ..nextPage()
      ..nextPage();
    await tester.pumpAndSettle();
    expect(editor(0).pageId, pages[2]);
    expect(workspace.statusOf(paneId(1)), NoteWorkspacePaneStatus.pastEnd);
    expect(find.text('No next page'), findsOneWidget);

    await tapKey(tester, find.byKey(const ValueKey('note-workspace-add-page')));

    expect(documents['a']!.pageCount, 4);
    expect(editor(0).pageId, pages[2]);
    expect(editor(1).pageId, documents['a']!.pageIds[3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the right page of a spread keeps the left one', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    await mode(tester, NoteViewMode.twoPage);
    final pages = documents['a']!.pageIds;

    workspace.focus(paneId(0));
    documents['a']!.removePage(pages[1]);
    await tester.pumpAndSettle();

    expect(editor(0).pageId, pages[0]);
    expect(editor(1).pageId, pages[2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the last page does not leave a pane past the end', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    editor(0).goToPage(documents['a']!.pageIds.last);
    await tester.pumpAndSettle();

    editor(0).removePage();
    await tester.pumpAndSettle();

    expect(workspace.statusOf(paneId(0)), NoteWorkspacePaneStatus.ready);
    expect(editor(0).pageIndex, 1);
    expect(workspace.layout.panes.single.pageIndex, 1);
    expect(tester.takeException(), isNull);
  });

  for (final kind in [PointerDeviceKind.stylus, PointerDeviceKind.touch]) {
    testWidgets('writing on both pages of a spread keeps both (${kind.name})', (
      tester,
    ) async {
      await pump(tester);
      await open(tester, 'a');
      await mode(tester, NoteViewMode.twoPage);
      workspace.tools.fingerDrawing = kind == PointerDeviceKind.touch;
      await tester.pumpAndSettle();

      await draw(tester, 0, kind: kind);
      // 다른 쪽이면 첫 입력부터 바로 써지고 초점도 옮겨진다.
      await draw(tester, 1, kind: kind);
      expect(workspace.focusedPaneId, paneId(1));
      await draw(tester, 0, y: 300, kind: kind);
      await workspace.save();

      final document = documents['a']!;
      expect(strokes(document.pageAt(0)), 2);
      expect(strokes(document.pageAt(1)), 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the same page twice: one side follows, a tap moves the focus', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    await mode(tester, NoteViewMode.doubleReading);
    workspace.focus(paneId(0));
    await tester.pumpAndSettle();
    expect(editor(0).pageId, editor(1).pageId);
    expect(workspace.needsFocusFirst(paneId(1)), isTrue);
    expect(find.text('Tap to edit here'), findsOneWidget);

    await draw(tester, 0);
    expect(strokes(editor(1).page), 1, reason: '따라오는 쪽에도 바로 보인다');

    // 첫 획은 초점만 옮기고 쓰이지 않는다.
    await draw(tester, 1, y: 300);
    expect(workspace.focusedPaneId, paneId(1));
    expect(strokes(editor(1).page), 1);
    expect(workspace.needsFocusFirst(paneId(0)), isTrue);

    await draw(tester, 1, y: 400);
    expect(strokes(editor(1).page), 2);
    expect(strokes(editor(0).page), 2);

    // 도구의 실행 취소는 초점 있는 쪽의 것이다.
    workspace.tools.onUndo!();
    await tester.pumpAndSettle();
    expect(strokes(editor(1).page), 1);
    expect(strokes(editor(0).page), 1);
    await workspace.save();
    expect(strokes(documents['a']!.pageAt(0)), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text still being typed moves to the other side with the focus', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    editor(0).addObject(
      NoteStickyObject(
        id: 'sticky',
        bounds: const Rect.fromLTWH(60, 60, 200, 150),
      ),
    );
    await tester.pumpAndSettle();
    await mode(tester, NoteViewMode.doubleReading);
    workspace.focus(paneId(0));
    await tester.pumpAndSettle();
    final at = onPane(tester, 0, const Offset(120, 100));
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    await tester.enterText(inPane(0, find.byType(EditableText)).last, 'typed');
    await tester.pump();

    // 터치로는 입력 칸의 초점이 저절로 풀리지 않는다.
    await tester.tapAt(
      onPane(tester, 1, const Offset(400, 600)),
      kind: PointerDeviceKind.touch,
    );
    await tester.pumpAndSettle();

    String text(NotePage page) =>
        (page.objects.single as NoteStickyObject).text;
    expect(workspace.focusedPaneId, paneId(1));
    expect(text(documents['a']!.pageAt(0)), 'typed');
    expect(text(editor(1).page), 'typed');
    await tapKey(
      tester,
      inPane(1, find.byKey(const ValueKey('note-top-mode-draw'))),
    );
    await draw(tester, 1, y: 500);
    await workspace.save();
    expect(text(documents['a']!.pageAt(0)), 'typed');
    expect(strokes(documents['a']!.pageAt(0)), 1);
    expect(tester.takeException(), isNull);
  });

  for (final byTap in [true, false]) {
    final how = byTap ? 'a tap' : 'the host';
    testWidgets(
      'a half-typed table cell moves along when $how moves the focus',
      (tester) async {
        await pump(tester);
        await open(tester, 'a');
        editor(0).addObject(
          NoteTableObject.grid(
            id: 'table',
            bounds: const Rect.fromLTWH(60, 200, 360, 150),
          ),
        );
        await tester.pumpAndSettle();
        await mode(tester, NoteViewMode.doubleReading);
        workspace.focus(paneId(0));
        await tester.pumpAndSettle();
        final at = onPane(tester, 0, const Offset(110, 225));
        await tester.tapAt(at, kind: PointerDeviceKind.mouse);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(at, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        await tester.enterText(
          inPane(0, find.byType(EditableText)).last,
          'cell',
        );
        await tester.pump();

        if (byTap) {
          await tester.tapAt(
            onPane(tester, 1, const Offset(400, 600)),
            kind: PointerDeviceKind.touch,
          );
        } else {
          // 앱이 초점만 옮기면 입력 칸은 그대로다.
          workspace.focus(paneId(1));
        }
        await tester.pumpAndSettle();

        String cell(NotePage page) =>
            (page.objects.single as NoteTableObject).cellAt(0, 0).text;
        expect(cell(documents['a']!.pageAt(0)), 'cell');
        expect(cell(editor(1).page), 'cell');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('two views on different pages write directly', (tester) async {
    await pump(tester);
    await open(tester, 'a');
    await mode(tester, NoteViewMode.doubleReading);
    editor(1).goToPage(documents['a']!.pageIds[2]);
    await tester.pumpAndSettle();
    expect(workspace.layout.panes[1].pageIndex, 2);
    expect(workspace.needsFocusFirst(paneId(1)), isFalse);

    await draw(tester, 1);
    await draw(tester, 0);
    await workspace.save();

    expect(strokes(documents['a']!.pageAt(0)), 1);
    expect(strokes(documents['a']!.pageAt(2)), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a squeeze shows the palette of the focused pane only', (
    tester,
  ) async {
    await pump(tester);
    await open(tester, 'a');
    await mode(tester, NoteViewMode.twoPage);
    await draw(tester, 1);

    workspace.tools.dispatcher.dispatch(NotePencilGesture.squeeze);
    await tester.pumpAndSettle();
    expect(editor(1).isPaletteOpen, isTrue);
    expect(editor(0).isPaletteOpen, isFalse);
    expect(
      inPane(1, find.byKey(const ValueKey('note-palette-close'))),
      findsOneWidget,
    );

    await draw(tester, 0);
    expect(editor(1).isPaletteOpen, isFalse);
    workspace.tools.dispatcher.dispatch(NotePencilGesture.squeeze);
    await tester.pumpAndSettle();
    expect(editor(0).isPaletteOpen, isTrue);
    expect(find.byKey(const ValueKey('note-palette-close')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two notes side by side share the pen', (tester) async {
    await pump(tester);
    await open(tester, 'b');
    await open(tester, 'a');
    await mode(tester, NoteViewMode.dualDocument);
    expect(find.text('Choose a note for this side'), findsOneWidget);

    await tapKey(tester, find.byKey(const ValueKey('note-workspace-pick-b')));
    expect(editor(1).document, same(documents['b']));

    workspace.tools.selectTool(NoteInkTypes.marker);
    await tester.pumpAndSettle();
    await draw(tester, 1);
    await draw(tester, 0);
    await workspace.save();

    for (final noteId in ['a', 'b']) {
      final page = documents[noteId]!.pageAt(0);
      expect(
        page.layers.single.scribble.strokes.single.ink,
        NoteInkTypes.marker,
        reason: noteId,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the layout menu changes the arrangement', (tester) async {
    await pump(tester);
    await open(tester, 'a');
    await tapKey(tester, find.byKey(const ValueKey('note-workspace-layout')));

    await tapKey(
      tester,
      find.byKey(const ValueKey('note-workspace-mode-split')),
    );
    expect(workspace.layout.panes, hasLength(2));
    expect(workspace.focusedPaneId, paneId(0));
    // 닫는 것은 초점 있는 쪽이라 둘째가 남는다.
    final kept = editor(1);

    await tapKey(
      tester,
      find.byKey(const ValueKey('note-workspace-axis-vertical')),
    );
    expect(workspace.layout.axis, Axis.vertical);
    await tapKey(
      tester,
      find.byKey(const ValueKey('note-workspace-close-pane')),
    );

    expect(workspace.layout.panes, hasLength(1));
    // 남은 쪽은 편집기와 화면 상태를 그대로 잇는다.
    expect(editor(0), same(kept));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a note that cannot open offers another try', (tester) async {
    var failures = 1;
    workspace.dispose();
    workspace = NoteWorkspaceController(
      openDocument: (noteId) async {
        if (failures-- > 0) throw StateError('offline');

        return documents[noteId];
      },
      createEditor: newEditor,
      onError: (error, _) => errors.add(error),
    );
    await pump(tester);

    await open(tester, 'a');
    expect(workspace.statusOf(paneId(0)), NoteWorkspacePaneStatus.failed);
    expect(errors.single, isStateError);

    await tapKey(
      tester,
      find.byKey(ValueKey('note-workspace-retry-${paneId(0)}')),
    );
    expect(workspace.statusOf(paneId(0)), NoteWorkspacePaneStatus.ready);

    await open(tester, 'gone');
    expect(workspace.statusOf(paneId(0)), NoteWorkspacePaneStatus.missing);
    await tapKey(
      tester,
      find.byKey(ValueKey('note-workspace-close-note-${paneId(0)}')),
    );
    expect(workspace.tabs.tabs.map((tab) => tab.noteId), ['a']);
    expect(editor(0).document, same(documents['a']));
    expect(tester.takeException(), isNull);
  });
}
