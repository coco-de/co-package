import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One stroke to draw for a styled line: a [path] plus the pen it needs.
///
/// Styles that decorate a line produce one of these (two for `double`). Stroke
/// the [path] with round joins; the colour is the caller's.
@immutable
class NoteStyledPath {
  const NoteStyledPath({
    required this.path,
    required this.strokeWidth,
    required this.cap,
  });

  /// The geometry to stroke, in the same coordinates as the input points.
  final Path path;

  /// Width to stroke [path] with, in the same units as the input points.
  final double strokeWidth;

  /// Line cap: round for solid, dotted, waves and double; butt for dashes.
  final StrokeCap cap;

  /// An anti-aliased stroke paint for this path in [color].
  Paint toPaint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = cap
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
}
