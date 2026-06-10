import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
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

    group('schedule()', () {
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
    });

    group('autoSaveDelayMs', () {
      test('기본값 1000ms', () {
        expect(AutoSaveScheduler.autoSaveDelayMs, 1000);
      });
    });

    group('내용 기반 변경 감지 (#동수 변경 저장 누락 회귀)', () {
      test('스트로크 수가 같아도 내용이 다르면 저장된다 (올가미 이동/색 변경)', () {
        fakeAsync((async) {
          final before = createScribble(
            strokes: [
              createStroke(points: [createPoint(x: 10, y: 10)]),
            ],
          );
          // 같은 개수, 좌표만 이동
          final after = createScribble(
            strokes: [
              createStroke(points: [createPoint(x: 99, y: 99)]),
            ],
          );

          scheduler.schedule('key1', before);
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys.length, 1);

          scheduler.schedule('key1', after);
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(
            savedKeys.length,
            2,
            reason: '개수만 비교하면 올가미 이동·색 변경·동수 추가삭제가 저장에서 누락된다',
          );
        });
      });

      test('빈 Scribble(전체 지우기)도 저장된다 — 지운 필기 부활 방지', () {
        fakeAsync((async) {
          scheduler.schedule('key1', createScribbleWithStrokes(strokeCount: 2));
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys.length, 1);

          scheduler.schedule('key1', createScribble(strokes: []));
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(
            savedKeys.length,
            2,
            reason: '전체 지우기를 영속화하지 않으면 재실행 시 지운 필기가 부활한다',
          );
        });
      });

      test('텍스트 객체만 변경되어도 저장된다 (strokes 비어 있어도)', () {
        fakeAsync((async) {
          final withText = createScribble(
            strokes: [],
            textDrawables: [createTextDrawable(id: 't1', x: 10)],
          );

          scheduler.schedule('key1', withText);
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys.length, 1, reason: '텍스트 전용 페이지도 저장 대상');
        });
      });

      test('재schedule 시 stale 스냅샷이 아닌 최신 상태가 저장된다', () {
        fakeAsync((async) {
          final savedScribbles = <int>[];
          final s = AutoSaveScheduler(
            onSave: (key, scribble) async {
              savedScribbles.add(scribble.strokes.length);
            },
            isDisposed: () => false,
          );

          // 5개 저장 완료 → 4개로 변경(타이머 대기) → 5개로 재변경
          s.schedule('k', createScribbleWithStrokes(strokeCount: 5));
          async.elapse(const Duration(milliseconds: 1100));
          s.schedule('k', createScribbleWithStrokeCountAndOffset(4, 0));
          async.elapse(const Duration(milliseconds: 300));
          s.schedule('k', createScribbleWithStrokeCountAndOffset(5, 50));
          async.elapse(const Duration(milliseconds: 1100));

          expect(
            savedScribbles.last,
            5,
            reason: '대기 중이던 4-stroke stale 스냅샷이 최신 상태를 덮어쓰면 안 된다',
          );
          s.dispose();
        });
      });
    });

    group('flush() — pending 스냅샷 반환', () {
      test('대기 중인 최신 스냅샷을 반환하고 타이머를 취소한다', () {
        fakeAsync((async) {
          final scribble = createScribbleWithStrokes(strokeCount: 3);
          scheduler.schedule('key1', scribble);

          final pending = scheduler.flush('key1');

          expect(pending, isNotNull);
          expect(pending!.strokes.length, 3);

          // 타이머는 취소되어 onSave가 호출되지 않는다
          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, isEmpty);
        });
      });

      test('대기 중인 스냅샷이 없으면 null을 반환한다', () {
        expect(scheduler.flush('key1'), isNull);
      });
    });

    group('invalidate() — 삭제된 필기 부활 방지', () {
      test('대기 중인 타이머와 비교 기준을 모두 제거한다', () {
        fakeAsync((async) {
          scheduler.schedule('key1', createScribbleWithStrokes(strokeCount: 2));
          scheduler.invalidate('key1');

          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, isEmpty, reason: '삭제 후 타이머가 발화하면 파일이 부활한다');
        });
      });

      test('invalidateByPrefix는 프리픽스 하위 키만 제거한다', () {
        fakeAsync((async) {
          scheduler.schedule(
            'book1/page1',
            createScribbleWithStrokes(strokeCount: 1),
          );
          scheduler.schedule(
            'book2/page1',
            createScribbleWithStrokes(strokeCount: 2),
          );

          scheduler.invalidateByPrefix('book1');

          async.elapse(
            Duration(milliseconds: AutoSaveScheduler.autoSaveDelayMs + 100),
          );
          expect(savedKeys, ['book2/page1']);
        });
      });
    });
  });
}

/// 좌표 오프셋이 다른 N-스트로크 Scribble (내용 구분용)
Scribble createScribbleWithStrokeCountAndOffset(int count, double offset) {
  return createScribble(
    strokes: [
      for (var i = 0; i < count; i++)
        createStroke(
          points: [createPoint(x: offset + i * 10, y: offset + i * 10)],
        ),
    ],
  );
}
