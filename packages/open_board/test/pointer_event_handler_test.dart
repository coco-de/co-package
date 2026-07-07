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
}
