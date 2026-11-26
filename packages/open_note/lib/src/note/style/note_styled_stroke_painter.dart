import 'dart:ui';

import 'package:open_note/src/note/style/note_line_path.dart';
import 'package:open_note/src/note/style/note_line_style.dart';

/// Draws a polyline in a [NoteLineStyle].
abstract final class NoteStyledStrokePainter {
  /// Paints the polyline [points] in [color] with pen [width] on [canvas].
  ///
  /// With [smooth] (the default) the points go through `NoteLinePath.smooth`
  /// first, which suits raw pen input; pass `false` for geometry that must be
  /// drawn exactly. Nothing is drawn for no points or a non-positive [width];
  /// a single point draws a dot.
  static void paint(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
    NoteLineStyle style, {
    bool smooth = true,
  }) {
    final base = smooth ? NoteLinePath.smooth(points) : points;
    for (final styled in NoteLinePath.renderPaths(base, width, style)) {
      canvas.drawPath(styled.path, styled.toPaint(color));
    }
  }
}
