import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_object_handle.dart';

/// One drag of the object layer in edit mode: moving the selection, or
/// resizing or rotating one object. Positions are page coordinates, and every
/// update is computed from where the drag began, so nothing accumulates.
///
/// The caller wraps it in `beginGesture` / `endGesture` on [controller].
sealed class NoteObjectDrag {
  /// The objects being changed.
  final NoteObjectController controller;

  const NoteObjectDrag(this.controller);

  /// The pointer is now at [position].
  void update(Offset position);
}

/// Moves objects. The middle of the moving group cannot be dragged off the
/// page (an object that already is off the page is not pulled back).
class NoteObjectMoveDrag extends NoteObjectDrag {
  /// The objects moving.
  final Set<String> ids;

  /// Where the pointer went down.
  final Offset origin;

  /// The middle of the moving group when the drag began.
  final Offset center;

  /// The page.
  final Size pageSize;

  Offset _moved = Offset.zero;

  NoteObjectMoveDrag(
    super.controller, {
    required this.ids,
    required this.origin,
    required this.center,
    required this.pageSize,
  });

  /// Starts moving the unlocked objects of the current selection, or `null`
  /// when none of them can move.
  static NoteObjectMoveDrag? ofSelection(
    NoteObjectController controller, {
    required Offset origin,
    required Size pageSize,
  }) {
    Rect? box;
    final ids = <String>{};
    for (final object in controller.selection) {
      if (object.locked) continue;
      ids.add(object.id);
      final rotated = NoteObjectGeometry.boundingBox(
        object.bounds,
        object.rotation,
      );
      box = box?.expandToInclude(rotated) ?? rotated;
    }

    return box == null
        ? null
        : NoteObjectMoveDrag(
            controller,
            ids: ids,
            origin: origin,
            center: box.center,
            pageSize: pageSize,
          );
  }

  @override
  void update(Offset position) {
    final wanted = position - origin;
    final allowed = Offset(
      wanted.dx.clamp(
        math.min(0, -center.dx),
        math.max(0, pageSize.width - center.dx),
      ),
      wanted.dy.clamp(
        math.min(0, -center.dy),
        math.max(0, pageSize.height - center.dy),
      ),
    );
    controller.moveBy(ids, allowed - _moved);
    _moved = allowed;
  }
}

/// Resizes one object by a grip, keeping the opposite side in place.
class NoteObjectResizeDrag extends NoteObjectDrag {
  /// The object as it was when the drag began.
  final NoteObject original;

  /// The grip being dragged.
  final NoteObjectHandle handle;

  /// From the pointer to the grip, so the object does not jump to the pointer
  /// when the grip was touched off-center.
  final Offset _grab;

  NoteObjectResizeDrag(
    super.controller, {
    required this.original,
    required this.handle,
    required Offset origin,
  }) : _grab =
           NoteObjectGeometry.handlePoint(
             original.bounds,
             original.rotation,
             handle,
           ) -
           origin;

  @override
  void update(Offset position) => controller.resize(
    original.id,
    NoteObjectGeometry.resize(
      bounds: original.bounds,
      rotation: original.rotation,
      handle: handle,
      pointer: position + _grab,
    ),
  );
}

/// Rotates one object about its center by the angle the pointer sweeps.
class NoteObjectRotateDrag extends NoteObjectDrag {
  /// The object as it was when the drag began.
  final NoteObject original;

  final double _startAngle;

  NoteObjectRotateDrag(
    super.controller, {
    required this.original,
    required Offset origin,
  }) : _startAngle = (origin - original.bounds.center).direction;

  @override
  void update(Offset position) {
    final arm = position - original.bounds.center;
    // Over the center the direction is meaningless.
    if (arm.distance < 0.5) return;
    controller.rotate(
      original.id,
      original.rotation + arm.direction - _startAngle,
    );
  }
}
