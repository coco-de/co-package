import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One step of a `NoteVectorPath`, in page coordinates.
@immutable
sealed class NoteVectorSegment {
  const NoteVectorSegment();
}

/// Starts a new subpath at [point].
final class NoteVectorMove extends NoteVectorSegment {
  /// A move to [point].
  const NoteVectorMove(this.point);

  /// Where the subpath starts.
  final Offset point;

  @override
  bool operator ==(Object other) =>
      other is NoteVectorMove && other.point == point;

  @override
  int get hashCode => Object.hash(NoteVectorMove, point);

  @override
  String toString() => 'M $point';
}

/// A straight line from the current point to [point].
final class NoteVectorLine extends NoteVectorSegment {
  /// A line to [point].
  const NoteVectorLine(this.point);

  /// Where the line ends.
  final Offset point;

  @override
  bool operator ==(Object other) =>
      other is NoteVectorLine && other.point == point;

  @override
  int get hashCode => Object.hash(NoteVectorLine, point);

  @override
  String toString() => 'L $point';
}

/// A cubic Bezier from the current point to [point].
final class NoteVectorCubic extends NoteVectorSegment {
  /// A cubic curve with control points [control1] and [control2].
  const NoteVectorCubic(this.control1, this.control2, this.point);

  /// The first control point.
  final Offset control1;

  /// The second control point.
  final Offset control2;

  /// Where the curve ends.
  final Offset point;

  @override
  bool operator ==(Object other) =>
      other is NoteVectorCubic &&
      other.control1 == control1 &&
      other.control2 == control2 &&
      other.point == point;

  @override
  int get hashCode => Object.hash(NoteVectorCubic, control1, control2, point);

  @override
  String toString() => 'C $control1 $control2 $point';
}

/// Closes the current subpath with a line back to its start.
final class NoteVectorClose extends NoteVectorSegment {
  /// A close step.
  const NoteVectorClose();

  @override
  bool operator ==(Object other) => other is NoteVectorClose;

  @override
  int get hashCode => (NoteVectorClose).hashCode;

  @override
  String toString() => 'Z';
}
