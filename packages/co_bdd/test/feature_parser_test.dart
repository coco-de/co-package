import 'package:co_test_gen/src/generator/feature_parser.dart';
import 'package:test/test.dart';

void main() {
  _defaultTargetTests();

  group('parseFeature', () {
    test('parses a basic .feature file', () {
      const content = '''
@smoke
@auth
Feature: Email Login
  User logs in with email

  Background:
    Given I am on the login page # navigate to login

  @validation
  Scenario: Successful login with valid email
    When I enter {'test@example.com'} in the email field # enter email
    And I enter {'password123'} in the password field # enter password
    And I tap the login button # tap login
    Then the store screen is displayed # verify store
''';

      final feature = parseFeature(content);

      expect(feature.name, 'Email Login');
      expect(feature.tags, ['smoke', 'auth']);
      expect(feature.background, hasLength(1));
      expect(feature.background.first.text, 'I am on the login page');
      expect(feature.scenarios, hasLength(1));

      final scenario = feature.scenarios.first;
      expect(scenario.name, 'Successful login with valid email');
      expect(scenario.tags, ['validation']);
      expect(scenario.steps, hasLength(4));
      expect(scenario.target, TestTarget.both);
    });

    test('determines TestTarget from tags', () {
      const content = '''
Feature: Test Targets

  @widget-only
  Scenario: Widget only test
    Given some step

  @patrol-only
  Scenario: Patrol only test
    Given some step

  @both
  Scenario: Both test
    Given some step

  Scenario: No tag defaults to both
    Given some step
''';

      final feature = parseFeature(content);
      expect(feature.scenarios, hasLength(4));
      expect(feature.scenarios[0].target, TestTarget.widgetOnly);
      expect(feature.scenarios[1].target, TestTarget.patrolOnly);
      expect(feature.scenarios[2].target, TestTarget.both);
      expect(feature.scenarios[3].target, TestTarget.both);
    });

    test('extracts parameters correctly', () {
      const content = '''
Feature: Parameter Test

  Scenario: Extract params
    When I enter {'hello'} in the {'email'} field
''';

      final feature = parseFeature(content);
      final step = feature.scenarios.first.steps.first;
      expect(step.params, ['hello', 'email']);
    });
  });

  group('Step', () {
    test('generates correct functionName', () {
      const step = Step(
        keyword: 'When',
        text: 'I enter in the email field',
        params: [],
      );
      expect(step.functionName, 'iEnterInTheEmailField');
    });

    test('strips parameter placeholders from functionName', () {
      const step = Step(
        keyword: 'When',
        text: "I enter {'test@example.com'} in the email field",
        params: ['test@example.com'],
      );
      expect(step.functionName, 'iEnterInTheEmailField');
    });

    test('generates correct fileName', () {
      const step = Step(
        keyword: 'Given',
        text: 'I am on the login page',
        params: [],
      );
      expect(step.fileName, 'i_am_on_the_login_page');
    });
  });
}

/// `defaultTarget` — 태그가 없는 시나리오의 기본 실행 대상.
///
/// 이 옵션이 없던 시절, 한쪽 레이어만 쓰는 프로젝트도 반대쪽 산출물이 강제로
/// 생성됐다. kobic 실측으로 feature 패키지 68개 파일 / 6,875줄이 **어디서도
/// 실행되지 않은 채** 생성·커밋되고 있었다(라이브러리 패키지라 Patrol 실행
/// 자체가 불가능). 기본값을 프로젝트가 정할 수 있어야 한다.
void _defaultTargetTests() {
  group('parseFeature defaultTarget', () {
    const content = '''
Feature: Sample

  Scenario: untagged scenario
    Then something happens

  @widget-only
  Scenario: widget tagged
    Then something happens

  @patrol-only
  Scenario: patrol tagged
    Then something happens
''';

    test('defaults to both when the option is omitted', () {
      final feature = parseFeature(content);

      expect(feature.scenarios[0].target, TestTarget.both);
    });

    test('untagged scenarios take the supplied default', () {
      final feature = parseFeature(
        content,
        defaultTarget: TestTarget.widgetOnly,
      );

      expect(feature.scenarios[0].target, TestTarget.widgetOnly);
    });

    test('tags always override the default', () {
      final feature = parseFeature(
        content,
        defaultTarget: TestTarget.widgetOnly,
      );

      // 기본값이 widgetOnly 여도 @patrol-only 는 그대로 이긴다 — 그러지 않으면
      // 예외를 표시할 방법이 사라져 옵션이 도입 목적을 잃는다.
      expect(feature.scenarios[1].target, TestTarget.widgetOnly);
      expect(feature.scenarios[2].target, TestTarget.patrolOnly);
    });

    test('applies to the last scenario in the file too', () {
      // 마지막 시나리오는 루프가 아니라 종료 후 _saveScenario 로 저장된다 —
      // 그 경로에 인자를 빠뜨리면 파일의 끝 하나만 조용히 both 로 남는다.
      final feature = parseFeature(
        content,
        defaultTarget: TestTarget.patrolOnly,
      );

      expect(feature.scenarios.last.target, TestTarget.patrolOnly);
    });
  });
}
