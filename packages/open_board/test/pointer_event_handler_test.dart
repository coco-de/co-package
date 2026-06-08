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
}
