import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_line_path.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_text_box_border_style.dart';
import 'package:open_note/src/note/style/note_text_box_style.dart';

/// Draws the box of a text drawable from a [NoteTextBoxStyle].
abstract final class NoteTextBoxDecoration {
  /// The box drawn around the text occupying [textBounds]: padding inflates it.
  static Rect outerRect(Rect textBounds, NoteTextBoxStyle style) =>
      style.padding.inflateRect(textBounds);

  /// Paints background and border around [textBounds] (the text itself is the
  /// caller's). The border lies inside [outerRect]; a dashed one uses the
  /// default dash pattern of `NoteLineStyle` scaled by the border width. A
  /// translucent style is composited as one layer.
  static void paint(Canvas canvas, Rect textBounds, NoteTextBoxStyle style) {
    final box = outerRect(textBounds, style);
    if (!style.isVisible || style.opacity <= 0) return;
    if (!box.isFinite || box.isEmpty) return;
    final layered = style.opacity < 1;
    if (layered) {
      canvas.saveLayer(
        box,
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: style.opacity),
      );
    }
    if (style.backgroundColor case final color?) {
      canvas.drawRRect(
        _rounded(box, style.cornerRadius),
        Paint()..color = color,
      );
    }
    _paintBorder(canvas, box, style);
    if (layered) canvas.restore();
  }

  static RRect _rounded(Rect rect, double radius) => RRect.fromRectAndRadius(
    rect,
    Radius.circular(math.max(0, math.min(radius, rect.shortestSide / 2))),
  );

  static void _paintBorder(Canvas canvas, Rect box, NoteTextBoxStyle style) {
    final color = style.borderColor;
    if (color == null || !style.hasBorder) return;
    final width = math.min(style.borderWidth, box.shortestSide / 2);
    final line = _rounded(
      box.deflate(width / 2),
      style.cornerRadius - width / 2,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (style.borderLineStyle == NoteTextBoxBorderStyle.solid) {
      canvas.drawRRect(line, paint);

      return;
    }
    canvas.drawPath(
      NoteLinePath.dashPath(
        Path()..addRRect(line),
        NoteLineStyle.dashedDashLength * width,
        NoteLineStyle.defaultGap * width,
      ),
      paint,
    );
  }
}
