# co_test_gen

BDD Dual Test Generator for Flutter — write Gherkin `.feature` files once, generate both **Widget Tests** and **Patrol E2E Tests** with shared step functions.

## Why?

Widget tests and Patrol E2E tests serve different purposes but often test the same user flows. Writing step functions twice is wasteful. `co_test_gen` solves this with:

1. **`TestDriver`** — an abstract interface that wraps both `WidgetTester` and `PatrolIntegrationTester`
2. **`DualTestBuilder`** — a `build_runner` builder that generates `.widget_test.dart` and `.patrol_test.dart` from a single `.feature` file

## Quick Start

### 1. Add dependencies

```yaml
dev_dependencies:
  co_test_gen: ^0.1.0
  build_runner: ^2.4.0
```

### 2. Configure `build.yaml`

```yaml
targets:
  $default:
    builders:
      co_test_gen|dual_test_gen:
        enabled: true
        generate_for:
          - test/src/bdd/*.feature
        options:
          stepFolder: step
```

### 3. Write a `.feature` file

```gherkin
# test/src/bdd/login.feature
@smoke
Feature: Login
  Background:
    Given I am on the login page

  Scenario: Successful login
    When I enter {'test@example.com'} in the email field
    And I tap the login button
    Then the home screen is displayed

  @patrol-only
  Scenario: Login with biometrics
    When I authenticate with biometrics
    Then the home screen is displayed
```

### 4. Write step functions using `TestDriver`

```dart
// test/src/bdd/step/i_am_on_the_login_page.dart
import 'package:co_test_gen/co_test_gen.dart';

Future<void> iAmOnTheLoginPage(TestDriver driver) async {
  await driver.pumpWidget(const LoginPage());
  await driver.settle();
}
```

```dart
// test/src/bdd/step/i_tap_the_login_button.dart
import 'package:co_test_gen/co_test_gen.dart';
import 'package:flutter/widgets.dart';

Future<void> iTapTheLoginButton(TestDriver driver) async {
  await driver.tap(const Key('login_button'));
  await driver.settle();
}
```

### 5. Generate tests

```bash
dart run build_runner build
```

This generates:

- `login.widget_test.dart` — uses `WidgetTestDriver(tester)` → runs as a widget test
- `login.patrol_test.dart` — uses `PatrolTestDriver($)` → runs as a Patrol E2E test

Both call the same step functions.

## Scenario Tags

| Tag | Widget Test | Patrol E2E |
|-----|:-----------:|:----------:|
| *(none)* / `@both` | ✅ | ✅ |
| `@widget-only` | ✅ | ❌ |
| `@patrol-only` | ❌ | ✅ |

## TestDriver API

| Method | Widget Test | Patrol E2E |
|--------|-------------|------------|
| `tap(Key)` | `tester.tap(find.byKey(key))` | `$(find.byKey(key)).tap()` |
| `tapText(String)` | `tester.tap(find.text(text))` | `$(text).tap()` |
| `enterText(Key, String)` | `tester.enterText(...)` | `$(...).enterText(...)` |
| `expectVisible(Key)` | `expect(find.byKey(key), findsOneWidget)` | same |
| `expectTextVisible(String)` | `expect(find.text(text), findsWidgets)` | same |
| `settle()` | `tester.pump()` | `$.pump()` |
| `pumpWidget(Widget)` | `tester.pumpWidget(widget)` | `$.pumpWidgetAndSettle(widget)` |
| `pressHome()` | no-op | `$.native.pressHome()` |
| `pressBack()` | no-op | `$.native.pressBack()` |

## Parameters

Step parameters use `{'value'}` syntax in `.feature` files:

```gherkin
When I enter {'test@example.com'} in the email field
```

Generated code:

```dart
await iEnterInTheEmailField(driver, 'test@example.com');
```

Step function signature:

```dart
Future<void> iEnterInTheEmailField(TestDriver driver, String param1) async {
  await driver.enterText(const Key('email_field'), param1);
}
```

## License

MIT
