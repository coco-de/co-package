import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Draw -> Undo -> Redo 통합 흐름', () {
    late ScribbleController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      try {
        // DrawingState 싱글톤 초기화
      } catch (_) {}
      controller = ScribbleController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('스트로크 추가 -> undo -> redo 흐름이 정상 동작한다', () {
      // 1. 초기 상태 확인
      expect(controller.isEmpty, true);
      expect(controller.canUndo, false);
      expect(controller.canRedo, false);

      // 2. 첫 번째 스트로크 추가
      final scribbleWith1Stroke = createScribbleWithStrokes(strokeCount: 1);
      controller.loadScribble(scribbleWith1Stroke);
      expect(controller.currentScribble.strokes.length, 1);
      expect(controller.isEmpty, false);

      // 3. 두 번째 스트로크 추가 (2개 스트로크)
      // HistoryValueNotifierMixin: 2번째 상태 변경 후 canUndo가 true가 됨
      final scribbleWith2Strokes = createScribbleWithStrokes(strokeCount: 2);
      controller.loadScribble(scribbleWith2Strokes);
      expect(controller.currentScribble.strokes.length, 2);
      expect(controller.canUndo, true);

      // 4. Undo 실행 -> 이전 상태(1개 스트로크)로 복원
      controller.undo();
      expect(controller.currentScribble.strokes.length, 1);
      expect(controller.canRedo, true);

      // 5. Redo 실행 -> 다시 2개 스트로크로 복원
      controller.redo();
      expect(controller.currentScribble.strokes.length, 2);
    });

    test('undo 후 스트로크가 제거된다', () {
      // 두 단계로 스트로크 추가하여 undo 히스토리 생성
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 2));
      expect(controller.currentScribble.strokes.length, 2);

      // undo 실행
      controller.undo();

      // 이전 상태(1개 스트로크)로 복원됨
      expect(controller.currentScribble.strokes.length, 1);
    });

    test('redo 후 스트로크가 복원된다', () {
      // 두 단계로 스트로크 추가 후 undo
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 2));
      controller.undo();
      expect(controller.currentScribble.strokes.length, 1);

      // redo 실행
      controller.redo();

      // 스트로크가 복원됨
      expect(controller.currentScribble.strokes.length, 2);
    });

    test('clear 후 undo로 복원 가능하다', () {
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 3));
      expect(controller.currentScribble.strokes.length, 3);

      controller.clear();
      expect(controller.isEmpty, true);
      expect(controller.canUndo, true);

      controller.undo();
      expect(controller.currentScribble.strokes.length, 3);
    });

    test('canUndo/canRedo 상태가 정확히 반영된다', () {
      // 초기 상태: undo/redo 불가
      expect(controller.canUndo, false);
      expect(controller.canRedo, false);

      // 첫 스트로크 추가: `resetHistoryToBaseline()` 이 baseline 을 history 에
      // 미리 push 하므로 첫 변경도 즉시 undo 가능하다 (히스토리 = [s1, baseline]).
      // 관련: 이슈 #170 "페이지 최초 필기 시 되돌리기 버튼 비활성화 수정".
      // (회귀 테스트: scribble_notifier_reset_history_test.dart 참고)
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      expect(controller.canUndo, true);
      expect(controller.canRedo, false);

      // 두 번째 스트로크 추가: history = [s2, s1, baseline]. 여전히 undo 가능.
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 2));
      expect(controller.canUndo, true);
      expect(controller.canRedo, false);

      // undo 후: 인덱스가 s1 위치(1)로 이동. 아래로 baseline 이 남아 undo 가능,
      // 위로 s2 가 있어 redo 도 가능하다.
      controller.undo();
      expect(controller.canUndo, true);
      expect(controller.canRedo, true);

      // redo 후: 인덱스가 s2(0)로 복귀. undo 가능, redo 불가.
      controller.redo();
      expect(controller.canUndo, true);
      expect(controller.canRedo, false);
    });
  });
}
