import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/state/text_settings.dart';
import 'package:open_note/src/module/text/text_drawable_extensions.dart';
import 'package:open_note/src/module/text/text_painter.dart';

/// Geometry transforms of a page's ink, used when a page turns or its margins
/// grow. Every transform returns a new [Scribble] and leaves the input
/// untouched; a transform that changes nothing returns the input itself.
abstract final class NoteInkTransforms {
  static const double _fullTurn = 2 * math.pi;
  static const double _epsilon = 1e-9;

  /// Shifts all ink by [delta].
  static Scribble translate(Scribble scribble, Offset delta) {
    if (delta == Offset.zero) return scribble;
    final copy = scribble.deepCopy();
    Offset move(Offset point) => point + delta;
    for (final stroke in copy.strokes) {
      _mapStroke(stroke, move);
    }
    for (final text in copy.textDrawables) {
      text
        ..x += delta.dx
        ..y += delta.dy;
    }
    for (final image in copy.imageDrawables) {
      image
        ..x += delta.dx
        ..y += delta.dy;
    }

    return copy;
  }

  /// Turns the ink clockwise by [quarterTurns] × 90° inside a page of
  /// [pageSize] (the size **before** turning). An odd number of turns swaps the
  /// page's width and height.
  static Scribble rotate(Scribble scribble, int quarterTurns, Size pageSize) {
    final turns = quarterTurns % 4;
    if (turns == 0) return scribble;
    final map = pointRotation(turns, pageSize);
    final angle = turns * math.pi / 2;
    final copy = scribble.deepCopy();
    for (final stroke in copy.strokes) {
      _mapStroke(stroke, map);
    }
    for (final image in copy.imageDrawables) {
      final center = map(
        Offset(image.x + image.width / 2, image.y + image.height / 2),
      );
      image
        ..x = center.dx - image.width / 2
        ..y = center.dy - image.height / 2
        ..rotation = normalizeAngle(image.rotation + angle);
    }
    for (final text in copy.textDrawables) {
      _rotateText(text, map, angle);
    }

    return copy;
  }

  /// Where a point of a [pageSize] page lands after [quarterTurns] clockwise
  /// quarter turns (y grows downwards).
  static Offset Function(Offset) pointRotation(
    int quarterTurns,
    Size pageSize,
  ) => switch (quarterTurns % 4) {
    1 => (point) => Offset(pageSize.height - point.dy, point.dx),
    2 => (point) => Offset(
      pageSize.width - point.dx,
      pageSize.height - point.dy,
    ),
    3 => (point) => Offset(point.dy, pageSize.width - point.dx),
    _ => (point) => point,
  };

  /// [angle] in `[0, 2π)`, with values within rounding of a full turn as 0.
  static double normalizeAngle(double angle) {
    final normalized = angle % _fullTurn;
    if (normalized < _epsilon || _fullTurn - normalized < _epsilon) return 0;

    return normalized;
  }

  static void _mapStroke(Stroke stroke, Offset Function(Offset) map) {
    for (final point in stroke.points) {
      _mapPoint(point, map);
    }
    for (final segment in stroke.segments) {
      if (segment.hasStart()) _mapPoint(segment.start, map);
      if (segment.hasEnd()) _mapPoint(segment.end, map);
      for (final point in segment.points) {
        _mapPoint(point, map);
      }
    }
  }

  static void _mapPoint(Point point, Offset Function(Offset) map) {
    final mapped = map(Offset(point.x, point.y));
    point
      ..x = mapped.dx
      ..y = mapped.dy;
  }

  /// The engine reads `(x, y)` as the centre of rotated text, but as an
  /// alignment anchor (left edge, centre or right edge, vertically centred) of
  /// unrotated text — convert between the two as the rotation starts or ends.
  static void _rotateText(
    TextDrawable text,
    Offset Function(Offset) map,
    double angle,
  ) {
    final center = text.rotation == 0
        ? TextDrawablePainter.getTextBounds(text).center
        : Offset(text.x, text.y);
    final mapped = map(center);
    text.rotation = normalizeAngle(text.rotation + angle);
    if (text.rotation != 0) {
      text
        ..x = mapped.dx
        ..y = mapped.dy;

      return;
    }
    final width = TextDrawablePainter.getTextBounds(text).width;
    final anchorX = switch (text.alignment) {
      TextAlignment.left => mapped.dx - width / 2,
      TextAlignment.center => mapped.dx,
      TextAlignment.right => mapped.dx + width / 2,
    };
    text
      ..x = anchorX
      ..y = mapped.dy;
  }
}
