import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Axis-aligned rectangle in logical pixels, relative to the frame (design)
/// or the captured boundary (implementation).
@immutable
final class GoldenRect {
  /// Creates a rectangle from its top-left corner and size.
  const GoldenRect(this.left, this.top, this.width, this.height);

  /// Rectangle spanning two corners.
  factory GoldenRect.fromLTRB(
    double left,
    double top,
    double right,
    double bottom,
  ) => GoldenRect(left, top, right - left, bottom - top);

  /// Parses `[x, y, width, height]`; returns `null` for anything else.
  static GoldenRect? tryParse(Object? json) {
    if (json is List<Object?> &&
        json.length == 4 &&
        json.every((value) => value is num && value.isFinite)) {
      final [x, y, w, h] = json.cast<num>();
      if (w < 0 || h < 0) return null;
      return GoldenRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
    }
    if (json is Map<String, Object?>) {
      final x = json['x'];
      final y = json['y'];
      final w = json['width'] ?? json['w'];
      final h = json['height'] ?? json['h'];
      if (x is num && y is num && w is num && h is num) {
        return tryParse([x, y, w, h]);
      }
    }
    return null;
  }

  /// Left edge.
  final double left;

  /// Top edge.
  final double top;

  /// Width, never negative.
  final double width;

  /// Height, never negative.
  final double height;

  /// Right edge.
  double get right => left + width;

  /// Bottom edge.
  double get bottom => top + height;

  /// Horizontal center.
  double get centerX => left + width / 2;

  /// Vertical center.
  double get centerY => top + height / 2;

  /// Area in logical px².
  double get area => width * height;

  /// Whether the rectangle has no area.
  bool get isEmpty => width <= 0 || height <= 0;

  /// Whether ([x], [y]) lies inside, edges included.
  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;

  /// Whether [other] lies completely inside, with [slack] logical pixels.
  bool containsRect(GoldenRect other, {double slack = 0}) =>
      other.left >= left - slack &&
      other.top >= top - slack &&
      other.right <= right + slack &&
      other.bottom <= bottom + slack;

  /// Overlapping part, or `null` when the rectangles do not overlap.
  GoldenRect? intersect(GoldenRect other) {
    final l = math.max(left, other.left);
    final t = math.max(top, other.top);
    final r = math.min(right, other.right);
    final b = math.min(bottom, other.bottom);
    return r > l && b > t ? GoldenRect.fromLTRB(l, t, r, b) : null;
  }

  /// Smallest rectangle containing both.
  GoldenRect union(GoldenRect other) => GoldenRect.fromLTRB(
    math.min(left, other.left),
    math.min(top, other.top),
    math.max(right, other.right),
    math.max(bottom, other.bottom),
  );

  /// Intersection over union in [0, 1].
  double iou(GoldenRect other) {
    final overlap = intersect(other)?.area ?? 0;
    final total = area + other.area - overlap;
    return total <= 0 ? 0 : overlap / total;
  }

  /// Fraction of this rectangle covered by [other].
  double coveredBy(GoldenRect other) {
    if (area <= 0) return 0;
    return (intersect(other)?.area ?? 0) / area;
  }

  /// Distance between the two centers.
  double centerDistance(GoldenRect other) {
    final dx = centerX - other.centerX;
    final dy = centerY - other.centerY;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Moved by ([dx], [dy]).
  GoldenRect shift(double dx, double dy) =>
      GoldenRect(left + dx, top + dy, width, height);

  /// Grown by [dx] horizontally and [dy] vertically on every side.
  GoldenRect inflate(double dx, double dy) =>
      GoldenRect(left - dx, top - dy, width + 2 * dx, height + 2 * dy);

  /// `[x, y, width, height]` rounded to hundredths.
  List<double> toJson() => [
    goldenRound(left),
    goldenRound(top),
    goldenRound(width),
    goldenRound(height),
  ];

  @override
  bool operator ==(Object other) =>
      other is GoldenRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'GoldenRect(${goldenRound(left)}, ${goldenRound(top)}, '
      '${goldenRound(width)}×${goldenRound(height)})';
}

/// [value] rounded to [digits] decimals, without `-0.0`.
double goldenRound(double value, [int digits = 2]) {
  if (!value.isFinite) return value;
  final factor = math.pow(10, digits);
  final rounded = (value * factor).round() / factor;
  return rounded == 0 ? 0 : rounded;
}
