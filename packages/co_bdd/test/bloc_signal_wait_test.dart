// `pumpFramesUntilBlocState` 회귀 테스트 (#13704).
//
// 이 헬퍼가 틀리면 E2E 하네스의 모든 인증·버전 판정이 함께 틀린다. 특히 두
// 형태를 고정한다 — ① 조건 충족 뒤 **즉시** 돌아오는가(1초 폴링으로 되돌아가지
// 않았는가) ② 영영 충족되지 않을 때 **펌프한 시간** 기준으로 끝나는가(FakeAsync
// 에서 벽시계를 쓰면 무한 루프다).
import 'dart:async';

import 'package:bloc_signals/bloc_signals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_bdd/co_bdd.dart';

/// 정수 상태를 갖는 최소 컨테이너.
class _Counter extends CubitSignal<int> {
  _Counter() : super(initialState: 0);

  void set(int value) => emit(value);
}

void main() {
  late _Counter counter;

  setUp(() => counter = _Counter());
  tearDown(() async {
    await counter.close();
  });

  testWidgets('이미 만족하면 펌프 없이 즉시 돌아온다', (tester) async {
    var pumps = 0;
    Future<void> countingPump(Duration duration) async {
      pumps++;
      await tester.pump(duration);
    }

    counter.set(3);
    final result = await pumpFramesUntilBlocState(
      countingPump,
      counter,
      (state) => state == 3,
    );

    expect(result, 3);
    expect(pumps, 0);
  });

  testWidgets('상태가 바뀌는 즉시 돌아온다 — 바뀐 틱 이후 추가 펌프가 없다', (tester) async {
    var pumps = 0;
    Future<void> countingPump(Duration duration) async {
      pumps++;
      await tester.pump(duration);
    }

    // 250ms 뒤에 바뀐다 — 100ms 틱 기준 세 번째 펌프(200→300ms) 안에서 발화한다.
    Timer(const Duration(milliseconds: 250), () => counter.set(7));

    final result = await pumpFramesUntilBlocState(
      countingPump,
      counter,
      (state) => state == 7,
      timeout: const Duration(seconds: 5),
    );

    expect(result, 7);
    // 1초 폴링이었다면 10번 펌프했을 자리 — 신호가 답이라 3번에 끝난다.
    expect(pumps, 3);
  });

  testWidgets('영영 만족하지 않으면 펌프한 시간 기준으로 타임아웃하고 마지막 상태를 남긴다', (tester) async {
    var pumps = 0;
    Future<void> countingPump(Duration duration) async {
      pumps++;
      await tester.pump(duration);
    }

    await expectLater(
      () async {
        await pumpFramesUntilBlocState(
          countingPump,
          counter,
          (state) => state == 99,
          timeout: const Duration(milliseconds: 500),
          description: '99 대기',
        );
      },
      throwsA(
        isA<TimeoutException>().having(
          (error) => error.message,
          'message',
          allOf(contains('99 대기'), contains('int')),
        ),
      ),
    );
    // 500ms / 100ms = 5틱 — 벽시계가 아니라 펌프 누적으로 끝났다는 증거다.
    expect(pumps, 5);
  });

  testWidgets('돌아온 뒤에는 더 이상 관찰하지 않는다 (effect 해제)', (tester) async {
    var evaluations = 0;
    Timer(const Duration(milliseconds: 150), () => counter.set(1));

    await pumpFramesUntilBlocState(tester.pump, counter, (state) {
      evaluations++;

      return state == 1;
    });

    final evaluationsAtReturn = evaluations;
    counter.set(2);
    await tester.pump(const Duration(milliseconds: 100));

    expect(evaluations, evaluationsAtReturn);
  });

  testWidgets('WidgetTester 확장으로도 같은 동작을 한다', (tester) async {
    Timer(const Duration(milliseconds: 120), () => counter.set(5));

    final result = await tester.pumpUntilBlocState(
      counter,
      (state) => state >= 5,
      timeout: const Duration(seconds: 2),
    );

    expect(result, 5);
  });

  group('waitForBlocState — 단위 테스트용 (펌프 없음)', () {
    test('이미 만족하면 즉시 돌아온다', () async {
      counter.set(3);

      final result = await waitForBlocState(counter, (state) => state == 3);

      expect(result, 3);
    });

    test('마이크로태스크 비동기 사슬이 내는 전이를 실제 대기 없이 잡는다', () async {
      final sw = Stopwatch()..start();

      // `flutter_bloc` 스트림 전이를 흉내낸 마이크로태스크 사슬 — mock UseCase
      // (`() async => ...`) 의 실제 완료 경로와 같은 모양이다.
      unawaited(() async {
        await Future<void>.microtask(() {});
        counter.set(1);
        await Future<void>.microtask(() {});
        counter.set(2);
        await Future<void>.microtask(() {});
        counter.set(3);
      }());

      final result = await waitForBlocState(counter, (state) => state == 3);

      sw.stop();
      expect(result, 3);
      // 고정 대기(50ms)로 되돌아가지 않았는가 — 사슬 완료는 마이크로태스크
      // 수준이라 벽시계로 수 ms 안쪽이어야 한다.
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('조건이 영영 충족되지 않으면 마지막 상태 타입을 담아 타임아웃한다', () async {
      await expectLater(
        () => waitForBlocState(
          counter,
          (state) => state == 99,
          timeout: const Duration(milliseconds: 100),
          description: '99 대기',
        ),
        throwsA(
          isA<TimeoutException>()
              .having((e) => e.message, 'message', contains('99 대기'))
              .having((e) => e.message, 'message', contains('int')),
        ),
      );
    });

    test('돌아온 뒤에는 더 이상 관찰하지 않는다 (effect 해제)', () async {
      var evaluations = 0;
      unawaited(() async {
        await Future<void>.microtask(() {});
        counter.set(1);
      }());

      await waitForBlocState(counter, (state) {
        evaluations++;

        return state == 1;
      });

      final evaluationsAtReturn = evaluations;
      counter.set(2);
      await Future<void>.delayed(Duration.zero);

      expect(evaluations, evaluationsAtReturn);
    });
  });
}
