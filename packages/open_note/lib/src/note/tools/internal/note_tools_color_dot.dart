// Internal to the tools module; not exported from the barrel.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A round colour sample: a checkerboard behind translucent colours, a thin
/// outline (so white is visible) and a ring when selected.
class NoteToolsColorDot extends StatelessWidget {
  /// Creates a dot.
  const NoteToolsColorDot({
    required this.color,
    required this.size,
    required this.borderColor,
    required this.ringColor,
    super.key,
    this.selected = false,
  });

  /// The sampled colour.
  final Color color;

  /// Diameter in logical pixels.
  final double size;

  /// Outline colour.
  final Color borderColor;

  /// Colour of the selection ring.
  final Color ringColor;

  /// Whether the ring is drawn.
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _ColorDotPainter(
        color: color,
        borderColor: borderColor,
        ringColor: ringColor,
        selected: selected,
      ),
    ),
  );
}

class _ColorDotPainter extends CustomPainter {
  final Color color;

  final Color borderColor;
  final Color ringColor;
  final bool selected;
  const _ColorDotPainter({
    required this.color,
    required this.borderColor,
    required this.ringColor,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.max(0.0, size.shortestSide / 2 - 3);
    final circle = Rect.fromCircle(center: center, radius: radius);
    if (color.a < 1) _paintCheckerboard(canvas, circle);
    canvas
      ..drawCircle(center, radius, Paint()..color = color)
      ..drawCircle(center, radius, _stroke(borderColor, 1));
    if (selected) {
      canvas.drawCircle(center, radius + 2, _stroke(ringColor, 2));
    }
  }

  @override
  bool shouldRepaint(_ColorDotPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.selected != selected;

  void _paintCheckerboard(Canvas canvas, Rect circle) {
    canvas
      ..save()
      ..clipPath(Path()..addOval(circle))
      ..drawRect(circle, Paint()..color = const Color(0xFFFFFFFF));
    const cell = 5.0;
    final dark = Paint()..color = const Color(0xFFCCCCCC);
    for (var row = 0; row * cell < circle.height; row++) {
      for (var column = 0; column * cell < circle.width; column++) {
        if ((row + column).isOdd) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            circle.left + column * cell,
            circle.top + row * cell,
            cell,
            cell,
          ),
          dark,
        );
      }
    }
    canvas.restore();
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;
}
