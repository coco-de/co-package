import 'package:co_test_gen/src/driver/test_driver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [WidgetTester]-based [TestDriver] implementation.
///
/// Used in BDD widget tests to share step functions with Patrol E2E tests.
///
/// ```dart
/// testWidgets('login success', (tester) async {
///   final driver = WidgetTestDriver(tester);
///   await iAmOnTheLoginPage(driver);
///   await iTapTheLoginButton(driver);
/// });
/// ```
class WidgetTestDriver extends TestDriver {
  /// Creates a driver wrapping [tester].
  WidgetTestDriver(this.tester);

  /// The underlying [WidgetTester] instance.
  final WidgetTester tester;

  @override
  Future<void> tap(Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  @override
  Future<void> tapText(String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
  }

  @override
  Future<void> enterText(Key key, String text) async {
    final descendant = find.descendant(
      of: find.byKey(key),
      matching: find.byType(EditableText),
    );
    if (descendant.evaluate().isNotEmpty) {
      await tester.enterText(descendant.first, text);
    } else {
      await tester.enterText(find.byKey(key), text);
    }
    await tester.pump();
  }

  @override
  Future<void> expectVisible(Key key) async {
    expect(find.byKey(key), findsOneWidget);
  }

  @override
  Future<void> expectTextVisible(String text) async {
    expect(find.text(text), findsWidgets);
  }

  @override
  Future<void> pumpWidget(Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
  }

  @override
  Future<void> settle({Duration? timeout}) async {
    await tester.pump();
    await tester.pump(timeout ?? const Duration(milliseconds: 100));
  }

  @override
  Future<void> wait(Duration duration) => tester.pump(duration);
}
