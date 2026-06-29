import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/viewer_gesture_bus.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 필기 서브트리에 "스타일러스 전용 pan 차단" [RawGestureDetector] 가 있는지 검사.
///
/// `_blockStylusPan` 이 추가한 [EagerGestureRecognizer] 는 stylus/invertedStylus
/// 만 [GestureRecognizer.supportedDevices] 로 가지며 touch 는 포함하지 않는다.
/// (kobic #7364 — 스타일러스 필기 시 컨텐츠가 함께 이동하던 race 차단)
bool _hasStylusPanBlocker(WidgetTester tester) {
  final detectors = tester.widgetList<RawGestureDetector>(
    find.byType(RawGestureDetector),
  );
  for (final detector in detectors) {
    final factory = detector.gestures[EagerGestureRecognizer];
    if (factory == null) {
      continue;
    }
    final recognizer = factory.constructor();
    final devices = recognizer.supportedDevices;
    recognizer.dispose();
    if (devices != null &&
        devices.contains(PointerDeviceKind.stylus) &&
        devices.contains(PointerDeviceKind.invertedStylus) &&
        !devices.contains(PointerDeviceKind.touch) &&
        !devices.contains(PointerDeviceKind.mouse)) {
      return true;
    }
  }
  return false;
}

void main() {
  group('ScribbleWidget 스타일러스 pan 차단 (kobic #7364)', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      modeNotifier = ScribbleModeNotifier();
      ViewerGestureBus().reset();
      // 기본 필기 도구(연필)로 초기화 — 하이라이터 테스트에서 변경 후 복원한다.
      DrawingState().selectedTool.value = DrawingTool.pencil;
    });

    tearDown(() {
      DrawingState().selectedTool.value = DrawingTool.pencil;
      ViewerGestureBus().reset();
      scribbleNotifier.dispose();
      modeNotifier.dispose();
    });

    Widget buildTestWidget({bool isScribbleEnable = true}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: ScribbleWidget(
            notifier: scribbleNotifier,
            modeNotifier: modeNotifier,
            isScribbleEnable: isScribbleEnable,
            child: const SizedBox(width: 300, height: 400),
          ),
        ),
      ),
    );

    testWidgets(
      'should_block_stylus_pan_when_drawing_tool_active',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 필기 도구(연필) 활성 → 스타일러스 전용 pan 차단 recognizer 존재.
        expect(_hasStylusPanBlocker(tester), isTrue);
      },
    );

    testWidgets(
      'should_not_block_stylus_when_highlighter_active',
      (tester) async {
        DrawingState().selectedTool.value = DrawingTool.highlighter;
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 하이라이터 모드에서는 스타일러스가 pdfrx 텍스트 선택을 해야 하므로
        // pan 차단 recognizer 가 없어야 한다(스타일러스 투과).
        expect(_hasStylusPanBlocker(tester), isFalse);
      },
    );

    testWidgets(
      'should_not_block_stylus_when_scribble_disabled',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(isScribbleEnable: false));
        await tester.pumpAndSettle();

        // 필기 비활성(순수 열람) 시에는 차단하지 않는다.
        expect(_hasStylusPanBlocker(tester), isFalse);
      },
    );
  });
}
