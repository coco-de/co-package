// Internal to the stroke vectorizer: the geometry of shape strokes, mirroring
// the engine's `ShapePaintDelegate` (whose drawing methods are private and
// paint straight to a canvas). Not exported from the module barrel.
import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/core/utils/geometry_utils.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';

/// The outline of a stroke with a `shapeType`, or `null` when the engine draws
/// nothing for it.
NoteVectorPath? noteShapeStrokePath(Stroke stroke) {
  if (stroke.points.length < 2) return null;
  final points = stroke.points;

  return switch (stroke.shapeType) {
    'line' => _polyline([_offset(points.first), _offset(points.last)]),
    'rectangle' || 'square' => _rectangle(stroke),
    'circle' || 'ellipse' =>
      points.length == 2
          ? _ovalFromBounds(points.first, points.last)
          : _fittedEllipse(stroke),
    'polyline' => _openPolyline(stroke),
    _ => stroke.segments.isNotEmpty ? _closedPolygon(stroke) : null,
  };
}

NoteVectorPath? _rectangle(Stroke stroke) {
  if (stroke.segments.isNotEmpty) return _closedPolygon(stroke);
  if (stroke.points.length != 2) return null;

  return NoteVectorPath()..addRect(
    Rect.fromPoints(_offset(stroke.points.first), _offset(stroke.points.last)),
  );
}

NoteVectorPath _ovalFromBounds(Point start, Point end) =>
    NoteVectorPath()..addOval(Rect.fromPoints(_offset(start), _offset(end)));

/// The ellipse the engine fits to a recognised circle's points (principal
/// component analysis).
NoteVectorPath? _fittedEllipse(Stroke stroke) {
  final points = stroke.points;
  if (points.length < 5) return _openPolyline(stroke);
  final centroid = GeometryUtils.calculateCentroid(points);
  final center = Offset(centroid.x, centroid.y);
  var covXx = 0.0;
  var covYy = 0.0;
  var covXy = 0.0;
  for (final point in points) {
    final dx = point.x - center.dx;
    final dy = point.y - center.dy;
    covXx += dx * dx;
    covYy += dy * dy;
    covXy += dx * dy;
  }
  covXx /= points.length;
  covYy /= points.length;
  covXy /= points.length;
  final angle = covXx == covYy && covXy == 0
      ? 0.0
      : 0.5 * math.atan2(2 * covXy, covXx - covYy);
  final trace = covXx + covYy;
  final det = covXx * covYy - covXy * covXy;
  final disc = math.sqrt(math.max(0, trace * trace - 4 * det));
  final principal = math.sqrt(math.max((trace + disc) / 2, 0));
  final secondary = math.sqrt(math.max((trace - disc) / 2, 0));
  final radii = _radii(points, center, angle, principal, secondary);

  return NoteVectorPath()..addOval(
    Rect.fromCenter(
      center: center,
      width: radii.width * 2,
      height: radii.height * 2,
    ),
    rotation: angle,
  );
}

Size _radii(
  List<Point> points,
  Offset center,
  double angle,
  double principal,
  double secondary,
) {
  final aspect = principal > 0 ? secondary / principal : 1.0;
  final cos = math.cos(-angle);
  final sin = math.sin(-angle);
  var maxX = 0.0;
  var maxY = 0.0;
  for (final point in points) {
    final dx = point.x - center.dx;
    final dy = point.y - center.dy;
    maxX = math.max(maxX, (dx * cos - dy * sin).abs());
    maxY = math.max(maxY, (dx * sin + dy * cos).abs());
  }
  if (aspect > 0.9) {
    final radius = math.max(maxX, maxY);

    return Size(radius, radius);
  }

  return Size(
    math.max(principal * 1.2, maxX * 0.95),
    math.max(secondary * 1.2, maxY * 0.95),
  );
}

/// A polygon through the segment ring, or through the points back to the
/// first one.
NoteVectorPath? _closedPolygon(Stroke stroke) {
  if (stroke.segments.isNotEmpty) return _segmentChain(stroke);
  if (stroke.points.isEmpty) return null;
  final points = stroke.points.map(_offset).toList();

  return _polyline([...points, points.first]);
}

NoteVectorPath? _openPolyline(Stroke stroke) {
  if (stroke.segments.isNotEmpty) return _segmentChain(stroke);
  if (stroke.points.isEmpty) return null;

  return _polyline(stroke.points.map(_offset).toList());
}

NoteVectorPath _segmentChain(Stroke stroke) => _polyline([
  _offset(stroke.segments.first.start),
  for (final segment in stroke.segments) _offset(segment.end),
]);

NoteVectorPath _polyline(List<Offset> points) {
  final path = NoteVectorPath()..moveTo(points.first);
  for (final point in points.skip(1)) {
    path.lineTo(point);
  }

  return path;
}

Offset _offset(Point point) => Offset(point.x, point.y);
