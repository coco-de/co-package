// 🎯 Dart imports:
import 'dart:math';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/point_calculator.dart';
import '../../data/model/protobuf/scribble.pb.dart';

/// Get an array of points describing a polygon that surrounds the input [line].
List<Point> getStroke(Stroke line) {
  return getStrokeOutlinePoints(
    getStrokePoints(line.points, options: line.options),
    options: line.options,
  );
}

/// Get the stroke's radius, given its size, thinning and p.
double getStrokeRadius(double size, double thinning, double p) {
  return size * (0.5 - thinning * (0.5 - p));
}

/// Get an array of points as objects with an adjusted point, p, vector, distance, and runningLength for the provided [points]. Used internally by `getStroke` but possibly of separate interest. Can be passed to `getStrokeOutlinePoints`.
List<StrokePoint> getStrokePoints(
  List<Point> points, {
  required StrokeOptions options,
}) {
  if (points.isEmpty) return [];

  final t = 0.15 + (1 - options.streamline) * 0.85;

  List<Point> pts = points;

  if (pts.length == 1) {
    pts = pts.toList();
    pts.add(Point(x: pts[0].x + 1, y: pts[0].y + 1, p: pts[0].p));
  }

  final strokePoints = <StrokePoint>[];

  var prev = StrokePoint(
    point: pts[0],
    vector: Point(x: 1, y: 1),
    distance: 0,
    runningLength: 0,
  );

  strokePoints.add(prev);

  Point point;

  double distance;

  double runningLength = 0;

  bool hasReachedMinimumLength = false;

  for (var i = 1; i < pts.length; i++) {
    if (options.isComplete && i == pts.length - 1) {
      point = pts[i];
    } else {
      point = lerp(prev.point, pts[i], t);

      if (!options.simulatePressure) {
        // Use real pressure.
        point = Point(x: point.x, y: point.y, p: pts[i].p);
      }
    }

    if (isEqual(point, prev.point)) {
      continue;
    }

    distance = dist(point, prev.point);

    runningLength += distance;

    if (i < pts.length - 1 && !hasReachedMinimumLength) {
      if (runningLength < options.size) {
        continue;
      }
      hasReachedMinimumLength = true;
    }

    prev = StrokePoint(
      point: point,
      vector: uni(sub(prev.point, point)),
      distance: distance,
      runningLength: runningLength,
    );

    strokePoints.add(prev);
  }

  if (strokePoints.length > 1) {
    strokePoints[0] = StrokePoint(
      point: strokePoints[0].point,
      vector: strokePoints[1].vector,
      distance: strokePoints[0].distance,
      runningLength: strokePoints[0].runningLength,
    );
  }

  return strokePoints;
}

const double rateOfPressureChange = 0.275;

/// Get an array of points representing the outline of a stroke, based on the provided [points]. Used internally by `getStroke` but possibly of separate interest. Accepts the result of `getStrokeOutlinePoints`.
///
/// The [size] argument sets the base diameter for the shape.
///
/// The [thinning] argument sets the effect of p on the stroke's size.
///
/// The [smoothing] argument sets the density of points along the stroke's edges.
///
/// The [streamline] argument sets the level of variation allowed in the input points.
///
/// The [taperStart] argument sets the distance to taper the front of the stroke.
///
/// The [capStart] argument sets whether to add a cap to the start of the stroke.
///
/// The [taperEnd] argument sets the distance to taper the end of the stroke.
///
/// The [capEnd] argument sets whether to add a cap to the end of the stroke.
///
/// The [simulatePressure] argument sets whether to simulate p or use the point's provided ps.
///
/// The [isComplete] argument sets whether the line is complete.
List<Point> getStrokeOutlinePoints(
  List<StrokePoint> points, {
  required StrokeOptions options,
}) {
  if (points.isEmpty || options.size < 0) return [];

  final totalLength = points.last.runningLength;

  final minDistance = pow(options.size * options.smoothing, 2);

  final leftPts = <Point>[];

  final rightPts = <Point>[];

  double prevPressure = points[0].point.p;

  double sp;

  double rp;

  for (var i = 0; i < min(10, points.length); i++) {
    var p = points[i].point.p;

    if (options.simulatePressure) {
      sp = min(1, points[i].distance / options.size);

      rp = min(1, 1 - sp);

      p = min(
        1,
        prevPressure + (rp - prevPressure) * (sp * rateOfPressureChange),
      );
    }

    prevPressure = (prevPressure + p) / 2;
  }

  double radius = getStrokeRadius(
    options.size,
    options.thinning,
    points.last.point.p,
  );
  double? firstRadius;

  var prevVector = points[0].vector;

  var pl = points[0].point;

  var pr = pl;

  var tl = pl;

  var tr = pr;

  Point nextVector;

  Point offset;

  double nextDpr;

  double ts;

  double te;

  for (var i = 0; i < points.length - 1; i++) {
    final curr = points[i];

    if (totalLength - curr.runningLength < 3) continue;
    // Pressure
    var p = curr.point.p;

    if (options.thinning != 0) {
      if (options.simulatePressure) {
        sp = min(1, curr.distance / options.size);
        rp = min(1, 1 - sp);
        p = min(
          1,
          prevPressure + (rp - prevPressure) * (sp * rateOfPressureChange),
        );
        radius = getStrokeRadius(options.size, options.thinning, p);
      } else {
        radius = getStrokeRadius(options.size, options.thinning, p);
      }
    }

    firstRadius ??= radius;

    ts = curr.runningLength < options.taperStart
        ? curr.runningLength / options.taperStart
        : 1;
    te = totalLength - curr.runningLength < options.taperEnd
        ? (totalLength - curr.runningLength) / options.taperEnd
        : 1;
    radius = max(0.01, radius * min(ts, te));

    // Left and Right Points

    nextVector = points[i + 1].vector;

    nextDpr = dpr(curr.vector, nextVector);

    if (nextDpr < 0) {
      // Sharp Corner

      final offset = mul(per(prevVector), radius);

      const step = 1 / 13;

      for (double t = 0; t <= 1; t += step) {
        tl = rotAround(sub(curr.point, offset), curr.point, pi * t);
        leftPts.add(tl);
        tr = rotAround(add(curr.point, offset), curr.point, pi * -t);
        rightPts.add(tr);
      }

      pl = tl;

      pr = tr;

      continue;
    }

    // Regular points

    offset = mul(per(lerp(nextVector, curr.vector, nextDpr)), radius);

    tl = sub(curr.point, offset);

    if (i == 0 || dist2(pl, tl) > minDistance) {
      leftPts.add(tl);
      pl = tl;
    }

    tr = add(curr.point, offset);

    if (i == 0 || dist2(pr, tr) > minDistance) {
      rightPts.add(tr);
      pr = tr;
    }

    prevPressure = p;

    prevVector = curr.vector;
  }

  final firstPoint = points.first.point;

  final lastPoint = () {
    return points.length > 1
        ? points.last.point
        : add(firstPoint, Point(x: 1, y: 1));
  }();

  final isVeryShort = leftPts.length <= 1 || rightPts.length <= 1;

  final startCap = <Point>[];

  final endCap = <Point>[];

  if (isVeryShort) {
    if (!(options.taperStart > 0 || options.taperEnd > 0) ||
        options.isComplete) {
      final start = prj(
        firstPoint,
        uni(per(sub(firstPoint, lastPoint))),
        -(firstRadius ??= radius),
      );

      final dotPts = <Point>[];

      const step = 1 / 13;

      for (double t = step; t <= 1; t += step) {
        dotPts.add(rotAround(start, firstPoint, pi * 2 * t));
      }

      return dotPts;
    }
  } else {
    // Start Cap
    if (options.taperStart > 0 || (options.taperEnd > 0 && isVeryShort)) {
      // noop
    } else if (options.capStart) {
      const step = 1 / 13;

      for (double t = step; t <= 1; t += step) {
        startCap.add(rotAround(rightPts.first, firstPoint, pi * t));
      }
    } else {
      final cornersVector = sub(leftPts.first, rightPts.first);

      final offsetA = mul(cornersVector, .50);
      final offsetB = mul(cornersVector, .51);

      startCap.addAll([
        sub(firstPoint, offsetA),
        sub(firstPoint, offsetB),
        add(firstPoint, offsetB),
        add(firstPoint, offsetA),
      ]);
    }

    // End Cap

    final mid = med(leftPts.last, rightPts.last);

    final direction = per(uni(sub(lastPoint, mid)));

    if (options.taperEnd > 0 || (options.taperStart > 0 && isVeryShort)) {
      endCap.add(lastPoint);
    } else if (options.capEnd) {
      final start = prj(lastPoint, direction, radius);

      const step = 1 / 29;

      for (double t = 0; t <= 1; t += step) {
        endCap.add(rotAround(start, lastPoint, pi * 3 * t));
      }
    } else {
      endCap.addAll([
        sub(lastPoint, mul(direction, radius)),
        sub(lastPoint, mul(direction, radius * .99)),
        add(lastPoint, mul(direction, radius * .99)),
        add(lastPoint, mul(direction, radius)),
      ]);
    }
  }

  return [...leftPts, ...endCap, ...rightPts.reversed, ...startCap];
}
