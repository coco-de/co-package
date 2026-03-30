import 'package:flutter/foundation.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble.notifier.dart';

/// Notifier 등록/해제/조회를 담당하는 레지스트리
///
/// ScribbleModeNotifier와 ScribbleNotifier의 라이프사이클을 관리합니다.
/// DrawingState에서 분리되어 단일 책임 원칙을 따릅니다.
class NotifierRegistry {
  final Set<ScribbleModeNotifier> _activeModeNotifiers =
      <ScribbleModeNotifier>{};
  final Set<ScribbleNotifier> _activeScribbleNotifiers = <ScribbleNotifier>{};
  ScribbleNotifier? _lastActiveScribbleNotifier;

  /// 활성 ScribbleNotifier 변경 알림용 ValueNotifier
  late ValueNotifier<ScribbleNotifier?> activeScribbleNotifierNotifier;

  /// 현재 활성 ScribbleNotifier (undo/redo 대상)
  ScribbleNotifier? get lastActiveScribbleNotifier =>
      _lastActiveScribbleNotifier;

  /// 모든 활성 modeNotifier들
  Set<ScribbleModeNotifier> get activeModeNotifiers => _activeModeNotifiers;

  /// ValueNotifier 초기화 (DrawingState._initializeNotifiers에서 호출)
  void initialize(
    ValueNotifier<ScribbleNotifier?> activeScribbleNotifierNotifier,
  ) {
    this.activeScribbleNotifierNotifier = activeScribbleNotifierNotifier;
    _activeModeNotifiers.clear();
    _activeScribbleNotifiers.clear();
    _lastActiveScribbleNotifier = null;
  }

  /// ScribbleModeNotifier 등록
  void registerModeNotifier(ScribbleModeNotifier modeNotifier) {
    _activeModeNotifiers.add(modeNotifier);
  }

  /// ScribbleModeNotifier 해제
  void unregisterModeNotifier(ScribbleModeNotifier modeNotifier) {
    _activeModeNotifiers.remove(modeNotifier);
  }

  /// ScribbleNotifier 등록
  void registerScribbleNotifier(ScribbleNotifier scribbleNotifier) {
    _activeScribbleNotifiers.add(scribbleNotifier);
  }

  /// ScribbleNotifier 해제
  ///
  /// [isDisposed] - 상위 DrawingState의 dispose 상태
  /// [onLastActiveCleared] - lastActive가 해제될 때 호출되는 콜백
  void unregisterScribbleNotifier(
    ScribbleNotifier scribbleNotifier, {
    required bool isDisposed,
    required VoidCallback onLastActiveCleared,
  }) {
    _activeScribbleNotifiers.remove(scribbleNotifier);

    if (_lastActiveScribbleNotifier == scribbleNotifier) {
      _lastActiveScribbleNotifier = null;

      if (!isDisposed) {
        activeScribbleNotifierNotifier.value = null;
        onLastActiveCleared();
      }
    }
  }

  /// 마지막 활성 ScribbleNotifier 설정
  ///
  /// [isDisposed] - 상위 DrawingState의 dispose 상태
  /// [onChanged] - lastActive가 변경될 때 호출되는 콜백
  /// 반환값: 실제로 변경되었으면 true
  bool setLastActiveScribbleNotifier(
    ScribbleNotifier scribbleNotifier, {
    required bool isDisposed,
  }) {
    if (isDisposed) {
      debugPrint(
        '⚠️ NotifierRegistry: dispose된 상태로 setLastActiveScribbleNotifier 호출 무시',
      );
      return false;
    }

    final isSame = _lastActiveScribbleNotifier == scribbleNotifier;

    if (!isSame) {
      _lastActiveScribbleNotifier = scribbleNotifier;

      if (!isDisposed) {
        activeScribbleNotifierNotifier.value = scribbleNotifier;
      }
    }

    return !isSame;
  }

  /// ModeNotifier에 해당하는 ScribbleNotifier 찾기
  ScribbleNotifier? findScribbleNotifierForModeNotifier(
    ScribbleModeNotifier modeNotifier,
  ) {
    if (_lastActiveScribbleNotifier != null) {
      return _lastActiveScribbleNotifier;
    }

    if (_activeScribbleNotifiers.isNotEmpty) {
      return _activeScribbleNotifiers.first;
    }

    return null;
  }

}
