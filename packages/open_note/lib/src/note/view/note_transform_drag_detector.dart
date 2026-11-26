import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Called for every change of a [NoteTransformDragDetector] gesture: how far
/// the focal point moved since the gesture began (in the coordinates given by
/// `toLocal`), the pinch factor and the rotation (radians) since then, and the
/// number of fingers.
typedef NoteTransformUpdate =
    void Function(Offset delta, double scale, double rotation, int fingers);

/// One-finger drag and two-finger pinch/rotate on a floating tool (ruler,
/// magnifier), measured in the coordinate space of an ancestor so the numbers
/// stay right when the tool or the page is rotated or scaled.
///
/// A new gesture starts ([onStart]) whenever the number of fingers changes;
/// the values of [onUpdate] are relative to it. Movement before the gesture was
/// recognised is included.
class NoteTransformDragDetector extends StatefulWidget {
  /// Detects drags, pinches and rotations on [child].
  const NoteTransformDragDetector({
    required this.toLocal,
    required this.onStart,
    required this.onUpdate,
    required this.child,
    super.key,
  });

  /// Converts a global position into the tool's coordinate space.
  final Offset Function(Offset global) toLocal;

  /// Remember the starting values here.
  final VoidCallback onStart;

  /// The gesture moved, scaled or rotated.
  final NoteTransformUpdate onUpdate;

  /// The tool being manipulated.
  final Widget child;

  @override
  State<NoteTransformDragDetector> createState() =>
      _NoteTransformDragDetectorState();
}

class _NoteTransformDragDetectorState extends State<NoteTransformDragDetector> {
  final Map<int, Offset> _fingers = {};

  /// Where the focal point was when the number of fingers last changed. The
  /// recognizer reports the position after its slop (or after the first move of
  /// a second finger), which would lose that movement.
  Offset? _anchor;
  Offset _focalStart = Offset.zero;

  void _onPointerDown(PointerDownEvent event) {
    _fingers[event.pointer] = event.position;
    _anchor = _centroid();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_fingers.containsKey(event.pointer)) {
      _fingers[event.pointer] = event.position;
    }
  }

  void _onPointerEnd(PointerEvent event) {
    if (_fingers.remove(event.pointer) != null) _anchor = _centroid();
  }

  Offset? _centroid() {
    if (_fingers.isEmpty) return null;

    return _fingers.values.reduce((a, b) => a + b) / _fingers.length.toDouble();
  }

  void _onScaleStart(ScaleStartDetails details) {
    final anchor = _anchor;
    final origin = anchor != null && _fingers.length == details.pointerCount
        ? anchor
        : details.focalPoint;
    _focalStart = widget.toLocal(origin);
    widget.onStart();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    widget.onUpdate(
      widget.toLocal(details.focalPoint) - _focalStart,
      details.scale,
      details.rotation,
      details.pointerCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: widget.child,
      ),
    );
  }
}
