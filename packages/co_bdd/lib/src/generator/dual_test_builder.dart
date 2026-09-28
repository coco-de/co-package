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

    // defaultTarget 옵션 — 태그가 없는 시나리오의 기본 실행 대상.
    //
    // 기본값 `both` 는 종전 동작이다. 프로젝트가 한쪽 레이어만 쓰는 경우
    // (예: feature 패키지는 라이브러리라 Patrol 실행 자체가 불가능) 여기서
    // 기본값을 바꿔 **쓰이지 않을 산출물이 생성되는 것을 막는다.**
    // 개별 시나리오는 `@widget-only` / `@patrol-only` 태그로 언제든 덮어쓴다.
    final defaultTarget = _parseTarget(options.config['defaultTarget']);

    // .feature 파싱
    final feature = parseFeature(content, defaultTarget: defaultTarget);
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

/// `defaultTarget` 옵션 문자열을 [TestTarget] 으로 해석한다.
///
/// 허용값: `both`(기본) · `widget-only` · `patrol-only`.
/// 알 수 없는 값은 **조용히 무시하지 않고 예외로 알린다** — 오타 하나가
/// 산출물 절반을 말없이 사라지게 만드는 옵션이라, 빌드가 성공한 채로
/// 잘못된 결과가 나오는 쪽이 훨씬 위험하다.
TestTarget _parseTarget(Object? raw) {
  if (raw == null) return TestTarget.both;
  return switch (raw) {
    'both' => TestTarget.both,
    'widget-only' => TestTarget.widgetOnly,
    'patrol-only' => TestTarget.patrolOnly,
    _ => throw ArgumentError.value(
      raw,
      'defaultTarget',
      "허용값은 'both' / 'widget-only' / 'patrol-only' 입니다",
    ),
  };
}
