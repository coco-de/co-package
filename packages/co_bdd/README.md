# co_bdd

BDD Dual Test Generator for Flutter — write Gherkin `.feature` files once, generate both **Widget Tests** and **Patrol E2E Tests** with shared step functions.

## Why?

Widget tests and Patrol E2E tests serve different purposes but often test the same user flows. Writing step functions twice is wasteful. `co_bdd` solves this with:

1. **`TestDriver`** — an abstract interface that wraps both `WidgetTester` and `PatrolIntegrationTester`
2. **`DualTestBuilder`** — a `build_runner` builder that generates `.widget_test.dart` and `.patrol_test.dart` from a single `.feature` file

## Quick Start

### 1. Add dependencies

```yaml
dev_dependencies:
  co_bdd:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_bdd
      ref: co_bdd-vX.Y.Z # or a commit SHA
  build_runner: ^2.4.0
```

### 2. Configure `build.yaml`

```yaml
targets:
  $default:
    builders:
      co_bdd|dual_test_gen:
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
| `sharedStepsImport` | `package:co_bdd/shared_steps.dart` | Import URI for the shared step library. |
| `sharedStepNames` | every step `shared_steps.dart` exports | Step file names to resolve from the shared package. Give it only to narrow the set. |
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
import 'package:co_bdd/co_bdd.dart';

Future<void> iAmOnTheLoginPage(TestDriver driver) async {
  await driver.pumpWidget(const LoginPage());
  await driver.settle();
}
```

```dart
// test/src/bdd/step/i_tap_the_login_button.dart
import 'package:co_bdd/co_bdd.dart';
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

## Shared steps

`package:co_bdd/shared_steps.dart` ships domain-free steps that take widget keys
or texts as parameters, so every project reuses **the same implementation**
instead of re-creating `i_tap_the_save_button.dart`-style local steps.

```yaml
options:
  sharedSteps: true # every step below; new ones arrive with a co_bdd bump
```

To add project steps, point `sharedStepsImport` at your own barrel that
re-exports this library, and list the extra names in `sharedStepNames`
together with the co_bdd ones you keep.

| Gherkin phrase | Step |
|---|---|
| `I tap the {'key'} widget` | `iTapTheWidget` |
| `I tap the {'key'} widget at index {'N'}` | `iTapTheWidgetAtIndex` (0-based) |
| `I tap the {'text'} text` | `iTapTheText` |
| `I long press the {'key'} widget` | `iLongPressTheWidget` |
| `I enter {'value'} in the {'key'} widget` | `iEnterInTheWidget` |
| `I clear the {'key'} widget` | `iClearTheWidget` |
| `I scroll until the {'key'} widget is visible` | `iScrollUntilTheWidgetIsVisible` |
| `I wait for {'N'} seconds` | `iWaitForSeconds` |
| `the {'key'} widget should be displayed` / `should not be displayed` | `theWidgetShouldBeDisplayed` / `theWidgetShouldNotBeDisplayed` |
| `the {'text'} text should be displayed` | `theTextShouldBeDisplayed` |
| `I should see {'N'} {'key'} widgets` | `iShouldSeeWidgets` |
| `the {'key'} widget should contain {'text'} text` | `theWidgetShouldContainText` |
| `the {'key'} widget should be selected` / `should not be selected` | Semantics `isSelected` |
| `the {'key'} widget should be enabled` / `should be disabled` | declared `Semantics(enabled:)` under the key |
| `the {'key'} toggle should be on` / `should be off` | declared `Semantics(toggled:)` under the key |
| `the current page should be {'N'}` | exact label of the `current_page_indicator` key |
| `the {'panel'} widget should be anchored to {'anchor'}` | popover `bottomEnd` placement |
| `the error message` / `loading indicator` / `success message` / `total count` `should be displayed`, `I confirm deletion`, `I tap the next page button` | fixed phrases on `CommonKeys` |

Keep **domain** steps local: `Given` page mounts and mock state, composite
actions, and steps whose name claims more than a key check (e.g. "the review
should be deleted") — rewriting those to a shared phrase silently weakens what
the scenario verifies.

State steps (enabled · toggled · selected) read what the control **declares to
assistive technologies** — `Semantics(enabled:)`, `Semantics(toggled:)` — instead of
design-system widget types, so the same phrase works for CoUI and Material
controls. They fail when the key has no such declaration or more than one, rather
than silently picking the first control.

## Test helpers

Exported from `package:co_bdd/co_bdd.dart`.

| Helper | Purpose |
|---|---|
| `testScaleVariants(description, body, scaling: …)` · `ScaleVariant` | Runs one widget test body across `scaling × textScaler` combinations (`kDefaultScaleInvariantTextScalers` = 1, 1.15, 1.3, 2). `scaling` is required — the project adapter supplies its design system's default |
| `expectNoLayoutOverflow` · `expectNoTextClipping` | Layout exceptions, and text silently clamped by a fixed height (which throws nothing) |
| `waitForBlocState` · `pumpFramesUntilBlocState` | Wait on a `bloc_signals` state signal instead of fixed delays |
| `installFakeWebViewPlatform()` | Mount screens that embed a web view in widget tests |
| `declaredSemanticsFlag` · `widgetTesterOf` | Building blocks for your own state steps |

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
