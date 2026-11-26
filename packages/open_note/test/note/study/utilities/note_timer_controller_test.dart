import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

import 'support/manual_note_ticker.dart';
import 'support/utility_test_helpers.dart';

const _second = Duration(seconds: 1);
const _minute = Duration(minutes: 1);

({NoteTimerController timer, ManualNoteTicker ticker}) _create({
  Duration duration = _minute,
}) {
  final ticker = ManualNoteTicker();
  final timer = NoteTimerController(duration: duration, ticker: ticker);
  addTearDown(timer.dispose);

  return (timer: timer, ticker: ticker);
}

void main() {
  group('NoteTimerController', () {
    test('starts idle with the full length remaining', () {
      final timer = NoteTimerController(ticker: ManualNoteTicker());
      addTearDown(timer.dispose);

      expect(timer.status, NoteTimerStatus.idle);
      expect(timer.duration, NoteTimerController.defaultDuration);
      expect(timer.remaining, timer.duration);
      expect(timer.progress, 0);
    });

    test('clamps the length', () {
      expect(
        _create(duration: const Duration(seconds: -1)).timer.duration,
        Duration.zero,
      );
      expect(
        _create(duration: const Duration(hours: 200)).timer.duration,
        NoteTimerController.maxDuration,
      );
    });

    test('counts down while running and reports progress', () {
      final (:timer, :ticker) = _create();

      timer.start();
      ticker.elapse(const Duration(seconds: 15));

      expect(timer.status, NoteTimerStatus.running);
      expect(timer.remaining, const Duration(seconds: 45));
      expect(timer.progress, closeTo(0.25, 1e-9));
    });

    test('can be driven by tick directly', () {
      final timer = _create().timer..start();

      timer.tick(_second);

      expect(timer.remaining, const Duration(seconds: 59));
    });

    test('ignores ticks unless running, and non-positive ticks', () {
      final timer = _create().timer;

      timer.tick(_second);
      expect(timer.remaining, _minute);

      timer
        ..start()
        ..tick(Duration.zero)
        ..tick(const Duration(seconds: -3));
      expect(timer.remaining, _minute);
    });

    test('pause keeps the time that already passed', () {
      final (:timer, :ticker) = _create();
      timer.start();
      ticker.pending = const Duration(milliseconds: 700);

      timer.pause();

      expect(timer.status, NoteTimerStatus.paused);
      expect(timer.remaining, const Duration(milliseconds: 59300));
      expect(ticker.isActive, isFalse);
      timer.tick(_second);
      expect(timer.remaining, const Duration(milliseconds: 59300));
    });

    test('a pause that uses up the time finishes instead', () {
      final (:timer, :ticker) = _create(duration: _second);
      timer.start();
      ticker.pending = const Duration(seconds: 2);

      timer.pause();

      expect(timer.status, NoteTimerStatus.finished);
      expect(timer.remaining, Duration.zero);
    });

    test('resume continues a paused countdown', () {
      final (:timer, :ticker) = _create();
      timer
        ..start()
        ..tick(const Duration(seconds: 10))
        ..pause()
        ..resume();
      ticker.elapse(const Duration(seconds: 5));

      expect(timer.status, NoteTimerStatus.running);
      expect(timer.remaining, const Duration(seconds: 45));
      expect(ticker.starts, 2);
    });

    test('start resumes when paused', () {
      final timer = _create().timer
        ..start()
        ..tick(const Duration(seconds: 10))
        ..pause()
        ..start();

      expect(timer.status, NoteTimerStatus.running);
      expect(timer.remaining, const Duration(seconds: 50));
    });

    test('finishes once, stops the ticker and calls onFinished', () {
      var finished = 0;
      final ticker = ManualNoteTicker();
      final timer = NoteTimerController(
        duration: _second,
        ticker: ticker,
        onFinished: () => finished++,
      );
      addTearDown(timer.dispose);

      timer.start();
      ticker.elapse(const Duration(seconds: 3));
      timer
        ..tick(_second)
        ..pause()
        ..resume();

      expect(timer.status, NoteTimerStatus.finished);
      expect(timer.remaining, Duration.zero);
      expect(timer.progress, 1);
      expect(ticker.isActive, isFalse);
      expect(finished, 1);
    });

    test('start after finishing runs the full length again', () {
      final timer = _create(duration: _second).timer
        ..start()
        ..tick(_second)
        ..start();

      expect(timer.status, NoteTimerStatus.running);
      expect(timer.remaining, _second);
    });

    test('reset returns to idle from any state', () {
      final (:timer, :ticker) = _create();
      timer
        ..start()
        ..tick(const Duration(seconds: 10))
        ..reset();

      expect(timer.status, NoteTimerStatus.idle);
      expect(timer.remaining, _minute);
      expect(ticker.isActive, isFalse);
    });

    test('does not start a zero length', () {
      final (:timer, :ticker) = _create(duration: Duration.zero);

      timer.start();

      expect(timer.status, NoteTimerStatus.idle);
      expect(ticker.starts, 0);
      expect(timer.progress, 0);
    });

    test('setDuration stops a run and shows the new length', () {
      final (:timer, :ticker) = _create();
      timer
        ..start()
        ..tick(_second)
        ..setDuration(const Duration(minutes: 2));

      expect(timer.status, NoteTimerStatus.idle);
      expect(timer.remaining, const Duration(minutes: 2));
      expect(ticker.isActive, isFalse);
    });

    test('notifies only on real changes', () {
      final timer = _create().timer;
      final calls = countNotifications(timer);

      timer
        ..pause()
        ..resume()
        ..reset()
        ..tick(_second)
        ..setDuration(_minute);
      expect(calls, isEmpty);

      timer.setDuration(const Duration(minutes: 2));
      expect(calls, hasLength(1));
      timer.start();
      expect(calls, hasLength(2));
      timer.start();
      expect(calls, hasLength(2));
      timer.tick(_second);
      expect(calls, hasLength(3));
    });

    test('does nothing after dispose and can be disposed twice', () {
      final ticker = ManualNoteTicker();
      final timer = NoteTimerController(ticker: ticker)..start();

      timer.dispose();

      expect(ticker.isActive, isFalse);
      expect(
        () => timer
          ..start()
          ..pause()
          ..resume()
          ..reset()
          ..tick(_second)
          ..setDuration(_minute)
          ..dispose(),
        returnsNormally,
      );
    });
  });
}
