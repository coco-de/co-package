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
  fixedPen,

  /// 균일 두께 펜 — 필압 무시 + 콘텐츠 좌표 고정 두께(줌 보정 없음). `fixedPen`
  /// (화면 물리 두께 보정)과 두께 정책만 다르다.
  uniformPen,

  erase,
  highlighter,
  text,
  shape,
  lasso,

  /// 이미지 임베드 선택/변형 모드 — 삽입된 [ImageDrawable] 을 탭 선택 후
  /// 이동/크기조절/회전/삭제한다. 잉크 그리기가 아니라 위젯 레이어 상호작용이다.
  image,
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
  late ValueNotifier<double> selectedThickness;

  /// shape 도구의 타겟 도형(ShapeTargets). '' 이면 자유 도형(자동 인식),
  /// 'line'/'ellipse'/'rectangle' 이면 드래그 bounding-box 결정적 드로잉.
  late ValueNotifier<String>
  selectedShapeType; // ===== 하위 객체들 (Facade 패턴) =====
  final NotifierRegistry _registry = NotifierRegistry();
  late final StateSynchronizer _synchronizer = StateSynchronizer(_registry);

  late final UndoRedoTracker _undoRedoTracker = UndoRedoTracker(_registry);
  final DrawingSettingsPersistence _persistence =
      DrawingSettingsPersistence(); // ✨ dispose 상태 추적 (위젯 생명주기 오류 방지)
  bool _isDisposed = false;

  /// 🖊️ 필기 활동(획 시작) 틱 (재초기화 가능).
  late ValueNotifier<int> _drawingActivityNotifier;

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

  /// Undo 가능 여부 실시간 추적 ValueNotifier
  ValueNotifier<bool> get canUndoNotifier => _undoRedoTracker.canUndoNotifier;

  /// Redo 가능 여부 실시간 추적 ValueNotifier
  ValueNotifier<bool> get canRedoNotifier => _undoRedoTracker.canRedoNotifier;

  /// 🖊️ 필기 활동(실제 사용자 획) 틱. [markDrawingActivity]()(pointer-down)마다
  /// 증가한다.
  ///
  /// `canUndoNotifier`/`canRedoNotifier` 는 `ValueNotifier<bool>` 이라 값이 실제로
  /// 바뀔 때만 알림한다 → 이미 히스토리가 있는 레이어(canUndo 가 이미 true)에서
  /// 연속 획을 그으면 edge 가 없어 "필기 활동"을 감지할 수 없다. "사용자가 그리는
  /// 중" UI(예: Undo/Redo pill auto-hide)는 이 틱을 구독하면 boolean edge 유무와
  /// 무관하게 매 획을 활동으로 인식할 수 있다. 페이지/탭 전환(프로그램적 활성
  /// 컨트롤러 설정)은 활동으로 치지 않는다(#7496).
  ValueNotifier<int> get drawingActivityNotifier => _drawingActivityNotifier;

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

  /// 🖊️ 필기 활동(실제 사용자 획) 신호. `pointer_event_handler` 의 pointer-down
  /// 에서만 호출해야 한다.
  ///
  /// ⚠️ [setLastActiveScribbleNotifier] 는 사용자 획뿐 아니라 페이지/탭 전환 시
  /// 캐시 매니저의 활성 컨트롤러 설정(`ScribbleCacheManager.setActiveController`)
  /// 에서도 호출된다. 활동 틱을 그 안에서 bump 하면 페이지 이동만으로도 활동으로
  /// 오인되어 "그리는 중" UI 가 깜빡인다(kobic #7496). 따라서 활동 틱은 실제
  /// pointer-down 경로에서만 이 메서드로 명시 발화한다.
  void markDrawingActivity() {
    if (!_isDisposed) _drawingActivityNotifier.value++;
  }

  /// 🎯 마지막 활성 ScribbleNotifier 설정 (필기 시작 / 페이지·탭 전환 시 호출)
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

  /// ↩️ 활성 notifier에 undo를 위임하고 버튼 상태를 갱신한다.
  ///
  /// UndoRedoTracker는 notifier를 listen하지 않으므로, notifier 메서드를
  /// 직접 호출하면 canUndo/canRedo 버튼 상태가 갱신되지 않는다.
  /// 툴바류 UI는 반드시 이 파사드를 사용한다.
  void undo() {
    final notifier = lastActiveScribbleNotifier;
    if (notifier != null && notifier.canUndo) {
      notifier.undo();
    }
    updateUndoRedoState();
  }

  /// ↪️ 활성 notifier에 redo를 위임하고 버튼 상태를 갱신한다.
  void redo() {
    final notifier = lastActiveScribbleNotifier;
    if (notifier != null && notifier.canRedo) {
      notifier.redo();
    }
    updateUndoRedoState();
  }

  /// 🗑️ 활성 notifier의 전체 지우기를 위임하고 버튼 상태를 갱신한다.
  void clearActive() {
    lastActiveScribbleNotifier?.clear();
    updateUndoRedoState();
  }

  /// 🔔 Undo/Redo 상태 변경 콜백 등록
  void registerUndoRedoUpdateCallback(VoidCallback callback) {
    canUndoNotifier.addListener(callback);
    canRedoNotifier.addListener(callback);
  }

  /// 🔔 Undo/Redo 상태 변경 콜백 해제
  void unregisterUndoRedoUpdateCallback(VoidCallback callback) {
    canUndoNotifier.removeListener(callback);
    canRedoNotifier.removeListener(callback);
  }

  /// 🎯 현재 상태를 특정 modeNotifier에 적용
  void applyToModeNotifier(ScribbleModeNotifier modeNotifier) {
    _synchronizer.applyToModeNotifier(
      modeNotifier,
      pointerMode: pointerMode,
      selectedTool: selectedTool,
      selectedColor: selectedColor,
      selectedThickness: selectedThickness,
      selectedShapeType: selectedShapeType,
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
    selectedShapeType = ValueNotifier('');

    // 🖊️ 필기 활동(획 시작) 틱 초기화
    _drawingActivityNotifier = ValueNotifier(0);

    // 🎯 활성 ScribbleNotifier 관리 ValueNotifier들 초기화
    final activeScribbleNotifierNotifier = ValueNotifier<ScribbleNotifier?>(
      null,
    );
    final canUndoNotifier = ValueNotifier(false);
    final canRedoNotifier = ValueNotifier(false);

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
      selectedShapeType: selectedShapeType,
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
