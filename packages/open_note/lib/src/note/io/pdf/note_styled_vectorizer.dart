import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/core/const.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/painter/stroke_styles.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';
import 'package:open_note/src/note/io/pdf/note_vector_shape.dart';
import 'package:open_note/src/note/io/render/note_render_geometry.dart';
import 'package:open_note/src/note/style/note_contour.dart';
import 'package:open_note/src/note/style/note_line_path.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_shape_geometry.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/style/note_shape_painter.dart';
import 'package:open_note/src/note/style/note_shape_style.dart';

/// Vector geometry for strokes with a line or shape style, matching what the
/// engine's painters draw (see [StrokeStyles]). Returns `null` for strokes the
/// plain vectorizer handles.
abstract final class NoteStyledVectorizer {
  /// Distance between samples when a decorated path is turned into segments.
  static const double _sampleSpacing = 1;

  /// How hidden edges of 3-D shapes are drawn.
  static final NoteLineStyle _hidden = NoteLineStyle.of(
    NoteLineStyleKind.dashed,
  );

  static List<NoteVectorShape>? vectorize(Stroke stroke) {
    if (stroke.ink == InkModes.lasso || !noteIsFiniteStroke(stroke)) {
      return null;
    }
    if (stroke.shapeType.isNotEmpty) return _shapes(stroke);

    return _line(stroke);
  }

  static List<NoteVectorShape>? _line(Stroke stroke) {
    final style = StrokeStyles.lineStyleOf(stroke);
    if (style == null || stroke.points.isEmpty) return null;
    final isMarker = stroke.ink == InkModes.marker;
    final color = Color(
      isMarker
          ? applyTransparencyToMarkerColorValue(stroke.color)
          : stroke.color,
    );
    final width = stroke.options.size * (isMarker ? 2 : 1);

    return _styled(
      NoteLinePath.smooth([
        for (final point in stroke.points) Offset(point.x, point.y),
      ]),
      color,
      width,
      style,
    );
  }

  static List<NoteVectorShape>? _shapes(Stroke stroke) {
    final color = Color(stroke.color);
    final width = math.max(0.0, stroke.options.size);
    final noteShape = StrokeStyles.noteShapeOf(stroke);
    if (noteShape != null) {
      return _noteShape(stroke, noteShape.kind, noteShape.style, color, width);
    }
    final shapeStyle = StrokeStyles.shapeStyleOf(stroke);
    var lineStyle = StrokeStyles.lineStyleOf(stroke);
    if (lineStyle == null &&
        shapeStyle != null &&
        shapeStyle.lineStyle.kind != NoteLineStyleKind.solid) {
      lineStyle = shapeStyle.lineStyle;
    }
    if (shapeStyle == null && lineStyle == null) return null;
    final outline = StrokeStyles.recognizedOutlineOf(stroke);
    final fill = shapeStyle?.fillColor;
    final shapes = <NoteVectorShape>[
      if (fill != null && outline.length > 2)
        NoteVectorShape.fill(
          _polyline(outline, close: true),
          fill.withValues(alpha: fill.a * shapeStyle!.fillOpacity),
        ),
    ];
    if (lineStyle != null) {
      return shapes..addAll(_styled(outline, color, width, lineStyle));
    }

    return shapes
      ..add(NoteVectorShape.stroke(_polyline(outline), color, width));
  }

  static List<NoteVectorShape> _noteShape(
    Stroke stroke,
    NoteShapeKind kind,
    NoteShapeStyle style,
    Color color,
    double width,
  ) {
    final drawing = NoteShapeGeometry.drawingFor(
      kind,
      StrokeStyles.shapeRectOf(stroke),
      cornerRadius: style.cornerRadius,
      headStyle: style.headStyle,
      headLength: NoteShapePainter.headLengthFor(width),
      containHeads: false,
    );
    final stroked = color.withValues(alpha: color.a * style.strokeOpacity);
    final fill = style.fillColor;
    final shapes = <NoteVectorShape>[
      if (fill != null && !kind.isLinear)
        for (final contour in drawing.outline.contours)
          NoteVectorShape.fill(
            _polyline(contour.points, close: true),
            fill.withValues(alpha: fill.a * style.fillOpacity),
          ),
    ];
    void strokeContours(
      Iterable<List<Offset>> contours,
      NoteLineStyle lineStyle,
    ) {
      for (final contour in contours) {
        if (lineStyle.kind == NoteLineStyleKind.solid) {
          shapes.add(
            NoteVectorShape.stroke(_polyline(contour), stroked, width),
          );
        } else {
          shapes.addAll(_styled(contour, stroked, width, lineStyle));
        }
      }
    }

    List<List<Offset>> closedPoints(Iterable<NoteContour> contours) => [
      for (final contour in contours)
        contour.closed && contour.points.isNotEmpty
            ? <Offset>[...contour.points, contour.points.first]
            : List<Offset>.of(contour.points),
    ];

    strokeContours(closedPoints(drawing.outline.contours), style.lineStyle);
    final inner = drawing.inner;
    if (inner != null) {
      strokeContours(closedPoints(inner.contours), style.lineStyle);
    }
    final hidden = drawing.hidden;
    if (hidden != null) {
      strokeContours(closedPoints(hidden.contours), _hidden);
    }
    final heads = drawing.heads;
    if (heads != null) {
      for (final contour in closedPoints(heads.contours)) {
        shapes.add(
          drawing.fillHeads
              ? NoteVectorShape.fill(_polyline(contour, close: true), stroked)
              : NoteVectorShape.stroke(_polyline(contour), stroked, width),
        );
      }
    }

    return shapes;
  }

  /// The decorated paths of [points], sampled back into segments.
  static List<NoteVectorShape> _styled(
    List<Offset> points,
    Color color,
    double width,
    NoteLineStyle style,
  ) => [
    for (final styled in NoteLinePath.renderPaths(points, width, style))
      if (_sampled(styled.path) case final path when !path.isEmpty)
        NoteVectorShape.stroke(path, color, styled.strokeWidth),
  ];

  static NoteVectorPath _sampled(Path source) {
    final result = NoteVectorPath();
    for (final metric in source.computeMetrics()) {
      final steps = math.max(1, (metric.length / _sampleSpacing).ceil());
      for (var step = 0; step <= steps; step++) {
        final tangent = metric.getTangentForOffset(
          metric.length * step / steps,
        );
        if (tangent == null) continue;
        if (step == 0) {
          result.moveTo(tangent.position);
        } else {
          result.lineTo(tangent.position);
        }
      }
    }

    return result;
  }

  static NoteVectorPath _polyline(List<Offset> points, {bool close = false}) {
    final path = NoteVectorPath();
    if (points.isEmpty) return path;
    path.moveTo(points.first);
    for (final point in points.skip(1)) {
      path.lineTo(point);
    }
    if (close) path.close();

    return path;
  }
}
