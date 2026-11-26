import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The plain numbers the drawing engine needs from the pen settings.
///
/// Produced by `NotePenSettings.toEngineParams`; not persisted.
@immutable
class NotePenEngineParams {
  /// `StrokeOptions.streamline` (how much the outline lags the raw input),
  /// 0.1–0.9.
  final double streamline;

  /// `StrokeOptions.smoothing` (how much outline edges are softened), 0–1.
  final double smoothing;

  /// Multiplier of the thinning each ink uses by default, 0.25–1.5; 1 leaves
  /// it unchanged.
  final double thinningScale;

  /// Exponent applied to a normalised pressure before the engine uses it,
  /// 0.5–2; 1 leaves pressure unchanged.
  final double pressureGamma;

  /// Creates a set of engine numbers.
  const NotePenEngineParams({
    required this.streamline,
    required this.smoothing,
    required this.thinningScale,
    required this.pressureGamma,
  });

  @override
  int get hashCode =>
      Object.hash(streamline, smoothing, thinningScale, pressureGamma);

  /// Applies [pressureGamma] to a normalised [pressure]: `p ^ gamma`.
  ///
  /// [pressure] is clamped into 0–1 first; NaN counts as 0.
  double applyPressure(double pressure) {
    final clamped = pressure.isNaN ? 0.0 : pressure.clamp(0.0, 1.0);

    return math.pow(clamped, pressureGamma).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is NotePenEngineParams &&
      other.streamline == streamline &&
      other.smoothing == smoothing &&
      other.thinningScale == thinningScale &&
      other.pressureGamma == pressureGamma;

  @override
  String toString() =>
      'NotePenEngineParams(streamline: $streamline, smoothing: $smoothing, '
      'thinningScale: $thinningScale, pressureGamma: $pressureGamma)';
}
