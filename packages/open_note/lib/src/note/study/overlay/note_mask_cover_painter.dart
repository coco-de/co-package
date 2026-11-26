import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill.dart';
import 'package:open_note/src/note/study/overlay/note_mask_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';

/// Paints one cover (a mask or a tape). Internal to `study/overlay`: the mask
/// and tape views use it as their painter and the objects call [paintCover]
/// from `paintToCanvas`.
///
/// A hidden cover is filled (with its pattern or image) at `fillOpacity`; a
/// revealed one shows only the faint outline of its shape.
class NoteMaskCoverPainter extends CustomPainter {
  /// Paints [geometry] with [fill].
  const NoteMaskCoverPainter({
    required this.geometry,
    required this.fill,
    required this.fillOpacity,
    required this.revealed,
    this.image,
    this.style = const NoteMaskStyle(),
  });

  /// The shape to cover.
  final NoteMaskGeometry geometry;

  /// How a hidden cover looks.
  final NoteMaskFill fill;

  /// Opacity of the fill, 0 to 1.
  final double fillOpacity;

  /// Whether the cover is lifted.
  final bool revealed;

  /// The decoded picture of an image fill, when available.
  final ui.Image? image;

  /// Outline and pattern metrics.
  final NoteMaskStyle style;

  /// Paints the cover onto [canvas].
  static void paintCover(
    Canvas canvas, {
    required NoteMaskGeometry geometry,
    required NoteMaskFill fill,
    required double fillOpacity,
    required bool revealed,
    ui.Image? image,
    NoteMaskStyle style = const NoteMaskStyle(),
  }) {
    if (revealed) {
      geometry.outline(canvas, style.outlineColor, style.outlineWidth);

      return;
    }
    if (fillOpacity <= 0) return;
    final decorated = fill.kind != NoteMaskFillKind.solid;
    if (!decorated) {
      geometry.fill(
        canvas,
        fill.color.withValues(alpha: fill.color.a * fillOpacity),
      );

      return;
    }
    final area = geometry.coverage;
    // The layer lets the pattern be clipped to the shape (`srcATop`) and fades
    // the whole cover at once, so overlapping parts do not add up.
    canvas.saveLayer(
      area.inflate(1),
      Paint()..color = Color.fromRGBO(0, 0, 0, fillOpacity),
    );
    geometry.fill(canvas, fill.color);
    _paintDecoration(canvas, area, fill, image, style);
    canvas.restore();
  }

  static void _paintDecoration(
    Canvas canvas,
    Rect area,
    NoteMaskFill fill,
    ui.Image? image,
    NoteMaskStyle style,
  ) {
    switch (fill.kind) {
      case NoteMaskFillKind.solid:
        return;
      case NoteMaskFillKind.stripes:
        _paintStripes(canvas, area, fill.patternColor, style);
      case NoteMaskFillKind.dots:
        _paintDots(canvas, area, fill.patternColor, style);
      case NoteMaskFillKind.image:
        if (image != null) _paintPicture(canvas, area, image);
    }
  }

  static void _paintStripes(
    Canvas canvas,
    Rect area,
    Color color,
    NoteMaskStyle style,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = style.stripeWidth
      ..blendMode = BlendMode.srcATop;
    for (
      var x = area.left - area.height;
      x < area.right;
      x += style.stripeSpacing
    ) {
      canvas.drawLine(
        Offset(x, area.bottom),
        Offset(x + area.height, area.top),
        paint,
      );
    }
  }

  static void _paintDots(
    Canvas canvas,
    Rect area,
    Color color,
    NoteMaskStyle style,
  ) {
    final half = style.dotSpacing / 2;
    final centers = [
      for (var y = area.top + half; y < area.bottom; y += style.dotSpacing)
        for (var x = area.left + half; x < area.right; x += style.dotSpacing)
          Offset(x, y),
    ];
    canvas.drawPoints(
      ui.PointMode.points,
      centers,
      Paint()
        ..color = color
        ..strokeWidth = style.dotRadius * 2
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.srcATop,
    );
  }

  static void _paintPicture(Canvas canvas, Rect area, ui.Image image) {
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, size, area.size);
    canvas.drawImageRect(
      image,
      Alignment.center.inscribe(fitted.source, Offset.zero & size),
      area,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.srcATop,
    );
  }

  @override
  void paint(Canvas canvas, Size size) => paintCover(
    canvas,
    geometry: geometry,
    fill: fill,
    fillOpacity: fillOpacity,
    revealed: revealed,
    image: image,
    style: style,
  );

  /// Only the shape (plus the style's slop) takes pointers; the rest of the box
  /// lets them through to whatever is beneath.
  @override
  bool hitTest(Offset position) =>
      geometry.contains(position, slop: style.hitSlop);

  @override
  bool shouldRepaint(NoteMaskCoverPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.fill != fill ||
      oldDelegate.fillOpacity != fillOpacity ||
      oldDelegate.revealed != revealed ||
      oldDelegate.image != image ||
      oldDelegate.style != style;
}
