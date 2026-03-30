import 'package:flutter/material.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

/// SharedPreferences 기반 설정 영구 저장 담당 클래스
///
/// DrawingState의 설정값(포인터 모드, 도구, 색상, 두께, 색상 슬롯)을
/// SharedPreferences에 저장/복원합니다.
class DrawingSettingsPersistence {
  /// 외부 설정 저장/복원 콜백들
  Future<void> Function()? onSave;
  Future<void> Function()? onLoad;

  /// 설정 저장 (외부 콜백 사용)
  Future<void> saveSettings() async {
    if (onSave != null) {
      await onSave!();
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

}
