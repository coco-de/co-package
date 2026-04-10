import 'package:co_test_gen/src/driver/test_driver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Patrol-based [TestDriver] implementation.
///
/// Used in BDD Patrol E2E tests to share step functions with widget tests.
///
/// Requires `package:patrol` as a dependency in your project.
/// The `PatrolIntegrationTester` type is not imported here to avoid
/// a hard dependency on patrol; instead, it accepts `dynamic` and
/// uses duck typing for the patrol-specific API.
///
/// ```dart
/// patrolTest('login success', ($) async {
///   final driver = PatrolTestDriver($);
///   await iAmOnTheLoginPage(driver);
///   await iTapTheLoginButton(driver);
/// });
/// ```
// ignore_for_file: avoid-dynamic
class PatrolTestDriver extends TestDriver {
  /// Creates a driver wrapping the Patrol tester [$].
  PatrolTestDriver(this.$);

  /// The underlying `PatrolIntegrationTester` instance.
  final dynamic $;

  @override
  Future<void> tap(Key key) async {
    // ignore: avoid-dynamic
    await ($ as dynamic).call(find.byKey(key)).tap() as Future<void>;
  }

  @override
  Future<void> tapText(String text) async {
    await ($ as dynamic).call(text).tap() as Future<void>;
  }

  @override
  Future<void> enterText(Key key, String text) async {
    final descendant = find.descendant(
      of: find.byKey(key),
      matching: find.byType(EditableText),
    );
    if (descendant.evaluate().isNotEmpty) {
      await ($ as dynamic).call(descendant.first).enterText(text)
          as Future<void>;
    } else {
      await ($ as dynamic).call(find.byKey(key)).enterText(text)
          as Future<void>;
    }
  }

  @override
  Future<void> expectVisible(Key key) async {
    expect(($ as dynamic).call(find.byKey(key)), findsOneWidget);
  }

  @override
  Future<void> expectTextVisible(String text) async {
    expect(($ as dynamic).call(text), findsWidgets);
  }

  @override
  Future<void> pumpWidget(Widget widget) async {
    await ($ as dynamic).pumpWidgetAndSettle(widget) as Future<void>;
  }

  @override
  Future<void> settle({Duration? timeout}) async {
    await ($ as dynamic).pump(timeout ?? const Duration(seconds: 5))
        as Future<void>;
  }

  @override
  Future<void> wait(Duration duration) async {
    await ($ as dynamic).pump(duration) as Future<void>;
  }

  @override
  Future<void> pressHome() async {
    await ($ as dynamic).native.pressHome() as Future<void>;
  }

  @override
  Future<void> openNotifications() async {
    await ($ as dynamic).native.openQuickSettings() as Future<void>;
  }

  @override
  Future<void> pressBack() async {
    await ($ as dynamic).native.pressBack() as Future<void>;
  }
}
