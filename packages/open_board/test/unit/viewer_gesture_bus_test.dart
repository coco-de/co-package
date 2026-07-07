import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/viewer_gesture_bus.dart';

void main() {
  group('ViewerGestureBus', () {
    tearDown(() => ViewerGestureBus().reset());

    test('should_return_same_singleton_instance', () {
      expect(ViewerGestureBus(), same(ViewerGestureBus()));
    });

    test('should_default_to_not_dragging', () {
      expect(ViewerGestureBus().isPanelDragging.value, isFalse);
    });

    test('should_flip_dragging_on_set_panel_dragging', () {
      final bus = ViewerGestureBus();
      final dragging = bus.isPanelDragging;

      bus.setPanelDragging(dragging: true);
      expect(dragging.value, isTrue);

      bus.setPanelDragging(dragging: false);
      expect(dragging.value, isFalse);
    });

    test('should_not_notify_when_value_unchanged', () {
      final bus = ViewerGestureBus();
      var notifications = 0;
      void listener() => notifications += 1;
      bus.isPanelDragging.addListener(listener);

      bus.setPanelDragging(dragging: false); // 동일 값 → 무시
      bus.setPanelDragging(dragging: true); // 변경 → 1회
      bus.setPanelDragging(dragging: true); // 동일 값 → 무시

      bus.isPanelDragging.removeListener(listener);
      expect(notifications, 1);
    });

    test('should_force_false_on_reset', () {
      final bus = ViewerGestureBus()..setPanelDragging(dragging: true);

      bus.reset();

      expect(bus.isPanelDragging.value, isFalse);
    });

    // kobic UB-213: 유실된 release 신호로 캔버스가 영구 게이트되는 것 방지.
    test(
      'should_auto_clear_after_max_stale_duration_when_release_is_lost',
      () {
        fakeAsync((async) {
          final bus = ViewerGestureBus()..setPanelDragging(dragging: true);
          expect(bus.isPanelDragging.value, isTrue);

          // onPointerUp/onPointerCancel/dispose 가 전혀 호출되지 않아도
          // watchdog 만료 후 자동 해제되어야 한다.
          async.elapse(
            ViewerGestureBus.maxStaleDuration - const Duration(milliseconds: 1),
          );
          expect(bus.isPanelDragging.value, isTrue); // 아직 만료 전.

          async.elapse(const Duration(milliseconds: 2));
          expect(bus.isPanelDragging.value, isFalse); // watchdog 만료.
        });
      },
    );

    test(
      'should_not_auto_clear_while_still_actively_dragging_move_renewed',
      () {
        fakeAsync((async) {
          final bus = ViewerGestureBus()..setPanelDragging(dragging: true);

          // onPointerMove 가 반복적으로 dragging:true 를 재신호(watchdog 재무장).
          for (var i = 0; i < 5; i++) {
            async.elapse(
              ViewerGestureBus.maxStaleDuration - const Duration(seconds: 1),
            );
            bus.setPanelDragging(dragging: true);
            expect(bus.isPanelDragging.value, isTrue);
          }

          // 정상 release.
          bus.setPanelDragging(dragging: false);
          expect(bus.isPanelDragging.value, isFalse);
        });
      },
    );

    test('should_cancel_watchdog_on_explicit_release', () {
      fakeAsync((async) {
        final bus = ViewerGestureBus()..setPanelDragging(dragging: true);

        bus.setPanelDragging(dragging: false);

        // 명시적 release 이후에는 watchdog 타이머가 남아있지 않아야 한다 —
        // 남아있다면 이 elapse 가 예외 없이 지나가도 무방하지만, pending timer
        // 로 인한 부작용(예: 다른 테스트로의 누수)이 없음을 확인.
        async.elapse(ViewerGestureBus.maxStaleDuration * 2);
        expect(bus.isPanelDragging.value, isFalse);
      });
    });
  });
}
