import 'package:flutter/foundation.dart';

/// 도구바 핸들 드래그 ↔ 캔버스 stroke 게이트 공유 채널 (G1, kobic #7026).
///
/// 캔버스는 `Listener`(제스처 arena 미참여, 항상 수신)로 포인터를 받기 때문에,
/// 도구바 핸들의 pen-down 이 캔버스에도 도달해 의도치 않은 stroke 가 오발된다.
/// 핸들과 캔버스는 제스처 arena 를 공유하지 않으므로 표준 경합으로 막을 수 없다.
///
/// 본 채널은 `DrawingState` 와 동일한 얇은 싱글톤 패턴으로, 도구바 핸들이
/// 드래그를 시작하면 [isPanelDragging] 을 올리고 캔버스가 이를 구독해 즉시
/// `resetTouch()` + `IgnorePointer` 로 입력을 차단한다.
///
/// 도구바(소비자)는 핸들 `Listener` 의 `onPointerDown` → [setPanelDragging] true,
/// `onPointerUp`/`onPointerCancel`/dispose → false 로 신호만 보낸다(엔진 내부
/// 미접근). 캔버스 차단·복구는 엔진이 책임진다.
class ViewerGestureBus {
  static final ViewerGestureBus _instance = ViewerGestureBus._internal();

  /// 도구바 핸들 드래그 중 여부 — true 면 캔버스 입력이 게이트된다.
  final ValueNotifier<bool> isPanelDragging = ValueNotifier(false);

  /// 싱글톤 인스턴스 반환 (`DrawingState()` 와 동일 패턴).
  factory ViewerGestureBus() => _instance;

  ViewerGestureBus._internal();

  /// 드래그 시작/종료 신호. 동일 값이면 무시(불필요 notify 차단).
  void setPanelDragging({required bool dragging}) {
    if (isPanelDragging.value != dragging) {
      isPanelDragging.value = dragging;
    }
  }

  /// 강제 해제 — 핸들 dispose/롤백 시 stale `true` 잔존 차단.
  void reset() => setPanelDragging(dragging: false);
}
