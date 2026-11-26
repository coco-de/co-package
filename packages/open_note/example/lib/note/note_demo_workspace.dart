import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/open_note.dart';

import '../i18n/strings.g.dart';
import 'note_demo_pdf.dart';
import 'note_demo_strings_ko.dart';

/// 노트 데모의 작업 공간 — 라이브러리 · 문서 저장소 · 스티커 · 검색 색인을
/// 앱이 켜져 있는 동안 유지한다. 웹에서도 돌도록 [MemoryNoteStore] 에만
/// 저장한다 (실제 앱은 `FileNoteStore` 나 자체 `NoteStore` 를 쓴다).
class NoteDemoWorkspace {
  NoteDemoWorkspace._();

  /// 데모 전체가 함께 쓰는 작업 공간.
  static NoteDemoWorkspace get instance => _instance;
  static NoteDemoWorkspace _instance = NoteDemoWorkspace._();

  /// 테스트마다 새로 시작한다 — 캐시한 Future 는 만든 테스트의 zone 에 묶인다.
  @visibleForTesting
  static void resetForTest() => _instance = NoteDemoWorkspace._();

  static const String _imagePrefix = 'demo-image:';

  final MemoryNoteStore store = MemoryNoteStore();

  /// 만들 때의 언어 — 객체 보기와 스티커 모음 이름이 따른다.
  final bool _korean = LocaleSettings.currentLocale == AppLocale.ko;

  NoteObjectsStrings get _objectStrings =>
      _korean ? noteObjectsStringsKo : const NoteObjectsStrings();

  /// 표 보기와 편집기 표 도구가 같은 선택을 쓴다.
  final NoteTableSelectionController tableSelection =
      NoteTableSelectionController();

  late final NoteObjectRegistry registry = standardNoteObjectRegistry(
    tableSelection: tableSelection,
    objectStrings: _objectStrings,
    tableStrings: _korean ? noteTableStringsKo : const NoteTableStrings(),
    studyStrings: _korean
        ? noteStudyOverlayStringsKo
        : const NoteStudyOverlayStrings(),
    stickerImageResolver: imageProvider,
    maskImageResolver: imageProvider,
  );

  late final NoteDocumentRepository documents = NoteDocumentRepository(
    store,
    registry: registry,
  );

  late final NoteStickerStore stickers = NoteStickerStore(
    strings: _objectStrings,
  );

  /// "샘플 PDF" 가져오기의 렌더러이자 글자 층.
  final NoteDemoPdf samplePdf = NoteDemoPdf();

  /// PDF 에서 온 쪽의 글자 층 — 샘플 PDF 만 글자를 알려 준다.
  NotePdfTextLayer? pdfTextLayer(String document) =>
      document == NoteDemoPdf.name ? samplePdf : null;

  /// 샘플 PDF 를 노트 쪽으로 바꾼다.
  Future<List<NotePage>> samplePdfPages() async {
    final imported = await NotePdfRendererImporter(
      samplePdf,
    ).import(NoteImportSource(name: NoteDemoPdf.name, bytes: Uint8List(0)));

    return notePagesFromImport(
      imported,
      storeImage: (png, _) => storeImage(png),
    );
  }

  /// 입력한 글(글상자 · 메모 · 표)을 찾는다. 손글씨 검색은 호스트의
  /// `NoteHandwritingIndexer` 몫이다.
  final NoteSearchIndex searchIndex = NoteSearchIndex();

  final Map<String, Uint8List> _images = {};
  Future<NoteLibrary>? _library;

  Future<NoteLibrary> library() => _library ??= _loadLibrary();

  /// 캡처 · 샘플 사진은 메모리에, 그 밖의 source 는 엔진 규칙대로 연다.
  ImageProvider imageProvider(String source) {
    final bytes = _images[source];

    return bytes != null ? MemoryImage(bytes) : resolveImageSource(source);
  }

  Future<String> storeImage(Uint8List png) async {
    final source = '$_imagePrefix${_images.length + 1}';
    _images[source] = png;

    return source;
  }

  /// "사진 추가" 데모 — 파일 선택기 대신 즉석에서 그린 사진 두 장.
  Future<List<NoteImageInsert>> samplePictures() async {
    const size = Size(480, 320);
    final pictures = <NoteImageInsert>[];
    for (final colors in const [
      [Color(0xFF42A5F5), Color(0xFF7E57C2)],
      [Color(0xFFFFB74D), Color(0xFFEF5350)],
    ]) {
      final png = await _gradientPng(size, colors);
      pictures.add(NoteImageInsert(await storeImage(png), size));
    }

    return pictures;
  }

  /// 노트를 연다 — 저장한 적이 없으면 줄 노트 한 쪽으로 시작한다.
  Future<NoteDocument> open(NoteSummary note) async {
    final loaded = await documents.load(note.id);

    return loaded?.document ??
        NoteDocument(
          id: note.id,
          registry: registry,
          title: note.title,
          defaultTemplate: NotePaperTemplate.lined(),
        );
  }

  /// 저장된 노트의 모든 쪽을 검색 색인에 넣는다.
  void index(NoteDocument document) {
    searchIndex.removeNote(document.id);
    for (final page in document.pages) {
      searchIndex.indexPage(document.id, page.id, notePageTexts(page));
    }
  }

  Future<NoteLibrary> _loadLibrary() async {
    final repository = NoteLibraryRepository(store);
    final library = await repository.load(
      onNotesRemoved: (ids) {
        for (final id in ids) {
          searchIndex.removeNote(id);
          documents.delete(id);
        }
      },
      onNotesDuplicated: (copies) {
        for (final copy in copies.entries) {
          documents.duplicate(copy.key, copy.value);
        }
      },
    );
    repository.bind(library);
    if (library.notes.isEmpty) await _seed(library);

    return library;
  }

  /// 처음 열면 바로 눌러 볼 수 있는 안내 노트와 폴더를 만든다.
  Future<void> _seed(NoteLibrary library) async {
    final folder = library.createFolder('강의');
    library.createNote(title: '빈 노트', folderId: folder.id);
    final tour = library.createNote(title: 'open_note 둘러보기');
    final document = NoteDocument(
      id: tour.id,
      registry: registry,
      title: tour.title,
      defaultTemplate: NotePaperTemplate.lined(),
    );
    final first = document.pageIds.single;
    final second = document.addPage(template: NotePaperTemplate.grid()).id;
    document.addPage(template: NotePaperTemplate.cornell());

    var table = NoteTableObject.grid(
      id: generateNoteId(),
      bounds: const Rect.fromLTWH(60, 360, 470, 150),
    );
    const cells = [
      ['도구', '무엇', '어디'],
      ['펜', '점선 · 물결 · 필압', '위 도구 줄'],
      ['가리개', '탭하면 보임', '가리기 모드'],
    ];
    for (var row = 0; row < cells.length; row++) {
      for (var column = 0; column < cells[row].length; column++) {
        table = table.setCellText(row, column, cells[row][column]);
      }
    }
    final intro = document.page(first)!;
    final introInk = intro.layers.single.scribble.deepCopy()
      ..textDrawables.add(
        TextDrawable(
          id: generateNoteId(),
          text: '2쪽으로 가기 (읽기 모드에서 누르기)',
          x: 345,
          y: 205,
          fontSize: 12,
          color: 0xFF1E88E5,
          textAlign: 'left',
        ),
      );
    document.replacePage(
      intro.copyWith(
        layers: [intro.layers.single.copyWith(scribble: introInk)],
        objects: [
          NoteStickyObject(
            id: generateNoteId(),
            bounds: const Rect.fromLTWH(60, 90, 260, 170),
            text: '스타일러스로 써 보세요.\n"선택" 모드에서 메모 · 표 · 화살표를 옮깁니다.',
          ),
          NoteLinkObject(
            id: generateNoteId(),
            bounds: const Rect.fromLTWH(340, 150, 190, 44),
            target: NotePageIdLink(second).format(),
          ),
          table,
        ],
      ),
    );
    final grid = document.page(second)!;
    final scribble = grid.layers.single.scribble.deepCopy()
      ..textDrawables.add(
        TextDrawable(
          id: generateNoteId(),
          text: '정의: 가리개로 덮고 외우기',
          x: 80,
          y: 140,
          fontSize: 20,
          color: 0xFF212121,
          textAlign: 'left',
        ),
      );
    document.replacePage(
      grid.copyWith(
        layers: [grid.layers.single.copyWith(scribble: scribble)],
        objects: [
          NoteMaskObject(
            id: generateNoteId(),
            bounds: const Rect.fromLTWH(70, 120, 300, 40),
          ),
        ],
      ),
    );
    document.bookmarks.toggle(second, title: '암기');
    document.outline.add('안내', first);
    await documents.save(document);
    index(document);
    library.touch(tour.id, pageCount: document.pageCount);
    document.dispose();
  }

  static Future<Uint8List> _gradientPng(Size size, List<Color> colors) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, colors),
    );
    canvas.drawCircle(
      rect.center,
      size.height / 4,
      Paint()..color = const Color(0x66FFFFFF),
    );
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return data!.buffer.asUint8List();
  }
}
