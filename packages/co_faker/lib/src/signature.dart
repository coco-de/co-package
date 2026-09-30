import 'dart:convert';
import 'dart:math' as math;

import 'co_faker.dart';

/// One sampled point of a pen stroke.
///
/// [x] and [y] are in the canvas coordinate space (origin top-left), [p] is
/// the pen pressure in `0..1`, and [t] is the timestamp in milliseconds
/// since the epoch. The fields match the `Point` message of `open_board`
/// (`x`, `y`, `p`, `timestamp`), see [CoFakerSignature.toOpenBoardPoints].
typedef CoInkPoint = ({double x, double y, double p, int t});

/// A stroke: the points between a pen-down and a pen-up.
typedef CoInkStroke = List<CoInkPoint>;

/// Generates handwritten-looking signature strokes.
///
/// A signature is two to four cursive-like strokes made of summed sine
/// waves and small loops. It is not a real signature and does not imitate
/// anyone's handwriting; it only fills signature fields in demos, widget
/// tests, and golden files. Output is deterministic: the same seed and
/// clock (or the same `name`) always produce the same points.
class CoFakerSignature {
  /// Creates a signature generator backed by [faker].
  CoFakerSignature(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// Generates signature strokes inside a [width] x [height] canvas.
  ///
  /// With [name] the strokes come from a stream derived from the seed and
  /// the name, so a person keeps the same signature no matter how many
  /// values were drawn before. Timestamps start at `faker.now`, with about
  /// 8-16 ms between points and a short pause between strokes.
  List<CoInkStroke> strokes({
    double width = 300,
    double height = 100,
    int? strokeCount,
    String? name,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be greater than zero');
    }
    final random = name == null
        ? faker.random
        : faker.derive('signature/$name').random;
    final count = strokeCount ?? random.int(min: 2, max: 4);
    if (count < 1) {
      throw ArgumentError.value(strokeCount, 'strokeCount', 'must be >= 1');
    }
    var time = faker.now.millisecondsSinceEpoch;
    var cursor = width * 0.08;
    final slot = width * 0.84 / count;
    final result = <CoInkStroke>[];
    for (var s = 0; s < count; s++) {
      final span = slot * random.double(min: 0.75, max: 1.0);
      final amp = height * random.double(min: 0.14, max: 0.3);
      final freq = random.double(min: 1.5, max: 4);
      final phase = random.double(max: math.pi);
      final loops = random.int(max: 2);
      final samples = (span / 3).clamp(12, 120).round();
      final stroke = <CoInkPoint>[];
      for (var i = 0; i <= samples; i++) {
        final t = i / samples;
        final loopX = loops > 0 ? math.cos(t * math.pi * 2 * loops) * 6 : 0.0;
        final loopY = loops > 0 ? math.sin(t * math.pi * 2 * loops) * 8 : 0.0;
        final x = cursor + span * t + loopX;
        final y =
            height * 0.55 +
            amp * math.sin(t * math.pi * 2 * freq + phase) * (1 - t * 0.4) +
            loopY;
        final pressure =
            0.35 + 0.55 * math.sin(t * math.pi) + random.double(max: 0.1);
        stroke.add((
          x: _round(x.clamp(0, width).toDouble(), 1),
          y: _round(y.clamp(0, height).toDouble(), 1),
          p: _round(pressure.clamp(0.1, 1).toDouble(), 2),
          t: time,
        ));
        time += random.int(min: 8, max: 16);
      }
      result.add(stroke);
      cursor += span + slot * 0.1;
      time += random.int(min: 120, max: 320);
    }
    return result;
  }

  /// Generates a signature as an offline SVG `data:` URI (transparent
  /// background), ready for `Image.network`, `<img>`, or golden tests.
  String dataUri({
    double width = 300,
    double height = 100,
    String? name,
    String color = '#1E2A78',
  }) {
    return svgDataUri(
      strokes(width: width, height: height, name: name),
      width: width,
      height: height,
      color: color,
    );
  }

  /// Converts [strokes] to an SVG path `d` attribute (`M x y L x y ...`).
  static String svgPath(List<CoInkStroke> strokes) {
    return strokes
        .where((stroke) => stroke.isNotEmpty)
        .map((stroke) {
          final first = stroke.first;
          final rest = stroke.skip(1).map((p) => 'L${p.x} ${p.y}').join(' ');
          return 'M${first.x} ${first.y} $rest'.trim();
        })
        .join(' ');
  }

  /// Renders [strokes] as an SVG `data:image/svg+xml;base64,` URI.
  static String svgDataUri(
    List<CoInkStroke> strokes, {
    double width = 300,
    double height = 100,
    String color = '#1E2A78',
    double strokeWidth = 2.2,
  }) {
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="${_fmt(width)}" '
        'height="${_fmt(height)}" viewBox="0 0 ${_fmt(width)} '
        '${_fmt(height)}"><path d="${svgPath(strokes)}" fill="none" '
        'stroke="$color" stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round"/></svg>';
    return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
  }

  /// Converts [strokes] to JSON-ready maps shaped like `open_board`'s
  /// `Point` (`x`, `y`, `p`, `timestamp`), one list per stroke.
  ///
  /// [width] and [height] scale the coordinates, which turns normalized
  /// `0..1` marks (such as `clinic.canvasMarks`) into canvas pixels.
  static List<List<Map<String, Object>>> toOpenBoardPoints(
    List<CoInkStroke> strokes, {
    double width = 1,
    double height = 1,
  }) {
    return <List<Map<String, Object>>>[
      for (final stroke in strokes)
        <Map<String, Object>>[
          for (final point in stroke)
            <String, Object>{
              'x': _round(point.x * width, 2),
              'y': _round(point.y * height, 2),
              'p': point.p,
              'timestamp': point.t,
            },
        ],
    ];
  }

  static double _round(double value, int digits) =>
      double.parse(value.toStringAsFixed(digits));

  static String _fmt(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
