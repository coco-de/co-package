import 'package:flutter/gestures.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/open_note.dart';
import 'package:open_note_example/i18n/strings.g.dart';
import 'package:open_note_example/main.dart';
import 'package:open_note_example/note/note_demo_workspace.dart';

/// 노트 데모 — 라이브러리 → 편집기 → 저장하고 돌아오기, 그리고 글 검색.
void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ko);
    NoteDemoWorkspace.resetForTest();
  });

  Future<void> openNoteDemo(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TranslationProvider(child: const OpenNoteExampleApp()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('노트 데모'));
    await tester.tap(find.text('노트 데모'));
    await tester.pumpAndSettle();
  }

  /// 자동 저장 · 라이브러리 저장 타이머까지 흘려보낸다.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('안내 노트를 열어 쓰고 목록으로 돌아오면 저장돼 있다', (tester) async {
    await openNoteDemo(tester);

    await tester.tap(find.text('open_note 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorView), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    final canvas = tester.getCenter(find.byType(NoteLayeredPageView));
    final gesture = await tester.startGesture(
      canvas + const Offset(-60, 120),
      kind: PointerDeviceKind.stylus,
    );
    for (var i = 1; i <= 6; i++) {
      await gesture.moveBy(const Offset(20, 4));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-top-back')));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorView), findsNothing);
    final library = await NoteDemoWorkspace.instance.library();
    final tour = library.notes.singleWhere(
      (note) => note.title == 'open_note 둘러보기',
    );
    final stored = (await NoteDemoWorkspace.instance.documents.load(tour.id))!;
    addTearDown(stored.document.dispose);
    expect(stored.document.pageAt(0).hasInk, isTrue);
    await drain(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다른 노트에서 고른 쪽을 가져온다', (tester) async {
    await openNoteDemo(tester);
    await tester.tap(find.text('open_note 둘러보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-top-page-menu')));
    await tester.pumpAndSettle();
    final import = find.byKey(const ValueKey('note-drawer-import-pages'));
    await tester.ensureVisible(import);
    await tester.tap(import);
    await tester.pumpAndSettle();
    await tester.tap(find.text('빈 노트'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-demo-import-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-top-back')));
    await tester.pumpAndSettle();
    await drain(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('두 노트를 탭으로 열고 나란히 쓰면 둘 다 저장된다', (tester) async {
    await openNoteDemo(tester);
    await tester.tap(find.text('open_note 둘러보기'));
    await tester.pumpAndSettle();
    Future<void> tapKey(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
    }

    await tapKey('note-workspace-open');
    await tester.tap(find.text('빈 노트').last);
    await tester.pumpAndSettle();
    await tapKey('note-workspace-layout');
    await tapKey('note-workspace-mode-dualDocument');
    final library = await NoteDemoWorkspace.instance.library();
    String idOf(String title) =>
        library.notes.singleWhere((note) => note.title == title).id;
    await tapKey('note-workspace-pick-${idOf('open_note 둘러보기')}');

    expect(find.byType(NoteEditorView), findsNWidgets(2));
    final canvas = tester.getCenter(find.byType(NoteLayeredPageView).last);
    final gesture = await tester.startGesture(
      canvas + const Offset(-40, 160),
      kind: PointerDeviceKind.stylus,
    );
    for (var i = 1; i <= 6; i++) {
      await gesture.moveBy(const Offset(12, 3));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-top-back')).last);
    await tester.pumpAndSettle();

    final stored = (await NoteDemoWorkspace.instance.documents.load(
      idOf('open_note 둘러보기'),
    ))!;
    addTearDown(stored.document.dispose);
    expect(stored.document.pageAt(0).hasInk, isTrue);
    await drain(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('샘플 PDF 를 가져와 글자를 골라 형광펜을 친다', (tester) async {
    await openNoteDemo(tester);
    await tester.tap(find.text('open_note 둘러보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-top-page-menu')));
    await tester.pumpAndSettle();
    final import = find.byKey(const ValueKey('note-drawer-import-pages'));
    await tester.ensureVisible(import);
    await tester.tap(import);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-demo-import-pdf')));
    // 쪽 그림을 만드는 엔진 작업은 실제 이벤트 루프가 돌아야 끝난다.
    for (var i = 0; i < 20 && find.text('2 / 4').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('2 / 4'), findsOneWidget);

    final mode = find.byKey(const ValueKey('note-top-mode-pdfText'));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    final editor = tester
        .widget<NoteEditorView>(find.byType(NoteEditorView))
        .controller;
    expect(editor.pdfText.runs.first.text, 'Conservation');

    // 제목의 첫 낱말부터 'energy' 까지 끈다 (테스트 글꼴은 제목이 줄을 넘긴다).
    final runs = editor.pdfText.runs;
    final last = runs.firstWhere((run) => run.text == 'energy');
    final rect = tester.getRect(find.byType(NotePageBackground).last);
    final size = editor.page.size;
    final mapping = NotePdfPageMapping(editor.page, editor.pdfOrigin!);
    Offset screen(Offset pdf) {
      final page = mapping.toPage(pdf);

      return rect.topLeft +
          Offset(
            page.dx * rect.width / size.width,
            page.dy * rect.height / size.height,
          );
    }

    final gesture = await tester.startGesture(
      screen(runs.first.rect.center),
      kind: PointerDeviceKind.stylus,
    );
    await gesture.moveTo(screen(last.rect.center));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      editor.pdfText.selectedText.replaceAll('\n', ' '),
      'Conservation of energy',
    );

    await tester.tap(find.byKey(const ValueKey('note-pdf-highlight')));
    await tester.pumpAndSettle();
    expect(editor.page.hasInk, isTrue);
    // 윗줄은 옆으로 밀려 있을 수 있다.
    final back = find.byKey(const ValueKey('note-top-back'));
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorView), findsNothing);
    await drain(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('글 검색 결과를 누르면 그 쪽이 열린다', (tester) async {
    await openNoteDemo(tester);

    await tester.tap(find.byKey(const ValueKey('note-demo-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '가리개로');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('정의').first);
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorView), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('note-top-back')));
    await tester.pumpAndSettle();
    await drain(tester);
    expect(tester.takeException(), isNull);
  });
}
