import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:co_bdd/src/generator/dual_test_builder.dart';
import 'package:co_bdd/src/generator/test_generator.dart';
import 'package:dart_style/dart_style.dart';
import 'package:package_config/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// build_runner 가 넘기는 [BuildStep] 중 빌더가 실제로 쓰는 네 멤버만 구현한다.
///
/// [writeAsString] 은 일부러 한 박자 늦게 끝난다 — 실제 파일 쓰기처럼
/// 빌더가 `await` 에서 제어를 내주는 동안 다른 빌드가 끼어들 수 있게 해야
/// 경합을 재현할 수 있다.
class _FakeBuildStep implements BuildStep {
  _FakeBuildStep(this.inputId, this.content, {this.languageVersion});

  @override
  final AssetId inputId;

  /// 입력 패키지의 언어 버전 — `null` 이면 package config 에 패키지가 없다.
  final LanguageVersion? languageVersion;

  @override
  Future<PackageConfig> get packageConfig async => PackageConfig([
    if (languageVersion case final version?)
      Package(
        inputId.package,
        Uri.parse('file:///${inputId.package}/'),
        packageUriRoot: Uri.parse('file:///${inputId.package}/lib/'),
        languageVersion: version,
      ),
  ]);

  /// 입력 `.feature` 본문.
  final String content;

  /// 빌더가 쓴 산출물 — 경로 → 본문.
  final Map<String, String> outputs = {};

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async =>
      content;

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> contents, {
    Encoding encoding = utf8,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    outputs[id.path] = await contents;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _feature = '''
Feature: Race
  Scenario: Tap a widget
    When I tap the {'search_button'} widget
''';

const _sharedImport = "import 'package:co_bdd/shared_steps.dart';";
const _localImport = "import 'step/i_tap_the_widget.dart';";

void main() {
  group('DualTestBuilder — 공유 step 목록은 빌드마다 독립이다', () {
    test('should keep each package list when two builds interleave '
        '(workspace 빌드에서 패키지별 목록이 섞이지 않는다)', () async {
      // A 는 i_tap_the_widget 을 공유 step 으로, B 는 로컬 step 으로 쓴다.
      final builderA = DualTestBuilder(
        options: const BuilderOptions({
          'sharedSteps': true,
          'sharedStepNames': ['i_tap_the_widget'],
        }),
      );
      final builderB = DualTestBuilder(
        options: const BuilderOptions({
          'sharedSteps': true,
          'sharedStepNames': <String>[],
        }),
      );
      final stepA = _FakeBuildStep(
        AssetId('a', 'test/src/bdd/race.feature'),
        _feature,
      );
      final stepB = _FakeBuildStep(
        AssetId('b', 'test/src/bdd/race.feature'),
        _feature,
      );

      // A 가 위젯 테스트를 쓰는 사이 B 가 끼어든다 — build_runner 가 여러
      // 패키지의 build() 를 한 isolate 에서 동시에 돌리는 것과 같은 모양.
      await Future.wait<void>([
        Future.sync(() => builderA.build(stepA)),
        Future.sync(() => builderB.build(stepB)),
      ]);

      final widgetA = stepA.outputs['test/src/bdd/race.widget_test.dart']!;
      final patrolA = stepA.outputs['test/src/bdd/race.patrol_test.dart']!;
      final widgetB = stepB.outputs['test/src/bdd/race.widget_test.dart']!;
      final patrolB = stepB.outputs['test/src/bdd/race.patrol_test.dart']!;

      for (final code in [widgetA, patrolA]) {
        expect(code, contains(_sharedImport));
        expect(code, isNot(contains(_localImport)));
      }
      for (final code in [widgetB, patrolB]) {
        expect(code, contains(_localImport));
        expect(code, isNot(contains(_sharedImport)));
      }
    });

    test('should default to every co_bdd shared step when the option is '
        'absent (목록이 없으면 co_bdd 공유 step 전부)', () async {
      final builder = DualTestBuilder(
        options: const BuilderOptions({'sharedSteps': true}),
      );
      final step = _FakeBuildStep(AssetId('a', 'test/src/bdd/race.feature'), """
Feature: Default
  Scenario: Shared steps without a list
    When I tap the {'search_button'} widget
    Then the {'save_button'} widget should be enabled
    And the {'push_toggle'} toggle should be on
    And I open the settings page
""");

      await builder.build(step);

      final code = step.outputs['test/src/bdd/race.widget_test.dart']!;
      expect(code, contains(_sharedImport));
      for (final name in [
        'i_tap_the_widget',
        'the_widget_should_be_enabled',
        'the_toggle_should_be_on',
      ]) {
        expect(sharedStepFileNames, contains(name));
        expect(code, isNot(contains("import 'step/$name.dart';")));
      }
      // 도메인 step 은 여전히 로컬이다.
      expect(code, contains("import 'step/i_open_the_settings_page.dart';"));
    });
  });

  group('DualTestBuilder — 생성물은 패키지 언어 버전으로 format 된다 (#100)', () {
    const feature = '''
Feature: Format
  Scenario: A scenario name long enough to push the generated test call past eighty columns
    Then the {'remittance_quote_receive'} widget should contain {'17,850,000동'} text
''';

    for (final (major, minor) in [(3, 7), (3, 6)]) {
      test(
        'should match DartFormatter at the package version $major.$minor',
        () async {
          final step = _FakeBuildStep(
            AssetId('a', 'test/src/bdd/format.feature'),
            feature,
            languageVersion: LanguageVersion(major, minor),
          );

          await DualTestBuilder(options: const BuilderOptions({})).build(step);

          final formatter = DartFormatter(
            languageVersion: Version(major, minor, 0),
          );
          expect(step.outputs, hasLength(2));
          for (final code in step.outputs.values) {
            expect(code, formatter.format(code));
          }
        },
      );
    }

    test('should fall back to the latest version when the package is '
        'unknown', () async {
      final step = _FakeBuildStep(
        AssetId('a', 'test/src/bdd/format.feature'),
        feature,
      );

      await DualTestBuilder(options: const BuilderOptions({})).build(step);

      final formatter = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      );
      for (final code in step.outputs.values) {
        expect(code, formatter.format(code));
      }
    });
  });
}
