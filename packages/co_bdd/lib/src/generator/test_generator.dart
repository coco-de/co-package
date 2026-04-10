/// Widget Test / Patrol Test code generator.
///
/// Receives a [FeatureFile] and generates `.widget_test.dart` and
/// `.patrol_test.dart`. Step functions use the `TestDriver` abstraction
/// so they can be reused across both test types.
library;

import 'package:co_test_gen/src/generator/feature_parser.dart';

/// Generates Widget Test code.
///
/// Creates a `WidgetTestDriver(tester)` and passes it to step functions
/// as `TestDriver driver`.
String generateWidgetTest(FeatureFile feature, {required String stepFolder}) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln();

  // Tags
  if (feature.tags.isNotEmpty) {
    final tags = feature.tags.map((tag) => "'$tag'").join(', ');
    buffer.writeln('@Tags([$tags])');
  }

  // Imports
  buffer
    ..writeln("import 'package:flutter_test/flutter_test.dart';")
    ..writeln("import 'package:co_test_gen/co_test_gen.dart';");

  // Step imports (widget-only + both scenarios)
  final widgetSteps = _collectStepsForTarget(feature, TestTarget.widgetOnly);
  final importedFiles = <String>{};
  for (final step in widgetSteps) {
    final fileName = step.fileName;
    if (importedFiles.add(fileName)) {
      buffer.writeln("import '$stepFolder/$fileName.dart';");
    }
  }

  buffer
    ..writeln()
    ..writeln('void main() {');

  // Background → bddSetUp
  if (feature.background.isNotEmpty) {
    buffer
      ..writeln('  Future<void> bddSetUp(WidgetTester tester) async {')
      ..writeln('    final driver = WidgetTestDriver(tester);');
    for (final step in feature.background) {
      buffer.writeln('    await ${_driverStepCall(step)};');
    }
    buffer.writeln('  }');
    buffer.writeln();
  }

  // Scenarios
  for (final scenario in feature.scenarios) {
    if (scenario.target == TestTarget.patrolOnly) continue;

    final tags = scenario.tags
        .where(
          (tag) =>
              tag != 'both' && tag != 'widget-only' && tag != 'patrol-only',
        )
        .toList();
    final tagStr = tags.isNotEmpty
        ? ", tags: [${tags.map((t) => "'$t'").join(', ')}]"
        : '';

    buffer.writeln(
      "  testWidgets('''${scenario.name}''', (tester) async {",
    );

    if (feature.background.isNotEmpty) {
      buffer.writeln('    await bddSetUp(tester);');
    }

    buffer.writeln('    final driver = WidgetTestDriver(tester);');
    for (final step in scenario.steps) {
      buffer.writeln('    await ${_driverStepCall(step)};');
    }

    buffer
      ..writeln('  }$tagStr);')
      ..writeln();
  }

  buffer.writeln('}');
  return buffer.toString();
}

/// Generates Patrol E2E Test code.
///
/// Creates a `PatrolTestDriver($)` and passes it to step functions
/// as `TestDriver driver`.
String generatePatrolTest(FeatureFile feature, {required String stepFolder}) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln();

  // Patrol tag for exclusion via `--exclude-tags patrol`
  buffer.writeln("@Tags(['patrol'])");

  // Imports
  buffer
    ..writeln("import 'package:flutter_test/flutter_test.dart';")
    ..writeln("import 'package:patrol/patrol.dart';")
    ..writeln("import 'package:co_test_gen/co_test_gen.dart';");

  // Step imports (patrol-only + both scenarios)
  final patrolSteps = _collectStepsForTarget(feature, TestTarget.patrolOnly);
  final importedFiles = <String>{};
  for (final step in patrolSteps) {
    final fileName = step.fileName;
    if (importedFiles.add(fileName)) {
      buffer.writeln("import '$stepFolder/$fileName.dart';");
    }
  }

  buffer
    ..writeln()
    ..writeln('void main() {');

  // Patrol config
  buffer
    ..writeln('  const config = PatrolTesterConfig(')
    ..writeln('    settleTimeout: Duration(seconds: 15),')
    ..writeln('    existsTimeout: Duration(seconds: 15),')
    ..writeln('    visibleTimeout: Duration(seconds: 15),')
    ..writeln('  );')
    ..writeln();

  // Background → bddSetUp
  if (feature.background.isNotEmpty) {
    buffer
      ..writeln(
        r'  Future<void> bddSetUp(PatrolIntegrationTester $) async {',
      )
      ..writeln(r'    final driver = PatrolTestDriver($);');
    for (final step in feature.background) {
      buffer.writeln('    await ${_driverStepCall(step)};');
    }
    buffer.writeln('  }');
    buffer.writeln();
  }

  // Scenarios
  for (final scenario in feature.scenarios) {
    if (scenario.target == TestTarget.widgetOnly) continue;

    buffer.writeln(
      r"  patrolTest('''${scenario.name}''', config: config, ($) async {"
          .replaceFirst(r'${scenario.name}', scenario.name),
    );

    if (feature.background.isNotEmpty) {
      buffer.writeln(r'    await bddSetUp($);');
    }

    buffer.writeln(r'    final driver = PatrolTestDriver($);');
    for (final step in scenario.steps) {
      buffer.writeln('    await ${_driverStepCall(step)};');
    }

    buffer
      ..writeln('  });')
      ..writeln();
  }

  buffer.writeln('}');
  return buffer.toString();
}

/// TestDriver-based step call — `funcName(driver, params...)`.
String _driverStepCall(Step step) {
  final funcName = step.functionName;
  final params = step.params.map((param) => "'$param'").join(', ');
  if (params.isNotEmpty) {
    return '$funcName(driver, $params)';
  }
  return '$funcName(driver)';
}

/// Collects steps for the given target (background + filtered scenarios).
List<Step> _collectStepsForTarget(
  FeatureFile feature,
  TestTarget includeTarget,
) {
  final steps = <Step>[...feature.background];
  for (final scenario in feature.scenarios) {
    if (includeTarget == TestTarget.widgetOnly &&
        scenario.target == TestTarget.patrolOnly) {
      continue;
    }
    if (includeTarget == TestTarget.patrolOnly &&
        scenario.target == TestTarget.widgetOnly) {
      continue;
    }
    steps.addAll(scenario.steps);
  }
  return steps;
}
