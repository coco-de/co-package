// ignore_for_file: prefer-declaring-const-constructor

/// build_runner Builder — .feature → dual test 생성.
library;

import 'dart:async';

import 'package:co_test_gen/src/generator/feature_parser.dart';
import 'package:co_test_gen/src/generator/test_generator.dart';
import 'package:build/build.dart';

/// .feature 파일에서 Widget Test + Patrol Test를 동시 생성하는 Builder.
///
/// ### build.yaml 설정
///
/// ```yaml
/// builders:
///   dual_test_gen:
///     import: "package:co_test_gen/builder.dart"
///     builder_factories: ["dualTestBuilder"]
///     build_extensions:
///       ".feature":
///         - ".widget_test.dart"
///         - ".patrol_test.dart"
///     auto_apply: dependents
///     build_to: source
/// ```
///
/// ### Feature 모듈 build.yaml
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       co_test_gen|dual_test_gen:
///         enabled: true
///         generate_for:
///           - test/src/bdd/*.feature
///         options:
///           stepFolder: step
/// ```
class DualTestBuilder implements Builder {
  /// [options]로 Builder를 생성합니다.
  DualTestBuilder({required this.options});

  /// 빌더 옵션.
  final BuilderOptions options;

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.feature': ['.widget_test.dart', '.patrol_test.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final content = await buildStep.readAsString(inputId);

    // .feature 파싱
    final feature = parseFeature(content);
    if (feature.scenarios.isEmpty) return;

    // stepFolder 옵션 (기본값: 'step')
    final stepFolder = options.config['stepFolder'] as String? ?? 'step';

    // Widget Test 생성
    final widgetScenarios = feature.scenarios.where(
      (scenario) => scenario.target != TestTarget.patrolOnly,
    );
    if (widgetScenarios.isNotEmpty) {
      final widgetTestId = inputId.changeExtension('.widget_test.dart');
      final widgetTestCode = generateWidgetTest(
        feature,
        stepFolder: stepFolder,
      );
      await buildStep.writeAsString(widgetTestId, widgetTestCode);
    }

    // Patrol Test 생성
    final patrolScenarios = feature.scenarios.where(
      (scenario) => scenario.target != TestTarget.widgetOnly,
    );
    if (patrolScenarios.isNotEmpty) {
      final patrolTestId = inputId.changeExtension('.patrol_test.dart');
      final patrolTestCode = generatePatrolTest(
        feature,
        stepFolder: stepFolder,
      );
      await buildStep.writeAsString(patrolTestId, patrolTestCode);
    }
  }
}
