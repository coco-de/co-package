import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/state/drawing_state.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/core/note_pdf_origin.dart';
import 'package:open_note/src/note/io/io.dart';
import 'package:open_note/src/note/tools/note_toolbar_layout.dart';
import 'package:open_note/src/note/tools/note_toolbar_dock_edge.dart';
import 'package:open_note/src/note/style/note_text_box_style.dart';
import 'package:open_note/src/note/style/note_text_box_border_style.dart';
import 'package:open_note/src/note/study/utilities/note_recording_controller.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/study/utilities/note_audio_recorder.dart';
import 'package:open_note/src/note/study/utilities/note_attachment.dart';
import 'package:open_note/src/note/study/utilities/fake_note_audio_recorder.dart';
import 'package:open_note/src/note/study/utilities/fake_note_audio_player.dart';
import 'package:open_note/src/note/nav/note_tag_ref.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/editor/editor.dart';
import 'package:open_note/src/note/editor/internal/note_quick_palette.dart';
import 'package:open_note/src/note/editor/internal/note_tool_options.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture_panel.dart';
import 'package:open_note/src/note/layer/note_layer_panel.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_view.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

import '../support/note_test_host.dart';

/// A 1 × 1 transparent PNG, so pictures decode in tests.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

ImageProvider _resolve(String source) => MemoryImage(_png);

NoteIdFactoryForTest _ids() {
  var next = 0;

  return () => 'n${++next}';
}

typedef NoteIdFactoryForTest = String Function();

void main() {
  late NoteDocument document;
  late NoteEditorController editor;
  late DrawingTool previousTool;

  setUp(() {
    previousTool = DrawingState().selectedTool.value;
    final tables = standardNoteObjectRegistry();
    document = NoteDocument(
      id: 'note',
      registry: tables,
      defaultTemplate: NotePaperTemplate.grid(),
      idFactory: _ids(),
    );
    editor = NoteEditorController(document: document, autoSaveDelay: null);
  });

  tearDown(() {
    DrawingState().selectedTool.value = previousTool;
  });

  Future<void> pump(
    WidgetTester tester, {
    Future<List<NoteImageInsert>> Function()? onPickImages,
    NoteAudioRecorder? audioRecorder,
    Future<NoteAttachment?> Function()? onPickAttachment,
    Future<void> Function()? onImportPages,
    ValueChanged<NoteToolbarLayout>? onToolbarLayoutChanged,
    NoteStickerStore? stickerStore,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() {
      editor.dispose();
      document.dispose();
    });
    await tester.pumpWidget(
      noteTestHost(
        NoteEditorView(
          controller: editor,
          imageProviderResolver: _resolve,
          onPickImages: onPickImages,
          audioRecorder: audioRecorder,
          onPickAttachment: onPickAttachment,
          onImportPages: onImportPages,
          onToolbarLayoutChanged: onToolbarLayoutChanged,
          stickerStore: stickerStore,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// A page point on screen.
  Offset onPage(WidgetTester tester, Offset page) {
    final rect = tester.getRect(find.byType(NotePageBackground).last);
    final size = editor.page.size;

    return rect.topLeft +
        Offset(
          page.dx * rect.width / size.width,
          page.dy * rect.height / size.height,
        );
  }

  Future<void> drag(
    WidgetTester tester,
    List<Offset> points, {
    PointerDeviceKind kind = PointerDeviceKind.stylus,
  }) async {
    final gesture = await tester.startGesture(
      onPage(tester, points.first),
      kind: kind,
    );
    for (var i = 1; i < points.length; i++) {
      for (var step = 1; step <= 4; step++) {
        await gesture.moveTo(
          onPage(tester, Offset.lerp(points[i - 1], points[i], step / 4)!),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  List<int> strokeColors() => [
    for (final stroke in editor.layers.activeNotifier.currentScribble.strokes)
      stroke.color,
  ];

  testWidgets('the stylus writes and the toolbar undoes', (tester) async {
    await pump(tester);

    await drag(tester, const [Offset(100, 100), Offset(260, 140)]);
    expect(strokeColors(), hasLength(1));

    await tapKey(tester, 'note-tool-undo');
    expect(strokeColors(), isEmpty);
    await tapKey(tester, 'note-tool-redo');
    expect(strokeColors(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stroke beside the ruler follows its edge', (tester) async {
    await pump(tester);
    editor.ruler
      ..setCenter(const Offset(300, 300))
      ..setVisible(true);
    await tester.pumpAndSettle();
    final edge = 300 - editor.ruler.width / 2;

    await drag(tester, [
      Offset(180, edge - 8),
      Offset(300, edge - 30),
      Offset(420, edge - 4),
    ]);

    final points =
        editor.layers.activeNotifier.currentScribble.strokes.single.points;
    expect(points.length, greaterThan(3));
    expect(points.map((point) => point.y), everyElement(closeTo(edge, 0.01)));

    // 몸통을 끌면 자만 움직이고 필기는 생기지 않는다.
    await drag(tester, const [
      Offset(300, 300),
      Offset(340, 380),
    ], kind: PointerDeviceKind.mouse);
    expect(editor.ruler.center.dy, closeTo(380, 3));
    expect(strokeColors(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the eraser cuts the stroke it crosses', (tester) async {
    await pump(tester);
    await drag(tester, const [Offset(100, 200), Offset(400, 200)]);
    await drag(tester, const [Offset(100, 400), Offset(400, 400)]);

    await tapKey(tester, 'note-tool-eraser');
    await drag(tester, const [Offset(250, 150), Offset(250, 250)]);

    expect(strokeColors(), hasLength(1));

    await tapKey(tester, 'note-option-pixel-eraser');
    await drag(tester, const [Offset(250, 350), Offset(250, 450)]);

    // 부분 지우개는 남은 두 조각을 남긴다.
    expect(strokeColors(), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tools show their own settings', (tester) async {
    await pump(tester);

    await tapKey(tester, 'note-tool-eraser');
    await tapKey(tester, 'note-option-pixel-eraser');
    expect(editor.tools.currentTool, 'erase');
    expect(editor.tools.eraserSettings.mode.name, 'pixel');

    await tapKey(tester, 'note-tool-shape');
    await tapKey(tester, 'note-option-shape-star');
    expect(editor.tools.shapeTarget, 'star');
    await tapKey(tester, 'note-option-shape-fill');
    expect(editor.tools.shapeStyle, isNotEmpty);

    await tapKey(tester, 'note-tool-pen');
    await tapKey(tester, 'note-option-line-dashed');
    expect(editor.tools.lineStyle, 'dashed');
    expect(find.byKey(const ValueKey('note-option-dash-gap')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a drawn star is a two-point star shape', (tester) async {
    await pump(tester);
    await tapKey(tester, 'note-tool-shape');
    await tapKey(tester, 'note-option-shape-star');

    await drag(tester, const [Offset(100, 100), Offset(300, 300)]);

    final stroke = editor.layers.activeNotifier.currentScribble.strokes.single;
    expect(stroke.shapeType, 'star');
    expect(stroke.points, hasLength(2));
  });

  testWidgets('pages are added and turned', (tester) async {
    await pump(tester);

    await tapKey(tester, 'note-top-add-page');
    expect(editor.pageCount, 2);
    expect(find.text('2 / 2'), findsOneWidget);

    final size = editor.page.size;
    await tapKey(tester, 'note-top-page-menu');
    await tapKey(tester, 'note-drawer-rotate');
    expect(editor.page.size, size.rotated);

    await tapKey(tester, 'note-top-previous');
    expect(find.text('1 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('object mode inserts a sticky note and deletes it', (
    tester,
  ) async {
    await pump(tester);

    await tapKey(tester, 'note-top-mode-objects');
    await tapKey(tester, 'note-object-insert-sticky');
    expect(editor.page.objects.single, isA<NoteStickyObject>());
    expect(find.byType(NoteStickyView), findsOneWidget);

    await tapKey(tester, 'note-object-delete');
    expect(editor.page.objects, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing picture picker is reported, not unhandled', (
    tester,
  ) async {
    await pump(
      tester,
      onPickImages: () async => throw StateError('no permission'),
    );

    await tapKey(tester, 'note-tool-image');
    await tapKey(tester, 'note-option-add-images');

    expect(tester.takeException(), isA<StateError>());
    expect(
      editor.layers.activeNotifier.currentScribble.imageDrawables,
      isEmpty,
    );
  });

  testWidgets('a curve is bent by dragging its middle', (tester) async {
    await pump(tester);
    await tapKey(tester, 'note-top-mode-objects');
    await tapKey(tester, 'note-object-insert-curve');
    final curve = editor.page.objects.single as NoteArrowObject;
    final start = curve.startPoint;
    final middle = curve.bendPoint;

    await drag(tester, [
      middle,
      middle + const Offset(40, 130),
    ], kind: PointerDeviceKind.mouse);

    final bent = editor.page.objects.single as NoteArrowObject;
    expect(bent.bendPoint.dy, closeTo(middle.dy + 130, 2));
    expect(bent.bendPoint.dx, closeTo(middle.dx + 40, 2));
    expect((bent.startPoint - start).distance, lessThan(0.01));

    // 한 번의 끌기는 실행 취소 한 번이다.
    editor.undo();
    expect(
      (editor.page.objects.single as NoteArrowObject).bendPoint.dy,
      closeTo(middle.dy, 0.01),
    );
    await tapKey(tester, 'note-object-arrow-straighten');
    expect((editor.page.objects.single as NoteArrowObject).bend, isNull);
    expect(tester.takeException(), isNull);
  });

  Future<void> doubleTap(WidgetTester tester, Offset page) async {
    await tester.tapAt(onPage(tester, page), kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(onPage(tester, page), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
  }

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.stylus]) {
    testWidgets('typed table text and a later ${kind.name} drag undo apart', (
      tester,
    ) async {
      editor
        ..addObject(
          NoteStickyObject(
            id: 'sticky',
            bounds: const Rect.fromLTWH(60, 60, 120, 100),
          ),
        )
        ..addObject(
          NoteTableObject.grid(
            id: 'table',
            bounds: const Rect.fromLTWH(60, 400, 360, 150),
          ),
        );
      await pump(tester);
      await tapKey(tester, 'note-top-mode-objects');
      await doubleTap(tester, const Offset(110, 425));
      await tester.enterText(find.byType(EditableText).last, 'hello');
      await tester.pump();

      await drag(tester, const [
        Offset(120, 100),
        Offset(320, 100),
      ], kind: kind);

      NoteTableObject table() =>
          editor.page.objects.whereType<NoteTableObject>().single;
      NoteStickyObject sticky() =>
          editor.page.objects.whereType<NoteStickyObject>().single;
      expect(table().cellAt(0, 0).text, 'hello');
      expect(sticky().bounds.left, greaterThan(200));

      editor.undo();
      await tester.pumpAndSettle();
      expect(sticky().bounds.left, 60);
      expect(table().cellAt(0, 0).text, 'hello');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('typed table text and a later drag undo separately', (
    tester,
  ) async {
    editor
      ..addObject(
        NoteStickyObject(
          id: 'sticky',
          bounds: const Rect.fromLTWH(60, 60, 120, 100),
        ),
      )
      ..addObject(
        NoteTableObject.grid(
          id: 'table',
          bounds: const Rect.fromLTWH(60, 400, 360, 150),
        ),
      );
    await pump(tester);
    await tapKey(tester, 'note-top-mode-objects');
    await doubleTap(tester, const Offset(110, 425));
    await tester.enterText(find.byType(EditableText).last, 'hello');
    await tester.pump();

    await drag(tester, const [
      Offset(120, 100),
      Offset(320, 100),
    ], kind: PointerDeviceKind.mouse);

    NoteTableObject table() =>
        editor.page.objects.whereType<NoteTableObject>().single;
    NoteStickyObject sticky() =>
        editor.page.objects.whereType<NoteStickyObject>().single;
    expect(table().cellAt(0, 0).text, 'hello');
    expect(sticky().bounds.left, greaterThan(200));

    editor.undo();
    await tester.pumpAndSettle();
    expect(sticky().bounds.left, 60);
    expect(table().cellAt(0, 0).text, 'hello');

    editor.undo();
    await tester.pumpAndSettle();
    expect(table().cellAt(0, 0).text, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo while typing in a sticky note takes the text back', (
    tester,
  ) async {
    editor.addObject(
      NoteStickyObject(
        id: 'sticky',
        bounds: const Rect.fromLTWH(60, 60, 200, 150),
      ),
    );
    await pump(tester);
    await tapKey(tester, 'note-top-mode-objects');
    await doubleTap(tester, const Offset(120, 100));
    await tester.enterText(find.byType(EditableText).last, 'draft');
    await tester.pump();
    NoteStickyObject sticky() => editor.page.objects.single as NoteStickyObject;

    await tapKey(tester, 'note-tool-undo');

    expect(sticky().text, '');
    // 편집을 끝내도 되살아나지 않는다.
    await tapKey(tester, 'note-top-mode-draw');
    expect(sticky().text, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the cover pen masks part of the page', (tester) async {
    await pump(tester);

    await tapKey(tester, 'note-top-mode-maskPen');
    await drag(tester, const [Offset(80, 80), Offset(240, 130)]);

    final mask = editor.page.objects.single as NoteMaskObject;
    expect(mask.bounds.width, closeTo(160, 3));
    expect(editor.mode, NoteEditorMode.maskPen);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a captured region becomes an excerpt', (tester) async {
    await pump(tester);

    await tapKey(tester, 'note-top-mode-region');
    await drag(tester, const [Offset(50, 50), Offset(200, 200)]);
    await tapKey(tester, 'note-top-save-excerpt');

    final excerpt = document.excerpts.byPage(editor.pageId).single;
    expect(excerpt.rect.left, closeTo(50 / editor.page.size.width, 0.01));
    expect(editor.mode, NoteEditorMode.draw);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lasso selection can be recoloured', (tester) async {
    await pump(tester);
    await drag(tester, const [Offset(120, 120), Offset(200, 140)]);
    await tapKey(tester, 'note-tool-lasso');

    await drag(tester, const [
      Offset(90, 90),
      Offset(240, 90),
      Offset(240, 180),
      Offset(90, 180),
      Offset(90, 92),
    ]);
    expect(editor.lassoSelection.isEmpty, isFalse);

    await tapKey(tester, 'note-recolor-${const Color(0xFFE53935).toARGB32()}');

    expect(strokeColors(), contains(0xFFE53935));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cropping the selected picture trims it', (tester) async {
    await pump(tester);
    final id = editor.insertImages(const [
      NoteImageInsert('photo', Size(200, 200)),
    ]).single;
    editor.selectImage(id);
    await tester.pumpAndSettle();
    final width = editor.selectedImage!.width;

    await tapKey(tester, 'note-option-image-crop');
    final area = tester.getRect(find.byKey(const ValueKey('note-crop-area')));
    final gesture = await tester.startGesture(
      area.topLeft + const Offset(1, 1),
    );
    await gesture.moveTo(area.center);
    await gesture.up();
    await tester.pumpAndSettle();
    await tapKey(tester, 'note-drawer-crop-apply');

    expect(editor.selectedImage!.width, closeTo(width / 2, 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reading mode follows a page link', (tester) async {
    final first = editor.pageId;
    editor.addPage();
    editor.addObject(
      NoteLinkObject(
        id: 'link',
        bounds: const Rect.fromLTWH(100, 100, 200, 60),
        target: editor.pageLink(first),
      ),
    );
    await pump(tester);

    await tapKey(tester, 'note-top-mode-read');
    await tester.tapAt(onPage(tester, const Offset(200, 130)));
    await tester.pumpAndSettle();

    expect(editor.pageId, first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('side panels show layers and the page grid', (tester) async {
    await pump(tester);
    final first = editor.pageId;
    await tapKey(tester, 'note-top-add-page');

    await tapKey(tester, 'note-tool-layers');
    expect(find.byType(NoteLayerPanel), findsOneWidget);

    await tapKey(tester, 'note-panel-tab-pages');
    final thumbnails = find.byType(NotePageThumbnail);
    expect(thumbnails, findsNWidgets(2));
    await tester.tap(thumbnails.first);
    await tester.pumpAndSettle();
    expect(editor.pageId, first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full screen hides the bars until it is left', (tester) async {
    await pump(tester);

    await tapKey(tester, 'note-top-view-menu');
    await tapKey(tester, 'note-top-full-screen');
    expect(
      find.byKey(const ValueKey('note-top-add-page')).hitTestable(),
      findsNothing,
    );

    await tapKey(tester, 'note-top-exit-full-screen');
    expect(
      find.byKey(const ValueKey('note-top-add-page')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('study tools open as floating windows', (tester) async {
    await pump(tester);

    await tapKey(tester, 'note-top-study-menu');
    await tapKey(tester, 'note-top-calculator');

    expect(find.byType(NoteCalculatorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('excerpts are listed and jump back to their page', (
    tester,
  ) async {
    final first = editor.pageId;
    editor
      ..addExcerpt(const Rect.fromLTWH(10, 10, 100, 40), label: 'Define')
      ..addPage();
    await pump(tester);

    await tapKey(tester, 'note-top-panel-excerpts');
    final excerpt = document.excerpts.byPage(first).single;
    await tapKey(tester, 'note-excerpt-row-${excerpt.id}');

    expect(editor.pageId, first);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page menu tags pages and imports through the app', (
    tester,
  ) async {
    var imports = 0;
    await pump(tester, onImportPages: () async => imports++);

    await tapKey(tester, 'note-top-page-menu');
    await tapKey(tester, 'note-drawer-import-pages');
    expect(imports, 1);

    await tapKey(tester, 'note-top-page-menu');
    await tapKey(tester, 'note-drawer-page-tags');
    await tester.enterText(find.byType(EditableText).last, 'exam');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      document.tags.refsOf('exam').single,
      NoteTagRef(noteId: 'note', pageId: editor.pageId),
    );

    await tapKey(tester, 'note-top-page-menu');
    await tapKey(tester, 'note-drawer-add-size-420x595');
    expect(editor.page.size, NotePageSize.a5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the toolbar can be rearranged and moved', (tester) async {
    NoteToolbarLayout? saved;
    await pump(tester, onToolbarLayoutChanged: (layout) => saved = layout);

    await tapKey(tester, 'note-top-view-menu');
    await tapKey(tester, 'note-top-toolbar-settings');
    await tapKey(tester, 'note-drawer-toolbar-show-pencil');
    await tapKey(tester, 'note-drawer-toolbar-left');

    expect(find.byKey(const ValueKey('note-tool-pencil')), findsNothing);
    expect(saved!.dockEdge, NoteToolbarDockEdge.left);
    final pen = tester.getRect(find.byKey(const ValueKey('note-tool-pen')));
    final eraser = tester.getRect(
      find.byKey(const ValueKey('note-tool-eraser')),
    );
    expect(pen.left, lessThan(60));
    expect(eraser.top, greaterThan(pen.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected text takes a bordered box', (tester) async {
    final notifier = editor.layers.activeNotifier;
    notifier.setScribble(
      scribble: notifier.currentScribble.deepCopy()
        ..textDrawables.add(
          TextDrawable(
            id: 't',
            text: 'Key idea',
            x: 120,
            y: 130,
            fontSize: 20,
            color: 0xFF000000,
            textAlign: 'left',
          ),
        ),
    );
    await pump(tester);
    editor.lassoSelection.publish(const [], const [0]);
    await tapKey(tester, 'note-tool-lasso');
    editor.lassoSelection.publish(const [], const [0]);
    await tester.pumpAndSettle();

    await tapKey(tester, 'note-option-text-dashed-border');

    final box = NoteTextBoxStyle.decode(
      editor
          .layers
          .activeNotifier
          .currentScribble
          .textDrawables
          .single
          .boxStyle,
    );
    expect(box.borderLineStyle, NoteTextBoxBorderStyle.dashed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping turns pages only in reading mode', (tester) async {
    editor.addPage();
    editor.previousPage();
    await pump(tester);
    final center = onPage(tester, const Offset(300, 420));

    await tester.flingFrom(center, const Offset(-200, 0), 800);
    await tester.pumpAndSettle();
    expect(editor.pageIndex, 0);

    await tapKey(tester, 'note-top-mode-read');
    await tester.flingFrom(center, const Offset(-200, 10), 800);
    await tester.pumpAndSettle();
    expect(editor.pageIndex, 1);
    await tester.flingFrom(center, const Offset(200, 0), 800);
    await tester.pumpAndSettle();
    expect(editor.pageIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zoom favourites and going to the writing zoom the page', (
    tester,
  ) async {
    await pump(tester);
    await drag(tester, const [Offset(100, 100), Offset(180, 130)]);
    double paperWidth() =>
        tester.getRect(find.byType(NotePageBackground).last).width;
    final fitted = paperWidth();

    await tapKey(tester, 'note-top-view-menu');
    await tapKey(tester, 'note-top-zoom-200');
    expect(paperWidth(), closeTo(fitted * 2, 1));
    await tapKey(tester, 'note-top-view-menu');
    await tapKey(tester, 'note-top-fit-page');
    expect(paperWidth(), closeTo(fitted, 1));

    await tapKey(tester, 'note-top-view-menu');
    await tapKey(tester, 'note-top-go-to-writing');
    expect(paperWidth(), greaterThan(fitted * 2));
    // 쓴 곳이 화면 안에 보인다.
    final writing = onPage(tester, const Offset(140, 115));
    expect(const Rect.fromLTWH(0, 0, 1400, 900).contains(writing), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final kind in [PointerDeviceKind.stylus, PointerDeviceKind.touch]) {
    for (final (side, from, to) in [
      ('right', const Offset(-60, 300), const Offset(-30, 330)),
      ('left', const Offset(40, 300), const Offset(10, 330)),
    ]) {
      testWidgets('an endless page grows $side while the view stays put '
          '(${kind.name})', (tester) async {
        await pump(tester);
        await tapKey(tester, 'note-top-page-menu');
        await tapKey(tester, 'note-drawer-endless');
        // 손가락 필기는 켜야 써진다(기본은 화면 이동).
        editor.tools.fingerDrawing = kind == PointerDeviceKind.touch;
        await tester.pumpAndSettle();
        final size = editor.page.size;
        Offset resolved(Offset point) =>
            Offset(point.dx < 0 ? size.width + point.dx : point.dx, point.dy);
        // 늘어난 만큼 쪽 좌표가 밀린 점.
        Offset shifted(Offset point) =>
            point + Offset(editor.page.margins.left, 0);
        const probe = Offset(200, 200);
        final screen = onPage(tester, probe);

        await drag(tester, [resolved(from), resolved(to)], kind: kind);

        expect(editor.page.size.width, size.width + 400);
        expect(editor.page.size.height, size.height);
        expect(editor.page.margins.left, side == 'left' ? 400 : 0);
        expect((onPage(tester, shifted(probe)) - screen).distance, lessThan(1));
        final stroke = editor.layers.activeNotifier.currentScribble.strokes;
        expect(
          stroke.single.points.first.x,
          closeTo(shifted(resolved(from)).dx, 3),
        );

        // 한 번의 실행 취소가 필기와 늘어남을 함께 되돌린다.
        await tapKey(tester, 'note-tool-undo');
        expect(strokeColors(), isEmpty);
        expect(editor.page.size, size);
        expect((onPage(tester, probe) - screen).distance, lessThan(1));

        await tapKey(tester, 'note-tool-redo');
        expect(strokeColors(), hasLength(1));
        expect(editor.page.size.width, size.width + 400);
        expect((onPage(tester, shifted(probe)) - screen).distance, lessThan(1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a sticker collection is made in the editor and used', (
    tester,
  ) async {
    final stickers = NoteStickerStore();
    addTearDown(stickers.dispose);
    await pump(
      tester,
      stickerStore: stickers,
      onPickImages: () async => const [
        NoteImageInsert('star.png', Size(10, 10)),
      ],
    );
    await tapKey(tester, 'note-top-mode-objects');
    await tapKey(tester, 'note-object-insert-sticker');

    await tapKey(tester, 'note-sticker-manage');
    await tapKey(tester, 'note-sticker-new-collection');
    await tapKey(tester, 'note-sticker-add-pictures');
    await tapKey(tester, 'note-sticker-manage');
    final item = stickers.collections.single.items.single;
    expect(item.source, 'star.png');

    await tapKey(tester, 'note-sticker-${item.id}');

    final placed = editor.page.objects.single as NoteStickerObject;
    expect(placed.source, 'star.png');
    expect(find.byKey(const ValueKey('note-sticker-manage')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pencil gestures are set in the editor and run', (tester) async {
    await pump(tester);
    await tapKey(tester, 'note-option-pencil-gestures');
    await tester.tap(
      find.byKey(
        NotePencilGesturePanel.optionKey(
          NotePencilGesture.doubleTap,
          NotePencilAction.undo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(editor.tools.gestures.doubleTap, NotePencilAction.undo);

    await drag(tester, const [Offset(100, 100), Offset(200, 140)]);
    expect(strokeColors(), hasLength(1));
    editor.tools.dispatcher.dispatch(NotePencilGesture.doubleTap);
    await tester.pumpAndSettle();
    expect(strokeColors(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a squeeze shows the tool palette at the pen', (tester) async {
    await pump(tester);
    final pen = onPage(tester, const Offset(300, 500));
    final hover = await tester.createGesture(kind: PointerDeviceKind.stylus);
    await hover.addPointer(location: pen - const Offset(5, 0));
    await hover.moveTo(pen);
    await tester.pump();

    editor.tools.dispatcher.dispatch(NotePencilGesture.squeeze);
    await tester.pumpAndSettle();
    final palette = find.byType(NoteQuickPalette);
    final card = tester.getRect(palette);
    expect(card.bottom, lessThan(pen.dy));
    expect(card.center.dx, closeTo(pen.dx, 1));

    // 팔레트 위를 지나도 자리를 지킨다.
    await hover.moveTo(card.center);
    editor.tools.setWidth(7);
    await tester.pumpAndSettle();
    expect(tester.getRect(palette), card);
    await hover.removePointer();

    await tapKey(tester, 'note-palette-marker');
    expect(editor.tools.currentTool, NoteInkTypes.marker);
    expect(palette, findsNothing);

    editor.tools.dispatcher.dispatch(NotePencilGesture.squeeze);
    await tester.pumpAndSettle();
    await tapKey(tester, 'note-palette-color-2');
    // 형광펜은 툴바처럼 반투명하게 고른다.
    final red = NoteToolOptions.quickColors[2].withValues(alpha: 0.5);
    expect(editor.tools.color, red);
    expect(palette, findsNothing);

    // 밖에 쓰면 닫히고 획은 써진다.
    editor.tools.dispatcher.dispatch(NotePencilGesture.squeeze);
    await tester.pumpAndSettle();
    await drag(tester, const [Offset(80, 80), Offset(160, 100)]);
    expect(palette, findsNothing);
    final written = Color(strokeColors().single);
    expect(written.toARGB32() & 0xFFFFFF, red.toARGB32() & 0xFFFFFF);
    expect(written.a, closeTo(0.5, 0.01));
    expect(tester.takeException(), isNull);
  });

  group('PDF text', () {
    const pageSize = NotePageSize(400, 600);
    const origin = NotePdfOrigin(
      document: 'slides.pdf',
      pageIndex: 0,
      size: pageSize,
      picture: 'slide.png',
    );
    final words = [
      // 낱말 사이가 줄 높이보다 좁으면 한 줄로 칠한다.
      for (final (text, left) in [('Energy', 60.0), ('is', 132.0)])
        NotePdfTextRun(text: text, rect: Rect.fromLTWH(left, 100, 60, 16)),
      const NotePdfTextRun(
        text: 'conserved',
        rect: Rect.fromLTWH(60, 130, 120, 16),
      ),
    ];
    late List<String> copied;
    var nextSlideId = 0;

    /// Opens an imported PDF page in PDF text mode.
    Future<void> openSlide(WidgetTester tester) async {
      final slide = NotePage.blank(
        template: NotePaperTemplate.image(
          id: 'imported:1',
          imageSource: 'slide.png',
          size: pageSize,
        ),
        idFactory: () => 'slide-${nextSlideId++}',
      ).copyWith(pdf: origin);
      document.appendPages([slide]);
      editor.dispose();
      editor = NoteEditorController(
        document: document,
        autoSaveDelay: null,
        initialPageId: slide.id,
        pdfTextLayer: (key) =>
            key == 'slides.pdf' ? FakeNotePdfTextLayer({0: words}) : null,
      );
      copied = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester);
      await tapKey(tester, 'note-top-mode-pdfText');
    }

    List<Stroke> strokes() =>
        editor.layers.activeNotifier.currentScribble.strokes;

    for (final kind in [PointerDeviceKind.stylus, PointerDeviceKind.touch]) {
      testWidgets('a drag selects text to highlight and copy (${kind.name})', (
        tester,
      ) async {
        await openSlide(tester);
        expect(find.text('Drag across the text to select it'), findsOneWidget);

        await drag(tester, const [
          Offset(70, 108),
          Offset(170, 138),
        ], kind: kind);
        expect(editor.pdfText.selectedText, 'Energy is\nconserved');

        await tapKey(tester, 'note-pdf-copy');
        expect(copied, ['Energy is\nconserved']);

        await tapKey(tester, 'note-pdf-highlight');
        // 줄마다 한 획이다.
        expect(strokes(), hasLength(2));
        expect(strokes().first.ink, 'marker');
        expect(strokes().first.points.first.y, closeTo(108, 0.01));
        expect(editor.pdfText.selected, isEmpty);

        await tapKey(tester, 'note-tool-undo');
        expect(strokes(), isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a tap picks a word; lines follow a turned page', (
      tester,
    ) async {
      await openSlide(tester);
      editor.rotatePage();
      await tester.pumpAndSettle();
      final at = NotePdfPageMapping(editor.page, origin);

      await tester.tapAt(onPage(tester, at.toPage(words.last.rect.center)));
      await tester.pumpAndSettle();
      expect(editor.pdfText.selectedText, 'conserved');

      await tapKey(tester, 'note-pdf-underline');
      final line = strokes().single;
      expect(line.ink, 'pen');
      // 90° 돌린 쪽에서는 밑줄이 세로로, 낱말 상자의 밑변을 따른다.
      expect(line.points.first.x, closeTo(line.points.last.x, 0.01));
      final bottom = at.toPage(words.last.rect.bottomLeft).dx;
      expect((line.points.first.x - bottom).abs(), lessThan(3));

      await tester.tapAt(onPage(tester, const Offset(20, 20)));
      await tester.pumpAndSettle();
      expect(editor.pdfText.selected, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('only a page still showing its PDF offers text', (
      tester,
    ) async {
      await openSlide(tester);

      editor.setPaper(NotePaperTemplate.grid());
      await tester.pumpAndSettle();
      expect(editor.canSelectPdfText, isFalse);
      expect(find.text('No selectable text on this page'), findsOneWidget);

      editor.undo();
      await tester.pumpAndSettle();
      expect(editor.canSelectPdfText, isTrue);
      expect(find.text('Drag across the text to select it'), findsOneWidget);

      editor.previousPage();
      await tester.pumpAndSettle();
      await tapKey(tester, 'note-top-mode-draw');
      expect(find.byKey(const ValueKey('note-top-mode-pdfText')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a locked layer is not marked', (tester) async {
      await openSlide(tester);
      editor.layers.setLocked(editor.layers.activeLayerId, true);
      await tester.pumpAndSettle();
      await drag(tester, const [Offset(70, 108), Offset(170, 108)]);

      await tapKey(tester, 'note-pdf-strikeout');

      expect(strokes(), isEmpty);
      expect(
        find.text('Show and unlock the layer to mark text'),
        findsOneWidget,
      );
      expect(editor.pdfText.selected, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('recording is added to the page it started on', (tester) async {
    final recordings = NoteRecordingController(player: FakeNoteAudioPlayer());
    addTearDown(recordings.dispose);
    editor.dispose();
    editor = NoteEditorController(
      document: document,
      recordings: recordings,
      autoSaveDelay: null,
    );
    await pump(tester, audioRecorder: FakeNoteAudioRecorder());

    await tapKey(tester, 'note-top-study-menu');
    await tapKey(tester, 'note-top-record');
    await tapKey(tester, 'note-top-add-page');
    await tapKey(tester, 'note-top-stop-recording');

    expect(recordings.recordings.single.pageNumber, 1);
    expect(document.recordingPageNumber(recordings.recordings.single.id), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attachments are added and removed', (tester) async {
    await pump(
      tester,
      onPickAttachment: () async => NoteAttachment(
        id: 'a1',
        kind: NoteAttachmentKind.document,
        source: 'slides.pdf',
        createdAt: DateTime.utc(2026, 11, 26),
      ),
    );

    await tapKey(tester, 'note-top-study-menu');
    await tapKey(tester, 'note-top-attachments');
    await tapKey(tester, 'note-drawer-attach');
    expect(find.text('slides.pdf'), findsOneWidget);

    await tapKey(tester, 'note-drawer-remove-attachment-a1');
    expect(document.attachments.items, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
