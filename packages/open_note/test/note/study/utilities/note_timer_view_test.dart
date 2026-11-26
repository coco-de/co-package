import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import '../../support/note_test_host.dart';
import 'support/manual_note_ticker.dart';
import 'support/utility_test_helpers.dart';

const _primary = ValueKey('timer-primary');
const _reset = ValueKey('timer-reset');
const _decrease = ValueKey('timer-decrease');
const _increase = ValueKey('timer-increase');

Future<NoteTimerController> _pumpTimer(
  WidgetTester tester, {
  required ManualNoteTicker ticker,
  Duration duration = const Duration(minutes: 5),
  Duration? step = const Duration(minutes: 1),
  NoteStudyUtilitiesStrings strings = const NoteStudyUtilitiesStrings(),
}) async {
  final controller = NoteTimerController(duration: duration, ticker: ticker);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    noteTestHost(
      Center(
        child: NoteTimerView(
          controller: controller,
          step: step,
          strings: strings,
        ),
      ),
    ),
  );

  return controller;
}

void main() {
  testWidgets('shows the remaining time rounded up', (tester) async {
    final ticker = ManualNoteTicker();
    await _pumpTimer(tester, ticker: ticker);
    expect(find.text('05:00'), findsOneWidget);

    await tapKey(tester, _primary);
    ticker.elapse(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('05:00'), findsOneWidget);

    ticker.elapse(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('04:59'), findsOneWidget);
  });

  testWidgets('shows hours above an hour', (tester) async {
    await _pumpTimer(
      tester,
      ticker: ManualNoteTicker(),
      duration: const Duration(hours: 1, minutes: 2, seconds: 3),
    );

    expect(find.text('1:02:03'), findsOneWidget);
  });

  testWidgets('start, pause, resume and reset drive the controller', (
    tester,
  ) async {
    final ticker = ManualNoteTicker();
    final controller = await _pumpTimer(tester, ticker: ticker);
    expect(semanticLabelOf(tester, _primary), 'Start');
    expect(isButtonEnabled(tester, _reset), isFalse);

    await tapKey(tester, _primary);
    expect(controller.status, NoteTimerStatus.running);
    expect(semanticLabelOf(tester, _primary), 'Pause');

    await tapKey(tester, _primary);
    expect(controller.status, NoteTimerStatus.paused);
    expect(semanticLabelOf(tester, _primary), 'Resume');

    await tapKey(tester, _primary);
    expect(controller.status, NoteTimerStatus.running);

    ticker.elapse(const Duration(seconds: 30));
    await tapKey(tester, _reset);
    expect(controller.status, NoteTimerStatus.idle);
    expect(find.text('05:00'), findsOneWidget);
  });

  testWidgets('says when the time is up', (tester) async {
    final ticker = ManualNoteTicker();
    final controller = await _pumpTimer(
      tester,
      ticker: ticker,
      duration: const Duration(seconds: 2),
    );
    await tapKey(tester, _primary);

    ticker.elapse(const Duration(seconds: 2));
    await tester.pump();

    expect(controller.status, NoteTimerStatus.finished);
    expect(find.text("Time's up"), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    await tapKey(tester, _primary);
    expect(controller.status, NoteTimerStatus.running);
    expect(find.text("Time's up"), findsNothing);
  });

  testWidgets('the step buttons change the length while idle', (tester) async {
    final controller = await _pumpTimer(
      tester,
      ticker: ManualNoteTicker(),
      duration: const Duration(minutes: 1),
    );
    expect(find.text('+01:00'), findsOneWidget);
    expect(find.text('−01:00'), findsOneWidget);

    await tapKey(tester, _increase);
    expect(controller.duration, const Duration(minutes: 2));
    await tapKey(tester, _decrease);
    await tapKey(tester, _decrease);

    expect(controller.duration, Duration.zero);
    expect(isButtonEnabled(tester, _decrease), isFalse);
    expect(isButtonEnabled(tester, _primary), isFalse);
  });

  testWidgets('hides the step buttons while running or without a step', (
    tester,
  ) async {
    await _pumpTimer(tester, ticker: ManualNoteTicker());
    await tapKey(tester, _primary);
    expect(find.byKey(_increase), findsNothing);

    await _pumpTimer(tester, ticker: ManualNoteTicker(), step: null);
    expect(find.byKey(_increase), findsNothing);
  });

  testWidgets('uses the given strings', (tester) async {
    await _pumpTimer(
      tester,
      ticker: ManualNoteTicker(),
      strings: const NoteStudyUtilitiesStrings(start: '시작', reset: '초기화'),
    );

    expect(find.text('시작'), findsOneWidget);
    expect(find.text('초기화'), findsOneWidget);
  });
}
