import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScribbleController 생명주기 통합 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // DrawingState 싱글톤 초기화
      try {
        DrawingState().dispose();
      } catch (_) {}
    });

    tearDown(() {
      try {
        DrawingState().dispose();
      } catch (_) {}
    });

    test('ScribbleController 생성 시 DrawingState에 등록된다', () {
      final drawingState = DrawingState();
      final initialNotifierCount = drawingState.activeNotifierCount;
      final initialScribbleNotifierCount =
          drawingState.activeScribbleNotifierCount;

      final controller = ScribbleController();

      // lazy 초기화이므로 프로퍼티 접근으로 초기화 유도
      final _ = controller.scribbleNotifier;

      expect(
        drawingState.activeNotifierCount,
        initialNotifierCount + 1,
      );
      expect(
        drawingState.activeScribbleNotifierCount,
        initialScribbleNotifierCount + 1,
      );

      controller.dispose();
    });

    test('ScribbleController dispose 시 DrawingState에서 해제된다', () {
      final drawingState = DrawingState();
      final initialNotifierCount = drawingState.activeNotifierCount;
      final initialScribbleNotifierCount =
          drawingState.activeScribbleNotifierCount;

      final controller = ScribbleController();
      // lazy 초기화 유도
      final _ = controller.scribbleNotifier;

      // 등록 확인
      expect(
        drawingState.activeNotifierCount,
        initialNotifierCount + 1,
      );

      // dispose
      controller.dispose();

      // 해제 확인
      expect(
        drawingState.activeNotifierCount,
        initialNotifierCount,
      );
      expect(
        drawingState.activeScribbleNotifierCount,
        initialScribbleNotifierCount,
      );
    });

    test('여러 컨트롤러 생성/해제가 정상 동작한다', () {
      final drawingState = DrawingState();
      final initialCount = drawingState.activeNotifierCount;

      final controller1 = ScribbleController();
      final controller2 = ScribbleController();
      final controller3 = ScribbleController();

      // lazy 초기화 유도
      final _ = controller1.scribbleNotifier;
      final __ = controller2.scribbleNotifier;
      final ___ = controller3.scribbleNotifier;

      expect(drawingState.activeNotifierCount, initialCount + 3);
      expect(
        drawingState.activeScribbleNotifierCount,
        initialCount + 3,
      );

      // 하나씩 해제
      controller1.dispose();
      expect(drawingState.activeNotifierCount, initialCount + 2);

      controller2.dispose();
      expect(drawingState.activeNotifierCount, initialCount + 1);

      controller3.dispose();
      expect(drawingState.activeNotifierCount, initialCount);
    });

    test('dispose 후 DrawingState 상태가 정상이다', () {
      final drawingState = DrawingState();

      final controller = ScribbleController();
      final _ = controller.scribbleNotifier;

      controller.dispose();

      // DrawingState 자체는 dispose되지 않음
      expect(drawingState.isDisposed, false);
    });
  });
}
