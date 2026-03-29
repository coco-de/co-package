import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/managers/auto_save_scheduler.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AutoSaveScheduler', () {
    late AutoSaveScheduler scheduler;
    late List<String> savedKeys;
    bool disposed = false;

    setUp(() {
      savedKeys = [];
      disposed = false;
      scheduler = AutoSaveScheduler(
        onSave: (key, scribble) async {
          savedKeys.add(key);
        },
        isDisposed: () => disposed,
      );
    });

    tearDown(() {
      scheduler.dispose();
    });

    group('초기 상태', () {
      test('pendingKeys는 비어있음', () {
        expect(scheduler.pendingKeys, isEmpty);
      });

      test('hasPendingTimer는 false', () {
        expect(scheduler.hasPendingTimer('any_key'), false);
      });
    });

    group('schedule()', () {
      test('빈 스트로크는 타이머 등록하지 않음', () {
        fakeAsync((async) {
          final scribble = createScribble(); // 빈 scribble
          scheduler.schedule('key1', scribble);

          expect(scheduler.hasPendingTimer('key1'), false);
          async.elapse(const Duration(seconds: 2));
          expect(savedKeys, isEmpty);
        });
      });

      test('스트로크가 있으면 타이머 등록', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 1);
          scheduler.schedule('key1', scribble);

          expect(scheduler.hasPendingTimer('key1'), true);
        });
      });

      test('지연 시간 후 onSave 콜백 호출', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 1);
          scheduler.schedule('key1', scribble);

          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs - 1),
          );
          expect(savedKeys, isEmpty); // 아직 호출 안됨

          async.elapse(const Duration(milliseconds: 2));
          expect(savedKeys, ['key1']); // 호출됨
        });
      });

      test('연속 호출 시 마지막 호출만 저장 (디바운스)', () {
        fakeAsync((async) {
          final scribble1 = createScribbleWithStrokes(strokeCount: 1);
          final scribble2 = createScribbleWithStrokes(strokeCount: 2);
          final scribble3 = createScribbleWithStrokes(strokeCount: 3);

          scheduler.schedule('key1', scribble1);
          async.elapse(const Duration(milliseconds: 300));
          scheduler.schedule('key1', scribble2);
          async.elapse(const Duration(milliseconds: 300));
          scheduler.schedule('key1', scribble3);

          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          // 디바운스로 인해 한 번만 저장
          expect(savedKeys.length, 1);
          expect(savedKeys.first, 'key1');
        });
      });

      test('같은 스트로크 수는 중복 저장 안 함', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 2);
          scheduler.schedule('key1', scribble);
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys.length, 1);

          // 같은 스트로크 수로 다시 schedule
          savedKeys.clear();
          scheduler.schedule('key1', scribble);
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, isEmpty); // 중복 저장 방지
        });
      });

      test('다른 키는 독립적으로 스케줄링', () {
        fakeAsync((async) {
          final scribble1 = createScribbleWithStrokes(strokeCount: 1);
          final scribble2 = createScribbleWithStrokes(strokeCount: 2);

          scheduler.schedule('key1', scribble1);
          scheduler.schedule('key2', scribble2);

          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, containsAll(['key1', 'key2']));
        });
      });

      test('dispose 상태에서는 onSave 미호출', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 1);
          scheduler.schedule('key1', scribble);

          disposed = true; // dispose 상태로 변경
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, isEmpty); // 호출되지 않음
        });
      });

      test('키 정규화 — 특수문자 처리', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 1);
          scheduler.schedule('key|1', scribble);

          // 정규화된 키로 타이머 등록됨
          expect(scheduler.hasPendingTimer('key|1'), true);
        });
      });
    });

    group('cancelAll()', () {
      test('모든 타이머 취소', () {
        fakeAsync((async) {
          final s1 = createScribbleWithStrokes(strokeCount: 1);
          final s2 = createScribbleWithStrokes(strokeCount: 2);
          scheduler.schedule('key1', s1);
          scheduler.schedule('key2', s2);

          scheduler.cancelAll();
          expect(scheduler.pendingKeys, isEmpty);

          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, isEmpty); // 취소되어 저장 안됨
        });
      });
    });

    group('dispose()', () {
      test('dispose 후 pendingKeys 비어있음', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 1);
          scheduler.schedule('key1', scribble);

          scheduler.dispose();
          expect(scheduler.pendingKeys, isEmpty);
        });
      });
    });

    group('autoSaveDelayMs', () {
      test('기본값 1000ms', () {
        expect(AutoSaveScheduler.autoSaveDelayMs, 1000);
      });
    });
  });
}
