import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/library/note_cover_design.dart';

/// Paints a [NoteCoverDesign] so that it fills the given size: a rounded card
/// with the design's pattern and a shaded spine along the left edge.
///
/// Everything is proportional to the size, so the same design looks alike on a
/// 40 px list thumbnail and on a full page. Painting is deterministic.
class NoteCoverPainter extends CustomPainter {
  /// Creates a painter for [design]; [cornerRadius] is capped at a quarter of
  /// the shorter side.
  const NoteCoverPainter(this.design, {this.cornerRadius = 6});

  /// The colours and pattern to paint.
  final NoteCoverDesign design;

  /// The corner radius in logical pixels.
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final radius = math.min(cornerRadius, size.shortestSide / 4);
    final card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas
      ..save()
      ..clipRRect(card)
      ..drawRect(Offset.zero & size, Paint()..color = design.background);
    _paintPattern(canvas, size);
    _paintSpine(canvas, size);
    canvas
      ..restore()
      ..drawRRect(
        card.deflate(0.25),
        Paint()
          ..color = const Color(0x33000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
  }

  @override
  bool shouldRepaint(NoteCoverPainter oldDelegate) =>
      oldDelegate.design != design || oldDelegate.cornerRadius != cornerRadius;

  void _paintPattern(Canvas canvas, Size size) {
    final fill = Paint()..color = design.accent;
    final width = size.width;
    final height = size.height;
    switch (design.pattern) {
      case NoteCoverPattern.plain:
        break;
      case NoteCoverPattern.band:
        canvas.drawRect(
          Rect.fromLTWH(0, height * 0.62, width, height * 0.14),
          fill,
        );
      case NoteCoverPattern.stripes:
        _paintStripes(canvas, size, fill);
      case NoteCoverPattern.dots:
        _paintDots(canvas, size, fill);
      case NoteCoverPattern.grid:
        _paintGrid(canvas, size);
      case NoteCoverPattern.diagonal:
        _paintDiagonals(canvas, size);
      case NoteCoverPattern.label:
        _paintLabel(canvas, size, fill);
      case NoteCoverPattern.split:
        canvas.drawRect(Rect.fromLTRB(0, height * 0.65, width, height), fill);
    }
  }

  /// The distance between repeated marks, never under two pixels so that a
  /// very narrow cover cannot make the loops run away.
  double _step(Size size, double fraction) =>
      math.max(size.width * fraction, 2);

  void _paintStripes(Canvas canvas, Size size, Paint fill) {
    final step = _step(size, 0.16);
    for (var x = size.width * 0.22; x < size.width; x += step) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, size.width * 0.05, size.height),
        fill,
      );
    }
  }

  void _paintDots(Canvas canvas, Size size, Paint fill) {
    final step = _step(size, 0.14);
    for (var y = step; y < size.height; y += step) {
      for (var x = step * 1.5; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), size.width * 0.022, fill);
      }
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final step = _step(size, 0.125);
    final line = Paint()
      ..color = design.accent
      ..strokeWidth = size.width * 0.008;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  void _paintDiagonals(Canvas canvas, Size size) {
    final line = Paint()
      ..color = design.accent
      ..strokeWidth = size.width * 0.04;
    final step = _step(size, 0.2);
    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }
  }

  void _paintLabel(Canvas canvas, Size size, Paint fill) {
    final plate = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.16,
      size.width * 0.66,
      size.height * 0.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, Radius.circular(size.width * 0.03)),
      fill,
    );
    final rule = Paint()
      ..color = design.background.withValues(alpha: 0.5)
      ..strokeWidth = plate.height * 0.07
      ..strokeCap = StrokeCap.round;
    for (final fraction in const [0.4, 0.68]) {
      final y = plate.top + plate.height * fraction;
      canvas.drawLine(
        Offset(plate.left + plate.width * 0.14, y),
        Offset(plate.right - plate.width * 0.14, y),
        rule,
      );
    }
  }

  void _paintSpine(Canvas canvas, Size size) {
    final spine = size.width * 0.085;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, spine, size.height),
        Paint()..color = const Color(0x2E000000),
      )
      ..drawRect(
        Rect.fromLTWH(spine, 0, math.max(size.width * 0.012, 0.5), size.height),
        Paint()..color = const Color(0x40FFFFFF),
      );
  }
}
