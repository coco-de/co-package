import 'package:flutter/widgets.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/notifier_registry.dart';

/// Undo/Redo 상태 추적 및 실행을 담당하는 클래스
///
/// NotifierRegistry를 주입받아 lastActive notifier를 조회합니다.
/// DrawingState에 대한 역방향 의존성이 없습니다.
class UndoRedoTracker {
  final NotifierRegistry _registry;

  UndoRedoTracker(this._registry);

  /// Undo/Redo 가능 여부 실시간 추적용 ValueNotifier
  late ValueNotifier<bool> canUndoNotifier;
  late ValueNotifier<bool> canRedoNotifier;

  /// Undo/Redo 후 화면 업데이트 콜백들
  final List<VoidCallback> _undoRedoUpdateCallbacks = [];

  /// dispose 상태 추적 (외부에서 주입)
  bool _isDisposed = false;

  /// ValueNotifier 초기화
  void initialize(
    ValueNotifier<bool> canUndoNotifier,
    ValueNotifier<bool> canRedoNotifier,
  ) {
    this.canUndoNotifier = canUndoNotifier;
    this.canRedoNotifier = canRedoNotifier;
    _undoRedoUpdateCallbacks.clear();
    _isDisposed = false;
  }

  /// dispose 상태 설정
  set isDisposed(bool value) => _isDisposed = value;

  /// Undo 가능 여부
  bool get canUndo => _registry.lastActiveScribbleNotifier?.canUndo ?? false;

  /// Redo 가능 여부
  bool get canRedo => _registry.lastActiveScribbleNotifier?.canRedo ?? false;

  /// Undo/Redo 후 화면 업데이트 콜백 등록
  void registerUndoRedoUpdateCallback(VoidCallback callback) {
    _undoRedoUpdateCallbacks.add(callback);
  }

  /// Undo/Redo 후 화면 업데이트 콜백 해제
  void unregisterUndoRedoUpdateCallback(VoidCallback callback) {
    _undoRedoUpdateCallbacks.remove(callback);
  }

  /// Undo/Redo 가능 여부 상태 업데이트 (public)
  void updateUndoRedoState() {
    _updateUndoRedoState();
  }

  /// Undo/Redo 가능 여부 상태 업데이트 (private)
  void _updateUndoRedoState() {
    if (_isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;

      try {
        final activeNotifier = _registry.lastActiveScribbleNotifier;

        if (activeNotifier == null) {
          if (canUndoNotifier.value != false) {
            canUndoNotifier.value = false;
          }
          if (canRedoNotifier.value != false) {
            canRedoNotifier.value = false;
          }
          return;
        }

        final newCanUndo = activeNotifier.canUndo;
        final newCanRedo = activeNotifier.canRedo;

        if (canUndoNotifier.value != newCanUndo) {
          canUndoNotifier.value = newCanUndo;
        }

        if (canRedoNotifier.value != newCanRedo) {
          canRedoNotifier.value = newCanRedo;
        }
      } on Exception {
        if (!_isDisposed) {
          if (canUndoNotifier.value != false) {
            canUndoNotifier.value = false;
          }
          if (canRedoNotifier.value != false) {
            canRedoNotifier.value = false;
          }
        }
      }
    });
  }

  /// Undo 실행
  void undo() {
    if (_registry.lastActiveScribbleNotifier?.canUndo ?? false) {
      _registry.lastActiveScribbleNotifier!.undo();
      _updateUndoRedoState();
      _triggerUndoRedoUpdate();
    }
  }

  /// Redo 실행
  void redo() {
    if (_registry.lastActiveScribbleNotifier?.canRedo ?? false) {
      _registry.lastActiveScribbleNotifier!.redo();
      _updateUndoRedoState();
      _triggerUndoRedoUpdate();
    }
  }

  /// 모든 등록된 콜백으로 화면 업데이트 트리거
  void _triggerUndoRedoUpdate() {
    for (final callback in _undoRedoUpdateCallbacks) {
      try {
        callback();
      } on Exception {
        // 콜백 실행 실패 시 무시
      }
    }
  }

  /// 모든 리소스 정리
  void clear() {
    _undoRedoUpdateCallbacks.clear();
  }
}
