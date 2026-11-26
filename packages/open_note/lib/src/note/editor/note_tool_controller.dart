import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/state/drawing_state.dart';
import 'package:open_note/src/module/state/scribble_input_options.dart';
import 'package:open_note/src/note/tools/tools.dart';

/// The note editor's tool state and its link to the engine.
///
/// The engine keeps the tool, colour, width, shape target and finger/pen mode
/// in the global [DrawingState] and re-applies them at the start of every
/// stroke. This controller therefore writes every choice there (and to the
/// bound [ScribbleModeNotifier]); what [DrawingState] does not know — stroke
/// stabilization and pressure, line and shape style, eraser mode, shape
/// snapping and the rectangle lasso — goes into the mode notifier's
/// [ScribbleInputOptions].
///
/// Colour, width and line style are remembered per ink. The controller also
/// implements [NoteToolActions], so a [NotePencilGestureDispatcher] (Apple
/// Pencil double tap / squeeze) can drive it.
class NoteToolController extends ChangeNotifier implements NoteToolActions {
  /// Starts with the active preset of [presets] if there is one, else [ink].
  NoteToolController({
    NoteToolPresetStore? presets,
    String ink = NoteInkTypes.pen,
    NotePenSettings penSettings = const NotePenSettings(),
    NoteEraserSettings eraser = const NoteEraserSettings(),
    NoteLassoSettings lasso = const NoteLassoSettings(),
    NotePencilGestureMap gestures = const NotePencilGestureMap(),
    bool fingerDrawing = false,
    bool holdToSnapShapes = false,
    this.onUndo,
    this.onRedo,
    this.onShowToolPalette,
  }) : presets = presets ?? NoteToolPresetStore.defaults(),
       _ownsPresets = presets == null,
       _ink = ink,
       _penSettings = penSettings,
       _eraser = eraser,
       _lasso = lasso,
       _fingerDrawing = fingerDrawing,
       _holdToSnapShapes = holdToSnapShapes {
    dispatcher = NotePencilGestureDispatcher(gestures, this);
    final active = this.presets.active;
    if (active != null) _loadPreset(active);
  }

  /// Pen favourites.
  final NoteToolPresetStore presets;

  /// Runs stylus gestures.
  late final NotePencilGestureDispatcher dispatcher;

  /// What Pencil double tap and squeeze do.
  NotePencilGestureMap get gestures => dispatcher.map;

  set gestures(NotePencilGestureMap value) {
    if (value == dispatcher.map) return;
    dispatcher.map = value;
    notifyListeners();
  }

  /// What [undo], [redo] and [showToolPalette] do. The editor sets undo and
  /// redo, and shows its quick palette unless a palette callback is given.
  VoidCallback? onUndo;
  VoidCallback? onRedo;
  VoidCallback? onShowToolPalette;

  final bool _ownsPresets;
  String _ink;
  String? _previousInk;
  final Map<String, Color> _colors = {
    NoteInkTypes.pen: const Color(0xFF000000),
    NoteInkTypes.pencil: const Color(0xFF424242),
    NoteInkTypes.marker: const Color(0x80FFEB3B),
    NoteInkTypes.fixedPen: const Color(0xFF000000),
    NoteInkTypes.uniformPen: const Color(0xFF000000),
    NoteInkTypes.shape: const Color(0xFF000000),
    NoteInkTypes.text: const Color(0xFF000000),
  };
  final Map<String, double> _widths = {
    NoteInkTypes.pen: 1,
    NoteInkTypes.pencil: 1,
    NoteInkTypes.marker: 4,
    NoteInkTypes.fixedPen: 1,
    NoteInkTypes.uniformPen: 1,
    NoteInkTypes.shape: 1.5,
    NoteInkTypes.text: 14,
  };
  final Map<String, String> _lineStyles = {};
  String _shapeTarget = '';
  String _shapeStyle = '';
  NotePenSettings _penSettings;
  NoteEraserSettings _eraser;
  NoteLassoSettings _lasso;
  bool _fingerDrawing;
  bool _holdToSnapShapes;
  final Set<ScribbleModeNotifier> _modeNotifiers = {};

  @override
  String get currentTool => _ink;

  /// The tool [previousTool] returns to.
  String? get previousInk => _previousInk;

  /// Colour of the current tool.
  Color get color => colorOf(_ink);

  /// Width of the current tool; the eraser's is its size.
  double get width => widthOf(_ink);

  /// Line style of the current tool (`solid` or a `NoteLineStyle` string).
  String get lineStyle => lineStyleOf(_ink);

  /// What the shape tool draws: '' (recognise a free-hand shape), `line`,
  /// `ellipse` or `rectangle`.
  String get shapeTarget => _shapeTarget;

  /// Fill, corner and opacity style of new shapes (`NoteShapeStyle` string).
  String get shapeStyle => _shapeStyle;

  NotePenSettings get penSettings => _penSettings;

  NoteEraserSettings get eraserSettings => _eraser;

  NoteLassoSettings get lassoSettings => _lasso;

  /// Whether fingers and the mouse draw (otherwise only a stylus does).
  bool get fingerDrawing => _fingerDrawing;

  /// Whether holding the pen still turns a drawn figure into a shape.
  bool get holdToSnapShapes => _holdToSnapShapes;

  /// Whether the current tool leaves ink (not eraser, lasso, text or image).
  bool get isInkingTool => !const {
    NoteInkTypes.erase,
    NoteInkTypes.lasso,
    NoteInkTypes.text,
    NoteInkTypes.image,
  }.contains(_ink);

  Color colorOf(String ink) => _colors[ink] ?? const Color(0xFF000000);

  double widthOf(String ink) =>
      ink == NoteInkTypes.erase ? _eraser.size : _widths[ink] ?? 1;

  String lineStyleOf(String ink) => _lineStyles[ink] ?? 'solid';

  /// The stroke input options the current settings translate to.
  ScribbleInputOptions get inputOptions {
    final pen = _penSettings.toEngineParams();
    final style = lineStyleOf(_ink);

    return ScribbleInputOptions(
      pen: ScribblePenParams(
        streamline: pen.streamline,
        smoothing: pen.smoothing,
        thinningScale: pen.thinningScale,
        pressureGamma: pen.pressureGamma,
      ),
      lineStyle: style == 'solid' ? '' : style,
      shapeStyle: _shapeStyle,
      eraserMode: _eraser.mode == NoteEraserMode.pixel
          ? ScribbleEraserMode.pixel
          : ScribbleEraserMode.stroke,
      pressureEraser: _eraser.pressureSwitchEnabled,
      pressureEraserThreshold: _eraser.pressureThreshold,
      holdToSnapShapes: _holdToSnapShapes,
      rectangleLasso: _lasso.shape == NoteLassoShape.rectangle,
    );
  }

  /// Applies the tool state to [modeNotifier] now and on every change.
  /// Editors shown side by side share one controller, each binding its own.
  void bind(ScribbleModeNotifier modeNotifier) {
    _modeNotifiers.add(modeNotifier);
    apply();
  }

  /// Stops applying to [modeNotifier] (to every one when null).
  void unbind([ScribbleModeNotifier? modeNotifier]) {
    if (modeNotifier == null) {
      _modeNotifiers.clear();
    } else {
      _modeNotifiers.remove(modeNotifier);
    }
  }

  /// Writes the current state to [DrawingState] and the bound mode notifiers.
  /// Call it again if something else changed the global tool state.
  void apply() {
    final drawing = DrawingState();
    drawing.pointerMode.value = _fingerDrawing
        ? DrawingPointerMode.mouseOnly
        : DrawingPointerMode.penOnly;
    // The pressure eraser uses the eraser's own width: keep it up to date by
    // visiting the eraser. Return to the tool's ink right away, or the
    // engine's global synchroniser takes it for leaving the eraser and
    // switches whichever drawing surface was used last.
    for (final mode in _modeNotifiers) {
      mode
        ..setEraser()
        ..setStrokeWidth(_engineWidth(NoteInkTypes.erase))
        ..setSelectedInk(_ink);
    }
    drawing.selectedShapeType.value = _shapeTarget;
    drawing.selectedColor.value = color;
    drawing.selectedThickness.value = _engineWidth(_ink);
    drawing.selectedTool.value = _drawingToolOf(_ink);
    for (final mode in _modeNotifiers) {
      mode.setInputOptions(inputOptions);
      drawing.applyToModeNotifier(mode);
    }
  }

  @override
  void selectTool(String ink) {
    if (ink == _ink) return;
    _previousInk = _ink;
    _ink = ink;
    _changed();
  }

  @override
  void previousTool() {
    final previous = _previousInk;
    if (previous != null) selectTool(previous);
  }

  @override
  void toggleEraser() {
    if (_ink != NoteInkTypes.erase) {
      selectTool(NoteInkTypes.erase);

      return;
    }
    final previous = _previousInk;
    selectTool(
      previous == null || previous == NoteInkTypes.erase
          ? NoteInkTypes.pen
          : previous,
    );
  }

  @override
  void undo() => onUndo?.call();

  @override
  void redo() => onRedo?.call();

  @override
  void showToolPalette() => onShowToolPalette?.call();

  @override
  void cyclePreset() {
    final next = presets.selectNext();
    if (next == null) return;
    _applyPresetState(next);
  }

  /// Selects a favourite and switches to its tool, colour, width and style.
  void applyPreset(NoteToolPreset preset) {
    presets.select(preset.id);
    _applyPresetState(preset);
  }

  /// Saves the current tool as a new favourite; null when the store is full or
  /// the tool cannot be saved.
  NoteToolPreset? saveAsPreset({String name = ''}) {
    if (!NoteInkTypes.isPresetInk(_ink)) return null;

    return presets.addFrom(
      name: name,
      ink: _ink,
      color: color,
      width: width,
      lineStyle: lineStyle,
      shapeTarget: _shapeTarget,
    );
  }

  /// Sets the colour of the current tool (ignored by eraser, lasso and image).
  void setColor(Color color) {
    if (!_colors.containsKey(_ink) || _colors[_ink] == color) return;
    _colors[_ink] = color;
    _changed();
  }

  /// Sets the width of the current tool; for the eraser this sets its size.
  void setWidth(double width) {
    if (width <= 0 || width == this.width) return;
    if (_ink == NoteInkTypes.erase) {
      _eraser = _eraser.copyWith(size: width);
    } else if (_widths.containsKey(_ink)) {
      _widths[_ink] = width;
    } else {
      return;
    }
    _changed();
  }

  /// Sets the line style of the current tool (`solid` or a `NoteLineStyle`).
  void setLineStyle(String lineStyle) {
    if (lineStyle == this.lineStyle) return;
    _lineStyles[_ink] = lineStyle;
    _changed();
  }

  void setShapeTarget(String shapeTarget) {
    if (shapeTarget == _shapeTarget) return;
    _shapeTarget = shapeTarget;
    _changed();
  }

  void setShapeStyle(String shapeStyle) {
    if (shapeStyle == _shapeStyle) return;
    _shapeStyle = shapeStyle;
    _changed();
  }

  set penSettings(NotePenSettings settings) {
    if (settings == _penSettings) return;
    _penSettings = settings;
    _changed();
  }

  set eraserSettings(NoteEraserSettings settings) {
    if (settings == _eraser) return;
    _eraser = settings;
    _changed();
  }

  set lassoSettings(NoteLassoSettings settings) {
    if (settings == _lasso) return;
    _lasso = settings;
    _changed();
  }

  set fingerDrawing(bool value) {
    if (value == _fingerDrawing) return;
    _fingerDrawing = value;
    _changed();
  }

  set holdToSnapShapes(bool value) {
    if (value == _holdToSnapShapes) return;
    _holdToSnapShapes = value;
    _changed();
  }

  @override
  void dispose() {
    _modeNotifiers.clear();
    if (_ownsPresets) presets.dispose();
    super.dispose();
  }

  void _applyPresetState(NoteToolPreset preset) {
    final previous = _ink;
    _loadPreset(preset);
    if (previous != _ink) _previousInk = previous;
    _changed();
  }

  void _loadPreset(NoteToolPreset preset) {
    _ink = preset.ink;
    _colors[preset.ink] = preset.color;
    _widths[preset.ink] = preset.width;
    _lineStyles[preset.ink] = preset.lineStyle;
    if (preset.ink == NoteInkTypes.shape) _shapeTarget = preset.shapeTarget;
  }

  void _changed() {
    apply();
    notifyListeners();
  }

  /// The engine stores one width per tool; its eraser radius is half the
  /// eraser size the settings describe.
  double _engineWidth(String ink) =>
      ink == NoteInkTypes.erase ? _eraser.size / 2 : widthOf(ink);

  static DrawingTool _drawingToolOf(String ink) => switch (ink) {
    NoteInkTypes.pencil => DrawingTool.pencil,
    NoteInkTypes.marker => DrawingTool.marker,
    NoteInkTypes.fixedPen => DrawingTool.fixedPen,
    NoteInkTypes.uniformPen => DrawingTool.uniformPen,
    NoteInkTypes.erase => DrawingTool.erase,
    NoteInkTypes.text => DrawingTool.text,
    NoteInkTypes.shape => DrawingTool.shape,
    NoteInkTypes.lasso => DrawingTool.lasso,
    NoteInkTypes.image => DrawingTool.image,
    _ => DrawingTool.pen,
  };
}
