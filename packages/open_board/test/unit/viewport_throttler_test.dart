import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/live/domain/batcher/viewport_throttler.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';

void main() {
  group('ViewportThrottler', () {
    late ViewportThrottler throttler;
    late List<ViewportMessage> emitted;

    setUp(() {
      emitted = [];
      throttler = ViewportThrottler(onThrottled: emitted.add);
    });

    tearDown(() => throttler.dispose());

    ViewportMessage msg({double scale = 1.0, int ts = 0}) => ViewportMessage(
          pageId: 'p1',
          scale: scale,
          centerX: 100,
          centerY: 200,
          viewportWidth: 800,
          viewportHeight: 600,
          timestampMicros: ts,
        );

    test('100ms 내 여러 변경 중 마지막 값만 전송', () {
      fakeAsync((async) {
        throttler.onViewportChanged(msg(scale: 1.0, ts: 1));
        throttler.onViewportChanged(msg(scale: 1.5, ts: 2));
        throttler.onViewportChanged(msg(scale: 2.0, ts: 3));

        expect(emitted, isEmpty);

        async.elapse(const Duration(milliseconds: 100));

        expect(emitted, hasLength(1));
        expect(emitted[0].scale, 2.0);
        expect(emitted[0].timestampMicros, 3);
      });
    });

    test('100ms 이후 새 변경은 새 윈도우 시작', () {
      fakeAsync((async) {
        throttler.onViewportChanged(msg(scale: 1.0, ts: 1));
        async.elapse(const Duration(milliseconds: 100));

        expect(emitted, hasLength(1));

        throttler.onViewportChanged(msg(scale: 3.0, ts: 200));
        async.elapse(const Duration(milliseconds: 100));

        expect(emitted, hasLength(2));
        expect(emitted[1].scale, 3.0);
      });
    });

    test('dispose 후 타이머 정리', () {
      fakeAsync((async) {
        throttler.onViewportChanged(msg(scale: 1.0, ts: 1));
        throttler.dispose();
        async.elapse(const Duration(milliseconds: 200));

        expect(emitted, isEmpty);
      });
    });
  });
}
