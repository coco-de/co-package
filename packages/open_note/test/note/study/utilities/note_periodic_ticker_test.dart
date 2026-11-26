import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';

const _interval = Duration(milliseconds: 100);

NotePeriodicTicker _ticker(FakeAsync async) =>
    NotePeriodicTicker(interval: _interval, now: () => async.elapsed);

void main() {
  group('NotePeriodicTicker', () {
    test('reports the time of every interval', () {
      fakeAsync((async) {
        final reports = <Duration>[];
        _ticker(async).start(reports.add);

        async.elapse(const Duration(milliseconds: 350));

        expect(reports, [_interval, _interval, _interval]);
      });
    });

    test('reports all the time when callbacks come late', () {
      fakeAsync((async) {
        var now = Duration.zero;
        final reports = <Duration>[];
        NotePeriodicTicker(
          interval: _interval,
          now: () => now,
        ).start(reports.add);

        now = const Duration(seconds: 5);
        async.elapse(_interval);

        expect(reports, [const Duration(seconds: 5)]);
      });
    });

    test('drain takes the unreported time exactly once', () {
      fakeAsync((async) {
        final ticker = _ticker(async);
        final reports = <Duration>[];
        ticker.start(reports.add);

        async.elapse(const Duration(milliseconds: 140));
        final drained = ticker.drain();
        async.elapse(const Duration(milliseconds: 60));

        expect(drained, const Duration(milliseconds: 40));
        expect(ticker.drain(), Duration.zero);
        expect(
          reports.fold(Duration.zero, (sum, next) => sum + next) + drained,
          const Duration(milliseconds: 200),
        );
      });
    });

    test('stops reporting', () {
      fakeAsync((async) {
        final ticker = _ticker(async);
        final reports = <Duration>[];
        ticker.start(reports.add);
        expect(ticker.isActive, isTrue);

        ticker.stop();
        async.elapse(const Duration(seconds: 1));

        expect(reports, isEmpty);
        expect(ticker.isActive, isFalse);
        expect(ticker.drain(), Duration.zero);
        expect(async.pendingTimers, isEmpty);
        ticker.stop();
      });
    });

    test('start replaces the previous run', () {
      fakeAsync((async) {
        final ticker = _ticker(async);
        final first = <Duration>[];
        final second = <Duration>[];
        ticker.start(first.add);
        async.elapse(const Duration(milliseconds: 150));

        ticker.start(second.add);
        async.elapse(_interval);

        expect(first, [_interval]);
        expect(second, [_interval]);
        expect(async.pendingTimers, hasLength(1));
        ticker.stop();
      });
    });

    test('a callback may stop the ticker', () {
      fakeAsync((async) {
        final ticker = _ticker(async);
        var reports = 0;
        ticker.start((_) {
          reports++;
          ticker.stop();
        });

        async.elapse(const Duration(seconds: 1));

        expect(reports, 1);
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
