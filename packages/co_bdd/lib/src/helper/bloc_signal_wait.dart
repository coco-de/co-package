import 'dart:async';

import 'package:bloc_signals/bloc_signals.dart' show BlocSignalBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_core/signals_core.dart' show effect;

/// 한 프레임을 펌프하는 함수 — `WidgetTester.pump` / `PatrolIntegrationTester.pump`
/// 의 tear-off 가 그대로 들어온다.
typedef PumpFrame = Future<void> Function(Duration duration);

/// BLoC 의 **상태 신호**가 [predicate] 를 만족할 때까지 기다린다 — 펌프가 필요 없다
/// (coco-de/unibook#13704 Phase D — 단위 테스트 적용).
///
/// `blocSignalTest`/순수 `test()` 안에서 `await Future<void>.delayed(50ms)` 로
/// "비동기 핸들러가 끝나길" 기다리던 자리를 대체한다. 실제 시간으로 재는 고정
/// 대기는 ① 조건이 이미 충족됐어도 그 시간을 그대로 지불하고 ② mock UseCase 가
/// 마이크로태스크로 끝나면 낭비이며 ③ 조건이 늦게 충족되면 조용히 실패한다.
/// 이 함수는 상태 신호를 [effect] 로 구독해 **바뀌는 그 순간** 조건을 재평가하고,
/// 만족하면 즉시 돌아온다 — 고정 대기 대비 수십~수백 ms 를 테스트당 회수한다.
///
/// ```dart
/// blocSignalTest<ChatBloc, ChatState>(
///   'should_emit_loaded_when_loadBook_succeeds',
///   build: () => ChatBloc(useCases: fakeUseCases),
///   act: (bloc) async {
///     bloc.add(const ChatEvent.loadBook(bookId: '1'));
///     await waitForBlocState(bloc, (s) => !s.isLoadingBook && s.book != null);
///   },
///   // wait: const Duration(milliseconds: 50),  ← 제거
///   expect: () => [isA<ChatState>().having(...), ...],
/// );
/// ```
///
/// ⚠️ **`WidgetTester` 안에서는 쓰지 않는다** — 타임아웃이 실제 `Timer` 라
/// FakeAsync 에서는 타임아웃이 발화하지 않는다(조건 충족 시에는 정상 동작).
/// 위젯 테스트는 [pumpFramesUntilBlocState]/`pumpUntilBlocState` 를 쓴다.
///
/// ⚠️ **실제 `Timer`(debounce·쿨다운·재연결 백오프)가 개입한 전이는 이 함수로
/// 기다릴 수 없다** — 신호는 변하지만 타이머는 아직 돌지 않았다. 그런 축은
/// `fake_async` 로 시간을 전진시키거나, 그대로 실제 대기를 유지한다.
Future<S> waitForBlocState<S>(
  BlocSignalBase<S> bloc,
  bool Function(S state) predicate, {
  Duration timeout = const Duration(seconds: 5),
  String? description,
}) async {
  final current = bloc.stateValue;
  if (predicate(current)) return current;

  final completer = Completer<S>();
  void completeIf(S state) {
    if (!completer.isCompleted && predicate(state)) completer.complete(state);
  }

  // `state.value` 읽기가 의존을 등록한다 — 이 신호가 바뀔 때만 다시 실행된다.
  final stopWatching = effect(() => completeIf(bloc.state.value));

  try {
    return await completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        '${description ?? 'BLoC 상태 대기'} — ${timeout.inMilliseconds}ms 안에 '
        '조건을 만족하지 못했다 (마지막 상태: ${bloc.stateValue.runtimeType})',
        timeout,
      ),
    );
  } finally {
    stopWatching();
  }
}

/// BLoC 의 **상태 신호**가 [predicate] 를 만족할 때까지 프레임을 펌프하며
/// 기다린다 (coco-de/unibook#13704).
///
/// bloc_signals 로 전환된 컨테이너는 `ReadonlySignal<State> state` 를 노출한다.
/// 이 함수는 그 신호를 [effect] 로 구독해 **상태가 바뀌는 그 순간** 조건을 다시
/// 평가하고, 만족하면 다음 틱에서 곧바로 돌아온다. 종전의 `for … pump(1초)` 폴링은
/// ① 조건 충족 뒤 최대 1초를 더 지불하고 ② 폴링 사이의 순간 상태(`Loading` 등)를
/// 놓치며 ③ 위젯 텍스트로 상태를 추정해야 했다.
///
/// ## 왜 effect 와 틱 검사를 둘 다 하는가
///
/// 신호가 정답이고 틱은 안전망이다. effect 콜백은 emit 과 **동기**로 실행되지만,
/// 같은 신호에 걸린 다른 effect 와의 실행 순서는 보장되지 않는다 — [predicate] 가
/// 바깥 변수(예: "Loading 을 봤다" 플래그)를 읽는 경우 그 변수가 아직 갱신되기
/// 전일 수 있다. 그래서 틱마다 한 번 더 평가한다(비용은 [interval] 당 함수 호출 1회).
///
/// ## 타임아웃은 펌프한 시간으로 잰다
///
/// 벽시계(`Stopwatch`)가 아니라 [interval] 의 누적으로 센다. 위젯 테스트의
/// FakeAsync 에서는 `pump(100ms)` 가 벽시계로 거의 0초에 끝나므로 벽시계 기준이면
/// **영원히 돈다.** Patrol(LiveTestWidgetsFlutterBinding)에서는 `pump(interval)` 이
/// 실제로 그만큼 기다리므로 누적값이 실시간과 같다.
///
/// 타임아웃 시 [TimeoutException] 을 던지며 메시지에 **마지막 상태의 타입**을
/// 담는다 — "무엇을 기다렸는데 어디서 멈춰 있었나" 가 실패 메시지에 있어야 한다.
///
/// ```dart
/// // Patrol
/// final state = await pumpFramesUntilBlocState(
///   $.pump, authBloc, (s) => s is Authenticated,
///   timeout: const Duration(seconds: 60), description: '로그인 결과',
/// );
///
/// // 위젯 테스트 (확장)
/// await tester.pumpUntilBlocState(cubit, (s) => s.isLoaded);
/// ```
Future<S> pumpFramesUntilBlocState<S>(
  PumpFrame pump,
  BlocSignalBase<S> bloc,
  bool Function(S state) predicate, {
  Duration timeout = const Duration(seconds: 15),
  Duration interval = const Duration(milliseconds: 100),
  String? description,
}) async {
  if (predicate(bloc.stateValue)) return bloc.stateValue;

  final completer = Completer<S>();
  void completeIf(S state) {
    if (!completer.isCompleted && predicate(state)) completer.complete(state);
  }

  // `state.value` 읽기가 의존을 등록한다 — 이 신호가 바뀔 때만 다시 실행된다.
  final stopWatching = effect(() => completeIf(bloc.state.value));

  try {
    var elapsed = Duration.zero;
    while (!completer.isCompleted) {
      if (elapsed >= timeout) {
        throw TimeoutException(
          '${description ?? 'BLoC 상태 대기'} — ${timeout.inSeconds}초 안에 '
          '조건을 만족하지 못했다 (마지막 상태: ${bloc.stateValue.runtimeType})',
          timeout,
        );
      }
      await pump(interval);
      elapsed += interval;
      completeIf(bloc.stateValue);
    }

    return await completer.future;
  } finally {
    stopWatching();
  }
}

/// 위젯 테스트용 편의 확장 — [pumpFramesUntilBlocState] 에 `tester.pump` 를 넘긴다.
extension BlocSignalWaitTester on WidgetTester {
  /// [bloc] 의 상태가 [predicate] 를 만족할 때까지 펌프하며 기다린다.
  Future<S> pumpUntilBlocState<S>(
    BlocSignalBase<S> bloc,
    bool Function(S state) predicate, {
    Duration timeout = const Duration(seconds: 15),
    Duration interval = const Duration(milliseconds: 100),
    String? description,
  }) => pumpFramesUntilBlocState(
    pump,
    bloc,
    predicate,
    timeout: timeout,
    interval: interval,
    description: description,
  );
}
