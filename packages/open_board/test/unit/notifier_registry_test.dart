import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/notifier_registry.dart';

void main() {
  late NotifierRegistry registry;
  late ValueNotifier<ScribbleNotifier?> activeNotifierNotifier;

  setUp(() {
    registry = NotifierRegistry();
    activeNotifierNotifier = ValueNotifier<ScribbleNotifier?>(null);
    registry.initialize(activeNotifierNotifier);
  });

  tearDown(() {
    activeNotifierNotifier.dispose();
  });

  group('NotifierRegistry', () {
    group('ModeNotifier 등록/해제', () {
      test('registerModeNotifier로 등록하면 카운트가 증가한다', () {
        final modeNotifier = ScribbleModeNotifier();

        registry.registerModeNotifier(modeNotifier);

        expect(registry.activeModeNotifierCount, 1);
        expect(registry.activeModeNotifiers.contains(modeNotifier), isTrue);
      });

      test('unregisterModeNotifier로 해제하면 카운트가 감소한다', () {
        final modeNotifier = ScribbleModeNotifier();
        registry.registerModeNotifier(modeNotifier);

        registry.unregisterModeNotifier(modeNotifier);

        expect(registry.activeModeNotifierCount, 0);
      });

      test('같은 notifier를 중복 등록해도 1개만 유지된다 (Set)', () {
        final modeNotifier = ScribbleModeNotifier();

        registry.registerModeNotifier(modeNotifier);
        registry.registerModeNotifier(modeNotifier);

        expect(registry.activeModeNotifierCount, 1);
      });

      test('여러 notifier를 등록할 수 있다', () {
        final notifier1 = ScribbleModeNotifier();
        final notifier2 = ScribbleModeNotifier();

        registry.registerModeNotifier(notifier1);
        registry.registerModeNotifier(notifier2);

        expect(registry.activeModeNotifierCount, 2);
      });
    });

    group('ScribbleNotifier 등록/해제', () {
      test('registerScribbleNotifier로 등록하면 카운트가 증가한다', () {
        final scribbleNotifier = ScribbleNotifier();

        registry.registerScribbleNotifier(scribbleNotifier);

        expect(registry.activeScribbleNotifierCount, 1);
      });

      test('unregisterScribbleNotifier로 해제하면 카운트가 감소한다', () {
        final scribbleNotifier = ScribbleNotifier();
        registry.registerScribbleNotifier(scribbleNotifier);

        registry.unregisterScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        expect(registry.activeScribbleNotifierCount, 0);
      });
    });

    group('lastActiveScribbleNotifier 추적', () {
      test('초기값은 null이다', () {
        expect(registry.lastActiveScribbleNotifier, isNull);
      });

      test('setLastActiveScribbleNotifier로 설정하면 값이 변경된다', () {
        final scribbleNotifier = ScribbleNotifier();

        registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        expect(registry.lastActiveScribbleNotifier, scribbleNotifier);
      });

      test('setLastActiveScribbleNotifier는 ValueNotifier도 업데이트한다', () {
        final scribbleNotifier = ScribbleNotifier();

        registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        expect(activeNotifierNotifier.value, scribbleNotifier);
      });

      test('같은 notifier를 다시 설정하면 변경되지 않은 것으로 간주한다', () {
        final scribbleNotifier = ScribbleNotifier();

        final firstResult = registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );
        final secondResult = registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        expect(firstResult, isTrue); // 변경됨
        expect(secondResult, isFalse); // 이미 동일
      });

      test('isDisposed가 true이면 설정을 무시한다', () {
        final scribbleNotifier = ScribbleNotifier();

        final result = registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: true,
        );

        expect(result, isFalse);
        expect(registry.lastActiveScribbleNotifier, isNull);
      });

      test('활성 notifier 해제 시 lastActive가 null로 설정된다', () {
        final scribbleNotifier = ScribbleNotifier();
        registry.registerScribbleNotifier(scribbleNotifier);
        registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        var callbackCalled = false;
        registry.unregisterScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
          onLastActiveCleared: () => callbackCalled = true,
        );

        expect(registry.lastActiveScribbleNotifier, isNull);
        expect(activeNotifierNotifier.value, isNull);
        expect(callbackCalled, isTrue);
      });

      test('활성이 아닌 notifier 해제 시 lastActive는 유지된다', () {
        final notifier1 = ScribbleNotifier();
        final notifier2 = ScribbleNotifier();
        registry.registerScribbleNotifier(notifier1);
        registry.registerScribbleNotifier(notifier2);
        registry.setLastActiveScribbleNotifier(
          notifier1,
          isDisposed: false,
        );

        registry.unregisterScribbleNotifier(
          notifier2,
          isDisposed: false,
        );

        expect(registry.lastActiveScribbleNotifier, notifier1);
      });
    });

    group('findScribbleNotifierForModeNotifier', () {
      test('lastActive가 있으면 해당 notifier를 반환한다', () {
        final scribbleNotifier = ScribbleNotifier();
        final modeNotifier = ScribbleModeNotifier();
        registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        final result = registry.findScribbleNotifierForModeNotifier(
          modeNotifier,
        );

        expect(result, scribbleNotifier);
      });

      test('lastActive가 없고 등록된 notifier가 있으면 첫 번째를 반환한다', () {
        final scribbleNotifier = ScribbleNotifier();
        final modeNotifier = ScribbleModeNotifier();
        registry.registerScribbleNotifier(scribbleNotifier);

        final result = registry.findScribbleNotifierForModeNotifier(
          modeNotifier,
        );

        expect(result, scribbleNotifier);
      });

      test('등록된 notifier가 없으면 null을 반환한다', () {
        final modeNotifier = ScribbleModeNotifier();

        final result = registry.findScribbleNotifierForModeNotifier(
          modeNotifier,
        );

        expect(result, isNull);
      });
    });

    group('clear', () {
      test('clear 후 모든 상태가 초기화된다', () {
        final modeNotifier = ScribbleModeNotifier();
        final scribbleNotifier = ScribbleNotifier();
        registry.registerModeNotifier(modeNotifier);
        registry.registerScribbleNotifier(scribbleNotifier);
        registry.setLastActiveScribbleNotifier(
          scribbleNotifier,
          isDisposed: false,
        );

        registry.clear();

        expect(registry.activeModeNotifierCount, 0);
        expect(registry.activeScribbleNotifierCount, 0);
        expect(registry.lastActiveScribbleNotifier, isNull);
      });
    });
  });
}
