import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/text_interaction_manager.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

/// 이슈 #100 회귀 방지 단위 테스트.
///
/// 검증 대상:
///  1. 오버레이 표시 상태에서 외부 터치 → deselect만 수행, 새 텍스트 생성 차단
///  2. 단일탭으로 텍스트 선택 시 `isTextDragPreparing`이 즉시 활성화되지 않음
///     (→ InteractiveViewer 핀치 줌이 차단되지 않음)
///  3. `onTextMoveStart`/`Update`/`End` 흐름이 원본 위치 기준 delta로
///     누적 점프 없이 텍스트를 이동시킴
void main() {
  group('TextInteractionManager (#100 regression guard)', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;
    late ScribbleWidgetState widgetState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(scribble: createScribble());
      modeNotifier = ScribbleModeNotifier();
      widgetState = ScribbleWidgetState();
    });

    tearDown(() {
      scribbleNotifier.dispose();
      modeNotifier.dispose();
      widgetState.dispose();
    });

    /// `TextInteractionManager`를 빌드 컨텍스트와 함께 생성한다.
    Future<TextInteractionManager> buildManager(
      WidgetTester tester, {
      required void Function(TextDrawable) onTextSelected,
      required void Function() onTextDeselected,
    }) async {
      late TextInteractionManager manager;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                manager = TextInteractionManager(
                  scribbleNotifier: scribbleNotifier,
                  modeNotifier: modeNotifier,
                  onStateChanged: () {},
                  context: context,
                  transformationController: null,
                  repaintBoundaryKey: null,
                  onTextSelected: onTextSelected,
                  onTextEdit: (_) {},
                  onTextUpdated: (_) {},
                  onTextDeselected: onTextDeselected,
                  widgetState: widgetState,
                );
                return const SizedBox(width: 400, height: 600);
              },
            ),
          ),
        ),
      );

      return manager;
    }

    /// `localPosition`만 의미가 있는 가상의 PointerDownEvent.
    PointerDownEvent makePointerDown(Offset position) {
      return PointerDownEvent(position: position);
    }

    testWidgets(
      '단일탭으로 텍스트를 선택해도 `isTextDragPreparing`이 즉시 true가 되지 않는다',
      (tester) async {
        // Given: 화면에 텍스트 1개가 존재하고 매니저가 준비됨
        final text = createTextDrawable(
          id: 't1',
          text: 'Hello',
          x: 100,
          y: 100,
        );
        scribbleNotifier.addTextDrawable(text);

        var selectedText = false;
        final manager = await buildManager(
          tester,
          onTextSelected: (_) => selectedText = true,
          onTextDeselected: () {},
        );

        // When: 텍스트 영역 내부를 단일탭 (선택 발생)
        final handled = manager.handlePointerDown(
          makePointerDown(const Offset(100, 100)),
        );

        // Then: 선택 콜백이 호출되고 오버레이가 표시되지만,
        //       드래그 준비 상태(isTextDragPreparing)는 false여야 한다.
        //       → InteractiveViewer 핀치 줌이 차단되지 않음.
        expect(handled, isTrue);
        expect(selectedText, isTrue);
        expect(manager.showTextOverlay, isTrue);
        expect(
          manager.isTextDragPreparing,
          isFalse,
          reason: 'PointerDown 즉시 _prepareDrag를 호출하지 않아 핀치 줌이 차단되지 않는다',
        );
        expect(
          manager.isAnyTextInteracting,
          isFalse,
          reason: '단일탭 선택만으로는 텍스트 상호작용 상태가 활성화되지 않는다',
        );
      },
      // SKIP — open-board#177: b0f63dd 가 단일탭 _prepareDrag 를 의도적으로 재도입.
      // #100 핀치 줌 정책의 제품 의도 결정 대기 (멀티터치 단락으로 보장되는지 검토).
      skip: true,
    );

    testWidgets('오버레이가 표시된 상태에서 외부 영역을 터치하면 deselect만 수행하고 새 텍스트를 만들지 않는다', (
      tester,
    ) async {
      // Given: 텍스트 1개가 선택된 상태 (showTextOverlay=true)
      final text = createTextDrawable(id: 't1', text: 'Hello', x: 100, y: 100);
      scribbleNotifier.addTextDrawable(text);

      var deselectCalled = false;
      TextDrawable? selectedTextDrawable;
      final manager = await buildManager(
        tester,
        onTextSelected: (t) => selectedTextDrawable = t,
        onTextDeselected: () {
          deselectCalled = true;
          selectedTextDrawable = null;
        },
      );

      // 텍스트 선택을 위해 내부 탭
      manager.handlePointerDown(makePointerDown(const Offset(100, 100)));
      expect(manager.showTextOverlay, isTrue);
      expect(selectedTextDrawable, isNotNull);

      // 텍스트 개수 측정 (외부 터치 후에도 동일해야 함)
      final beforeTextCount = scribbleNotifier.getCurrentTextDrawables().length;

      // When: 텍스트 바운딩 박스 외부를 탭
      final handled = manager.handlePointerDown(
        makePointerDown(const Offset(350, 500)),
      );

      // Then: deselect가 일어나고, 새 텍스트는 생성되지 않는다.
      expect(handled, isTrue, reason: '이벤트가 소비되어 fall-through 차단');
      expect(deselectCalled, isTrue);
      expect(manager.showTextOverlay, isFalse);
      expect(selectedTextDrawable, isNull);
      expect(
        scribbleNotifier.getCurrentTextDrawables().length,
        beforeTextCount,
        reason: '외부 터치만으로는 새 텍스트가 추가되지 않아야 한다',
      );
    });

    testWidgets(
      'onTextMoveStart 후 onTextMoveUpdate는 원본 위치 + delta로 누적 점프 없이 이동한다',
      (tester) async {
        // Given: 텍스트 1개 추가 + 단일탭으로 선택
        final text = createTextDrawable(id: 't1', text: 'Move', x: 100, y: 100);
        scribbleNotifier.addTextDrawable(text);

        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        manager.handlePointerDown(makePointerDown(const Offset(100, 100)));
        expect(manager.showTextOverlay, isTrue);

        // When: GestureDetector가 pan을 인식한 시점에 onTextMoveStart 호출
        manager.onTextMoveStart(
          DragStartDetails(
            globalPosition: const Offset(120, 110),
            localPosition: const Offset(120, 110),
          ),
        );

        // 첫 번째 update — start로부터 (10, 5) 이동
        manager.onTextMoveUpdate(
          DragUpdateDetails(
            globalPosition: const Offset(130, 115),
            localPosition: const Offset(130, 115),
          ),
        );

        var current = scribbleNotifier.getCurrentTextDrawables().firstWhere(
          (t) => t.id == 't1',
        );
        expect(
          current.position,
          closeTo2D(110, 105),
          reason: '원본(100,100) + delta(10,5) = (110,105)',
        );

        // 두 번째 update — start로부터 (40, 30) 이동
        // 누적 방식이면 첫 번째 후 위치(110,105)에서 추가 이동되어 잘못된 결과가 나옴.
        // 원본 기준이면 (100,100) + (40,30) = (140,130)이어야 함.
        manager.onTextMoveUpdate(
          DragUpdateDetails(
            globalPosition: const Offset(160, 140),
            localPosition: const Offset(160, 140),
          ),
        );

        final expectedFinalPositionMatcher = closeTo2D(140, 130);
        current = scribbleNotifier.getCurrentTextDrawables().firstWhere(
          (t) => t.id == 't1',
        );
        expect(
          current.position,
          expectedFinalPositionMatcher,
          reason: '원본(100,100) + delta(40,30) = (140,130) — 누적되면 안 됨',
        );

        // When: drag 종료
        manager.onTextMoveEnd(DragEndDetails());

        // Then: 드래그 상태가 정리됨
        expect(
          manager.isDraggingText,
          isFalse,
          reason: 'onTextMoveEnd 후 드래그 상태가 정리되어야 한다',
        );
        expect(
          manager.isAnyTextInteracting,
          isFalse,
          reason: 'drag 종료 후 모든 상호작용 상태가 해제되어야 한다',
        );

        // 최종 위치는 마지막 update 결과 유지
        final finalText = scribbleNotifier.getCurrentTextDrawables().firstWhere(
          (t) => t.id == 't1',
        );
        expect(finalText.position, expectedFinalPositionMatcher);
      },
      // SKIP — open-board#177: b0f63dd 가 드래그 경로를 onTextMoveStart/Update →
      // raw pointer(handlePointerMove)로 이전. #100 origin+delta 가드 재작성 결정 대기.
      skip: true,
    );

    testWidgets('onTextMoveUpdate는 _selectedTextIndex가 없으면 안전하게 무시된다', (
      tester,
    ) async {
      // Given: 텍스트 미선택 상태
      final manager = await buildManager(
        tester,
        onTextSelected: (_) {},
        onTextDeselected: () {},
      );

      // When: 선택 없이 onTextMoveStart/Update를 호출
      manager.onTextMoveStart(
        DragStartDetails(globalPosition: .zero, localPosition: .zero),
      );
      manager.onTextMoveUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(50, 50),
          localPosition: const Offset(50, 50),
        ),
      );

      // Then: 어떤 텍스트도 변경되지 않고 예외가 발생하지 않는다.
      expect(manager.isDraggingText, isFalse);
      expect(scribbleNotifier.getCurrentTextDrawables(), isEmpty);
    });

    testWidgets(
      'kobic UB-595 — 시각 버튼(35px) 밖이지만 selection_overlay 히트 영역(49px) 안쪽인 '
      '좌하단 변형 핸들을 드래그해도 텍스트박스가 이동하지 않는다',
      (tester) async {
        // Given: 충분히 큰 텍스트 1개를 추가하고 단일탭으로 선택한다
        //        (오버레이 표시 → _selectedTextIndex 세팅).
        //        ⚠️ 이 첫 탭 자체가 이미 _prepareDrag를 호출해
        //        isTextDragPreparing을 true로 만든다(open-board#177,
        //        #100 정책과 무관한 현재 동작) — 그래서 이 테스트는 그
        //        내부 플래그가 아니라 "텍스트가 실제로 움직였는가"라는
        //        관측 가능한 증상을 직접 단언한다.
        final text = createTextDrawable(
          id: 't1',
          text: 'Hello World Testing',
          x: 200,
          y: 200,
          fontSize: 24,
        );
        scribbleNotifier.addTextDrawable(text);

        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        manager.handlePointerDown(makePointerDown(const Offset(200, 200)));
        expect(manager.showTextOverlay, isTrue);

        final originalPosition = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1')
            .position;

        // 변형 핸들(좌하단) 코너 좌표를 프로덕션 코드와 동일한 공식으로 계산한다
        // (TextInteractionManager._getRotatedButtonPositions /
        //  TextDrawablePainter 와 동일: 텍스트 박스 + 4px 패딩의 좌하단).
        final textPainter = TextPainter(
          text: TextSpan(text: text.text, style: text.style),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        )..layout();
        final center = text.position;
        final halfWidth = textPainter.width / 2;
        final halfHeight = textPainter.height / 2;
        final corner = Offset(
          center.dx - halfWidth - 4,
          center.dy + halfHeight + 4,
        );

        // 옛 raw 판정 반경(35px 버튼 → 17.5px)보다는 멀지만 새 반경
        // (selectionHandleTouchSize=49px → 24.5px, selection_overlay의 실제
        // GestureDetector 히트 영역) 이내인 지점 — 대각선(박스 내부 방향)으로
        // 22px 이동한 "불일치 링" 위의 터치를 재현한다.
        const ringDistance = 22.0;
        const diagonal = ringDistance * 0.70710678; // cos(45°) == sin(45°)
        final ringTouch = corner + const Offset(diagonal, -diagonal);

        // sanity check: 이 터치가 실제로 "불일치 링" 안에 있는지 확인한다
        // (텍스트가 너무 작아 링이 박스 밖으로 새면 이 테스트 자체가 무의미해진다).
        expect(
          (ringTouch - corner).distance,
          closeTo(ringDistance, 0.01),
          reason: '테스트 좌표 계산 자체가 코너로부터 22px 떨어져 있어야 한다',
        );

        // When: 변형 핸들의 "불일치 링" 위를 터치하고, 텍스트 드래그
        //       임계값(15px)을 넘겨 이동시키려 한다 — 실제 사용자가
        //       핸들을 잡고 확대하려는 제스처와 동일.
        manager.handlePointerDown(makePointerDown(ringTouch));
        manager.handlePointerMove(
          PointerMoveEvent(position: ringTouch + const Offset(20, 20)),
        );

        // Then: 변형 모드로 처리되어 텍스트박스는 절대 이동하지 않아야 한다
        //       (kobic UB-595 — "확대 대신 이동"이 바로 이 지점의 회귀다).
        final afterPosition = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1')
            .position;
        expect(
          afterPosition,
          equals(originalPosition),
          reason:
              'kobic UB-595 — 변형 핸들 드래그가 텍스트박스를 이동시키면 안 '
              '된다 (raw pointer 경로가 이 터치를 컨트롤 영역으로 인식하지 '
              '못하면 텍스트 드래그로 새어나가 이 위치가 바뀐다)',
        );
        expect(
          manager.isAnyTextInteracting,
          isTrue,
          reason: '변형(크기조절/회전) 상태(_isTextResizing)로 진입해야 한다',
        );
      },
    );

    testWidgets(
      'kobic UB-595 (2차) — 위젯 GestureDetector(onTextTransformStart/Update)를 '
      '한 번도 거치지 않아도(스타일러스에서 실측된 상황) 변형 핸들 드래그가 실제로 '
      '확대 계산을 완결한다',
      (tester) async {
        // Given: 이 테스트는 raw pointer 경로(handlePointerDown/Move)만
        //        호출하고 selection_overlay의 onPanStart/Update(위젯
        //        GestureDetector 경로)는 절대 부르지 않는다 — 스타일러스
        //        입력에서 위젯 아레나가 그 recognizer에 한 번도 넘어가지
        //        않는 실측 상황과 동일한 호출 순서다.
        final text = createTextDrawable(
          id: 't1',
          text: 'Hello World Testing',
          x: 200,
          y: 200,
          fontSize: 24,
        );
        scribbleNotifier.addTextDrawable(text);

        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        manager.handlePointerDown(makePointerDown(const Offset(200, 200)));
        expect(manager.showTextOverlay, isTrue);

        final originalFontSize = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1')
            .fontSize;

        // 변형 핸들(좌하단) 코너 좌표 — 위 UB-595(1차) 테스트와 동일한
        // 공식(프로덕션의 _getTransformHandleCanvasPosition과 일치).
        final textPainter = TextPainter(
          text: TextSpan(text: text.text, style: text.style),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        )..layout();
        final center = text.position;
        final halfWidth = textPainter.width / 2;
        final halfHeight = textPainter.height / 2;
        final corner = Offset(
          center.dx - halfWidth - 4,
          center.dy + halfHeight + 4,
        );

        // When: 변형 핸들을 누르고(raw pointer 경로가 _beginResizeRotate를
        //       직접 호출), 중심에서 더 멀어지는 방향(코너가 중심에서 뻗은
        //       방향 그대로 연장)으로 드래그한다. onTextTransformStart/Update
        //       는 이 테스트 전체에서 한 번도 호출되지 않는다.
        manager.handlePointerDown(makePointerDown(corner));
        manager.handlePointerMove(
          PointerMoveEvent(position: corner + const Offset(-20, 20)),
        );

        // Then: raw pointer 경로 스스로 확대 계산을 완결해 폰트 크기가
        //       커져야 한다 — 이 2차 수정 이전에는 handlePointerMove의
        //       _isTextResizing 분기가 `return true`만 하는 no-op이어서,
        //       위젯 GestureDetector가 아레나를 이기지 못하면(스타일러스)
        //       폰트 크기가 전혀 바뀌지 않았다(kobic UB-595 2차 — "핸들을
        //       눌러도 회전/확대축소가 완전히 무반응").
        final afterFontSize = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1')
            .fontSize;
        expect(
          afterFontSize,
          greaterThan(originalFontSize),
          reason:
              'kobic UB-595 (2차) — 위젯 GestureDetector의 onPanUpdate 없이 '
              'raw pointer 경로만으로도 변형 핸들 드래그의 확대 계산이 '
              '실제로 반영되어야 한다',
        );
      },
    );

    group('UB-273 — 새 텍스트 생성 탭 확정/장치 정책 회귀 가드', () {
      /// DrawingState(전역 싱글턴)의 pointerMode를 변경하고, 변경 리스너가
      /// 스케줄하는 영속화 디바운스(50ms Future.delayed)를 flush한다.
      /// flush하지 않으면 테스트 종료 시 pending Timer로 실패한다.
      Future<void> setPointerMode(
        WidgetTester tester,
        DrawingPointerMode mode,
      ) async {
        DrawingState().pointerMode.value = mode;
        await tester.pump(const Duration(milliseconds: 60));
      }

      /// `localPosition`만 의미가 있는 가상의 PointerMoveEvent.
      PointerMoveEvent makePointerMove(Offset position) {
        return PointerMoveEvent(position: position);
      }

      /// `localPosition`만 의미가 있는 가상의 PointerUpEvent.
      PointerUpEvent makePointerUp(Offset position) {
        return PointerUpEvent(position: position);
      }

      testWidgets('펜모드의 손가락 down은 새 텍스트를 만들지 않는다 (페이지 탐색 담당 장치)', (
        tester,
      ) async {
        // Given: 펜모드 (스타일러스만 그리기/생성 가능)
        await setPointerMode(tester, DrawingPointerMode.penOnly);
        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        // When: 손가락(touch)으로 빈 영역 down → up (탭)
        final handled = manager.handlePointerDown(
          makePointerDown(const Offset(200, 300)),
        );
        manager.handlePointerUp(makePointerUp(const Offset(200, 300)));
        await tester.pump();

        // Then: 에디터가 열리지 않고 이벤트도 소비되지 않는다
        //       (kobic 쪽 페이지 스와이프/엣지 탭이 온전히 동작).
        expect(handled, isFalse, reason: '펜모드의 손가락은 페이지 탐색 담당 — 텍스트 생성 대상 아님');
        expect(
          widgetState.isEditingText,
          isFalse,
          reason: '인라인 에디터(키보드)가 열리면 안 된다 (UB-273 깜빡임 원인)',
        );
        expect(scribbleNotifier.getCurrentTextDrawables(), isEmpty);
      });

      testWidgets('손모드의 손가락 탭은 down이 아닌 up 시점에 에디터를 연다', (tester) async {
        // Given: 손모드 (손가락/마우스로 그리기/생성 가능)
        await setPointerMode(tester, DrawingPointerMode.mouseOnly);
        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        // When: 빈 영역 down
        final handled = manager.handlePointerDown(
          makePointerDown(const Offset(200, 300)),
        );

        // Then: down 시점에는 아직 생성 보류 (스와이프일 수 있음)
        expect(handled, isTrue, reason: '탭 후보로 이벤트 접수');
        expect(
          widgetState.isEditingText,
          isFalse,
          reason: 'down 즉시 에디터를 열면 스와이프 시작점마다 키보드가 깜빡인다',
        );

        // When: 슬롭 이내 이동 후 up (진짜 탭)
        manager.handlePointerUp(makePointerUp(const Offset(203, 302)));
        await tester.pump();

        // Then: up 시점에 에디터가 열린다
        expect(
          widgetState.isEditingText,
          isTrue,
          reason: '슬롭 이내 탭으로 확정되면 인라인 에디터가 열려야 한다',
        );

        // Cleanup: 에디터 오버레이 정리 + 잔여 타이머(포커스 상실 지연 완료) flush
        manager.dispose();
        await tester.pump(const Duration(milliseconds: 200));
        await setPointerMode(tester, DrawingPointerMode.penOnly); // 기본값 복원
      });

      testWidgets('슬롭을 넘는 이동(페이지 스와이프)은 새 텍스트 생성을 취소한다', (tester) async {
        // Given: 손모드
        await setPointerMode(tester, DrawingPointerMode.mouseOnly);
        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        // When: down → 수평 120px 이동(스와이프) → up
        manager.handlePointerDown(makePointerDown(const Offset(200, 300)));
        manager.handlePointerMove(makePointerMove(const Offset(320, 300)));
        manager.handlePointerUp(makePointerUp(const Offset(340, 300)));
        await tester.pump();

        // Then: 에디터가 열리지 않는다 (UB-273 핵심 시나리오)
        expect(
          widgetState.isEditingText,
          isFalse,
          reason: '스와이프는 텍스트 생성 탭이 아니다 — 키보드 깜빡임 방지',
        );
        expect(scribbleNotifier.getCurrentTextDrawables(), isEmpty);

        await setPointerMode(tester, DrawingPointerMode.penOnly); // 기본값 복원
      });

      testWidgets('펜모드의 스타일러스 탭은 up 시점에 에디터를 연다', (tester) async {
        // Given: 펜모드
        await setPointerMode(tester, DrawingPointerMode.penOnly);
        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        // When: 스타일러스로 빈 영역 down → up (탭)
        manager.handlePointerDown(
          const PointerDownEvent(
            kind: PointerDeviceKind.stylus,
            position: Offset(200, 300),
          ),
        );
        expect(
          widgetState.isEditingText,
          isFalse,
          reason: 'down 시점에는 아직 생성 보류',
        );

        manager.handlePointerUp(
          const PointerUpEvent(
            kind: PointerDeviceKind.stylus,
            position: Offset(200, 300),
          ),
        );
        await tester.pump();

        // Then: 그리기 장치(스타일러스) 탭은 정상적으로 에디터를 연다
        expect(
          widgetState.isEditingText,
          isTrue,
          reason: '펜모드에서 스타일러스 탭의 텍스트 생성은 유지되어야 한다',
        );

        // Cleanup: 에디터 오버레이 정리 + 잔여 타이머(포커스 상실 지연 완료) flush
        manager.dispose();
        await tester.pump(const Duration(milliseconds: 200));
      });
    });
  });

  group('kobic UB-626 / #12409 — Overlay 조상 스케일 변환 회귀 가드', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;
    late ScribbleWidgetState widgetState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(scribble: createScribble());
      modeNotifier = ScribbleModeNotifier();
      widgetState = ScribbleWidgetState();
      DrawingState().pointerMode.value = DrawingPointerMode.mouseOnly;
    });

    tearDown(() {
      scribbleNotifier.dispose();
      modeNotifier.dispose();
      widgetState.dispose();
    });

    /// `ResponsiveScaledBox`(kobic `app/unibook/lib/app/app.dart`)가 태블릿
    /// 폭 구간 기기에서 실제로 만드는 상황을 최소 재현한다 — Overlay 가
    /// `Transform.scale` 조상 **안쪽**에 있는 트리. 실기기(SM-X610, 세로)
    /// 실측 배율은 752.9/800 ≈ 0.9411 이었다.
    ///
    /// [Transform.scale] 의 alignment 를 topLeft 로 고정해 RepaintBoundary 의
    /// origin 이 Overlay 의 origin 과 정확히 일치하게 한다 — 그래야 기대값이
    /// `localPosition` 그대로인지를 오프셋 계산 없이 바로 단언할 수 있다.
    const scale = 0.9411;

    Future<TextInteractionManager> buildScaledManager(
      WidgetTester tester,
      GlobalKey repaintBoundaryKey,
    ) async {
      late TextInteractionManager manager;

      await tester.pumpWidget(
        MaterialApp(
          home: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) {
                    manager = TextInteractionManager(
                      scribbleNotifier: scribbleNotifier,
                      modeNotifier: modeNotifier,
                      onStateChanged: () {},
                      context: context,
                      transformationController: null,
                      repaintBoundaryKey: repaintBoundaryKey,
                      onTextSelected: (_) {},
                      onTextEdit: (_) {},
                      onTextUpdated: (_) {},
                      onTextDeselected: () {},
                      widgetState: widgetState,
                    );
                    return RepaintBoundary(
                      key: repaintBoundaryKey,
                      child: const SizedBox(width: 400, height: 600),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      return manager;
    }

    testWidgets('Overlay 가 조상 스케일 변환 안쪽에 있어도 새 텍스트 편집기가 탭 지점에 정확히 나타난다', (
      tester,
    ) async {
      final repaintBoundaryKey = GlobalKey();
      final manager = await buildScaledManager(tester, repaintBoundaryKey);

      // 탭 지점 — RepaintBoundary 로컬 좌표계(=Overlay 로컬 좌표계, origin 일치) 기준.
      const tapPosition = Offset(100, 150);

      manager.handlePointerDown(PointerDownEvent(position: tapPosition));
      manager.handlePointerUp(PointerUpEvent(position: tapPosition));
      await tester.pump();

      final editor = tester.widget<InlineTextEditor>(
        find.byType(InlineTextEditor),
      );

      // ✅ 고쳐진 동작: ancestor 를 Overlay 로 지정했으므로, Overlay 와
      // RepaintBoundary 가 같은 좌표계를 공유하는 이 트리에서는
      // editorPosition == tapPosition 이 정확히 성립해야 한다.
      expect(editor.position, tapPosition);

      // ⛔ 되돌림 감지: ancestor 를 다시 빼면(=루트 기준 절대좌표) 그 값은
      // tapPosition * scale 이 된다 — 회귀 시 이 값과 우연히 같아지지
      // 않도록 스케일이 1.0 이 아님을 별도로 확인한다(픽스처 동치 방지).
      expect(scale, isNot(1.0));
      expect(editor.position, isNot(tapPosition * scale));

      manager.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Overlay 가 조상 스케일 변환 안쪽에 있어도 기존 텍스트 편집기가 원래 위치에 정확히 나타난다', (
      tester,
    ) async {
      final repaintBoundaryKey = GlobalKey();

      // 기존 텍스트 하나를 미리 배치한다(캔버스 로컬 좌표 기준).
      const existingTextPosition = Offset(120, 80);
      scribbleNotifier.addTextDrawable(
        TextDrawable(
          id: 'existing',
          text: '기존 텍스트',
          x: existingTextPosition.dx,
          y: existingTextPosition.dy,
          fontSize: 20,
          color: 0xFF000000,
        ),
      );

      final manager = await buildScaledManager(tester, repaintBoundaryKey);

      // 기존 텍스트는 더블탭으로만 편집기가 열린다(_handleExistingTextTap).
      // 텍스트의 `.position` 자체는 정렬(.left)과 무관하게 항상 렌더 영역의
      // 수직 중심이므로(_isPointInTextBounds), 폭/높이 실측 없이도 항상
      // 히트된다.
      manager.handlePointerDown(
        PointerDownEvent(position: existingTextPosition),
      );
      manager.handlePointerUp(PointerUpEvent(position: existingTextPosition));
      manager.handlePointerDown(
        PointerDownEvent(position: existingTextPosition),
      );
      manager.handlePointerUp(PointerUpEvent(position: existingTextPosition));
      await tester.pump();

      final editor = tester.widget<InlineTextEditor>(
        find.byType(InlineTextEditor),
      );

      expect(editor.position, existingTextPosition);
      expect(editor.position, isNot(existingTextPosition * scale));

      manager.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
