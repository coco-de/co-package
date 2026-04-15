/// build_runner Builder — .feature → dual test 생성.
library;

import 'dart:async';

import 'package:co_test_gen/src/generator/feature_parser.dart';
import 'package:co_test_gen/src/generator/test_generator.dart'
    show
        defaultSharedStepsImport,
        generatePatrolTest,
        generateWidgetTest,
        sharedStepFileNames;
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

    // sharedSteps 옵션 (기본값: false)
    // true이면 sharedStepFileNames에 매칭되는 step은
    // 로��� step 대신 sharedStepsImport 패키지에서 import됩니다.
    final useSharedSteps = options.config['sharedSteps'] as bool? ?? false;

    // sharedStepsImport 옵션 — 공유 step 패키지 import 경로
    final sharedStepsImport =
        options.config['sharedStepsImport'] as String? ??
        defaultSharedStepsImport;

    // sharedStepNames 옵션 — 프로젝트별 공유 step 목록 등���
    final customSharedNames =
        (options.config['sharedStepNames'] as List<dynamic>?)?.cast<String>();
    if (customSharedNames != null) {
      sharedStepFileNames
        ..clear()
        ..addAll(customSharedNames);
    }

    // Widget Test 생성
    final widgetScenarios = feature.scenarios.where(
      (scenario) => scenario.target != TestTarget.patrolOnly,
    );
    if (widgetScenarios.isNotEmpty) {
      final widgetTestId = inputId.changeExtension('.widget_test.dart');
      final widgetTestCode = generateWidgetTest(
        feature,
        stepFolder: stepFolder,
        useSharedSteps: useSharedSteps,
        sharedStepsImport: sharedStepsImport,
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
        useSharedSteps: useSharedSteps,
        sharedStepsImport: sharedStepsImport,
      );
      await buildStep.writeAsString(patrolTestId, patrolTestCode);
    }
  }
}
