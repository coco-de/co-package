/// BDD Dual Test Generator + TestDriver abstraction.
///
/// Generates Widget Test + Patrol E2E Test from Gherkin `.feature` files.
/// Step functions use a shared [TestDriver] interface, allowing the same
/// BDD steps to run as both widget tests and Patrol integration tests.
///
/// ## Quick Start
///
/// 1. Add to `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   co_test_gen: ^0.1.0
///   build_runner: ^2.4.0
/// ```
///
/// 2. Configure `build.yaml`:
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
///
/// 3. Write a `.feature` file:
/// ```gherkin
/// @smoke
/// Feature: Login
///   Background:
///     Given I am on the login page
///
///   Scenario: Successful login
///     When I enter {'test@example.com'} in the email field
///     Then the home screen is displayed
/// ```
///
/// 4. Write step functions using [TestDriver]:
/// ```dart
/// import 'package:co_test_gen/co_test_gen.dart';
///
/// Future<void> iAmOnTheLoginPage(TestDriver driver) async {
///   await driver.pumpWidget(const LoginPage());
///   await driver.settle();
/// }
/// ```
///
/// 5. Run `dart run build_runner build` to generate test files.
library;

export 'src/driver/patrol_test_driver.dart';
export 'src/driver/test_driver.dart';
export 'src/driver/widget_test_driver.dart';
export 'src/generator/dual_test_builder.dart';
export 'src/generator/feature_parser.dart';
export 'src/generator/test_generator.dart';
