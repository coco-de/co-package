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

/// Get an array of points as objects with an adjusted point, p, vector,
/// distance, and runningLength for the provided [points].
///
/// perfect_freehand 2.5.x 정렬:
///   - 2점 stroke 일 때 4개 보간점을 추가하여 tapered start/end의 "dash" 라인
///     아티팩트를 제거.
///   - 두 입력 점이 동일하면 1점으로 축소 후 1pt 오프셋 처리.
List<StrokePoint> getStrokePoints(
  List<Point> points, {
  required StrokeOptions options,
}) {
  if (points.isEmpty) return [];

  final t = 0.15 + (1 - options.streamline) * 0.85;

  // 입력 리스트를 mutate 하지 않도록 필요한 경우 새 리스트로 교체.
  List<Point> pts = points;

  // 두 입력 점이 동일 좌표인 경우 1점으로 축소.
  if (pts.length == 2 && isEqual(pts[0], pts[1])) {
    pts = <Point>[pts[0]];
  }

  // 2점 stroke: 보간점 4개를 추가해 매끄럽게 (perfect_freehand 2.5.0).
  if (pts.length == 2) {
    final first = pts[0];
    final last = pts[1];
    pts = <Point>[first];
    for (int i = 1; i < 5; i++) {
      pts.add(lerp(first, last, i / 4));
    }
  }

  // 1점 stroke: 1pt 오프셋 점을 추가.
  if (pts.length == 1) {
    pts = <Point>[pts[0], Point(x: pts[0].x + 1, y: pts[0].y + 1, p: pts[0].p)];
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

/// Get an array of points representing the outline of a stroke, based on the
/// provided [points].
///
/// perfect_freehand 2.5.x 정렬:
///   - sharp corner 임계값을 `dpr < 0` → `dpr < size/128`로 완화하고,
///     이전/다음 vector 모두를 검사 (직각·약간 둔각도 sharp 처리).
///   - sharp corner 처리 후 좌/우를 reflect 하여 다음 segment와 자연스럽게 연결.
///   - 같은 코너가 두 번 sharp 로 감지되지 않도록 `isPrevPointSharpCorner` 추적.
///   - 끝부분 noise 제거 임계값을 `< 3`(하드코딩) → `< size/2` 그리고
///     `isComplete` 일 때만 적용 (그리는 도중 깜빡임 감소).
///   - 마지막 점도 루프 안에서 inline 처리.
///   - end cap direction을 `per(-points.last.vector)`로 단순화.
///   - `pow(x, 2)` → `x * x` 핫루프 마이크로 최적화.
List<Point> getStrokeOutlinePoints(
  List<StrokePoint> points, {
  required StrokeOptions options,
}) {
  if (points.isEmpty || options.size <= 0) return [];

  final size = options.size;
  final totalLength = points.last.runningLength;

  // Performance: avoid pow() in hot path.
  final smoothingScale = size * options.smoothing;
  final minDistance = smoothingScale * smoothingScale;

  // Sharp corner threshold (perfect_freehand 2.5.0).
  // dpr 가 이 값보다 작으면 sharp corner 로 취급.
  final maxDprForSharpCorner = size / 128;

  final leftPts = <Point>[];
  final rightPts = <Point>[];

  // Smooth initial pressure: average first 10 distances' simulated pressures
  // to prevent fat starts.
  double prevPressure = points[0].point.p;
  {
    final upTo = min(10, points.length - 1);
    for (var i = 0; i < upTo; i++) {
      var p = points[i].point.p;
      if (options.simulatePressure) {
        final sp = min(1.0, points[i].distance / size);
        final rp = min(1.0, 1.0 - sp);
        p = min(
          1.0,
          prevPressure + (rp - prevPressure) * (sp * rateOfPressureChange),
        );
      }
      prevPressure = (prevPressure + p) / 2;
    }
  }

  final lastStrokePoint = points.last;
  double radius = getStrokeRadius(
    size,
    options.thinning,
    lastStrokePoint.point.p,
  );
  double? firstRadius;

  var prevVector = points[0].vector;

  var pl = points[0].point;

  var pr = pl;

  var tl = pl;

  var tr = pr;

  // Track sharp-corner state to avoid detecting the same corner twice.
  bool isPrevPointSharpCorner = false;

  for (var i = 0; i < points.length; i++) {
    final curr = points[i];
    final point = curr.point;
    final vector = curr.vector;
    final runningLength = curr.runningLength;

    // 끝부분 noise 제거: stroke 가 완성된 상태에서만, 그리고 sharp 직후가 아닐 때
    // 마지막 size/2 거리는 건너뛴다. 그리는 도중 적용하면 깜빡임 발생.
    if (i < points.length - 1 &&
        options.isComplete &&
        !isPrevPointSharpCorner &&
        totalLength - runningLength < size / 2) {
      continue;
    }

    // Pressure / radius
    var p = point.p;
    if (options.thinning != 0) {
      if (options.simulatePressure) {
        final sp = min(1.0, curr.distance / size);
        final rp = min(1.0, 1.0 - sp);
        p = min(
          1.0,
          prevPressure + (rp - prevPressure) * (sp * rateOfPressureChange),
        );
        prevPressure = p;
      }
      radius = getStrokeRadius(size, options.thinning, p);
    } else {
      radius = size / 2;
    }
    firstRadius ??= radius;

    // Tapering
    final ts = runningLength < options.taperStart
        ? runningLength / options.taperStart
        : 1.0;
    final te = totalLength - runningLength < options.taperEnd
        ? (totalLength - runningLength) / options.taperEnd
        : 1.0;
    radius = max(0.01, radius * min(ts, te));

    // Sharp corner detection (이전/다음 vector 모두 검사).
    final nextVector = i < points.length - 1 ? points[i + 1].vector : vector;
    final nextDpr = i < points.length - 1 ? dpr(vector, nextVector) : 1.0;
    final prevDpr = dpr(vector, prevVector);

    final isPointSharpCorner =
        prevDpr < maxDprForSharpCorner && !isPrevPointSharpCorner;
    final isNextPointSharpCorner = nextDpr < maxDprForSharpCorner;

    if (isPointSharpCorner || isNextPointSharpCorner) {
      // 코너에 둥근 cap 을 그리고, 좌/우 방향이 바뀌므로 reflect 한다.
      final prevOffset = mul(per(prevVector), radius);

      const step = 1 / 13;
      for (double t = 0; t <= 1; t += step) {
        tl = rotAround(sub(point, prevOffset), point, pi * t);
        leftPts.add(tl);
        tr = rotAround(add(point, prevOffset), point, pi * -t);
        rightPts.add(tr);
      }

      // 좌/우 reflect: 다음 segment 와 연결되도록 점 추가 (perfect_freehand 2.5.0).
      final nextOffset = mul(per(nextVector), radius);
      tl = rotAround(add(point, nextOffset), point, -pi);
      tr = rotAround(sub(point, nextOffset), point, pi);
      leftPts.add(tl);
      rightPts.add(tr);
      pl = tr;
      pr = tl;

      if (isNextPointSharpCorner) {
        isPrevPointSharpCorner = true;
      }
      continue;
    }

    isPrevPointSharpCorner = false;

    // 마지막 점은 inline 처리 (cap 계산은 루프 밖에서 별도로 처리).
    if (i == points.length - 1) {
      final offset = mul(per(vector), radius);
      leftPts.add(sub(point, offset));
      rightPts.add(add(point, offset));
      continue;
    }

    // Regular points
    final offset = mul(per(lerp(nextVector, vector, nextDpr)), radius);

    tl = sub(point, offset);

    if (i <= 1 || dist2(pl, tl) > minDistance) {
      leftPts.add(tl);
      pl = tl;
    }

    tr = add(point, offset);

    if (i <= 1 || dist2(pr, tr) > minDistance) {
      rightPts.add(tr);
      pr = tr;
    }

    prevVector = vector;
  }

  final firstStrokePoint = points.first;
  final firstPoint = firstStrokePoint.point;
  final pointsLength = points.length;

  final lastPoint = pointsLength > 1
      ? lastStrokePoint.point
      : add(firstPoint, firstStrokePoint.vector);

  final startCap = <Point>[];

  final endCap = <Point>[];

  // 매우 짧은 stroke (1점) 은 dot 처리.
  if (pointsLength == 1) {
    if (!(options.taperStart > 0 || options.taperEnd > 0) ||
        options.isComplete) {
      final start = prj(
        firstPoint,
        uni(per(sub(firstPoint, lastPoint))),
        -(firstRadius ?? radius),
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
    // (pointsLength == 1 분기는 위에서 이미 처리되었으므로 두 번째 조건은
    // 사실상 false 이지만, perfect_freehand 원본 가독성을 위해 명시 유지.)
    if (options.taperStart > 0 ||
        (options.taperEnd > 0 && pointsLength == 1)) {
      // tapered start - 추가 cap 점을 그리지 않는다 (의도된 no-op)
      assert(true, 'tapered start: noop');
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
  }

  // End cap direction: per(-points.last.vector). per((x,y))=(y,-x) 이므로
  // per((-x,-y)) = (-y, x). p 는 의미 없는 값이지만 expression 단순화를 위해 유지.
  final lv = lastStrokePoint.vector;
  final direction = Point(x: -lv.y, y: lv.x, p: lv.p);

  if (options.taperEnd > 0 || (options.taperStart > 0 && pointsLength == 1)) {
    endCap.add(lastPoint);
  } else if (options.capEnd) {
    final start = prj(lastPoint, direction, radius);

    const step = 1 / 29;

    for (double t = step; t <= 1; t += step) {
      endCap.add(rotAround(start, lastPoint, pi * 3 * t));
    }
  } else {
    endCap.addAll([
      add(lastPoint, mul(direction, radius)),
      add(lastPoint, mul(direction, radius * .99)),
      sub(lastPoint, mul(direction, radius * .99)),
      sub(lastPoint, mul(direction, radius)),
    ]);
  }

  return [...leftPts, ...endCap, ...rightPts.reversed, ...startCap];
}
