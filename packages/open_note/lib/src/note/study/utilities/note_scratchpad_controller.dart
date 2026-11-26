import 'package:flutter/widgets.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/scribble_controller.dart';

/// The state of a scratchpad: a throwaway drawing surface on a coloured,
/// translucent sheet. It owns the engine's [ScribbleController] that holds the
/// ink.
///
/// Listeners are notified when the sheet changes and when ink is committed or
/// removed (not on every pointer move). The engine's global drawing state
/// applies to the pad like to every engine canvas: the current tool, colour,
/// width and pointer mode (pen only by default) decide what a stroke looks like
/// and which pointers draw. Setters and [clear] do nothing after [dispose].
class NoteScratchpadController extends ChangeNotifier {
  /// [opacity] is clamped to [minOpacity]–1.
  NoteScratchpadController({
    Color color = defaultSheetColor,
    double opacity = defaultOpacity,
  }) : _color = color,
       _opacity = _clampOpacity(opacity, fallback: defaultOpacity),
       scribbleController = ScribbleController() {
    // The engine initialises lazily and re-enters itself if a listener reads it
    // while it does, so initialise before subscribing.
    _remember(scribbleController.currentScribble);
    scribbleController.addListener(_onInkChanged);
  }

  /// Pale sticky-note yellow.
  static const Color defaultSheetColor = Color(0xFFFFF59D);

  /// The sheet opacity of a new pad.
  static const double defaultOpacity = 0.9;

  /// The sheet stays at least this opaque, so it can be found.
  static const double minOpacity = 0.1;

  /// Holds the pad's ink; hosts may read it to save or export the drawing.
  /// Disposed with this controller.
  final ScribbleController scribbleController;

  Color _color;
  double _opacity;
  Scribble? _scribble;
  int _itemCount = 0;
  bool _disposed = false;

  /// The sheet's colour, drawn at [opacity].
  Color get color => _color;

  set color(Color value) {
    if (_disposed || value == _color) return;
    _color = value;
    notifyListeners();
  }

  /// How opaque the sheet is, [minOpacity]–1. Ink is always opaque.
  double get opacity => _opacity;

  set opacity(double value) {
    final next = _clampOpacity(value, fallback: _opacity);
    if (_disposed || next == _opacity) return;
    _opacity = next;
    notifyListeners();
  }

  /// Whether nothing has been drawn.
  bool get isEmpty => _itemCount == 0;

  /// Erases all ink (it can be undone through [scribbleController]).
  void clear() {
    if (_disposed) return;
    scribbleController.clear();
  }

  static double _clampOpacity(double value, {required double fallback}) =>
      value.isNaN ? fallback : value.clamp(minOpacity, 1).toDouble();

  static int _countItems(Scribble scribble) =>
      scribble.strokes.length +
      scribble.textDrawables.length +
      scribble.imageDrawables.length;

  bool _remember(Scribble scribble) {
    final count = _countItems(scribble);
    final changed = !identical(scribble, _scribble) || count != _itemCount;
    _scribble = scribble;
    _itemCount = count;

    return changed;
  }

  void _onInkChanged() {
    if (_remember(scribbleController.currentScribble)) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    scribbleController
      ..removeListener(_onInkChanged)
      ..dispose();
    super.dispose();
  }
}
