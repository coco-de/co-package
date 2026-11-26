import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:open_note/src/note/style/note_image_crop.dart';
import 'package:open_note/src/note/style/note_image_style.dart';

/// Draws a decoded image with a [NoteImageStyle].
///
/// The destination rectangle is where the **cropped** part appears: the host
/// sizes it to the crop (see `NoteImageCrop.sourceRect`) to keep the aspect
/// ratio.
abstract final class NoteImageStylePainter {
  /// Paints [image] into [dest]: the cropped pixels, clipped to
  /// [clipPathFor], then the border inside that outline. A translucent style is
  /// composited as one layer. Nothing is drawn for an empty or non-finite
  /// [dest], or zero opacity.
  static void paint(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect dest,
    NoteImageStyle style,
  ) {
    if (!dest.isFinite || dest.isEmpty || style.opacity <= 0) return;
    final outline = clipPathFor(dest, style);
    final layered = style.opacity < 1;
    if (layered) {
      canvas.saveLayer(
        dest,
        ui.Paint()
          ..color = const ui.Color(0xFF000000).withValues(alpha: style.opacity),
      );
    }
    canvas
      ..save()
      ..clipPath(outline)
      ..drawImageRect(
        image,
        style.crop.sourceRect(
          ui.Size(image.width.toDouble(), image.height.toDouble()),
        ),
        dest,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    _paintBorder(canvas, outline, style);
    canvas.restore();
    if (layered) canvas.restore();
  }

  /// The visible outline of the image drawn into [dest]: the rounded rectangle,
  /// intersected with the crop polygon if there is one.
  static ui.Path clipPathFor(ui.Rect dest, NoteImageStyle style) {
    final radius = math.max(
      0.0,
      math.min(style.cornerRadius, dest.shortestSide / 2),
    );
    final frame = ui.Path()
      ..addRRect(ui.RRect.fromRectAndRadius(dest, ui.Radius.circular(radius)));
    final crop = style.crop;
    if (crop is! NoteImagePolygonCrop) return frame;
    final polygon = crop.outlineIn(dest);
    if (radius <= 0) return polygon;

    return ui.Path.combine(ui.PathOperation.intersect, frame, polygon);
  }

  /// A stroke twice the border width, of which the clip keeps the inner half.
  static void _paintBorder(
    ui.Canvas canvas,
    ui.Path outline,
    NoteImageStyle style,
  ) {
    final color = style.borderColor;
    if (color == null || !style.hasBorder) return;
    canvas.drawPath(
      outline,
      ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = style.borderWidth * 2,
    );
  }
}
