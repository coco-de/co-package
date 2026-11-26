import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:open_note/src/note/document/note_document.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_tool_controller.dart';
import 'package:open_note/src/note/view/note_tabs_controller.dart';
import 'package:open_note/src/note/view/note_view_layout_controller.dart';
import 'package:open_note/src/note/view/note_view_pane.dart';

/// Opens the note [noteId]; null when it no longer exists.
typedef NoteWorkspaceOpener = Future<NoteDocument?> Function(String noteId);

/// Creates the editor of one pane, starting on [initialPageId]. Pass [tools]
/// to it: panes share one tool state because the engine's is global.
typedef NoteWorkspaceEditorFactory =
    NoteEditorController Function(
      NoteDocument document,
      NoteToolController tools,
      String initialPageId,
    );

/// What a workspace pane shows.
enum NoteWorkspacePaneStatus {
  /// No note is assigned.
  empty,

  /// The note is being opened.
  loading,

  /// Opening threw; see [NoteWorkspaceController.errorOf].
  failed,

  /// The note no longer exists.
  missing,

  /// The page after the last one: the right side of a two-page spread.
  pastEnd,

  /// An editor shows the pane's page.
  ready,
}

/// Several editors on one screen: tabs of open notes and the panes of
/// [NoteViewMode] (one page, a two-page spread, two views of one note, two
/// notes, or a split).
///
/// Each pane has its own [NoteEditorController]; they share [tools] and one
/// document per note. A finished edit is committed to the document right away
/// when another pane has the same note, so that pane shows it. A pane on the
/// same page as the focused one only follows along ([needsFocusFirst]), so one
/// page is never edited in two places at once.
class NoteWorkspaceController extends ChangeNotifier {
  NoteWorkspaceController({
    required this.openDocument,
    required this.createEditor,
    this.onDocumentClosed,
    this.onError,
    NoteToolController? tools,
    NoteViewLayoutController? layout,
    NoteTabsController? tabs,
  }) : tools = tools ?? NoteToolController(),
       _ownsTools = tools == null,
       layout = layout ?? NoteViewLayoutController(),
       _ownsLayout = layout == null,
       tabs = tabs ?? NoteTabsController(),
       _ownsTabs = tabs == null {
    _focusedPaneId = this.layout.panes.first.id;
    _hostPalette = this.tools.onShowToolPalette;
    this.layout.addListener(_onLayout);
    this.tabs.addListener(notifyListeners);
    _apply();
  }

  final NoteWorkspaceOpener openDocument;
  final NoteWorkspaceEditorFactory createEditor;

  /// Called once no tab and no pane uses a document any more, after its
  /// editors saved; dispose it here if you created it.
  final void Function(String noteId, NoteDocument document)? onDocumentClosed;

  /// Failures to open or save a note.
  final void Function(Object error, StackTrace stack)? onError;

  final NoteToolController tools;
  final NoteViewLayoutController layout;
  final NoteTabsController tabs;

  final bool _ownsTools;
  final bool _ownsLayout;

  /// The app's own palette callback; without one the focused editor's quick
  /// palette answers.
  late final VoidCallback? _hostPalette;
  final bool _ownsTabs;
  final Map<String, _OpenNote> _notes = {};
  final Map<(String, String), _PaneEditor> _editors = {};

  /// The page each note was last turned to, to come back to from its tab.
  final Map<String, int> _lastPages = {};

  /// Pages asked for by id before their note was open.
  final Map<(String, String), String> _wantedPages = {};

  late String _focusedPaneId;
  String _shown = '';
  bool _isApplying = false;
  bool _isReconcileScheduled = false;
  bool _isDisposed = false;

  String get focusedPaneId => _focusedPaneId;

  NoteEditorController? get focusedEditor => editorOf(_focusedPaneId);

  /// The editor of [paneId], or null while the pane has no open note.
  NoteEditorController? editorOf(String paneId) => _entryOf(paneId)?.editor;

  /// The open document of [noteId], if any.
  NoteDocument? documentOf(String noteId) => _notes[noteId]?.document;

  /// Why the note of [paneId] could not be opened.
  Object? errorOf(String paneId) => _noteOf(paneId)?.error;

  NoteWorkspacePaneStatus statusOf(String paneId) {
    final pane = layout.pane(paneId);
    if (pane == null || pane.noteId == null) {
      return NoteWorkspacePaneStatus.empty;
    }
    final note = _noteOf(paneId);
    if (note == null || note.isLoading) return NoteWorkspacePaneStatus.loading;
    if (note.error != null) return NoteWorkspacePaneStatus.failed;
    final document = note.document;
    if (document == null) return NoteWorkspacePaneStatus.missing;

    return pane.pageIndex >= document.pageCount
        ? NoteWorkspacePaneStatus.pastEnd
        : NoteWorkspacePaneStatus.ready;
  }

  /// Whether [paneId] must be focused before it takes input: it shows the page
  /// the focused pane shows, or the focused pane is still editing an object of
  /// the same note. Its first tap then only moves the focus.
  bool needsFocusFirst(String paneId) {
    if (paneId == _focusedPaneId ||
        statusOf(paneId) != NoteWorkspacePaneStatus.ready) {
      return false;
    }
    final editor = editorOf(paneId);
    final focused = focusedEditor;
    if (editor == null || focused == null) return false;
    if (!identical(editor.document, focused.document)) return false;

    return editor.pageId == focused.pageId ||
        focused.session.objects.editingId != null ||
        focused.session.shared.editingId != null;
  }

  /// Moves the focus (tool undo and redo, the active tab) to [paneId] and
  /// finishes what the previously focused pane was editing.
  void focus(String paneId) {
    if (_isDisposed ||
        paneId == _focusedPaneId ||
        layout.pane(paneId) == null) {
      return;
    }
    final previous = focusedEditor;
    _focusedPaneId = paneId;
    previous?.closePalette();
    _wireTools();
    final noteId = layout.pane(paneId)?.noteId;
    if (noteId != null) tabs.activate(noteId);
    _notifyIfChanged();
    if (previous == null) return;
    // On a later task, after a text field losing the focus handed in its text.
    Timer.run(() {
      if (!_isDisposed && _isOpen(previous)) previous.commit();
    });
  }

  /// Shows [noteId] in [paneId] (the focused pane by default) and gives it a
  /// tab. It opens on [pageId] (once the note is open) or [pageIndex], else
  /// where it was last.
  void open(
    String noteId, {
    String title = '',
    String? paneId,
    String? pageId,
    int? pageIndex,
  }) {
    if (_isDisposed || noteId.isEmpty) return;
    final target = paneId ?? _focusedPaneId;
    if (layout.pane(target) == null) return;
    final index = tabs.indexOf(noteId);
    tabs.open(
      noteId,
      title.isEmpty && index >= 0 ? tabs.tabs[index].title : title,
    );
    focus(target);
    if (pageId == null) {
      _wantedPages.remove((target, noteId));
    } else {
      _wantedPages[(target, noteId)] = pageId;
    }
    if (layout.pane(target)?.noteId != noteId || pageIndex != null) {
      layout.setNote(
        target,
        noteId,
        pageIndex: pageIndex ?? _lastPages[noteId] ?? 0,
      );
    }
    _apply();
  }

  /// Closes the tab of [noteId]. Panes showing it move to the active tab, or
  /// become empty when another pane shows that one.
  void closeTab(String noteId) {
    if (_isDisposed || !tabs.close(noteId)) return;
    for (final pane in layout.panes) {
      if (layout.pane(pane.id)?.noteId != noteId) continue;
      final next = tabs.activeId;
      final isShown = layout.panes.any(
        (other) => other.id != pane.id && other.noteId == next,
      );
      final shown = isShown ? null : next;
      layout.setNote(
        pane.id,
        shown,
        pageIndex: shown == null ? 0 : _lastPages[shown] ?? 0,
      );
    }
    _apply();
  }

  void setMode(NoteViewMode mode) =>
      layout.setMode(mode, keepPaneId: _focusedPaneId);

  /// Removes [paneId]; the last pane stays.
  void closePane(String paneId) => layout.removePane(paneId);

  /// Opens a note that failed to open again.
  void retry(String paneId) {
    final noteId = layout.pane(paneId)?.noteId;
    if (noteId == null || _notes[noteId]?.error == null) return;
    _notes.remove(noteId);
    _apply();
  }

  /// Adds the page a [NoteWorkspacePaneStatus.pastEnd] pane is waiting for.
  void addPageTo(String paneId) {
    focus(paneId);
    editorOf(paneId)?.addPage(position: NotePageInsertPosition.end);
  }

  /// Commits and saves every open editor.
  Future<void> save() async {
    for (final entry in List.of(_editors.values)) {
      await entry.editor.save();
    }
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    layout.removeListener(_onLayout);
    tabs.removeListener(notifyListeners);
    for (final entry in _editors.values) {
      entry.editor
        ..removeListener(entry.listener)
        ..commit()
        ..dispose();
    }
    _editors.clear();
    for (final MapEntry(:key, :value) in _notes.entries) {
      final document = value.document;
      if (document != null) onDocumentClosed?.call(key, document);
    }
    _notes.clear();
    if (!_ownsTools) tools.onShowToolPalette = _hostPalette;
    if (_ownsLayout) layout.dispose();
    if (_ownsTabs) tabs.dispose();
    if (_ownsTools) tools.dispose();
    super.dispose();
  }

  _OpenNote? _noteOf(String paneId) {
    final noteId = layout.pane(paneId)?.noteId;

    return noteId == null ? null : _notes[noteId];
  }

  _PaneEditor? _entryOf(String paneId) {
    final noteId = layout.pane(paneId)?.noteId;

    return noteId == null ? null : _editors[(paneId, noteId)];
  }

  bool _isOpen(NoteEditorController editor) =>
      _editors.values.any((entry) => identical(entry.editor, editor));

  bool _isSpreadSecond(String paneId) =>
      layout.mode == NoteViewMode.twoPage &&
      layout.panes.length > 1 &&
      layout.panes[1].id == paneId;

  void _onLayout() {
    _apply();
    _notifyIfChanged();
  }

  /// Makes the editors match the layout: opens notes, creates and closes
  /// editors and turns each to its pane's page.
  void _apply() {
    if (_isDisposed || _isApplying) return;
    _isApplying = true;
    try {
      if (layout.pane(_focusedPaneId) == null) {
        _focusedPaneId = layout.panes.first.id;
      }
      for (final pane in layout.panes) {
        _applyPane(pane.id);
      }
      _release();
      _wireTools();
    } finally {
      _isApplying = false;
    }
    _notifyIfChanged();
  }

  void _applyPane(String paneId) {
    final noteId = layout.pane(paneId)?.noteId;
    if (noteId == null) return;
    final note = _notes[noteId];
    if (note == null) {
      _load(noteId);

      return;
    }
    note.isReleasing = false;
    final document = note.document;
    if (document == null) return;
    if (_wantedPages.remove((paneId, noteId)) case final wanted?) {
      final at = document.indexOf(wanted);
      if (at >= 0) layout.setPage(paneId, at);
    }
    final pane = layout.pane(paneId)!;
    var index = pane.pageIndex;
    // Only a spread's second page may point past the end.
    if (index >= document.pageCount && !_isSpreadSecond(paneId)) {
      index = document.pageCount - 1;
      layout.setPage(paneId, index);
    }
    final entry = _editors[(paneId, noteId)] ??= _create(pane, document);
    entry.isShown = true;
    if (index < document.pageCount) {
      final pageId = document.pageIds[index];
      if (entry.editor.pageId != pageId) entry.editor.goToPage(pageId);
    }
    entry.seen = (entry.editor.pageId, entry.editor.pageIndex);
    if (paneId == _focusedPaneId || !_lastPages.containsKey(noteId)) {
      _lastPages[noteId] = math.min(index, document.pageCount - 1);
    }
  }

  _PaneEditor _create(NoteViewPane pane, NoteDocument document) {
    final index = math.min(pane.pageIndex, document.pageCount - 1);
    final editor = createEditor(document, tools, document.pageIds[index]);
    assert(
      identical(editor.tools, tools),
      'pane editors must use the workspace tools',
    );
    final entry = _PaneEditor(editor, _scheduleReconcile);
    editor.addListener(entry.listener);
    entry.stamp = entry.currentStamp;

    return entry;
  }

  void _load(String noteId) {
    final note = _OpenNote();
    _notes[noteId] = note;
    Future<NoteDocument?>.sync(() => openDocument(noteId)).then(
      (document) {
        if (_isDisposed || !identical(_notes[noteId], note)) {
          if (document != null) onDocumentClosed?.call(noteId, document);

          return;
        }
        note
          ..isLoading = false
          ..document = document;
        _apply();
      },
      onError: (Object error, StackTrace stack) {
        if (_isDisposed || !identical(_notes[noteId], note)) return;
        note
          ..isLoading = false
          ..error = error;
        onError?.call(error, stack);
        _notifyIfChanged();
      },
    );
  }

  /// Commits editors that left the screen, closes those no pane or tab needs,
  /// and releases documents nothing uses.
  void _release() {
    final visible = {
      for (final pane in layout.panes)
        if (pane.noteId case final noteId?) (pane.id, noteId),
    };
    for (final key in List.of(_editors.keys)) {
      final entry = _editors[key]!;
      final (paneId, noteId) = key;
      if (visible.contains(key)) continue;
      if (entry.isShown) {
        entry
          ..isShown = false
          ..editor.commit();
      }
      if (layout.pane(paneId) != null && tabs.contains(noteId)) continue;
      _editors.remove(key);
      _notes[noteId]?.closing.add(_close(entry));
    }
    for (final noteId in List.of(_notes.keys)) {
      if (!_isUsed(noteId)) _releaseDocument(noteId);
    }
  }

  bool _isUsed(String noteId) =>
      tabs.contains(noteId) ||
      layout.panes.any((pane) => pane.noteId == noteId);

  /// Saves [entry]'s editor and disposes it after the frame that removes its
  /// view.
  Future<void> _close(_PaneEditor entry) {
    final editor = entry.editor..removeListener(entry.listener);
    final closed = Completer<void>();
    unawaited(
      editor.save().catchError(_reportError).whenComplete(() {
        SchedulerBinding.instance
          ..addPostFrameCallback((_) {
            editor.dispose();
            closed.complete();
          })
          ..scheduleFrame();
      }),
    );

    return closed.future;
  }

  void _releaseDocument(String noteId) {
    final note = _notes[noteId]!;
    if (note.isReleasing) return;
    note.isReleasing = true;
    // Kept until its editors saved; reopened meanwhile, it is used again.
    unawaited(
      Future.wait(List.of(note.closing)).then((_) {
        if (_isDisposed ||
            !note.isReleasing ||
            !identical(_notes[noteId], note) ||
            _isUsed(noteId)) {
          return;
        }
        _notes.remove(noteId);
        final document = note.document;
        if (document != null) onDocumentClosed?.call(noteId, document);
      }),
    );
  }

  void _reportError(Object error, StackTrace stack) =>
      onError?.call(error, stack);

  void _wireTools() {
    final editor = focusedEditor;
    tools
      ..onUndo = editor?.undo
      ..onRedo = editor?.redo
      ..onShowToolPalette = _hostPalette ?? editor?.togglePalette;
  }

  /// Editors report changes in the middle of their own work, so they are
  /// looked at afterwards.
  void _scheduleReconcile() {
    if (_isDisposed || _isReconcileScheduled) return;
    _isReconcileScheduled = true;
    scheduleMicrotask(() {
      _isReconcileScheduled = false;
      if (!_isDisposed) _reconcile();
    });
  }

  /// Follows a page turned in a pane, then hands finished edits to the other
  /// panes of the same note.
  void _reconcile() {
    _followTurnedPage();
    _apply();
    _shareEdits();
    _notifyIfChanged();
  }

  void _followTurnedPage() {
    final paneIds = [
      _focusedPaneId,
      for (final pane in layout.panes)
        if (pane.id != _focusedPaneId) pane.id,
    ];
    for (final paneId in paneIds) {
      final entry = _entryOf(paneId);
      if (entry == null) continue;
      final now = (entry.editor.pageId, entry.editor.pageIndex);
      final before = entry.seen;
      if (now == before) continue;
      entry.seen = now;
      // A page removed elsewhere leaves the pane at its position.
      final lostPage =
          before != null && entry.editor.document.indexOf(before.$1) < 0;
      if (lostPage && paneId != _focusedPaneId) continue;
      layout.setPage(paneId, now.$2);

      return;
    }
  }

  void _shareEdits() {
    for (final pane in layout.panes) {
      final entry = _entryOf(pane.id);
      if (entry == null) continue;
      final stamp = entry.currentStamp;
      if (stamp == entry.stamp) continue;
      entry.stamp = stamp;
      final editor = entry.editor;
      final hasCompany = _editors.values.any(
        (other) =>
            !identical(other.editor, editor) &&
            identical(other.editor.document, editor.document),
      );
      if (hasCompany &&
          (editor.session.isModified ||
              editor.session.areSharedObjectsModified)) {
        editor.commit(flush: false);
      }
    }
  }

  /// Notifies when what the panes show changed, not for every edit.
  void _notifyIfChanged() {
    if (_isDisposed) return;
    final shown = [
      _focusedPaneId,
      for (final pane in layout.panes)
        '${pane.id} ${pane.noteId} ${statusOf(pane.id).name} '
            '${needsFocusFirst(pane.id)} '
            '${identityHashCode(editorOf(pane.id))}',
    ].join('|');
    if (shown == _shown) return;
    _shown = shown;
    notifyListeners();
  }
}

class _OpenNote {
  NoteDocument? document;
  Object? error;
  bool isLoading = true;
  bool isReleasing = false;

  /// Editors of this note that are saving before they are disposed.
  final List<Future<void>> closing = [];
}

class _PaneEditor {
  _PaneEditor(this.editor, this.listener);

  final NoteEditorController editor;
  final VoidCallback listener;
  bool isShown = false;

  /// The page the editor showed when the layout last matched it.
  (String, int)? seen;

  /// The history when its edits were last handed over.
  Object? stamp;

  Object get currentStamp {
    final session = editor.session;
    final history = session.history;

    return (
      identityHashCode(session),
      history.pushCount,
      history.undoLength,
      history.redoLength,
    );
  }
}
