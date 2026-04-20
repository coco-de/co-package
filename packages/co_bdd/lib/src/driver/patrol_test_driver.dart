// patrol 4.x에서 $.native 는 deprecated(→ platformAutomator) 이지만
// 해당 대체 API의 메서드 시그니처(pressHome/openQuickSettings/pressBack)가
// 아직 동일하게 제공되지 않아 당분간 native 를 유지한다.
// ignore_for_file: deprecated_member_use

import 'package:co_test_gen/src/driver/test_driver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

/// Patrol-based [TestDriver] implementation.
///
/// Wraps [PatrolIntegrationTester] for BDD Patrol E2E tests, sharing
/// step functions with widget tests through the [TestDriver] abstraction.
///
/// ```dart
/// patrolTest('login success', ($) async {
///   final driver = PatrolTestDriver($);
///   await iAmOnTheLoginPage(driver);
///   await iTapTheLoginButton(driver);
/// });
/// ```
class PatrolTestDriver extends TestDriver {
  /// Creates a driver wrapping the Patrol tester [$].
  PatrolTestDriver(this.$);

  /// The underlying [PatrolIntegrationTester] instance.
  final PatrolIntegrationTester $;

  @override
  Future<void> tap(Key key) async {
    await $(find.byKey(key)).tap();
  }

  @override
  Future<void> tapText(String text) async {
    await $(text).tap();
  }

  @override
  Future<void> enterText(Key key, String text) async {
    final descendant = find.descendant(
      of: find.byKey(key),
      matching: find.byType(EditableText),
    );
    if (descendant.evaluate().isNotEmpty) {
      await $(descendant.first).enterText(text);
    } else {
      await $(find.byKey(key)).enterText(text);
    }
  }

  @override
  Future<void> expectVisible(Key key) async {
    expect($(find.byKey(key)), findsOneWidget);
  }

  @override
  Future<void> expectTextVisible(String text) async {
    expect($(text), findsWidgets);
  }

  @override
  Future<void> pumpWidget(Widget widget) async {
    await $.pumpWidgetAndSettle(widget);
  }

  @override
  Future<void> settle({Duration? timeout}) async {
    await $.pump(timeout ?? const Duration(seconds: 5));
  }

  @override
  Future<void> wait(Duration duration) async {
    await $.pump(duration);
  }

  @override
  Future<void> pressHome() async {
    await $.native.pressHome();
  }

  @override
  Future<void> openNotifications() async {
    await $.native.openQuickSettings();
  }

  @override
  Future<void> pressBack() async {
    await $.native.pressBack();
  }
}
