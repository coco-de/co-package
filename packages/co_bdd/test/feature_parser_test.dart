import 'package:co_test_gen/src/generator/feature_parser.dart';
import 'package:test/test.dart';

void main() {
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
