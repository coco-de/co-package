import 'package:flutter/widgets.dart';

/// The small icons the overlay widgets draw. Internal to `study/overlay`.
enum NoteOverlayGlyphKind {
  /// A cross.
  close,

  /// A tick.
  check,

  /// A baseline: minimize.
  minimize,

  /// A window outline: restore.
  restore,

  /// An outlined pushpin.
  pin,

  /// A filled pushpin.
  pinned,

  /// Diagonal lines of a resize corner.
  resizeGrip,
}

/// A vector icon, drawn so no icon font is needed. Internal to
/// `study/overlay`.
class NoteOverlayGlyph extends StatelessWidget {
  /// Draws [kind].
  const NoteOverlayGlyph(
    this.kind, {
    this.color = const Color(0xFF424242),
    this.size = 16,
    super.key,
  });

  /// Which icon.
  final NoteOverlayGlyphKind kind;

  /// Stroke colour.
  final Color color;

  /// Width and height.
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(kind: kind, color: color),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.kind, required this.color});

  final NoteOverlayGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit / 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset at(double x, double y) => Offset(x * unit, y * unit);
    switch (kind) {
      case NoteOverlayGlyphKind.close:
        canvas
          ..drawLine(at(0.25, 0.25), at(0.75, 0.75), line)
          ..drawLine(at(0.75, 0.25), at(0.25, 0.75), line);
      case NoteOverlayGlyphKind.check:
        canvas.drawPath(
          Path()
            ..moveTo(0.18 * unit, 0.54 * unit)
            ..lineTo(0.42 * unit, 0.76 * unit)
            ..lineTo(0.82 * unit, 0.28 * unit),
          line,
        );
      case NoteOverlayGlyphKind.minimize:
        canvas.drawLine(at(0.22, 0.72), at(0.78, 0.72), line);
      case NoteOverlayGlyphKind.restore:
        canvas.drawRect(Rect.fromPoints(at(0.24, 0.24), at(0.76, 0.76)), line);
      case NoteOverlayGlyphKind.pin || NoteOverlayGlyphKind.pinned:
        canvas.drawLine(at(0.5, 0.56), at(0.5, 0.9), line);
        if (kind == NoteOverlayGlyphKind.pinned) {
          canvas.drawCircle(at(0.5, 0.34), 0.22 * unit, Paint()..color = color);
        }
        canvas.drawCircle(at(0.5, 0.34), 0.22 * unit, line);
      case NoteOverlayGlyphKind.resizeGrip:
        canvas
          ..drawLine(at(0.3, 0.9), at(0.9, 0.3), line)
          ..drawLine(at(0.62, 0.9), at(0.9, 0.62), line);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
