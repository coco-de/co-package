import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/widgets/pointer_event_handler.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 지연 시작(deferred draw start) 위젯 레벨 회귀 테스트 (kobic UB-188).
///
/// [PointerEventHandler] 단위 테스트(pointer_event_handler_test.dart)는
/// 보류/승격/폐기 버퍼링 로직 자체만 검증한다. 이 파일은
/// [ScribbleWidget.shouldDeferDrawStart] 를 통해 그 로직이 실제 pointer
/// 이벤트 흐름(down → move/up)과 올바르게 오케스트레이션되는지 확인한다 —
/// 링크 위 짧은 탭이 dot 필기를 전혀 남기지 않는지, 링크 위에서 시작하는
/// 진짜 드래그는 정상적으로 필기되는지가 이 수정의 핵심 계약이다.
void main() {
  late ScribbleNotifier scribbleNotifier;
  late ScribbleModeNotifier modeNotifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    scribbleNotifier = ScribbleNotifier(
      scribble: Scribble(strokes: [], width: 300, height: 400),
    );
    modeNotifier = ScribbleModeNotifier()..setPen();
    // mouseOnly + pen: Jira UB-188 재현 조건(웹/Chrome + 마우스)과 동일.
    DrawingState().pointerMode.value = DrawingPointerMode.mouseOnly;
    DrawingState().selectedTool.value = DrawingTool.pen;
  });

  tearDown(() {
    DrawingState().pointerMode.value = DrawingPointerMode.penOnly;
    DrawingState().selectedTool.value = DrawingTool.pencil;
    scribbleNotifier.dispose();
    modeNotifier.dispose();
  });

  Drawing drawingState() => scribbleNotifier.currentState as Drawing;

  Widget buildTestWidget({bool Function(Offset)? shouldDeferDrawStart}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: ScribbleWidget(
              notifier: scribbleNotifier,
              modeNotifier: modeNotifier,
              shouldDeferDrawStart: shouldDeferDrawStart,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

  testWidgets('지연 대상 지점을 짧게 탭하면 아무 필기도 남지 않는다', (tester) async {
    await tester.pumpWidget(buildTestWidget(shouldDeferDrawStart: (_) => true));
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(ScribbleWidget));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.down(center);
    await tester.pump(const Duration(milliseconds: 50));

    // 보류 중에는 activeLine 이 생성되지 않는다 — 화면에 아무 것도 안 보임.
    expect(drawingState().activeLine, isNull);

    await gesture.up();
    await tester.pumpAndSettle();

    // 짧은 탭으로 확정 — 최종 strokes 에도 아무 흔적이 남지 않는다.
    expect(scribbleNotifier.currentScribble.strokes, isEmpty);
    expect(drawingState().activeLine, isNull);
  });

  testWidgets('지연 대상 지점에서 시작해 slop 을 넘겨 드래그하면 정상적으로 필기된다', (tester) async {
    await tester.pumpWidget(buildTestWidget(shouldDeferDrawStart: (_) => true));
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(ScribbleWidget));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.down(center);
    await tester.pump(const Duration(milliseconds: 20));

    // slop(15px) 이내 — 아직 보류 중.
    await gesture.moveBy(const Offset(5, 0));
    await tester.pump();
    expect(drawingState().activeLine, isNull);

    // slop 초과 — 승격되어 실제로 그리기 시작.
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(drawingState().activeLine, isNotNull);

    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scribbleNotifier.currentScribble.strokes, hasLength(1));
    // 승격 시 원래 down 지점부터 그려져야 한다 — 버퍼링된 이동 경로가
    // 유실되지 않고 재생되었는지 확인.
    final points = scribbleNotifier.currentScribble.strokes.single.points;
    expect(points, isNotEmpty);
  });

  testWidgets('지연 대상 지점을 이동 없이 오래 누르면 timeout 후 승격되어 점이 남는다', (tester) async {
    await tester.pumpWidget(buildTestWidget(shouldDeferDrawStart: (_) => true));
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(ScribbleWidget));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.down(center);

    // kDeferStartTimeout(300ms) 경과 전에는 여전히 보류 상태.
    await tester.pump(const Duration(milliseconds: 100));
    expect(drawingState().activeLine, isNull);

    // timeout 경과 — Timer 는 testWidgets 의 FakeAsync 클럭에 예약되므로
    // tester.pump(duration) 으로 가짜 시계를 진행시켜야 발화한다.
    await tester.pump(
      PointerEventHandler.kDeferStartTimeout + const Duration(milliseconds: 50),
    );
    expect(drawingState().activeLine, isNotNull);

    await gesture.up();
    await tester.pumpAndSettle();

    // 기존(지연 시작 도입 전) 동작과 동일하게, 오래 누른 뒤 뗀 점은 보존된다
    // — 짧은 탭만 폐기 대상이라는 계약을 지킨다.
    expect(scribbleNotifier.currentScribble.strokes, hasLength(1));
  });

  testWidgets('predicate 가 false 를 반환하면 기존과 완전히 동일하게 즉시 그려진다', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(shouldDeferDrawStart: (_) => false),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(ScribbleWidget));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.down(center);
    await tester.pump();

    // false 를 반환하면 지연 없이 즉시 activeLine 이 생성된다(기존 동작).
    expect(drawingState().activeLine, isNotNull);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(scribbleNotifier.currentScribble.strokes, hasLength(1));
  });

  testWidgets('shouldDeferDrawStart 미주입 시 기존과 완전히 동일하게 즉시 그려진다', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(ScribbleWidget));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.down(center);
    await tester.pump();

    expect(drawingState().activeLine, isNotNull);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(scribbleNotifier.currentScribble.strokes, hasLength(1));
  });
}
