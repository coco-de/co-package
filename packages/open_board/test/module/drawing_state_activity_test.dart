// DrawingState.drawingActivityNotifier — 획 시작(setLastActiveScribbleNotifier)
// 마다 증가하는 필기 활동 틱 검증 (kobic #7491).
//
// canUndo/canRedo(ValueNotifier<bool>)는 값이 바뀔 때만 알림하므로, 이미 이력이
// 있는 레이어의 연속 획을 활동으로 감지하지 못한다. 활동 틱은 활성 레이어 변경
// 여부·boolean 값과 무관하게 매 pointer-down 을 활동으로 신호한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // UndoRedoTracker 가 WidgetsBinding.addPostFrameCallback 을 사용하므로
  // (dispose/updateUndoRedoState 경로) 바인딩 초기화가 필요하다.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingState.drawingActivityNotifier (#7491)', () {
    late ScribbleController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = ScribbleController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('setLastActiveScribbleNotifier 는 활동 틱을 증가시킨다', () {
      final drawingState = DrawingState();
      final before = drawingState.drawingActivityNotifier.value;

      drawingState.setLastActiveScribbleNotifier(controller.scribbleNotifier);

      expect(drawingState.drawingActivityNotifier.value, greaterThan(before));
    });

    test('같은 레이어에 연속 호출해도(활성 변경 없음) 매번 증가한다', () {
      final drawingState = DrawingState();
      final notifier = controller.scribbleNotifier;

      // 첫 획 → 활성 지정.
      drawingState.setLastActiveScribbleNotifier(notifier);
      final afterFirst = drawingState.drawingActivityNotifier.value;

      // 같은 레이어에 두 번째 획 — 활성은 변하지 않지만(isSame=true) 활동은 발생.
      drawingState.setLastActiveScribbleNotifier(notifier);

      expect(
        drawingState.drawingActivityNotifier.value,
        greaterThan(afterFirst),
      );
    });

    test('리스너가 획 시작마다 통지된다', () {
      final drawingState = DrawingState();
      var notified = 0;
      void onActivity() => notified++;
      drawingState.drawingActivityNotifier.addListener(onActivity);
      addTearDown(
        () => drawingState.drawingActivityNotifier.removeListener(onActivity),
      );

      drawingState.setLastActiveScribbleNotifier(controller.scribbleNotifier);
      drawingState.setLastActiveScribbleNotifier(controller.scribbleNotifier);

      expect(notified, 2);
    });
  });
}
