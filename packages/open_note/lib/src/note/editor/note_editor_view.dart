import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/module/widgets/scribble_widget.dart'
    show PanDirection;
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/internal/note_editor_drawer_kind.dart';
import 'package:open_note/src/note/editor/internal/note_editor_drawers.dart';
import 'package:open_note/src/note/editor/internal/note_editor_toolbar.dart';
import 'package:open_note/src/note/editor/internal/note_object_options.dart';
import 'package:open_note/src/note/editor/internal/note_page_overlay.dart';
import 'package:open_note/src/note/editor/internal/note_pdf_text_bar.dart';
import 'package:open_note/src/note/editor/internal/note_quick_palette.dart';
import 'package:open_note/src/note/editor/internal/note_side_panel.dart';
import 'package:open_note/src/note/editor/internal/note_tool_options.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/editor/note_export.dart';
import 'package:open_note/src/note/editor/note_page_content.dart';
import 'package:open_note/src/note/document/note_page_background.dart';
import 'package:open_note/src/note/io/render/note_region_capture.dart';
import 'package:open_note/src/note/layer/note_layered_page_view.dart';
import 'package:open_note/src/note/nav/note_tag_editor.dart';
import 'package:open_note/src/note/nav/note_tag_ref.dart';
import 'package:open_note/src/note/objects/note_sticker_manager.dart';
import 'package:open_note/src/note/objects/note_sticker_manager_style.dart';
import 'package:open_note/src/note/objects/note_sticker_object.dart';
import 'package:open_note/src/note/objects/note_sticker_store.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_controller.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_request.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_result_panel.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_service.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_controller.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_host.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_spec.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_controller.dart';
import 'package:open_note/src/note/study/utilities/note_calculator_view.dart';
import 'package:open_note/src/note/study/utilities/note_recording_list.dart';
import 'package:open_note/src/note/study/utilities/note_scratchpad_controller.dart';
import 'package:open_note/src/note/study/utilities/note_scratchpad_view.dart';
import 'package:open_note/src/note/study/utilities/note_stopwatch_controller.dart';
import 'package:open_note/src/note/study/utilities/note_stopwatch_view.dart';
import 'package:open_note/src/note/study/utilities/note_timer_controller.dart';
import 'package:open_note/src/note/study/utilities/note_timer_view.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/tools/note_color_picker.dart';
import 'package:open_note/src/note/tools/note_eraser_settings_panel.dart';
import 'package:open_note/src/note/tools/note_pen_settings_sheet.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture_panel.dart';
import 'package:open_note/src/note/tools/note_text_style_preset_store.dart';
import 'package:open_note/src/note/tools/note_tool_preset_bar.dart';
import 'package:open_note/src/note/tools/note_toolbar_dock_edge.dart';
import 'package:open_note/src/note/tools/note_toolbar_layout.dart';
import 'package:open_note/src/note/tools/note_toolbar_placement.dart';
import 'package:open_note/src/note/view/note_chrome_visibility.dart';
import 'package:open_note/src/note/view/note_display_filter.dart';
import 'package:open_note/src/note/view/note_full_screen_controller.dart';
import 'package:open_note/src/note/view/note_magnifier.dart';
import 'package:open_note/src/note/view/note_magnifier_controller.dart';
import 'package:open_note/src/note/view/note_thumbnail_grid_controller.dart';
import 'package:open_note/src/note/view/note_zoom_lock.dart';
import 'package:open_note/src/note/view/note_zoom_presets.dart';
import 'package:open_note/src/note/view/note_zoom_math.dart';
import 'package:open_note/src/note/study/utilities/note_audio_recorder.dart';
import 'package:open_note/src/note/study/utilities/note_attachment.dart';

/// The note editor: toolbar and tool settings, the page with its layers and
/// objects, side panels (layers, pages, bookmarks, outline), page, view and
/// study menus, covering and capturing.
///
/// Drive it with a [NoteEditorController]; everything the editor needs from
/// the platform is optional and handed in: picking pictures, keeping captured
/// ones, an AI service, extra floating windows (a web or chat view) and export.
///
/// It needs a `Directionality`, a `MediaQuery` and, for tooltips, an
/// `Overlay` — any app widget provides them.
class NoteEditorView extends StatefulWidget {
  const NoteEditorView({
    required this.controller,
    super.key,
    this.strings = const NoteEditorStrings(),
    this.style = const NoteEditorStyle(),
    this.toolbarLayout,
    this.onToolbarLayoutChanged,
    this.textStyles,
    this.fontFamilies = const [],
    this.paperTemplates = const [],
    this.stickerStore,
    this.imageProviderResolver = resolveImageSource,
    this.onPickImages,
    this.onStoreImage,
    this.aiPenService,
    this.studyWindows = const [],
    this.audioRecorder,
    this.onPickAttachment,
    this.onOpenAttachment,
    this.zoomPresets,
    this.onExport,
    this.onImportPages,
    this.onBack,
    this.maxZoom = 5,
  });

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;

  /// Which tools show, their order and where the bar sits. The user's choice is
  /// the host's to keep.
  final NoteToolbarLayout? toolbarLayout;

  /// The floating toolbar was moved.
  final ValueChanged<NoteToolbarLayout>? onToolbarLayoutChanged;

  /// Text style favourites; the built-in ones when null.
  final NoteTextStylePresetStore? textStyles;

  /// Fonts the app loaded (for example with `NoteFontManager`), offered for
  /// selected text boxes.
  final List<String> fontFamilies;

  /// Papers offered besides the built-in ones.
  final List<NotePaperTemplate> paperTemplates;

  final NoteStickerStore? stickerStore;

  final NoteImageProviderResolver imageProviderResolver;

  /// Lets the user choose pictures; without it there is no "add pictures".
  final Future<List<NoteImageInsert>> Function()? onPickImages;

  /// Keeps a captured picture and returns its source; needed to make
  /// stickers from captures.
  final Future<String> Function(Uint8List png)? onStoreImage;

  /// The AI pen (solve, explain, translate); without it there is no "ask AI".
  final NoteAiPenService? aiPenService;

  /// More floating windows for the study menu, such as a web or chat view.
  final List<NoteFloatingWindowSpec> studyWindows;

  /// Records audio into `controller.recordings`; without it there is no
  /// record button.
  final NoteAudioRecorder? audioRecorder;

  /// Lets the user choose a file to attach to the note.
  final Future<NoteAttachment?> Function()? onPickAttachment;

  /// Opens an attached file.
  final ValueChanged<NoteAttachment>? onOpenAttachment;

  /// The zoom favourites of the view menu (the user's to keep); 150, 200 and
  /// 300 % when null.
  final NoteZoomPresets? zoomPresets;

  /// Exports the note (see `exportNotePdf`).
  final VoidCallback? onExport;

  /// Lets the user bring pages in: choose another note or a file, then call
  /// `controller.importPages` or `controller.insertPages`.
  final Future<void> Function()? onImportPages;

  final VoidCallback? onBack;

  final double maxZoom;

  @override
  State<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<NoteEditorView> {
  final TransformationController _transform = TransformationController();
  final NoteMagnifierController _magnifier = NoteMagnifierController();
  final NoteZoomLock _zoomLock = NoteZoomLock();
  final NoteFullScreenController _fullScreen = NoteFullScreenController();
  final NoteThumbnailGridController _thumbnails = NoteThumbnailGridController(
    columns: 2,
  );
  final NoteFloatingWindowController _windows = NoteFloatingWindowController();
  NoteTextStylePresetStore? _ownTextStyles;
  NoteCalculatorController? _calculator;
  NoteTimerController? _timer;
  NoteStopwatchController? _stopwatch;
  NoteScratchpadController? _scratchpad;
  NoteAiPenController? _ai;
  Uint8List? _aiImage;
  NoteEditorDrawerKind? _drawer;
  NoteSidePanelTab? _panel;
  bool _showPresets = false;
  NoteDisplayMode _display = NoteDisplayMode.normal;
  Rect? _captured;
  Offset? _floatingOffset;
  NoteToolbarLayout? _editedToolbar;
  NoteZoomPresets? _ownZoomPresets;

  /// Swiping turns pages in reading mode along this axis; null turns it off.
  Axis? _swipe = Axis.horizontal;
  final Map<int, Offset> _swipeStarts = {};
  bool _swipeHadTwo = false;
  bool _isGrowthScheduled = false;
  bool _isRestoringPlace = false;
  bool _wasPaletteOpen = false;
  Offset? _stylusPosition;
  Offset? _paletteAnchor;
  final GlobalKey _paletteKey = GlobalKey();
  late _PageGeometry _geometry;

  /// The page a running recording started on.
  String? _recordingPageId;
  final GlobalKey _canvasKey = GlobalKey();
  late String _pageId;

  NoteToolbarLayout get _toolbarLayout =>
      _editedToolbar ?? widget.toolbarLayout ?? NoteToolbarLayout();

  NoteZoomPresets get _zoomPresets =>
      widget.zoomPresets ??
      (_ownZoomPresets ??= NoteZoomPresets(const [1.5, 2, 3]));

  NoteEditorController get _controller => widget.controller;

  NoteEditorStrings get _strings => widget.strings;

  NoteEditorStyle get _style => widget.style;

  NoteTextStylePresetStore get _textStyles =>
      widget.textStyles ??
      (_ownTextStyles ??= NoteTextStylePresetStore.defaults(
        strings: _strings.tools,
      ));

  @override
  void initState() {
    super.initState();
    _pageId = _controller.pageId;
    _geometry = _PageGeometry.of(_controller.page);
    _controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(NoteEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != _controller) {
      oldWidget.controller.removeListener(_onController);
      _controller.addListener(_onController);
      _pageId = _controller.pageId;
      _geometry = _PageGeometry.of(_controller.page);
      _captured = null;
    }
    if (widget.toolbarLayout != oldWidget.toolbarLayout) {
      _editedToolbar = null;
      _floatingOffset = null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _transform.dispose();
    _magnifier.dispose();
    _zoomLock.dispose();
    _fullScreen.dispose();
    _thumbnails.dispose();
    _windows.dispose();
    _ownTextStyles?.dispose();
    _ownZoomPresets?.dispose();
    _calculator?.dispose();
    _timer?.dispose();
    _stopwatch?.dispose();
    _scratchpad?.dispose();
    _ai?.dispose();
    super.dispose();
  }

  void _onController() {
    if (_controller.pageId != _pageId) {
      _pageId = _controller.pageId;
      _transform.value = Matrix4.identity();
      _captured = null;
    }
    _keepPlaceAsPageGrows();
    // The palette stays where the pen was when it opened.
    if (_controller.isPaletteOpen != _wasPaletteOpen) {
      _wasPaletteOpen = _controller.isPaletteOpen;
      _paletteAnchor = _stylusPosition;
    }
    if (_controller.mode != NoteEditorMode.region) _captured = null;
  }

  @override
  Widget build(BuildContext context) {
    final undo = _controller.undo;
    final redo = _controller.redo;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): redo,
        if (_controller.pdfText.selected.isNotEmpty) ...{
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true): _copyText,
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              _copyText,
        },
      },
      child: Focus(
        autofocus: true,
        child: DefaultTextStyle(
          style: _style.textStyle,
          child: ListenableBuilder(
            listenable: Listenable.merge([_controller, _fullScreen, _zoomLock]),
            builder: (context, _) => ColoredBox(
              color: _style.barColor,
              child: NoteFloatingWindowHost(
                controller: _windows,
                strings: _strings.studyOverlay,
                child: _layout(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _copyText() => unawaited(
    Clipboard.setData(ClipboardData(text: _controller.pdfText.selectedText)),
  );

  Widget _layout() {
    final layout = _toolbarLayout;
    final docked = layout.placement == NoteToolbarPlacement.docked;
    final edge = layout.dockEdge;
    final hidden = _fullScreen.chromeHidden;
    final panel = _panel;
    Widget? dock(NoteToolbarDockEdge at) =>
        !hidden && docked && edge == at ? _toolbar(layout, at) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteChromeVisibility(
          hidden: hidden,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topBar(),
              ?dock(NoteToolbarDockEdge.top),
              ..._contextBars(),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?dock(NoteToolbarDockEdge.left),
              Expanded(child: _canvas(layout)),
              if (!hidden && panel != null)
                SizedBox(
                  width: _style.panelWidth,
                  child: NoteSidePanel(
                    controller: _controller,
                    strings: _strings,
                    style: _style,
                    tab: panel,
                    thumbnails: _thumbnails,
                    imageProviderResolver: widget.imageProviderResolver,
                    onTab: (tab) => setState(() => _panel = tab),
                    onClose: () => setState(() => _panel = null),
                  ),
                ),
              ?dock(NoteToolbarDockEdge.right),
            ],
          ),
        ),
        ?dock(NoteToolbarDockEdge.bottom),
      ],
    );
  }

  Widget _toolbar(NoteToolbarLayout layout, NoteToolbarDockEdge edge) {
    final horizontal =
        edge == NoteToolbarDockEdge.top || edge == NoteToolbarDockEdge.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _style.barColor,
        border: Border.all(color: _style.dividerColor, width: 0.5),
      ),
      child: NoteEditorToolbar(
        controller: _controller,
        layout: layout,
        strings: _strings,
        style: _style,
        axis: horizontal ? Axis.horizontal : Axis.vertical,
        layersShown: _panel == NoteSidePanelTab.layers,
        presetsShown: _showPresets,
        onToggleLayers: () => _togglePanel(NoteSidePanelTab.layers),
        onTogglePresets: () => setState(() => _showPresets = !_showPresets),
      ),
    );
  }

  Widget _topBar() {
    final controller = _controller;

    return NoteEditorStrip(
      style: _style,
      children: [
        if (widget.onBack != null) _top('back', _strings.back, widget.onBack),
        _top(
          'previous',
          '‹',
          controller.pageIndex > 0 ? controller.previousPage : null,
          semanticLabel: _strings.previousPage,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            _strings.pageCounter(
              controller.pageLabel,
              controller.pageIndex,
              controller.pageCount,
            ),
            key: const ValueKey('note-page-counter'),
          ),
        ),
        _top(
          'next',
          '›',
          controller.pageIndex < controller.pageCount - 1
              ? controller.nextPage
              : null,
          semanticLabel: _strings.nextPage,
        ),
        _top('add-page', _strings.addPage, () => controller.addPage()),
        _drawerButton(
          'page-menu',
          _strings.pageMenu,
          NoteEditorDrawerKind.pageMenu,
        ),
        for (final (mode, label) in [
          (NoteEditorMode.draw, _strings.drawMode),
          (NoteEditorMode.objects, _strings.objectMode),
          (NoteEditorMode.read, _strings.readMode),
          (NoteEditorMode.maskPen, _strings.maskMode),
          (NoteEditorMode.region, _strings.regionMode),
          if (controller.canSelectPdfText ||
              controller.mode == NoteEditorMode.pdfText)
            (NoteEditorMode.pdfText, _strings.pdfTextMode),
        ])
          _top(
            'mode-${mode.name}',
            label,
            () => controller.mode = mode,
            selected: controller.mode == mode,
          ),
        _top(
          'bookmark',
          controller.isBookmarked ? _strings.removeBookmark : _strings.bookmark,
          controller.toggleBookmark,
          selected: controller.isBookmarked,
        ),
        for (final (tab, label) in [
          (NoteSidePanelTab.pages, _strings.pagesPanel),
          (NoteSidePanelTab.outline, _strings.outlinePanel),
          (NoteSidePanelTab.bookmarks, _strings.bookmarksPanel),
          (NoteSidePanelTab.excerpts, _strings.excerptsPanel),
        ])
          _top(
            'panel-${tab.name}',
            label,
            () => _togglePanel(tab),
            selected: _panel == tab,
          ),
        _drawerButton(
          'view-menu',
          _strings.viewMenu,
          NoteEditorDrawerKind.viewMenu,
        ),
        _drawerButton(
          'study-menu',
          _strings.studyMenu,
          NoteEditorDrawerKind.studyMenu,
        ),
        if (controller.repository != null)
          _top(
            'save',
            controller.isSaving
                ? _strings.saving
                : controller.saveError != null
                ? _strings.saveFailed
                : controller.hasUnsavedChanges
                ? _strings.unsaved
                : _strings.saved,
            controller.hasUnsavedChanges && !controller.isSaving ? _save : null,
          ),
        if (_recordingPageId != null)
          _top(
            'stop-recording',
            _strings.stopRecording,
            () => _runHostTask(_stopRecording),
            selected: true,
          ),
        if (widget.onExport != null)
          _top('export', _strings.export, widget.onExport),
      ],
    );
  }

  List<Widget> _contextBars() {
    final controller = _controller;
    final drawer = _drawer;

    return [
      if (_showPresets && controller.mode == NoteEditorMode.draw)
        SizedBox(
          height: 72,
          child: NoteToolPresetBar(
            store: controller.tools.presets,
            strings: _strings.tools,
            onSelected: (preset) {
              controller.tools.applyPreset(preset);
              controller.mode = NoteEditorMode.draw;
            },
          ),
        ),
      if (controller.mode == NoteEditorMode.draw)
        NoteToolOptions(
          controller: controller,
          strings: _strings,
          style: _style,
          textStyles: _textStyles,
          fontFamilies: widget.fontFamilies,
          onDrawer: _toggleDrawer,
          onAddImages: widget.onPickImages == null
              ? null
              : () => _runHostTask(_addImages),
        )
      else if (controller.mode == NoteEditorMode.pdfText)
        NotePdfTextBar(controller: controller, strings: _strings, style: _style)
      else
        NoteObjectOptions(
          controller: controller,
          strings: _strings,
          style: _style,
          onDrawer: _toggleDrawer,
        ),
      if (drawer != null)
        NoteDrawerSurface(
          key: ValueKey('note-drawer-${drawer.name}'),
          style: _style,
          child: _drawerContent(drawer),
        ),
    ];
  }

  Widget _drawerContent(NoteEditorDrawerKind drawer) {
    final controller = _controller;
    final tools = controller.tools;

    return switch (drawer) {
      NoteEditorDrawerKind.colors => NoteColorPicker(
        color: tools.color,
        strings: _strings.tools,
        onChanged: tools.setColor,
      ),
      NoteEditorDrawerKind.pencilGestures => NotePencilGesturePanel(
        map: tools.gestures,
        strings: _strings.tools,
        onChanged: (map) => tools.gestures = map,
      ),
      NoteEditorDrawerKind.penSettings => NotePenSettingsSheet(
        settings: tools.penSettings,
        strings: _strings.tools,
        onChanged: (settings) => tools.penSettings = settings,
      ),
      NoteEditorDrawerKind.eraserSettings => NoteEraserSettingsPanel(
        settings: tools.eraserSettings,
        strings: _strings.tools,
        onChanged: (settings) => tools.eraserSettings = settings,
      ),
      NoteEditorDrawerKind.pageMenu => NotePageMenuDrawer(
        controller: controller,
        strings: _strings,
        style: _style,
        onDrawer: _openDrawer,
        onClose: _closeDrawer,
        onImportPages: widget.onImportPages == null
            ? null
            : () => _runHostTask(widget.onImportPages!),
      ),
      NoteEditorDrawerKind.pageTags => NoteTagEditor(
        key: ValueKey('note-page-tags-${controller.pageId}'),
        tags: controller.document.tags,
        target: NoteTagRef(
          noteId: controller.document.id,
          pageId: controller.pageId,
        ),
        strings: _strings.nav,
      ),
      NoteEditorDrawerKind.paper => NotePaperDrawer(
        controller: controller,
        strings: _strings,
        style: _style,
        extraTemplates: widget.paperTemplates,
        imageProviderResolver: widget.imageProviderResolver,
      ),
      NoteEditorDrawerKind.stickers => _stickers(),
      NoteEditorDrawerKind.linkPages => NoteLinkPagesDrawer(
        controller: controller,
        strings: _strings,
        style: _style,
        onClose: _closeDrawer,
      ),
      NoteEditorDrawerKind.viewMenu => _viewMenu(),
      NoteEditorDrawerKind.toolbar => NoteToolbarDrawer(
        layout: _toolbarLayout,
        strings: _strings,
        style: _style,
        onChanged: _changeToolbar,
      ),
      NoteEditorDrawerKind.attachments => NoteAttachmentsDrawer(
        attachments: controller.document.attachments,
        strings: _strings,
        style: _style,
        onOpen: widget.onOpenAttachment,
        onAttach: widget.onPickAttachment == null
            ? null
            : () => _runHostTask(_attachFile),
      ),
      NoteEditorDrawerKind.studyMenu => _studyMenu(),
      NoteEditorDrawerKind.imageCrop => NoteImageCropDrawer(
        controller: controller,
        strings: _strings,
        style: _style,
        imageProviderResolver: widget.imageProviderResolver,
        onClose: _closeDrawer,
      ),
      NoteEditorDrawerKind.aiPen => _aiPanel(),
    };
  }

  Widget _stickers() {
    final store = widget.stickerStore;
    if (store == null) {
      return Text(_strings.noStickers, style: _style.textStyle);
    }
    final pick = widget.onPickImages;

    return NoteStickerManager(
      store: store,
      imageProviderResolver: widget.imageProviderResolver,
      strings: _strings.objects,
      style: NoteStickerManagerStyle(
        textStyle: _style.textStyle,
        mutedColor: _style.mutedColor,
        accentColor: _style.accentColor,
        selectedColor: _style.selectedColor,
      ),
      onPickPictures: pick == null
          ? null
          : () async => [for (final picture in await pick()) picture.source],
      onSelected: (item) {
        _controller.addObject(
          NoteStickerObject(
            id: _controller.newId(),
            bounds: _controller.placement(const Size(140, 140)),
            source: item.source,
          ),
        );
        _closeDrawer();
      },
    );
  }

  Widget _canvas(NoteToolbarLayout layout) {
    final controller = _controller;
    final page = controller.page;
    final hidden = _fullScreen.chromeHidden;
    final floating = layout.placement == NoteToolbarPlacement.floating;
    final offset = _floatingOffset ?? layout.floatingOffset;
    final captured = _captured;

    return Listener(
      key: _canvasKey,
      onPointerDown: _canvasDown,
      onPointerHover: _trackStylus,
      onPointerUp: _swipeUp,
      onPointerCancel: (event) => _swipeStarts.remove(event.pointer),
      child: ClipRect(
        child: ColoredBox(
          color: _style.canvasColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NoteDisplayFilter(
                mode: _display,
                child: NoteLayeredPageView(
                  key: ObjectKey(controller.session),
                  layers: controller.layers,
                  modeNotifier: controller.modeNotifier,
                  pageSize: page.size,
                  transformationController: _transform,
                  drawingEnabled: controller.mode == NoteEditorMode.draw,
                  zoomEnabled: !_zoomLock.locked,
                  // A grown endless page is fitted smaller, so it may zoom
                  // further to keep the same reach.
                  maxScale:
                      widget.maxZoom *
                      math.max(
                        1,
                        math.max(
                          page.size.width / page.paperSize.width,
                          page.size.height / page.paperSize.height,
                        ),
                      ),
                  panDirection: PanDirection.both,
                  onStrokeFinished: _scheduleGrowth,
                  imageProviderResolver: widget.imageProviderResolver,
                  lassoSelection: controller.lassoSelection,
                  onImageSelectionChanged: controller.selectImage,
                  background: NotePageBackground(
                    page,
                    imageProviderResolver: widget.imageProviderResolver,
                  ),
                  foreground: NotePageOverlay(
                    controller: controller,
                    strings: _strings,
                    onRegionSelected: (region) =>
                        setState(() => _captured = region),
                  ),
                ),
              ),
              NoteMagnifier(controller: _magnifier, strings: _strings.view),
              if (controller.isPaletteOpen)
                Positioned.fill(
                  child: CustomSingleChildLayout(
                    delegate: _NearPen(_paletteAnchor),
                    child: NoteQuickPalette(
                      key: _paletteKey,
                      controller: controller,
                      strings: _strings,
                      style: _style,
                    ),
                  ),
                ),
              if (!hidden && floating)
                Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: _floatingToolbar(layout, offset),
                ),
              if (captured != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Center(child: _captureActions(captured)),
                ),
              if (hidden)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _floatingSurface(
                    _top(
                      'exit-full-screen',
                      _strings.exitFullScreen,
                      _fullScreen.show,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingSurface(Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      color: _style.panelColor,
      borderRadius: BorderRadius.circular(_style.radius),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
    ),
    child: child,
  );

  Widget _floatingToolbar(NoteToolbarLayout layout, Offset offset) =>
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _floatingSurface(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                key: const ValueKey('note-toolbar-handle'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) =>
                    setState(() => _floatingOffset = offset + details.delta),
                onPanEnd: (_) {
                  final moved = _floatingOffset;
                  if (moved == null) return;
                  _floatingOffset = null;
                  _changeToolbar(layout.copyWith(floatingOffset: moved));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('⠿', style: _style.textStyle),
                ),
              ),
              Flexible(
                child: NoteEditorToolbar(
                  controller: _controller,
                  layout: layout,
                  strings: _strings,
                  style: _style,
                  axis: Axis.horizontal,
                  layersShown: _panel == NoteSidePanelTab.layers,
                  presetsShown: _showPresets,
                  onToggleLayers: () => _togglePanel(NoteSidePanelTab.layers),
                  onTogglePresets: () =>
                      setState(() => _showPresets = !_showPresets),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _captureActions(Rect region) => _floatingSurface(
    NoteEditorStrip(
      style: _style,
      children: [
        if (widget.onStoreImage != null)
          _top(
            'make-sticker',
            _strings.makeSticker,
            () => _runHostTask(() => _makeSticker(region)),
          ),
        _top('save-excerpt', _strings.saveExcerpt, () {
          _controller.addExcerpt(region, label: _strings.excerptLabel);
          _finishCapture();
        }),
        if (widget.aiPenService != null)
          _top(
            'ask-ai',
            _strings.askAi,
            () => _runHostTask(() => _askAi(region)),
          ),
        _top('cancel-region', _strings.cancel, _finishCapture),
      ],
    ),
  );

  Widget _viewMenu() => Wrap(
    spacing: _style.spacing,
    runSpacing: _style.spacing,
    children: [
      for (final (mode, label) in [
        (NoteDisplayMode.normal, _strings.normalColors),
        (NoteDisplayMode.night, _strings.nightMode),
        (NoteDisplayMode.eyeProtect, _strings.eyeProtect),
      ])
        _top(
          'display-${mode.name}',
          label,
          () => setState(() => _display = mode),
          selected: _display == mode,
        ),
      _top(
        'ruler',
        _strings.ruler,
        () => setState(_controller.ruler.toggle),
        selected: _controller.ruler.visible,
      ),
      _top(
        'magnifier',
        _strings.magnifier,
        () => setState(_magnifier.toggle),
        selected: _magnifier.visible,
      ),
      _top(
        'zoom-lock',
        _strings.zoomLock,
        () => _zoomLock.setLocked(!_zoomLock.locked),
        selected: _zoomLock.locked,
      ),
      _top(
        'fit-page',
        _strings.fitPage,
        () => _afterClosingDrawer(() => _zoomTo(1)),
      ),
      _top(
        'go-to-writing',
        _strings.goToWriting,
        () => _afterClosingDrawer(_goToWriting),
      ),
      for (final level in _zoomPresets.levels)
        _top(
          'zoom-${(level * 100).round()}',
          _strings.zoomLevel((level * 100).round()),
          () => _afterClosingDrawer(() => _zoomTo(level)),
        ),
      _top('save-zoom', _strings.saveZoom, () {
        setState(
          () => _zoomPresets.toggle(NoteZoomMath.scaleOf(_transform.value)),
        );
      }),
      for (final (axis, label) in [
        (Axis.horizontal, _strings.swipeHorizontal),
        (Axis.vertical, _strings.swipeVertical),
      ])
        _top(
          'swipe-${axis.name}',
          label,
          () => setState(() => _swipe = _swipe == axis ? null : axis),
          selected: _swipe == axis,
        ),
      _top(
        'toolbar-settings',
        _strings.toolbarSettings,
        () => _openDrawer(NoteEditorDrawerKind.toolbar),
      ),
      _top('full-screen', _strings.fullScreen, () {
        _closeDrawer();
        _fullScreen.hide();
      }),
    ],
  );

  Widget _studyMenu() => Wrap(
    spacing: _style.spacing,
    runSpacing: _style.spacing,
    children: [
      _top('calculator', _strings.calculator, () {
        final calculator = _calculator ??= NoteCalculatorController();
        _openWindow(
          'calculator',
          _strings.calculator,
          const Size(280, 420),
          (_) => NoteCalculatorView(
            controller: calculator,
            strings: _strings.studyUtilities,
          ),
        );
      }),
      _top('timer', _strings.timer, () {
        final timer = _timer ??= NoteTimerController();
        _openWindow(
          'timer',
          _strings.timer,
          const Size(280, 240),
          (_) => NoteTimerView(
            controller: timer,
            strings: _strings.studyUtilities,
          ),
        );
      }),
      _top('stopwatch', _strings.stopwatch, () {
        final stopwatch = _stopwatch ??= NoteStopwatchController();
        _openWindow(
          'stopwatch',
          _strings.stopwatch,
          const Size(280, 320),
          (_) => NoteStopwatchView(
            controller: stopwatch,
            strings: _strings.studyUtilities,
          ),
        );
      }),
      _top('scratchpad', _strings.scratchpad, () {
        final scratchpad = _scratchpad ??= NoteScratchpadController();
        _openWindow(
          'scratchpad',
          _strings.scratchpad,
          const Size(340, 320),
          (_) => NoteScratchpadView(
            controller: scratchpad,
            strings: _strings.studyUtilities,
          ),
        );
      }),
      if (_controller.recordings case final recordings?)
        _top('recordings', _strings.recordings, () {
          _openWindow(
            'recordings',
            _strings.recordings,
            const Size(340, 360),
            (_) => ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => NoteRecordingList(
                controller: recordings,
                pageNumber: _controller.pageIndex + 1,
                strings: _strings.studyUtilities,
              ),
            ),
          );
        }),
      if (widget.audioRecorder != null &&
          _controller.recordings != null &&
          _recordingPageId == null)
        _top('record', _strings.record, () {
          _closeDrawer();
          _runHostTask(_startRecording);
        }),
      _top(
        'attachments',
        _strings.attachments,
        () => _openDrawer(NoteEditorDrawerKind.attachments),
      ),
      for (final window in widget.studyWindows)
        _top('window-${window.id}', window.title, () {
          _windows.open(window);
          _closeDrawer();
        }),
    ],
  );

  Widget _aiPanel() {
    final ai = _ai;
    if (ai == null) return const SizedBox.shrink();

    return SizedBox(
      height: _style.drawerMaxHeight - _style.spacing * 4,
      child: NoteAiPenResultPanel(
        controller: ai,
        strings: _strings.studyOverlay,
        onKindSelected: (kind) =>
            unawaited(ai.run(NoteAiPenRequest(kind: kind, imagePng: _aiImage))),
        onClose: () {
          ai.cancel();
          _closeDrawer();
        },
      ),
    );
  }

  void _openWindow(String id, String title, Size size, WidgetBuilder builder) {
    _windows.open(
      NoteFloatingWindowSpec(
        id: id,
        title: title,
        builder: builder,
        initialRect: Offset(24, 24) & size,
      ),
    );
    _closeDrawer();
  }

  Widget _top(
    String key,
    String label,
    VoidCallback? onPressed, {
    bool selected = false,
    String? semanticLabel,
  }) => NoteEditorButton(
    key: ValueKey('note-top-$key'),
    label: label,
    semanticLabel: semanticLabel,
    tooltip: semanticLabel,
    style: _style,
    onPressed: onPressed,
    selected: selected,
  );

  Widget _drawerButton(String key, String label, NoteEditorDrawerKind drawer) =>
      _top(
        key,
        label,
        () => _toggleDrawer(drawer),
        selected: _drawer == drawer,
      );

  void _togglePanel(NoteSidePanelTab tab) =>
      setState(() => _panel = _panel == tab ? null : tab);

  void _toggleDrawer(NoteEditorDrawerKind drawer) =>
      setState(() => _drawer = _drawer == drawer ? null : drawer);

  void _openDrawer(NoteEditorDrawerKind drawer) =>
      setState(() => _drawer = drawer);

  void _closeDrawer() {
    if (mounted) setState(() => _drawer = null);
  }

  void _changeToolbar(NoteToolbarLayout layout) {
    setState(() => _editedToolbar = layout);
    widget.onToolbarLayoutChanged?.call(layout);
  }

  /// The open drawer shrinks the page area, so zoom is worked out after it
  /// is gone and the page has its final size.
  void _afterClosingDrawer(VoidCallback action) {
    _closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  /// The render box of the first [T] under the canvas.
  RenderBox? _canvasBox<T extends Widget>() {
    RenderBox? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget is T) {
        final box = element.renderObject;
        if (box is RenderBox && box.hasSize) found = box;

        return;
      }
      element.visitChildren(visit);
    }

    _canvasKey.currentContext?.visitChildElements(visit);

    return found;
  }

  /// Zooms to [scale] (1 fits the page) around the middle of the view.
  void _zoomTo(double scale) {
    final viewer = _canvasBox<InteractiveViewer>();
    if (viewer == null) return;
    _transform.value = scale <= 1.001
        ? Matrix4.identity()
        : NoteZoomMath.zoomAround(
            _transform.value,
            viewer.size.center(Offset.zero),
            scale,
            max: widget.maxZoom,
          );
  }

  /// Zooms onto what is on the page.
  void _goToWriting() {
    final content = notePageContentBounds(_controller.page);
    final viewer = _canvasBox<InteractiveViewer>();
    final paper = _canvasBox<NotePageBackground>();
    if (viewer == null || paper == null) return;
    if (content == null) {
      _transform.value = Matrix4.identity();

      return;
    }
    // Where the content is in the viewer before its transform.
    Offset untransformed(Offset page) => NoteZoomMath.toContent(
      _transform.value,
      viewer.globalToLocal(paper.localToGlobal(page)),
    );
    final area = Rect.fromPoints(
      untransformed(content.topLeft),
      untransformed(content.bottomRight),
    );
    final fit =
        0.9 *
        math.min(
          viewer.size.width / math.max(area.width, 1),
          viewer.size.height / math.max(area.height, 1),
        );
    final scale = fit.clamp(1.0, widget.maxZoom);
    _transform.value = scale <= 1.001
        ? Matrix4.identity()
        : NoteZoomMath.centerOn(area, viewer.size, scale);
  }

  /// Checks for growth once the edit that finished has been recorded (the
  /// engine also reports a finish while undo or a page change is applying).
  void _scheduleGrowth() {
    if (_isGrowthScheduled) return;
    _isGrowthScheduled = true;
    scheduleMicrotask(() {
      _isGrowthScheduled = false;
      if (mounted) _controller.growAfterWriting();
    });
  }

  /// When an endless page grows, or undo and redo change its growth, keeps
  /// what is on screen where it was although the page is fitted at another
  /// size.
  void _keepPlaceAsPageGrows() {
    final page = _controller.page;
    final previous = _geometry;
    final geometry = _PageGeometry.of(page);
    _geometry = geometry;
    if (!page.autoGrows ||
        _isRestoringPlace ||
        !geometry.isRegrowthOf(previous)) {
      return;
    }
    // Still the layout from before the change: it is rebuilt next frame.
    final before = _paperPlacement();
    if (before == null) return;
    _isRestoringPlace = true;
    final transform = _transform.value.clone();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isRestoringPlace = false;
      if (!mounted) return;
      _restorePlace(before, transform, previous.margins);
    });
  }

  void _restorePlace(
    ({Offset origin, double scale}) before,
    Matrix4 transform,
    EdgeInsets margins,
  ) {
    final after = _paperPlacement();
    if (after == null || after.scale <= 0) return;
    // Growing left or up moved the content by this much on the page.
    final shift = _controller.page.margins.topLeft - margins.topLeft;
    final zoom = NoteZoomMath.scaleOf(transform);
    final next = zoom * before.scale / after.scale;
    _transform.value = next < 0.999
        ? Matrix4.identity()
        : NoteZoomMath.matrix(
            next,
            before.origin * zoom +
                NoteZoomMath.translationOf(transform) -
                (after.origin + shift * after.scale) * next,
          );
  }

  /// Where the fitted page sits in the viewer before its transform.
  ({Offset origin, double scale})? _paperPlacement() {
    final viewer = _canvasBox<InteractiveViewer>();
    final paper = _canvasBox<NotePageBackground>();
    if (viewer == null || paper == null) return null;
    Offset untransformed(Offset page) => NoteZoomMath.toContent(
      _transform.value,
      viewer.globalToLocal(paper.localToGlobal(page)),
    );
    final origin = untransformed(Offset.zero);

    return (
      origin: origin,
      scale: (untransformed(const Offset(100, 0)) - origin).distance / 100,
    );
  }

  /// A press outside the quick palette closes it and still reaches the page.
  void _canvasDown(PointerDownEvent event) {
    _trackStylus(event);
    if (_controller.isPaletteOpen && !_isOnPalette(event.position)) {
      _controller.closePalette();
    }
    _swipeDown(event);
  }

  void _trackStylus(PointerEvent event) {
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      _stylusPosition = event.localPosition;
    }
  }

  bool _isOnPalette(Offset global) {
    final box = _paletteKey.currentContext?.findRenderObject();

    return box is RenderBox &&
        (box.localToGlobal(Offset.zero) & box.size).contains(global);
  }

  void _swipeDown(PointerDownEvent event) {
    if (_controller.mode != NoteEditorMode.read) return;
    _swipeStarts[event.pointer] = event.position;
    if (_swipeStarts.length > 1) _swipeHadTwo = true;
  }

  /// A one-finger flick along [_swipe] turns the page when the page is not
  /// zoomed.
  void _swipeUp(PointerUpEvent event) {
    final start = _swipeStarts.remove(event.pointer);
    if (start == null || _swipeStarts.isNotEmpty) return;
    final hadTwo = _swipeHadTwo;
    _swipeHadTwo = false;
    final axis = _swipe;
    if (hadTwo ||
        axis == null ||
        _controller.mode != NoteEditorMode.read ||
        NoteZoomMath.scaleOf(_transform.value) > 1.01) {
      return;
    }
    final delta = event.position - start;
    final along = axis == Axis.horizontal ? delta.dx : delta.dy;
    final across = axis == Axis.horizontal ? delta.dy : delta.dx;
    if (along.abs() < 80 || across.abs() > along.abs() / 2) return;
    along < 0 ? _controller.nextPage() : _controller.previousPage();
  }

  Future<void> _startRecording() async {
    final pageId = _controller.pageId;
    await widget.audioRecorder!.start();
    if (mounted) setState(() => _recordingPageId = pageId);
  }

  Future<void> _stopRecording() async {
    final recording = await widget.audioRecorder!.stop();
    if (!mounted) return;
    final controller = _controller;
    final index = controller.document.indexOf(_recordingPageId ?? '');
    controller.recordings?.add(
      recording.copyWith(
        pageNumber: (index < 0 ? controller.pageIndex : index) + 1,
      ),
    );
    setState(() => _recordingPageId = null);
  }

  Future<void> _attachFile() async {
    final document = _controller.document;
    final attachment = await widget.onPickAttachment!();
    if (attachment != null) document.attachments.insert(attachment);
  }

  /// Runs work that calls into the host (a picker, storage, a service) and
  /// reports its failure instead of leaving it unhandled.
  void _runHostTask(Future<void> Function() task) {
    unawaited(
      task().catchError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'open_note editor',
          ),
        );
      }),
    );
  }

  void _save() {
    unawaited(
      _controller.save().catchError((Object error, StackTrace stack) {
        // The button shows the failure (saveError); report it as well.
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }),
    );
  }

  Future<void> _addImages() async {
    final controller = _controller;
    final images = await widget.onPickImages!();
    if (mounted && identical(controller, _controller)) {
      controller.insertImages(images);
    }
  }

  void _finishCapture() {
    setState(() => _captured = null);
    _controller.mode = NoteEditorMode.draw;
  }

  /// The open page's [region] as a PNG; null when the page changed meanwhile.
  Future<Uint8List?> _render(Rect region, {required bool transparent}) async {
    final controller = _controller..commit();
    final page = controller.page;
    final shared = controller.session.shared.objects;
    final images = await loadNoteImages(
      notePageImageSources(page, shared: shared),
      resolver: widget.imageProviderResolver,
    );
    try {
      final png = await NoteRegionCapture.capture(
        notePageRenderInput(page, shared: shared, images: images),
        region,
        transparentBackground: transparent,
      );

      return mounted && controller.pageId == page.id ? png : null;
    } finally {
      for (final image in images.values) {
        image.dispose();
      }
    }
  }

  Future<void> _makeSticker(Rect region) async {
    final png = await _render(region, transparent: true);
    if (png == null) return;
    final source = await widget.onStoreImage!(png);
    if (!mounted) return;
    final store = widget.stickerStore;
    if (store != null) {
      final collection =
          store.collections
              .where((c) => c.name == _strings.captureCollection)
              .firstOrNull ??
          store.createCollection(_strings.captureCollection);
      store.addItem(collection.id, source);
    }
    _finishCapture();
    _controller.addObject(
      NoteStickerObject(
        id: _controller.newId(),
        bounds: _controller.placement(region.size, center: region.center),
        source: source,
      ),
    );
  }

  Future<void> _askAi(Rect region) async {
    final png = await _render(region, transparent: false);
    if (png == null) return;
    final ai = _ai ??= NoteAiPenController(service: widget.aiPenService!);
    _aiImage = png;
    _finishCapture();
    _openDrawer(NoteEditorDrawerKind.aiPen);
    await ai.run(NoteAiPenRequest(kind: NoteAiPenKind.solve, imagePng: png));
  }
}

/// What decides where the open page's content is shown.
class _PageGeometry {
  const _PageGeometry(this.pageId, this.margins, this.content, this.turns);

  factory _PageGeometry.of(NotePage page) => _PageGeometry(
    page.id,
    page.margins,
    page.contentRect.size,
    page.paperTurns,
  );

  final String pageId;
  final EdgeInsets margins;
  final Size content;
  final int turns;

  /// Whether only the margins of the same page changed since [other].
  bool isRegrowthOf(_PageGeometry other) =>
      other.pageId == pageId &&
      other.turns == turns &&
      other.content == content &&
      other.margins != margins;
}

/// Places the quick palette above the pen, or low in the middle, inside the
/// canvas.
class _NearPen extends SingleChildLayoutDelegate {
  const _NearPen(this.pen);

  static const double _edge = 8;
  static const double _gap = 24;

  final Offset? pen;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(
          0,
          math.min(NoteQuickPalette.maxWidth, constraints.maxWidth - _edge * 2),
        ),
        maxHeight: math.max(0, constraints.maxHeight - _edge * 2),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final anchor = pen ?? Offset(size.width / 2, size.height * 0.85);
    var top = anchor.dy - childSize.height - _gap;
    if (top < _edge) top = anchor.dy + _gap;
    double within(double value, double extent, double child) =>
        value.clamp(_edge, math.max(_edge, extent - child - _edge));

    return Offset(
      within(anchor.dx - childSize.width / 2, size.width, childSize.width),
      within(top, size.height, childSize.height),
    );
  }

  @override
  bool shouldRelayout(_NearPen oldDelegate) => oldDelegate.pen != pen;
}
