import 'package:co_bdd/src/driver/test_driver.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

/// [WidgetTester]-based [TestDriver] implementation.
///
/// Internally uses [PatrolTester] from `patrol_finders` for a concise,
/// chainable finder API (`$(finder).tap()`). Step functions remain
/// unchanged because [TestDriver]'s external interface is preserved.
///
/// ```dart
/// testWidgets('login success', (tester) async {
///   final driver = WidgetTestDriver(tester);
///   await iAmOnTheLoginPage(driver);
///   await iTapTheLoginButton(driver);
/// });
/// ```
///
/// To customize timeouts, pass a [PatrolTesterConfig]:
/// ```dart
/// final driver = WidgetTestDriver(
///   tester,
///   config: const PatrolTesterConfig(
///     settleTimeout: Duration(seconds: 30),
///   ),
/// );
/// ```
class WidgetTestDriver extends TestDriver {
  /// Creates a driver wrapping [tester]. Optionally accepts a custom
  /// [PatrolTesterConfig]; defaults to `PatrolTesterConfig()`.
  WidgetTestDriver(
    this.tester, {
    PatrolTesterConfig config = const PatrolTesterConfig(),
  }) : patrolTester = PatrolTester(tester: tester, config: config);

  /// The underlying [WidgetTester] instance.
  final WidgetTester tester;

  /// The [PatrolTester] wrapping [tester]. Exposed so that step
  /// implementations can access advanced finder APIs when needed.
  final PatrolTester patrolTester;

  @override
  Future<void> tap(Key key) async {
    await patrolTester(find.byKey(key)).tap();
  }

  @override
  Future<void> tapText(String text) async {
    await patrolTester(text).tap();
  }

  @override
  Future<void> enterText(Key key, String text) async {
    final descendant = find.descendant(
      of: find.byKey(key),
      matching: find.byType(EditableText),
    );
    if (descendant.evaluate().isNotEmpty) {
      await patrolTester(descendant.first).enterText(text);
    } else {
      await patrolTester(find.byKey(key)).enterText(text);
    }
  }

  @override
  Future<void> expectVisible(Key key) async {
    expect(patrolTester(find.byKey(key)), findsOneWidget);
  }

  @override
  Future<void> expectTextVisible(String text) async {
    expect(patrolTester(text), findsWidgets);
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

  @override
  Future<void> expectNotVisible(Key key) async {
    expect(find.byKey(key), findsNothing);
  }

  @override
  Future<void> expectCount(Key key, int count) async {
    expect(find.byKey(key), findsNWidgets(count));
  }

  @override
  Future<void> tapAtIndex(Key key, int index) async {
    await patrolTester(find.byKey(key).at(index)).tap();
  }

  @override
  Future<void> scrollUntilVisible(Key key) async {
    await patrolTester(find.byKey(key)).scrollTo();
  }

  @override
  Future<void> expectContainsText(Key key, String text) async {
    final finder = find.descendant(
      of: find.byKey(key),
      matching: find.text(text, findRichText: true),
    );
    expect(finder, findsWidgets);
  }

  @override
  Future<void> longPress(Key key) async {
    await tester.longPress(find.byKey(key));
    await tester.pump();
  }

  /// Sends the `popRoute` message the engine sends on Android's system back, so
  /// the app's own back handling (`Navigator`, `Router`, `PopScope`) really
  /// runs. Flutter's own tests simulate the back button the same way.
  ///
  /// The leaving route stays in the tree until its transition ends (about
  /// 300–500 ms), so a following "should not be displayed" would still fail
  /// after the usual 100 ms [settle]. The fake clock is advanced by one second
  /// to let it finish.
  ///
  /// With nothing left to pop (the root route) the framework would close the
  /// app on a device; here the call just returns, and the scenario's `Then`
  /// steps decide what that means.
  @override
  Future<void> pressBack() async {
    final message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('popRoute'),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}
