import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_contour_builder.dart';
import 'package:open_note/src/note/style/note_shape_drawing.dart';

/// The isometric 3-D wire frames, viewed from above and in front. [Rect]
/// arguments are normalised. Internal: not exported by the module barrel.
abstract final class NoteShapeSolidGeometry {
  /// Height over width of a circle seen isometrically (`1 / √3`).
  static const double _isometricRatio = 0.5773502691896258;
  static const double _equatorRatio = 0.3;

  /// A cube: a hexagonal silhouette, three visible and three hidden edges.
  static NoteShapeDrawing cube(Rect box) {
    final quarter = box.height / 4;
    final upperLeft = Offset(box.left, box.top + quarter);
    final upperRight = Offset(box.right, box.top + quarter);
    final lowerLeft = Offset(box.left, box.bottom - quarter);
    final lowerRight = Offset(box.right, box.bottom - quarter);

    return _drawing(
      outline: NoteContourBuilder()
        ..polygon([
          box.topCenter,
          upperRight,
          lowerRight,
          box.bottomCenter,
          lowerLeft,
          upperLeft,
        ]),
      inner: NoteContourBuilder()
        ..polyline([upperLeft, box.center, upperRight])
        ..polyline([box.center, box.bottomCenter]),
      hidden: NoteContourBuilder()
        ..polyline([box.topCenter, box.center])
        ..polyline([lowerLeft, box.center, lowerRight]),
    );
  }

  /// A square pyramid with its apex at the top centre.
  static NoteShapeDrawing pyramid(Rect box) {
    final base = math.min(box.width * _isometricRatio, box.height / 2);
    final apex = box.topCenter;
    final left = Offset(box.left, box.bottom - base / 2);
    final right = Offset(box.right, box.bottom - base / 2);
    final back = Offset(box.center.dx, box.bottom - base);

    return _drawing(
      outline: NoteContourBuilder()
        ..polygon([apex, right, box.bottomCenter, left]),
      inner: NoteContourBuilder()..polyline([apex, box.bottomCenter]),
      hidden: NoteContourBuilder()
        ..polyline([apex, back])
        ..polyline([left, back, right]),
    );
  }

  /// An upright cylinder: the front rim of the top is visible, the back half
  /// of the base hidden.
  static NoteShapeDrawing cylinder(Rect box) {
    final height = _ellipseHeight(box);
    final top = Rect.fromLTRB(box.left, box.top, box.right, box.top + height);
    final bottom = Rect.fromLTRB(
      box.left,
      box.bottom - height,
      box.right,
      box.bottom,
    );

    return _drawing(
      outline: NoteContourBuilder()
        ..moveTo(top.centerLeft)
        ..lineTo(bottom.centerLeft)
        ..arc(bottom, math.pi, -math.pi)
        ..lineTo(top.centerRight)
        ..arc(top, 0, -math.pi)
        ..close(),
      inner: NoteContourBuilder()..arc(top, math.pi, -math.pi),
      hidden: NoteContourBuilder()..arc(bottom, math.pi, math.pi),
    );
  }

  /// A cone with its apex at the top centre; the sides are tangent to the base.
  static NoteShapeDrawing cone(Rect box) {
    final height = _ellipseHeight(box);
    final base = Rect.fromLTRB(
      box.left,
      box.bottom - height,
      box.right,
      box.bottom,
    );
    final reach = base.center.dy - box.top;
    final tangent = reach > 0
        ? math.asin((height / 2 / reach).clamp(0.0, 1.0))
        : 0.0;

    return _drawing(
      outline: NoteContourBuilder()
        ..moveTo(box.topCenter)
        ..arc(base, -tangent, math.pi + 2 * tangent)
        ..close(),
      hidden: NoteContourBuilder()
        ..arc(base, math.pi + tangent, math.pi - 2 * tangent),
    );
  }

  /// A sphere with its equator: the front half visible, the back half hidden.
  static NoteShapeDrawing sphere(Rect box) {
    final height = box.height * _equatorRatio;
    final equator = Rect.fromCenter(
      center: box.center,
      width: box.width,
      height: height,
    );

    return _drawing(
      outline: NoteContourBuilder()..oval(box),
      inner: NoteContourBuilder()..arc(equator, math.pi, -math.pi),
      hidden: NoteContourBuilder()..arc(equator, math.pi, math.pi),
    );
  }

  static double _ellipseHeight(Rect box) =>
      math.min(box.width * _isometricRatio, box.height / 3);

  static NoteShapeDrawing _drawing({
    required NoteContourBuilder outline,
    required NoteContourBuilder hidden,
    NoteContourBuilder? inner,
  }) => NoteShapeDrawing(
    outline: outline.build(),
    inner: inner?.build(),
    hidden: hidden.build(),
  );
}
