import 'package:co_test_gen/src/generator/feature_parser.dart';
import 'package:co_test_gen/src/generator/test_generator.dart';
import 'package:test/test.dart';

void main() {
  final feature = FeatureFile(
    name: 'Email Login',
    tags: ['smoke', 'auth'],
    background: [
      const Step(keyword: 'Given', text: 'I am on the login page', params: []),
    ],
    scenarios: [
      const Scenario(
        name: 'Successful login',
        tags: ['validation'],
        steps: [
          Step(
            keyword: 'When',
            text: "I enter {'test@example.com'} in the email field",
            params: ['test@example.com'],
          ),
          Step(keyword: 'And', text: 'I tap the login button', params: []),
          Step(
            keyword: 'Then',
            text: 'the store screen is displayed',
            params: [],
          ),
        ],
      ),
      const Scenario(
        name: 'Patrol only scenario',
        tags: ['patrol-only'],
        steps: [Step(keyword: 'Given', text: 'app is running', params: [])],
      ),
      const Scenario(
        name: 'Widget only scenario',
        tags: ['widget-only'],
        steps: [Step(keyword: 'Given', text: 'widget is mounted', params: [])],
      ),
    ],
  );

  group('generateWidgetTest', () {
    test('creates WidgetTestDriver and passes to steps', () {
      final code = generateWidgetTest(feature, stepFolder: 'step');

      expect(code, contains("import 'package:co_test_gen/co_test_gen.dart'"));
      expect(code, contains('WidgetTestDriver(tester)'));
      expect(
        code,
        contains("iEnterInTheEmailField(driver, 'test@example.com')"),
      );
      expect(code, contains('iTapTheLoginButton(driver)'));
      expect(code, contains('iAmOnTheLoginPage(driver)'));
    });

    test('excludes patrol-only scenarios', () {
      final code = generateWidgetTest(feature, stepFolder: 'step');

      expect(code, contains('Successful login'));
      expect(code, isNot(contains('Patrol only scenario')));
      expect(code, contains('Widget only scenario'));
    });
  });

  group('generatePatrolTest', () {
    test('creates PatrolTestDriver and passes to steps', () {
      final code = generatePatrolTest(feature, stepFolder: 'step');

      expect(code, contains("import 'package:co_test_gen/co_test_gen.dart'"));
      expect(code, contains("import 'package:patrol/patrol.dart'"));
      expect(code, contains(r'PatrolTestDriver($)'));
      expect(
        code,
        contains("iEnterInTheEmailField(driver, 'test@example.com')"),
      );
    });

    test('excludes widget-only scenarios', () {
      final code = generatePatrolTest(feature, stepFolder: 'step');

      expect(code, contains('Successful login'));
      expect(code, contains('Patrol only scenario'));
      expect(code, isNot(contains('Widget only scenario')));
    });

    test('step calls are identical in both outputs', () {
      final widgetCode = generateWidgetTest(feature, stepFolder: 'step');
      final patrolCode = generatePatrolTest(feature, stepFolder: 'step');

      expect(
        widgetCode,
        contains("iEnterInTheEmailField(driver, 'test@example.com')"),
      );
      expect(
        patrolCode,
        contains("iEnterInTheEmailField(driver, 'test@example.com')"),
      );
    });
  });

  group('sharedSteps (generic key-based)', () {
    setUp(() {
      sharedStepFileNames
        ..clear()
        ..addAll(['i_tap_the_widget', 'the_widget_should_be_displayed']);
    });

    tearDown(() => sharedStepFileNames.clear());

    final sharedFeature = FeatureFile(
      name: 'Generic Step Test',
      tags: [],
      background: [],
      scenarios: [
        const Scenario(
          name: 'Widget tap and display',
          tags: [],
          steps: [
            Step(
              keyword: 'When',
              text: "I tap the {'search_button'} widget",
              params: ['search_button'],
            ),
            Step(
              keyword: 'Then',
              text: "the {'book_list'} widget should be displayed",
              params: ['book_list'],
            ),
            Step(keyword: 'When', text: 'I tap the login button', params: []),
          ],
        ),
      ],
    );

    test('without sharedSteps all steps use local imports', () {
      final code = generateWidgetTest(sharedFeature, stepFolder: 'step');

      expect(code, contains("import 'step/i_tap_the_widget.dart'"));
      expect(
        code,
        contains("import 'step/the_widget_should_be_displayed.dart'"),
      );
      expect(code, contains("import 'step/i_tap_the_login_button.dart'"));
    });

    test('with sharedSteps generic steps use package import', () {
      final code = generateWidgetTest(
        sharedFeature,
        stepFolder: 'step',
        useSharedSteps: true,
        sharedStepsImport: 'package:my_app/shared_steps.dart',
      );

      // Generic steps are NOT imported locally
      expect(code, isNot(contains("import 'step/i_tap_the_widget.dart'")));
      // Instead they come from the shared package
      expect(code, contains("import 'package:my_app/shared_steps.dart'"));
      // Domain-specific steps still use local import
      expect(code, contains("import 'step/i_tap_the_login_button.dart'"));
    });

    test('patrol test also uses shared imports', () {
      final code = generatePatrolTest(
        sharedFeature,
        stepFolder: 'step',
        useSharedSteps: true,
        sharedStepsImport: 'package:my_app/shared_steps.dart',
      );

      expect(code, contains("import 'package:my_app/shared_steps.dart'"));
      expect(code, contains("import 'step/i_tap_the_login_button.dart'"));
    });
  });
}
