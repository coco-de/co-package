import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// The grabbable line between two panes of a `NoteResizablePanes`.
///
/// [axis] is the axis of the panes: with [Axis.horizontal] the panes sit side
/// by side, so the divider is vertical and is dragged left and right.
class NotePaneDivider extends StatelessWidget {
  /// A divider that reports its drags and accessibility steps.
  const NotePaneDivider({
    required this.axis,
    required this.fraction,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onNudge,
    super.key,
    this.dividerKey,
    this.step = 0.05,
    this.cursor = MouseCursor.defer,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  });

  /// Axis along which the panes are arranged.
  final Axis axis;

  /// Share of the pane before this divider, announced to screen readers.
  final double fraction;

  /// A drag began.
  final GestureDragStartCallback onDragStart;

  /// The drag moved.
  final GestureDragUpdateCallback onDragUpdate;

  /// The drag ended or was cancelled.
  final VoidCallback onDragEnd;

  /// A screen reader asked to grow (positive) or shrink the pane before.
  final ValueChanged<double> onNudge;

  /// Key of the gesture area (for tests and automation).
  final Key? dividerKey;

  /// Size of one accessibility step.
  final double step;

  /// Mouse cursor over the divider.
  final MouseCursor cursor;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  static String _percent(double fraction) =>
      '${(fraction.clamp(0.0, 1.0) * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;

    return Semantics(
      container: true,
      slider: true,
      label: strings.resizeDivider,
      value: _percent(fraction),
      increasedValue: _percent(fraction + step),
      decreasedValue: _percent(fraction - step),
      onIncrease: () => onNudge(step),
      onDecrease: () => onNudge(-step),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          key: dividerKey,
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: horizontal ? onDragStart : null,
          onHorizontalDragUpdate: horizontal ? onDragUpdate : null,
          onHorizontalDragEnd: horizontal ? (_) => onDragEnd() : null,
          onHorizontalDragCancel: horizontal ? onDragEnd : null,
          onVerticalDragStart: horizontal ? null : onDragStart,
          onVerticalDragUpdate: horizontal ? null : onDragUpdate,
          onVerticalDragEnd: horizontal ? null : (_) => onDragEnd(),
          onVerticalDragCancel: horizontal ? null : onDragEnd,
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _NoteDividerPainter(
                horizontal: horizontal,
                color: style.dividerColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteDividerPainter extends CustomPainter {
  const _NoteDividerPainter({required this.horizontal, required this.color});

  /// Whether the panes are side by side (the line is then vertical).
  final bool horizontal;
  final Color color;

  static const double _gripLength = 36;
  static const double _gripThickness = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color;
    final line = horizontal
        ? Rect.fromCenter(center: center, width: 1, height: size.height)
        : Rect.fromCenter(center: center, width: size.width, height: 1);
    final grip = horizontal
        ? Rect.fromCenter(
            center: center,
            width: _gripThickness,
            height: _gripLength,
          )
        : Rect.fromCenter(
            center: center,
            width: _gripLength,
            height: _gripThickness,
          );
    canvas
      ..drawRect(line, paint)
      ..drawRRect(
        RRect.fromRectAndRadius(grip, const Radius.circular(2)),
        paint,
      );
  }

  @override
  bool shouldRepaint(_NoteDividerPainter old) =>
      old.horizontal != horizontal || old.color != color;
}
