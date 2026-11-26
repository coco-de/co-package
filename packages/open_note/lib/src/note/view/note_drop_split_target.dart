import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_drag_data.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// Reports a note dropped on one edge of [child] — the gesture that opens it
/// beside the current page (see `NoteViewLayoutController.openBeside`).
///
/// While a [NoteDragData] hovers over it, the edge zones are shown and the one
/// under the pointer is highlighted and labelled. Each zone covers
/// [zoneFraction] of the width (left and right, full height) or of the height
/// (top and bottom, between the side zones). A drop in the middle is ignored
/// and stays available to drag targets outside this widget. The zones never
/// take ordinary pointers, so [child] keeps working.
class NoteDropSplitTarget extends StatefulWidget {
  /// Wraps [child] in edge drop zones that report through [onDrop].
  const NoteDropSplitTarget({
    required this.child,
    required this.onDrop,
    super.key,
    this.canAccept,
    this.sides = allSides,
    this.zoneFraction = defaultZoneFraction,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  });

  /// The four sides.
  static const Set<NoteDropSide> allSides = {
    NoteDropSide.left,
    NoteDropSide.right,
    NoteDropSide.top,
    NoteDropSide.bottom,
  };

  /// Default [zoneFraction].
  static const double defaultZoneFraction = 0.25;

  /// Key of the hit area of [side].
  static Key zoneKey(NoteDropSide side) =>
      ValueKey<String>('note-drop-zone-${side.name}');

  /// The zone of [side] in a target of [size], given the offered [sides] and
  /// the zone size [zoneFraction] (clamped to 0.05–0.45).
  static Rect zoneRect(
    NoteDropSide side,
    Size size, {
    double zoneFraction = defaultZoneFraction,
    Set<NoteDropSide> sides = allSides,
  }) {
    final fraction = zoneFraction.clamp(0.05, 0.45);
    final width = size.width * fraction;
    final height = size.height * fraction;
    final start = sides.contains(NoteDropSide.left) ? width : 0.0;
    final end = sides.contains(NoteDropSide.right)
        ? size.width - width
        : size.width;

    return switch (side) {
      NoteDropSide.left => Rect.fromLTWH(0, 0, width, size.height),
      NoteDropSide.right => Rect.fromLTWH(
        size.width - width,
        0,
        width,
        size.height,
      ),
      NoteDropSide.top => Rect.fromLTRB(start, 0, end, height),
      NoteDropSide.bottom => Rect.fromLTRB(
        start,
        size.height - height,
        end,
        size.height,
      ),
    };
  }

  /// The view underneath; it stays interactive.
  final Widget child;

  /// A note was dropped on [NoteDropSide].
  final void Function(NoteDragData data, NoteDropSide side) onDrop;

  /// Which notes may be dropped (default: all).
  final bool Function(NoteDragData data)? canAccept;

  /// The edges offered.
  final Set<NoteDropSide> sides;

  /// Depth of each zone as a share of the width or height.
  final double zoneFraction;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  State<NoteDropSplitTarget> createState() => _NoteDropSplitTargetState();
}

class _NoteDropSplitTargetState extends State<NoteDropSplitTarget> {
  bool _hovering = false;
  NoteDropSide? _active;

  bool _accepts(NoteDragData data) => widget.canAccept?.call(data) ?? true;

  void _setHovering(bool hovering) {
    if (_hovering != hovering) setState(() => _hovering = hovering);
  }

  void _setActive(NoteDropSide side) {
    if (_active != side) setState(() => _active = side);
  }

  void _clearActive(NoteDropSide side) {
    if (_active == side) setState(() => _active = null);
  }

  void _drop(NoteDragData data, NoteDropSide side) {
    setState(() {
      _active = null;
      _hovering = false;
    });
    widget.onDrop(data, side);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildOverlay(constraints.biggest),
          ),
        ),
      ],
    );
  }

  Rect _rectOf(NoteDropSide side, Size size) => NoteDropSplitTarget.zoneRect(
    side,
    size,
    zoneFraction: widget.zoneFraction,
    sides: widget.sides,
  );

  Widget _buildOverlay(Size size) {
    final visible = _hovering || _active != null;

    // The order matters: drag targets are found front to back, so the tracker
    // (which accepts nothing) is seen first, then the zone under the pointer.
    return Stack(
      children: [
        if (visible)
          Positioned.fill(child: IgnorePointer(child: _buildHighlights(size))),
        for (final side in widget.sides)
          Positioned.fromRect(
            key: ValueKey<NoteDropSide>(side),
            rect: _rectOf(side, size),
            child: _buildZone(side),
          ),
        Positioned.fill(
          key: const ValueKey<String>('note-drop-tracker'),
          child: _buildTracker(),
        ),
      ],
    );
  }

  Widget _buildZone(NoteDropSide side) {
    return DragTarget<NoteDragData>(
      key: NoteDropSplitTarget.zoneKey(side),
      onWillAcceptWithDetails: (details) => _accepts(details.data),
      onMove: (details) {
        if (_accepts(details.data)) _setActive(side);
      },
      onLeave: (_) => _clearActive(side),
      onAcceptWithDetails: (details) => _drop(details.data, side),
      builder: (context, candidates, rejected) => const SizedBox.expand(),
    );
  }

  /// Sees every drag over the whole target without ever accepting one.
  Widget _buildTracker() {
    return DragTarget<NoteDragData>(
      onWillAcceptWithDetails: (_) => false,
      onMove: (details) {
        if (_accepts(details.data)) _setHovering(true);
      },
      onLeave: (_) => _setHovering(false),
      builder: (context, candidates, rejected) => const SizedBox.expand(),
    );
  }

  Widget _buildHighlights(Size size) {
    final active = _active;

    return Stack(
      children: [
        for (final side in widget.sides)
          Positioned.fromRect(
            rect: _rectOf(side, size).deflate(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: side == active
                    ? widget.style.dropZoneActiveColor
                    : widget.style.dropZoneColor,
                border: Border.all(color: widget.style.accentColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: side == active ? _buildLabel(side) : null,
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(NoteDropSide side) {
    final strings = widget.strings;
    final text = switch (side) {
      NoteDropSide.left => strings.dropLeft,
      NoteDropSide.right => strings.dropRight,
      NoteDropSide.top => strings.dropTop,
      NoteDropSide.bottom => strings.dropBottom,
    };

    return Center(
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: widget.style.textColor),
        ),
      ),
    );
  }
}
