  import 'package:flutter/widgets.dart';
  import 'package:open_board/src/module/state/notifier_registry.dart';

  /// Undo/Redo 상태 추적 및 실행을 담당하는 클래스
  ///
  /// NotifierRegistry를 주입받아 lastActive notifier를 조회합니다.
  /// DrawingState에 대한 역방향 의존성이 없습니다.
  class UndoRedoTracker {
    /// Undo/Redo 가능 여부 실시간 추적용 ValueNotifier
    late ValueNotifier<bool> canUndoNotifier;

    late ValueNotifier<bool> canRedoNotifier;

    final NotifierRegistry _registry;

    /// dispose 상태 추적 (외부에서 주입)
    bool _isDisposed = false;

    UndoRedoTracker(this._registry);

    /// ValueNotifier 초기화
    void initialize(
      ValueNotifier<bool> canUndoNotifier,
      ValueNotifier<bool> canRedoNotifier,
    ) {
      this.canUndoNotifier = canUndoNotifier;
      this.canRedoNotifier = canRedoNotifier;
      _isDisposed = false;
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
  }
