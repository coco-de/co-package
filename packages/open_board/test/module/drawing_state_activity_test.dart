// DrawingState.drawingActivityNotifier — 실제 사용자 획(markDrawingActivity)마다
// 증가하는 필기 활동 틱 검증 (kobic #7491, #7496).
//
// canUndo/canRedo(ValueNotifier<bool>)는 값이 바뀔 때만 알림하므로, 이미 이력이
// 있는 레이어의 연속 획을 활동으로 감지하지 못한다(#7491). 활동 틱은 boolean 값과
// 무관하게 매 획을 신호한다.
//
// ⚠️ #7496: setLastActiveScribbleNotifier 는 사용자 획뿐 아니라 페이지/탭 전환 시
// 캐시 매니저(setActiveController)에서도 호출되므로, 여기서 틱을 올리면 페이지
// 이동만으로 pill 이 깜빡인다. 따라서 틱은 markDrawingActivity(실제 pointer-down)
// 에서만 발화하고, setLastActiveScribbleNotifier 는 발화하지 않아야 한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // UndoRedoTracker 가 WidgetsBinding.addPostFrameCallback 을 사용하므로
  // (dispose/updateUndoRedoState 경로) 바인딩 초기화가 필요하다.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrawingState.drawingActivityNotifier (#7491, #7496)', () {
    late ScribbleController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = ScribbleController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('markDrawingActivity 는 활동 틱을 증가시킨다', () {
      final drawingState = DrawingState();
      final before = drawingState.drawingActivityNotifier.value;

      drawingState.markDrawingActivity();

      expect(drawingState.drawingActivityNotifier.value, greaterThan(before));
    });

    test('markDrawingActivity 연속 호출 시 매번 증가한다', () {
      final drawingState = DrawingState();

      drawingState.markDrawingActivity();
      final afterFirst = drawingState.drawingActivityNotifier.value;
      drawingState.markDrawingActivity();

      expect(
        drawingState.drawingActivityNotifier.value,
        greaterThan(afterFirst),
      );
    });

    // #7496 회귀 가드: 페이지/탭 전환(setActiveController → setLastActive)이
    // 활동으로 오인되면 pill 이 깜빡인다. setLastActive 는 틱을 올리지 않아야 한다.
    test('setLastActiveScribbleNotifier 는 활동 틱을 올리지 않는다', () {
      final drawingState = DrawingState();
      final before = drawingState.drawingActivityNotifier.value;

      drawingState.setLastActiveScribbleNotifier(controller.scribbleNotifier);

      expect(drawingState.drawingActivityNotifier.value, before);
    });

    test('리스너가 markDrawingActivity 마다 통지된다', () {
      final drawingState = DrawingState();
      var notified = 0;
      void onActivity() => notified++;
      drawingState.drawingActivityNotifier.addListener(onActivity);
      addTearDown(
        () => drawingState.drawingActivityNotifier.removeListener(onActivity),
      );

      drawingState.markDrawingActivity();
      drawingState.markDrawingActivity();

      expect(notified, 2);
    });
  });
}
