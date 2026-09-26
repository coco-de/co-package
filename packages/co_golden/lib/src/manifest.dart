import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'coverage.dart';
import 'environment.dart';
import 'variant.dart';

/// Schema name written to every run manifest.
const String goldenRunSchema = 'co_golden.run';

/// Schema version written to every run manifest.
const int goldenRunSchemaVersion = 1;

/// Outcome of one variant.
enum GoldenResultStatus {
  /// Rendered and captured without errors.
  passed,

  /// Failed in some phase, or rendered with errors such as overflows.
  failed,
}

/// Result of one variant, as written to the run manifest.
@immutable
final class GoldenResult {
  /// Creates a result.
  const GoldenResult({
    required this.variant,
    required this.fileStem,
    required this.status,
    required this.duration,
    this.image,
    this.overflowCount = 0,
    this.errors = const [],
    this.failurePhase,
  });

  /// Result for [variant] with its axes flattened into JSON.
  factory GoldenResult.of(
    GoldenVariant<Object?> variant, {
    required GoldenResultStatus status,
    required Duration duration,
    String? image,
    int overflowCount = 0,
    List<String> errors = const [],
    String? failurePhase,
  }) => GoldenResult(
    variant: variant.toJson(),
    fileStem: variant.fileStem,
    status: status,
    duration: duration,
    image: image,
    overflowCount: overflowCount,
    errors: errors,
    failurePhase: failurePhase,
  );

  /// Axis values of the variant.
  final Map<String, Object?> variant;

  /// File name of the variant without extension.
  final String fileStem;

  /// Outcome.
  final GoldenResultStatus status;

  /// Wall-clock time of the variant.
  final Duration duration;

  /// Captured image path relative to the output directory, or `null` when
  /// nothing was captured.
  final String? image;

  /// Number of layout overflow errors reported while rendering.
  final int overflowCount;

  /// Short descriptions of the errors, in report order.
  final List<String> errors;

  /// Phase that threw, or `null` when no phase threw.
  final String? failurePhase;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'variant': variant,
    'fileStem': fileStem,
    'status': status.name,
    'durationMs': duration.inMilliseconds,
    'image': image,
    'overflowCount': overflowCount,
    'errors': errors,
    'failurePhase': failurePhase,
  };
}

/// Collects the results of one scenario and writes its run manifest.
final class GoldenScenarioReport {
  /// Creates an empty report.
  GoldenScenarioReport({
    required this.suite,
    required this.scenario,
    required this.mode,
    required this.plan,
    this.description,
  });

  /// Suite (usually the package) of the scenario.
  final String suite;

  /// Scenario name.
  final String scenario;

  /// Human description shown by galleries.
  final String? description;

  /// Mode the results were produced in.
  final GoldenMatrixMode mode;

  /// Plan the results belong to.
  final GoldenPlan<Object?> plan;

  final List<GoldenResult> _results = [];

  /// Results recorded so far.
  List<GoldenResult> get results => List.unmodifiable(_results);

  /// Records one variant.
  void add(GoldenResult result) => _results.add(result);

  /// Manifest path below [outputDirectory]:
  /// `runs/<suite>/<scenario>.json`.
  static String manifestPath(String suite, String scenario) =>
      p.posix.join('runs', suite, '$scenario.json');

  /// JSON form of the manifest.
  Map<String, Object?> toJson({DateTime? generatedAt}) => {
    'schema': goldenRunSchema,
    'schemaVersion': goldenRunSchemaVersion,
    'suite': suite,
    'scenario': scenario,
    'description': description,
    'mode': mode.name,
    'generatedAt': (generatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'plan': plan.toJson(),
    'results': [for (final result in _results) result.toJson()],
  };

  /// Writes the manifest below [outputDirectory] and returns the file.
  ///
  /// The file is written to a temporary name first and then renamed, so a
  /// reader never sees half a manifest.
  File write(String outputDirectory) {
    final file = File(p.join(outputDirectory, manifestPath(suite, scenario)));
    file.parent.createSync(recursive: true);
    final temporary = File('${file.path}.tmp');
    temporary.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(toJson()),
      flush: true,
    );
    return temporary.renameSync(file.path);
  }
}
