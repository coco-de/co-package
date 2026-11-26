import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Recognizes a tap or a drag of one primary pointer.
///
/// Unlike a pan recognizer it takes the arena as soon as the pointer moves
/// past the touch slop (not the larger pan slop), so dragging an object wins
/// over a scrolling or panning ancestor. A tap either takes the arena when the
/// pointer lifts, so an ancestor's double-tap cannot delay or swallow it, or
/// waits for it, so a recognizer deeper in the tree wins (see [track]). Drag
/// positions are local to the widget that called [track].
class NoteObjectGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Asked when a drag is about to start; `false` gives the pointer up so an
  /// ancestor may use it.
  bool Function()? canDrag;

  /// A press and release without dragging, with the release position.
  ValueChanged<Offset>? onTap;

  /// A drag starts, with the position where the pointer went down.
  ValueChanged<Offset>? onDragStart;

  /// The dragging pointer is now at this position.
  ValueChanged<Offset>? onDragUpdate;

  /// The drag ended with the pointer lifted.
  VoidCallback? onDragEnd;

  /// The drag was interrupted.
  VoidCallback? onDragCancel;

  _Session? _session;

  NoteObjectGestureRecognizer({super.debugOwner})
    : super(allowedButtonsFilter: _isPrimaryButton);

  /// Whether a pointer is being followed.
  bool get isTracking => _session != null;

  @override
  String get debugDescription => 'note object';

  /// Follows [event] unless another pointer is being followed or it is not a
  /// primary press. Returns whether it is followed.
  ///
  /// With [takesTap] a tap claims the arena when the pointer lifts; pass
  /// `false` when a widget deeper in the tree may want the tap.
  bool track(PointerDownEvent event, {required bool takesTap}) {
    if (_session != null || !isPointerAllowed(event)) return false;
    addPointer(event);
    _session?.takesTap = takesTap;

    return _session != null;
  }

  /// Stops following the pointer without calling anything.
  void abandon() {
    final session = _session;
    if (session == null) return;
    _session = null;
    resolve(GestureDisposition.rejected);
    stopTrackingPointer(session.pointer);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_session != null) return;
    super.addAllowedPointer(event);
    _session = _Session(event.pointer, event.position, event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    final session = _session;
    if (session != null && event.pointer == session.pointer) {
      switch (event) {
        case PointerMoveEvent():
          _move(session, event);
        case PointerUpEvent():
          _lift(session, event);
        case PointerCancelEvent():
          _cancel(session);
        default:
          break;
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    final session = _session;
    if (session == null || session.pointer != pointer) return;
    session.accepted = true;
    if (session.liftedAt != null) _finishTap(session);
  }

  @override
  void rejectGesture(int pointer) {
    final session = _session;
    if (session == null || session.pointer != pointer) return;
    _session = null;
    stopTrackingPointer(pointer);
    if (session.dragging) onDragCancel?.call();
  }

  // Nothing to do: a tap may still be waiting for the arena, so the session
  // stays.
  @override
  // ignore: no-empty-block
  void didStopTrackingLastPointer(int pointer) {}

  static bool _isPrimaryButton(int buttons) => buttons == kPrimaryButton;

  void _move(_Session session, PointerMoveEvent event) {
    if (!session.dragging) {
      final travel = (event.position - session.downGlobal).distance;
      if (travel <= computeHitSlop(event.kind, gestureSettings)) return;
      if (!(canDrag?.call() ?? true)) {
        resolve(GestureDisposition.rejected);

        return;
      }
      resolve(GestureDisposition.accepted);
      // Another recognizer may already have won the pointer.
      if (!identical(_session, session)) return;
      session.dragging = true;
      onDragStart?.call(session.downLocal);
    }
    onDragUpdate?.call(event.localPosition);
  }

  void _lift(_Session session, PointerUpEvent event) {
    if (session.dragging) {
      _session = null;
      onDragEnd?.call();

      return;
    }
    session.liftedAt = event.localPosition;
    // Winning calls acceptGesture, which finishes the tap.
    if (session.takesTap) resolve(GestureDisposition.accepted);
    // Without winning yet, the arena decides when it is swept after this event.
    if (identical(_session, session) && session.accepted) _finishTap(session);
  }

  void _cancel(_Session session) {
    _session = null;
    resolve(GestureDisposition.rejected);
    if (session.dragging) onDragCancel?.call();
  }

  void _finishTap(_Session session) {
    final position = session.liftedAt;
    _session = null;
    if (position != null) onTap?.call(position);
  }
}

class _Session {
  final int pointer;

  final Offset downGlobal;
  final Offset downLocal;
  bool takesTap = false;
  bool accepted = false;
  bool dragging = false;
  Offset? liftedAt;
  _Session(this.pointer, this.downGlobal, this.downLocal);
}
