import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import '../../support/note_test_host.dart';
import 'support/manual_note_ticker.dart';
import 'support/utility_test_helpers.dart';

const _primary = ValueKey('stopwatch-primary');
const _lap = ValueKey('stopwatch-lap');
const _reset = ValueKey('stopwatch-reset');

void main() {
  late ManualNoteTicker ticker;
  late NoteStopwatchController controller;

  setUp(() {
    ticker = ManualNoteTicker();
    controller = NoteStopwatchController(ticker: ticker);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpView(WidgetTester tester, {double maxLapsHeight = 160}) =>
      tester.pumpWidget(
        noteTestHost(
          Center(
            child: NoteStopwatchView(
              controller: controller,
              maxLapsHeight: maxLapsHeight,
            ),
          ),
        ),
      );

  testWidgets('shows whole elapsed seconds', (tester) async {
    await pumpView(tester);
    expect(find.text('00:00'), findsOneWidget);
    await tapKey(tester, _primary);

    ticker.elapse(const Duration(seconds: 61, milliseconds: 900));
    await tester.pump();

    expect(find.text('01:01'), findsOneWidget);
  });

  testWidgets('shows hours above an hour', (tester) async {
    await pumpView(tester);
    await tapKey(tester, _primary);

    ticker.elapse(const Duration(hours: 2, seconds: 5));
    await tester.pump();

    expect(find.text('2:00:05'), findsOneWidget);
  });

  testWidgets('starts, pauses, resumes and resets', (tester) async {
    await pumpView(tester);
    expect(isButtonEnabled(tester, _lap), isFalse);
    expect(isButtonEnabled(tester, _reset), isFalse);

    await tapKey(tester, _primary);
    expect(semanticLabelOf(tester, _primary), 'Pause');
    expect(isButtonEnabled(tester, _lap), isTrue);

    await tapKey(tester, _primary);
    expect(controller.status, NoteStopwatchStatus.paused);
    expect(semanticLabelOf(tester, _primary), 'Resume');
    expect(isButtonEnabled(tester, _lap), isFalse);

    await tapKey(tester, _primary);
    expect(controller.status, NoteStopwatchStatus.running);

    await tapKey(tester, _reset);
    expect(controller.status, NoteStopwatchStatus.idle);
    expect(semanticLabelOf(tester, _primary), 'Start');
  });

  testWidgets('lists laps newest first with split and total', (tester) async {
    await pumpView(tester);
    await tapKey(tester, _primary);
    ticker.elapse(const Duration(seconds: 10));
    await tapKey(tester, _lap);
    ticker.elapse(const Duration(seconds: 25));
    await tapKey(tester, _lap);

    expect(find.text('Lap 1'), findsOneWidget);
    expect(find.text('Lap 2'), findsOneWidget);
    expect(find.text('00:25'), findsOneWidget);
    expect(find.text('00:35'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Lap 2')).dy,
      lessThan(tester.getTopLeft(find.text('Lap 1')).dy),
    );
  });

  testWidgets('can hide the lap list', (tester) async {
    await pumpView(tester, maxLapsHeight: 0);
    await tapKey(tester, _primary);
    await tapKey(tester, _lap);

    expect(controller.laps, hasLength(1));
    expect(find.text('Lap 1'), findsNothing);
  });

  testWidgets('a long lap list scrolls within its height', (tester) async {
    await pumpView(tester, maxLapsHeight: 60);
    controller.start();
    for (var i = 0; i < 20; i++) {
      controller
        ..tick(const Duration(seconds: 1))
        ..lap();
    }
    await tester.pump();

    expect(find.text('Lap 20'), findsOneWidget);
    expect(find.text('Lap 1'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();
    expect(find.text('Lap 1'), findsOneWidget);
  });
}
