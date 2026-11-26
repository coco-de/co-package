import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_region_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_region_selector_style.dart';

/// Dims the page around a region selection and draws its border and handles.
/// Internal to `study/overlay`.
class NoteRegionPainter extends CustomPainter {
  /// Paints [region] (nothing but the scrim when `null`).
  const NoteRegionPainter({required this.region, required this.style});

  /// The selection in page coordinates.
  final Rect? region;

  /// Colours and metrics.
  final NoteRegionSelectorStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final selection = region;
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (selection != null) scrim.addRect(selection);
    canvas.drawPath(scrim, Paint()..color = style.scrimColor);
    if (selection != null) _paintSelection(canvas, selection);
  }

  @override
  bool shouldRepaint(NoteRegionPainter oldDelegate) =>
      oldDelegate.region != region || oldDelegate.style != style;

  void _paintSelection(Canvas canvas, Rect selection) {
    final border = Paint()
      ..color = style.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth;
    canvas.drawRect(selection, border);
    for (final handle in NoteRegionHandle.values) {
      final center = handle.positionOn(selection);
      canvas
        ..drawCircle(
          center,
          style.handleRadius,
          Paint()..color = style.handleColor,
        )
        ..drawCircle(center, style.handleRadius, border);
    }
  }
}
