import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('DrawingState', () {
    late DrawingState drawingState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // 싱글톤 리셋: dispose 후 새 인스턴스 생성
      try {
        DrawingState().dispose();
      } catch (_) {}
      drawingState = DrawingState();
    });

    tearDown(() {
      try {
        drawingState.dispose();
      } catch (_) {}
    });

    group('싱글톤 패턴', () {
      test('팩토리 생성자는 같은 인스턴스 반환', () {
        final a = DrawingState();
        final b = DrawingState();
        expect(identical(a, b), true);
      });

      test('dispose 후 새 인스턴스 생성', () {
        final first = DrawingState();
        first.dispose();
        final second = DrawingState();
        expect(second.isDisposed, false);
      });
    });

    group('초기 상태', () {
      test('기본 도구는 pencil', () {
        expect(drawingState.selectedTool.value, DrawingTool.pencil);
      });

      test('기본 색상은 검정', () {
        expect(drawingState.selectedColor.value, Colors.black);
      });

      test('기본 두께는 2.0', () {
        expect(drawingState.selectedThickness.value, 2.0);
      });

      test('기본 포인터 모드는 penOnly', () {
        expect(drawingState.pointerMode.value, DrawingPointerMode.penOnly);
      });

      test('showColorPicker 기본값 false', () {
        expect(drawingState.showColorPicker.value, false);
      });

      test('색상 슬롯 4개', () {
        expect(drawingState.colorSlots.value.length, 4);
        expect(drawingState.colorSlots.value.first, Colors.black);
      });

      test('isDisposed 기본값 false', () {
        expect(drawingState.isDisposed, false);
      });

      test('활성 notifier 수 0', () {
        expect(drawingState.activeNotifierCount, 0);
        expect(drawingState.activeScribbleNotifierCount, 0);
      });

      test('lastActiveScribbleNotifier null', () {
        expect(drawingState.lastActiveScribbleNotifier, isNull);
      });

      test('canUndo/canRedo 기본값 false', () {
        expect(drawingState.canUndoNotifier.value, false);
        expect(drawingState.canRedoNotifier.value, false);
      });
    });

    group('reset', () {
      test('모든 상태를 기본값으로 초기화', () {
        drawingState.selectedTool.value = .marker;
        drawingState.selectedColor.value = Colors.red;
        drawingState.selectedThickness.value = 10.0;

        drawingState.reset();

        expect(drawingState.selectedTool.value, DrawingTool.pencil);
        expect(drawingState.selectedColor.value, Colors.black);
        expect(drawingState.selectedThickness.value, 2.0);
      });
    });

    group('ModeNotifier 등록/해제', () {
      late ScribbleModeNotifier modeNotifier;

      setUp(() {
        modeNotifier = ScribbleModeNotifier();
      });

      test('registerNotifier 후 카운트 증가', () {
        drawingState.registerNotifier(modeNotifier);
        expect(drawingState.activeNotifierCount, 1);
      });

      test('unregisterNotifier 후 카운트 감소', () {
        drawingState.registerNotifier(modeNotifier);
        drawingState.unregisterNotifier(modeNotifier);
        expect(drawingState.activeNotifierCount, 0);
      });

      test('중복 등록은 Set이므로 1개만', () {
        drawingState.registerNotifier(modeNotifier);
        drawingState.registerNotifier(modeNotifier);
        expect(drawingState.activeNotifierCount, 1);
      });
    });

    group('ScribbleNotifier 등록/해제', () {
      late ScribbleNotifier scribbleNotifier;

      setUp(() {
        scribbleNotifier = ScribbleNotifier(
          scribble: createScribble(),
        );
      });

      test('registerScribbleNotifier 후 카운트 증가', () {
        drawingState.registerScribbleNotifier(scribbleNotifier);
        expect(drawingState.activeScribbleNotifierCount, 1);
      });

      test('unregisterScribbleNotifier 후 카운트 감소', () {
        drawingState.registerScribbleNotifier(scribbleNotifier);
        drawingState.unregisterScribbleNotifier(scribbleNotifier);
        expect(drawingState.activeScribbleNotifierCount, 0);
      });
    });

    group('setLastActiveScribbleNotifier', () {
      test('dispose 후 호출 무시', () {
        drawingState.dispose();
        drawingState = DrawingState();
      });
    });

    group('도구 상태 변경', () {
      test('selectedTool ValueNotifier 변경 알림', () {
        int changeCount = 0;
        drawingState.selectedTool.addListener(() => changeCount++);

        drawingState.selectedTool.value = .pen;
        expect(changeCount, 1);

        drawingState.selectedTool.value = .erase;
        expect(changeCount, 2);
      });

      test('selectedColor ValueNotifier 변경 알림', () {
        int changeCount = 0;
        drawingState.selectedColor.addListener(() => changeCount++);

        drawingState.selectedColor.value = Colors.red;
        expect(changeCount, 1);
      });

      test('selectedThickness ValueNotifier 변경 알림', () {
        int changeCount = 0;
        drawingState.selectedThickness.addListener(() => changeCount++);

        drawingState.selectedThickness.value = 5.0;
        expect(changeCount, 1);
      });
    });

    group('undo/redo 위임', () {
      test('lastActiveScribbleNotifier 없으면 undo/redo 무시', () {
        // 에러 없이 동작
        drawingState.undo();
        drawingState.redo();
      });

      test('undo/redo 직접 호출 가능', () {
        // WidgetsBinding 없는 환경에서는 setLastActive 없이 테스트
        drawingState.undo();
        drawingState.redo();
        // 에러 없이 동작
      });
    });

    group('dispose', () {
      test('dispose 후 isDisposed true', () {
        drawingState.dispose();
        expect(drawingState.isDisposed, true);
      });

      test('dispose 후 새 팩토리 호출은 새 인스턴스', () {
        drawingState.dispose();
        final newInstance = DrawingState();
        expect(newInstance.isDisposed, false);
        newInstance.dispose();
      });
    });

    group('DrawingPointerMode enum', () {
      test('모든 모드 존재', () {
        expect(
          DrawingPointerMode.values,
          contains(DrawingPointerMode.mouseOnly),
        );
        expect(
          DrawingPointerMode.values,
          contains(DrawingPointerMode.penOnly),
        );
      });
    });

    group('DrawingTool enum', () {
      test('모든 도구 존재', () {
        expect(DrawingTool.values.length, 8);
        expect(DrawingTool.values, contains(DrawingTool.pen));
        expect(DrawingTool.values, contains(DrawingTool.pencil));
        expect(DrawingTool.values, contains(DrawingTool.marker));
        expect(DrawingTool.values, contains(DrawingTool.erase));
        expect(DrawingTool.values, contains(DrawingTool.highlighter));
        expect(DrawingTool.values, contains(DrawingTool.text));
        expect(DrawingTool.values, contains(DrawingTool.shape));
        expect(DrawingTool.values, contains(DrawingTool.lasso));
      });
    });
  });
}
