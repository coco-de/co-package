import 'dart:math' as math;

import 'package:open_board/src/core/algorithm/douglas_peucker.dart' as dp;
import 'package:open_board/open_board.dart';

extension ScribbleExtension on Scribble {
  Scribble setTolerance(double t) {
    final newScribble = Scribble.fromBuffer(writeToBuffer());
    for (final stroke in newScribble.strokes) {
      final newPoints = dp.DouglasPeucker.simplify(
        stroke.points.map((pt) => dp.Point(pt.x, pt.y)).toList(),
        tolerance: t,
        highestQuality: true,
      );
      stroke.points.clear();
      stroke.points.addAll(newPoints.map((pt) => Point(x: pt.x, y: pt.y)));
    }
    return newScribble;
  }

  int get totalPoints {
    var total = 0;
    for (final stroke in strokes) {
      total += stroke.points.length;
    }
    return total;
  }

  String getFileSize() {
    int bytes = writeToBuffer().length;
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
