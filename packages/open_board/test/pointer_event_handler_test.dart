import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/widgets/pointer_event_handler.dart';

void main() {
  late PointerEventHandler handler;
  late ScribbleNotifier scribbleNotifier;
  late ScribbleModeNotifier modeNotifier;

  setUp(() {
    scribbleNotifier = ScribbleNotifier();
    modeNotifier = ScribbleModeNotifier();
    handler = PointerEventHandler(
      scribbleNotifier: scribbleNotifier,
      modeNotifier: modeNotifier,
      onStateChanged: () {},
      onScribble: (_) {},
      onScribbleFinished: (_) {},
    );
  });

  tearDown(() {
    handler.dispose();
    scribbleNotifier.dispose();
    modeNotifier.dispose();
  });

  group('터치 카운트 관리', () {
    test('초기 상태에서 멀티터치가 아님', () {
      expect(handler.isMultiTouch(), isFalse);
    });

    test('incrementTouch 한 번 호출 시 멀티터치가 아님', () {
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('incrementTouch 두 번 호출 시 멀티터치 감지', () {
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);
    });

    test('incrementTouch 세 번 호출 시에도 멀티터치', () {
      handler.incrementTouch();
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);
    });

    test('decrementTouch로 터치 카운트 감소', () {
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('decrementTouch가 0 이하로 내려가지 않음', () {
      handler.decrementTouch();
      handler.decrementTouch();

      // 0 이하로 내려갔어도 이후 incrementTouch 1번으로 멀티터치 아님
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });

    test('dispose 후 터치 카운트 초기화', () {
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      handler.dispose();
      expect(handler.isMultiTouch(), isFalse);
    });
  });

  group('하이라이트 모드 핀치 줌 시나리오', () {
    test('pointerCancel 시에도 터치 카운트 정상 감소', () {
      // 핀치 줌 중 시스템 cancel 이벤트 발생 시나리오
      handler.incrementTouch();
      handler.incrementTouch();
      expect(handler.isMultiTouch(), isTrue);

      // cancel로 터치 감소
      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);

      handler.decrementTouch();
      expect(handler.isMultiTouch(), isFalse);
    });
  });

  group('팜 리젝션 (kobic UB-219)', () {
    test('팜으로 마킹된 포인터는 isPalmIgnored가 true', () {
      handler.markPalmIgnored(1);

      expect(handler.isPalmIgnored(1), isTrue);
      expect(handler.isPalmIgnored(2), isFalse);
    });

    test('손모드 필기 중 도착한 팜 접촉은 isEffectiveMultiTouch에서 제외된다', () {
      // 첫 손가락(필기 중) down
      handler.incrementTouch();
      // 팜/보조손가락 down — 손모드 필기 중이므로 팜으로 마킹
      handler.incrementTouch();
      handler.markPalmIgnored(2);

      // 하드웨어 터치 총합은 2(멀티터치)지만, 팜을 뺀 유효 터치는 1이므로
      // 진행 중인 스트로크의 move/스크롤 차단 판정에는 영향을 주지 않는다.
      expect(handler.isMultiTouch(), isTrue);
      expect(handler.isEffectiveMultiTouch, isFalse);
    });

    test('필기 시작 전 진짜 두 손가락 동시 접촉은 회귀 없이 멀티터치로 인정된다', () {
      // 팜으로 마킹되지 않은 두 손가락 — 기존 핀치줌/팬 동작 그대로 유지.
      handler.incrementTouch();
      handler.incrementTouch();

      expect(handler.isMultiTouch(), isTrue);
      expect(handler.isEffectiveMultiTouch, isTrue);
    });

    test('팜 마킹된 포인터 위에 실제 두 번째 손가락이 더해지면 유효 멀티터치', () {
      // 필기 중(1) + 팜(2, 무시) + 진짜 두 번째 손가락(3)
      handler
        ..incrementTouch()
        ..incrementTouch();
      handler.markPalmIgnored(2);
      handler.incrementTouch();

      expect(handler.isEffectiveMultiTouch, isTrue);
    });

    test('clearPalmIgnored 후 다시 유효 터치로 카운트된다', () {
      handler
        ..incrementTouch()
        ..incrementTouch();
      handler.markPalmIgnored(2);
      expect(handler.isEffectiveMultiTouch, isFalse);

      handler.clearPalmIgnored(2);
      expect(handler.isEffectiveMultiTouch, isTrue);
    });

    test('resetTouch 호출 시 팜 마킹도 함께 초기화된다', () {
      handler
        ..incrementTouch()
        ..incrementTouch();
      handler.markPalmIgnored(2);

      handler.resetTouch();

      expect(handler.isMultiTouch(), isFalse);
      expect(handler.isPalmIgnored(2), isFalse);
    });

    test('dispose 호출 시 팜 마킹도 함께 초기화된다', () {
      handler
        ..incrementTouch()
        ..incrementTouch();
      handler.markPalmIgnored(2);

      handler.dispose();

      expect(handler.isPalmIgnored(2), isFalse);
      expect(handler.isEffectiveMultiTouch, isFalse);
    });
  });

  group('지연 시작 (kobic UB-188)', () {
    PointerDownEvent downEvent({
      int pointer = 1,
      Offset position = Offset.zero,
    }) =>
        PointerDownEvent(pointer: pointer, position: position);

    PointerMoveEvent moveEvent({int pointer = 1, required Offset position}) =>
        PointerMoveEvent(pointer: pointer, position: position);

    test('beginDeferredStroke 직후에는 보류 상태만 생기고 notifier 는 그대로다', () {
      expect(handler.hasPendingDeferredStroke, isFalse);

      handler.beginDeferredStroke(downEvent(), onTimeout: () {});

      expect(handler.hasPendingDeferredStroke, isTrue);
      expect(handler.pendingDeferredPointerId, 1);
      // activeLine 이 생성되지 않아 Drawing 상태로도 전이하지 않는다.
      expect(scribbleNotifier.currentState.activePointerIds, isEmpty);
    });

    test('slop 이내 이동은 승격되지 않고 버퍼링만 된다', () {
      handler.beginDeferredStroke(downEvent(), onTimeout: () {});

      final shouldPromote = handler.bufferOrShouldPromoteDeferredMove(
        moveEvent(position: const Offset(5, 0)), // slop(15) 이내
      );

      expect(shouldPromote, isFalse);
      expect(handler.hasPendingDeferredStroke, isTrue);
    });

    test('slop 초과 이동은 승격 신호를 반환한다', () {
      handler.beginDeferredStroke(downEvent(), onTimeout: () {});

      final shouldPromote = handler.bufferOrShouldPromoteDeferredMove(
        moveEvent(position: const Offset(20, 0)), // slop(15) 초과
      );

      expect(shouldPromote, isTrue);
      // 승격 여부 판정 자체는 내부 상태를 지우지 않는다 — 실제 승격은
      // 호출자가 takePendingDeferredStroke 로 명시적으로 수행해야 한다.
      expect(handler.hasPendingDeferredStroke, isTrue);
    });

    test('다른 포인터의 move 는 보류에 영향을 주지 않는다', () {
      handler.beginDeferredStroke(downEvent(pointer: 1), onTimeout: () {});

      final shouldPromote = handler.bufferOrShouldPromoteDeferredMove(
        moveEvent(pointer: 2, position: const Offset(100, 100)),
      );

      expect(shouldPromote, isFalse);
      expect(handler.hasPendingDeferredStroke, isTrue);
      expect(handler.pendingDeferredPointerId, 1);
    });

    test('보류가 없는 상태에서 move 는 항상 false 를 반환한다', () {
      final shouldPromote = handler.bufferOrShouldPromoteDeferredMove(
        moveEvent(position: const Offset(100, 100)),
      );

      expect(shouldPromote, isFalse);
    });

    test('takePendingDeferredStroke 는 버퍼링된 move 를 순서대로 담아 반환한다', () {
      final down = downEvent();
      handler.beginDeferredStroke(down, onTimeout: () {});

      final move1 = moveEvent(position: const Offset(3, 0));
      final move2 = moveEvent(position: const Offset(6, 0));
      handler.bufferOrShouldPromoteDeferredMove(move1);
      handler.bufferOrShouldPromoteDeferredMove(move2);

      final pending = handler.takePendingDeferredStroke(1);

      expect(pending, isNotNull);
      expect(pending!.downEvent, same(down));
      expect(pending.bufferedMoves, [move1, move2]);
    });

    test('takePendingDeferredStroke 는 호출 후 내부 상태를 비운다', () {
      handler.beginDeferredStroke(downEvent(), onTimeout: () {});

      final first = handler.takePendingDeferredStroke(1);
      final second = handler.takePendingDeferredStroke(1);

      expect(first, isNotNull);
      expect(second, isNull);
      expect(handler.hasPendingDeferredStroke, isFalse);
    });

    test('다른 pointerId 로 takePendingDeferredStroke 하면 null 이고 보류는 유지된다', () {
      handler.beginDeferredStroke(downEvent(pointer: 1), onTimeout: () {});

      final result = handler.takePendingDeferredStroke(2);

      expect(result, isNull);
      expect(handler.hasPendingDeferredStroke, isTrue);
    });

    test('보류가 없을 때 takePendingDeferredStroke 는 null 을 반환한다', () {
      expect(handler.takePendingDeferredStroke(1), isNull);
    });

    test(
      'kDeferStartTimeout 이 지나도 승격/폐기되지 않으면 onTimeout 이 호출된다',
      () async {
        var timedOut = false;
        handler.beginDeferredStroke(
          downEvent(),
          onTimeout: () {
            timedOut = true;
          },
        );

        await Future<void>.delayed(
          PointerEventHandler.kDeferStartTimeout +
              const Duration(milliseconds: 50),
        );

        expect(timedOut, isTrue);
      },
    );

    test('takePendingDeferredStroke 로 먼저 처리되면 onTimeout 은 호출되지 않는다', () async {
      var timedOut = false;
      handler.beginDeferredStroke(
        downEvent(),
        onTimeout: () {
          timedOut = true;
        },
      );

      handler.takePendingDeferredStroke(1); // promote/discard 대신 즉시 소비

      await Future<void>.delayed(
        PointerEventHandler.kDeferStartTimeout +
            const Duration(milliseconds: 50),
      );

      expect(timedOut, isFalse);
    });

    test('dispose 이후에는 예약된 onTimeout 이 호출되지 않는다', () async {
      var timedOut = false;
      handler.beginDeferredStroke(
        downEvent(),
        onTimeout: () {
          timedOut = true;
        },
      );

      handler.dispose();
      expect(handler.hasPendingDeferredStroke, isFalse);

      await Future<void>.delayed(
        PointerEventHandler.kDeferStartTimeout +
            const Duration(milliseconds: 50),
      );

      expect(timedOut, isFalse);
    });

    test('resetTouch 호출 시 보류 중이던 스트로크도 폐기된다', () {
      handler.beginDeferredStroke(downEvent(), onTimeout: () {});

      handler.resetTouch();

      expect(handler.hasPendingDeferredStroke, isFalse);
    });

    test('새 보류가 시작되면 이전(미해결) 보류의 onTimeout 은 발화하지 않는다', () async {
      var firstTimedOut = false;
      var secondTimedOut = false;

      handler.beginDeferredStroke(
        downEvent(pointer: 1),
        onTimeout: () => firstTimedOut = true,
      );
      // 첫 보류가 아직 남아있는 채로 새 보류가 시작되면(멀티터치 등) 이전
      // 타이머가 명시적으로 취소된다.
      handler.beginDeferredStroke(
        downEvent(pointer: 2),
        onTimeout: () => secondTimedOut = true,
      );

      await Future<void>.delayed(
        PointerEventHandler.kDeferStartTimeout +
            const Duration(milliseconds: 50),
      );

      expect(firstTimedOut, isFalse);
      expect(secondTimedOut, isTrue);
      // onTimeout 은 알림일 뿐 스스로 상태를 비우지 않는다 — 실제 승격/폐기는
      // 호출자가 takePendingDeferredStroke 로 수행해야 하므로, 두 번째
      // 보류는 여전히 pointer 2 로 남아 있다.
      expect(handler.pendingDeferredPointerId, 2);
    });
  });
}
