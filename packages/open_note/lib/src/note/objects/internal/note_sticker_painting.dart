import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Draws stickers for both the widget's placeholder and the canvas export.
abstract final class NoteStickerPainting {
  static const Color _placeholderFill = Color(0x14000000);
  static const Color _placeholderBorder = Color(0x33000000);

  /// A light box standing in for a picture that is not available.
  static void paintPlaceholder(Canvas canvas, Rect rect) {
    if (rect.isEmpty) return;
    canvas
      ..drawRect(rect, Paint()..color = _placeholderFill)
      ..drawRect(
        rect.deflate(0.5),
        Paint()
          ..color = _placeholderBorder
          ..style = PaintingStyle.stroke,
      );
  }

  /// [image] fitted inside [rect] keeping its aspect ratio, optionally
  /// mirrored left to right.
  static void paintImage(
    Canvas canvas,
    Rect rect,
    ui.Image image, {
    required bool flipHorizontal,
  }) {
    if (rect.isEmpty) return;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, size, rect.size);
    final source = Alignment.center.inscribe(fitted.source, Offset.zero & size);
    final target = Alignment.center.inscribe(fitted.destination, rect);
    canvas.save();
    if (flipHorizontal) {
      canvas
        ..translate(target.center.dx * 2, 0)
        ..scale(-1, 1);
    }
    canvas
      ..drawImageRect(
        image,
        source,
        target,
        Paint()..filterQuality = FilterQuality.medium,
      )
      ..restore();
  }
}
