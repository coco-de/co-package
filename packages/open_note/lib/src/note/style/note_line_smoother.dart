import 'dart:math' as math;
import 'dart:ui';

/// The smoothing behind `NoteLinePath.smooth`. Internal: not exported by the
/// module barrel.
abstract final class NoteLineSmoother {
  static const double _minSpacing = 0.5;
  static const double _maxShift = 1.5;
  static const double _defaultSampleSpacing = 2;
  static const int _maxSamplesPerSegment = 24;
  static const double _minKnotStep = 1e-4;

  /// See `NoteLinePath.smooth`.
  static List<Offset> smooth(List<Offset> points, {double sampleSpacing = 2}) {
    final finite = [
      for (final point in points)
        if (point.isFinite) point,
    ];
    if (finite.length < 3) return finite;
    final thinned = _thin(finite);
    if (thinned.length < 3) return thinned;
    final spacing = sampleSpacing.isFinite && sampleSpacing > 0
        ? sampleSpacing
        : _defaultSampleSpacing;

    return _spline(_denoise(thinned), spacing);
  }

  /// Drops samples closer than [_minSpacing], keeping both end points.
  static List<Offset> _thin(List<Offset> points) {
    final result = <Offset>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      if ((points[i] - result.last).distance >= _minSpacing) {
        result.add(points[i]);
      }
    }
    final end = points.last;
    while (result.length > 1 && (result.last - end).distance < _minSpacing) {
      result.removeLast();
    }
    result.add(end);

    return result;
  }

  /// Pulls interior points towards their neighbours, never further than
  /// [_maxShift], so jitter fades while sharp corners of sparse input stay.
  static List<Offset> _denoise(List<Offset> points) => [
    points.first,
    for (var i = 1; i < points.length - 1; i++)
      points[i] + _limit((points[i - 1] + points[i + 1]) / 4 - points[i] / 2),
    points.last,
  ];

  static Offset _limit(Offset shift) {
    final distance = shift.distance;

    return distance <= _maxShift ? shift : shift * (_maxShift / distance);
  }

  static List<Offset> _spline(List<Offset> points, double spacing) {
    final result = <Offset>[points.first];
    for (var i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      final before = i > 0 ? points[i - 1] : from * 2 - to;
      final after = i + 2 < points.length ? points[i + 2] : to * 2 - from;
      final samples = ((to - from).distance / spacing).ceil().clamp(
        1,
        _maxSamplesPerSegment,
      );
      for (var k = 1; k < samples; k++) {
        result.add(_catmullRom(before, from, to, after, k / samples));
      }
      result.add(to);
    }

    return result;
  }

  /// A point of the centripetal Catmull-Rom segment between [b] and [c].
  static Offset _catmullRom(
    Offset a,
    Offset b,
    Offset c,
    Offset d,
    double fraction,
  ) {
    final t1 = _knot(a, b);
    final t2 = t1 + _knot(b, c);
    final t3 = t2 + _knot(c, d);
    final t = t1 + (t2 - t1) * fraction;
    final a1 = _blend(a, b, 0, t1, t);
    final a2 = _blend(b, c, t1, t2, t);
    final a3 = _blend(c, d, t2, t3, t);
    final b1 = _blend(a1, a2, 0, t2, t);
    final b2 = _blend(a2, a3, t1, t3, t);

    return _blend(b1, b2, t1, t2, t);
  }

  static double _knot(Offset from, Offset to) =>
      math.max(math.sqrt((to - from).distance), _minKnotStep);

  static Offset _blend(
    Offset from,
    Offset to,
    double start,
    double end,
    double t,
  ) {
    final span = end - start;

    return from * ((end - t) / span) + to * ((t - start) / span);
  }
}
