import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_ruler_unit.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// Paints the body of a horizontal ruler: a translucent bar with ticks along
/// both long edges and numbers under the top major ticks. The ruler's start is
/// at x = 0; rotate the canvas or widget to turn it.
class NoteRulerPainter extends CustomPainter {
  /// Paints ticks and numbers for [unit].
  const NoteRulerPainter({
    required this.unit,
    this.style = const NoteViewStyle(),
  });

  /// Unit of the ticks and numbers.
  final NoteRulerUnit unit;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  static const double _majorLength = 12;
  static const double _mediumLength = 9;
  static const double _minorLength = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    final outline = Paint()
      ..color = style.rulerMarkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas
      ..drawRRect(body, Paint()..color = style.rulerColor)
      ..drawRRect(body, outline);
    final ticks = unit.ticks(size.width);
    final half = unit.minorPerMajor ~/ 2;
    for (var i = 0; i < ticks.length; i++) {
      final tick = ticks[i];
      final x = tick.position;
      final length = tick.isMajor
          ? _majorLength
          : i % half == 0
          ? _mediumLength
          : _minorLength;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, length), outline)
        ..drawLine(
          Offset(x, size.height),
          Offset(x, size.height - length),
          outline,
        );
      final label = tick.label;
      if (label != null) _paintLabel(canvas, label, x);
    }
  }

  void _paintLabel(Canvas canvas, String label, double x) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: 8, color: style.rulerMarkColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter
      ..paint(canvas, Offset(x - painter.width / 2, _majorLength + 1))
      ..dispose();
  }

  @override
  bool shouldRepaint(NoteRulerPainter old) =>
      old.unit != unit || old.style != style;
}
