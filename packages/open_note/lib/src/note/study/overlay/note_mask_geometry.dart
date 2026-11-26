import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';

/// The covered area of a mask or tape inside a rectangle. The widgets,
/// `paintToCanvas` and hit testing all go through this, so what is painted,
/// exported and tapped always agree.
///
/// Stroke and tape coordinates are *fractions of the centre-line box*: the
/// rectangle shrunk by half the thickness on every side ([centerLineBox]). A
/// shape built from fractions in that box never leaves the rectangle.
@immutable
sealed class NoteMaskGeometry {
  const NoteMaskGeometry();

  /// [area] shrunk by half of [thickness] on every side, collapsing to the
  /// centre line (never inverting) when [area] is thinner than [thickness].
  static Rect centerLineBox(Rect area, double thickness) {
    final dx = math.min(thickness / 2, area.width / 2);
    final dy = math.min(thickness / 2, area.height / 2);

    return Rect.fromLTRB(
      area.left + dx,
      area.top + dy,
      area.right - dx,
      area.bottom - dy,
    );
  }

  /// The point at [fraction] (0–1 per axis) of [box].
  static Offset fromFraction(Offset fraction, Rect box) => Offset(
    box.left + fraction.dx * box.width,
    box.top + fraction.dy * box.height,
  );

  /// The inverse of [fromFraction], clamped to 0–1. An axis of (almost) zero
  /// length gives 0.5.
  static Offset toFraction(Offset point, Rect box) => Offset(
    _axisFraction(point.dx - box.left, box.width),
    _axisFraction(point.dy - box.top, box.height),
  );

  /// Each axis of [fraction] clamped to 0–1 (a non-finite axis becomes 0.5).
  static Offset clampFraction(Offset fraction) =>
      Offset(_clampUnit(fraction.dx), _clampUnit(fraction.dy));

  /// Reads a `{x, y}` fraction, clamped to 0–1; `null` when [value] is not a
  /// pair of finite numbers.
  static Offset? fractionFromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final x = json['x'];
    final y = json['y'];
    if (x is! num || y is! num || !x.isFinite || !y.isFinite) return null;

    return clampFraction(Offset(x.toDouble(), y.toDouble()));
  }

  /// The smallest rectangle containing every point; [Rect.zero] when empty.
  static Rect boundsOf(Iterable<Offset> points) {
    var box = Rect.zero;
    var first = true;
    for (final point in points) {
      final here = Rect.fromLTWH(point.dx, point.dy, 0, 0);
      box = first
          ? here
          : Rect.fromLTRB(
              math.min(box.left, here.left),
              math.min(box.top, here.top),
              math.max(box.right, here.right),
              math.max(box.bottom, here.bottom),
            );
      first = false;
    }

    return box;
  }

  static double _axisFraction(double distance, double length) =>
      length > 1e-6 ? _clampUnit(distance / length) : 0.5;

  static double _clampUnit(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0) : 0.5;

  /// A rectangle containing everything [fill] paints.
  Rect get coverage;

  /// Whether [point] lies on the shape, widened by [slop] on every side.
  bool contains(Offset point, {double slop = 0});

  /// Paints the whole shape in [color].
  void fill(Canvas canvas, Color color);

  /// Paints only a [width] wide outline of the shape in [color].
  void outline(Canvas canvas, Color color, double width);
}

/// A rectangle with slightly rounded corners.
final class NoteMaskRectGeometry extends NoteMaskGeometry {
  /// Covers [rect].
  const NoteMaskRectGeometry(this.rect, {this.cornerRadius = 0});

  /// The covered rectangle.
  final Rect rect;

  /// Radius of the corners.
  final double cornerRadius;

  RRect get _rounded =>
      RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

  @override
  Rect get coverage => rect;

  @override
  bool contains(Offset point, {double slop = 0}) =>
      _rounded.inflate(slop).contains(point);

  @override
  void fill(Canvas canvas, Color color) =>
      canvas.drawRRect(_rounded, Paint()..color = color);

  @override
  void outline(Canvas canvas, Color color, double width) => canvas.drawRRect(
    _rounded.deflate(width / 2),
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteMaskRectGeometry &&
      other.rect == rect &&
      other.cornerRadius == cornerRadius;

  @override
  int get hashCode => Object.hash(rect, cornerRadius);
}

/// A straight strip with flat ends: a straight tape.
final class NoteMaskQuadGeometry extends NoteMaskGeometry {
  /// Covers the [corners] in order.
  const NoteMaskQuadGeometry(this.corners);

  /// The strip of [width] along the line from [start] to [end]. A line of zero
  /// length becomes a square of side [width] centred on [start].
  factory NoteMaskQuadGeometry.strip(Offset start, Offset end, double width) {
    final line = end - start;
    final length = line.distance;
    final unit = length > 1e-6 ? line / length : const Offset(1, 0);
    final reach = length > 1e-6 ? Offset.zero : unit * (width / 2);
    final from = start - reach;
    final to = end + reach;
    final side = Offset(-unit.dy, unit.dx) * (width / 2);

    return NoteMaskQuadGeometry([
      from + side,
      to + side,
      to - side,
      from - side,
    ]);
  }

  /// The four corners, in drawing order.
  final List<Offset> corners;

  Path get _path => Path()..addPolygon(corners, true);

  @override
  Rect get coverage => NoteMaskGeometry.boundsOf(corners);

  @override
  bool contains(Offset point, {double slop = 0}) {
    if (_path.contains(point)) return true;
    for (var i = 0; i < corners.length; i++) {
      final next = corners[(i + 1) % corners.length];
      if (_distanceToSegment(point, corners[i], next) <= slop) return true;
    }

    return false;
  }

  @override
  void fill(Canvas canvas, Color color) =>
      canvas.drawPath(_path, Paint()..color = color);

  @override
  void outline(Canvas canvas, Color color, double width) => canvas.drawPath(
    _path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteMaskQuadGeometry && listEquals(other.corners, corners);

  @override
  int get hashCode => Object.hashAll(corners);
}

/// A thick polyline with round caps and joins: a stroke mask.
final class NoteMaskStrokeGeometry extends NoteMaskGeometry {
  /// A line of [width] through [points] (one point makes a dot).
  const NoteMaskStrokeGeometry(this.points, this.width);

  /// The centre line.
  final List<Offset> points;

  /// Thickness of the stroke.
  final double width;

  bool get _isDot => points.every((point) => point == points.first);

  @override
  Rect get coverage => NoteMaskGeometry.boundsOf(points).inflate(width / 2);

  @override
  bool contains(Offset point, {double slop = 0}) {
    if (points.isEmpty) return false;
    final reach = width / 2 + slop;
    if (points.length == 1) return (point - points.first).distance <= reach;
    for (var i = 1; i < points.length; i++) {
      if (_distanceToSegment(point, points[i - 1], points[i]) <= reach) {
        return true;
      }
    }

    return false;
  }

  @override
  void fill(Canvas canvas, Color color) =>
      _draw(canvas, width, Paint()..color = color);

  @override
  void outline(Canvas canvas, Color color, double width) {
    canvas.saveLayer(coverage.inflate(width), Paint());
    _draw(canvas, this.width, Paint()..color = color);
    // Erasing a thinner copy leaves just the rim.
    _draw(
      canvas,
      math.max(this.width - width * 2, 0),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool operator ==(Object other) =>
      other is NoteMaskStrokeGeometry &&
      other.width == width &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(width, Object.hashAll(points));

  void _draw(Canvas canvas, double thickness, Paint paint) {
    if (points.isEmpty || thickness <= 0) return;
    if (_isDot) {
      canvas.drawCircle(points.first, thickness / 2, paint);

      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
}

double _distanceToSegment(Offset point, Offset from, Offset to) {
  final segment = to - from;
  final lengthSquared = segment.distanceSquared;
  if (lengthSquared == 0) return (point - from).distance;
  final along =
      ((point - from).dx * segment.dx + (point - from).dy * segment.dy) /
      lengthSquared;

  return (point - (from + segment * along.clamp(0.0, 1.0))).distance;
}
