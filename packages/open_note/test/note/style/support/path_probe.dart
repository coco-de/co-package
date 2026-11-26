import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Points every [step] units along every contour of [path], ends included.
List<Offset> samplePath(Path path, {double step = 0.5}) => [
  for (final metric in path.computeMetrics())
    for (var i = 0; i <= (metric.length / step).ceil(); i++)
      metric.getTangentForOffset(math.min(i * step, metric.length))!.position,
];

/// Total length of all contours of [path].
double pathLength(Path path) =>
    path.computeMetrics().fold(0, (sum, metric) => sum + metric.length);

/// The tight bounds of the curves of [path] (from samples).
Rect sampledBounds(Path path) {
  final points = samplePath(path, step: 0.25);

  return Rect.fromLTRB(
    points.map((p) => p.dx).reduce(math.min),
    points.map((p) => p.dy).reduce(math.min),
    points.map((p) => p.dx).reduce(math.max),
    points.map((p) => p.dy).reduce(math.max),
  );
}

/// How many contours [path] has.
int contourCount(Path path) => path.computeMetrics().length;

/// Whether every sampled point of [path] lies in [rect], give or take
/// [tolerance].
void expectInside(
  Path path,
  Rect rect, {
  double tolerance = 0.01,
  String? reason,
}) {
  final room = rect.inflate(tolerance);
  for (final point in samplePath(path)) {
    expect(
      point.dx >= room.left &&
          point.dx <= room.right &&
          point.dy >= room.top &&
          point.dy <= room.bottom,
      isTrue,
      reason: '$point is outside $rect (${reason ?? ''})',
    );
  }
}

/// Matches an [Offset] within [tolerance].
Matcher closeToOffset(Offset expected, [double tolerance = 1e-3]) =>
    predicate<Offset>(
      (actual) => (actual - expected).distance <= tolerance,
      'is within $tolerance of $expected',
    );
