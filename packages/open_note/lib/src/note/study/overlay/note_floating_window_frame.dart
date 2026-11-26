import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_controller.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_style.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_title_bar.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_glyph.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// One window of `NoteFloatingWindowHost`, positioned in the host's `Stack`.
/// Internal to `study/overlay`.
///
/// Any press on it focuses it. The body stays built while minimized (at its
/// full size, off stage) so a web view or a chat keeps its state.
class NoteFloatingWindowFrame extends StatefulWidget {
  /// Draws [window] inside a host of [hostSize].
  const NoteFloatingWindowFrame({
    required this.window,
    required this.controller,
    required this.hostSize,
    required this.focused,
    required this.style,
    required this.strings,
    super.key,
  });

  /// The window to draw.
  final NoteFloatingWindow window;

  /// Receives every action.
  final NoteFloatingWindowController controller;

  /// Size of the host.
  final Size hostSize;

  /// Whether the window has focus.
  final bool focused;

  /// Colours and metrics.
  final NoteFloatingWindowStyle style;

  /// Accessibility labels.
  final NoteStudyOverlayStrings strings;

  @override
  State<NoteFloatingWindowFrame> createState() =>
      _NoteFloatingWindowFrameState();
}

class _NoteFloatingWindowFrameState extends State<NoteFloatingWindowFrame> {
  Rect? _gestureStart;
  Offset _gestureDelta = Offset.zero;

  NoteFloatingWindow get _window => widget.window;

  /// The spec's minimum, but never smaller than the window chrome needs: the
  /// three title bar buttons with a little room to drag by, and the resize
  /// corner below the title bar (so it never covers a button).
  Size get _minSize {
    final style = widget.style;
    final corner = _window.spec.resizable ? style.resizeHandleExtent : 0;

    return Size(
      math.max(_window.spec.minSize.width, style.buttonExtent * 3 + 24),
      math.max(_window.spec.minSize.height, style.titleBarHeight + corner),
    );
  }

  /// The expanded rectangle, kept inside the host.
  Rect get _expanded => NoteFloatingWindowGeometry.clamp(
    _window.rect,
    widget.hostSize,
    minSize: _minSize,
  );

  /// What is on screen: the title bar alone while minimized.
  Rect get _shown {
    if (!_window.minimized) return _expanded;
    final bar = widget.style.titleBarHeight;
    final rect = _window.rect;

    return NoteFloatingWindowGeometry.clamp(
      Rect.fromLTWH(rect.left, rect.top, rect.width, bar),
      widget.hostSize,
      minSize: Size(_minSize.width, bar),
    );
  }

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: _shown,
    child: Listener(
      onPointerDown: (_) => widget.controller.focus(_window.id),
      child: Opacity(opacity: _window.opacity, child: _chrome(context)),
    ),
  );

  Widget _chrome(BuildContext context) {
    final style = widget.style;
    final radius = BorderRadius.all(Radius.circular(style.cornerRadius));

    return Semantics(
      key: ValueKey('note-floating-window-${_window.id}'),
      container: true,
      explicitChildNodes: true,
      label: _window.spec.title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: radius,
          boxShadow: style.shadows,
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.focused
                  ? style.focusedBorderColor
                  : style.borderColor,
            ),
            borderRadius: radius,
          ),
          child: ClipRRect(borderRadius: radius, child: _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final expanded = _expanded;
    final bodyHeight = math.max(
      0.0,
      expanded.height - widget.style.titleBarHeight,
    );

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titleBar(),
            Offstage(
              offstage: _window.minimized,
              child: SizedBox(
                width: expanded.width,
                height: bodyHeight,
                child: Builder(builder: _window.spec.builder),
              ),
            ),
          ],
        ),
        if (_window.spec.resizable && !_window.minimized)
          Positioned(right: 0, bottom: 0, child: _resizeCorner()),
      ],
    );
  }

  Widget _titleBar() => NoteFloatingWindowTitleBar(
    window: _window,
    controller: widget.controller,
    focused: widget.focused,
    style: widget.style,
    strings: widget.strings,
    onDragStart: _beginGesture,
    onDragUpdate: _move,
    onDragEnd: _endGesture,
  );

  Widget _resizeCorner() => Semantics(
    label: widget.strings.resizeWindow,
    child: MouseRegion(
      cursor: SystemMouseCursors.resizeDownRight,
      child: GestureDetector(
        key: ValueKey('note-floating-resize-${_window.id}'),
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (_) => _beginGesture(),
        onPanUpdate: (details) => _resize(details.delta),
        onPanEnd: (_) => _endGesture(),
        onPanCancel: _endGesture,
        child: SizedBox.square(
          dimension: widget.style.resizeHandleExtent,
          child: Center(
            child: NoteOverlayGlyph(
              NoteOverlayGlyphKind.resizeGrip,
              color: widget.style.iconColor,
              size: 14,
            ),
          ),
        ),
      ),
    ),
  );

  // Gestures start from what is on screen and add up the whole drag, so a
  // window held at an edge comes back only when the pointer does.
  void _beginGesture() {
    _gestureStart = _shown;
    _gestureDelta = Offset.zero;
  }

  void _endGesture() => _gestureStart = null;

  void _move(Offset delta) {
    final start = _gestureStart;
    if (start == null) return;
    _gestureDelta += delta;
    final moved = NoteFloatingWindowGeometry.clamp(
      start.shift(_gestureDelta),
      widget.hostSize,
      minSize: start.size,
    );
    widget.controller.move(_window.id, moved.topLeft);
  }

  void _resize(Offset delta) {
    final start = _gestureStart;
    if (start == null) return;
    _gestureDelta += delta;
    widget.controller.setRect(
      _window.id,
      NoteFloatingWindowGeometry.resize(
        start,
        _gestureDelta,
        widget.hostSize,
        minSize: _minSize,
      ),
    );
  }
}
