import 'dart:io' show Platform;

import 'package:meta/meta.dart';

/// What a golden matrix does when its tests run.
enum GoldenMatrixMode {
  /// Register the variants as skipped tests. This is the default, so matrix
  /// tests can live next to ordinary tests without failing runs that have no
  /// baselines.
  skip,

  /// Render every variant and write the PNG to the output directory without
  /// comparing it to anything. Layout errors still fail the variant.
  capture,

  /// Compare every variant with a baseline next to the test file through
  /// `matchesGoldenFile` (`--update-goldens` writes the baselines).
  compare,
}

/// Mode and output location of golden matrices, usually read from the
/// process environment.
@immutable
final class GoldenMatrixEnvironment {
  /// Creates an explicit environment, mainly for tests.
  const GoldenMatrixEnvironment({
    this.mode = GoldenMatrixMode.skip,
    this.outputDirectory = defaultOutputDirectory,
  });

  /// Reads [modeVariable] and [outputVariable] from [environment] (the
  /// process environment by default).
  ///
  /// An empty or missing mode means [GoldenMatrixMode.skip]. An unknown value
  /// throws an [ArgumentError] instead of skipping, so a typo in CI cannot
  /// turn a capture run into a silent no-op.
  factory GoldenMatrixEnvironment.fromEnvironment([
    Map<String, String>? environment,
  ]) {
    final values = environment ?? Platform.environment;
    final raw = values[modeVariable]?.trim().toLowerCase() ?? '';
    final mode = switch (raw) {
      '' || 'skip' => GoldenMatrixMode.skip,
      'capture' => GoldenMatrixMode.capture,
      'compare' => GoldenMatrixMode.compare,
      _ => throw ArgumentError.value(
        raw,
        modeVariable,
        'must be one of skip, capture, compare',
      ),
    };
    final output = values[outputVariable]?.trim() ?? '';
    return GoldenMatrixEnvironment(
      mode: mode,
      outputDirectory: output.isEmpty ? defaultOutputDirectory : output,
    );
  }

  /// Environment variable that selects the mode.
  static const String modeVariable = 'CO_GOLDEN_MODE';

  /// Environment variable that overrides the capture output directory.
  static const String outputVariable = 'CO_GOLDEN_OUTPUT';

  /// Capture output directory, relative to the package being tested.
  static const String defaultOutputDirectory = 'build/co_golden';

  /// Active mode.
  final GoldenMatrixMode mode;

  /// Directory that receives `images/` and `runs/` in capture mode.
  final String outputDirectory;
}
