import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// The part of an image that is shown, in **image fractions**: `(0, 0)` is the
/// top-left corner of the image and `(1, 1)` the bottom-right one.
///
/// Either a [NoteImageRectCrop] or a freeform [NoteImagePolygonCrop]; [none]
/// shows the whole image. JSON: `{}` ([none]), `{rect: [l, t, r, b]}` or
/// `{polygon: [x0, y0, x1, y1, …]}`. Invalid input reads as [none].
@immutable
sealed class NoteImageCrop {
  /// The whole image.
  static const NoteImageCrop none = NoteImageRectCrop._(
    Rect.fromLTWH(0, 0, 1, 1),
  );

  /// Smallest width and height of a crop, in image fractions.
  static const double minExtent = 0.01;

  const NoteImageCrop._();

  /// A rectangular crop from the left, top, right and bottom edges as image
  /// fractions. Edges are put in order and clamped to 0 – 1; a crop thinner
  /// than [minExtent] or with a non-finite edge becomes [none].
  factory NoteImageCrop.rect(
    double left,
    double top,
    double right,
    double bottom,
  ) {
    if (![left, top, right, bottom].every((edge) => edge.isFinite)) {
      return none;
    }
    final fraction = Rect.fromLTRB(
      math.min(left, right).clamp(0.0, 1.0),
      math.min(top, bottom).clamp(0.0, 1.0),
      math.max(left, right).clamp(0.0, 1.0),
      math.max(top, bottom).clamp(0.0, 1.0),
    );
    if (fraction.width < minExtent || fraction.height < minExtent) return none;

    return NoteImageRectCrop._(fraction);
  }

  /// A freeform crop through [points] (image fractions, clamped to 0 – 1). The
  /// path is closed; non-finite and repeated points are dropped. Fewer than
  /// three points, or an outline without area, become [none].
  factory NoteImageCrop.polygon(List<Offset> points) {
    final clean = <Offset>[];
    for (final point in points) {
      if (!point.isFinite) continue;
      final inside = Offset(point.dx.clamp(0.0, 1.0), point.dy.clamp(0.0, 1.0));
      if (clean.isEmpty || clean.last != inside) clean.add(inside);
    }
    if (clean.length > 1 && clean.first == clean.last) clean.removeLast();
    if (clean.length < 3) return none;
    final bounds = _boundsOf(clean);
    if (bounds.width < minExtent || bounds.height < minExtent) return none;
    if (_isStraight(clean)) return none;

    return NoteImagePolygonCrop._(List.unmodifiable(clean));
  }

  /// Reads [toJson]; never throws.
  factory NoteImageCrop.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return none;
    final rect = _numbers(json['rect']);
    if (rect != null && rect.length == 4) {
      return NoteImageCrop.rect(rect[0], rect[1], rect[2], rect[3]);
    }
    final polygon = _numbers(json['polygon']);
    if (polygon == null || polygon.length.isOdd) return none;

    return NoteImageCrop.polygon([
      for (var i = 0; i < polygon.length; i += 2)
        Offset(polygon[i], polygon[i + 1]),
    ]);
  }

  static List<double>? _numbers(Object? value) {
    if (value is! List) return null;
    final numbers = [for (final entry in value) entry is num ? entry : null];
    if (numbers.contains(null)) return null;

    return [for (final entry in numbers) entry!.toDouble()];
  }

  static Rect _boundsOf(List<Offset> points) {
    var left = points.first.dx;
    var right = points.first.dx;
    var top = points.first.dy;
    var bottom = points.first.dy;
    for (final point in points) {
      left = math.min(left, point.dx);
      right = math.max(right, point.dx);
      top = math.min(top, point.dy);
      bottom = math.max(bottom, point.dy);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Whether every point is (nearly) on one line, so nothing is enclosed. A
  /// signed area would not do: it cancels out for a self-crossing lasso.
  static bool _isStraight(List<Offset> points) {
    final origin = points.first;
    var far = origin;
    for (final point in points) {
      if ((point - origin).distanceSquared > (far - origin).distanceSquared) {
        far = point;
      }
    }
    final axis = far - origin;
    if (axis.distance <= 0) return true;

    return points.every((point) {
      final offset = point - origin;
      final cross = axis.dx * offset.dy - axis.dy * offset.dx;

      return cross.abs() / axis.distance < minExtent / 2;
    });
  }

  /// The bounding box of the visible part, in image fractions.
  Rect get bounds;

  /// Whether the whole image is shown.
  bool get isNone => this == none;

  /// The pixels of an image of [imageSize] covered by [bounds].
  Rect sourceRect(Size imageSize) => Rect.fromLTRB(
    bounds.left * imageSize.width,
    bounds.top * imageSize.height,
    bounds.right * imageSize.width,
    bounds.bottom * imageSize.height,
  );

  /// The visible outline when [bounds] is drawn into [dest].
  Path outlineIn(Rect dest);

  /// The JSON map form (see the class documentation).
  JsonMap toJson();
}

/// A rectangular crop.
final class NoteImageRectCrop extends NoteImageCrop {
  const NoteImageRectCrop._(this.bounds) : super._();

  @override
  final Rect bounds;

  @override
  Path outlineIn(Rect dest) => Path()..addRect(dest);

  @override
  JsonMap toJson() => isNone
      ? <String, Object?>{}
      : {
          'rect': [bounds.left, bounds.top, bounds.right, bounds.bottom],
        };

  @override
  bool operator ==(Object other) =>
      other is NoteImageRectCrop && other.bounds == bounds;

  @override
  int get hashCode => bounds.hashCode;

  @override
  String toString() => 'NoteImageRectCrop($bounds)';
}

/// A freeform (lasso) crop.
final class NoteImagePolygonCrop extends NoteImageCrop {
  const NoteImagePolygonCrop._(this.points) : super._();

  /// The closed outline in image fractions, at least three points.
  final List<Offset> points;

  @override
  Rect get bounds => NoteImageCrop._boundsOf(points);

  @override
  Path outlineIn(Rect dest) {
    final box = bounds;
    Offset place(Offset point) => Offset(
      dest.left + (point.dx - box.left) / box.width * dest.width,
      dest.top + (point.dy - box.top) / box.height * dest.height,
    );

    return Path()..addPolygon([for (final p in points) place(p)], true);
  }

  @override
  JsonMap toJson() => {
    'polygon': [
      for (final point in points) ...[point.dx, point.dy],
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is NoteImagePolygonCrop && listEquals(other.points, points);

  @override
  int get hashCode => Object.hashAll(points);

  @override
  String toString() => 'NoteImagePolygonCrop(${points.length} points)';
}
