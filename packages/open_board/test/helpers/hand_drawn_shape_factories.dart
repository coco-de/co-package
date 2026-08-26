import 'dart:math' as math;

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

import 'protobuf_factories.dart';

/// 실제 손가락/스타일러스 드로잉을 흉내낸 사각형 궤적 생성 (UB-555).
///
/// - 모서리를 [cornerRadiusRatio] 비율만큼 둥글게 굴린다 (완벽한 직각 대신).
/// - 각 점에 [jitterRatio] 비율의 수직 방향 노이즈를 더한다 (손떨림).
/// - 시작/끝 사이에 약간의 간격을 남긴다 (완벽히 맞물려 닫지 않음).
List<Point> handDrawnRectanglePoints({
  required double left,
  required double top,
  required double right,
  required double bottom,
  required math.Random rng,
  double jitterRatio = 0.02,
  double cornerRadiusRatio = 0.08,
  int pointsPerSide = 25,
  double gapRatio = 0.03,
}) {
  final w = right - left;
  final h = bottom - top;
  final side = math.min(w, h);
  final r = side * cornerRadiusRatio;
  final jitter = side * jitterRatio;

  final centers = [
    [left + r, top + r], // top-left
    [right - r, top + r], // top-right
    [right - r, bottom - r], // bottom-right
    [left + r, bottom - r], // bottom-left
  ];
  final cornerAngles = [
    [math.pi, math.pi * 1.5],
    [math.pi * 1.5, math.pi * 2],
    [0.0, math.pi * 0.5],
    [math.pi * 0.5, math.pi],
  ];
  final rawEdges = <List<double>>[
    [left + r, top, right - r, top],
    [right, top + r, right, bottom - r],
    [right - r, bottom, left + r, bottom],
    [left, bottom - r, left, top + r],
  ];

  final points = <Point>[];
  void addJittered(double x, double y, double nx, double ny) {
    final j = (rng.nextDouble() * 2 - 1) * jitter;
    points.add(createPoint(x: x + nx * j, y: y + ny * j));
  }

  for (var edgeIndex = 0; edgeIndex < 4; edgeIndex++) {
    final e = rawEdges[edgeIndex];
    final dx = e[2] - e[0];
    final dy = e[3] - e[1];
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = len == 0 ? 0.0 : -dy / len;
    final ny = len == 0 ? 0.0 : dx / len;
    for (var i = 0; i < pointsPerSide; i++) {
      final t = i / pointsPerSide;
      addJittered(e[0] + dx * t, e[1] + dy * t, nx, ny);
    }
    // 이 변의 끝을 다음 변의 시작과 잇는 코너 아크.
    final nextCorner = (edgeIndex + 1) % 4;
    final c = centers[nextCorner];
    final a = cornerAngles[nextCorner];
    const cornerSteps = 6;
    for (var i = 0; i <= cornerSteps; i++) {
      final t = a[0] + (a[1] - a[0]) * (i / cornerSteps);
      addJittered(
        c[0] + r * math.cos(t),
        c[1] + r * math.sin(t),
        math.cos(t),
        math.sin(t),
      );
    }
  }

  final gap = side * gapRatio;
  if (points.isNotEmpty && gap > 0) {
    final first = points.first;
    final last = points.last;
    final dx = first.x - last.x;
    final dy = first.y - last.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > gap) {
      final t = (len - gap) / len;
      points[points.length - 1] = createPoint(
        x: last.x + dx * t,
        y: last.y + dy * t,
      );
    }
  }

  return points;
}

/// 손으로 그린 것처럼 지터를 가진 삼각형 궤적 생성 (UB-555).
List<Point> handDrawnTrianglePoints({
  required List<List<double>> vertices,
  required math.Random rng,
  double jitterRatio = 0.02,
  int pointsPerSide = 20,
}) {
  final points = <Point>[];
  final cx = (vertices[0][0] + vertices[1][0] + vertices[2][0]) / 3;
  final cy = (vertices[0][1] + vertices[1][1] + vertices[2][1]) / 3;
  double approxSize = 0;
  for (final v in vertices) {
    approxSize = math.max(
      approxSize,
      math.sqrt(math.pow(v[0] - cx, 2) + math.pow(v[1] - cy, 2)),
    );
  }
  final jitter = approxSize * jitterRatio;
  for (var v = 0; v < 3; v++) {
    final a = vertices[v];
    final b = vertices[(v + 1) % 3];
    for (var i = 0; i < pointsPerSide; i++) {
      final t = i / pointsPerSide;
      final x = a[0] + (b[0] - a[0]) * t;
      final y = a[1] + (b[1] - a[1]) * t;
      final j = (rng.nextDouble() * 2 - 1) * jitter;
      points.add(createPoint(x: x + j, y: y + j));
    }
  }
  points.add(createPoint(x: vertices.first[0], y: vertices.first[1]));
  return points;
}

/// 손으로 그린 것처럼 반경이 살짝 흔들리는 원 궤적 생성 (UB-555).
List<Point> handDrawnCirclePoints({
  required double centerX,
  required double centerY,
  required double radius,
  required math.Random rng,
  double jitterRatio = 0.03,
  int numPoints = 60,
}) {
  final points = <Point>[];
  final jitter = radius * jitterRatio;
  for (var i = 0; i < numPoints; i++) {
    final t = i / numPoints * 2 * math.pi;
    final j = (rng.nextDouble() * 2 - 1) * jitter;
    final r = radius + j;
    points.add(
      createPoint(x: centerX + r * math.cos(t), y: centerY + r * math.sin(t)),
    );
  }
  return points;
}
