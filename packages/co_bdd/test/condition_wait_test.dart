import 'dart:async';

import 'package:co_bdd/co_bdd.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('already ready incurs no pump or fixed delay', (tester) async {
    final before = tester.binding.clock.now();
    await WidgetTestDriver(tester).waitUntil(() => true);
    expect(tester.binding.clock.now(), before);
  });

  testWidgets('advances fake time only until the state becomes ready', (
    tester,
  ) async {
    var ready = false;
    Timer(const Duration(milliseconds: 120), () => ready = true);
    final before = tester.binding.clock.now();
    await WidgetTestDriver(tester).waitUntil(() => ready);
    expect(
      tester.binding.clock.now().difference(before),
      const Duration(milliseconds: 150),
    );
  });

  testWidgets('times out exactly at the budget with a diagnostic', (
    tester,
  ) async {
    final before = tester.binding.clock.now();
    Object? failure;
    try {
      await WidgetTestDriver(tester).waitUntil(
        () => false,
        timeout: const Duration(milliseconds: 125),
        description: 'authenticated',
      );
    } on Object catch (error) {
      failure = error;
    }
    expect(
      failure,
      isA<TimeoutException>().having(
        (e) => e.message,
        'message',
        'authenticated',
      ),
    );
    expect(
      tester.binding.clock.now().difference(before),
      const Duration(milliseconds: 125),
    );
  });

  testWidgets('invalid intervals cannot hang a run', (tester) async {
    await expectLater(
      WidgetTestDriver(tester).waitUntil(() => false, interval: Duration.zero),
      throwsArgumentError,
    );
  });
}
