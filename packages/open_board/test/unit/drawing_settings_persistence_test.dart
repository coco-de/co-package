import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/drawing_settings_persistence.dart';

void main() {
  late DrawingSettingsPersistence persistence;

  setUp(() {
    persistence = DrawingSettingsPersistence();
  });

  group('DrawingSettingsPersistence', () {
    group('초기 상태', () {
      test('persistenceEnabled는 초기에 false이다', () {
        expect(persistence.persistenceEnabled, isFalse);
      });

      test('onSave는 초기에 null이다', () {
        expect(persistence.onSave, isNull);
      });

      test('onLoad는 초기에 null이다', () {
        expect(persistence.onLoad, isNull);
      });
    });

    group('setupCallbacks', () {
      test('onSave 콜백을 설정할 수 있다', () async {
        var saveCalled = false;
        persistence.setupCallbacks(
          onSave: () => saveCalled = true,
        );

        await persistence.saveSettings();

        expect(saveCalled, isTrue);
      });

      test('onLoad 콜백을 설정할 수 있다', () async {
        var loadCalled = false;
        persistence.setupCallbacks(
          onLoad: () => loadCalled = true,
        );

        await persistence.loadSettings();

        expect(loadCalled, isTrue);
      });
    });

    group('saveSettings', () {
      test('onSave가 null이면 아무 일도 일어나지 않는다', () async {
        // 예외 없이 실행되면 성공
        await persistence.saveSettings();
      });

      test('onSave가 설정되어 있으면 호출된다', () async {
        var callCount = 0;
        persistence.setupCallbacks(onSave: () => callCount++);

        await persistence.saveSettings();
        await persistence.saveSettings();

        expect(callCount, 2);
      });
    });

    group('loadSettings', () {
      test('onLoad가 null이면 아무 일도 일어나지 않는다', () async {
        // 예외 없이 실행되면 성공
        await persistence.loadSettings();
      });

      test('onLoad가 설정되어 있으면 호출된다', () async {
        var callCount = 0;
        persistence.setupCallbacks(onLoad: () => callCount++);

        await persistence.loadSettings();

        expect(callCount, 1);
      });
    });

    group('disablePersistence', () {
      test('disablePersistence 후 persistenceEnabled가 false가 된다', () {
        persistence.disablePersistence();

        expect(persistence.persistenceEnabled, isFalse);
      });

      test('disablePersistence 후 onSave/onLoad가 null이 된다', () {
        persistence.setupCallbacks(
          onSave: () {},
          onLoad: () {},
        );

        persistence.disablePersistence();

        expect(persistence.onSave, isNull);
        expect(persistence.onLoad, isNull);
      });
    });

    group('resetToDefaults', () {
      test('기본값으로 초기화된다', () async {
        final pointerMode = ValueNotifier(DrawingPointerMode.mouseOnly);
        final selectedTool = ValueNotifier(DrawingTool.marker);
        final selectedColor = ValueNotifier<Color>(Colors.red);
        final selectedThickness = ValueNotifier(5.0);
        final showColorPicker = ValueNotifier(true);

        await persistence.resetToDefaults(
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
          showColorPicker: showColorPicker,
        );

        expect(pointerMode.value, DrawingPointerMode.penOnly);
        expect(selectedTool.value, DrawingTool.pencil);
        expect(selectedColor.value, Colors.black);
        expect(selectedThickness.value, 2.0);
        expect(showColorPicker.value, isFalse);

        pointerMode.dispose();
        selectedTool.dispose();
        selectedColor.dispose();
        selectedThickness.dispose();
        showColorPicker.dispose();
      });
    });

    group('setupAutoSave', () {
      test('ValueNotifier 변경 시 saveSettings이 호출된다', () async {
        var saveCount = 0;
        persistence.setupCallbacks(onSave: () => saveCount++);

        final pointerMode = ValueNotifier(DrawingPointerMode.penOnly);
        final selectedTool = ValueNotifier(DrawingTool.pencil);
        final selectedColor = ValueNotifier(Colors.black);
        final selectedThickness = ValueNotifier(2.0);

        persistence.setupAutoSave(
          pointerMode: pointerMode,
          selectedTool: selectedTool,
          selectedColor: selectedColor,
          selectedThickness: selectedThickness,
          syncToAllNotifiers: () {},
        );

        // 상태 변경으로 자동 저장 트리거
        selectedColor.value = Colors.red;

        // 비동기 처리 대기
        await Future.delayed(.zero);

        expect(saveCount, greaterThanOrEqualTo(1));

        pointerMode.dispose();
        selectedTool.dispose();
        selectedColor.dispose();
        selectedThickness.dispose();
      });
    });

    group('clear', () {
      test('clear 후 콜백이 null이 된다', () {
        persistence.setupCallbacks(
          onSave: () {},
          onLoad: () {},
        );

        persistence.clear();

        expect(persistence.onSave, isNull);
        expect(persistence.onLoad, isNull);
      });
    });
  });
}
