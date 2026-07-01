import 'package:flutter/material.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/notifier_registry.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

/// 전역 상태를 모든 Notifier에 동기화하는 담당 클래스
///
/// DrawingState의 현재 도구/색상/두께를 각 ScribbleModeNotifier에 적용합니다.
/// NotifierRegistry를 주입받아 사용합니다.
class StateSynchronizer {
  final NotifierRegistry _registry;

  StateSynchronizer(this._registry);

  /// 현재 상태를 특정 modeNotifier에 적용
  void applyToModeNotifier(
    ScribbleModeNotifier modeNotifier, {
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required ValueNotifier<String> selectedShapeType,
  }) {
    try {
      final currentTool = selectedTool.value;
      final currentColor = selectedColor.value;
      final currentThickness = selectedThickness.value;

      final beforeState = modeNotifier.state;

      // 지우개에서 다른 도구로 전환하는 경우 ScribbleNotifier도 함께 변경
      final isEraserToOtherTool =
          beforeState.inkGroupInfo.selectedInk == 'erase' &&
          currentTool != DrawingTool.erase;
      ScribbleNotifier? correspondingScribbleNotifier;

      if (isEraserToOtherTool) {
        correspondingScribbleNotifier =
            _registry.findScribbleNotifierForModeNotifier(modeNotifier);
        if (correspondingScribbleNotifier != null) {
          correspondingScribbleNotifier.setStrokeInk();
        }
      }

      // 포인터 모드 설정
      if (pointerMode.value == DrawingPointerMode.mouseOnly) {
        modeNotifier.setAllowedPointersMode(ScribblePointerMode.all);
      } else {
        modeNotifier.setAllowedPointersMode(ScribblePointerMode.penOnly);
      }

      // ⚠️ 순서 중요: setStrokeWidth/setColor는 selectedInk를 기준으로 box를
      //    갱신하므로, 도구 변경(setPen 등)을 FIRST 호출해 selectedInk를
      //    먼저 새 도구로 바꿔야 색/두께가 올바른 box에 들어간다.
      switch (currentTool) {
        case DrawingTool.pen:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setPen();
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);

        case DrawingTool.pencil:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setPencil();
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);

        case DrawingTool.marker:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          final markerColor = currentColor.withValues(alpha: 0.5);
          modeNotifier.setMarker();
          modeNotifier.setColor(markerColor);
          modeNotifier.setStrokeWidth(currentThickness);

        case DrawingTool.fixedPen:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setFixedPen();
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);

        case DrawingTool.uniformPen:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setUniformPen();
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);

        case DrawingTool.highlighter:
          break;

        case DrawingTool.erase:
          modeNotifier.setEraser();
          modeNotifier.setStrokeWidth(currentThickness);

          if (beforeState.inkGroupInfo.selectedInk != 'erase') {
            correspondingScribbleNotifier =
                _registry.findScribbleNotifierForModeNotifier(modeNotifier);
            if (correspondingScribbleNotifier != null) {
              correspondingScribbleNotifier.setEraser();
            }
          }

        case DrawingTool.text:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setText();

        case DrawingTool.shape:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setShape();
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);
          // 타겟 도형(자유/타원/사각형/선분)을 전달 — setColor/setStrokeWidth
          // 뒤에 호출해 copyWith 재구성으로 덮이지 않게 한다.
          modeNotifier.setShapeType(selectedShapeType.value);

        case DrawingTool.lasso:
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setLassoSelection();

        case DrawingTool.image:
          // 이미지 임베드 모드는 잉크 그리기가 아니라 위젯 레이어 상호작용이므로
          // 색/두께를 건드리지 않고 모드만 전환한다.
          modeNotifier.setImage();
      }

      // 상태 불일치 감지 (지우개/올가미/텍스트/이미지 제외)
      final afterState = modeNotifier.state;
      if (currentTool != DrawingTool.erase &&
          currentTool != DrawingTool.lasso &&
          currentTool != DrawingTool.text &&
          currentTool != DrawingTool.image) {
        final expectedColor = currentTool == DrawingTool.marker
            ? currentColor.withValues(alpha: 0.5)
            : currentColor;
        final actualColor = afterState.inkGroupInfo.selectedColor;
        final actualThickness = afterState.inkGroupInfo.seletedStrokeWidth;

        if (actualColor != expectedColor) {
          modeNotifier.setColor(expectedColor);
        }
        if (actualThickness != currentThickness) {
          modeNotifier.setStrokeWidth(currentThickness);
        }
      }
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
    }
  }

  /// 모든 활성 notifier에 현재 상태 동기화
  void syncToAllNotifiers({
    required ValueNotifier<DrawingPointerMode> pointerMode,
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
    required ValueNotifier<String> selectedShapeType,
  }) {
    final notifiers = _registry.activeModeNotifiers;
    if (notifiers.isEmpty) return;

    for (final notifier in notifiers) {
      applyToModeNotifier(
        notifier,
        pointerMode: pointerMode,
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        selectedThickness: selectedThickness,
        selectedShapeType: selectedShapeType,
      );
    }

    // 동기화 후 일치성 확인
    Future.delayed(const Duration(milliseconds: 100), () {
      ensureStateConsistency(
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        selectedThickness: selectedThickness,
      );
    });
  }

  /// 강제 상태 일치 확인 및 재설정
  void ensureStateConsistency({
    required ValueNotifier<DrawingTool> selectedTool,
    required ValueNotifier<Color> selectedColor,
    required ValueNotifier<double> selectedThickness,
  }) {
    final notifiers = _registry.activeModeNotifiers;
    if (notifiers.isEmpty) return;

    final expectedTool = selectedTool.value;
    final expectedColor = selectedColor.value;
    final expectedThickness = selectedThickness.value;

    for (final notifier in notifiers) {
      final state = notifier.state;
      final actualColor = state.inkGroupInfo.selectedColor;
      final actualThickness = state.inkGroupInfo.seletedStrokeWidth;

      if (expectedTool != DrawingTool.erase &&
          expectedTool != DrawingTool.lasso) {
        final expectedFinalColor = expectedTool == DrawingTool.marker
            ? expectedColor.withValues(alpha: 0.5)
            : expectedColor;

        if (actualColor != expectedFinalColor) {
          notifier.setColor(expectedFinalColor);
        }

        if (actualThickness != expectedThickness) {
          notifier.setStrokeWidth(expectedThickness);
        }
      }
    }
  }

  /// 특정 ScribbleNotifier의 상태를 현재 전역 도구에 맞게 동기화
  void syncScribbleNotifierToGlobalTool(
    ScribbleNotifier scribbleNotifier, {
    required ValueNotifier<DrawingTool> selectedTool,
  }) {
    try {
      final currentTool = selectedTool.value;

      switch (currentTool) {
        case DrawingTool.pen:
        case DrawingTool.pencil:
        case DrawingTool.marker:
        case DrawingTool.fixedPen:
        case DrawingTool.uniformPen:
        case DrawingTool.highlighter:
        case DrawingTool.shape:
        case DrawingTool.text:
        case DrawingTool.lasso:
        case DrawingTool.image:
          scribbleNotifier.setStrokeInk();
          break;
        case DrawingTool.erase:
          scribbleNotifier.setEraser();
          break;
      }
    } on Exception {
      // ScribbleNotifier 동기화 실패 시 무시
    }
  }
}
