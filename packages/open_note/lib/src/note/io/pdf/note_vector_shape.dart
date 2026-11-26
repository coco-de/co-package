import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';

/// A path plus how to paint it: either filled with the non-zero rule, or
/// stroked with round caps and joins (the engine's only pen styles).
@immutable
class NoteVectorShape {
  /// [path] filled with [color] (non-zero rule).
  const NoteVectorShape.fill(this.path, this.color)
    : filled = true,
      strokeWidth = 0;

  /// [path] stroked [strokeWidth] wide in [color], with round caps and joins.
  /// A width of 0 is a hairline.
  const NoteVectorShape.stroke(this.path, this.color, this.strokeWidth)
    : filled = false;

  /// The geometry, in page coordinates. Do not add to it.
  final NoteVectorPath path;

  /// Paint colour, alpha included.
  final Color color;

  /// Whether the path is filled rather than stroked.
  final bool filled;

  /// Line width in page units; 0 for filled shapes.
  final double strokeWidth;

  /// The paint the engine would draw this with.
  Paint toPaint() => Paint()
    ..color = color
    ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
