import 'package:flutter/material.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/notifier_registry.dart';
import 'package:open_board/src/module/state/state_synchronizer.dart';
import 'package:open_board/src/module/state/undo_redo_tracker.dart';
import 'package:open_board/src/module/state/drawing_settings_persistence.dart';

enum DrawingPointerMode { mouseOnly, penOnly }

enum DrawingTool { pen, pencil, marker, erase, highlighter, text, shape, lasso }

/// 🌍 전역 필기 도구 상태 관리 (싱글톤)
///
/// 모든 ScribbleWidget에서 공유되는 전역 상태를 관리합니다.
/// 양면보기 등에서 여러 필기 위젯이 있어도 일관된 상태를 유지합니다.
///
/// 내부적으로 NotifierRegistry, StateSynchronizer, UndoRedoTracker,
/// DrawingSettingsPersistence에 위임합니다 (Facade 패턴).
class DrawingState {
  static DrawingState? _instance;

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

  // ===== 하위 객체들 (Facade 패턴) =====
  final NotifierRegistry _registry = NotifierRegistry();
  late final StateSynchronizer _synchronizer = StateSynchronizer(_registry);
  late final UndoRedoTracker _undoRedoTracker = UndoRedoTracker(_registry);
  final DrawingSettingsPersistence _persistence = DrawingSettingsPersistence();

  // 🎨 전역 상태 변수들 (재초기화 가능)
  late ValueNotifier<DrawingPointerMode> pointerMode;
  late ValueNotifier<DrawingTool> selectedTool;
  late ValueNotifier<Color> selectedColor;
  late ValueNotifier<double> selectedThickness;
  late ValueNotifier<bool> showColorPicker;

  // 🎨 4개의 색상 슬롯 (즐겨찾기) - ValueNotifier로 감싸서 UI 반응형으로
  late ValueNotifier<List<Color>> colorSlots;

  // 🔗 외부 설정 저장/복원 콜백들
  Future<void> Function()? get onSave => _persistence.onSave;
  set onSave(Future<void> Function()? value) => _persistence.onSave = value;

  Future<void> Function()? get onLoad => _persistence.onLoad;
  set onLoad(Future<void> Function()? value) => _persistence.onLoad = value;

  // ✨ dispose 상태 추적 (위젯 생명주기 오류 방지)
  bool _isDisposed = false;

  /// 등록된 notifier 수 확인
  int get activeNotifierCount => _registry.activeModeNotifierCount;

  /// 등록된 scribbleNotifier 수 확인
  int get activeScribbleNotifierCount => _registry.activeScribbleNotifierCount;

  /// 현재 활성 ScribbleNotifier (undo/redo 대상)
  ScribbleNotifier? get lastActiveScribbleNotifier =>
      _registry.lastActiveScribbleNotifier;

  /// 🛡️ dispose 여부 확인
  bool get isDisposed => _isDisposed;

  /// 활성 ScribbleNotifier 변경 알림 ValueNotifier
  ValueNotifier<ScribbleNotifier?> get activeScribbleNotifierNotifier =>
      _registry.activeScribbleNotifierNotifier;

  /// Undo/Redo 가능 여부 실시간 추적 ValueNotifier
  ValueNotifier<bool> get canUndoNotifier => _undoRedoTracker.canUndoNotifier;
  ValueNotifier<bool> get canRedoNotifier => _undoRedoTracker.canRedoNotifier;

  /// 🔄 ValueNotifier들 초기화 (재사용 시 필요)
  void _initializeNotifiers() {
    _isDisposed = false;

    // 🎨 기본 상태 ValueNotifier들 초기화
    pointerMode = ValueNotifier(DrawingPointerMode.penOnly);
    selectedTool = ValueNotifier(DrawingTool.pencil);
    selectedColor = ValueNotifier(Colors.black);
    selectedThickness = ValueNotifier(2.0);
    showColorPicker = ValueNotifier(false);

    // 🎨 색상 슬롯 기본값 초기화
    colorSlots = ValueNotifier([
      Colors.black,
      const Color(0xFFFE4429), // 빨강
      const Color(0xFF218BFF), // 파랑
      const Color(0xFFFCE14B), // 노랑
    ]);

    // 🎯 활성 ScribbleNotifier 관리 ValueNotifier들 초기화
    final activeScribbleNotifierNotifier =
        ValueNotifier<ScribbleNotifier?>(null);
    final canUndoNotifier = ValueNotifier<bool>(false);
    final canRedoNotifier = ValueNotifier<bool>(false);

    // 하위 객체들 초기화
    _registry.initialize(activeScribbleNotifierNotifier);
    _undoRedoTracker.initialize(canUndoNotifier, canRedoNotifier);
  }

  /// 🔄 상태 초기화 (필요한 경우)
  void reset() {
    pointerMode.value = DrawingPointerMode.penOnly;
    selectedTool.value = DrawingTool.pencil;
    selectedColor.value = Colors.black;
    selectedThickness.value = 2.0;
    showColorPicker.value = false;

    // 모든 활성 notifier에 적용
    _syncToAllNotifiers();
  }

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

  /// 🌍 모든 활성 notifier에 현재 상태 동기화
  void _syncToAllNotifiers() {
    _synchronizer.syncToAllNotifiers(
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

  /// 🎨 도구 변경 (모든 notifier에 자동 동기화)
  void setTool(DrawingTool tool) {
    selectedTool.value = tool;
    _syncToAllNotifiers();
  }

  /// 🎨 색상 변경 (모든 notifier에 자동 동기화)
  void setColor(Color color) {
    selectedColor.value = color;
    _syncToAllNotifiers();
  }

  /// 🎨 두께 변경 (모든 notifier에 자동 동기화)
  void setThickness(double thickness) {
    selectedThickness.value = thickness;
    _syncToAllNotifiers();
  }

  /// 🎨 포인터 모드 변경 (모든 notifier에 자동 동기화)
  void setPointerMode(DrawingPointerMode mode) {
    pointerMode.value = mode;
    _syncToAllNotifiers();
  }

  /// 설정 콜백 등록 (외부에서 호출)
  void setupCallbacks({
    Future<void> Function()? onSave,
    Future<void> Function()? onLoad,
  }) {
    _persistence.setupCallbacks(onSave: onSave, onLoad: onLoad);
  }

  /// 설정 저장 (외부 콜백 사용)
  Future<void> saveSettings() async {
    await _persistence.saveSettings();
  }

  /// 설정 복원 (외부 콜백 사용)
  Future<void> loadSettings() async {
    await _persistence.loadSettings();
    // 복원 후 모든 notifier에 동기화
    _syncToAllNotifiers();
  }

  /// 🔗 SharedPreferences 기반 영구 저장 활성화
  Future<void> enablePersistence() async {
    await _persistence.enablePersistence(
      pointerMode: pointerMode,
      selectedTool: selectedTool,
      selectedColor: selectedColor,
      selectedThickness: selectedThickness,
      colorSlots: colorSlots,
      syncToAllNotifiers: _syncToAllNotifiers,
    );
  }

  /// 🔗 SharedPreferences 기반 영구 저장 비활성화
  void disablePersistence() {
    _persistence.disablePersistence();
  }

  /// 🔄 설정 초기화 (기본값으로 리셋)
  Future<void> resetToDefaults() async {
    await _persistence.resetToDefaults(
      pointerMode: pointerMode,
      selectedTool: selectedTool,
      selectedColor: selectedColor,
      selectedThickness: selectedThickness,
      showColorPicker: showColorPicker,
    );

    // 모든 활성 notifier에 적용
    _syncToAllNotifiers();
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

  /// 📝 디스포즈 (앱 종료 시)
  void dispose() {
    _isDisposed = true;
    _undoRedoTracker.isDisposed = true;

    pointerMode.dispose();
    selectedTool.dispose();
    selectedColor.dispose();
    selectedThickness.dispose();
    showColorPicker.dispose();

    // 🎯 ValueNotifier들도 정리
    _registry.activeScribbleNotifierNotifier.dispose();
    _undoRedoTracker.canUndoNotifier.dispose();
    _undoRedoTracker.canRedoNotifier.dispose();

    // 하위 객체들 정리
    _registry.clear();
    _undoRedoTracker.clear();
    _persistence.clear();
  }

  /// 🔍 현재 상태 디버깅 출력
  void debugCurrentState() {}

  /// 🔍 모든 등록된 modeNotifier의 현재 상태 확인
  void debugAllNotifierStates() {
    // 디버그 모드에서만 사용 - 현재는 비활성화
    for (final _ in _registry.activeModeNotifiers) {
      // 상태 확인 로직 (현재 비활성화)
    }
  }

  /// 🎯 강제 상태 일치 확인 및 재설정 (불일치 시 한번 더 설정)
  void ensureStateConsistency() {
    _synchronizer.ensureStateConsistency(
      selectedTool: selectedTool,
      selectedColor: selectedColor,
      selectedThickness: selectedThickness,
    );
  }

  // ===== Undo/Redo 관련 메서드들 =====

  /// 🔙 Undo 가능 여부 (활성 ScribbleNotifier 기준)
  bool get canUndo => _undoRedoTracker.canUndo;

  /// 🔜 Redo 가능 여부 (활성 ScribbleNotifier 기준)
  bool get canRedo => _undoRedoTracker.canRedo;

  /// 🎯 Undo/Redo 후 화면 업데이트 콜백 등록
  void registerUndoRedoUpdateCallback(VoidCallback callback) {
    _undoRedoTracker.registerUndoRedoUpdateCallback(callback);
  }

  /// 🎯 Undo/Redo 후 화면 업데이트 콜백 해제
  void unregisterUndoRedoUpdateCallback(VoidCallback callback) {
    _undoRedoTracker.unregisterUndoRedoUpdateCallback(callback);
  }

  /// 🔙 Undo 실행 (활성 ScribbleNotifier 기준)
  void undo() {
    _undoRedoTracker.undo();
  }

  /// 🔜 Redo 실행 (활성 ScribbleNotifier 기준)
  void redo() {
    _undoRedoTracker.redo();
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
}
