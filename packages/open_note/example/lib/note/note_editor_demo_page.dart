import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_note/open_note.dart';

import '../i18n/strings.g.dart';
import 'note_demo_pdf.dart';
import 'note_demo_strings_ko.dart';
import 'note_demo_workspace.dart';

/// 노트를 [NoteWorkspaceView] 로 편집하는 화면 — 탭 · 두 쪽 보기 · 분할.
/// [document] 를 첫 탭으로 열고, 닫을 때 저장 · 색인하고 문서를 해제한다.
class NoteEditorDemoPage extends StatefulWidget {
  const NoteEditorDemoPage({
    required this.library,
    required this.document,
    this.initialPageId,
    super.key,
  });

  final NoteLibrary library;
  final NoteDocument document;
  final String? initialPageId;

  @override
  State<NoteEditorDemoPage> createState() => _NoteEditorDemoPageState();
}

class _NoteEditorDemoPageState extends State<NoteEditorDemoPage> {
  final NoteDemoWorkspace _workspace = NoteDemoWorkspace.instance;

  /// AI 펜 · 녹음 · 재생은 인터페이스만 있다 — 데모는 가짜 구현이다.
  final NoteAiPenService _ai = FakeNoteAiPenService();
  final NoteAudioRecorder _recorder = FakeNoteAudioRecorder();
  final FakeNoteAudioPlayer _player = FakeNoteAudioPlayer();

  /// 녹음 목록은 노트마다 따로다 (편집기가 문서의 목록을 읽어 들인다).
  final Map<String, NoteRecordingController> _recordings = {};

  /// 화면이 닫히기 전에 처음 문서를 한 번만 내준다 (다시 열면 저장소에서).
  late NoteDocument? _first = widget.document;
  late final NoteToolPresetStore _presets = NoteToolPresetStore.defaults(
    strings: _toolsStrings,
  );
  late final NoteToolController _tools = NoteToolController(presets: _presets);
  late final NoteWorkspaceController _notes = NoteWorkspaceController(
    tools: _tools,
    openDocument: _openDocument,
    createEditor: _createEditor,
    onDocumentClosed: _documentClosed,
    onError: (error, _) => _message('$error'),
  );
  NoteToolbarLayout _toolbar = NoteToolbarLayout();
  bool _closing = false;

  bool get _korean => LocaleSettings.currentLocale == AppLocale.ko;

  NoteToolsStrings get _toolsStrings =>
      _korean ? noteToolsStringsKo : const NoteToolsStrings();

  @override
  void initState() {
    super.initState();
    final noteId = widget.document.id;
    _notes.open(
      noteId,
      title: widget.library.noteById(noteId)?.title ?? '',
      pageId: widget.initialPageId,
    );
  }

  @override
  void dispose() {
    // 화면이 걷히는 중에는 목록을 갱신하지 않는다 (닫을 때 이미 남긴다).
    _closing = true;
    _notes.dispose();
    for (final recordings in _recordings.values) {
      recordings.dispose();
    }
    _tools.dispose();
    _presets.dispose();
    _player.dispose();
    _first?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final korean = context.t.$meta.locale == AppLocale.ko;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        body: SafeArea(
          child: NoteWorkspaceView(
            controller: _notes,
            strings: korean
                ? noteWorkspaceStringsKo
                : const NoteWorkspaceStrings(),
            viewStrings: korean ? noteViewStringsKo : const NoteViewStrings(),
            onPickNote: _pickNote,
            paneBuilder: (context, editor, paneId) =>
                _editorView(editor, korean: korean),
          ),
        ),
      ),
    );
  }

  Widget _editorView(NoteEditorController editor, {required bool korean}) =>
      NoteEditorView(
        controller: editor,
        strings: korean ? noteEditorStringsKo : const NoteEditorStrings(),
        toolbarLayout: _toolbar,
        onToolbarLayoutChanged: (layout) => setState(() => _toolbar = layout),
        stickerStore: _workspace.stickers,
        imageProviderResolver: _workspace.imageProvider,
        onPickImages: _workspace.samplePictures,
        onStoreImage: _workspace.storeImage,
        aiPenService: _ai,
        audioRecorder: _recorder,
        onPickAttachment: _pickAttachment,
        onOpenAttachment: (attachment) => _message(attachment.source),
        onImportPages: () => _importPages(editor),
        studyWindows: [
          NoteFloatingWindowSpec(
            id: 'web',
            title: korean ? '웹 · ChatGPT' : 'Web · ChatGPT',
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  korean ? '앱이 쓰는 웹뷰를 여기에 넣습니다.' : 'Put your web view here.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
        onBack: () => unawaited(_close()),
        onExport: () => unawaited(_export(editor)),
      );

  Future<NoteDocument?> _openDocument(String noteId) async {
    final first = _first;
    if (first != null && first.id == noteId) {
      _first = null;

      return first;
    }
    final note = widget.library.noteById(noteId);

    return note == null ? null : _workspace.open(note);
  }

  NoteEditorController _createEditor(
    NoteDocument document,
    NoteToolController tools,
    String initialPageId,
  ) => NoteEditorController(
    document: document,
    tools: tools,
    repository: _workspace.documents,
    recordings: _recordings.putIfAbsent(
      document.id,
      () => NoteRecordingController(player: _player),
    ),
    tableSelection: _workspace.tableSelection,
    pdfTextLayer: _workspace.pdfTextLayer,
    layerName: (number) => _korean ? '레이어 $number' : 'Layer $number',
    objectStrings: _korean ? noteObjectsStringsKo : const NoteObjectsStrings(),
    initialPageId: initialPageId,
    onOpenUrl: _message,
    onOpenNote: _openLinkedNote,
  );

  /// 다른 노트로 가는 링크는 새 탭으로 연다.
  void _openLinkedNote(String noteId, String? pageId) {
    final note = widget.library.noteById(noteId);
    if (note == null) {
      _message(noteId);

      return;
    }
    _notes.open(noteId, title: note.title, pageId: pageId);
  }

  void _documentClosed(String noteId, NoteDocument document) {
    if (!_closing) _record(document);
    _recordings.remove(noteId)?.dispose();
    document.dispose();
  }

  /// 목록과 검색 색인에 노트의 지금 모습을 남긴다.
  void _record(NoteDocument document) {
    _workspace.index(document);
    widget.library.touch(document.id, pageCount: document.pageCount);
  }

  Future<NoteTab?> _pickNote() async {
    final note = await showDialog<NoteSummary>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(_korean ? '어느 노트를 열까요?' : 'Open which note?'),
        children: [
          for (final note in widget.library.notes)
            if (!_notes.tabs.contains(note.id))
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(note),
                child: Text(note.title),
              ),
        ],
      ),
    );

    return note == null ? null : NoteTab(noteId: note.id, title: note.title);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    try {
      await _notes.save();
    } on Object catch (error) {
      _message('$error');
    }
    for (final tab in _notes.tabs.tabs) {
      final document = _notes.documentOf(tab.noteId);
      if (document != null) _record(document);
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// 파일 선택기 대신 견본 첨부를 하나 만든다.
  Future<NoteAttachment?> _pickAttachment() async => NoteAttachment(
    id: generateNoteId(),
    kind: NoteAttachmentKind.document,
    source: _korean ? '강의 자료.pdf' : 'slides.pdf',
    createdAt: systemNoteClock(),
  );

  /// 샘플 PDF 를 가져오거나, 다른 노트를 고르고 가져올 쪽을 고른다.
  Future<void> _importPages(NoteEditorController editor) async {
    final others = [
      for (final note in widget.library.notes)
        if (note.id != editor.document.id) note,
    ];
    final choice = await showDialog<Object>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(_korean ? '어디에서 가져올까요?' : 'Import from?'),
        children: [
          SimpleDialogOption(
            key: const ValueKey('note-demo-import-pdf'),
            onPressed: () => Navigator.of(context).pop(NoteDemoPdf.name),
            child: Text(
              _korean ? '샘플 PDF (글자 선택 가능)' : 'Sample PDF (selectable text)',
            ),
          ),
          for (final note in others)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(note),
              child: Text(note.title),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == NoteDemoPdf.name) {
      final pages = await _workspace.samplePdfPages();
      if (mounted) {
        editor.insertPages(pages, position: NotePageInsertPosition.after);
      }

      return;
    }
    if (choice is! NoteSummary) return;
    final note = choice;
    final source = await _workspace.open(note);
    try {
      if (!mounted) return;
      final pageIds = await showDialog<List<String>>(
        context: context,
        builder: (context) =>
            _PagePickerDialog(document: source, korean: _korean),
      );
      if (pageIds != null && mounted) {
        editor.importPages(source, pageIds);
      }
    } finally {
      source.dispose();
    }
  }

  Future<void> _export(NoteEditorController editor) async {
    editor.commit();
    final bytes = await exportNotePdf(
      editor.document,
      imageProviderResolver: _workspace.imageProvider,
    );
    final size = (bytes.length / 1024).ceil();
    _message(_korean ? 'PDF 를 만들었습니다 ($size KB)' : 'PDF created ($size KB)');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// 가져올 쪽 고르기 — 처음에는 모두 골라 둔다.
class _PagePickerDialog extends StatefulWidget {
  const _PagePickerDialog({required this.document, required this.korean});

  final NoteDocument document;
  final bool korean;

  @override
  State<_PagePickerDialog> createState() => _PagePickerDialogState();
}

class _PagePickerDialogState extends State<_PagePickerDialog> {
  late final Set<String> _picked = {...widget.document.pageIds};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.korean ? '가져올 쪽' : 'Pages to import'),
    content: SizedBox(
      width: 320,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final pageId in widget.document.pageIds)
            CheckboxListTile(
              value: _picked.contains(pageId),
              title: Text(
                NoteEditorStrings.defaultPageOption(
                  widget.document.labelOf(pageId),
                ),
              ),
              onChanged: (value) => setState(
                () => value == true
                    ? _picked.add(pageId)
                    : _picked.remove(pageId),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.korean ? '취소' : 'Cancel'),
      ),
      FilledButton(
        key: const ValueKey('note-demo-import-confirm'),
        onPressed: _picked.isEmpty
            ? null
            : () => Navigator.of(context).pop([
                for (final pageId in widget.document.pageIds)
                  if (_picked.contains(pageId)) pageId,
              ]),
        child: Text(widget.korean ? '가져오기' : 'Import'),
      ),
    ],
  );
}
