import 'dart:ui';

import 'package:open_note/src/note/style/note_shape_arrow_geometry.dart';
import 'package:open_note/src/note/style/note_shape_drawing.dart';
import 'package:open_note/src/note/style/note_shape_flat_geometry.dart';
import 'package:open_note/src/note/style/note_shape_head_style.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/style/note_shape_paths.dart';
import 'package:open_note/src/note/style/note_shape_solid_geometry.dart';

/// Builds the geometry of every [NoteShapeKind] inside a rectangle.
///
/// **Rectangles.** Closed and 3-D shapes normalise the rectangle and fill it.
/// `line`, `arrow` and `doubleArrow` run from `Offset(rect.left, rect.top)` to
/// `Offset(rect.right, rect.bottom)`, **so the rectangle is not normalised**:
/// pass `Rect.fromLTRB(start.dx, start.dy, end.dx, end.dy)` to draw in any
/// direction (`Rect.fromPoints` would lose it).
///
/// **Containment.** All geometry stays inside the rectangle (for linear kinds,
/// the normalised one). An arrowhead needs room: on an axis where the
/// rectangle is thinner than the head (a horizontal arrow has no height) it
/// reaches at most half the head width beyond it.
///
/// A rectangle with a non-finite edge yields empty paths.
abstract final class NoteShapeGeometry {
  /// The paths of [kind] in [rect].
  ///
  /// [cornerRadius] (page units) rounds `rectangle`, `roundedRectangle`
  /// (which is rounded by 15 % of its shorter side when it is 0) and the flat
  /// polygons; other kinds ignore it. [headStyle] and [headLength] only apply
  /// to arrows; the default length is a quarter of the arrow, at most 24, and a
  /// length is capped at 60 % (45 % per end for `doubleArrow`) of the arrow.
  static NoteShapePaths pathsFor(
    NoteShapeKind kind,
    Rect rect, {
    double cornerRadius = 0,
    NoteShapeHeadStyle headStyle = NoteShapeHeadStyle.triangle,
    double? headLength,
  }) => drawingFor(
    kind,
    rect,
    cornerRadius: cornerRadius,
    headStyle: headStyle,
    headLength: headLength,
  ).toPaths();

  /// Like [pathsFor], with the arrowheads separate and every edge also as a
  /// polyline (`NoteContour`).
  ///
  /// With [containHeads] (the default) arrow tips move inwards to honour the
  /// containment rule above. Pass `false` to keep the tips exactly on the end
  /// points, which lets the head of a nearly horizontal or vertical arrow
  /// reach beyond the rectangle (what `NoteShapePainter` does).
  static NoteShapeDrawing drawingFor(
    NoteShapeKind kind,
    Rect rect, {
    double cornerRadius = 0,
    NoteShapeHeadStyle headStyle = NoteShapeHeadStyle.triangle,
    double? headLength,
    bool containHeads = true,
  }) {
    if (!_isFinite(rect)) {
      return NoteShapeDrawing(outline: NoteShapePart.empty());
    }
    final box = Rect.fromPoints(rect.topLeft, rect.bottomRight);
    NoteShapeDrawing polygon(List<Offset> vertices) =>
        NoteShapeFlatGeometry.polygon(vertices, cornerRadius);

    return switch (kind) {
      NoteShapeKind.line ||
      NoteShapeKind.arrow ||
      NoteShapeKind.doubleArrow => NoteShapeArrowGeometry.draw(
        kind,
        rect.topLeft,
        rect.bottomRight,
        headStyle: headStyle,
        headLength: headLength,
        containHeads: containHeads,
      ),
      NoteShapeKind.rectangle => NoteShapeFlatGeometry.rectangle(
        box,
        cornerRadius,
      ),
      NoteShapeKind.roundedRectangle => NoteShapeFlatGeometry.roundedRectangle(
        box,
        cornerRadius,
      ),
      NoteShapeKind.ellipse => NoteShapeFlatGeometry.ellipse(box),
      NoteShapeKind.triangle => polygon(NoteShapeFlatGeometry.triangle(box)),
      NoteShapeKind.rightTriangle => polygon(
        NoteShapeFlatGeometry.rightTriangle(box),
      ),
      NoteShapeKind.diamond => polygon(NoteShapeFlatGeometry.diamond(box)),
      NoteShapeKind.pentagon => polygon(NoteShapeFlatGeometry.pentagon(box)),
      NoteShapeKind.hexagon => polygon(NoteShapeFlatGeometry.hexagon(box)),
      NoteShapeKind.star => polygon(NoteShapeFlatGeometry.star(box)),
      NoteShapeKind.cube => NoteShapeSolidGeometry.cube(box),
      NoteShapeKind.cylinder => NoteShapeSolidGeometry.cylinder(box),
      NoteShapeKind.cone => NoteShapeSolidGeometry.cone(box),
      NoteShapeKind.pyramid => NoteShapeSolidGeometry.pyramid(box),
      NoteShapeKind.sphere => NoteShapeSolidGeometry.sphere(box),
    };
  }

  static bool _isFinite(Rect rect) =>
      rect.left.isFinite &&
      rect.top.isFinite &&
      rect.right.isFinite &&
      rect.bottom.isFinite;
}
