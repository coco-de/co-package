/// Widget Test / Patrol Test code generator.
///
/// Receives a [FeatureFile] and generates `.widget_test.dart` and
/// `.patrol_test.dart`. Step functions use the `TestDriver` abstraction
/// so they can be reused across both test types.
///
/// ## Shared Steps
///
/// When `sharedSteps` is enabled, steps whose `fileName` matches an entry
/// in `sharedStepFileNames` are imported from a shared package instead of
/// generating a local step file. This eliminates duplication across features.
///
/// Configure via build.yaml:
/// ```yaml
/// options:
///   sharedSteps: true   # every co_bdd shared step, from package:co_bdd/shared_steps.dart
/// ```
///
/// ## Formatting
///
/// Both outputs go through `DartFormatter`, so a generated file passes
/// `dart format --set-exit-if-changed` as is (coco-de/co-package#100).
library;

import 'package:co_bdd/src/generator/feature_parser.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Default import path for shared steps package.
const defaultSharedStepsImport = 'package:co_bdd/shared_steps.dart';

/// Step file names (without `.dart`) that `package:co_bdd/shared_steps.dart`
/// exports — the default for `sharedStepNames`.
///
/// With `sharedSteps: true` and no list, every co_bdd shared step resolves
/// from the shared library, so a project picks up a new shared step by bumping
/// co_bdd instead of editing each `build.yaml`. Give `sharedStepNames` only to
/// narrow the set — for example when `sharedStepsImport` points to a project
/// barrel that re-exports part of this library.
///
/// `test/shared_steps_contract_test.dart` keeps this set equal to the exports
/// of `lib/shared_steps.dart`. It is `const` on purpose: the default used to be
/// a mutable registry refilled on every build, and in a
/// `build_runner --workspace` run one package's list leaked into another
/// package's output (coco-de/unibook#14429).
const Set<String> sharedStepFileNames = {
  'i_clear_the_widget',
  'i_confirm_deletion',
  'i_enter_in_the_widget',
  'i_long_press_the_widget',
  'i_scroll_until_the_widget_is_visible',
  'i_should_see_widgets',
  'i_tap_the_next_page_button',
  'i_tap_the_text',
  'i_tap_the_widget',
  'i_tap_the_widget_at_index',
  'i_wait_for_seconds',
  'the_current_page_should_be',
  'the_error_message_should_be_displayed',
  'the_loading_indicator_should_be_displayed',
  'the_success_message_should_be_displayed',
  'the_text_should_be_displayed',
  'the_toggle_should_be_off',
  'the_toggle_should_be_on',
  'the_total_count_should_be_displayed',
  'the_widget_should_be_anchored_to',
  'the_widget_should_be_disabled',
  'the_widget_should_be_displayed',
  'the_widget_should_be_enabled',
  'the_widget_should_be_selected',
  'the_widget_should_contain_text',
  'the_widget_should_not_be_displayed',
  'the_widget_should_not_be_selected',
};

/// Generates Widget Test code.
///
/// Creates a `WidgetTestDriver(tester)` and passes it to step functions
/// as `TestDriver driver`.
///
/// The output is formatted at [languageVersion] — the language version of the
/// package the file is generated into (default: the formatter's latest).
String generateWidgetTest(
  FeatureFile feature, {
  required String stepFolder,
  bool useSharedSteps = false,
  String sharedStepsImport = defaultSharedStepsImport,
  Set<String>? sharedStepNames,
  Version? languageVersion,
}) {
  final sharedNames = sharedStepNames ?? sharedStepFileNames;
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
    ..writeln("import 'package:co_bdd/co_bdd.dart';");

  // Step imports — shared steps are imported from a single package import,
  // local steps are imported individually from the step folder.
  final widgetSteps = _collectStepsForTarget(feature, TestTarget.widgetOnly);
  final importedFiles = <String>{};
  var needsSharedImport = false;
  for (final step in widgetSteps) {
    final fileName = step.fileName;
    if (importedFiles.add(fileName)) {
      if (useSharedSteps && sharedNames.contains(fileName)) {
        needsSharedImport = true;
      } else {
        buffer.writeln("import '$stepFolder/$fileName.dart';");
      }
    }
  }
  if (needsSharedImport) {
    buffer.writeln("import '$sharedStepsImport';");
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

    buffer.writeln("  testWidgets('''${scenario.name}''', (tester) async {");

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
  return _format(buffer.toString(), languageVersion);
}

/// Generates Patrol E2E Test code.
///
/// Creates a `PatrolTestDriver($)` and passes it to step functions
/// as `TestDriver driver`.
///
/// The output is formatted at [languageVersion] — the language version of the
/// package the file is generated into (default: the formatter's latest).
String generatePatrolTest(
  FeatureFile feature, {
  required String stepFolder,
  bool useSharedSteps = false,
  String sharedStepsImport = defaultSharedStepsImport,
  Set<String>? sharedStepNames,
  Version? languageVersion,
}) {
  final sharedNames = sharedStepNames ?? sharedStepFileNames;
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
    ..writeln("import 'package:co_bdd/co_bdd.dart';");

  // Step imports — shared steps from package, local steps from folder
  final patrolSteps = _collectStepsForTarget(feature, TestTarget.patrolOnly);
  final importedFiles = <String>{};
  var needsSharedImport = false;
  for (final step in patrolSteps) {
    final fileName = step.fileName;
    if (importedFiles.add(fileName)) {
      if (useSharedSteps && sharedNames.contains(fileName)) {
        needsSharedImport = true;
      } else {
        buffer.writeln("import '$stepFolder/$fileName.dart';");
      }
    }
  }
  if (needsSharedImport) {
    buffer.writeln("import '$sharedStepsImport';");
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
      ..writeln(r'  Future<void> bddSetUp(PatrolIntegrationTester $) async {')
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
  return _format(buffer.toString(), languageVersion);
}

/// Formats [code] the way `dart format` does at [languageVersion].
///
/// A version newer than the formatter knows is clamped to its latest, which is
/// what `dart format` itself uses. Code the formatter cannot parse (for example
/// a scenario name containing three single quotes) is returned unformatted, so
/// the compile error still points at the generated line instead of failing the
/// build here.
String _format(String code, Version? languageVersion) {
  final latest = DartFormatter.latestLanguageVersion;
  final version = languageVersion == null || languageVersion > latest
      ? latest
      : languageVersion;
  try {
    return DartFormatter(languageVersion: version).format(code);
  } on FormatterException {
    return code;
  }
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
