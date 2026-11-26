import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_contour.dart';
import 'package:open_note/src/note/style/note_shape_drawing.dart';

/// Records edges both as an exact [Path] and as sampled contours. Internal: not
/// exported by the module barrel.
///
/// Angles are in radians, 0 at three o'clock, positive clockwise on screen.
class NoteContourBuilder {
  static const int _curveSteps = 8;
  static const int _minArcSteps = 4;
  static const int _maxArcSteps = 64;
  static const int _minOvalSteps = 24;
  static const int _maxOvalSteps = 360;
  static const double _sampleLength = 3;
  static const double _quarter = math.pi / 2;
  static const double _tiny = 1e-9;

  final Path _path = Path();
  final List<NoteContour> _contours = [];
  final List<Offset> _points = [];

  /// The point of the ellipse inscribed in [oval] at [angle].
  static Offset pointOn(Rect oval, double angle) =>
      oval.center +
      Offset(
        oval.width / 2 * math.cos(angle),
        oval.height / 2 * math.sin(angle),
      );

  /// Starts a new open contour at [point].
  void moveTo(Offset point) {
    _finish(closed: false);
    _path.moveTo(point.dx, point.dy);
    _points.add(point);
  }

  /// Draws a straight edge to [point] (starting a contour when none is open).
  void lineTo(Offset point) {
    if (_points.isEmpty) {
      moveTo(point);

      return;
    }
    _path.lineTo(point.dx, point.dy);
    _points.add(point);
  }

  /// An open polyline through [points] as its own contour.
  void polyline(List<Offset> points) {
    moveTo(points.first);
    points.skip(1).forEach(lineTo);
  }

  /// A closed polygon through [points] as its own contour.
  void polygon(List<Offset> points) {
    polyline(points);
    close();
  }

  /// A quadratic curve from the current point.
  void quadraticTo(Offset control, Offset end) {
    final start = _points.isEmpty ? control : _points.last;
    if (_points.isEmpty) moveTo(control);
    _path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    for (var k = 1; k <= _curveSteps; k++) {
      final t = k / _curveSteps;
      final u = 1 - t;
      _points.add(start * (u * u) + control * (2 * u * t) + end * (t * t));
    }
  }

  /// An arc of the ellipse inscribed in [oval] from [start] over [sweep]
  /// radians. A line joins it to the open contour when needed.
  void arc(Rect oval, double start, double sweep) {
    final first = pointOn(oval, start);
    if (_points.isEmpty || (_points.last - first).distance > 1e-6) {
      lineTo(first);
    }
    // One conic per quadrant keeps Path.getBounds inside the ellipse's box.
    for (final (from, span) in _splitAtQuadrants(start, sweep)) {
      _path.arcTo(oval, from, span, false);
      _sampleArc(oval, from, span);
    }
  }

  /// A full ellipse as its own closed contour.
  void oval(Rect rect) {
    _finish(closed: false);
    _path.addOval(rect);
    final steps = (math.pi * (rect.width + rect.height) / 2 / _sampleLength)
        .ceil()
        .clamp(_minOvalSteps, _maxOvalSteps);
    _contours.add(
      NoteContour([
        for (var k = 0; k < steps; k++) pointOn(rect, 2 * math.pi * k / steps),
      ], closed: true),
    );
  }

  /// Closes the open contour.
  void close() {
    _path.close();
    _finish(closed: true);
  }

  /// The recorded edges.
  NoteShapePart build() {
    _finish(closed: false);

    return NoteShapePart(_path, List.unmodifiable(_contours));
  }

  Iterable<(double, double)> _splitAtQuadrants(
    double start,
    double sweep,
  ) sync* {
    final end = start + sweep;
    final direction = sweep.sign;
    var angle = start;
    while ((end - angle) * direction > _tiny) {
      final quadrant = angle / _quarter;
      final boundary = direction > 0
          ? (quadrant + _tiny).floor() + 1
          : (quadrant - _tiny).ceil() - 1;
      var next = boundary * _quarter;
      if ((next - end) * direction > 0) next = end;
      yield (angle, next - angle);
      angle = next;
    }
  }

  void _sampleArc(Rect oval, double start, double sweep) {
    final radius = math.max(oval.width, oval.height) / 2;
    final steps = (radius * sweep.abs() / _sampleLength).ceil().clamp(
      _minArcSteps,
      _maxArcSteps,
    );
    for (var k = 1; k <= steps; k++) {
      _points.add(pointOn(oval, start + sweep * k / steps));
    }
  }

  void _finish({required bool closed}) {
    if (_points.isEmpty) return;
    _contours.add(NoteContour(_points, closed: closed));
    _points.clear();
  }
}
