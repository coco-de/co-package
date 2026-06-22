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
  });
}
