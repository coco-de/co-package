import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_line_smoother.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_line_waves.dart';
import 'package:open_note/src/note/style/note_polyline.dart';
import 'package:open_note/src/note/style/note_styled_path.dart';

/// Pure line geometry: smoothing of pen input, and the paths that draw a
/// polyline in a [NoteLineStyle]. All lengths are in the coordinates of the
/// points.
abstract final class NoteLinePath {
  /// Upper bound on the dashes, wave samples or zigzag vertices made for one
  /// line; beyond it the pattern is stretched.
  static const int maxSegments = 20000;

  static const double _miterLimit = 0.35;

  /// De-noises a raw pen polyline and resamples it along a centripetal
  /// Catmull-Rom spline about every [sampleSpacing] units.
  ///
  /// The first and last points are kept exactly, non-finite points are dropped,
  /// samples closer than 0.5 units are merged and no input point is pulled more
  /// than 1.5 units. Fewer than three usable points come back as they are.
  static List<Offset> smooth(List<Offset> points, {double sampleSpacing = 2}) =>
      NoteLineSmoother.smooth(points, sampleSpacing: sampleSpacing);

  /// The strokes that draw the polyline [points] with pen [width] in [style].
  ///
  /// The polyline is decorated as given (call [smooth] first for raw pen
  /// input). `dashed`, `dotted`, `wavy` and `zigzag` return one path and
  /// `double` two parallel ones, each [width] wide. With [closed] the last point
  /// joins the first (three or more distinct points). A single point (or a line
  /// of zero length) gives one round dot; no point or a [width] that is not a
  /// positive finite number gives an empty list. Non-finite points are
  /// ignored.
  static List<NoteStyledPath> renderPaths(
    List<Offset> points,
    double width,
    NoteLineStyle style, {
    bool closed = false,
  }) {
    final line = NotePolyline(points, closed: closed);
    if (line.points.isEmpty || !width.isFinite || width <= 0) return const [];
    if (line.length <= 0) return [_dot(line.points.first, width)];

    return switch (style.kind) {
      NoteLineStyleKind.solid => [
        _stroke(_basePath(line), width, StrokeCap.round),
      ],
      NoteLineStyleKind.dashed => [_dashes(line, width, style, StrokeCap.butt)],
      NoteLineStyleKind.dotted => [
        _dashes(line, width, style, StrokeCap.round),
      ],
      NoteLineStyleKind.wavy => [_wave(line, width, style)],
      NoteLineStyleKind.zigzag => [_zigzag(line, width, style)],
      NoteLineStyleKind.double => _doubleLines(line, width, style),
    };
  }

  /// The path through [points] with straight segments.
  static Path polylinePath(List<Offset> points, {bool closed = false}) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (closed) path.close();

    return path;
  }

  /// Cuts [source] (any path, curves included) into dashes of [dashLength]
  /// separated by [gap], restarting on every contour. Lengths that are not
  /// positive return a copy of [source].
  static Path dashPath(Path source, double dashLength, double gap) {
    if (!(dashLength > 0) || !(gap > 0)) return Path.from(source);
    final result = Path();
    for (final metric in source.computeMetrics()) {
      final natural = dashLength + gap;
      final period = math.max(natural, metric.length / maxSegments);
      final dash = dashLength * period / natural;
      for (var i = 0; i * period < metric.length; i++) {
        final start = i * period;
        result.addPath(
          metric.extractPath(start, math.min(start + dash, metric.length)),
          Offset.zero,
        );
      }
    }

    return result;
  }

  /// [points] moved sideways by [distance] with mitred corners. A positive
  /// [distance] goes to the quarter-turn side of the walking direction (below a
  /// left-to-right line on screen). Very sharp corners are capped at about three
  /// times [distance].
  static List<Offset> offsetPolyline(
    List<Offset> points,
    double distance, {
    bool closed = false,
  }) {
    final line = NotePolyline(points, closed: closed);
    if (line.points.length < 2) return List.of(line.points);

    return [
      for (var i = 0; i < line.points.length; i++)
        line.points[i] + _miter(line, i) * distance,
    ];
  }

  static Offset _miter(NotePolyline line, int index) {
    final points = line.points;
    final count = points.length;
    final previous = index > 0 || line.closed
        ? _segmentNormal(points[(index - 1 + count) % count], points[index])
        : null;
    final next = index < count - 1 || line.closed
        ? _segmentNormal(points[index], points[(index + 1) % count])
        : null;
    if (previous == null) return next!;
    if (next == null) return previous;
    final sum = previous + next;
    if (sum.distance < 1e-6) return next;
    final bisector = sum / sum.distance;
    final cosine = bisector.dx * next.dx + bisector.dy * next.dy;

    return bisector / math.max(cosine, _miterLimit);
  }

  static Offset _segmentNormal(Offset from, Offset to) {
    final delta = to - from;

    return Offset(-delta.dy, delta.dx) / delta.distance;
  }

  static NoteStyledPath _stroke(Path path, double width, StrokeCap cap) =>
      NoteStyledPath(path: path, strokeWidth: width, cap: cap);

  static Path _basePath(NotePolyline line) =>
      polylinePath(line.points, closed: line.closed);

  static NoteStyledPath _dot(Offset point, double width) => _stroke(
    polylinePath([point, point + const Offset(0.01, 0)]),
    width,
    StrokeCap.round,
  );

  static NoteStyledPath _dashes(
    NotePolyline line,
    double width,
    NoteLineStyle style,
    StrokeCap cap,
  ) => _stroke(
    dashPath(_basePath(line), style.dashLength * width, style.gap * width),
    width,
    cap,
  );

  static NoteStyledPath _wave(
    NotePolyline line,
    double width,
    NoteLineStyle style,
  ) => _stroke(
    polylinePath(
      NoteLineWaves.sine(
        line,
        amplitude: style.amplitude * width,
        wavelength: style.wavelength * width,
        maxSamples: maxSegments,
      ),
      closed: line.closed,
    ),
    width,
    StrokeCap.round,
  );

  static NoteStyledPath _zigzag(
    NotePolyline line,
    double width,
    NoteLineStyle style,
  ) => _stroke(
    polylinePath(
      NoteLineWaves.triangle(
        line,
        amplitude: style.amplitude * width,
        wavelength: style.wavelength * width,
        maxSamples: maxSegments,
      ),
      closed: line.closed,
    ),
    width,
    StrokeCap.round,
  );

  static List<NoteStyledPath> _doubleLines(
    NotePolyline line,
    double width,
    NoteLineStyle style,
  ) {
    final offset = (width + style.doubleGap * width) / 2;

    return [
      for (final side in const [-1.0, 1.0])
        _stroke(
          polylinePath(
            offsetPolyline(line.points, side * offset, closed: line.closed),
            closed: line.closed,
          ),
          width,
          StrokeCap.round,
        ),
    ];
  }
}
