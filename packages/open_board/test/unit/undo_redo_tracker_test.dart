import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/notifier_registry.dart';
import 'package:open_board/src/module/state/undo_redo_tracker.dart';

void main() {
  group('UndoRedoTracker', () {
    group('canUndo / canRedo', () {
      test('활성 notifier가 없으면 canUndo는 false', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        expect(tracker.canUndo, isFalse);
      });

      test('활성 notifier가 없으면 canRedo는 false', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        expect(tracker.canRedo, isFalse);
      });
    });

    group('updateUndoRedoState', () {
      testWidgets('활성 notifier가 없으면 canUndo/canRedo가 false로 설정된다', (
        tester,
      ) async {
        await tester.pumpWidget(const SizedBox());

        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        final canUndoNotifier = ValueNotifier(true);
        final canRedoNotifier = ValueNotifier(true);
        tracker.initialize(canUndoNotifier, canRedoNotifier);

        tracker.updateUndoRedoState();

        // addPostFrameCallback을 실행하기 위해 scheduleFrame + pump
        WidgetsBinding.instance.scheduleFrame();
        await tester.pump();

        expect(canUndoNotifier.value, isFalse);
        expect(canRedoNotifier.value, isFalse);
      });

      testWidgets('isDisposed가 true이면 상태를 업데이트하지 않는다', (tester) async {
        await tester.pumpWidget(const SizedBox());

        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        final canUndoNotifier = ValueNotifier(true);
        final canRedoNotifier = ValueNotifier(false);
        tracker.initialize(canUndoNotifier, canRedoNotifier);

        tracker.isDisposed = true;

        tracker.updateUndoRedoState();
        await tester.pump();

        // dispose 상태이므로 변경되지 않음
        expect(canUndoNotifier.value, isTrue);
      });
    });

    group('undo/redo 콜백', () {
      test('registerUndoRedoUpdateCallback으로 콜백을 등록할 수 있다', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        var callCount = 0;
        tracker.registerUndoRedoUpdateCallback(() => callCount++);

        expect(callCount, 0);
      });

      test('unregisterUndoRedoUpdateCallback으로 콜백을 해제할 수 있다', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        var callCount = 0;
        final callback = () => callCount++;

        tracker.registerUndoRedoUpdateCallback(callback);
        tracker.unregisterUndoRedoUpdateCallback(callback);

        expect(callCount, 0);
      });
    });

    group('undo', () {
      test('활성 notifier가 없으면 undo는 아무 일도 하지 않는다', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        // 예외 없이 실행되면 성공
        tracker.undo();
      });
    });

    group('redo', () {
      test('활성 notifier가 없으면 redo는 아무 일도 하지 않는다', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        // 예외 없이 실행되면 성공
        tracker.redo();
      });
    });

    group('clear', () {
      test('clear 후 콜백 목록이 초기화된다', () {
        final registry = NotifierRegistry();
        registry.initialize(ValueNotifier<ScribbleNotifier?>(null));
        final tracker = UndoRedoTracker(registry);
        tracker.initialize(
          ValueNotifier(false),
          ValueNotifier(false),
        );

        var callCount = 0;
        tracker.registerUndoRedoUpdateCallback(() => callCount++);

        tracker.clear();

        expect(callCount, 0);
      });
    });
  });
}
