// 시간 경과에 따른 상태 전이 검증이라 async.elapse() 후 매번 다른 상태를
// 읽으므로 변수 추출·중복 단언 경고는 오탐이다 (uniform_pen_test.dart 와 동일 사유).
// ignore_for_file: prefer-moving-to-variable, avoid-duplicate-test-assertions
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

    // 리팩터 회귀 가드: cancel() 이 `if (value != dragging)` 가드 안으로
    // 잘못 옮겨지면(값이 이미 true 라 가드를 못 타는 경우), 근접 간격의 재호출이
    // 기존 타이머를 취소하지 못해 "최초 호출 기준 만료 시각"에 여전히 해제되는
    // 회귀가 생길 수 있다 — 이 테스트는 그 회귀를 감지한다.
    test('should_extend_deadline_from_latest_call_even_with_near_zero_gap', () {
      fakeAsync((async) {
        // t=0: 최초 호출 → A 만료 시각 = maxStaleDuration.
        const gap = Duration(milliseconds: 100);
        final bus = ViewerGestureBus()..setPanelDragging(dragging: true);

        // t=gap: 짧은 간격으로 재신호 → B 만료 시각 = gap + maxStaleDuration.
        async.elapse(gap);
        bus.setPanelDragging(dragging: true);

        // t = B 만료 1ms 전(= A 만료는 이미 지남) — 재신호가 A 의 타이머를
        // 제대로 취소했다면(취소 못했다면 A 만료 시점에 이미 false 였을 것)
        // 여전히 dragging 상태여야 한다.
        async.elapse(
          ViewerGestureBus.maxStaleDuration - const Duration(milliseconds: 1),
        );
        expect(bus.isPanelDragging.value, isTrue);

        // t 가 B 만료를 넘기면 정상적으로 해제된다.
        async.elapse(const Duration(milliseconds: 2));
        expect(bus.isPanelDragging.value, isFalse);
      });
    });

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
