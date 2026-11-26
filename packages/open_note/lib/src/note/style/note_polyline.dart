import 'dart:ui';

/// An arc-length view of a polyline, used by the line decorations. Internal:
/// not exported by the module barrel.
class NotePolyline {
  /// Builds a cleaned polyline: non-finite and (nearly) repeated points are
  /// dropped. A [closed] line loses a repeated end point and needs three
  /// distinct points to stay closed.
  factory NotePolyline(List<Offset> source, {bool closed = false}) {
    final points = <Offset>[];
    for (final point in source) {
      if (!point.isFinite) continue;
      if (points.isNotEmpty && (point - points.last).distanceSquared < _tiny) {
        continue;
      }
      points.add(point);
    }
    if (closed &&
        points.length > 1 &&
        (points.first - points.last).distanceSquared < _tiny) {
      points.removeLast();
    }

    return NotePolyline._(points, closed: closed && points.length > 2);
  }

  NotePolyline._(this.points, {required this.closed})
    : _walk = [...points, if (closed) points.first] {
    var total = 0.0;
    for (var i = 0; i < _walk.length; i++) {
      if (i > 0) total += (_walk[i] - _walk[i - 1]).distance;
      _lengths.add(total);
    }
  }

  static const double _tiny = 1e-12;

  /// The distinct vertices (without the closing repeat).
  final List<Offset> points;

  /// Whether the last vertex joins back to the first one.
  final bool closed;

  final List<Offset> _walk;
  final List<double> _lengths = [];

  /// Total length, including the closing segment when [closed].
  double get length => _lengths.isEmpty ? 0 : _lengths.last;

  /// The point [distance] along the line. It wraps around a closed line and is
  /// clamped to the ends of an open one. Requires at least one vertex.
  Offset pointAt(double distance) {
    if (_walk.length < 2) return _walk.first;
    final at = _normalise(distance);
    final index = _segmentAt(at);
    final span = _lengths[index + 1] - _lengths[index];
    if (span <= 0) return _walk[index];
    final t = (at - _lengths[index]) / span;

    return Offset.lerp(_walk[index], _walk[index + 1], t)!;
  }

  /// The unit normal at [distance] (the direction turned a quarter turn),
  /// measured over `±window` so it does not flip abruptly at a vertex.
  Offset normalAt(double distance, double window) {
    if (_walk.length < 2) return Offset.zero;
    var tangent = pointAt(distance + window) - pointAt(distance - window);
    if (tangent.distanceSquared < _tiny) {
      final index = _segmentAt(_normalise(distance));
      tangent = _walk[index + 1] - _walk[index];
    }
    final size = tangent.distance;
    if (size <= 0) return Offset.zero;

    return Offset(-tangent.dy / size, tangent.dx / size);
  }

  double _normalise(double distance) {
    if (closed && length > 0) return distance % length;

    return distance.clamp(0.0, length);
  }

  int _segmentAt(double distance) {
    var low = 0;
    var high = _walk.length - 2;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_lengths[middle] <= distance) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }

    return low;
  }
}
