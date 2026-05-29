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

// Driver
export 'src/driver/patrol_test_driver.dart';
export 'src/driver/test_driver.dart';
export 'src/driver/widget_test_driver.dart';

// Generator (build-time only)
//
// ⚠️ 생성된 `*.widget_test.dart` / step 파일이 이 런타임 배럴을 import 하므로,
// build-time 전용 generator(=`package:build`/`analyzer` 의존)를 여기서 export 하면
// 런타임 테스트 컴파일에 `build`/`analyzer` 가 끌려 들어가 버전 비호환(analyzer 10 ↔
// build 4.x) 으로 컴파일이 깨진다. generator 는 build_runner 엔트리인 `builder.dart`
// 에서만 직접 사용하므로 배럴에서 제외한다. (kobic#6398)

// Keys
export 'src/key/common_keys.dart';

// Steps
export 'src/step/auth_steps.dart';
export 'src/step/navigation_steps.dart';
export 'src/step/search_steps.dart';
