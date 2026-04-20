import 'package:flutter/widgets.dart';

/// Abstract test driver shared between Widget Test and Patrol E2E.
///
/// This abstraction allows BDD step functions to work with both
/// [WidgetTester] (widget tests) and `PatrolIntegrationTester` (E2E tests)
/// through a unified interface.
///
/// ## Usage in step functions
///
/// ```dart
/// Future<void> iTapTheLoginButton(TestDriver driver) async {
///   await driver.tap(const Key('login_button'));
///   await driver.settle();
/// }
/// ```
///
/// ## Implementations
///
/// - [WidgetTestDriver] — wraps [WidgetTester] for widget tests
/// - [PatrolTestDriver] — wraps `PatrolIntegrationTester` for E2E tests
abstract class TestDriver {
  /// Taps the widget identified by [key].
  Future<void> tap(Key key);

  /// Taps the widget containing [text].
  Future<void> tapText(String text);

  /// Enters [text] into the text field identified by [key].
  Future<void> enterText(Key key, String text);

  /// Asserts that the widget identified by [key] is visible.
  Future<void> expectVisible(Key key);

  /// Asserts that a widget containing [text] is visible.
  Future<void> expectTextVisible(String text);

  /// Waits for all animations to complete.
  Future<void> settle({Duration? timeout});

  /// Waits for the specified [duration].
  Future<void> wait(Duration duration);

  /// Pumps a widget into the test environment.
  Future<void> pumpWidget(Widget widget) async {}

  // --- Extended assertions / actions ---

  /// Asserts that no widget identified by [key] exists in the tree.
  Future<void> expectNotVisible(Key key);

  /// Asserts exactly [count] widgets matching [key] exist.
  Future<void> expectCount(Key key, int count);

  /// Taps the widget at [index] among widgets matching [key].
  Future<void> tapAtIndex(Key key, int index);

  /// Scrolls the enclosing [Scrollable] until the widget identified by
  /// [key] becomes visible.
  Future<void> scrollUntilVisible(Key key);

  /// Asserts that the subtree rooted at [key] contains [text].
  Future<void> expectContainsText(Key key, String text);

  /// Long-presses the widget identified by [key].
  Future<void> longPress(Key key);

  // --- Patrol-only (no-op in widget tests) ---

  /// Presses the home button (Patrol only).
  Future<void> pressHome() async {}

  /// Opens the notification shade (Patrol only).
  Future<void> openNotifications() async {}

  /// Presses the back button (Patrol only).
  Future<void> pressBack() async {}
}
