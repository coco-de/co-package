import 'package:flutter/widgets.dart';

/// The glyphs the study-utility widgets draw themselves, so they do not depend
/// on an icon font.
enum NoteUtilityGlyph {
  /// A triangle.
  play,

  /// Two bars.
  pause,

  /// A cross.
  delete,
}

/// Paints a [NoteUtilityGlyph] in a square. Not part of the public API.
class NoteUtilityIcon extends StatelessWidget {
  /// A [glyph] in [color], [size] logical pixels square.
  const NoteUtilityIcon({
    required this.glyph,
    required this.color,
    super.key,
    this.size = 18,
  });

  /// What to draw.
  final NoteUtilityGlyph glyph;

  /// The paint color.
  final Color color;

  /// Width and height.
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(glyph: glyph, color: color),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.glyph, required this.color});

  final NoteUtilityGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 12;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5 * unit;
    switch (glyph) {
      case NoteUtilityGlyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(3 * unit, 2 * unit)
            ..lineTo(10 * unit, 6 * unit)
            ..lineTo(3 * unit, 10 * unit)
            ..close(),
          fill,
        );
      case NoteUtilityGlyph.pause:
        canvas
          ..drawRect(
            Rect.fromLTRB(3 * unit, 2 * unit, 5 * unit, 10 * unit),
            fill,
          )
          ..drawRect(
            Rect.fromLTRB(7 * unit, 2 * unit, 9 * unit, 10 * unit),
            fill,
          );
      case NoteUtilityGlyph.delete:
        canvas
          ..drawLine(
            Offset(3 * unit, 3 * unit),
            Offset(9 * unit, 9 * unit),
            stroke,
          )
          ..drawLine(
            Offset(9 * unit, 3 * unit),
            Offset(3 * unit, 9 * unit),
            stroke,
          );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
