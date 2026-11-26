import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_object_handle.dart';

/// The selection frame of one object: where its grips are and which grip a
/// point touches. All coordinates are page coordinates.
@immutable
class NoteObjectFrame {
  /// The smallest radius, in page units, in which a grip can be touched.
  static const double minimumHitRadius = 16;

  /// Where the rotation grip may sit, relative to the sides of the object, best
  /// first: above, below, right, left.
  static const List<Offset> _sides = [
    Offset(0, -1),
    Offset(0, 1),
    Offset(1, 0),
    Offset(-1, 0),
  ];

  /// The object framed.
  final String objectId;

  /// Its unrotated bounds.
  final Rect bounds;

  /// Its rotation.
  final double rotation;

  /// Diameter of a drawn grip.
  final double handleSize;

  /// The page, which the rotation grip should stay inside.
  final Size pageSize;

  const NoteObjectFrame({
    required this.objectId,
    required this.bounds,
    required this.rotation,
    required this.handleSize,
    required this.pageSize,
  });

  /// How close a pointer must be to a grip.
  double get hitRadius => math.max(handleSize, minimumHitRadius);

  /// The distance from the object's side to the rotation grip.
  double get rotationDistance => hitRadius * 2;

  /// The four corners of the rotated object.
  List<Offset> get corners => NoteObjectGeometry.corners(bounds, rotation);

  /// Where the line to the rotation grip starts: the middle of a side.
  Offset get rotationAnchor => _rotationPlacement.anchor;

  /// The rotation grip sits above the object, or else below, right or left of
  /// it, whichever keeps it on the page; if none does, above, pushed onto it.
  ({Offset anchor, Offset grip}) get _rotationPlacement {
    final page = (Offset.zero & pageSize).deflate(handleSize / 2);
    ({Offset anchor, Offset grip}) at(Offset side) {
      final local = Offset(
        side.dx * bounds.width / 2,
        side.dy * bounds.height / 2,
      );
      Offset onPage(Offset point) =>
          bounds.center + NoteObjectGeometry.rotateVector(point, rotation);

      return (
        anchor: onPage(local),
        grip: onPage(local + side * rotationDistance),
      );
    }

    for (final side in _sides) {
      final placement = at(side);
      if (page.contains(placement.grip)) return placement;
    }
    final fallback = at(_sides.first);

    return (
      anchor: fallback.anchor,
      grip: Offset(
        fallback.grip.dx.clamp(0.0, pageSize.width),
        fallback.grip.dy.clamp(0.0, pageSize.height),
      ),
    );
  }

  /// The frame for the layer's current selection: exactly one object, not
  /// locked. Otherwise `null` (a multi-selection can only be moved).
  static NoteObjectFrame? forSelection(
    NoteObjectController controller, {
    required double handleSize,
    required Size pageSize,
  }) {
    if (controller.selectedIds.length != 1) return null;
    final NoteObject? object = controller.find(controller.selectedIds.first);
    if (object == null || object.locked) return null;

    return NoteObjectFrame(
      objectId: object.id,
      bounds: object.bounds,
      rotation: object.rotation,
      handleSize: handleSize,
      pageSize: pageSize,
    );
  }

  /// Where [handle] is drawn.
  Offset positionOf(NoteObjectHandle handle) =>
      handle == NoteObjectHandle.rotate
      ? _rotationPlacement.grip
      : NoteObjectGeometry.handlePoint(bounds, rotation, handle);

  /// The grip touched at [point], the nearest one when several are in reach.
  ///
  /// Inside the object the reach shrinks to a quarter of its shorter side, so
  /// the middle of even a tiny object can still be dragged.
  NoteObjectHandle? handleAt(Offset point) {
    final inside = NoteObjectGeometry.contains(bounds, rotation, point);
    var reach = inside
        ? math.min(hitRadius, bounds.shortestSide / 4)
        : hitRadius;
    NoteObjectHandle? nearest;
    for (final handle in NoteObjectHandle.values) {
      final distance = (positionOf(handle) - point).distance;
      if (distance <= reach) {
        nearest = handle;
        reach = distance;
      }
    }

    return nearest;
  }
}
