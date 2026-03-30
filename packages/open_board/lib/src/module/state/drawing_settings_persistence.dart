import 'package:flutter/material.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 기반 설정 영구 저장 담당 클래스
///
/// DrawingState의 설정값(포인터 모드, 도구, 색상, 두께, 색상 슬롯)을
/// SharedPreferences에 저장/복원합니다.
class DrawingSettingsPersistence {
  // SharedPreferences 키 상수들
  static const String _keyPointerMode = 'drawing_pointer_mode';
  static const String _keySelectedTool = 'drawing_selected_tool';
  static const String _keySelectedColor = 'drawing_selected_color';
  static const String _keySelectedThickness = 'drawing_selected_thickness';
  static const String _keyColorSlots = 'drawing_color_slots';

  /// 설정 저장/복원 활성화 플래그
  bool _persistenceEnabled = false;

  /// 외부 설정 저장/복원 콜백들
  Future<void> Function()? onSave;
  Future<void> Function()? onLoad;

  /// 영구 저장 활성화 여부
  bool get persistenceEnabled => _persistenceEnabled;

  /// 설정 콜백 등록
  void setupCallbacks({
    Future<void> Function()? onSave,
    Future<void> Function()? onLoad,
  }) {
    this.onSave = onSave;
    this.onLoad = onLoad;
  }

  /// 설정 저장 (외부 콜백 사용)
  Future<void> saveSettings() async {
    if (onSave != null) {
      await onSave!();
    }
  }

  /// 설정 복원 (외부 콜백 사용)
  Future<void> loadSettings() async {
    if (onLoad != null) {
      await onLoad!();
    }
  }

  /// SharedPreferences 기반 영구 저장 활성화
  Future<void> enablePersistence({
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required ValueNotifier<List<Color>> colorSlots,
    required VoidCallback syncToAllNotifiers,
  }) async {
    if (_persistenceEnabled) return;

    try {
      _persistenceEnabled = true;

      onSave = () => _saveToSharedPreferences(
            pointerMode: pointerMode,
            selectedTool: selectedTool,
            selectedColor: selectedColor,
            selectedThickness: selectedThickness,
            colorSlots: colorSlots,
          );
      onLoad = () => _loadFromSharedPreferences(
            pointerMode: pointerMode,
            selectedTool: selectedTool,
            selectedColor: selectedColor,
            selectedThickness: selectedThickness,
            colorSlots: colorSlots,
          );

      // 저장된 설정 즉시 복원
      await loadSettings();
      syncToAllNotifiers();
    } on Exception {
      _persistenceEnabled = false;
    }
  }

  /// SharedPreferences 기반 영구 저장 비활성화
  void disablePersistence() {
    _persistenceEnabled = false;
    onSave = null;
    onLoad = null;
  }

  /// SharedPreferences에 설정 저장
  Future<void> _saveToSharedPreferences({
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required ValueNotifier<List<Color>> colorSlots,
  }) async {
    if (!_persistenceEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyPointerMode, pointerMode.value.toString());
      await prefs.setString(_keySelectedTool, selectedTool.value.toString());
      await prefs.setInt(_keySelectedColor, selectedColor.value.toARGB32());
      await prefs.setDouble(_keySelectedThickness, selectedThickness.value);

      final slotValues = colorSlots.value
          .map((color) => color.toARGB32().toString())
          .toList();
      await prefs.setStringList(_keyColorSlots, slotValues);
    } on Exception catch (error, stackTrace) {
      debugPrint('SharedPreferences 저장 에러: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// SharedPreferences에서 설정 복원
  Future<void> _loadFromSharedPreferences({
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required ValueNotifier<List<Color>> colorSlots,
  }) async {
    if (!_persistenceEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final pointerModeStr = prefs.getString(_keyPointerMode);
      if (pointerModeStr != null) {
        if (pointerModeStr.contains('mouseOnly')) {
          pointerMode.value = DrawingPointerMode.mouseOnly;
        } else if (pointerModeStr.contains('penOnly')) {
          pointerMode.value = DrawingPointerMode.penOnly;
        }
      }

      final toolStr = prefs.getString(_keySelectedTool);
      if (toolStr != null) {
        for (final tool in DrawingTool.values) {
          if (toolStr.contains(tool.toString().split('.').last)) {
            selectedTool.value = tool;
            break;
          }
        }
      }

      final colorValue = prefs.getInt(_keySelectedColor);
      if (colorValue != null) {
        selectedColor.value = Color(colorValue);
      }

      final thickness = prefs.getDouble(_keySelectedThickness);
      if (thickness != null) {
        selectedThickness.value = thickness;
      }

      final slotStrings = prefs.getStringList(_keyColorSlots);
      if (slotStrings != null && slotStrings.length == 4) {
        colorSlots.value =
            slotStrings.map((str) => Color(int.parse(str))).toList();
      }
    } on Exception catch (_) {
      // 설정 복원 실패 시 기본값 유지
    }
  }

  /// 설정 초기화 (기본값으로 리셋)
  Future<void> resetToDefaults({
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required ValueNotifier<bool> showColorPicker,
  }) async {
    try {
      pointerMode.value = DrawingPointerMode.penOnly;
      selectedTool.value = DrawingTool.pencil;
      selectedColor.value = Colors.black;
      selectedThickness.value = 2.0;
      showColorPicker.value = false;

      if (_persistenceEnabled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyPointerMode);
        await prefs.remove(_keySelectedTool);
        await prefs.remove(_keySelectedColor);
        await prefs.remove(_keySelectedThickness);
      }
    } on Exception catch (_) {
      // 설정 초기화 실패 시 무시
    }
  }

  /// 자동 저장 리스너 설정
  void setupAutoSave({
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required VoidCallback syncToAllNotifiers,
  }) {
    pointerMode.addListener(() {
      saveSettings();
      Future.delayed(const Duration(milliseconds: 50), syncToAllNotifiers);
    });

    selectedTool.addListener(() {
      saveSettings();
      Future.delayed(const Duration(milliseconds: 50), syncToAllNotifiers);
    });

    selectedColor.addListener(() {
      saveSettings();
      Future.delayed(const Duration(milliseconds: 50), syncToAllNotifiers);
    });

    selectedThickness.addListener(() {
      saveSettings();
      Future.delayed(const Duration(milliseconds: 50), syncToAllNotifiers);
    });
  }

  /// 모든 리소스 정리
  void clear() {
    onSave = null;
    onLoad = null;
  }
}
