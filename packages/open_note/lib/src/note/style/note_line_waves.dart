import 'dart:math' as math;
import 'dart:ui';

import 'package:open_note/src/note/style/note_polyline.dart';

/// The wave and zigzag decorations. Internal: not exported by the module
/// barrel.
abstract final class NoteLineWaves {
  /// Samples per half wave of a sine wave.
  static const int _samplesPerHalfWave = 8;

  /// A sine wave around [line]. The wavelength is stretched so a whole number
  /// of half waves fits, which puts both ends of an open line exactly on its
  /// end points and makes a closed line seamless. At most about [maxSamples]
  /// points are produced.
  static List<Offset> sine(
    NotePolyline line, {
    required double amplitude,
    required double wavelength,
    required int maxSamples,
  }) {
    final halves = _halfWaves(line, wavelength, maxSamples ~/ 2);
    final perHalf = math.max(
      2,
      math.min(_samplesPerHalfWave, maxSamples ~/ halves),
    );
    final count = halves * perHalf;
    final step = line.length / count;
    final window = math.max(step, 0.5);
    Offset sample(int k) =>
        line.pointAt(k * step) +
        line.normalAt(k * step, window) *
            (amplitude * math.sin(math.pi * k / perHalf));

    return [
      line.pointAt(0),
      for (var k = 1; k < count; k++) sample(k),
      if (!line.closed) line.points.last,
    ];
  }

  /// A triangular wave around [line]: one vertex at the peak of every half
  /// wave, alternating sides, with the same fitting rules as [sine].
  static List<Offset> triangle(
    NotePolyline line, {
    required double amplitude,
    required double wavelength,
    required int maxSamples,
  }) {
    final halves = _halfWaves(line, wavelength, maxSamples);
    final half = line.length / halves;
    final window = math.max(half / 4, 0.5);
    Offset peak(int k) {
      final at = (k + 0.5) * half;
      final side = k.isEven ? amplitude : -amplitude;

      return line.pointAt(at) + line.normalAt(at, window) * side;
    }

    return [
      line.pointAt(0),
      for (var k = 0; k < halves; k++) peak(k),
      if (!line.closed) line.points.last,
    ];
  }

  static int _halfWaves(NotePolyline line, double wavelength, int limit) {
    // Capped before rounding: a vanishing wavelength divides to infinity.
    final wanted = math.min(line.length / (wavelength / 2), limit.toDouble());
    final halves = math.max(1, wanted.round());
    if (!line.closed) return halves;

    return math.max(2, halves.isOdd ? halves + 1 : halves);
  }
}
