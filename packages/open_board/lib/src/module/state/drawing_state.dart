  import 'package:flutter/material.dart';
  import 'package:open_board/src/module/scribble_mode.notifier.dart';
  import 'package:open_board/src/module/scribble.notifier.dart';
  import 'package:open_board/src/module/state/notifier_registry.dart';
  import 'package:open_board/src/module/state/state_synchronizer.dart';
  import 'package:open_board/src/module/state/undo_redo_tracker.dart';
  import 'package:open_board/src/module/state/drawing_settings_persistence.dart';

  enum DrawingPointerMode { mouseOnly, penOnly }

  enum DrawingTool {
    pen,
    pencil,
    marker,
    erase,
    highlighter,
    text,
    shape,
    lasso,
  }

  /// 🌍 전역 필기 도구 상태 관리 (싱글톤)
  ///
  /// 모든 ScribbleWidget에서 공유되는 전역 상태를 관리합니다.
  /// 양면보기 등에서 여러 필기 위젯이 있어도 일관된 상태를 유지합니다.
  ///
  /// 내부적으로 NotifierRegistry, StateSynchronizer, UndoRedoTracker,
  /// DrawingSettingsPersistence에 위임합니다 (Facade 패턴).
  class DrawingState {
    static DrawingState? _instance;

    // 🎨 전역 상태 변수들 (재초기화 가능)
    late ValueNotifier<DrawingPointerMode> pointerMode;

    late ValueNotifier<DrawingTool> selectedTool;

    late ValueNotifier<Color> selectedColor;
    late ValueNotifier<double>
    selectedThickness; // ===== 하위 객체들 (Facade 패턴) =====
    final NotifierRegistry _registry = NotifierRegistry();
    late final StateSynchronizer _synchronizer = StateSynchronizer(_registry);

    late final UndoRedoTracker _undoRedoTracker = UndoRedoTracker(_registry);
    final DrawingSettingsPersistence _persistence =
        DrawingSettingsPersistence(); // ✨ dispose 상태 추적 (위젯 생명주기 오류 방지)
    bool _isDisposed = false;
    factory DrawingState() {
      if (_instance == null || _instance!._isDisposed) {
        // 🔄 인스턴스가 없거나 dispose된 경우 새로 생성
        _instance = DrawingState._internal();
      }
      return _instance!;
    }

    DrawingState._internal() {
      _initializeNotifiers();
      _setupAutoSave();
    }

    /// 현재 활성 ScribbleNotifier (undo/redo 대상)
    ScribbleNotifier? get lastActiveScribbleNotifier =>
        _registry.lastActiveScribbleNotifier;

    /// 📝 ScribbleModeNotifier 등록 (ScribbleWidget에서 자동 호출)
    void registerNotifier(ScribbleModeNotifier modeNotifier) {
      _registry.registerModeNotifier(modeNotifier);
      // 등록 즉시 현재 전역 상태 적용
      applyToModeNotifier(modeNotifier);
    }

    /// 📝 ScribbleModeNotifier 해제 (ScribbleWidget dispose 시 자동 호출)
    void unregisterNotifier(ScribbleModeNotifier modeNotifier) {
      _registry.unregisterModeNotifier(modeNotifier);
    }

    /// 📝 ScribbleNotifier 등록 (ScribbleWidget에서 자동 호출)
    void registerScribbleNotifier(ScribbleNotifier scribbleNotifier) {
      _registry.registerScribbleNotifier(scribbleNotifier);
    }

    /// 📝 ScribbleNotifier 해제 (ScribbleWidget dispose 시 자동 호출)
    void unregisterScribbleNotifier(ScribbleNotifier scribbleNotifier) {
      _registry.unregisterScribbleNotifier(
        scribbleNotifier,
        isDisposed: _isDisposed,
        onLastActiveCleared: () => _undoRedoTracker.updateUndoRedoState(),
      );
    }

    /// 🎯 마지막 활성 ScribbleNotifier 설정 (필기 시작 시 호출)
    void setLastActiveScribbleNotifier(ScribbleNotifier scribbleNotifier) {
      final changed = _registry.setLastActiveScribbleNotifier(
        scribbleNotifier,
        isDisposed: _isDisposed,
      );

      // 🔄 즉시 undo/redo 상태 업데이트
      _undoRedoTracker.updateUndoRedoState();

      if (changed) {
        // 🎯 약간의 지연 후 한 번 더 업데이트 (비동기 상태 변경 반영)
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_registry.lastActiveScribbleNotifier == scribbleNotifier) {
            _undoRedoTracker.updateUndoRedoState();
          }
        });
      }
    }

    /// Undo 가능 여부 실시간 추적 ValueNotifier
    ValueNotifier<bool> get canUndoNotifier => _undoRedoTracker.canUndoNotifier;

    /// Redo 가능 여부 실시간 추적 ValueNotifier
    ValueNotifier<bool> get canRedoNotifier => _undoRedoTracker.canRedoNotifier;

    /// 🎯 Undo/Redo 가능 여부 상태 업데이트 (public)
    void updateUndoRedoState() {
      _undoRedoTracker.updateUndoRedoState();
    }

    /// 🎯 현재 상태를 특정 modeNotifier에 적용
    void applyToModeNotifier(ScribbleModeNotifier modeNotifier) {
      _synchronizer.applyToModeNotifier(
        modeNotifier,
        pointerMode: pointerMode,
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        selectedThickness: selectedThickness,
      );
    }

    /// 🚀 강제 동기화 (외부에서 호출 가능)
    void forceSyncAll() {
      _syncToAllNotifiers();
    }

    /// 🎯 특정 ScribbleNotifier의 상태를 현재 전역 도구에 맞게 동기화
    void syncScribbleNotifierToGlobalTool(ScribbleNotifier scribbleNotifier) {
      _synchronizer.syncScribbleNotifierToGlobalTool(
        scribbleNotifier,
        selectedTool: selectedTool,
      );

      // 상태 변경 후 Undo/Redo 상태 업데이트
      updateUndoRedoState();
    }

    /// 🔄 ValueNotifier들 초기화 (재사용 시 필요)
    void _initializeNotifiers() {
      _isDisposed = false;

      // 🎨 기본 상태 ValueNotifier들 초기화
      pointerMode = ValueNotifier(DrawingPointerMode.penOnly);
      selectedTool = ValueNotifier(DrawingTool.pencil);
      selectedColor = ValueNotifier(Colors.black);
      selectedThickness = ValueNotifier(2.0);

      // 🎯 활성 ScribbleNotifier 관리 ValueNotifier들 초기화
      final activeScribbleNotifierNotifier = ValueNotifier<ScribbleNotifier?>(
        null,
      );
      final canUndoNotifier = ValueNotifier<bool>(false);
      final canRedoNotifier = ValueNotifier<bool>(false);

      // 하위 객체들 초기화
      _registry.initialize(activeScribbleNotifierNotifier);
      _undoRedoTracker.initialize(canUndoNotifier, canRedoNotifier);
    }

    /// 🌍 모든 활성 notifier에 현재 상태 동기화
    void _syncToAllNotifiers() {
      _synchronizer.syncToAllNotifiers(
        pointerMode: pointerMode,
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        selectedThickness: selectedThickness,
      );
    }

    /// 설정이 변경될 때마다 자동 저장 및 동기화 설정
    void _setupAutoSave() {
      _persistence.setupAutoSave(
        pointerMode: pointerMode,
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        selectedThickness: selectedThickness,
        syncToAllNotifiers: _syncToAllNotifiers,
      );
    }
  }
