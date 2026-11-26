import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/lasso/scribble_lasso_selection.dart';
import 'package:open_note/src/module/text/inline_text_editor.dart'
    show LinkTargetResolver;
import 'package:open_note/src/module/text/text_box_typography.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/widgets/scribble_widget.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/layer/note_layer_content.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';
import 'package:open_note/src/note/layer/note_scribble_view.dart';

/// Edits the active layer of a [NoteLayerStack] while showing the other layers
/// in place.
///
/// One [ScribbleWidget] draws the active layer. Layers below and above it are
/// painted read-only in the same page coordinates ([NoteScribbleView]), and
/// [foreground] (note objects) sits on top of everything. Switching layers
/// keeps the zoom and pan.
class NoteLayeredPageView extends StatefulWidget {
  const NoteLayeredPageView({
    required this.layers,
    required this.modeNotifier,
    required this.pageSize,
    super.key,
    this.background,
    this.foreground,
    this.transformationController,
    this.drawingEnabled = true,
    this.maxScale = 5,
    this.panDirection = PanDirection.both,
    this.textBoxTypography = defaultTextBoxTypography,
    this.imageProviderResolver,
    this.linkTargetResolver,
    this.onStrokeFinished,
    this.lassoSelection,
    this.onImageSelectionChanged,
    this.zoomEnabled = true,
  });

  final NoteLayerStack layers;

  /// Tool, colour, width and input options shared by every layer.
  final ScribbleModeNotifier modeNotifier;

  final NotePageSize pageSize;

  /// The paper (or document page) drawn under all ink. White when null.
  final Widget? background;

  /// Interactive content above all ink, laid out in page coordinates.
  final Widget? foreground;

  /// Zoom and pan. An internal controller is used when null.
  final TransformationController? transformationController;

  /// Set false to turn drawing off (read mode, object editing).
  final bool drawingEnabled;

  /// Maximum zoom, relative to the fitted page (see `ScribbleWidget.maxScale`).
  final double maxScale;
  final PanDirection panDirection;
  final TextBoxTypography textBoxTypography;
  final ImageProvider Function(String source)? imageProviderResolver;
  final LinkTargetResolver? linkTargetResolver;

  /// Called after a pen or eraser gesture finishes.
  final VoidCallback? onStrokeFinished;

  /// Receives the lasso selection of the active layer.
  final ScribbleLassoSelection? lassoSelection;

  /// The id of the image selected on the active layer, or null.
  final ValueChanged<String?>? onImageSelectionChanged;

  /// False keeps the current zoom.
  final bool zoomEnabled;

  @override
  State<NoteLayeredPageView> createState() => _NoteLayeredPageViewState();
}

class _NoteLayeredPageViewState extends State<NoteLayeredPageView> {
  TransformationController? _ownController;

  TransformationController get _transform =>
      widget.transformationController ??
      (_ownController ??= TransformationController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.layers,
    builder: (context, _) {
      final stack = widget.layers;
      final active = stack.activeLayer;
      final contents = stack.contents;
      final activeIndex = stack.indexOf(active.id);
      final size = widget.pageSize.toSize();
      final onFinished = widget.onStrokeFinished;

      return ScribbleWidget(
        // A new widget per layer: the engine binds its gesture managers to one
        // notifier.
        key: ValueKey('note-layer-${active.id}'),
        notifier: stack.activeNotifier,
        modeNotifier: widget.modeNotifier,
        transformationController: _transform,
        preserveViewTransform: true,
        contentLogicalSize: size,
        isScribbleEnable: widget.drawingEnabled && stack.canDrawOnActive,
        maxScale: widget.maxScale,
        panDirection: widget.panDirection,
        textBoxTypography: widget.textBoxTypography,
        linkTargetResolver: widget.linkTargetResolver,
        lassoSelection: widget.lassoSelection,
        onImageSelectionChanged: widget.onImageSelectionChanged,
        zoomEnabled: widget.zoomEnabled,
        inkOpacity: active.visible ? active.opacity : 0,
        onScribbleFinished: onFinished == null ? null : (_) => onFinished(),
        layersBelow: _readOnly(contents.sublist(0, activeIndex), size),
        layersAbove: _readOnly(contents.sublist(activeIndex + 1), size),
        foreground: widget.foreground,
        child: SizedBox.fromSize(
          size: size,
          child:
              widget.background ?? const ColoredBox(color: Color(0xFFFFFFFF)),
        ),
      );
    },
  );

  Widget? _readOnly(List<NoteLayerContent> contents, Size size) {
    final shown = [
      for (final content in contents)
        if (content.layer.visible && !content.isEmpty) content,
    ];
    if (shown.isEmpty) return null;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final content in shown)
          Opacity(
            key: ValueKey('note-readonly-${content.layer.id}'),
            opacity: content.layer.opacity,
            child: NoteScribbleView(
              scribble: content.scribble,
              size: size,
              textBoxTypography: widget.textBoxTypography,
              imageProviderResolver: widget.imageProviderResolver,
            ),
          ),
      ],
    );
  }
}
