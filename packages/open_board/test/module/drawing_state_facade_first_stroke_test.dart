import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

/// #5818 회귀 테스트 — 페이지 최초 필기 시 DrawingState 파사드의
/// canUndoNotifier 가 갱신되지 않아 undo 버튼(pill)이 비활성으로 남던 버그.
///
/// 배경: notifier 레벨 `canUndo`(=`ScribbleController.canUndo`)는 이미 #170 에서
/// 첫 획부터 true 였다(`draw_undo_redo_test.dart` 참고). 그러나 UI pill 은
/// `DrawingState.canUndoNotifier`(파사드)를 구독한다. 이 파사드는 오직
/// `updateUndoRedoState()` 로만 갱신되는데, 이 호출은 pointer-DOWN(획 커밋 전,
/// canUndo=false) · undo/redo · 도구변경 · 페이지전환에서만 일어나고 **획 커밋
/// (onPointerUp → notifier state 세터)** 시점에는 일어나지 않았다. 그래서 한
/// 페이지의 첫 획이 커밋돼도 파사드가 false 로 남아 undo 버튼이 비활성이었다.
///
/// 수정: `ScribbleController` 의 notifier 리스너에서, 활성 레이어의 canUndo/
/// canRedo 가 실제로 바뀌면 파사드를 갱신한다. 획 커밋 순간 canUndo 가 true 로
/// 바뀌므로 최초 획도 즉시 undo 가능해진다.
///
/// 테스트 노트: `DrawingState.updateUndoRedoState()` 는 `addPostFrameCallback`
/// 으로 값을 반영하므로, 위젯 트리를 pump 하고 프레임을 실제로 그려야
/// (`scheduleFrame`) 콜백이 흐른다. `_flushFrames` 가 그 역할을 한다.
void main() {
  group('DrawingState 파사드 canUndoNotifier — 페이지 최초 필기 (#5818)', () {
    late ScribbleController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = ScribbleController();
    });

    tearDown(() {
      controller.dispose();
    });

    /// 예약된 post-frame 갱신(파사드 update + setActive 의 50ms 지연 update)이
    /// 모두 실행되도록 여러 프레임을 강제로 그린다.
    Future<void> flushFrames(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        WidgetsBinding.instance.scheduleFrame();
        await tester.pump(const Duration(milliseconds: 30));
      }
    }

    testWidgets('활성 레이어에서 첫 획 커밋 시 canUndoNotifier 가 true 로 갱신된다', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());

      final drawingState = DrawingState();
      final notifier = controller.scribbleNotifier;
      final canUndoNotifier = drawingState.canUndoNotifier;

      // 1. pointer-DOWN 모사: 이 레이어를 활성(undo/redo 대상)으로 지정.
      drawingState.setLastActiveScribbleNotifier(notifier);

      // 2. 커밋 전 파사드 갱신을 모두 흘려보낸다 → false 로 안정.
      //    (실제로는 pointer-DOWN 시 canUndo=false 를 반영하는 단계.)
      await flushFrames(tester);
      expect(
        canUndoNotifier.value,
        isFalse,
        reason: '획 커밋 전에는 undo 불가(baseline 만 존재)',
      );

      // 3. 페이지 최초 필기 커밋 (= onPointerUp 의 `state = ...` 와 동일 경로).
      notifier.setScribble(scribble: createScribbleWithStrokes(strokeCount: 1));

      // 4. 커밋으로 예약된 파사드 갱신이 실행되도록 프레임을 흘린다.
      await flushFrames(tester);

      // notifier 레벨(#170)뿐 아니라 파사드도 즉시 undo 가능해야 한다(#5818).
      expect(notifier.canUndo, isTrue);
      expect(
        canUndoNotifier.value,
        isTrue,
        reason: '첫 획 커밋 후 파사드 canUndoNotifier 가 true 여야 pill undo 버튼이 활성화된다',
      );
    });

    testWidgets('첫 획을 undo 하면 baseline 으로 복원되고 파사드가 false 로 돌아간다', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());

      final drawingState = DrawingState();
      final notifier = controller.scribbleNotifier;
      final canUndoNotifier = drawingState.canUndoNotifier;

      drawingState.setLastActiveScribbleNotifier(notifier);
      await flushFrames(tester);

      notifier.setScribble(scribble: createScribbleWithStrokes(strokeCount: 1));
      await flushFrames(tester);
      expect(canUndoNotifier.value, isTrue);

      // 파사드 undo → baseline(빈 페이지)로 복원, 더는 undo 불가.
      drawingState.undo();
      await flushFrames(tester);

      expect(controller.isEmpty, isTrue);
      expect(canUndoNotifier.value, isFalse);
    });
  });
}
