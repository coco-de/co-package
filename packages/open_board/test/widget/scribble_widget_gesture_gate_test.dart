import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/viewer_gesture_bus.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _ignoringCount(WidgetTester tester) => tester
    .widgetList<IgnorePointer>(find.byType(IgnorePointer))
    .where((widget) => widget.ignoring)
    .length;

void main() {
  group('ScribbleWidget G1 게이트 (ViewerGestureBus, kobic #7026)', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      modeNotifier = ScribbleModeNotifier();
      ViewerGestureBus().reset();
    });

    tearDown(() {
      ViewerGestureBus().reset();
      scribbleNotifier.dispose();
      modeNotifier.dispose();
    });

    Widget buildTestWidget() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: ScribbleWidget(
            notifier: scribbleNotifier,
            modeNotifier: modeNotifier,
            child: const SizedBox(width: 300, height: 400),
          ),
        ),
      ),
    );

    testWidgets('should_engage_ignore_pointer_when_panel_dragging', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final baseline = _ignoringCount(tester);

      ViewerGestureBus().setPanelDragging(dragging: true);
      await tester.pump();

      // 핸들 드래그 중 → 게이트 IgnorePointer 1개 추가 활성(캔버스 입력 차단).
      expect(_ignoringCount(tester), baseline + 1);

      // kobic UB-213: watchdog Timer 를 테스트 종료 전 명시적으로 취소한다 —
      // tearDown 의 reset() 은 flutter_test 의 pending-timer 불변식 검사보다
      // 늦게 실행되어 여기서 취소하지 않으면 다음 테스트에서
      // "A Timer is still pending" 로 실패한다.
      ViewerGestureBus().reset();
    });

    testWidgets('should_release_ignore_pointer_when_drag_ends', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final baseline = _ignoringCount(tester);

      ViewerGestureBus().setPanelDragging(dragging: true);
      await tester.pump();
      ViewerGestureBus().setPanelDragging(dragging: false);
      await tester.pump();

      // release 후 게이트 해제 → baseline 회복(그리기 재개 가능).
      expect(_ignoringCount(tester), baseline);
    });

    // kobic UB-213: release 신호가 유실돼도(up/cancel/dispose 미호출) 실제
    // ScribbleWidget/IgnorePointer 트리에 watchdog 자동 해제가 전파되는지
    // 검증 — bus 단위 테스트(viewer_gesture_bus_test.dart)는 IgnorePointer
    // 까지 도달하는지 증명하지 않으므로 이 위젯 트리에서 실제 Timer 로 확인.
    testWidgets(
      'should_release_ignore_pointer_via_real_watchdog_when_release_lost',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        final baseline = _ignoringCount(tester);

        ViewerGestureBus().setPanelDragging(dragging: true);
        await tester.pump();
        expect(_ignoringCount(tester), baseline + 1);

        // release(up/cancel) 없이 watchdog 최대 시간만 흘려보낸다.
        await tester.pump(
          ViewerGestureBus.maxStaleDuration + const Duration(milliseconds: 50),
        );

        // watchdog 이 실제 IgnorePointer 트리까지 자동 해제를 전파해야 한다.
        expect(_ignoringCount(tester), baseline);
      },
    );
  });
}
