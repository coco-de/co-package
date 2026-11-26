import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/tools/internal/note_tools_numbers.dart';

/// A colour as hue, saturation, value and alpha (sRGB).
///
/// Values read from this object are normalised: [h] is in `[0, 360)` degrees
/// (360 wraps to 0) and [s], [v] and [a] are in `[0, 1]`. NaN or infinity
/// reads as 0 (1 for [a]).
///
/// [toColor] rounds to 8 bits per channel, so converting an 8-bit colour with
/// [NoteHsv.fromColor] and back returns the same colour. Greys have no hue and
/// black has neither hue nor saturation, so a picker must keep those itself.
@immutable
class NoteHsv {
  final double _h;

  final double _s;

  final double _v;
  final double _a;

  /// Creates a colour from its components.
  const NoteHsv({
    required double h,
    required double s,
    required double v,
    double a = 1,
  }) : _h = h,
       _s = s,
       _v = v,
       _a = a;

  /// The HSV form of [color]; greys get hue 0.
  factory NoteHsv.fromColor(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;
    final high = math.max(r, math.max(g, b));
    final delta = high - math.min(r, math.min(g, b));

    return NoteHsv(
      h: _hueOf(r, g, b, high: high, delta: delta),
      s: high <= 0 ? 0 : delta / high,
      v: high,
      a: color.a,
    );
  }

  /// Hue in degrees.
  double get h {
    if (!_h.isFinite) return 0;
    final wrapped = _h % 360;

    return wrapped >= 360 ? 0 : wrapped;
  }

  /// Saturation: 0 is grey, 1 fully saturated.
  double get s => noteClampOr(_s, min: 0, max: 1, fallback: 0);

  /// Value (brightness): 0 is black.
  double get v => noteClampOr(_v, min: 0, max: 1, fallback: 0);

  /// Opacity.
  double get a => noteClampOr(_a, min: 0, max: 1, fallback: 1);

  @override
  int get hashCode => Object.hash(h, s, v, a);

  /// The RGB colour, rounded to 8 bits per channel.
  Color toColor() {
    final chroma = v * s;
    final sector = h / 60;
    final second = chroma * (1 - (sector % 2 - 1).abs());
    final (r, g, b) = switch (sector.floor()) {
      0 => (chroma, second, 0.0),
      1 => (second, chroma, 0.0),
      2 => (0.0, chroma, second),
      3 => (0.0, second, chroma),
      4 => (second, 0.0, chroma),
      _ => (chroma, 0.0, second),
    };
    final base = v - chroma;

    return Color.fromARGB(
      _byte(a),
      _byte(r + base),
      _byte(g + base),
      _byte(b + base),
    );
  }

  /// A copy with the given components replaced.
  NoteHsv copyWith({double? h, double? s, double? v, double? a}) =>
      NoteHsv(h: h ?? this.h, s: s ?? this.s, v: v ?? this.v, a: a ?? this.a);

  @override
  bool operator ==(Object other) =>
      other is NoteHsv &&
      other.h == h &&
      other.s == s &&
      other.v == v &&
      other.a == a;

  @override
  String toString() => 'NoteHsv(h: $h, s: $s, v: $v, a: $a)';

  static double _hueOf(
    double r,
    double g,
    double b, {
    required double high,
    required double delta,
  }) {
    if (delta <= 0) return 0;
    if (high == r) return 60 * (((g - b) / delta) % 6);
    if (high == g) return 60 * ((b - r) / delta + 2);

    return 60 * ((r - g) / delta + 4);
  }

  static int _byte(double channel) => (channel * 255).round().clamp(0, 255);
}
