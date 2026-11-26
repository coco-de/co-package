// Internal to the tools module; not exported from the barrel.

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/note_hsv.dart';

/// The saturation (x) and brightness (y, top is bright) plane of one hue, with
/// the current position ringed.
class NoteSaturationValuePainter extends CustomPainter {
  /// The current colour; its hue tints the plane.
  final NoteHsv color;

  /// Corner radius of the plane.
  final double radius;

  /// Paints the plane for [color].
  const NoteSaturationValuePainter(this.color, {this.radius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hue = NoteHsv(h: color.h, s: 1, v: 1).toColor();
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFFFFFFFF), hue],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      )
      ..restore();
    final center = Offset(color.s * size.width, (1 - color.v) * size.height);
    canvas
      ..drawCircle(
        center,
        8,
        Paint()
          ..color = const Color(0x99000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      )
      ..drawCircle(
        center,
        8,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(NoteSaturationValuePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
