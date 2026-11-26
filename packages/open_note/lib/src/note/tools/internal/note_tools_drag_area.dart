// Internal to the tools module; not exported from the barrel.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Reports the pointer position while the user presses or drags on [child], as
/// fractions (0–1) of its size.
///
/// It claims the gesture at pointer down, so a scrolling parent cannot steal a
/// drag that starts on it.
class NoteToolsDragArea extends StatelessWidget {
  /// Creates a drag area.
  const NoteToolsDragArea({
    required this.onPosition,
    required this.onEnd,
    required this.child,
    super.key,
  });

  /// Called at pointer down and on every move, with clamped fractions.
  final ValueChanged<Offset> onPosition;

  /// Called when the pointer is lifted or the gesture is cancelled.
  final VoidCallback onEnd;

  /// The surface; its size is the unit of the reported fractions.
  final Widget child;

  void _report(BuildContext context, Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    onPosition(
      Offset(
        (local.dx / size.width).clamp(0.0, 1.0),
        (local.dy / size.height).clamp(0.0, 1.0),
      ),
    );
  }

  void _configure(BuildContext context, PanGestureRecognizer recognizer) {
    recognizer
      ..onStart = ((details) => _report(context, details.localPosition))
      ..onUpdate = ((details) => _report(context, details.localPosition))
      ..onEnd = ((_) => onEnd())
      ..onCancel = onEnd;
  }

  @override
  Widget build(BuildContext context) => Builder(
    builder: (area) => RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      gestures: {
        _EagerPanRecognizer:
            GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
              _EagerPanRecognizer.new,
              (recognizer) => _configure(area, recognizer),
            ),
      },
      child: child,
    ),
  );
}

class _EagerPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
