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
    }
    final path = Path();
    path.moveTo(stroke.points[0].x, stroke.points[0].y);
    for (int i = 1; i < stroke.points.length - 1; ++i) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      path.quadraticBezierTo(p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    }
    // 마지막 점까지 직선으로 연결한다.
    // quadratic 스무딩 루프는 `length - 1`까지만 돌아 마지막 점을 누락하므로,
    // 2점 직선(정지 직선화된 마커)은 moveTo만 남아 빈 path가 되고,
    // N점 스트로크도 마지막 세그먼트가 끝점에 닿지 않는다.
    final last = stroke.points.last;
    path.lineTo(last.x, last.y);
    return path;
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
    }
    final path = Path();
    path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
    for (int i = 1; i < outlinePoints.length - 1; ++i) {
      final p0 = outlinePoints[i];
      final p1 = outlinePoints[i + 1];
      path.quadraticBezierTo(p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    }
    // outline 마지막 점까지 연결 후 윤곽을 닫는다.
    // 루프가 `length - 1`까지만 돌아 마지막 outline 점을 누락하면
    // 직선화된 스트로크의 끝(첫 점→마지막 점 방향)이 채워지지 않는다.
    final last = outlinePoints.last;
    path.lineTo(last.x, last.y);
    path.close();
    return path;
  }
}
