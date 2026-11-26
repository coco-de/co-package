import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:open_note/src/core/utils/extensions/paint_extension/ex_color.dart';
import 'package:open_note/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/lasso/scribble_lasso_selection.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_document.dart';
import 'package:open_note/src/note/document/note_document_repository.dart';
import 'package:open_note/src/note/document/note_ink_transforms.dart';
import 'package:open_note/src/note/document/note_pdf_page_mapping.dart';
import 'package:open_note/src/note/editor/note_pdf_text_controller.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_layer.dart';
import 'package:open_note/src/note/io/markup/note_text_markup_builder.dart';
import 'package:open_note/src/note/io/markup/note_text_markup_kind.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/document/note_page_ops.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_page_content.dart';
import 'package:open_note/src/note/editor/note_page_session.dart';
import 'package:open_note/src/note/editor/note_tool_controller.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';
import 'package:open_note/src/note/nav/nav.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';
import 'package:open_note/src/note/study/overlay/note_mask_object.dart';
import 'package:open_note/src/note/study/overlay/note_mask_ops.dart';
import 'package:open_note/src/note/study/overlay/note_mask_pen_session.dart';
import 'package:open_note/src/note/study/utilities/note_recording_controller.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/style/note_text_box_style.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_selection_controller.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_text_style_preset.dart';
import 'package:open_note/src/note/view/note_ruler_controller.dart';

/// A picture to place on a page: where it is and its size in pixels or points
/// (only the aspect ratio and the upper bound of its size matter).
@immutable
class NoteImageInsert {
  const NoteImageInsert(this.source, this.size);

  final String source;
  final Size size;
}

/// Everything the note editor does: the open page and its editing session,
/// tools and modes, page operations, lasso and image edits, objects, links,
/// bookmarks, search and saving. `NoteEditorView` is its widget; a host with
/// its own interface can drive it directly.
///
/// Edits of the open page live in [session] until [commit] (or [save]) writes
/// them into [document]; page operations commit first. With a [repository] the
/// note is saved [autoSaveDelay] after the first unsaved change. [dispose] does
/// not save: await [save] first.
///
/// The controller never disposes [document], [repository] or [recordings].
class NoteEditorController extends ChangeNotifier {
  NoteEditorController({
    required this.document,
    NoteToolController? tools,
    NoteTableSelectionController? tableSelection,
    this.repository,
    this.autoSaveDelay = const Duration(seconds: 3),
    this.recordings,
    this.pdfTextLayer,
    this.onOpenUrl,
    this.onOpenNote,
    this.layerName,
    this.objectStrings = const NoteObjectsStrings(),
    NoteMaskPenSession? maskPen,
    String? initialPageId,
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
  }) : tools = tools ?? NoteToolController(),
       _ownsTools = tools == null,
       tableSelection = tableSelection ?? NoteTableSelectionController(),
       _ownsTableSelection = tableSelection == null,
       _maskPen = maskPen ?? NoteMaskPenSession(),
       _idFactory = idFactory,
       _clock = clock {
    _savedRevision = document.revision;
    this.tools
      ..bind(modeNotifier)
      ..onUndo = undo
      ..onRedo = redo
      ..onShowToolPalette ??= togglePalette
      ..addListener(notifyListeners);
    lassoSelection.addListener(notifyListeners);
    final recordings = this.recordings;
    if (recordings != null) {
      recordings.loadJson(document.recordings);
      _recordingsJson = NoteJson.encode(recordings.toJson());
      recordings.addListener(_onRecordingsChanged);
    }
    final initial = initialPageId == null
        ? -1
        : document.indexOf(initialPageId);
    _openPage(document.pageAt(math.max(0, initial)).id);
    document.addListener(_onDocumentChanged);
  }

  final NoteDocument document;

  /// Where the note is saved; null leaves saving to the host.
  final NoteDocumentRepository? repository;

  /// How long after the first unsaved change the note is saved; null saves only
  /// on [save].
  final Duration? autoSaveDelay;

  /// The note's recordings, if the host records audio. Its list is kept in the
  /// document and follows pages when they move.
  final NoteRecordingController? recordings;

  /// The text of an imported PDF, by the [NotePdfOrigin.document] key; null
  /// for PDFs whose text cannot be selected.
  final NotePdfTextLayer? Function(String document)? pdfTextLayer;

  /// The text of the open PDF page, read while in [NoteEditorMode.pdfText].
  late final NotePdfTextController pdfText = NotePdfTextController()
    ..addListener(notifyListeners);

  /// Opens an external link (only [NoteUrlLink.safeSchemes] reach this).
  final void Function(String url)? onOpenUrl;

  /// Opens another note; [pageId] is null for its first page.
  final void Function(String noteId, String? pageId)? onOpenNote;

  /// Names new layers; defaults to "Layer N".
  final String Function(int number)? layerName;

  final NoteObjectsStrings objectStrings;

  /// Tool, colour, width and input settings. Give editors shown side by side
  /// the same controller: the engine's tool state is global, so separate
  /// controllers would make one editor draw with the other's tool.
  final NoteToolController tools;

  /// The selected cells of table objects. The object registry's table views
  /// must use the same instance.
  final NoteTableSelectionController tableSelection;

  /// The engine's tool state, shared by every layer and page.
  final ScribbleModeNotifier modeNotifier = ScribbleModeNotifier();

  /// What the lasso selected on the active layer.
  final ScribbleLassoSelection lassoSelection = ScribbleLassoSelection();

  /// Follows links on the page and in text.
  late final NoteLinkNavigator links = NoteLinkNavigator(
    pageOrder: () => document.pageIds,
    goToPage: goToPage,
    openNote: (noteId, pageId) => onOpenNote?.call(noteId, pageId),
    openUrl: (url) => onOpenUrl?.call(url),
    currentNoteId: document.id,
  );

  /// The ruler on the page, in page coordinates. Pen and shape strokes that
  /// start beside one of its edges follow that edge.
  final NoteRulerController ruler = NoteRulerController();

  /// Flashes an excerpt after jumping to it.
  late final NoteExcerptFlashController excerptFlash =
      NoteExcerptFlashController();

  final bool _ownsTools;
  final bool _ownsTableSelection;
  final NoteIdFactory _idFactory;
  final NoteClock _clock;
  final List<NotePageSession> _retired = [];

  late NotePageSession _session;
  NoteMaskPenSession _maskPen;

  /// The open page's [NoteUndoStack.pushCount] when writing was last checked.
  int _writingSeen = 0;
  NoteEditorMode _mode = NoteEditorMode.draw;
  String? _selectedImageId;
  Timer? _autoSaveTimer;
  late int _savedRevision;
  int _savesInFlight = 0;
  Object? _saveError;
  String _recordingsJson = '';
  bool _isPaletteOpen = false;
  bool _isSyncingRecordings = false;
  bool _isSwitching = false;
  bool _isDisposed = false;

  /// The open page's layers, objects and undo history. Replaced when the page
  /// changes.
  NotePageSession get session => _session;

  NoteLayerStack get layers => _session.layers;

  /// The open page as it is now.
  NotePage get page => _session.page;

  String get pageId => _session.pageId;

  int get pageIndex => document.indexOf(pageId);

  int get pageCount => document.pageCount;

  /// The page number printed for the open page.
  String get pageLabel => document.labelOf(pageId);

  NoteEditorMode get mode => _mode;

  set mode(NoteEditorMode value) {
    if (value == _mode) return;
    if (_mode == NoteEditorMode.objects) {
      _flushInput();
      for (final controller in [_session.objects, _session.shared]) {
        controller
          ..endEditing()
          ..clearSelection();
      }
    }
    if (_mode == NoteEditorMode.draw) _dropLasso();
    if (_mode == NoteEditorMode.maskPen) _maskPen.cancel();
    _isPaletteOpen = false;
    _mode = value;
    _syncPdfText();
    notifyListeners();
  }

  /// Switches to a drawing tool (and back to [NoteEditorMode.draw]).
  void selectTool(String ink) {
    tools.selectTool(ink);
    mode = NoteEditorMode.draw;
  }

  /// The look of new cover masks.
  NoteMaskPenSession get maskPen => _maskPen;

  set maskPen(NoteMaskPenSession value) {
    if (identical(value, _maskPen)) return;
    _maskPen.cancel();
    _maskPen = value;
    notifyListeners();
  }

  bool get canUndo => _session.history.canUndo;

  bool get canRedo => _session.history.canRedo;

  /// Reverts the latest edit of the open page; text still being typed in an
  /// object counts as the latest one.
  /// Where the open page's PDF text comes from, while its paper still shows
  /// that PDF page.
  NotePdfOrigin? get pdfOrigin {
    final layer = pdfTextLayer;
    if (layer == null) return null;
    final shown = page;
    final origin = shown.pdf;
    if (origin == null || shown.template.imageSource != origin.picture) {
      return null;
    }

    return layer(origin.document) == null ? null : origin;
  }

  bool get canSelectPdfText => pdfOrigin != null;

  /// Selects PDF text from one page point to another.
  void selectPdfText(Offset from, Offset to) {
    final origin = pdfOrigin;
    if (origin == null) return;
    final mapping = NotePdfPageMapping(page, origin);
    pdfText.select(mapping.toPdf(from), mapping.toPdf(to));
  }

  /// The boxes of the selected PDF text, in page coordinates.
  List<Rect> get pdfSelectionRects {
    final origin = pdfOrigin;
    if (origin == null || pdfText.selected.isEmpty) return const [];
    final mapping = NotePdfPageMapping(page, origin);

    return [for (final run in pdfText.selected) mapping.rectToPage(run.rect)];
  }

  /// Marks the selected PDF text with strokes on the active layer, as one undo
  /// step, and ends the selection. False when there is nothing to mark or the
  /// layer is hidden or locked.
  bool markPdfSelection(NoteTextMarkupKind kind, Color color) {
    final origin = pdfOrigin;
    final selected = pdfText.selected;
    if (origin == null || selected.isEmpty || !layers.canDrawOnActive) {
      return false;
    }
    _flushInput();
    final mapping = NotePdfPageMapping(page, origin);
    // Built flat along the PDF's lines, then placed, so lines stay along the
    // text on turned pages.
    final marks = [
      for (final stroke in NoteTextMarkupBuilder.build(
        selected,
        kind,
        color,
        idFactory: _idFactory,
        clock: _clock,
      ))
        _placed(stroke, mapping),
    ];
    final notifier = layers.activeNotifier;
    notifier.setScribble(
      scribble: notifier.currentScribble.deepCopy()..strokes.addAll(marks),
    );
    pdfText.clear();

    return true;
  }

  static Stroke _placed(Stroke stroke, NotePdfPageMapping mapping) {
    final placed = stroke.deepCopy();
    for (final point in placed.points) {
      final at = mapping.toPage(Offset(point.x, point.y));
      point
        ..x = at.dx
        ..y = at.dy;
    }
    placed.width *= mapping.scale;
    placed.options.size *= mapping.scale;

    return placed;
  }

  void _syncPdfText() {
    final origin = _mode == NoteEditorMode.pdfText ? pdfOrigin : null;
    if (origin == null) {
      pdfText.reset();

      return;
    }
    unawaited(
      pdfText.load((
        _session.pageId,
        origin,
      ), () => pdfTextLayer!(origin.document)!.runs(origin.pageIndex)),
    );
  }

  /// Whether the quick tool palette (Pencil squeeze) is shown.
  bool get isPaletteOpen => _isPaletteOpen;

  void togglePalette() {
    _isPaletteOpen = !_isPaletteOpen;
    notifyListeners();
  }

  void closePalette() {
    if (!_isPaletteOpen) return;
    _isPaletteOpen = false;
    notifyListeners();
  }

  void undo() {
    _flushInput();
    _session.history.undo();
  }

  void redo() {
    _flushInput();
    _session.history.redo();
  }

  // ───────────────────────── pages ─────────────────────────

  /// Shows another page. Returns false for an unknown or removed page.
  bool goToPage(String pageId) {
    if (pageId == this.pageId) return true;
    if (document.indexOf(pageId) < 0) return false;
    _switching(() {
      _leavePage();
      _openPage(pageId);
    });

    return true;
  }

  bool nextPage() => _goToIndex(pageIndex + 1);

  bool previousPage() => _goToIndex(pageIndex - 1);

  /// Adds a blank page and shows it (see [NoteDocument.addPage]).
  NotePage addPage({
    NotePageInsertPosition position = NotePageInsertPosition.after,
    NotePaperTemplate? template,
    NotePageSize? size,
    NotePageOrientation? orientation,
  }) {
    commit();
    final added = document.addPage(
      after: position == NotePageInsertPosition.after ? pageId : null,
      before: position == NotePageInsertPosition.before ? pageId : null,
      index: position == NotePageInsertPosition.end ? pageCount : null,
      template: template,
      size: size,
      orientation: orientation,
    );
    _syncRecordings();
    goToPage(added.id);

    return added;
  }

  /// Copies the open page after itself and shows the copy.
  NotePage? duplicatePage() {
    commit();
    final copy = document.duplicatePage(pageId);
    if (copy == null) return null;
    _syncRecordings();
    goToPage(copy.id);

    return copy;
  }

  /// Moves a page (the open one by default) to the trash. The last page stays.
  bool removePage([String? id]) {
    final target = id ?? pageId;
    final index = document.indexOf(target);
    if (index < 0 || pageCount == 1) return false;
    if (target == pageId) {
      _goToIndex(index + 1 < pageCount ? index + 1 : index - 1);
    }
    final removed = document.removePage(target);
    if (removed) _syncRecordings();

    return removed;
  }

  /// Brings back a removed page and shows it.
  bool restorePage(String id) {
    if (!document.restorePage(id)) return false;
    _syncRecordings();
    goToPage(id);

    return true;
  }

  bool movePage(String id, int newIndex) {
    final moved = document.movePage(id, newIndex);
    if (moved) _syncRecordings();

    return moved;
  }

  /// Turns the open page clockwise by [quarterTurns] × 90°, as one undo step.
  void rotatePage([int quarterTurns = 1]) {
    final turns = quarterTurns % 4;
    if (turns == 0) return;
    _flushInput();
    _dropLasso();
    final current = page;
    final size = current.size.toSize();
    _session.rearrange(
      'rotate',
      NotePageOps.rotate(current, turns),
      moveInk: (scribble) => NoteInkTransforms.rotate(scribble, turns, size),
    );
  }

  /// Sets the extended margins of the open page, as one undo step.
  void setMargins(EdgeInsets margins, {NotePaperTemplate? marginTemplate}) {
    _flushInput();
    _dropLasso();
    _session.rearrange(
      'margins',
      _withMargins(page, margins, marginTemplate),
      moveInk: _shift(page.margins, margins),
    );
  }

  /// Widens the margin on [side] by [amount] (negative narrows it).
  void extendMargin(NoteMarginSide side, double amount) =>
      setMargins(NotePageOps.extended(page.margins, side, amount));

  /// How close writing may come to the right or bottom edge of an endless page.
  static const double endlessMargin = 120;

  /// How close writing may come to the left or top edge of an endless page;
  /// closer than [endlessMargin], since writing near the top is ordinary.
  static const double endlessLeadingMargin = 24;

  /// How much an endless page grows at a time.
  static const double endlessStep = 400;

  /// Makes the open page endless (it grows, see [growEndlessPage]) or stops it
  /// growing.
  void setEndlessPage(bool endless) {
    if (page.autoGrows == endless) return;
    _session.setAutoGrows(endless);
  }

  /// Grows an endless page after writing near one of its edges; the view calls
  /// this when a stroke finished. The growth joins the writing's undo step, so
  /// one undo takes both back. Undo, redo, other edits and a lasso selection do
  /// not grow the page. Returns whether it grew.
  bool growAfterWriting() {
    final history = _session.history;
    if (history.isApplying || history.isGrouping) return false;
    if (history.pushCount == _writingSeen) return false;
    _writingSeen = history.pushCount;
    if (history.undoLabel != 'ink' || !lassoSelection.isEmpty) return false;
    final written = notePageContentBounds(page);
    final margins = written == null ? null : _grownMargins(written);
    if (margins == null) return false;
    history.amend(() => _grow(margins));

    return true;
  }

  /// Grows an endless page whose [area] is near an edge, as one undo step.
  /// Growing left or up moves the content along. Returns whether it grew.
  bool growEndlessPage(Rect area) {
    final margins = _grownMargins(area);
    if (margins == null) return false;
    _grow(margins);

    return true;
  }

  /// The margins an endless page needs around [area], or null.
  EdgeInsets? _grownMargins(Rect area) {
    final current = page;
    if (!current.autoGrows) return null;
    double growth(double short) =>
        short <= 0 ? 0 : (short / endlessStep).ceil() * endlessStep;
    final grown = EdgeInsets.fromLTRB(
      growth(endlessLeadingMargin - area.left),
      growth(endlessLeadingMargin - area.top),
      growth(area.right + endlessMargin - current.size.width),
      growth(area.bottom + endlessMargin - current.size.height),
    );

    return grown == EdgeInsets.zero ? null : current.margins + grown;
  }

  void _grow(EdgeInsets margins) {
    final current = page;
    if (margins.left != current.margins.left ||
        margins.top != current.margins.top) {
      _dropLasso();
    }
    _session.rearrange(
      'grow',
      NotePageOps.setMargins(current, margins),
      moveInk: _shift(current.margins, margins),
    );
  }

  /// Changes the paper of the open page as one undo step. With [allPages] every
  /// other page takes it too (undo brings back the open page's paper only).
  void setPaper(NotePaperTemplate template, {bool allPages = false}) {
    _flushInput();
    _session.rearrange(
      'paper',
      page.copyWith(template: template.fitted(page.paperSize)),
    );
    if (allPages) {
      commit(flush: false);
      document.setTemplate([
        for (final id in document.pageIds)
          if (id != pageId) id,
      ], template);
    }
  }

  /// Copies pages of another note here and shows the first of them.
  List<NotePage> importPages(
    NoteDocument source,
    Iterable<String> sourcePageIds, {
    NotePageInsertPosition position = NotePageInsertPosition.after,
  }) {
    commit();
    final imported = document.importPages(
      source,
      sourcePageIds,
      index: _insertIndex(position),
    );
    if (imported.isNotEmpty) {
      _syncRecordings();
      goToPage(imported.first.id);
    }

    return imported;
  }

  /// Adds pages built elsewhere (from an imported PDF, say) and shows the
  /// first of them.
  void insertPages(
    List<NotePage> pages, {
    NotePageInsertPosition position = NotePageInsertPosition.end,
  }) {
    if (pages.isEmpty) return;
    commit();
    document.appendPages(pages, index: _insertIndex(position));
    _syncRecordings();
    goToPage(pages.first.id);
  }

  // ─────────────────────── lasso and images ───────────────────────

  /// Restyles the lasso selection: strokes take colour, width and line style
  /// ('' is solid), text boxes take the colour.
  bool restyleSelection({Color? color, double? width, String? lineStyle}) {
    if (lassoSelection.isEmpty) return false;
    layers.activeNotifier.restyleStrokes(
      lassoSelection.strokeIndexes,
      color: color == null ? null : colorToInt(color),
      width: width,
      lineStyle: lineStyle,
      textIndexes: lassoSelection.textIndexes,
    );

    return true;
  }

  /// Puts a thicker copy of the selected strokes in [color] under them (the
  /// outline lettering effect).
  bool outlineSelection({required Color color, double extraWidth = 3}) {
    final strokes = lassoSelection.strokeIndexes;
    if (strokes.isEmpty) return false;
    _dropLasso();
    layers.activeNotifier.outlineStrokes(
      strokes,
      color: colorToInt(color),
      extraWidth: extraWidth,
    );

    return true;
  }

  /// Moves the lasso selection to the layer [layerId].
  bool moveSelectionToLayer(String layerId) {
    if (lassoSelection.isEmpty) return false;
    final scribble = layers.activeNotifier.currentScribble;
    final strokes = lassoSelection.strokeIndexes.toSet();
    final texts = {
      for (final index in lassoSelection.textIndexes)
        if (index >= 0 && index < scribble.textDrawables.length)
          scribble.textDrawables[index].id,
    };
    _dropLasso();

    return layers.moveToLayer(
      fromId: layers.activeLayerId,
      toId: layerId,
      strokeIndexes: strokes,
      textIds: texts,
    );
  }

  /// Gives the lasso-selected text boxes a text style favourite.
  bool applyTextStyle(NoteTextStylePreset preset) => _editSelectedTexts((text) {
    final styled = text.deepCopy()
      ..fontFamily = preset.fontFamily
      ..fontSize = preset.fontSize
      ..color = colorToInt(preset.color)
      ..isBold = preset.bold
      ..isItalic = preset.italic
      ..isUnderlined = preset.underline
      ..textAlign = preset.align.name;

    return _withBoxStyle(
      styled,
      NoteTextBoxStyle.decode(
        text.boxStyle,
      ).copyWith(lineHeight: preset.lineHeight),
    );
  });

  /// Changes the font of the lasso-selected text boxes. The host loads the
  /// font (see `NoteFontManager`).
  bool setSelectedTextFont(String family) =>
      _editSelectedTexts((text) => text.deepCopy()..fontFamily = family);

  /// Sets the background, border and padding of the lasso-selected text boxes.
  bool styleSelectedTextBoxes(NoteTextBoxStyle style) =>
      _editSelectedTexts((text) => _withBoxStyle(text.deepCopy(), style));

  /// Places pictures in a grid on the active layer as one undo step and
  /// switches to the image tool. Returns their ids.
  List<String> insertImages(List<NoteImageInsert> images) {
    if (images.isEmpty || !layers.canDrawOnActive) return const [];
    final area = page.contentRect.deflate(32);
    final columns = math.sqrt(images.length).ceil();
    final rows = (images.length / columns).ceil();
    const gap = 8.0;
    final cell = Size(
      math.max(1, (area.width - gap * (columns - 1)) / columns),
      math.max(1, (area.height - gap * (rows - 1)) / rows),
    );
    final added = <ImageDrawable>[];
    for (final (index, image) in images.indexed) {
      final natural = image.size.isEmpty ? cell : image.size;
      final scale = math.min(
        1.0,
        math.min(cell.width / natural.width, cell.height / natural.height),
      );
      final size = natural * scale;
      final origin = Offset(
        area.left + (index % columns) * (cell.width + gap),
        area.top + (index ~/ columns) * (cell.height + gap),
      );
      added.add(
        ImageDrawable(
          id: _idFactory(),
          source: image.source,
          x: origin.dx + (cell.width - size.width) / 2,
          y: origin.dy + (cell.height - size.height) / 2,
          width: size.width,
          height: size.height,
          opacity: 1,
        ),
      );
    }
    final notifier = layers.activeNotifier;
    notifier.setScribble(
      scribble: notifier.currentScribble.copyWithContents(
        imageDrawables: [...notifier.currentScribble.imageDrawables, ...added],
      ),
    );
    selectTool(NoteInkTypes.image);

    return [for (final image in added) image.id];
  }

  /// The image selected on the active layer (see [selectImage]).
  ImageDrawable? get selectedImage {
    final id = _selectedImageId;
    if (id == null) return null;
    for (final image in layers.activeNotifier.currentScribble.imageDrawables) {
      if (image.id == id) return image;
    }

    return null;
  }

  /// Remembers the image the page view selected.
  void selectImage(String? id) {
    if (id == _selectedImageId) return;
    _selectedImageId = id;
    notifyListeners();
  }

  /// Applies a frame, crop or opacity to the selected image. A new crop trims
  /// the picture in place: what stays visible keeps its position and size.
  bool styleSelectedImage(NoteImageStyle style) {
    final image = selectedImage;
    if (image == null) return false;
    final styled = image.deepCopy();
    final oldCrop = NoteImageStyle.decode(image.imageStyle).crop.bounds;
    final crop = style.crop.bounds;
    if (crop != oldCrop) {
      final unitWidth = image.width / oldCrop.width;
      final unitHeight = image.height / oldCrop.height;
      styled
        ..x = image.x + (crop.left - oldCrop.left) * unitWidth
        ..y = image.y + (crop.top - oldCrop.top) * unitHeight
        ..width = crop.width * unitWidth
        ..height = crop.height * unitHeight;
    }
    if (style == NoteImageStyle.plain) {
      styled.clearImageStyle();
    } else {
      styled.imageStyle = style.encode();
    }
    layers.activeNotifier.updateImageDrawable(image.id, styled);
    notifyListeners();

    return true;
  }

  // ─────────────────────── objects ───────────────────────

  String newId() => _idFactory();

  /// A [size] box around [center] (the page centre by default), kept on the
  /// page.
  Rect placement(Size size, {Offset? center}) {
    final bounds = Offset.zero & page.size.toSize();
    final width = math.min(size.width, bounds.width);
    final height = math.min(size.height, bounds.height);
    final point = center ?? bounds.center;

    return Rect.fromLTWH(
      (point.dx - width / 2).clamp(0.0, bounds.width - width),
      (point.dy - height / 2).clamp(0.0, bounds.height - height),
      width,
      height,
    );
  }

  /// Adds an object to the page (or, with [onEveryPage], to the note), selects
  /// it and switches to object mode.
  bool addObject(NoteObject object, {bool onEveryPage = false}) {
    mode = NoteEditorMode.objects;
    final target = onEveryPage ? _session.shared : _session.objects;
    final other = onEveryPage ? _session.objects : _session.shared;
    other.clearSelection();

    return target.add(object);
  }

  /// Adds a mask drawn with the mask pen, where its scope says.
  bool addMask(NoteMaskObject mask) =>
      (mask.scope == NoteMaskScope.document
              ? _session.shared
              : _session.objects)
          .add(mask, select: false);

  /// Reveals or covers every mask and tape of the open page.
  void setMasksRevealed(bool revealed) {
    for (final controller in [_session.objects, _session.shared]) {
      final next = revealed
          ? NoteMaskOps.revealAll(controller.objects)
          : NoteMaskOps.hideAll(controller.objects);
      _updateAll(controller, next);
    }
  }

  /// Removes every mask and tape of the open page, one undo step per layer of
  /// objects.
  void clearMasks() {
    for (final controller in [_session.objects, _session.shared]) {
      final kept = NoteMaskOps.clearAll(controller.objects).toSet();
      final removed = [
        for (final object in controller.objects)
          if (!kept.contains(object)) object.id,
      ];
      if (removed.isNotEmpty) controller.remove(removed);
    }
  }

  // ─────────────────────── links and navigation ───────────────────────

  bool followLink(NoteLinkTarget target) => links.navigate(target);

  /// Follows a raw link string (`page:3`, `pageid:…`, `note:…`, a URL).
  bool followRawLink(String raw) {
    final target = NoteLinkTarget.parse(raw);

    return target != null && followLink(target);
  }

  /// A link to a page of this note that survives reordering.
  String pageLink(String pageId) => NotePageIdLink(pageId).format();

  bool get isBookmarked => document.bookmarks.isBookmarked(pageId);

  void toggleBookmark() => document.bookmarks.toggle(pageId);

  /// Saves a labelled region of the open page ([pageRect] in page units).
  NoteExcerpt? addExcerpt(
    Rect pageRect, {
    String? label,
    String? note,
    Color? color,
  }) => document.excerpts.add(
    pageId: pageId,
    rect: NoteExcerpt.fractionsOf(pageRect, page.size.toSize()),
    label: label,
    note: note,
    color: color,
  );

  /// Shows the page of an excerpt and flashes it.
  bool showExcerpt(NoteExcerpt excerpt) {
    if (!goToPage(excerpt.pageId)) return false;
    excerptFlash.flash(excerpt.id);

    return true;
  }

  /// Puts the typed text of every page in [index].
  void indexInto(NoteSearchIndex index) {
    for (final stored in document.pages) {
      final current = stored.id == pageId ? page : stored;
      index.indexPage(document.id, current.id, notePageTexts(current));
    }
  }

  // ─────────────────────── saving ───────────────────────

  bool get hasUnsavedChanges =>
      _session.isModified ||
      _session.areSharedObjectsModified ||
      document.dirtyPageIds.isNotEmpty ||
      document.revision != _savedRevision;

  bool get isSaving => _savesInFlight > 0;

  /// Why the latest save failed; null after a successful one.
  Object? get saveError => _saveError;

  /// Writes the open page into [document]. With [flush] text still being typed
  /// is included (and a table's cell editor is closed).
  void commit({bool flush = true}) {
    if (flush) _flushInput();
    final session = _session;
    final sharedChanged = session.areSharedObjectsModified;
    if (!session.isModified && !sharedChanged) return;
    final stored = session.snapshot();
    final shared = session.shared.objects;
    session.markClean(stored);
    final wasSwitching = _isSwitching;
    _isSwitching = true;
    try {
      document.replacePage(stored);
      if (sharedChanged) document.documentObjects = shared;
    } finally {
      _isSwitching = wasSwitching;
    }
    notifyListeners();
  }

  /// Commits and saves with [repository]. Rethrows what the store throws.
  Future<void> save() => _save(flush: true, rethrowErrors: true);

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    document.removeListener(_onDocumentChanged);
    recordings?.removeListener(_onRecordingsChanged);
    tools
      ..removeListener(notifyListeners)
      ..unbind(modeNotifier);
    // Another editor sharing the tools may own the callbacks by now.
    if (tools.onUndo == undo) tools.onUndo = null;
    if (tools.onRedo == redo) tools.onRedo = null;
    if (tools.onShowToolPalette == togglePalette) {
      tools.onShowToolPalette = null;
    }
    if (_ownsTools) tools.dispose();
    lassoSelection
      ..removeListener(notifyListeners)
      ..dispose();
    _session
      ..removeListener(_onSessionChanged)
      ..dispose();
    for (final session in List.of(_retired)) {
      _disposeRetired(session);
    }
    if (_ownsTableSelection) tableSelection.dispose();
    excerptFlash.dispose();
    ruler.dispose();
    pdfText.dispose();
    modeNotifier.dispose();
    super.dispose();
  }

  Future<void> _save({required bool flush, required bool rethrowErrors}) async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    commit(flush: flush);
    final repository = this.repository;
    if (repository == null) return;
    final revision = document.revision;
    _savesInFlight++;
    _saveError = null;
    notifyListeners();
    try {
      await repository.save(document);
      _savedRevision = revision;
      // `commit` above armed the next autosave before this write started. Drop
      // it when nothing is left to save; a failed write or a newer edit keeps it.
      if (!hasUnsavedChanges) {
        _autoSaveTimer?.cancel();
        _autoSaveTimer = null;
      }
    } on Object catch (error) {
      _saveError = error;
      if (rethrowErrors) rethrow;
    } finally {
      _savesInFlight--;
      notifyListeners();
    }
  }

  void _scheduleAutoSave() {
    final delay = autoSaveDelay;
    if (repository == null || delay == null || _isDisposed) return;
    if ((_autoSaveTimer?.isActive ?? false) || !hasUnsavedChanges) return;
    _autoSaveTimer = Timer(delay, () {
      _autoSaveTimer = null;
      if (!_isDisposed) {
        unawaited(_save(flush: false, rethrowErrors: false));
      }
    });
  }

  void _onSessionChanged() {
    _syncPdfText();
    notifyListeners();
    _scheduleAutoSave();
  }

  /// Adopts changes made to the document directly (a settings screen, say).
  void _onDocumentChanged() {
    if (!_isSwitching) {
      final stored = document.page(pageId);
      if (document.indexOf(pageId) < 0) {
        _switching(() {
          _retire(_session);
          _openPage(document.pageIds.first);
        });
      } else if (!_session.isModified &&
          !_session.areSharedObjectsModified &&
          (!identical(stored, _session.snapshot()) ||
              !listEquals(document.documentObjects, _session.shared.objects))) {
        _switching(() {
          final id = pageId;
          _retire(_session);
          _openPage(id);
        });
      }
    }
    notifyListeners();
    _scheduleAutoSave();
  }

  void _onRecordingsChanged() {
    if (_isSyncingRecordings) return;
    final json = recordings!.toJson();
    final encoded = NoteJson.encode(json);
    if (encoded == _recordingsJson) return;
    _recordingsJson = encoded;
    document.recordings = json;
  }

  /// Gives a live recording list the page numbers after pages moved.
  void _syncRecordings() {
    final controller = recordings;
    if (controller == null) return;
    _isSyncingRecordings = true;
    try {
      for (final recording in List.of(controller.recordings)) {
        controller.attachToPage(
          recording.id,
          document.recordingPageNumber(recording.id),
        );
      }
    } finally {
      _isSyncingRecordings = false;
    }
    _recordingsJson = NoteJson.encode(controller.toJson());
  }

  static NotePage _withMargins(
    NotePage page,
    EdgeInsets margins,
    NotePaperTemplate? marginTemplate,
  ) {
    final resized = NotePageOps.setMargins(page, margins);

    return marginTemplate == null
        ? resized
        : resized.copyWith(marginTemplate: () => marginTemplate);
  }

  /// How the ink moves when margins change from [from] to [to].
  static Scribble Function(Scribble)? _shift(EdgeInsets from, EdgeInsets to) {
    final shift = Offset(to.left - from.left, to.top - from.top);

    return shift == Offset.zero
        ? null
        : (scribble) => NoteInkTransforms.translate(scribble, shift);
  }

  bool _goToIndex(int index) =>
      index >= 0 && index < pageCount && goToPage(document.pageAt(index).id);

  int _insertIndex(NotePageInsertPosition position) => switch (position) {
    NotePageInsertPosition.before => pageIndex,
    NotePageInsertPosition.after => pageIndex + 1,
    NotePageInsertPosition.end => pageCount,
  };

  /// Runs a page switch without adopting the document changes it makes, then
  /// notifies once.
  void _switching(VoidCallback body) {
    final wasSwitching = _isSwitching;
    _isSwitching = true;
    try {
      body();
    } finally {
      _isSwitching = wasSwitching;
    }
    notifyListeners();
    _scheduleAutoSave();
  }

  void _openPage(String pageId) {
    _session = NotePageSession(
      document.page(pageId)!,
      registry: document.registry,
      sharedObjects: document.documentObjects,
      idFactory: _idFactory,
      clock: _clock,
      objectStrings: objectStrings,
      layerName: layerName,
    )..addListener(_onSessionChanged);
    _writingSeen = 0;
    _session.layers.strokeConstraintFor = _alongRuler;
    _syncPdfText();
  }

  Offset Function(Offset position)? _alongRuler(Offset start) {
    final edge = ruler.edgeNear(start);

    return edge == null
        ? null
        : (point) => ruler.projectOnto(edge, point, clampToLength: false);
  }

  void _leavePage() {
    _isPaletteOpen = false;
    _flushInput();
    _session.objects.endEditing();
    _session.shared.endEditing();
    _dropLasso();
    _maskPen.cancel();
    _selectedImageId = null;
    commit(flush: false);
    _retire(_session);
  }

  /// Disposes a replaced session once the frame that stops showing it is done.
  void _retire(NotePageSession session) {
    session.removeListener(_onSessionChanged);
    _retired.add(session);
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _disposeRetired(session))
      ..ensureVisualUpdate();
  }

  void _disposeRetired(NotePageSession session) {
    if (_retired.remove(session)) session.dispose();
  }

  void _flushInput() {
    for (final controller in [_session.objects, _session.shared]) {
      final editingId = controller.editingId;
      final editing = editingId == null ? null : controller.find(editingId);
      if (editing is NoteTableObject) {
        final flushed = tableSelection.flushEditor(editing);
        if (flushed != editing) controller.update(flushed);
      }
      controller.flushPendingEdits();
    }
  }

  bool _editSelectedTexts(TextDrawable Function(TextDrawable text) change) {
    final scribble = layers.activeNotifier.currentScribble;
    final texts = [...scribble.textDrawables];
    var changed = false;
    for (final index in lassoSelection.textIndexes) {
      if (index < 0 || index >= texts.length) continue;
      texts[index] = change(texts[index]);
      changed = true;
    }
    if (!changed) return false;
    layers.activeNotifier.setScribble(
      scribble: scribble.copyWithContents(textDrawables: texts),
    );

    return true;
  }

  static TextDrawable _withBoxStyle(TextDrawable text, NoteTextBoxStyle style) {
    if (style == NoteTextBoxStyle.plain) {
      text.clearBoxStyle();
    } else {
      text.boxStyle = style.encode();
    }

    return text;
  }

  void _dropLasso() {
    if (lassoSelection.isEmpty) return;
    lassoSelection.clear();
    layers.activeNotifier.removeLassoStrokes();
  }

  void _updateAll(NoteObjectController controller, List<NoteObject> next) {
    controller.beginGesture();
    for (final object in next) {
      final current = controller.find(object.id);
      if (current != null && current != object) controller.update(object);
    }
    controller.endGesture();
  }
}
