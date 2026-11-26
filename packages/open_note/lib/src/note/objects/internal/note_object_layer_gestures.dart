import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/objects/internal/note_object_drag.dart';
import 'package:open_note/src/note/objects/internal/note_object_frame.dart';
import 'package:open_note/src/note/objects/internal/note_object_gesture_recognizer.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_handle.dart';
import 'package:open_note/src/note/objects/note_object_layer.dart';

/// What the tracked pointer went down on: an object, or a grip of its frame.
typedef _Target = ({String id, NoteObjectHandle? handle});

/// Turns the pointer events of a [NoteObjectLayer] in edit mode into
/// selection, double-tap editing, drags and deselection. Positions are local
/// to the layer, which are page coordinates.
class NoteObjectLayerGestures {
  /// Recognizes taps and drags on objects and grips.
  final NoteObjectGestureRecognizer recognizer = NoteObjectGestureRecognizer(
    debugOwner: 'NoteObjectLayer',
  );

  /// The layer widget as currently configured.
  final NoteObjectLayer Function() _layer;

  final Set<int> _claimed = {};

  _Target? _target;

  /// Whether the tracked press came soon enough after a tap on the same
  /// object to make a double tap.
  bool _isSecondPress = false;

  NoteObjectDrag? _drag;
  String? _lastTapId;
  Timer? _doubleTapTimer;
  int? _emptyPointer;
  Offset _emptyOrigin = Offset.zero;
  NoteObjectLayerGestures(this._layer) {
    recognizer
      ..canDrag = _canDrag
      ..onTap = _tap
      ..onDragStart = _dragStart
      ..onDragUpdate = _dragUpdate
      ..onDragEnd = _dragEnd
      ..onDragCancel = _dragCancel;
  }

  bool get _editMode => _layer().mode == NoteObjectLayerMode.edit;

  NoteObjectController get _controller => _layer().controller;

  /// A widget being edited took [pointer], so the layer leaves it alone.
  void claim(int pointer) => _claimed.add(pointer);

  /// Whether a grip or an object is at [position].
  bool isTarget(Offset position) => _targetAt(position) != null;

  /// A pointer went down anywhere in the layer.
  void pointerDown(PointerDownEvent event) {
    final claimed = _claimed.remove(event.pointer);
    // A second finger means this was not a plain tap on empty space.
    final secondFinger = _emptyPointer != null;
    _emptyPointer = null;
    if (!_editMode || claimed) return;
    final target = _targetAt(event.localPosition);
    if (target != null) {
      _track(event, target);
    } else if (!secondFinger &&
        !recognizer.isTracking &&
        event.buttons == kPrimaryButton) {
      _emptyPointer = event.pointer;
      _emptyOrigin = event.position;
    }
  }

  /// A pointer moved.
  void pointerMove(PointerMoveEvent event) {
    if (event.pointer != _emptyPointer) return;
    final travel = (event.position - _emptyOrigin).distance;
    if (travel > computeHitSlop(event.kind, recognizer.gestureSettings)) {
      _emptyPointer = null;
    }
  }

  /// A pointer was lifted. A tap on empty space clears the selection.
  void pointerUp(PointerUpEvent event) {
    if (event.pointer != _emptyPointer) return;
    _emptyPointer = null;
    if (!_editMode) return;
    _forgetTap();
    _controller.clearSelection();
  }

  /// A pointer was cancelled.
  void pointerCancel(PointerCancelEvent event) {
    if (event.pointer == _emptyPointer) _emptyPointer = null;
  }

  /// Drops whatever is in progress, keeping what an unfinished drag already
  /// did as one undo step. Safe to call while the tree is being built.
  void interrupt() {
    recognizer.abandon();
    _forgetTap();
    _target = null;
    _emptyPointer = null;
    _claimed.clear();
    final drag = _drag;
    _drag = null;
    if (drag != null) {
      // Ending the gesture notifies the history, so not during the build.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => drag.controller.endGesture(),
      );
    }
  }

  /// Releases the recognizer.
  void dispose() {
    interrupt();
    recognizer.dispose();
  }

  void _track(PointerDownEvent event, _Target target) {
    // Only the edited object has a widget that can compete for its taps.
    final takesTap = target.id != _controller.editingId;
    if (!recognizer.track(event, takesTap: takesTap)) return;
    _target = target;
    _isSecondPress =
        _lastTapId == target.id && (_doubleTapTimer?.isActive ?? false);
  }

  _Target? _targetAt(Offset position) {
    final layer = _layer();
    final frame = NoteObjectFrame.forSelection(
      layer.controller,
      handleSize: layer.handleSize,
      pageSize: layer.size,
    );
    final handle = frame?.handleAt(position);
    if (frame != null && handle != null) {
      return (id: frame.objectId, handle: handle);
    }
    final object = layer.controller.objectAt(position);

    return object == null ? null : (id: object.id, handle: null);
  }

  /// A locked object cannot be dragged, so an ancestor may use the pointer.
  bool _canDrag() {
    final target = _target;
    if (target == null) return false;
    if (target.handle != null) return true;
    final object = _controller.find(target.id);

    return object != null && !object.locked;
  }

  void _tap(Offset position) {
    final target = _target;
    _target = null;
    // Tapping a grip changes nothing.
    if (target == null || target.handle != null) return;
    if (HardwareKeyboard.instance.isShiftPressed) {
      _forgetTap();
      _controller.toggleSelection(target.id);
    } else if (_isSecondPress) {
      _forgetTap();
      _controller.beginEditing(target.id);
    } else {
      _controller.select(target.id);
      _rememberTap(target.id);
    }
  }

  void _rememberTap(String id) {
    _forgetTap();
    _lastTapId = id;
    _doubleTapTimer = Timer(kDoubleTapTimeout, _forgetTap);
  }

  void _forgetTap() {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    _lastTapId = null;
  }

  void _dragStart(Offset origin) {
    _forgetTap();
    final target = _target;
    if (target == null) return;
    final controller = _controller;
    if (target.handle == null && !controller.selectedIds.contains(target.id)) {
      controller.select(target.id);
    }
    // Commits pending editor input first, as its own undo step.
    controller.beginGesture();
    final drag = _createDrag(target, origin);
    if (drag == null) {
      controller.endGesture();
    } else {
      _drag = drag;
    }
  }

  NoteObjectDrag? _createDrag(_Target target, Offset origin) {
    final controller = _controller;
    final handle = target.handle;
    if (handle == null) {
      return NoteObjectMoveDrag.ofSelection(
        controller,
        origin: origin,
        pageSize: _layer().size,
      );
    }
    final object = controller.find(target.id);
    if (object == null || object.locked) return null;

    return handle == NoteObjectHandle.rotate
        ? NoteObjectRotateDrag(controller, original: object, origin: origin)
        : NoteObjectResizeDrag(
            controller,
            original: object,
            handle: handle,
            origin: origin,
          );
  }

  void _dragUpdate(Offset position) {
    final drag = _drag;
    if (drag == null) return;
    // Stop once the gesture is gone (the content was reloaded or someone
    // cancelled it): later moves would each become their own undo step.
    if (drag.controller.isGestureActive) {
      drag.update(position);
    } else {
      _drag = null;
    }
  }

  void _dragEnd() => _takeDrag()?.controller.endGesture();

  void _dragCancel() => _takeDrag()?.controller.cancelGesture();

  NoteObjectDrag? _takeDrag() {
    final drag = _drag;
    _drag = null;
    _target = null;

    return drag;
  }
}
