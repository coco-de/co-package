import 'package:example/web_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theme switch updates terminal app chrome', (tester) async {
    await tester.pumpWidget(const TerminalExampleApp());
    await tester.pumpAndSettle();
    final bar = find.byType(AppBar);
    final before = Theme.of(tester.element(bar)).brightness;
    await tester.tap(find.byKey(const ValueKey('example-theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(bar)).brightness, isNot(before));
  });
}
