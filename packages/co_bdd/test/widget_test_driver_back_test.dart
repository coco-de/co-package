import 'package:co_bdd/co_bdd.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `WidgetTestDriver.pressBack()` 동작 테스트 (#147).
///
/// 종전에는 빈 함수라 누르면 아무 일도 하지 않고 통과했다. 시스템 뒤로 가기와 같은
/// 경로로 앱의 `Navigator`·`PopScope` 처리가 실제로 돌아야 한다.
void main() {
  // 첫 화면의 버튼이 둘째 화면을 쌓는다. 둘째 화면은 [secondBody] 를 그린다.
  Future<WidgetTestDriver> pumpTwoRoutes(
    WidgetTester tester, {
    required Widget secondBody,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text('first'),
                TextButton(
                  key: const Key('open_second'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(body: secondBody),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return WidgetTestDriver(tester);
  }

  testWidgets('pops the route like the system back button', (tester) async {
    final driver = await pumpTwoRoutes(
      tester,
      secondBody: const Text('second'),
    );
    await driver.tap(const Key('open_second'));
    await driver.settle();
    expect(find.text('second'), findsOneWidget);

    await driver.pressBack();

    expect(find.text('second'), findsNothing);
    expect(find.text('first'), findsOneWidget);
  });

  testWidgets('goes through PopScope, so a blocked screen stays', (
    tester,
  ) async {
    var blocked = 0;
    final driver = await pumpTwoRoutes(
      tester,
      secondBody: PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) blocked++;
        },
        child: const Text('second'),
      ),
    );
    await driver.tap(const Key('open_second'));
    await driver.settle();

    await driver.pressBack();

    expect(blocked, 1, reason: '뒤로 가기가 PopScope 까지 전달돼야 한다');
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('ends without an error on the root route', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('root')));
    final driver = WidgetTestDriver(tester);

    await driver.pressBack();

    expect(find.text('root'), findsOneWidget);
  });
}
