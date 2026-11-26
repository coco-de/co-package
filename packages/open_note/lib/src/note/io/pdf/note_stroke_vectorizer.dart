import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/core/const.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/core/utils/stroke_calculator.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/io/pdf/note_shape_vectorizer.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';
import 'package:open_note/src/note/io/pdf/note_vector_shape.dart';
import 'package:open_note/src/note/io/render/note_render_geometry.dart';

/// Turns an engine [Stroke] into the vector geometry the engine paints, so a
/// PDF shows the same ink as the screen.
///
/// - shape strokes (`shapeType` set): stroked outlines, as the engine's shape
///   painter draws them;
/// - `pen` and `shape` ink: the filled perfect_freehand outline;
/// - `pencil` and `marker`: the stroked smoothing curve through the points
///   (marker twice as wide, with its pastel transparency);
/// - `fixedPen` and `uniformPen`: the streamlined centre line, smoothed the
///   same way and stroked at the stroke size (within about a unit of the
///   engine's uniform-width outline, even for sparse strokes);
/// - lasso, eraser and unknown inks: nothing.
///
/// The input stroke is never modified.
abstract final class NoteStrokeVectorizer {
  /// The shape for [stroke], or `null` when the engine draws nothing (or the
  /// stroke holds non-finite numbers).
  static NoteVectorShape? vectorize(Stroke stroke) {
    if (stroke.ink == InkModes.lasso || !noteIsFiniteStroke(stroke)) {
      return null;
    }
    if (stroke.shapeType.isNotEmpty) {
      final path = noteShapeStrokePath(stroke);

      return path == null
          ? null
          : NoteVectorShape.stroke(
              path,
              Color(stroke.color),
              math.max(0, stroke.options.size),
            );
    }

    return switch (stroke.ink) {
      InkModes.pen || InkModes.shape => _outline(stroke),
      InkModes.pencil => _curve(
        stroke,
        Color(stroke.color),
        stroke.options.size,
      ),
      InkModes.marker => _curve(
        stroke,
        Color(applyTransparencyToMarkerColorValue(stroke.color)),
        stroke.options.size * 2,
      ),
      InkModes.fixedPen || InkModes.uniformPen => _centreLine(stroke),
      _ => null,
    };
  }

  /// Mirrors `SketchLinePainter.getPathForStrokeOld`.
  static NoteVectorShape? _outline(Stroke stroke) {
    final outline = [
      for (final point in getStroke(stroke)) Offset(point.x, point.y),
    ];
    if (outline.isEmpty || !outline.every((point) => point.isFinite)) {
      return null;
    }
    final path = _smoothPath(outline);
    if (outline.length > 1) path.close();

    return NoteVectorShape.fill(path, Color(stroke.color));
  }

  /// Mirrors `SketchLinePainter.getSimplePathForStroke`.
  static NoteVectorShape? _curve(Stroke stroke, Color color, double width) {
    if (stroke.points.isEmpty) return null;
    final points = [
      for (final point in stroke.points) Offset(point.x, point.y),
    ];

    return NoteVectorShape.stroke(
      _smoothPath(points),
      color,
      math.max(0, width),
    );
  }

  /// Quadratic curves through the midpoints; a single point is a tiny circle.
  static NoteVectorPath _smoothPath(List<Offset> points) {
    final path = NoteVectorPath();
    if (points.length < 2) {
      return path..addOval(Rect.fromCircle(center: points.first, radius: 1));
    }
    path.moveTo(points.first);
    for (var i = 1; i < points.length - 1; i++) {
      path.quadraticTo(points[i], (points[i] + points[i + 1]) / 2);
    }

    return path..lineTo(points.last);
  }

  static NoteVectorShape? _centreLine(Stroke stroke) {
    final options = stroke.options.deepCopy()
      ..thinning = 0
      ..simulatePressure = false;
    final centre = [
      for (final point in getStrokePoints(stroke.points, options: options))
        Offset(point.point.x, point.point.y),
    ];
    if (centre.isEmpty || !centre.every((point) => point.isFinite)) return null;
    // The same midpoint smoothing the engine applies to its outline, so sparse
    // strokes bend as they do on screen. A zero-length line with round caps is
    // drawn as a dot.
    final path = centre.length > 1
        ? _smoothPath(centre)
        : (NoteVectorPath()
            ..moveTo(centre.first)
            ..lineTo(centre.first));

    return NoteVectorShape.stroke(
      path,
      Color(stroke.color),
      math.max(0, stroke.options.size),
    );
  }
}
