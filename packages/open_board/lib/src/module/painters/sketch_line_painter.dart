import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/stroke_calculator.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

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

  Path? getPathForStrokeOld(Stroke stroke) {
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
}
