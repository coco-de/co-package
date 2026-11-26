import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A horizontal slider drawn with plain widgets (the package does not depend on
/// a design system). Dragging or tapping the track reports a value in
/// `[min, max]`, snapped to [divisions] steps when given.
class NoteSlider extends StatelessWidget {
  const NoteSlider({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeEnd,
    this.activeColor = const Color(0xFF2962FF),
    this.inactiveColor = const Color(0xFFBDBDBD),
    this.thumbColor = const Color(0xFFFFFFFF),
    this.thumbRadius = 11,
    this.trackHeight = 4,
    this.semanticLabel,
  }) : assert(max > min, 'max must be greater than min'),
       assert(divisions == null || divisions > 0);

  /// Current value; clamped into `[min, max]` for display.
  final double value;

  /// Called continuously while the user drags, with the snapped new value.
  final ValueChanged<double> onChanged;

  /// Called once when a drag or tap ends.
  final ValueChanged<double>? onChangeEnd;

  final double min;
  final double max;

  /// Number of equal steps between [min] and [max], or `null` for continuous.
  final int? divisions;

  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final double thumbRadius;
  final double trackHeight;

  /// Accessibility label announced with the value.
  final String? semanticLabel;

  /// Snaps [raw] into the range and onto the division grid.
  double snap(double raw) {
    final clamped = raw.clamp(min, max);
    final steps = divisions;
    if (steps == null) return clamped;
    final step = (max - min) / steps;

    return (min + ((clamped - min) / step).round() * step).clamp(min, max);
  }

  double _valueAt(double dx, double width) {
    final usable = math.max(width - 2 * thumbRadius, 1);
    final fraction = ((dx - thumbRadius) / usable).clamp(0.0, 1.0);

    return snap(min + fraction * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    final shown = value.clamp(min, max);
    final step = divisions == null
        ? (max - min) / 20
        : (max - min) / divisions!;

    return Semantics(
      slider: true,
      label: semanticLabel,
      value: shown.toStringAsFixed(2),
      increasedValue: snap(shown + step).toStringAsFixed(2),
      decreasedValue: snap(shown - step).toStringAsFixed(2),
      onIncrease: () => onChanged(snap(shown + step)),
      onDecrease: () => onChanged(snap(shown - step)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : 200.0;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                onChanged(_valueAt(details.localPosition.dx, width)),
            onTapUp: (details) =>
                onChangeEnd?.call(_valueAt(details.localPosition.dx, width)),
            onHorizontalDragUpdate: (details) =>
                onChanged(_valueAt(details.localPosition.dx, width)),
            onHorizontalDragEnd: (_) => onChangeEnd?.call(shown),
            child: SizedBox(
              width: width,
              height: thumbRadius * 2 + 8,
              child: CustomPaint(
                painter: _NoteSliderPainter(
                  fraction: (shown - min) / (max - min),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  thumbColor: thumbColor,
                  thumbRadius: thumbRadius,
                  trackHeight: trackHeight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoteSliderPainter extends CustomPainter {
  const _NoteSliderPainter({
    required this.fraction,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.thumbRadius,
    required this.trackHeight,
  });

  final double fraction;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final double thumbRadius;
  final double trackHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final left = thumbRadius;
    final right = size.width - thumbRadius;
    final thumbX = left + (right - left) * fraction;
    final radius = Radius.circular(trackHeight / 2);
    final track = Rect.fromLTRB(
      left,
      centerY - trackHeight / 2,
      right,
      centerY + trackHeight / 2,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(track, radius),
        Paint()..color = inactiveColor,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, track.top, thumbX, track.bottom),
          radius,
        ),
        Paint()..color = activeColor,
      )
      ..drawCircle(
        Offset(thumbX, centerY + 1),
        thumbRadius,
        Paint()..color = const Color(0x33000000),
      )
      ..drawCircle(
        Offset(thumbX, centerY),
        thumbRadius,
        Paint()..color = thumbColor,
      )
      ..drawCircle(
        Offset(thumbX, centerY),
        thumbRadius,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_NoteSliderPainter old) =>
      old.fraction != fraction ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor ||
      old.thumbColor != thumbColor ||
      old.thumbRadius != thumbRadius ||
      old.trackHeight != trackHeight;
}
