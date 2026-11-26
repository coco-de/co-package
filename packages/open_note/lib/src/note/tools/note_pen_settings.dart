import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_tools_numbers.dart';
import 'package:open_note/src/note/tools/note_pen_engine_params.dart';

/// How pen input is turned into ink.
///
/// Every value read from this object is inside its range: values outside it are
/// clamped and NaN or infinity reads as the default.
///
/// JSON: `{"motionSmoothing": int 0–10, "stabilization": number 0–1,
/// "pressureSensitivity": number 0–1}`. A missing or mistyped key gives the
/// default.
@immutable
class NotePenSettings {
  /// Lowest [motionSmoothing].
  static const int minMotionSmoothing = 0;

  /// Highest [motionSmoothing].
  static const int maxMotionSmoothing = 10;

  /// Default [motionSmoothing].
  static const int defaultMotionSmoothing = 5;

  /// Default [stabilization].
  static const double defaultStabilization = 0.2;

  /// Default [pressureSensitivity]; it leaves pressure untouched.
  static const double defaultPressureSensitivity = 0.5;

  final int _motionSmoothing;

  final double _stabilization;

  final double _pressureSensitivity;

  /// Creates settings; see the getters for ranges and defaults.
  const NotePenSettings({
    int motionSmoothing = defaultMotionSmoothing,
    double stabilization = defaultStabilization,
    double pressureSensitivity = defaultPressureSensitivity,
  }) : _motionSmoothing = motionSmoothing,
       _stabilization = stabilization,
       _pressureSensitivity = pressureSensitivity;

  /// Reads the JSON form described on the class; never throws.
  factory NotePenSettings.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NotePenSettings(
      motionSmoothing: NoteJson.integer(
        map,
        'motionSmoothing',
        defaultMotionSmoothing,
      ),
      stabilization: NoteJson.number(
        map,
        'stabilization',
        defaultStabilization,
      ),
      pressureSensitivity: NoteJson.number(
        map,
        'pressureSensitivity',
        defaultPressureSensitivity,
      ),
    );
  }

  /// Outline softening, 0 (none) – 10 (strongest). Default 5.
  int get motionSmoothing =>
      _motionSmoothing.clamp(minMotionSmoothing, maxMotionSmoothing);

  /// Hand-tremor stabilization, 0 (off) – 1 (strongest). Default 0.2.
  double get stabilization => noteClampOr(
    _stabilization,
    min: 0,
    max: 1,
    fallback: defaultStabilization,
  );

  /// How strongly pressure changes the line, 0–1. Default 0.5 (neutral).
  double get pressureSensitivity => noteClampOr(
    _pressureSensitivity,
    min: 0,
    max: 1,
    fallback: defaultPressureSensitivity,
  );

  @override
  int get hashCode =>
      Object.hash(motionSmoothing, stabilization, pressureSensitivity);

  /// The numbers the engine uses. With `m` = [motionSmoothing], `s` =
  /// [stabilization] and `p` = [pressureSensitivity]:
  ///
  /// * `smoothing = m / 10` (0 → 0, 5 → 0.5, 10 → 1);
  /// * `streamline = 0.1 + 0.8 * s` (0 → 0.1, 0.2 → 0.26, 1 → 0.9);
  /// * `thinningScale` is linear between the points (0, 0.25), (0.5, 1) and
  ///   (1, 1.5): `0.25 + 1.5 * p` up to 0.5, then `1 + (p - 0.5)`;
  /// * `pressureGamma = 2 ^ (2 * (p - 0.5))` (0 → 0.5, 0.5 → 1, 1 → 2). The
  ///   engine raises the pressure to this power, so below 0.5 light touches get
  ///   thicker and above 0.5 they get thinner.
  NotePenEngineParams toEngineParams() {
    final pressure = pressureSensitivity;

    return NotePenEngineParams(
      streamline: 0.1 + 0.8 * stabilization,
      smoothing: motionSmoothing / maxMotionSmoothing,
      thinningScale: _thinningScale(pressure),
      pressureGamma: math.pow(2, 2 * (pressure - 0.5)).toDouble(),
    );
  }

  /// A copy with the given values replaced.
  NotePenSettings copyWith({
    int? motionSmoothing,
    double? stabilization,
    double? pressureSensitivity,
  }) => NotePenSettings(
    motionSmoothing: motionSmoothing ?? this.motionSmoothing,
    stabilization: stabilization ?? this.stabilization,
    pressureSensitivity: pressureSensitivity ?? this.pressureSensitivity,
  );

  /// The JSON form described on the class.
  JsonMap toJson() => {
    'motionSmoothing': motionSmoothing,
    'stabilization': stabilization,
    'pressureSensitivity': pressureSensitivity,
  };

  @override
  bool operator ==(Object other) =>
      other is NotePenSettings &&
      other.motionSmoothing == motionSmoothing &&
      other.stabilization == stabilization &&
      other.pressureSensitivity == pressureSensitivity;

  @override
  String toString() => 'NotePenSettings(${toJson()})';

  static double _thinningScale(double sensitivity) =>
      sensitivity <= 0.5 ? 0.25 + 1.5 * sensitivity : 1 + (sensitivity - 0.5);
}
