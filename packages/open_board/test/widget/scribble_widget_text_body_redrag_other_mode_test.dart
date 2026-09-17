import 'package:flutter/gestures.dart' show PointerDeviceKind;
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

/// kobic#12374 후속 회귀 가드.
///
/// 실사용 시나리오는 **모드를 전환하는 것이 아니라, 처음부터 다른
/// 도구(펜슬 등)에 있는 상태에서** 이미 존재하는(선택되지 않은) 텍스트를
/// 탭해 선택한 뒤, 그 상태로 다시 드래그하는 흐름이다.
///
/// ⚠️ 텍스트 모드에서 선택한 뒤 다른 모드로 **전환**하는 시나리오는 이
/// 결함과 무관하다 — `ScribbleWidget._onModeChanged`가 텍스트 모드를
/// 벗어나는 즉시 선택을 강제로 해제하기 때문에(의도된 기존 동작),
/// "다른 모드인데 선택된 상태"는 그 경로로는 애초에 발생할 수 없다.
///
/// "선택된 상태"가 성립하는 유일한 경로는 **다른 모드에 있는 동안** 기존
/// 텍스트를 탭해 선택하는 것이다 — 이때도 `ScribbleWidget._processPointerDown`
/// 의 mode-based dispatch(`else` 분기)가 `isTouchOrMouse` 만 허용하므로
/// (`스타일러스는 그리기 의도로 간주해 텍스트 상호작용 차단`), **선택
/// 자체는 손가락/마우스로만 가능**하다.
///
/// 과거 `_handleTextSelectionArea` 는 도구가 정확히 text 일 때만
/// `textManager.handlePointerDown` 을 호출했다 — 다른 도구에서는
/// "선택 상태만 유지"라는 이름으로 아무 것도 하지 않았다(raw pointer 경로가
/// `_prepareDrag` 를 호출하지 않음). 그 결과 뒤이은 `handlePointerMove` 가
/// "아무 것도 처리되지 않음"으로 판정해 `hideTextOverlayAndDeselect` 를
/// 발동시켰다.
void main() {
  group(
    'ScribbleWidget 텍스트박스 본문 재드래그 — 다른 도구 모드 (kobic#12374 후속)',
    () {
      late ScribbleNotifier scribbleNotifier;
      late ScribbleModeNotifier modeNotifier;

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        scribbleNotifier = ScribbleNotifier(
          scribble: Scribble(strokes: [], width: 300, height: 400),
        );
        // 처음부터 다른 도구(pencil) — 텍스트 모드를 거치지 않는다.
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
        'pencil 모드에서 손가락으로 기존 텍스트를 선택한 뒤 재드래그하면 '
        '이동하고 선택이 유지된다',
        (tester) async {
          // 충분히 큰 텍스트를 써서 중심점이 삭제/변형 버튼(모서리, 반경
          // 24.5px)의 히트 영역과 겹치지 않도록 한다.
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

          // 1) pencil 모드에서 손가락으로 기존(미선택) 텍스트를 탭해
          //    선택한다 — 스타일러스라면 "그리기 의도"로 간주돼 선택
          //    자체가 되지 않는다(_processPointerDown 의 mode-based
          //    dispatch, isTouchOrMouse 게이트).
          final selectGesture = await tester.startGesture(
            const Offset(100, 100),
          ); // 기본 kind = touch
          // ⚠️ ScribbleWidget._handlePointerDown 은 touch 를 kTouchDelay
          // (30ms) 만큼 Future.delayed 로 지연 처리한다 — duration 없는
          // pump() 는 fake clock 을 전혀 흘리지 않아 그 콜백이 발화하지
          // 않는다.
          await tester.pump(const Duration(milliseconds: 50));
          await selectGesture.up();
          await tester.pump();

          expect(
            DrawingState().hasSelectedTextBox.value,
            isTrue,
            reason: 'pencil 모드에서도 손가락 탭으로 기존 텍스트가 선택돼야 한다',
          );

          // _isDoubleTap 판정(실제 벽시계, 800ms)에 걸리지 않도록
          // runAsync 로 fake-async 존을 벗어나 실제 시간을 흘려보낸다.
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 900)),
          );

          final originalPosition = scribbleNotifier
              .getCurrentTextDrawables()
              .firstWhere((t) => t.id == 't1')
              .position;

          // 2) 이미 선택된 상태에서 본문을 **새로운 별개의 제스처**로
          //    드래그한다(스타일러스 — 원 리포트의 "펜도 마찬가지"에 대응).
          final dragGesture = await tester.startGesture(
            const Offset(100, 100),
            kind: PointerDeviceKind.stylus,
          );
          await tester.pump();
          await dragGesture.moveBy(const Offset(30, 20));
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
            reason:
                'kobic#12374 후속 — 다른 도구 모드에서 이미 선택된 텍스트박스를 '
                '재드래그하면 실제로 이동해야 한다',
          );
          expect(
            DrawingState().hasSelectedTextBox.value,
            isTrue,
            reason:
                '재드래그 도중/이후에도 선택이 풀리면 안 된다 — 풀리면 손가락 '
                '입력이 다시 필기 레이어에 도달하지 못하는 회귀로 이어진다',
          );
        },
      );
    },
  );
}
