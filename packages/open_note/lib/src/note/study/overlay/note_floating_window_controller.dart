import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_spec.dart';

/// The open floating windows, their places and their stacking order.
///
/// [windows] is in paint order, bottom first. Pinned windows form a layer above
/// the unpinned ones; within each layer the most recently focused window is on
/// top, so the focused window is above everything except pinned windows.
///
/// Rectangles are host coordinates. The controller only enforces each window's
/// minimum size; keeping windows inside the screen is the host's job. Unknown
/// ids, non-finite values and every call after [dispose] are ignored, and
/// listeners hear only about real changes.
class NoteFloatingWindowController extends ChangeNotifier {
  /// The lowest opacity, so a window can always be found and closed.
  static const double minOpacity = 0.2;

  final List<NoteFloatingWindow> _windows = [];
  String? _focusedId;
  bool _disposed = false;

  /// The open windows, bottom first (unmodifiable).
  List<NoteFloatingWindow> get windows => List.unmodifiable(_windows);

  /// The window that has focus, if any.
  String? get focusedId => _focusedId;

  /// The open window with [id], or `null`.
  NoteFloatingWindow? window(String id) {
    for (final window in _windows) {
      if (window.id == id) return window;
    }

    return null;
  }

  /// Whether a window with [id] is open.
  bool isOpen(String id) => window(id) != null;

  /// Opens [spec] on top and focuses it. An open window with the same id keeps
  /// its place, size, opacity and pin; it takes the new spec, is restored and
  /// comes forward.
  void open(NoteFloatingWindowSpec spec) {
    final existing = window(spec.id);
    final next = existing == null
        ? NoteFloatingWindow(
            spec: spec,
            rect: _atLeast(spec.initialRect, spec.minSize),
            opacity: _clampOpacity(spec.opacity),
          )
        : existing.copyWith(
            spec: spec,
            rect: _atLeast(existing.rect, spec.minSize),
            minimized: false,
          );
    _commit(_raised(next), spec.id);
  }

  /// Closes a window. When it had focus, the topmost window that is not
  /// minimized takes it (the topmost one when all are minimized).
  void close(String id) {
    if (!isOpen(id)) return;
    final rest = [
      for (final window in _windows)
        if (window.id != id) window,
    ];
    _commit(rest, _focusedId == id ? _topmost(rest) : _focusedId);
  }

  /// Closes every window.
  void closeAll() => _commit(const [], null);

  /// Gives a window focus and brings it to the top of its layer.
  void focus(String id) {
    final target = window(id);
    if (target != null) _commit(_raised(target), id);
  }

  /// Moves a window so its top-left corner is at [topLeft].
  void move(String id, Offset topLeft) {
    final target = window(id);
    if (target == null || !topLeft.isFinite) return;
    _replace(target.copyWith(rect: topLeft & target.rect.size));
  }

  /// Resizes a window, keeping its top-left corner; at least its minimum size.
  /// Works for windows the user cannot resize, too.
  void resize(String id, Size size) {
    final target = window(id);
    if (target == null) return;
    setRect(id, target.rect.topLeft & size);
  }

  /// Moves and resizes a window in one step.
  void setRect(String id, Rect rect) {
    final target = window(id);
    if (target == null || !rect.isFinite) return;
    _replace(target.copyWith(rect: _atLeast(rect, target.spec.minSize)));
  }

  /// Sets the opacity, clamped to [minOpacity]–1.
  void setOpacity(String id, double opacity) {
    final target = window(id);
    if (target == null || opacity.isNaN) return;
    _replace(target.copyWith(opacity: _clampOpacity(opacity)));
  }

  /// Pins or unpins a window and moves it to the top of its new layer. Focus
  /// does not change.
  void togglePin(String id) {
    final target = window(id);
    if (target == null) return;
    _commit(_raised(target.copyWith(pinned: !target.pinned)), _focusedId);
  }

  /// Collapses a window to its title bar. Order and focus stay.
  void minimize(String id) {
    final target = window(id);
    if (target != null) _replace(target.copyWith(minimized: true));
  }

  /// Expands a minimized window, focuses it and brings it forward.
  void restore(String id) {
    final target = window(id);
    if (target == null || !target.minimized) return;
    _commit(_raised(target.copyWith(minimized: false)), id);
  }

  /// [minimize] or [restore], whichever applies.
  void toggleMinimize(String id) {
    final target = window(id);
    if (target == null) return;
    target.minimized ? restore(id) : minimize(id);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static Rect _atLeast(Rect rect, Size minSize) =>
      rect.topLeft &
      Size(
        math.max(rect.width, minSize.width),
        math.max(rect.height, minSize.height),
      );

  static double _clampOpacity(double opacity) =>
      opacity.isNaN ? 1 : opacity.clamp(minOpacity, 1.0);

  static String? _topmost(List<NoteFloatingWindow> windows) {
    for (final window in windows.reversed) {
      if (!window.minimized) return window.id;
    }

    return windows.isEmpty ? null : windows.last.id;
  }

  /// The windows with [window] on top of its (pinned or unpinned) layer.
  List<NoteFloatingWindow> _raised(NoteFloatingWindow window) {
    final others = [
      for (final other in _windows)
        if (other.id != window.id) other,
    ];
    final firstPinned = window.pinned
        ? -1
        : others.indexWhere((other) => other.pinned);

    return others
      ..insert(firstPinned < 0 ? others.length : firstPinned, window);
  }

  void _replace(NoteFloatingWindow window) => _commit([
    for (final other in _windows) other.id == window.id ? window : other,
  ], _focusedId);

  void _commit(List<NoteFloatingWindow> next, String? focusedId) {
    if (_disposed) return;
    if (focusedId == _focusedId && _same(next)) return;
    _windows
      ..clear()
      ..addAll(next);
    _focusedId = focusedId;
    notifyListeners();
  }

  bool _same(List<NoteFloatingWindow> next) {
    if (next.length != _windows.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i] != _windows[i]) return false;
    }

    return true;
  }
}
