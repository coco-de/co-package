part of 'note_library_view.dart';

/// Reports two-finger pinches over [child] as incremental scale factors.
class _NoteDrawerPinch extends StatefulWidget {
  const _NoteDrawerPinch({
    required this.enabled,
    required this.onZoom,
    required this.child,
  });

  final bool enabled;
  final ValueChanged<double> onZoom;
  final Widget child;

  @override
  State<_NoteDrawerPinch> createState() => _NoteDrawerPinchState();
}

class _NoteDrawerPinchState extends State<_NoteDrawerPinch> {
  double _previousScale = 1;

  void _handleStart(ScaleStartDetails details) => _previousScale = 1;

  void _handleUpdate(ScaleUpdateDetails details) {
    // One finger scrolls; only two or more pinch.
    if (details.pointerCount < 2 || details.scale <= 0) return;
    final delta = details.scale / _previousScale;
    _previousScale = details.scale;
    widget.onZoom(delta);
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    gestures: {
      if (widget.enabled)
        _NotePinchRecognizer:
            GestureRecognizerFactoryWithHandlers<_NotePinchRecognizer>(
              () => _NotePinchRecognizer(debugOwner: this),
              (recognizer) => recognizer
                ..onStart = _handleStart
                ..onUpdate = _handleUpdate,
            ),
    },
    child: widget.child,
  );
}

/// A scale recognizer that claims the gesture as soon as a second finger is
/// down, so that the scroll view below cannot take a pinch for a scroll.
class _NotePinchRecognizer extends ScaleGestureRecognizer {
  _NotePinchRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    // [pointerCount] does not include the pointer being added yet.
    if (pointerCount >= 1) resolve(GestureDisposition.accepted);
  }
}
