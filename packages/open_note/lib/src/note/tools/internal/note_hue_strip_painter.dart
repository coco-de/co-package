// Internal to the tools module; not exported from the barrel.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/note_hsv.dart';

/// The full hue circle as a strip with a marker at [hue].
class NoteHueStripPainter extends CustomPainter {
  static const _markerWidth = 6.0;

  /// Marked hue, 0–360.
  final double hue;

  /// Corner radius of the strip.
  final double radius;

  /// Paints the strip with a marker at [hue] degrees.
  const NoteHueStripPainter(this.hue, {this.radius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = [
      for (var degrees = 0.0; degrees <= 360; degrees += 60)
        NoteHsv(h: degrees % 360, s: 1, v: 1).toColor(),
    ];
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
    const half = _markerWidth / 2;
    final x = math.max(
      half,
      math.min(hue / 360 * size.width, size.width - half),
    );
    final marker = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, size.height / 2),
        width: _markerWidth,
        height: size.height + 4,
      ),
      const Radius.circular(half),
    );
    canvas
      ..drawRRect(
        marker,
        Paint()
          ..color = const Color(0x99000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      )
      ..drawRRect(
        marker,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(NoteHueStripPainter oldDelegate) =>
      oldDelegate.hue != hue || oldDelegate.radius != radius;
}
