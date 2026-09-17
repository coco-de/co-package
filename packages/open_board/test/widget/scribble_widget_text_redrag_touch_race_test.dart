import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/protobuf_factories.dart';

/// kobic#12374 후속 회귀 가드 — **터치 kTouchDelay(30ms) 레이스**.
///
/// `scribble_widget_text_body_redrag_other_mode_test.dart` 는 재드래그를
/// 스타일러스로 수행해(down이 지연 없이 동기 처리됨) 이 레이스를 노출하지
/// 않는다. 실사용(손가락 재드래그)은 down 이 [kTouchDelay](30ms) 만큼
/// `Future.delayed` 로 지연 처리되는데, 사용자가 down 직후 곧바로(30ms
/// 안에) 손가락을 움직이는 것이 자연스러운 드래그 동작이라 그 초기 move
/// 이벤트가 지연된 down 처리보다 먼저 도착한다.
///
/// 그 순간 `TextInteractionManager` 는 아직 `_prepareDrag`/
/// `_beginResizeRotate` 가 세팅되지 않은 상태라 `handlePointerMove` 가
/// `false` 를 반환하고, `ScribbleWidget._handlePointerMove` 의 "아무 것도
/// 처리되지 않음" 폴백이 이를 "다른 곳을 그리려는 의도"로 오판해
/// `hideTextOverlayAndDeselect()` 를 발동시킨다 — 손가락 재드래그가
/// "이동은 되지만 선택이 풀렸다 돌아온다"는 깜빡임으로, 핸들 재드래그가
/// "선택이 풀린다"는 결함으로 보고된 근본 원인.
///
/// 수정: down 이 아직 `_pendingTouchDowns` 에 남아 있는(= 지연 처리를
/// 거치지 않은) 포인터의 move 는 "미처리"를 근거로 선택 해제하지 않는다.
void main() {
  group(
    'ScribbleWidget 텍스트박스 재드래그 — 터치 kTouchDelay 레이스 (kobic#12374 후속)',
    () {
      late ScribbleNotifier scribbleNotifier;
      late ScribbleModeNotifier modeNotifier;

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        scribbleNotifier = ScribbleNotifier(
          scribble: Scribble(strokes: [], width: 300, height: 400),
        );
        modeNotifier = ScribbleModeNotifier()..setPencil();
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
        'pencil 모드에서 손가락 재드래그가 kTouchDelay 이내에 움직여도 '
        '선택이 풀리지 않고 결국 이동한다',
        (tester) async {
          final text = createTextDrawable(
            id: 't1',
            text: 'Hello World Testing',
            x: 100,
            y: 100,
            fontSize: 24,
          );
          scribbleNotifier.addTextDrawable(text);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          // 1) 손가락으로 기존(미선택) 텍스트를 탭해 선택한다.
          final selectGesture = await tester.startGesture(
            const Offset(100, 100),
          );
          await tester.pump(const Duration(milliseconds: 50));
          await selectGesture.up();
          await tester.pump();

          expect(DrawingState().hasSelectedTextBox.value, isTrue);

          // 더블탭(800ms) 오판을 피하려고 실제 시간을 흘려보낸다.
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 900)),
          );

          final originalPosition = scribbleNotifier
              .getCurrentTextDrawables()
              .firstWhere((t) => t.id == 't1')
              .position;

          // 2) 재드래그 — **터치**로, down 직후(fake 시간 0ms 경과) 곧바로
          //    움직인다. kTouchDelay(30ms)가 아직 흐르지 않았으므로
          //    ScribbleWidget._processPointerDown 이 이 down 을 아직
          //    처리하지 않은 상태에서 move 가 먼저 도착한다.
          final dragGesture = await tester.startGesture(
            const Offset(100, 100),
          ); // 기본 kind = touch
          await dragGesture.moveBy(const Offset(15, 10));

          // ⚠️ 이 시점에 선택이 풀려 있으면 레이스 가드가 없는 것이다 —
          // 아직 pump(duration)으로 30ms 를 흘리지 않았으므로 지연된 down
          // 처리(_beginResizeRotate/_prepareDrag)는 아직 일어나지 않았다.
          expect(
            DrawingState().hasSelectedTextBox.value,
            isTrue,
            reason:
                'kTouchDelay(30ms) 이내에 도착한 초기 move 만으로 선택이 '
                '풀리면 안 된다 — down 처리가 아직 도착하지 않았을 뿐, 다른 '
                '곳을 그리려는 의도가 아니다',
          );

          // 3) 지연된 down 이 실제로 처리되도록 시간을 흘린 뒤 드래그를
          //    계속하고 마무리한다.
          await tester.pump(const Duration(milliseconds: 50));
          await dragGesture.moveBy(const Offset(15, 10));
          await tester.pump();
          await dragGesture.up();
          await tester.pump();

          final afterPosition = scribbleNotifier
              .getCurrentTextDrawables()
              .firstWhere((t) => t.id == 't1')
              .position;

          expect(
            afterPosition,
            isNot(equals(originalPosition)),
            reason: '레이스를 넘긴 뒤에는 정상적으로 이동해야 한다',
          );
          expect(DrawingState().hasSelectedTextBox.value, isTrue);
        },
      );
    },
  );
}
