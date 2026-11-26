part of 'note_tile.dart';

/// The round selection mark of a note tile: a filled circle with a tick when
/// [checked], an empty ring otherwise.
class _NoteCheckMark extends StatelessWidget {
  const _NoteCheckMark({required this.checked, required this.color, super.key});

  /// Whether the note is selected.
  final bool checked;

  /// The fill of a checked mark.
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(22),
    painter: _NoteCheckPainter(checked, color),
  );
}

/// The pushpin badge of a pinned note.
class _NotePinMark extends StatelessWidget {
  const _NotePinMark({required this.color, super.key});

  /// The colour of the pin.
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.square(20), painter: _NotePinPainter(color));
}

class _NoteCheckPainter extends CustomPainter {
  const _NoteCheckPainter(this.checked, this.color);

  final bool checked;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = checked ? color : const Color(0xE6FFFFFF),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = checked ? const Color(0xFFFFFFFF) : const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (!checked) return;
    final tick = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.36);
    canvas.drawPath(
      tick,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_NoteCheckPainter oldDelegate) =>
      oldDelegate.checked != checked || oldDelegate.color != color;
}

class _NotePinPainter extends CustomPainter {
  const _NotePinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 20;
    canvas
      ..drawCircle(
        size.center(Offset.zero),
        unit * 10,
        Paint()..color = const Color(0xF2FFFFFF),
      )
      ..save()
      ..scale(unit);
    final head = Path()
      ..moveTo(7.5, 4.5)
      ..lineTo(12.5, 4.5)
      ..lineTo(12, 8.5)
      ..lineTo(14.5, 11.5)
      ..lineTo(5.5, 11.5)
      ..lineTo(8, 8.5)
      ..close();
    canvas
      ..drawPath(head, Paint()..color = color)
      ..drawLine(
        const Offset(10, 11.5),
        const Offset(10, 16),
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NotePinPainter oldDelegate) => oldDelegate.color != color;
}
