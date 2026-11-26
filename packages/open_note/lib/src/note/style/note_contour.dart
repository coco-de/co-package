import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One polyline of a shape: curves are sampled finely, corners are exact.
@immutable
class NoteContour {
  NoteContour(List<Offset> points, {this.closed = false})
    : points = List.unmodifiable(points);

  /// The vertices in drawing order. A closed contour does not repeat its first
  /// point.
  final List<Offset> points;

  /// Whether the last point joins back to the first.
  final bool closed;

  @override
  bool operator ==(Object other) =>
      other is NoteContour &&
      other.closed == closed &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(closed, Object.hashAll(points));

  @override
  String toString() => 'NoteContour(${points.length} points, closed: $closed)';
}
