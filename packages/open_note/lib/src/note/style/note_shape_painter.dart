import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_line_path.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_shape_drawing.dart';
import 'package:open_note/src/note/style/note_shape_geometry.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/style/note_shape_style.dart';
import 'package:open_note/src/note/style/note_styled_path.dart';

/// Draws a shape with its fill, decorated outline, hidden edges and heads.
abstract final class NoteShapePainter {
  static const double _minHeadLength = 10;
  static const double _headLengthPerWidth = 4.5;
  static const double _decorationReach = 8;

  static final NoteLineStyle _hiddenEdges = NoteLineStyle.of(
    NoteLineStyleKind.dashed,
  );

  /// The arrowhead length [paint] uses for a stroke [width] (page units):
  /// four and a half widths, at least 10.
  static double headLengthFor(double width) =>
      math.max(_minHeadLength, width * _headLengthPerWidth);

  /// Paints [kind] in [rect] with a [width] wide stroke in [strokeColor].
  ///
  /// See `NoteShapeGeometry` for how the rectangle is read (linear kinds keep
  /// its direction). Arrow tips are exactly on the end points. The fill is
  /// drawn first and only for closed kinds; hidden edges are dashed; heads are
  /// solid. A translucent stroke is composited as one layer, so crossing edges
  /// do not darken. A [width] that is not positive draws only the fill, and a
  /// rectangle with a non-finite edge draws nothing.
  static void paint(
    Canvas canvas,
    Rect rect,
    NoteShapeKind kind,
    Color strokeColor,
    double width,
    NoteShapeStyle style,
  ) {
    if (!rect.isFinite) return;
    final drawing = NoteShapeGeometry.drawingFor(
      kind,
      rect,
      cornerRadius: style.cornerRadius,
      headStyle: style.headStyle,
      headLength: headLengthFor(width),
      containHeads: false,
    );
    if (!kind.isLinear) _fill(canvas, drawing.outline.path, style);
    final alpha = strokeColor.a * style.strokeOpacity;
    if (!width.isFinite || width <= 0 || alpha <= 0) return;
    final layered = alpha < 1;
    if (layered) {
      canvas.saveLayer(
        _reachOf(rect, width),
        Paint()..color = const Color(0xFF000000).withValues(alpha: alpha),
      );
    }
    _strokeAll(canvas, drawing, strokeColor.withValues(alpha: 1), width, style);
    if (layered) canvas.restore();
  }

  static Rect _reachOf(Rect rect, double width) => Rect.fromPoints(
    rect.topLeft,
    rect.bottomRight,
  ).inflate(width * _decorationReach + headLengthFor(width));

  static void _fill(Canvas canvas, Path path, NoteShapeStyle style) {
    final color = style.fillColor;
    if (color == null) return;
    final alpha = color.a * style.fillOpacity;
    if (alpha <= 0) return;
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  static void _strokeAll(
    Canvas canvas,
    NoteShapeDrawing drawing,
    Color color,
    double width,
    NoteShapeStyle style,
  ) {
    _strokePart(canvas, drawing.outline, color, width, style.lineStyle);
    if (drawing.inner case final inner?) {
      _strokePart(canvas, inner, color, width, style.lineStyle);
    }
    if (drawing.hidden case final hidden?) {
      _strokePart(canvas, hidden, color, width, _hiddenEdges);
    }
    if (drawing.heads case final heads?) {
      _paintHeads(canvas, heads, color, width, filled: drawing.fillHeads);
    }
  }

  static void _strokePart(
    Canvas canvas,
    NoteShapePart part,
    Color color,
    double width,
    NoteLineStyle line,
  ) {
    switch (line.kind) {
      case NoteLineStyleKind.solid:
        _draw(canvas, part.path, color, width, StrokeCap.round);
      case NoteLineStyleKind.dashed:
      case NoteLineStyleKind.dotted:
        _draw(
          canvas,
          NoteLinePath.dashPath(
            part.path,
            line.dashLength * width,
            line.gap * width,
          ),
          color,
          width,
          line.kind == NoteLineStyleKind.dotted
              ? StrokeCap.round
              : StrokeCap.butt,
        );
      case NoteLineStyleKind.wavy:
      case NoteLineStyleKind.zigzag:
      case NoteLineStyleKind.double:
        _decorate(canvas, part, color, width, line);
    }
  }

  static void _decorate(
    Canvas canvas,
    NoteShapePart part,
    Color color,
    double width,
    NoteLineStyle line,
  ) {
    for (final contour in part.contours) {
      final strokes = NoteLinePath.renderPaths(
        contour.points,
        width,
        line,
        closed: contour.closed,
      );
      for (final styled in strokes) {
        canvas.drawPath(styled.path, styled.toPaint(color));
      }
    }
  }

  static void _paintHeads(
    Canvas canvas,
    NoteShapePart heads,
    Color color,
    double width, {
    required bool filled,
  }) {
    if (filled) {
      canvas.drawPath(heads.path, Paint()..color = color);
    } else {
      _draw(canvas, heads.path, color, width, StrokeCap.round);
    }
  }

  static void _draw(
    Canvas canvas,
    Path path,
    Color color,
    double width,
    StrokeCap cap,
  ) {
    final styled = NoteStyledPath(path: path, strokeWidth: width, cap: cap);
    canvas.drawPath(styled.path, styled.toPaint(color));
  }
}
