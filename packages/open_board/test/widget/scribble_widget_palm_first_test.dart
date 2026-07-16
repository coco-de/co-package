  import 'package:flutter/gestures.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/scribble.notifier.dart';
  import 'package:open_board/src/module/scribble_mode.notifier.dart';
  import 'package:open_board/src/module/state/drawing_state.dart';
  import 'package:open_board/src/module/state/scribble.state.dart';
  import 'package:open_board/src/module/state/viewer_gesture_bus.dart';
  import 'package:open_board/src/module/widgets/pointer_event_handler.dart';
  import 'package:open_board/src/module/widgets/scribble_widget.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  /// kobic UB-219 2차 — 손모드 팜 리젝션의 위젯 오케스트레이션 회귀 테스트.
  ///
  /// PR #232(1차 팜 리젝션)의 단위 테스트는 [PointerEventHandler]의 마킹/유효
  /// 멀티터치 판정만 검증했고, 아래 시나리오들은 위젯 레벨 오케스트레이션
  /// 공백으로 남아 실기기에서 "가끔 필기가 원활하지 않음"으로 재현됐다:
  ///
  ///   1. 팜이 필기 손가락보다 먼저 닿는 경우 (팜-먼저 스왑)
  ///   2. 팜을 얹은 채 획을 뗐다 다시 시작하는 연속 획 필기
  ///   3. up 유실(isScribbleEnable 토글 등)로 인한 상태 고착 자가치유
  ///   4. uniformPen 도구에서 팜 리젝션 미발동 (도구 집합 누락)
  ///   5. 필기 시작 전 두 손가락 동시 핀치줌 보존 (#232 AC-2 회귀 방지)
  void main() {
    // kTouchDelay(30ms) 지연 콜백 발화용 펌프 시간.
    const touchDelayPump = Duration(milliseconds: 40);
    // _ScribbleWidgetState.kPalmSwapMinStrokeAge(100ms)를 실제 벽시계로
    // 초과시키기 위한 대기 시간 (createdAt 판정은 DateTime.now() 기반이라
    // fake-async pump 로는 흐르지 않는다 — runAsync 로 실제 대기).
    const palmSwapAgeWait = Duration(milliseconds: 180);

    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      modeNotifier = ScribbleModeNotifier()..setPen();
      ViewerGestureBus().reset();
      // 손모드(mouseOnly) + 필기 도구(pen) — 전역 상태가 팜 리젝션 게이트
      // (_isInHandModeWithDrawingTool)와 _canStartDrawing 의 판정 근거다.
      DrawingState().pointerMode.value = DrawingPointerMode.mouseOnly;
      DrawingState().selectedTool.value = DrawingTool.pen;
    });

    tearDown(() {
      ViewerGestureBus().reset();
      DrawingState().pointerMode.value = DrawingPointerMode.penOnly;
      DrawingState().selectedTool.value = DrawingTool.pencil;
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

    Drawing drawingState() => scribbleNotifier.currentState as Drawing;

    testWidgets('should_swap_to_real_finger_when_palm_lands_first', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. 팜이 먼저 착지 → 30ms 지연 후 팜이 잠정 스트로크를 시작해버린다.
      final palm = await tester.createGesture(kind: PointerDeviceKind.touch);
      await palm.down(tester.getCenter(find.byType(ScribbleWidget)) +
          const Offset(0, 120));
      await tester.pump(touchDelayPump);
      expect(drawingState().activeLine, isNotNull);
      final palmOwnerIds = drawingState().activePointerIds;
      expect(palmOwnerIds, hasLength(1));

      // 2. 팜은 정지한 채 최소 스트로크 나이(100ms)를 실제 시간으로 경과.
      await tester.runAsync(() => Future<void>.delayed(palmSwapAgeWait));

      // 3. 진짜 필기 손가락 착지 → 팜 스트로크 폐기 + 손가락으로 스왑.
      final finger = await tester.createGesture(kind: PointerDeviceKind.touch);
      final fingerStart =
          tester.getCenter(find.byType(ScribbleWidget)) - const Offset(50, 80);
      await finger.down(fingerStart);
      await tester.pump();

      final swapped = drawingState();
      expect(swapped.activeLine, isNotNull);
      expect(swapped.activePointerIds, hasLength(1));
      expect(swapped.activePointerIds.first, isNot(palmOwnerIds.first));

      // 4. 손가락으로 획을 긋고 뗀다 → 손가락 획 1개만 커밋된다.
      await finger.moveTo(fingerStart + const Offset(40, 40));
      await tester.pump();
      await finger.up();
      await tester.pump();

      expect(scribbleNotifier.currentState.scribble.strokes, hasLength(1));

      await palm.up();
      await tester.pump();
      // 팜의 잠정 라인은 커밋되지 않았어야 한다.
      expect(scribbleNotifier.currentState.scribble.strokes, hasLength(1));

      // 획 시작 시 DrawingState.setLastActiveScribbleNotifier 가 거는 50ms
      // undo/redo 디바운스 타이머를 소화한다 (pending-timer 불변식).
      await tester.pump(const Duration(milliseconds: 60));
    });

    testWidgets('should_keep_drawing_second_stroke_while_palm_resting', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.byType(ScribbleWidget));

      // 1. 손가락으로 획 1 시작 + 이동 (슬롭 초과 → 스왑 대상 아님).
      final finger = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger.down(center - const Offset(60, 60));
      await tester.pump(touchDelayPump);
      await finger.moveTo(center - const Offset(20, 20));
      await tester.pump();
      expect(drawingState().activeLine, isNotNull);

      // 2. 필기 중 팜 착지 → #232 팜 마킹 (획 유지).
      final palm = await tester.createGesture(kind: PointerDeviceKind.touch);
      await palm.down(center + const Offset(0, 140));
      await tester.pump();

      // 3. 획 1 종료 — 팜은 계속 화면에 얹혀 있다.
      await finger.up();
      await tester.pump();
      expect(scribbleNotifier.currentState.scribble.strokes, hasLength(1));

      // 4. 팜을 얹은 채 획 2 시작 — 수정 전에는 팜이 하드웨어 터치 카운트에
      //    남아 isMultiTouch() 기준 핀치줌 대기로 소비돼 그려지지 않았다.
      final finger2 = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger2.down(center - const Offset(40, 0));
      await tester.pump(touchDelayPump);
      expect(drawingState().activeLine, isNotNull);

      await finger2.moveTo(center + const Offset(10, 30));
      await tester.pump();
      await finger2.up();
      await tester.pump();

      expect(scribbleNotifier.currentState.scribble.strokes, hasLength(2));

      await palm.up();
      await tester.pump();
    });

    testWidgets('should_self_heal_after_pointer_up_lost_by_scribble_toggle', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.byType(ScribbleWidget));

      // 1. 손모드 필기 시작 (손모드 플래그 + notifier 소유권 활성).
      final finger = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger.down(center);
      await tester.pump(touchDelayPump);
      expect(drawingState().activePointerIds, isNotEmpty);

      // 2. 필기 도중 isScribbleEnable 토글 → 이어지는 up 이 위젯/notifier 에
      //    전달되지 않아(1966 조기 반환) 소유권·손모드 플래그·드래그 플래그가
      //    전부 stale 로 잔존하는 실제 유실 경로.
      await tester.pumpWidget(buildTestWidget(isScribbleEnable: false));
      await tester.pump();
      await finger.up();
      await tester.pump();
      expect(drawingState().activePointerIds, isNotEmpty, reason: 'up 유실 전제');

      // 3. 필기 재활성 후 새 손가락 down → 자가치유가 stale 상태를 정리하고
      //    정상적으로 새 획이 시작·커밋되어야 한다. 수정 전에는 stale
      //    activePointerIds 가 지연 시작 게이트를 영구 차단해 필기가 죽었다.
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final finger2 = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger2.down(center - const Offset(30, 30));
      await tester.pump(touchDelayPump);
      expect(drawingState().activeLine, isNotNull);

      await finger2.moveTo(center + const Offset(20, 20));
      await tester.pump();
      await finger2.up();
      await tester.pump();

      expect(
        scribbleNotifier.currentState.scribble.strokes.length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('should_apply_palm_rejection_with_uniform_pen', (tester) async {
      // uniformPen 은 #232 당시 손모드 필기 도구 집합에서 누락돼 팜 리젝션이
      // 아예 발동하지 않던 도구다 (도구 집합 누락 수정 회귀 방지).
      DrawingState().selectedTool.value = DrawingTool.uniformPen;
      modeNotifier.setUniformPen();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.byType(ScribbleWidget));

      // 1. 균일펜으로 획 시작 + 이동.
      final finger = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger.down(center - const Offset(60, 60));
      await tester.pump(touchDelayPump);
      await finger.moveTo(center - const Offset(20, 20));
      await tester.pump();

      // 2. 필기 중 팜 착지 — 수정 전에는 손모드 플래그가 세팅되지 않아 팜이
      //    유효 멀티터치로 집계되고 move 가 조기 반환돼 획이 끊겼다.
      final palm = await tester.createGesture(kind: PointerDeviceKind.touch);
      await palm.down(center + const Offset(0, 140));
      await tester.pump();

      // 3. 팜이 얹힌 채 획을 계속 긋고 뗀다 → 하나의 획으로 커밋.
      await finger.moveTo(center + const Offset(20, 20));
      await tester.pump();
      await finger.up();
      await tester.pump();

      expect(scribbleNotifier.currentState.scribble.strokes, hasLength(1));
      final stroke = scribbleNotifier.currentState.scribble.strokes.first;
      expect(stroke.points.length, greaterThan(1), reason: '획이 끊기지 않고 이어짐');

      await palm.up();
      await tester.pump();

      // 획 시작 시 DrawingState.setLastActiveScribbleNotifier 가 거는 50ms
      // undo/redo 디바운스 타이머를 소화한다 (pending-timer 불변식).
      await tester.pump(const Duration(milliseconds: 60));
    });

    testWidgets('should_preserve_two_finger_pinch_before_drawing', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.byType(ScribbleWidget));

      // 필기 시작 전 두 손가락이 kTouchDelay(30ms) 안에 동시에 닿으면
      // 기존과 동일하게 핀치줌/팬 의도로 인정 — 어느 쪽도 획을 시작하지
      // 않아야 한다 (#232 AC-2 유지, 팜-먼저 스왑 미발동 확인).
      final finger1 = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger1.down(center - const Offset(40, 0));
      final finger2 = await tester.createGesture(kind: PointerDeviceKind.touch);
      await finger2.down(center + const Offset(40, 0));
      await tester.pump(touchDelayPump);

      expect(drawingState().activeLine, isNull);
      expect(scribbleNotifier.currentState.scribble.strokes, isEmpty);

      await finger1.up();
      await finger2.up();
      await tester.pump();
    });
  }
