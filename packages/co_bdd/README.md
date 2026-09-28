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

#### Builder options

| Option | Default | Description |
|---|---|---|
| `stepFolder` | `step` | Directory holding local step files, relative to the `.feature`. |
| `sharedSteps` | `false` | Resolve known step names from a shared package instead of local files. |
| `sharedStepsImport` | `package:co_test_gen/shared_steps.dart` | Import URI for the shared step library. |
| `sharedStepNames` | built-in list | Step file names to resolve from the shared package. |
| `defaultTarget` | `both` | Execution target for scenarios that carry **no** target tag. One of `both` / `widget-only` / `patrol-only`. |

##### `defaultTarget` — don't generate what you can't run

By default every `.feature` produces **both** `*.widget_test.dart` and
`*.patrol_test.dart`. That is wrong for packages that can only run one of them.

Patrol needs a buildable app (`test_directory` plus a package name / bundle id).
A pure **library** package has no `main.dart`, so its generated
`*.patrol_test.dart` can never execute — it is dead weight that still gets
generated, formatted, committed, and reviewed. Measured in one consumer: **68
files / 6,875 lines** in that state, plus a `if (driver is PatrolTestDriver)
return;` guard in 384 step files written solely to keep those dead outputs
compiling.

Set the default per package and tag only the exceptions:

```yaml
options:
  defaultTarget: widget-only   # library package — Patrol cannot run here
```

```gherkin
Scenario: inherits the package default (widget-only)
  Then something happens

@patrol-only
Scenario: an explicit tag always wins over the default
  Then something happens
```

An unrecognised value throws rather than falling back silently — a typo in this
option would otherwise remove half your generated tests while the build still
reports success.

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
