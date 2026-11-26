import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/objects/note_object_handle.dart';

/// Pure geometry of rotated objects.
///
/// Every point is in page coordinates (origin top-left, y down). A `rotation`
/// is in radians, clockwise on screen, about the center of the unrotated
/// `bounds`.
abstract final class NoteObjectGeometry {
  /// The smallest width or height, in page units, that resizing may produce.
  static const double minimumSize = 12;

  /// Slack so that a point exactly on an edge counts as inside despite
  /// floating-point rounding.
  static const double _tolerance = 1e-6;

  /// [vector] turned clockwise (on screen) by [radians].
  static Offset rotateVector(Offset vector, double radians) {
    final cosine = math.cos(radians);
    final sine = math.sin(radians);

    return Offset(
      vector.dx * cosine - vector.dy * sine,
      vector.dx * sine + vector.dy * cosine,
    );
  }

  /// [point] turned clockwise by [radians] about [center].
  static Offset rotateAround(Offset point, Offset center, double radians) =>
      center + rotateVector(point - center, radians);

  /// Whether [point] lies inside [bounds] turned by [rotation] about its
  /// center (edges included). A rect with a negative size is read as its
  /// mirrored, positive equivalent.
  static bool contains(Rect bounds, double rotation, Offset point) {
    // Undo the rotation, then test against the axis-aligned rectangle.
    final local = rotateVector(point - bounds.center, -rotation);

    return local.dx.abs() <= bounds.width.abs() / 2 + _tolerance &&
        local.dy.abs() <= bounds.height.abs() / 2 + _tolerance;
  }

  /// The four corners of [bounds] after [rotation], clockwise from the corner
  /// that is the top left before rotating.
  static List<Offset> corners(Rect bounds, double rotation) => [
    for (final corner in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomRight,
      bounds.bottomLeft,
    ])
      rotateAround(corner, bounds.center, rotation),
  ];

  /// The smallest axis-aligned rectangle that encloses [bounds] after
  /// [rotation].
  static Rect boundingBox(Rect bounds, double rotation) {
    final points = corners(bounds, rotation);
    var box = Rect.fromPoints(points.first, points.first);
    for (final point in points.skip(1)) {
      box = box.expandToInclude(Rect.fromPoints(point, point));
    }

    return box;
  }

  /// The same angle as [radians], wrapped into `(-π, π]`. A non-finite input
  /// stays non-finite.
  static double normalizeAngle(double radians) {
    const turn = 2 * math.pi;
    final wrapped = radians % turn;

    return wrapped > math.pi ? wrapped - turn : wrapped;
  }

  /// [rect] with a non-negative size of at least [minimum] on each axis.
  /// A side that is too short grows about the rect's center.
  static Rect normalizeRect(Rect rect, {double minimum = 0}) {
    final sorted = Rect.fromPoints(rect.topLeft, rect.bottomRight);
    if (sorted.width >= minimum && sorted.height >= minimum) return sorted;

    return Rect.fromCenter(
      center: sorted.center,
      width: math.max(sorted.width, minimum),
      height: math.max(sorted.height, minimum),
    );
  }

  /// Where the resize grip [handle] sits on [bounds] after [rotation].
  /// [NoteObjectHandle.rotate] has no place on the bounds and gives the center.
  static Offset handlePoint(
    Rect bounds,
    double rotation,
    NoteObjectHandle handle,
  ) =>
      bounds.center +
      rotateVector(
        Offset(
          handle.horizontal * bounds.width / 2,
          handle.vertical * bounds.height / 2,
        ),
        rotation,
      );

  /// The new unrotated bounds after dragging the grip [handle] of a rotated
  /// object to [pointer] (page coordinates).
  ///
  /// The side or corner opposite the grip stays where it is on the page, the
  /// rotation is unchanged, and neither dragged side can come closer than
  /// [minimum] to the opposite one. [NoteObjectHandle.rotate] returns
  /// [bounds].
  static Rect resize({
    required Rect bounds,
    required double rotation,
    required NoteObjectHandle handle,
    required Offset pointer,
    double minimum = minimumSize,
  }) {
    if (!handle.isResize) return bounds;
    // The pointer in the object's own frame, whose origin is the old center.
    final local = rotateVector(pointer - bounds.center, -rotation);
    final (left, right) = _resizeAxis(
      handle.horizontal,
      local.dx,
      bounds.width / 2,
      minimum,
    );
    final (top, bottom) = _resizeAxis(
      handle.vertical,
      local.dy,
      bounds.height / 2,
      minimum,
    );
    // The new center, moved back into page coordinates.
    final shift = rotateVector(
      Offset((left + right) / 2, (top + bottom) / 2),
      rotation,
    );

    return Rect.fromCenter(
      center: bounds.center + shift,
      width: right - left,
      height: bottom - top,
    );
  }

  /// The new `(low, high)` edges of one axis of half extent [half].
  static (double, double) _resizeAxis(
    int side,
    double pointer,
    double half,
    double minimum,
  ) => switch (side) {
    < 0 => (math.min(pointer, half - minimum), half),
    > 0 => (-half, math.max(pointer, -half + minimum)),
    _ => (-half, half),
  };
}
