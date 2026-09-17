import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/protobuf_factories.dart';

/// kobic#12374 회귀 가드.
///
/// 텍스트박스가 선택된 채로 다른 필기 도구(펜/지우개 등)로 전환하면 호스트
/// 앱(`pdf_viewer_widget.dart`)의 `_shouldTrackAsPenPointer` 게이트가
/// `DrawingState().hasSelectedTextBox` 를 참조해, 어느 도구가 활성이든
/// 손가락으로도 그 컨트롤을 계속 조작할 수 있게 한다. 이 테스트는 그
/// 플래그가 `ScribbleWidget` 의 텍스트 선택/해제/dispose 마다 정확히
/// 동기화되는지 — open_board 쪽 절반을 검증한다.
void main() {
  group('ScribbleWidget → DrawingState.hasSelectedTextBox 동기화 (kobic#12374)', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      modeNotifier = ScribbleModeNotifier()..setText();
      DrawingState().hasSelectedTextBox.value = false;
    });

    tearDown(() {
      scribbleNotifier.dispose();
      modeNotifier.dispose();
      DrawingState().hasSelectedTextBox.value = false;
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

    testWidgets(
      '텍스트박스를 선택하면 true, 선택 해제하면 false 로 동기화된다',
      (tester) async {
        final text = createTextDrawable(
          id: 't1',
          text: 'Hello',
          x: 100,
          y: 100,
        );
        scribbleNotifier.addTextDrawable(text);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(DrawingState().hasSelectedTextBox.value, isFalse);

        // 스타일러스는 ScribbleWidget 이 지연 없이 동기 처리하므로
        // 결정적으로 테스트할 수 있다(디바이스 종류는 이 동기화 로직과
        // 무관 — _shouldTrackAsPenPointer 는 호스트 앱 쪽에서 검증한다).
        final selectGesture = await tester.startGesture(
          const Offset(100, 100),
          kind: PointerDeviceKind.stylus,
        );
        await tester.pump();
        await selectGesture.up();
        await tester.pump();

        expect(DrawingState().hasSelectedTextBox.value, isTrue);

        // 텍스트 바깥의 빈 영역을 탭하면 선택이 해제된다.
        final deselectGesture = await tester.startGesture(
          const Offset(280, 380),
          kind: PointerDeviceKind.stylus,
        );
        await tester.pump();
        await deselectGesture.up();
        await tester.pump();

        expect(DrawingState().hasSelectedTextBox.value, isFalse);
      },
    );

    testWidgets(
      '텍스트박스가 선택된 채로 위젯이 dispose 되면 false 로 복원된다',
      (tester) async {
        final text = createTextDrawable(
          id: 't1',
          text: 'Hello',
          x: 100,
          y: 100,
        );
        scribbleNotifier.addTextDrawable(text);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final selectGesture = await tester.startGesture(
          const Offset(100, 100),
          kind: PointerDeviceKind.stylus,
        );
        await tester.pump();
        await selectGesture.up();
        await tester.pump();

        expect(DrawingState().hasSelectedTextBox.value, isTrue);

        // 위젯을 트리에서 제거해 dispose 를 유발한다.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(
          DrawingState().hasSelectedTextBox.value,
          isFalse,
          reason:
              '선택된 채로 위젯이 사라지면 플래그를 되돌려야 한다 — 그러지 '
              '않으면 이 위젯이 사라진 뒤에도 다른 도구에서 손가락 입력이 '
              '계속 필기 레이어로 새어 들어간다',
        );
      },
    );
  });
}
