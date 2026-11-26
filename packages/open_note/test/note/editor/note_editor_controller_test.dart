import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/editor/editor.dart';
import 'package:open_note/src/note/nav/nav.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';
import 'package:open_note/src/note/study/utilities/fake_note_audio_player.dart';
import 'package:open_note/src/note/study/utilities/note_recording_controller.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/style/note_image_crop.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

Stroke _line(String id, double y, {int color = 0xFF000000}) => Stroke(
  id: id,
  ink: 'pen',
  color: color,
  width: 2,
  options: StrokeOptions(size: 2),
  points: [
    Point(x: 20, y: y, p: 0.5),
    Point(x: 120, y: y, p: 0.5),
  ],
);

NoteIdFactory _ids() {
  var next = 0;

  return () => 'n${++next}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NoteDocument document;
  late NoteEditorController editor;

  NoteDocument newDocument() => NoteDocument(
    id: 'note',
    registry: standardNoteObjectRegistry(),
    defaultTemplate: NotePaperTemplate.lined(),
    idFactory: _ids(),
  );

  setUp(() {
    document = newDocument();
    editor = NoteEditorController(document: document, autoSaveDelay: null);
  });

  tearDown(() {
    editor.dispose();
    document.dispose();
  });

  /// Draws a stroke on the active layer, as a finished gesture would.
  void draw(Stroke stroke) {
    final notifier = editor.layers.activeNotifier;
    notifier.setScribble(
      scribble: notifier.currentScribble.deepCopy()..strokes.add(stroke),
    );
  }

  List<String> strokeIds(NotePage page) => [
    for (final content in page.layers)
      for (final stroke in content.scribble.strokes) stroke.id,
  ];

  group('pages', () {
    test('ink is committed when leaving a page and comes back', () {
      final first = editor.pageId;
      draw(_line('a', 40));
      expect(strokeIds(document.page(first)!), isEmpty);

      final second = editor.addPage();

      expect(editor.pageId, second.id);
      expect(strokeIds(document.page(first)!), ['a']);
      expect(editor.previousPage(), isTrue);
      expect(strokeIds(editor.page), ['a']);
      expect(editor.previousPage(), isFalse);
    });

    test('undo and redo belong to the open page', () {
      draw(_line('a', 40));
      expect(editor.canUndo, isTrue);

      editor.undo();
      expect(strokeIds(editor.page), isEmpty);
      editor.redo();
      expect(strokeIds(editor.page), ['a']);
    });

    test('adding before and at the end', () {
      final first = editor.pageId;
      final before = editor.addPage(position: NotePageInsertPosition.before);
      editor.goToPage(first);
      final last = editor.addPage(position: NotePageInsertPosition.end);

      expect(document.pageIds, [before.id, first, last.id]);
    });

    test('removing the open page shows a neighbour; restore shows it', () {
      draw(_line('a', 40));
      final first = editor.pageId;
      final second = editor.addPage().id;
      editor.goToPage(first);

      expect(editor.removePage(), isTrue);
      expect(editor.pageId, second);
      expect(editor.removePage(), isFalse);
      expect(editor.restorePage(first), isTrue);
      expect(editor.pageId, first);
      expect(strokeIds(editor.page), ['a']);
    });

    test('rotation is one undo step with the ink', () {
      draw(_line('a', 40));
      final size = editor.page.size;

      editor.rotatePage();

      expect(editor.page.size, size.rotated);
      expect(strokeIds(editor.page), ['a']);
      Point first() =>
          editor.page.layers.single.scribble.strokes.single.points.first;
      expect(first().x, closeTo(size.height - 40, 0.001));

      editor.undo();
      expect(editor.page.size, size);
      expect(editor.page.paperTurns, 0);
      expect(first().x, closeTo(20, 0.001));
      expect(first().y, closeTo(40, 0.001));
      // 필기 기록은 남아 있다.
      editor.undo();
      expect(strokeIds(editor.page), isEmpty);
      editor
        ..redo()
        ..redo();
      expect(editor.page.size, size.rotated);
      expect(first().x, closeTo(size.height - 40, 0.001));
      editor.commit();
      expect(document.page(editor.pageId)!.size, size.rotated);
    });

    test('margins widen the page and undo brings the ink back', () {
      draw(_line('a', 40));
      final size = editor.page.size;

      editor.extendMargin(NoteMarginSide.left, 120);

      expect(editor.page.size.width, size.width + 120);
      expect(editor.page.margins, const EdgeInsets.only(left: 120));
      Point first() =>
          editor.page.layers.single.scribble.strokes.single.points.first;
      expect(first().x, closeTo(140, 0.001));

      editor.undo();
      expect(editor.page.size, size);
      expect(editor.page.margins, EdgeInsets.zero);
      expect(first().x, closeTo(20, 0.001));
    });

    test('a page without ink keeps rotation as one step', () {
      final size = editor.page.size;

      editor
        ..rotatePage()
        ..undo();

      expect(editor.page.size, size);
      expect(editor.canUndo, isFalse);
      expect(editor.canRedo, isTrue);
    });

    test('a paper change is one undo step', () {
      final lined = editor.page.template;

      editor.setPaper(NotePaperTemplate.grid());

      expect(editor.page.template.kind, NotePaperTemplate.grid().kind);
      editor.undo();
      expect(editor.page.template, lined);
    });

    test('writing near the edge grows an endless page in the same step', () {
      final size = editor.page.size;
      // 왼쪽 가장자리에서 떨어진 획.
      Stroke inner(String id, double y) => _line(id, y).deepCopy()
        ..points.first.x = 120
        ..points.last.x = 220;
      editor.setEndlessPage(true);
      draw(inner('a', 400));
      expect(editor.growAfterWriting(), isFalse);

      draw(inner('b', size.height - 20));
      expect(editor.growAfterWriting(), isTrue);
      expect(editor.page.size.height, size.height + 400);
      expect(editor.page.size.width, size.width);
      // 같은 필기로 두 번 늘리지 않는다.
      expect(editor.growAfterWriting(), isFalse);

      editor.undo();
      expect(strokeIds(editor.page), ['a']);
      expect(editor.page.size, size);
      // 되돌린 뒤에는 다시 늘리지 않아 다시 실행할 수 있다.
      expect(editor.growAfterWriting(), isFalse);
      editor.redo();
      expect(editor.growAfterWriting(), isFalse);
      expect(strokeIds(editor.page), ['a', 'b']);
      expect(editor.page.size.height, size.height + 400);
    });

    test('writing near the left or top edge moves the content along', () {
      final size = editor.page.size;
      editor.setEndlessPage(true);
      draw(_line('a', 10).deepCopy()..points.first.x = 5);

      expect(editor.growAfterWriting(), isTrue);

      expect(editor.page.margins.left, 400);
      expect(editor.page.margins.top, 400);
      expect(editor.page.size.width, size.width + 400);
      final point =
          editor.page.layers.single.scribble.strokes.single.points.first;
      expect(point.x, closeTo(405, 0.001));
      expect(point.y, closeTo(410, 0.001));
      editor.undo();
      expect(strokeIds(editor.page), isEmpty);
      expect(editor.page.size, size);
    });

    test('other edits do not grow an endless page', () {
      editor.setEndlessPage(true);
      draw(_line('a', 40));
      editor.growAfterWriting();
      final size = editor.page.size;

      // 가장자리 가까이의 객체 추가나 쪽 설정 변경은 필기가 아니다.
      editor
        ..addObject(
          const NoteStickyObject(
            id: 'sticky',
            bounds: Rect.fromLTWH(2, 2, 80, 80),
          ),
        )
        ..setPaper(NotePaperTemplate.dotted());

      expect(editor.growAfterWriting(), isFalse);
      expect(editor.page.size, size);
    });

    test('an endless page grows on request and is saved', () {
      final size = editor.page.size;
      expect(
        editor.growEndlessPage(Rect.fromLTWH(size.width - 10, 40, 5, 5)),
        isFalse,
      );

      editor.setEndlessPage(true);
      expect(
        editor.growEndlessPage(const Rect.fromLTWH(40, 40, 50, 50)),
        isFalse,
      );
      expect(
        editor.growEndlessPage(
          Rect.fromLTWH(40, 40, size.width - 60, size.height + 300),
        ),
        isTrue,
      );

      expect(editor.page.size.width, size.width + 400);
      expect(editor.page.size.height, size.height + 800);
      editor.commit();
      expect(document.page(editor.pageId)!.autoGrows, isTrue);
      expect(document.page(editor.pageId)!.size, editor.page.size);
      editor.undo();
      expect(editor.page.size, size);
    });

    test('a change made to the document directly is adopted', () {
      document.setTemplate([editor.pageId], NotePaperTemplate.dotted());

      expect(editor.page.template.kind, NotePaperTemplate.dotted().kind);
    });

    test('pages from another note are imported after the current one', () {
      final source = NoteDocument(
        id: 'other',
        registry: document.registry,
        idFactory: () => 'x',
      );
      addTearDown(source.dispose);

      final imported = editor.importPages(source, source.pageIds);

      expect(imported, hasLength(1));
      expect(editor.pageId, imported.single.id);
      expect(editor.pageIndex, 1);
    });
  });

  group('lasso, layers and images', () {
    test('restyle and outline change the selected strokes', () {
      draw(_line('a', 40));
      draw(_line('b', 80));
      editor.lassoSelection.publish([1], const []);

      expect(
        editor.restyleSelection(color: const Color(0xFFFF0000), width: 5),
        isTrue,
      );
      final strokes = editor.layers.activeNotifier.currentScribble.strokes;
      expect(strokes[1].color, 0xFFFF0000);
      expect(strokes[1].width, 5);
      expect(strokes[0].color, 0xFF000000);

      expect(editor.outlineSelection(color: const Color(0xFF00FF00)), isTrue);
      expect(
        editor.layers.activeNotifier.currentScribble.strokes,
        hasLength(3),
      );
      expect(editor.lassoSelection.isEmpty, isTrue);
    });

    test('the selection moves to another layer in one step', () {
      draw(_line('a', 40));
      final bottom = editor.layers.activeLayerId;
      final top = editor.layers.addLayer().id;
      editor.layers.setActive(bottom);
      editor.lassoSelection.publish([0], const []);

      expect(editor.moveSelectionToLayer(top), isTrue);

      expect(editor.layers.scribbleOf(bottom).strokes, isEmpty);
      expect(editor.layers.scribbleOf(top).strokes.single.id, 'a');
      editor.undo();
      expect(editor.layers.scribbleOf(bottom).strokes.single.id, 'a');
    });

    test('pictures fit a grid inside the page and undo together', () {
      final ids = editor.insertImages(const [
        NoteImageInsert('a.png', Size(4000, 3000)),
        NoteImageInsert('b.png', Size(100, 100)),
        NoteImageInsert('c.png', Size(300, 900)),
      ]);

      final images =
          editor.layers.activeNotifier.currentScribble.imageDrawables;
      expect([for (final image in images) image.id], ids);
      final area = Offset.zero & editor.page.size.toSize();
      for (final image in images) {
        expect(
          area.contains(Offset(image.x + image.width, image.y + image.height)),
          isTrue,
        );
      }
      // Small pictures are not enlarged; large ones keep their aspect.
      expect(images[1].width, 100);
      expect(images[0].width / images[0].height, closeTo(4 / 3, 0.01));
      expect(editor.tools.currentTool, 'image');

      editor.undo();
      expect(
        editor.layers.activeNotifier.currentScribble.imageDrawables,
        isEmpty,
      );
    });

    test('the selected picture takes a frame; plain clears it', () {
      final id = editor.insertImages(const [
        NoteImageInsert('a.png', Size(100, 100)),
      ]).single;
      editor.selectImage(id);
      final framed = NoteImageStyle(borderColor: const Color(0xFF000000));

      expect(editor.styleSelectedImage(framed), isTrue);
      expect(NoteImageStyle.decode(editor.selectedImage!.imageStyle), framed);

      editor.styleSelectedImage(NoteImageStyle.plain);
      expect(editor.selectedImage!.hasImageStyle(), isFalse);
    });

    test('cropping trims the picture where it is; undoing it restores', () {
      final id = editor.insertImages(const [
        NoteImageInsert('a.png', Size(200, 100)),
      ]).single;
      editor.selectImage(id);
      final before = editor.selectedImage!.deepCopy();

      editor.styleSelectedImage(
        NoteImageStyle(crop: NoteImageCrop.rect(0.5, 0, 1, 0.5)),
      );

      var image = editor.selectedImage!;
      expect(image.width, closeTo(before.width / 2, 0.001));
      expect(image.height, closeTo(before.height / 2, 0.001));
      expect(image.x, closeTo(before.x + before.width / 2, 0.001));
      expect(image.y, closeTo(before.y, 0.001));

      editor.styleSelectedImage(NoteImageStyle.plain);
      image = editor.selectedImage!;
      expect(image.width, closeTo(before.width, 0.001));
      expect(image.x, closeTo(before.x, 0.001));
    });
  });

  group('objects', () {
    NoteStickyObject sticky() => NoteStickyObject(
      id: editor.newId(),
      bounds: editor.placement(const Size(150, 120)),
      text: 'Formula',
    );

    test('adding switches to object mode and undo removes it', () {
      expect(editor.addObject(sticky()), isTrue);

      expect(editor.mode, NoteEditorMode.objects);
      expect(editor.page.objects, hasLength(1));
      expect(editor.session.objects.selectedIds, hasLength(1));
      editor.undo();
      expect(editor.page.objects, isEmpty);
    });

    test('every shipped kind can be duplicated, tables included', () {
      editor.addObject(
        NoteTableObject.grid(
          id: 'table',
          bounds: const Rect.fromLTWH(10, 10, 200, 90),
        ),
      );

      final copies = editor.session.objects.duplicate(['table']);

      expect(copies, hasLength(1));
      expect(editor.page.objects.whereType<NoteTableObject>(), hasLength(2));
    });

    test('placement stays on the page', () {
      final size = editor.page.size.toSize();

      final rect = editor.placement(
        const Size(100, 100),
        center: const Offset(-40, 10000),
      );

      expect(rect.left, 0);
      expect(rect.bottom, size.height);
    });

    test('every-page masks are stored on the note', () {
      final mask = NoteMaskObject(
        id: 'm',
        bounds: const Rect.fromLTWH(10, 10, 80, 30),
        scope: NoteMaskScope.document,
      );

      editor
        ..addMask(mask)
        ..addPage();

      expect(document.documentObjects.single.id, 'm');
      expect(editor.session.shared.objects.single.id, 'm');
      editor.setMasksRevealed(true);
      editor.commit();
      expect(
        (document.documentObjects.single as NoteMaskObject).revealed,
        isTrue,
      );
      editor.clearMasks();
      editor.commit();
      expect(document.documentObjects, isEmpty);
    });

    test('page links follow reordering', () {
      final first = editor.pageId;
      final second = editor.addPage().id;
      final link = editor.pageLink(second);
      editor.goToPage(first);
      editor.movePage(second, 0);

      expect(editor.followRawLink(link), isTrue);
      expect(editor.pageId, second);
      expect(editor.followRawLink('page:2'), isTrue);
      expect(editor.pageId, first);
    });

    test('search finds typed text of every page', () {
      editor.addObject(sticky());
      editor.addPage();
      draw(_line('a', 40));
      final notifier = editor.layers.activeNotifier;
      notifier.setScribble(
        scribble: notifier.currentScribble.deepCopy()
          ..textDrawables.add(
            TextDrawable(id: 't', text: 'Lecture 3', x: 10, y: 10),
          ),
      );
      final index = NoteSearchIndex();
      addTearDown(index.dispose);

      editor.indexInto(index);

      expect(index.search('formula').single.pageId, document.pageIds.first);
      expect(index.search('lecture').single.pageId, editor.pageId);
    });
  });

  test('recordings follow their page through page operations', () {
    final recordings = NoteRecordingController(player: FakeNoteAudioPlayer());
    addTearDown(recordings.dispose);
    editor.dispose();
    document.recordings = {
      'recordings': [
        {'id': 'r', 'source': 'a.m4a', 'pageNumber': 1},
      ],
    };
    editor = NoteEditorController(
      document: document,
      recordings: recordings,
      autoSaveDelay: null,
    );

    editor.addPage(position: NotePageInsertPosition.before);
    expect(recordings.recordings.single.pageNumber, 2);

    editor.removePage(document.pageIds.last);
    expect(recordings.recordings.single.pageNumber, isNull);
    editor.restorePage(document.trashedPages.single.page.id);
    expect(recordings.recordings.single.pageNumber, 2);

    recordings.rename('r', 'Lecture');
    expect(
      (document.recordings['recordings']! as List).single,
      containsPair('title', 'Lecture'),
    );
  });

  test('editors side by side share one tool controller', () {
    final tools = NoteToolController();
    addTearDown(tools.dispose);
    final other = newDocument();
    addTearDown(other.dispose);
    final left = NoteEditorController(
      document: document,
      tools: tools,
      autoSaveDelay: null,
    );
    final right = NoteEditorController(
      document: other,
      tools: tools,
      autoSaveDelay: null,
    );
    addTearDown(right.dispose);

    tools.setLineStyle('dashed');

    expect(left.modeNotifier.state.inputOptions.lineStyle, 'dashed');
    expect(right.modeNotifier.state.inputOptions.lineStyle, 'dashed');

    left.dispose();
    tools.setLineStyle('dotted');

    expect(right.modeNotifier.state.inputOptions.lineStyle, 'dotted');
    expect(tools.onUndo, isNotNull);
  });

  testWidgets('autosave writes changes after the delay', (tester) async {
    final store = MemoryNoteStore();
    final saved = newDocument();
    addTearDown(saved.dispose);
    final autosaving = NoteEditorController(
      document: saved,
      repository: NoteDocumentRepository(store, registry: saved.registry),
      autoSaveDelay: const Duration(seconds: 2),
    );
    addTearDown(autosaving.dispose);
    final notifier = autosaving.layers.activeNotifier;
    notifier.setScribble(
      scribble: notifier.currentScribble.deepCopy()
        ..strokes.add(_line('a', 40)),
    );
    expect(autosaving.hasUnsavedChanges, isTrue);

    await tester.pump(const Duration(seconds: 1));
    expect(await store.exists('notes/note/note.json'), isFalse);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(await store.exists('notes/note/note.json'), isTrue);
    expect(autosaving.hasUnsavedChanges, isFalse);
    final loaded = (await NoteDocumentRepository(
      store,
      registry: saved.registry,
    ).load('note'))!;
    addTearDown(loaded.document.dispose);
    expect(strokeIds(loaded.document.pageAt(0)), ['a']);
  });

  testWidgets('a failed save is reported and later saves work', (tester) async {
    final store = _FailingStore();
    final saved = newDocument();
    addTearDown(saved.dispose);
    final autosaving = NoteEditorController(
      document: saved,
      repository: NoteDocumentRepository(store, registry: saved.registry),
      autoSaveDelay: const Duration(seconds: 1),
    );
    addTearDown(autosaving.dispose);
    store.failing = true;
    saved.title = 'changed';

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(autosaving.saveError, isA<StateError>());
    await expectLater(autosaving.save(), throwsStateError);

    store.failing = false;
    await autosaving.save();
    expect(autosaving.saveError, isNull);
    expect(autosaving.hasUnsavedChanges, isFalse);
  });
}

class _FailingStore extends MemoryNoteStore {
  bool failing = false;

  @override
  Future<List<String>> list(String prefix) {
    if (failing) throw StateError('store offline');

    return super.list(prefix);
  }
}
