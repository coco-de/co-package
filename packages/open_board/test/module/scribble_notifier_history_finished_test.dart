// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';

/// 실행 취소 · 다시 실행도 내용을 바꾸는 완료다 (unibook#14751 R1-G3).
///
/// [ScribbleNotifier.onScribbleFinished] 는 `setScribble` · 텍스트 · 이미지처럼
/// 히스토리에 커밋된 편집의 완료를 알린다. 실행 취소 · 다시 실행은 값 알림만
/// 내고 이 콜백을 부르지 않아, 완료 시점에만 도는 호스트의 표면 간 동기화가
/// 실행 취소를 반대편 표면에 옮기지 못했다 — 반대편에서 다음에 그으면 취소한
/// 획이 되살아나 저장된다.
void main() {
  PointerDownEvent down(double x, double y) => PointerDownEvent(
    kind: PointerDeviceKind.stylus,
    pointer: 1,
    position: Offset(x, y),
  );
  PointerMoveEvent move(double x, double y) => PointerMoveEvent(
    kind: PointerDeviceKind.stylus,
    pointer: 1,
    position: Offset(x, y),
  );
  PointerUpEvent up(double x, double y) => PointerUpEvent(
    kind: PointerDeviceKind.stylus,
    pointer: 1,
    position: Offset(x, y),
  );

  late ScribbleNotifier notifier;
  late ScribbleModeNotifier mode;
  late int finished;

  setUp(() {
    notifier = ScribbleNotifier()..resetHistoryToBaseline();
    mode = ScribbleModeNotifier();
    finished = 0;
    notifier.onScribbleFinished = () => finished++;
  });

  tearDown(() {
    notifier.dispose();
    mode.dispose();
  });

  void drawStroke() {
    notifier
      ..onPointerDown(down(10, 10), mode.state)
      ..onPointerUpdate(move(40, 40), mode.state)
      ..onPointerUp(up(60, 60), mode.state);
  }

  test('should_notify_finished_when_undo_and_redo_change_content', () {
    drawStroke();
    expect(notifier.value.scribble.strokes, hasLength(1));
    expect(finished, 0, reason: '획 커밋의 완료는 PointerEventHandler 가 알린다');

    notifier.undo();
    expect(notifier.value.scribble.strokes, isEmpty);
    expect(finished, 1, reason: '실행 취소는 내용을 바꾼 완료다');

    notifier.redo();
    expect(notifier.value.scribble.strokes, hasLength(1));
    expect(finished, 2, reason: '다시 실행도 내용을 바꾼 완료다');
  });

  test('should_not_notify_finished_when_there_is_nothing_to_undo_or_redo', () {
    expect(notifier.canUndo, isFalse);
    expect(notifier.canRedo, isFalse);

    notifier
      ..undo()
      ..redo();

    expect(finished, 0, reason: '되돌릴 것이 없으면 내용이 그대로다');
  });
}
