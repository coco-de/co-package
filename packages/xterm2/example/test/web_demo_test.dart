import 'package:example/web_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local shell dispatches commands and edits Unicode input', () {
    final output = StringBuffer();
    final shell = DemoShell(output.write);
    shell.write('echo 안녕\u007f하세요\r');
    expect(output.toString(), contains('안하세요\r\n'));
    shell.run('help');
    expect(output.toString(), contains('Show available commands'));
    shell.run('colors');
    expect(output.toString(), contains('\x1b[48;5;16m'));
    shell.write('\x1b[A');
    shell.write('echo OK\r');
    expect(output.toString(), contains('OK\r\n'));
    shell.run('missing');
    expect(output.toString(), contains('Unknown command: missing'));
  });

  testWidgets('terminal and controls fit a 320px screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TerminalExampleApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('terminal-view')), findsOneWidget);
    await tester.tap(find.text('colors'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
