import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/extentions/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('기본 밀리초 100ms', () {
      final debouncer = Debouncer();
      expect(debouncer.milliseconds, 100);
    });

    test('커스텀 밀리초', () {
      final debouncer = Debouncer(milliseconds: 500);
      expect(debouncer.milliseconds, 500);
    });

    test('디바운스 후 실행', () {
      fakeAsync((async) {
        final debouncer = Debouncer(milliseconds: 100);
        int callCount = 0;

        debouncer.run(() => callCount++);
        expect(callCount, 0);

        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 1);
      });
    });

    test('연속 호출 시 마지막만 실행', () {
      fakeAsync((async) {
        final debouncer = Debouncer(milliseconds: 100);
        int callCount = 0;

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => callCount++);

        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 1); // 마지막 호출만 실행
      });
    });

    test('타이머 만료 전에는 실행 안 됨', () {
      fakeAsync((async) {
        final debouncer = Debouncer(milliseconds: 200);
        int callCount = 0;

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 0);
      });
    });
  });
}
