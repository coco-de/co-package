import 'dart:async';

import 'package:co_bdd/co_bdd.dart';
import 'package:co_bdd/shared_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  PatrolTestDriver driver(WidgetTester tester) => PatrolTestDriver(
    PatrolIntegrationTester(
      tester: tester,
      config: const PatrolTesterConfig(),
      platformAutomator: _UnusedPlatform(),
    ),
  );

  testWidgets('existing settle keeps its five-second pump', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final before = tester.binding.clock.now();
    await driver(tester).settle();
    expect(
      tester.binding.clock.now().difference(before),
      const Duration(seconds: 5),
    );
  });

  testWidgets(
    'existing settle accepts repeating animation and custom duration',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CircularProgressIndicator()),
      );
      final before = tester.binding.clock.now();
      await driver(tester).settle(timeout: const Duration(milliseconds: 300));
      expect(
        tester.binding.clock.now().difference(before),
        const Duration(milliseconds: 300),
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('shared steps retain their wait for delayed response state', (
    tester,
  ) async {
    Timer? response;
    var ready = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                TextButton(
                  key: const Key('continue'),
                  onPressed: () {
                    response = Timer(
                      const Duration(seconds: 3),
                      () => setState(() => ready = true),
                    );
                  },
                  child: const Text('Continue'),
                ),
                Text(ready ? 'ready' : 'pending'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await iTapTheWidget(driver(tester), 'continue');
      await driver(tester).expectTextVisible('ready');
    } finally {
      response?.cancel();
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('new waitUntil returns immediately for prepared Patrol state', (
    tester,
  ) async {
    final before = tester.binding.clock.now();
    await driver(tester).waitUntil(() => true);
    expect(tester.binding.clock.now(), before);
  });

  testWidgets('new waitUntil observes state despite repeating animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CircularProgressIndicator()),
    );
    var ready = false;
    final response = Timer(
      const Duration(milliseconds: 120),
      () => ready = true,
    );
    final before = tester.binding.clock.now();
    try {
      await driver(tester).waitUntil(() => ready);
      expect(
        tester.binding.clock.now().difference(before),
        const Duration(milliseconds: 150),
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
    } finally {
      response.cancel();
      await tester.pumpWidget(const SizedBox());
    }
  });
}

class _UnusedPlatform implements PlatformAutomator {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('No native calls in this test');
}
