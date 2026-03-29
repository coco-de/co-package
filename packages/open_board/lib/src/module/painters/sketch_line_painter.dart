import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/stroke_calculator.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;

mixin SketchLinePainter {
  Path? getSimplePathForStroke(Stroke stroke) {
    if (stroke.points.isEmpty) {
      return null;
    } else if (stroke.points.length < 2) {
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(stroke.points[0].x, stroke.points[0].y),
          radius: 1,
        ),
      );
    } else {
      final path = Path();
      path.moveTo(stroke.points[0].x, stroke.points[0].y);
      for (int i = 1; i < stroke.points.length - 1; ++i) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        path.quadraticBezierTo(
          p0.x,
          p0.y,
          (p0.x + p1.x) / 2,
          (p0.y + p1.y) / 2,
        );
      }
      return path;
    }
  }

  Path? getPathForStrokeOld(Stroke stroke, {double scaleFactor = 1.0}) {
    final outlinePoints = getStroke(stroke);
    if (outlinePoints.isEmpty) {
      return null;
    } else if (outlinePoints.length < 2) {
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(outlinePoints[0].x, outlinePoints[0].y),
          radius: 1,
        ),
      );
    } else {
      final path = Path();
      path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
      for (int i = 1; i < outlinePoints.length - 1; ++i) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(
          p0.x,
          p0.y,
          (p0.x + p1.x) / 2,
          (p0.y + p1.y) / 2,
        );
      }
      return path;
    }
  }

  Path? getPathForStroke(Stroke stroke, {double scaleFactor = 1.0}) {
    final points = stroke.points
        .map((point) => pf.Point(point.x, point.y, point.p))
        .toList();
    final outlinePoints = pf.getStroke(
      points,
      options: pf.StrokeOptions(
        size: stroke.options.size,
        thinning: stroke.options.thinning,
        smoothing: stroke.options.smoothing,
        streamline: stroke.options.streamline,
        start: pf.StrokeEndOptions.start(
          customTaper: stroke.options.taperStart,
          cap: stroke.options.capStart,
        ),
        end: pf.StrokeEndOptions.end(
          customTaper: stroke.options.taperEnd,
          cap: stroke.options.capEnd,
        ),
        simulatePressure: stroke.options.simulatePressure,
        isComplete: stroke.options.isComplete,
      ),
    );
    if (outlinePoints.isEmpty) {
      return null;
    } else if (outlinePoints.length < 2) {
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(outlinePoints[0].dx, outlinePoints[0].dy),
          radius: 1,
        ),
      );
    } else {
      final path = Path();
      path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
      for (int i = 1; i < outlinePoints.length - 1; ++i) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      return path;
    }
  }
}
