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

    // NOTE: `loadScribble`은 페이지 로드(외부 데이터 반영)이므로 undo
    // baseline을 리셋한다. 사용자 필기 시뮬레이션은 setScribble을 사용한다.
    void draw(int strokeCount) {
      controller.scribbleNotifier.setScribble(
        scribble: createScribbleWithStrokes(strokeCount: strokeCount),
      );
    }

    test('스트로크 추가 -> undo -> redo 흐름이 정상 동작한다', () {
      // 1. 초기 상태 확인
      expect(controller.isEmpty, true);
      expect(controller.canUndo, false);
      expect(controller.canRedo, false);

      // 2. 페이지 로드 — undo 단계를 소모하지 않는다
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      expect(controller.currentScribble.strokes.length, 1);
      expect(controller.isEmpty, false);
      expect(controller.canUndo, false);

      // 3. 필기 추가 (2개 스트로크 상태)
      draw(2);
      expect(controller.currentScribble.strokes.length, 2);
      expect(controller.canUndo, true);

      // 4. Undo 실행 -> 로드된 상태(1개 스트로크)로 복원
      controller.undo();
      expect(controller.currentScribble.strokes.length, 1);
      expect(controller.canRedo, true);

      // 5. Redo 실행 -> 다시 2개 스트로크로 복원
      controller.redo();
      expect(controller.currentScribble.strokes.length, 2);
    });

    test('undo 후 스트로크가 제거된다', () {
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      draw(2);
      expect(controller.currentScribble.strokes.length, 2);

      // undo 실행
      controller.undo();

      // 이전 상태(1개 스트로크)로 복원됨
      expect(controller.currentScribble.strokes.length, 1);
    });

    test('redo 후 스트로크가 복원된다', () {
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      draw(2);
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

    test('페이지 로드는 undo로 빈 화면이 되지 않는다 (데이터 유실 방지)', () {
      // 페이지 로드가 히스토리에 push되면 undo 한 번으로 페이지 전체가
      // 빈 baseline으로 되돌아가고, 페이지 전환 시 빈 데이터가 저장되어
      // 원본이 영구 유실된다.
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 3));

      expect(controller.canUndo, false);
      controller.undo();
      expect(controller.currentScribble.strokes.length, 3);
    });

    test('canUndo/canRedo 상태가 정확히 반영된다', () {
      // 초기 상태: undo/redo 불가
      expect(controller.canUndo, false);
      expect(controller.canRedo, false);

      // 페이지 로드: 로드된 데이터가 새 baseline — undo 불가
      controller.loadScribble(createScribbleWithStrokes(strokeCount: 1));
      expect(controller.canUndo, false);
      expect(controller.canRedo, false);

      // 첫 필기: 즉시 undo 가능 (history = [s2, loaded]).
      // 관련: 이슈 #170 "페이지 최초 필기 시 되돌리기 버튼 비활성화 수정".
      // (회귀 테스트: scribble_notifier_reset_history_test.dart 참고)
      draw(2);
      expect(controller.canUndo, true);
      expect(controller.canRedo, false);

      // undo 후: 로드된 baseline 위치 — redo만 가능.
      controller.undo();
      expect(controller.canUndo, false);
      expect(controller.canRedo, true);

      // redo 후: 다시 s2 — undo 가능, redo 불가.
      controller.redo();
      expect(controller.canUndo, true);
      expect(controller.canRedo, false);
    });

    test('빈 페이지에서 첫 필기는 즉시 undo 가능하다 (#170)', () {
      draw(1);
      expect(controller.canUndo, true);

      controller.undo();
      expect(controller.isEmpty, true);
    });
  });
}
