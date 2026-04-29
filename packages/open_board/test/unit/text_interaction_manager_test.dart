import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
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
      scribbleNotifier = ScribbleNotifier(
        scribble: createScribble(),
      );
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
    );

    testWidgets(
      '오버레이가 표시된 상태에서 외부 영역을 터치하면 deselect만 수행하고 새 텍스트를 만들지 않는다',
      (tester) async {
        // Given: 텍스트 1개가 선택된 상태 (showTextOverlay=true)
        final text = createTextDrawable(
          id: 't1',
          text: 'Hello',
          x: 100,
          y: 100,
        );
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
        final beforeTextCount = scribbleNotifier
            .getCurrentTextDrawables()
            .length;

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
      },
    );

    testWidgets(
      'onTextMoveStart 후 onTextMoveUpdate는 원본 위치 + delta로 누적 점프 없이 이동한다',
      (tester) async {
        // Given: 텍스트 1개 추가 + 단일탭으로 선택
        final text = createTextDrawable(
          id: 't1',
          text: 'Move',
          x: 100,
          y: 100,
        );
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

        var current = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1');
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
        current = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1');
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
        final finalText = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1');
        expect(finalText.position, expectedFinalPositionMatcher);
      },
    );

    testWidgets(
      'onTextMoveUpdate는 _selectedTextIndex가 없으면 안전하게 무시된다',
      (tester) async {
        // Given: 텍스트 미선택 상태
        final manager = await buildManager(
          tester,
          onTextSelected: (_) {},
          onTextDeselected: () {},
        );

        // When: 선택 없이 onTextMoveStart/Update를 호출
        manager.onTextMoveStart(
          DragStartDetails(
            globalPosition: .zero,
            localPosition: .zero,
          ),
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
      },
    );
  });
}
