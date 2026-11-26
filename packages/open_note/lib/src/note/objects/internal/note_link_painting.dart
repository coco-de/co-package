import 'dart:ui';

import 'package:open_note/src/note/objects/note_link_object.dart';

/// Draws link hotspots for both the widget and the canvas export.
abstract final class NoteLinkPainting {
  static const double _width = 1.5;
  static const double _radius = 4;

  /// Draws the [appearance] of a hotspot covering [rect].
  static void paint(
    Canvas canvas,
    Rect rect,
    NoteLinkAppearance appearance,
    Color color,
  ) {
    if (appearance == NoteLinkAppearance.hidden || rect.isEmpty) return;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    if (appearance == NoteLinkAppearance.outline) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(_width / 2),
          const Radius.circular(_radius),
        ),
        stroke,
      );
    } else {
      final y = rect.bottom - _width / 2;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), stroke);
    }
  }
}
