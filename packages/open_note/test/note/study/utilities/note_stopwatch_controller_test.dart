import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import 'support/manual_note_ticker.dart';
import 'support/utility_test_helpers.dart';

const _second = Duration(seconds: 1);

({NoteStopwatchController watch, ManualNoteTicker ticker}) _create({
  int maxLaps = 999,
}) {
  final ticker = ManualNoteTicker();
  final watch = NoteStopwatchController(ticker: ticker, maxLaps: maxLaps);
  addTearDown(watch.dispose);

  return (watch: watch, ticker: ticker);
}

void main() {
  group('NoteStopwatchController', () {
    test('starts idle at zero', () {
      final watch = _create().watch;

      expect(watch.status, NoteStopwatchStatus.idle);
      expect(watch.elapsed, Duration.zero);
      expect(watch.laps, isEmpty);
    });

    test('counts up while running', () {
      final (:watch, :ticker) = _create();

      watch.start();
      ticker
        ..elapse(const Duration(seconds: 3))
        ..elapse(const Duration(seconds: 4));

      expect(watch.isRunning, isTrue);
      expect(watch.elapsed, const Duration(seconds: 7));
    });

    test('pause keeps the passed time and start continues', () {
      final (:watch, :ticker) = _create();
      watch
        ..start()
        ..tick(_second);
      ticker.pending = const Duration(milliseconds: 250);

      watch.pause();
      watch.tick(_second);

      expect(watch.status, NoteStopwatchStatus.paused);
      expect(watch.elapsed, const Duration(milliseconds: 1250));
      expect(ticker.isActive, isFalse);

      watch.start();
      ticker.elapse(_second);
      expect(watch.elapsed, const Duration(milliseconds: 2250));
    });

    test('records laps with splits and totals', () {
      final (:watch, :ticker) = _create();
      watch
        ..start()
        ..tick(const Duration(seconds: 12));
      watch.lap();
      watch.tick(const Duration(seconds: 8));
      ticker.pending = const Duration(milliseconds: 500);
      watch.lap();

      expect(watch.laps, const [
        NoteStopwatchLap(
          number: 1,
          total: Duration(seconds: 12),
          split: Duration(seconds: 12),
        ),
        NoteStopwatchLap(
          number: 2,
          total: Duration(milliseconds: 20500),
          split: Duration(milliseconds: 8500),
        ),
      ]);
      expect(watch.laps.removeLast, throwsUnsupportedError);
    });

    test('only laps while running, up to maxLaps', () {
      final watch = _create(maxLaps: 2).watch..lap();
      expect(watch.laps, isEmpty);

      watch
        ..start()
        ..lap()
        ..lap()
        ..lap();
      expect(watch.laps, hasLength(2));

      watch.pause();
      watch.lap();
      expect(watch.laps, hasLength(2));
    });

    test('reset returns to zero without laps', () {
      final (:watch, :ticker) = _create();
      watch
        ..start()
        ..tick(_second)
        ..lap()
        ..reset();

      expect(watch.status, NoteStopwatchStatus.idle);
      expect(watch.elapsed, Duration.zero);
      expect(watch.laps, isEmpty);
      expect(ticker.isActive, isFalse);
    });

    test('ignores ticks unless running, and non-positive ticks', () {
      final watch = _create().watch..tick(_second);
      expect(watch.elapsed, Duration.zero);

      watch
        ..start()
        ..tick(Duration.zero)
        ..tick(const Duration(seconds: -1));
      expect(watch.elapsed, Duration.zero);
    });

    test('notifies only on real changes', () {
      final watch = _create().watch;
      final calls = countNotifications(watch);

      watch
        ..pause()
        ..reset()
        ..lap()
        ..tick(_second);
      expect(calls, isEmpty);

      watch.start();
      watch.start();
      expect(calls, hasLength(1));
      watch.tick(_second);
      expect(calls, hasLength(2));
    });

    test('does nothing after dispose', () {
      final ticker = ManualNoteTicker();
      final watch = NoteStopwatchController(ticker: ticker)..start();

      watch.dispose();

      expect(ticker.isActive, isFalse);
      expect(
        () => watch
          ..start()
          ..pause()
          ..lap()
          ..reset()
          ..tick(_second)
          ..dispose(),
        returnsNormally,
      );
    });
  });

  group('NoteStopwatchLap', () {
    const lap = NoteStopwatchLap(
      number: 3,
      total: Duration(milliseconds: 90500),
      split: Duration(milliseconds: 30250),
    );

    test('round-trips through JSON', () {
      expect(lap.toJson(), {'number': 3, 'totalMs': 90500, 'splitMs': 30250});
      expect(NoteStopwatchLap.fromJson(lap.toJson()), lap);
      expect(NoteStopwatchLap.fromJson(lap.toJson()).hashCode, lap.hashCode);
    });

    test('reads malformed values leniently', () {
      const fallback = NoteStopwatchLap(
        number: 1,
        total: Duration.zero,
        split: Duration.zero,
      );

      expect(NoteStopwatchLap.fromJson(null), fallback);
      expect(NoteStopwatchLap.fromJson('lap'), fallback);
      expect(
        NoteStopwatchLap.fromJson({
          'number': -4,
          'totalMs': -10,
          'splitMs': 'x',
        }),
        fallback,
      );
    });

    test('copies with changes', () {
      expect(lap.copyWith(number: 4).number, 4);
      expect(lap.copyWith(total: Duration.zero).total, Duration.zero);
      expect(lap.copyWith(), lap);
      expect(lap.copyWith(split: Duration.zero), isNot(lap));
    });
  });
}
