import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A rotating arc that shows work in progress without a design system.
/// Internal to `study/overlay`.
class NoteOverlaySpinner extends StatefulWidget {
  /// Creates a spinner.
  const NoteOverlaySpinner({required this.color, this.size = 20, super.key});

  /// Colour of the arc.
  final Color color;

  /// Diameter.
  final double size;

  @override
  State<NoteOverlaySpinner> createState() => _NoteOverlaySpinnerState();
}

class _NoteOverlaySpinnerState extends State<NoteOverlaySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _turns,
    child: CustomPaint(
      size: Size.square(widget.size),
      painter: _ArcPainter(widget.color),
    ),
  );
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawArc(
    (Offset.zero & size).deflate(1.5),
    0,
    math.pi * 1.5,
    false,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}
