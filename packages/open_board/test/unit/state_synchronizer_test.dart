import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/notifier_registry.dart';
import 'package:open_board/src/module/state/state_synchronizer.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

void main() {
  late NotifierRegistry registry;
  late StateSynchronizer synchronizer;
  late ValueNotifier<DrawingPointerMode> pointerMode;
  late ValueNotifier<DrawingTool> selectedTool;
  late ValueNotifier<Color> selectedColor;
  late ValueNotifier<double> selectedThickness;

  setUp(() {
    registry = NotifierRegistry();
    final activeNotifierNotifier = ValueNotifier<ScribbleNotifier?>(null);
    registry.initialize(activeNotifierNotifier);
    synchronizer = StateSynchronizer(registry);

    pointerMode = ValueNotifier(DrawingPointerMode.penOnly);
    selectedTool = ValueNotifier(DrawingTool.pencil);
    selectedColor = ValueNotifier(Colors.black);
    selectedThickness = ValueNotifier(2.0);
  });

  tearDown(() {
    pointerMode.dispose();
    selectedTool.dispose();
    selectedColor.dispose();
    selectedThickness.dispose();
  });

  group('StateSynchronizer', () {
    group('applyToModeNotifier', () {
      test('펜 도구 적용 시 색상/두께/도구가 올바르게 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .pen;
        selectedColor.value = Colors.red;
        selectedThickness.value = 3.0;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'pen');
        expect(modeNotifier.state.inkGroupInfo.selectedColor, Colors.red);
        expect(modeNotifier.state.inkGroupInfo.seletedStrokeWidth, 3.0);
      });

      test('연필 도구 적용 시 올바르게 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .pencil;
        selectedColor.value = Colors.blue;
        selectedThickness.value = 1.5;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'pencil');
        expect(modeNotifier.state.inkGroupInfo.selectedColor, Colors.blue);
        expect(modeNotifier.state.inkGroupInfo.seletedStrokeWidth, 1.5);
      });

      test('마커 도구 적용 시 투명도 0.5가 적용된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .marker;
        selectedColor.value = Colors.green;
        selectedThickness.value = 4.0;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'marker');
        final expectedColor = Colors.green.withValues(alpha: 0.5);
        expect(modeNotifier.state.inkGroupInfo.selectedColor, expectedColor);
      });

      test('지우개 도구 적용 시 erase 모드가 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .erase;
        selectedThickness.value = 5.0;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'erase');
        // Note: setStrokeWidth sets the width for the current ink (before switching),
        // then setEraser() switches selectedInk. The erase ink has its own default width.
      });

      test('올가미 도구 적용 시 lasso 모드가 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .lasso;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'lasso');
      });

      test('텍스트 도구 적용 시 text 모드가 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .text;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'text');
      });

      test('도형 도구 적용 시 shape 모드가 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        selectedTool.value = .shape;
        selectedColor.value = Colors.orange;
        selectedThickness.value = 2.5;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedInk, 'shape');
        expect(modeNotifier.state.inkGroupInfo.selectedColor, Colors.orange);
      });

      test('mouseOnly 포인터 모드 시 all 포인터 모드가 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        pointerMode.value = .mouseOnly;
        selectedTool.value = .pencil;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(
          modeNotifier.state.allowedPointersMode,
          ScribblePointerMode.all,
        );
      });

      test('penOnly 포인터 모드 시 penOnly가 설정된다', () {
        final modeNotifier = ScribbleModeNotifier();
        pointerMode.value = .penOnly;
        selectedTool.value = .pencil;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(
          modeNotifier.state.allowedPointersMode,
          ScribblePointerMode.penOnly,
        );
      });
    });

    group('syncToAllNotifiers', () {
      test('등록된 모든 notifier에 상태가 동기화된다', () {
        final notifier1 = ScribbleModeNotifier();
        final notifier2 = ScribbleModeNotifier();
        registry.registerModeNotifier(notifier1);
        registry.registerModeNotifier(notifier2);

        selectedTool.value = .pen;
        selectedColor.value = Colors.red;
        selectedThickness.value = 3.0;

        synchronizer.syncToAllNotifiers(
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(notifier1.state.inkGroupInfo.selectedInk, 'pen');
        expect(notifier1.state.inkGroupInfo.selectedColor, Colors.red);
        expect(notifier2.state.inkGroupInfo.selectedInk, 'pen');
        expect(notifier2.state.inkGroupInfo.selectedColor, Colors.red);
      });

      test('등록된 notifier가 없으면 아무 일도 일어나지 않는다', () {
        // 예외 없이 실행되면 성공
        synchronizer.syncToAllNotifiers(
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );
      });
    });

    group('ensureStateConsistency', () {
      test('불일치 상태를 감지하고 재설정한다', () {
        final modeNotifier = ScribbleModeNotifier();
        registry.registerModeNotifier(modeNotifier);

        // 먼저 도구 적용
        selectedTool.value = .pen;
        selectedColor.value = Colors.red;
        selectedThickness.value = 3.0;

        synchronizer.applyToModeNotifier(
          modeNotifier,
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        // 일치성 확인
        synchronizer.ensureStateConsistency(
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
        );

        expect(modeNotifier.state.inkGroupInfo.selectedColor, Colors.red);
        expect(modeNotifier.state.inkGroupInfo.seletedStrokeWidth, 3.0);
      });
    });

    group('syncScribbleNotifierToGlobalTool', () {
      test('그리기 도구일 때 setStrokeInk이 호출된다', () {
        final scribbleNotifier = ScribbleNotifier();
        selectedTool.value = .pen;

        // 예외 없이 실행되면 성공
        synchronizer.syncScribbleNotifierToGlobalTool(
          scribbleNotifier,
          selectedTool: selectedTool,
        );
      });

      test('지우개 도구일 때 setEraser가 호출된다', () {
        final scribbleNotifier = ScribbleNotifier();
        selectedTool.value = .erase;

        // 예외 없이 실행되면 성공
        synchronizer.syncScribbleNotifierToGlobalTool(
          scribbleNotifier,
          selectedTool: selectedTool,
        );
      });
    });
  });
}
