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
  });
}
