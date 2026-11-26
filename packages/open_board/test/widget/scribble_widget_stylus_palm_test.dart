// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ScribbleNotifier notifier;
  late ScribbleModeNotifier modeNotifier;
  late List<Scribble> finished;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifier = ScribbleNotifier(scribble: Scribble(width: 300, height: 400));
    modeNotifier = ScribbleModeNotifier()..setPen();
    finished = [];
    DrawingState().pointerMode.value = .penOnly;
    DrawingState().selectedTool.value = .pen;
  });

  tearDown(() {
    DrawingState().selectedTool.value = .pencil;
    notifier.dispose();
    modeNotifier.dispose();
  });

  Future<Offset> mount(
    WidgetTester tester, {
    bool deferDrawStart = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: ScribbleWidget(
              notifier: notifier,
              modeNotifier: modeNotifier,
              isScribbleEnable: true,
              shouldDeferDrawStart: deferDrawStart ? (_) => true : null,
              onScribbleFinished: (state) =>
                  finished.add(state.currentState.scribble),
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getCenter(find.byType(ScribbleWidget));
  }

  testWidgets('should_commit_pen_strokes_while_two_touches_are_held', (
    tester,
  ) async {
    final center = await mount(tester);
    final firstTouch = await tester.startGesture(
      center + const Offset(-85, 60),
    );
    final secondTouch = await tester.startGesture(
      center + const Offset(85, 60),
    );
    await tester.pump(const Duration(milliseconds: 40));

    for (final offset in [const Offset(0, -45), const Offset(0, -5)]) {
      final start = center + offset;
      final pen = await tester.startGesture(start, kind: .stylus);
      await tester.pump();
      await pen.moveTo(start + const Offset(30, 15));
      await tester.pump();
      final drawing = notifier.currentState as Drawing;
      expect(drawing.activeLine?.points, hasLength(2));
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.scaleEnabled, isFalse);
      expect(viewer.panEnabled, isFalse);
      await pen.up();
      await tester.pump();
      expect(notifier.currentState.activePointerIds, isEmpty);
    }

    expect(notifier.currentState.scribble.strokes, hasLength(2));
    expect(finished, hasLength(2));
    await firstTouch.up();
    await secondTouch.up();
    await tester.pumpAndSettle();
  });

  testWidgets('should_keep_pen_active_when_other_contacts_end_or_cancel', (
    tester,
  ) async {
    final center = await mount(tester);
    final beforePen = await tester.startGesture(center + const Offset(-85, 60));
    await tester.pump(const Duration(milliseconds: 40));
    final pen = await tester.startGesture(center, kind: .stylus);
    await tester.pump();
    final afterPen = await tester.startGesture(center + const Offset(85, 60));
    await beforePen.cancel();
    await afterPen.up();
    await tester.pump();

    expect(finished, isEmpty);
    expect(notifier.currentState.activePointerIds, hasLength(1));
    await pen.moveBy(const Offset(35, 25));
    await pen.cancel();
    await tester.pumpAndSettle();

    expect(notifier.currentState.activePointerIds, isEmpty);
    expect(notifier.currentState.scribble.strokes, hasLength(1));
    expect(finished, hasLength(1));
  });

  testWidgets('should_discard_deferred_pen_tap_when_two_touches_are_held', (
    tester,
  ) async {
    final center = await mount(tester, deferDrawStart: true);
    final firstTouch = await tester.startGesture(
      center + const Offset(-85, 60),
    );
    final secondTouch = await tester.startGesture(
      center + const Offset(85, 60),
    );
    await tester.pump(const Duration(milliseconds: 40));

    final pen = await tester.startGesture(center, kind: .stylus);
    await tester.pump();
    final viewer = find.byType(InteractiveViewer);
    expect(tester.widget<InteractiveViewer>(viewer).scaleEnabled, isFalse);
    await pen.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(notifier.currentState.scribble.strokes, isEmpty);
    expect(notifier.currentState.activePointerIds, isEmpty);
    expect(tester.widget<InteractiveViewer>(viewer).scaleEnabled, isTrue);
    await firstTouch.up();
    await secondTouch.up();
    await tester.pumpAndSettle();
  });
}
