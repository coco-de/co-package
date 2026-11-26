import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_contour_builder.dart';
import 'package:open_note/src/note/style/note_shape_drawing.dart';

/// The 2-D closed shapes. [Rect] arguments are normalised. Internal: not
/// exported by the module barrel.
abstract final class NoteShapeFlatGeometry {
  static const double _defaultRoundFraction = 0.15;
  static const double _starInnerRadius = 0.382;

  /// A rectangle, with circular corners when [cornerRadius] is positive.
  static NoteShapeDrawing rectangle(Rect box, double cornerRadius) {
    final radius = _usableRadius(cornerRadius, box);
    if (radius <= 0) return polygon(_corners(box), 0);

    return _roundedBox(box, radius);
  }

  /// A rectangle that is rounded even without a [cornerRadius] (15 % of the
  /// shorter side).
  static NoteShapeDrawing roundedRectangle(Rect box, double cornerRadius) =>
      rectangle(
        box,
        cornerRadius > 0
            ? cornerRadius
            : box.shortestSide * _defaultRoundFraction,
      );

  /// The ellipse inscribed in [box].
  static NoteShapeDrawing ellipse(Rect box) =>
      _outline(NoteContourBuilder()..oval(box));

  /// A closed polygon whose corners are cut [cornerRadius] away from each
  /// vertex and rounded with a quadratic curve.
  static NoteShapeDrawing polygon(List<Offset> vertices, double cornerRadius) {
    if (!(cornerRadius > 0) || !cornerRadius.isFinite) {
      return _outline(NoteContourBuilder()..polygon(vertices));
    }
    final builder = NoteContourBuilder();
    final count = vertices.length;
    for (var i = 0; i < count; i++) {
      final vertex = vertices[i];
      final previous = vertices[(i - 1 + count) % count];
      final next = vertices[(i + 1) % count];
      final cut = math.min(
        cornerRadius,
        math.min((previous - vertex).distance, (next - vertex).distance) / 2,
      );
      builder
        ..lineTo(vertex + _towards(vertex, previous) * cut)
        ..quadraticTo(vertex, vertex + _towards(vertex, next) * cut);
    }

    return _outline(builder..close());
  }

  /// Apex at the top centre, base along the bottom edge.
  static List<Offset> triangle(Rect box) => [
    box.topCenter,
    box.bottomRight,
    box.bottomLeft,
  ];

  /// Right angle at the bottom-left corner.
  static List<Offset> rightTriangle(Rect box) => [
    box.topLeft,
    box.bottomRight,
    box.bottomLeft,
  ];

  /// Vertices at the middle of each edge.
  static List<Offset> diamond(Rect box) => [
    box.topCenter,
    box.centerRight,
    box.bottomCenter,
    box.centerLeft,
  ];

  /// A regular pentagon (apex up) stretched to fill [box].
  static List<Offset> pentagon(Rect box) => _fitToBox([
    for (var i = 0; i < 5; i++) _unit(-math.pi / 2 + 2 * math.pi * i / 5),
  ], box);

  /// A regular hexagon (flat top and bottom) stretched to fill [box].
  static List<Offset> hexagon(Rect box) =>
      _fitToBox([for (var i = 0; i < 6; i++) _unit(math.pi * i / 3)], box);

  /// A five-pointed star (one point up) stretched to fill [box].
  static List<Offset> star(Rect box) => _fitToBox([
    for (var i = 0; i < 10; i++)
      _unit(-math.pi / 2 + math.pi * i / 5) * (i.isEven ? 1 : _starInnerRadius),
  ], box);

  static List<Offset> _corners(Rect box) => [
    box.topLeft,
    box.topRight,
    box.bottomRight,
    box.bottomLeft,
  ];

  static NoteShapeDrawing _outline(NoteContourBuilder builder) =>
      NoteShapeDrawing(outline: builder.build());

  static double _usableRadius(double radius, Rect box) =>
      radius.isFinite && radius > 0
      ? math.min(radius, box.shortestSide / 2)
      : 0;

  static NoteShapeDrawing _roundedBox(Rect box, double radius) {
    final size = Size.square(radius * 2);
    Rect corner(double left, double top) => Offset(left, top) & size;
    final right = box.right - radius * 2;
    final bottom = box.bottom - radius * 2;
    const quarter = math.pi / 2;
    final builder = NoteContourBuilder()
      ..moveTo(Offset(box.left + radius, box.top))
      ..lineTo(Offset(box.right - radius, box.top))
      ..arc(corner(right, box.top), -quarter, quarter)
      ..lineTo(Offset(box.right, box.bottom - radius))
      ..arc(corner(right, bottom), 0, quarter)
      ..lineTo(Offset(box.left + radius, box.bottom))
      ..arc(corner(box.left, bottom), quarter, quarter)
      ..lineTo(Offset(box.left, box.top + radius))
      ..arc(corner(box.left, box.top), 2 * quarter, quarter)
      ..close();

    return _outline(builder);
  }

  static Offset _unit(double angle) => Offset(math.cos(angle), math.sin(angle));

  static Offset _towards(Offset from, Offset to) {
    final delta = to - from;
    final distance = delta.distance;

    return distance > 0 ? delta / distance : Offset.zero;
  }

  static List<Offset> _fitToBox(List<Offset> points, Rect box) {
    var bounds = Rect.fromPoints(points.first, points.first);
    for (final point in points) {
      bounds = Rect.fromLTRB(
        math.min(bounds.left, point.dx),
        math.min(bounds.top, point.dy),
        math.max(bounds.right, point.dx),
        math.max(bounds.bottom, point.dy),
      );
    }

    return [
      for (final point in points)
        Offset(
          box.left + (point.dx - bounds.left) / bounds.width * box.width,
          box.top + (point.dy - bounds.top) / bounds.height * box.height,
        ),
    ];
  }
}
