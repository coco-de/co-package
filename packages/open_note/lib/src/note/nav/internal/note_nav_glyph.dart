import 'package:flutter/widgets.dart';

/// The small vector icons of the nav panels (there is no icon font without a
/// design system). Not exported by the barrel.
enum NoteNavGlyph {
  chevronRight,
  chevronDown,
  plus,
  close,
  rename,
  indent,
  outdent,
  bookmark,
  bookmarkFilled,
}

/// Paints one [NoteNavGlyph] centred in its box on a 16 x 16 design grid.
class NoteNavGlyphPainter extends CustomPainter {
  const NoteNavGlyphPainter({required this.glyph, required this.color});

  final NoteNavGlyph glyph;
  final Color color;

  static const double _grid = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / (_grid * 1.5);
    canvas
      ..save()
      ..translate(
        (size.width - _grid * unit) / 2,
        (size.height - _grid * unit) / 2,
      )
      ..scale(unit);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = glyph == NoteNavGlyph.bookmarkFilled
          ? PaintingStyle.fill
          : PaintingStyle.stroke;
    for (final line in _lines(glyph)) {
      final path = Path()..moveTo(line.first.dx, line.first.dy);
      for (final point in line.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(NoteNavGlyphPainter old) =>
      old.glyph != glyph || old.color != color;

  static List<List<Offset>> _lines(NoteNavGlyph glyph) => switch (glyph) {
    NoteNavGlyph.chevronRight => const [
      [Offset(6, 3), Offset(11, 8), Offset(6, 13)],
    ],
    NoteNavGlyph.chevronDown => const [
      [Offset(3, 6), Offset(8, 11), Offset(13, 6)],
    ],
    NoteNavGlyph.plus => const [
      [Offset(8, 3), Offset(8, 13)],
      [Offset(3, 8), Offset(13, 8)],
    ],
    NoteNavGlyph.close => const [
      [Offset(4, 4), Offset(12, 12)],
      [Offset(12, 4), Offset(4, 12)],
    ],
    NoteNavGlyph.rename => const [
      [Offset(3, 13), Offset(4, 10), Offset(11, 3), Offset(13, 5)],
      [Offset(13, 5), Offset(6, 12), Offset(3, 13)],
    ],
    NoteNavGlyph.indent => const [
      [Offset(2, 3), Offset(2, 13)],
      [Offset(5, 8), Offset(14, 8)],
      [Offset(10, 4), Offset(14, 8), Offset(10, 12)],
    ],
    NoteNavGlyph.outdent => const [
      [Offset(14, 3), Offset(14, 13)],
      [Offset(11, 8), Offset(2, 8)],
      [Offset(6, 4), Offset(2, 8), Offset(6, 12)],
    ],
    NoteNavGlyph.bookmark || NoteNavGlyph.bookmarkFilled => const [
      [
        Offset(4, 2),
        Offset(12, 2),
        Offset(12, 14),
        Offset(8, 11),
        Offset(4, 14),
        Offset(4, 2),
      ],
    ],
  };
}
