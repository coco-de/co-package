import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/internal/note_object_frame.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_object_handle.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';

/// The edit-mode chrome above the objects: the outline of every selected
/// object, a dashed hint around link areas, the grips of a single selection and
/// a mark on each locked object. It never takes pointers; the layer works out
/// grip hits from the same [NoteObjectFrame].
class NoteObjectOverlay extends StatelessWidget {
  const NoteObjectOverlay({
    required this.controller,
    required this.pageSize,
    required this.handleSize,
    required this.color,
    required this.lockColor,
    required this.strings,
    super.key,
  });

  static List<Offset> _outlinesOf(Iterable<NoteObject> objects) => [
    for (final object in objects)
      ...NoteObjectGeometry.corners(object.bounds, object.rotation),
  ];

  /// The objects and selection to decorate.
  final NoteObjectController controller;

  /// The page size, which places the rotation grip.
  final Size pageSize;

  /// Diameter of a grip.
  final double handleSize;

  /// Colour of the outlines and grips.
  final Color color;

  /// Colour of the badge of a lock mark.
  final Color lockColor;

  /// Accessibility labels.
  final NoteObjectsStrings strings;

  @override
  Widget build(BuildContext context) {
    final frame = NoteObjectFrame.forSelection(
      controller,
      handleSize: handleSize,
      pageSize: pageSize,
    );
    final selected = controller.selectedIds;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _NoteObjectOutlinePainter(
            outlines: _outlinesOf(controller.selection),
            // A link area may be invisible, so edit mode shows where it is.
            hints: _outlinesOf(
              controller.objects.where(
                (object) =>
                    !selected.contains(object.id) && object.linkTarget != null,
              ),
            ),
            stem: frame == null
                ? null
                : (
                    frame.rotationAnchor,
                    frame.positionOf(NoteObjectHandle.rotate),
                  ),
            color: color,
          ),
        ),
        if (frame != null)
          for (final handle in NoteObjectHandle.values)
            _GripMarker(
              key: ValueKey('note-object-handle-${handle.name}'),
              center: frame.positionOf(handle),
              size: handleSize,
              color: color,
              filled: handle == NoteObjectHandle.rotate,
              label: handle == NoteObjectHandle.rotate
                  ? strings.rotateHandleLabel
                  : strings.resizeHandleLabel,
            ),
        for (final object in controller.objects)
          if (object.locked)
            _LockMark(
              key: ValueKey('note-object-lock-${object.id}'),
              center: NoteObjectGeometry.handlePoint(
                object.bounds,
                object.rotation,
                NoteObjectHandle.topRight,
              ),
              size: handleSize * 1.5,
              color: lockColor,
              label: strings.lockedLabel,
            ),
      ],
    );
  }
}

class _GripMarker extends StatelessWidget {
  const _GripMarker({
    required this.center,
    required this.size,
    required this.color,
    required this.filled,
    required this.label,
    super.key,
  });

  static const Color _paper = Color(0xFFFFFFFF);

  final Offset center;
  final double size;
  final Color color;
  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: Rect.fromCircle(center: center, radius: size / 2),
    child: Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : _paper,
          border: Border.all(color: filled ? _paper : color, width: 1.5),
        ),
      ),
    ),
  );
}

class _LockMark extends StatelessWidget {
  const _LockMark({
    required this.center,
    required this.size,
    required this.color,
    required this.label,
    super.key,
  });

  final Offset center;
  final double size;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: Rect.fromCircle(center: center, radius: size / 2),
    child: Semantics(
      label: label,
      child: CustomPaint(painter: _PadlockPainter(color)),
    ),
  );
}

class _PadlockPainter extends CustomPainter {
  static const Color _glyph = Color(0xFFFFFFFF);

  final Color badge;

  const _PadlockPainter(this.badge);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    final bodyTop = center.dy - side * 0.04;
    canvas
      ..drawCircle(center, side / 2, Paint()..color = badge)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center.dx - side * 0.22,
            bodyTop,
            side * 0.44,
            side * 0.3,
          ),
          Radius.circular(side * 0.05),
        ),
        Paint()..color = _glyph,
      )
      ..drawArc(
        Rect.fromCircle(
          center: Offset(center.dx, bodyTop),
          radius: side * 0.15,
        ),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = _glyph
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.09,
      );
  }

  @override
  bool shouldRepaint(_PadlockPainter oldDelegate) => oldDelegate.badge != badge;
}

/// Outlines are flat lists of four corners per object.
class _NoteObjectOutlinePainter extends CustomPainter {
  static const double _width = 1.5;

  static const double _dash = 4;
  static const double _gap = 3;
  final List<Offset> outlines;

  final List<Offset> hints;

  /// From the side of the object to the rotation grip.
  final (Offset, Offset)? stem;

  final Color color;
  const _NoteObjectOutlinePainter({
    required this.outlines,
    required this.hints,
    required this.stem,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (var start = 0; start + 3 < outlines.length; start += 4) {
      canvas.drawPath(_quad(outlines, start), stroke);
    }
    final faint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var start = 0; start + 3 < hints.length; start += 4) {
      _paintDashed(canvas, _quad(hints, start), faint);
    }
    final line = stem;
    if (line != null) canvas.drawLine(line.$1, line.$2, stroke);
  }

  @override
  bool shouldRepaint(_NoteObjectOutlinePainter oldDelegate) =>
      !listEquals(oldDelegate.outlines, outlines) ||
      !listEquals(oldDelegate.hints, hints) ||
      oldDelegate.stem != stem ||
      oldDelegate.color != color;

  static Path _quad(List<Offset> corners, int start) =>
      Path()..addPolygon(corners.sublist(start, start + 4), true);

  static void _paintDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += _dash + _gap) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + _dash, metric.length)),
          paint,
        );
      }
    }
  }
}
