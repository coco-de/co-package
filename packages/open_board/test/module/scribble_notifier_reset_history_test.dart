import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble.notifier.dart';

import '../helpers/protobuf_factories.dart';

/// 회귀 테스트: "페이지 최초 필기 시 되돌리기 버튼 비활성화" 버그 (kobic #6316).
///
/// `ScribbleController._initializeNotifiers()` 에서 spurious history 를 비우기 위해
/// `clearQueue()` 만 호출하면 history 가 완전히 비워져, 첫 변경 시
/// `_undoHistory.length == 1` 이 되어 `canUndo = _undoIndex(0) + 1 < 1 = false`
/// 가 되는 버그가 있었다.
///
/// `resetHistoryToBaseline()` 은 clearQueue 직후 현재 상태를 baseline 으로 history 에
/// 추가하여 첫 변경이 즉시 undo 가능하도록 보정한다.
void main() {
  group('ScribbleNotifier.resetHistoryToBaseline()', () {
    late ScribbleNotifier notifier;

    setUp(() {
      notifier = ScribbleNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('호출 직후에는 변경 사항이 없으므로 canUndo 는 false 다', () {
      notifier.resetHistoryToBaseline();
      expect(notifier.canUndo, isFalse);
    });

    test('첫 변경 이후 canUndo 가 true 가 되어야 한다 (회귀 방지)', () {
      notifier.resetHistoryToBaseline();

      // 첫 stroke 추가
      notifier.setScribble(
        scribble: createScribbleWithStrokes(strokeCount: 1),
      );

      expect(
        notifier.canUndo,
        isTrue,
        reason:
            'resetHistoryToBaseline 후 첫 변경은 즉시 undo 가능해야 합니다. '
            '(buggy clearQueue 만 호출 시 length=1 -> canUndo=false 가 됨)',
      );
    });

    test('첫 stroke 후 undo 하면 빈 상태로 복원된다', () {
      notifier.resetHistoryToBaseline();
      notifier.setScribble(
        scribble: createScribbleWithStrokes(strokeCount: 1),
      );

      notifier.undo();

      expect(notifier.currentScribble.strokes, isEmpty);
    });

    test('연속된 stroke 변경에서 모두 undo 가능해야 한다', () {
      notifier.resetHistoryToBaseline();

      notifier.setScribble(
        scribble: createScribbleWithStrokes(strokeCount: 1),
      );
      expect(notifier.canUndo, isTrue);

      notifier.setScribble(
        scribble: createScribbleWithStrokes(strokeCount: 2),
      );
      expect(notifier.canUndo, isTrue);

      // 2번 undo 후 baseline (빈 상태) 도달
      notifier.undo();
      expect(notifier.currentScribble.strokes.length, 1);

      notifier.undo();
      expect(notifier.currentScribble.strokes, isEmpty);
    });
  });
}
