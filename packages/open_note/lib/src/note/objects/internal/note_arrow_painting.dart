import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/objects/note_arrow_object.dart';

/// Draws arrows for both the widget and the canvas export.
abstract final class NoteArrowPainting {
  /// The point at [fraction] of [rect].
  static Offset pointIn(Rect rect, Offset fraction) => Offset(
    rect.left + fraction.dx.clamp(0.0, 1.0) * rect.width,
    rect.top + fraction.dy.clamp(0.0, 1.0) * rect.height,
  );

  /// The control point of the quadratic curve from [from] to [to] whose
  /// middle passes through [through].
  static Offset controlFor(Offset from, Offset through, Offset to) =>
      through * 2 - (from + to) / 2;

  /// The tight bounds of the quadratic curve.
  static Rect curveBounds(Offset from, Offset control, Offset to) {
    List<double> extremes(double a, double b, double c) {
      final values = [a, c];
      final divisor = a - 2 * b + c;
      if (divisor.abs() > 1e-9) {
        final t = (a - b) / divisor;
        if (t > 0 && t < 1) {
          final u = 1 - t;
          values.add(u * u * a + 2 * u * t * b + t * t * c);
        }
      }

      return values;
    }

    final x = extremes(from.dx, control.dx, to.dx);
    final y = extremes(from.dy, control.dy, to.dy);

    return Rect.fromLTRB(
      x.reduce(math.min),
      y.reduce(math.min),
      x.reduce(math.max),
      y.reduce(math.max),
    );
  }

  /// Draws [arrow] with its bounds laid over [rect]. An arrow of no length
  /// draws nothing.
  static void paint(Canvas canvas, Rect rect, NoteArrowObject arrow) {
    final from = pointIn(rect, arrow.start);
    final to = pointIn(rect, arrow.end);
    if (arrow.bend case final bend?) {
      _paintCurve(
        canvas,
        from,
        controlFor(from, pointIn(rect, bend), to),
        to,
        arrow,
      );

      return;
    }
    final length = (to - from).distance;
    if (length < 0.001) return;
    final direction = (to - from) / length;
    final width = arrow.effectiveWidth;
    final capLength = _capLength(width, length);
    final stroke = _strokePaint(arrow);
    _paintShaft(
      canvas,
      _shaftEnd(from, direction, arrow.tailStyle, capLength),
      _shaftEnd(to, -direction, arrow.headStyle, capLength),
      stroke,
      arrow.dashed,
    );
    _paintCap(canvas, to, direction, arrow.headStyle, capLength, stroke);
    _paintCap(canvas, from, -direction, arrow.tailStyle, capLength, stroke);
  }

  static void _paintCurve(
    Canvas canvas,
    Offset from,
    Offset control,
    Offset to,
    NoteArrowObject arrow,
  ) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty || metrics.first.length < 0.001) return;
    final metric = metrics.first;
    final capLength = _capLength(arrow.effectiveWidth, metric.length);
    final stroke = _strokePaint(arrow);
    double trim(NoteArrowCap cap) =>
        cap == NoteArrowCap.triangle ? capLength * 0.9 : 0;
    final begin = trim(arrow.tailStyle);
    final finish = metric.length - trim(arrow.headStyle);
    if (!arrow.dashed) {
      canvas.drawPath(metric.extractPath(begin, finish), stroke);
    } else {
      final dash = math.max(stroke.strokeWidth * 3, 6).toDouble();
      final gap = math.max(stroke.strokeWidth * 2, 4).toDouble();
      for (var at = begin; at < finish; at += dash + gap) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + dash, finish)),
          stroke,
        );
      }
    }
    // The caps point along the curve's tangents at its ends.
    Offset towards(Offset tip, Offset other, Offset fallback) {
      final direction = (tip - other).distance < 0.001
          ? tip - fallback
          : tip - other;

      return direction / direction.distance;
    }

    _paintCap(
      canvas,
      to,
      towards(to, control, from),
      arrow.headStyle,
      capLength,
      stroke,
    );
    _paintCap(
      canvas,
      from,
      towards(from, control, to),
      arrow.tailStyle,
      capLength,
      stroke,
    );
  }

  /// The caps grow with the line but never swallow the whole arrow.
  static double _capLength(double width, double length) =>
      math.min(math.max(width * 4, 10), length / 2).toDouble();

  static Paint _strokePaint(NoteArrowObject arrow) => Paint()
    ..color = arrow.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = arrow.effectiveWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Where the line stops at a tip: short of it under a filled head, so the
  /// line does not poke through the point.
  static Offset _shaftEnd(
    Offset tip,
    Offset inward,
    NoteArrowCap cap,
    double capLength,
  ) => cap == NoteArrowCap.triangle ? tip + inward * capLength * 0.9 : tip;

  static void _paintShaft(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint stroke,
    bool dashed,
  ) {
    final length = (to - from).distance;
    if (!dashed || length < 0.001) {
      canvas.drawLine(from, to, stroke);

      return;
    }
    final direction = (to - from) / length;
    final dash = math.max(stroke.strokeWidth * 3, 6).toDouble();
    final gap = math.max(stroke.strokeWidth * 2, 4).toDouble();
    for (var at = 0.0; at < length; at += dash + gap) {
      canvas.drawLine(
        from + direction * at,
        from + direction * math.min(at + dash, length),
        stroke,
      );
    }
  }

  static void _paintCap(
    Canvas canvas,
    Offset tip,
    Offset direction,
    NoteArrowCap cap,
    double length,
    Paint stroke,
  ) {
    if (cap == NoteArrowCap.none) return;
    final base = tip - direction * length;
    final side = Offset(-direction.dy, direction.dx) * length * 0.5;
    final path = Path()
      ..moveTo(base.dx + side.dx, base.dy + side.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(base.dx - side.dx, base.dy - side.dy);
    if (cap == NoteArrowCap.open) {
      canvas.drawPath(path, stroke);
    } else {
      canvas.drawPath(path..close(), Paint()..color = stroke.color);
    }
  }
}
