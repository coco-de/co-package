import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_contour_builder.dart';
import 'package:open_note/src/note/style/note_shape_drawing.dart';
import 'package:open_note/src/note/style/note_shape_head_style.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';

/// The `line`, `arrow` and `doubleArrow` shapes. Internal: not exported by the
/// module barrel.
abstract final class NoteShapeArrowGeometry {
  static const double _defaultHeadFraction = 0.25;
  static const double _defaultHeadLimit = 24;
  static const double _singleHeadFraction = 0.6;
  static const double _doubleHeadFraction = 0.45;
  static const double _halfWidthRatio = 0.5;
  static const double _dotRadiusRatio = 0.35;
  static const int _fitPasses = 4;
  static const double _tiny = 1e-9;

  /// The shaft from [start] to [end] plus its heads.
  ///
  /// With [containHeads] the head tips move inwards (and, as a last resort, the
  /// head vertices are clamped) so the whole arrow stays inside the rectangle
  /// spanned by the two points, on every axis where the head fits at all.
  static NoteShapeDrawing draw(
    NoteShapeKind kind,
    Offset start,
    Offset end, {
    required NoteShapeHeadStyle headStyle,
    required double? headLength,
    required bool containHeads,
  }) {
    final span = (end - start).distance;
    final size = _headSize(kind, span, headLength);
    final style = kind == NoteShapeKind.line
        ? NoteShapeHeadStyle.none
        : headStyle;
    if (style == NoteShapeHeadStyle.none || span <= _tiny || size <= 0) {
      return NoteShapeDrawing(outline: _segment(start, end));
    }
    final both = kind == NoteShapeKind.doubleArrow;
    final frame = containHeads ? Rect.fromPoints(start, end) : null;
    var tip = end;
    var tail = start;
    if (frame != null) {
      // Moving one end turns the line, which moves the other head again.
      for (var round = 0; round < _fitPasses; round++) {
        tip = _fit(tip, tail, size, style, frame);
        if (both) tail = _fit(tail, tip, size, style, frame);
      }
    }
    final direction = _unit(tip - tail);
    final heads = NoteContourBuilder();
    _addHead(heads, tip, direction, size, style, frame);
    if (both) _addHead(heads, tail, -direction, size, style, frame);

    return NoteShapeDrawing(
      outline: _segment(
        both ? _shaftEnd(tail, -direction, size, style) : tail,
        _shaftEnd(tip, direction, size, style),
      ),
      heads: heads.build(),
      fillHeads: style != NoteShapeHeadStyle.open,
    );
  }

  static double _headSize(NoteShapeKind kind, double span, double? wanted) {
    final size =
        wanted ?? math.min(span * _defaultHeadFraction, _defaultHeadLimit);
    if (!size.isFinite || size <= 0) return 0;
    final fraction = kind == NoteShapeKind.doubleArrow
        ? _doubleHeadFraction
        : _singleHeadFraction;

    return math.min(size, span * fraction);
  }

  static NoteShapePart _segment(Offset start, Offset end) =>
      (NoteContourBuilder()..polyline([start, end])).build();

  static Offset _unit(Offset vector) {
    final distance = vector.distance;

    return distance > _tiny ? vector / distance : const Offset(1, 0);
  }

  static Offset _shaftEnd(
    Offset tip,
    Offset direction,
    double size,
    NoteShapeHeadStyle style,
  ) => switch (style) {
    NoteShapeHeadStyle.triangle => tip - direction * size,
    NoteShapeHeadStyle.dot => tip - direction * (size * _dotRadiusRatio),
    NoteShapeHeadStyle.open || NoteShapeHeadStyle.none => tip,
  };

  /// The extreme points of a head: its three vertices, or the four sides of
  /// the dot.
  static List<Offset> _headPoints(
    Offset tip,
    Offset direction,
    double size,
    NoteShapeHeadStyle style,
  ) {
    if (style == NoteShapeHeadStyle.dot) {
      final radius = size * _dotRadiusRatio;
      final center = tip - direction * radius;

      return [
        center + Offset(radius, 0),
        center - Offset(radius, 0),
        center + Offset(0, radius),
        center - Offset(0, radius),
      ];
    }
    final base = tip - direction * size;
    final side = Offset(-direction.dy, direction.dx) * size * _halfWidthRatio;

    return [base + side, tip, base - side];
  }

  static void _addHead(
    NoteContourBuilder builder,
    Offset tip,
    Offset direction,
    double size,
    NoteShapeHeadStyle style,
    Rect? frame,
  ) {
    if (style == NoteShapeHeadStyle.dot) {
      final radius = size * _dotRadiusRatio;
      builder.oval(
        Rect.fromCircle(center: tip - direction * radius, radius: radius),
      );

      return;
    }
    var points = _headPoints(tip, direction, size, style);
    if (frame != null) points = _clampInto(points, frame);
    if (style == NoteShapeHeadStyle.open) {
      builder.polyline(points);
    } else {
      builder.polygon(points);
    }
  }

  static Offset _fit(
    Offset tip,
    Offset anchor,
    double size,
    NoteShapeHeadStyle style,
    Rect frame,
  ) {
    var current = tip;
    for (var pass = 0; pass < _fitPasses; pass++) {
      final points = _headPoints(current, _unit(current - anchor), size, style);
      final shift = Offset(
        _axisShift([for (final p in points) p.dx], frame.left, frame.right),
        _axisShift([for (final p in points) p.dy], frame.top, frame.bottom),
      );
      if (shift.distance <= _tiny) break;
      current += shift;
    }

    return current;
  }

  /// How far to move [values] to put them within `[low, high]`; 0 when they
  /// cannot fit at all.
  static double _axisShift(List<double> values, double low, double high) {
    final least = values.reduce(math.min);
    final most = values.reduce(math.max);
    if (most - least > high - low + _tiny) return 0;
    if (least < low) return low - least;

    return most > high ? high - most : 0;
  }

  static List<Offset> _clampInto(List<Offset> points, Rect frame) {
    final xs = [for (final p in points) p.dx];
    final ys = [for (final p in points) p.dy];
    final fitsX = xs.reduce(math.max) - xs.reduce(math.min) <= frame.width;
    final fitsY = ys.reduce(math.max) - ys.reduce(math.min) <= frame.height;

    return [
      for (final point in points)
        Offset(
          fitsX ? point.dx.clamp(frame.left, frame.right) : point.dx,
          fitsY ? point.dy.clamp(frame.top, frame.bottom) : point.dy,
        ),
    ];
  }
}
