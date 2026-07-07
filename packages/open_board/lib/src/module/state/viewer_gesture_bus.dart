import 'dart:async';

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
/// 도구바(소비자)는 핸들 `Listener` 의 `onPointerDown`/`onPointerMove` →
/// [setPanelDragging] true(watchdog 갱신), `onPointerUp`/`onPointerCancel`/
/// dispose → false 로 신호만 보낸다(엔진 내부 미접근). 캔버스 차단·복구는
/// 엔진이 책임진다.
class ViewerGestureBus {
  /// 유실된 release 신호로 [isPanelDragging] 이 영구 고착되는 것을 막는
  /// 안전망 최대 시간 (kobic UB-213).
  ///
  /// 실제 핸들 드래그 중에는 `onPointerMove` 가 [setPanelDragging] true 를
  /// 반복 호출해 매번 이 watchdog 을 재무장하므로 정상 드래그는 절대
  /// 만료되지 않는다. OS 제스처 충돌(엣지 도킹 위치의 시스템 스와이프 등)이나
  /// 위젯 dispose 타이밍 문제로 `onPointerUp`/`onPointerCancel`/dispose 리셋이
  /// 유실된 경우에만 이 시간 이후 자동 해제된다.
  ///
  /// ⚠️ 트레이드오프(의도됨): 이 최대 시간은 손가락/펜을 뗀 상태를 직접 감지하지
  /// 않고 "마지막 활동(down/move) 이후 경과 시간"만 본다. 따라서 핸들을 누른 채
  /// **한 치의 움직임도 없이**(터치스크린은 보통 미세한 지터로 move 이벤트가
  /// 발생하므로 실사용에서는 드묾) 이 시간을 초과해 정지하면, 그 포인터가 아직
  /// 눌려 있는 상태에서도 게이트가 조기 해제될 수 있다 — "영구 고착"이라는
  /// 치명적 실패를 "드문 경우의 짧은 무방비 창"으로 바꾸는 의도된 절충이다.
  /// 멀티터치(핸들 위 여러 손가락) 추적은 이 값과 무관한 별개의 기존 한계다.
  @visibleForTesting
  static const Duration maxStaleDuration = Duration(seconds: 2);

  static final ViewerGestureBus _instance = ViewerGestureBus._internal();

  /// 도구바 핸들 드래그 중 여부 — true 면 캔버스 입력이 게이트된다.
  final ValueNotifier<bool> isPanelDragging = ValueNotifier(false);

  Timer? _staleWatchdog;

  /// 싱글톤 인스턴스 반환 (`DrawingState()` 와 동일 패턴).
  factory ViewerGestureBus() => _instance;

  ViewerGestureBus._internal();

  /// 드래그 시작/유지/종료 신호. 동일 값이면 notify 는 생략하되, `dragging`이
  /// true 인 모든 호출(down 뿐 아니라 move 포함)은 매번 watchdog 을 재무장한다.
  void setPanelDragging({required bool dragging}) {
    _staleWatchdog?.cancel();
    _staleWatchdog = null;
    if (dragging) {
      _staleWatchdog = Timer(maxStaleDuration, () {
        isPanelDragging.value = false;
      });
    }
    if (isPanelDragging.value != dragging) {
      isPanelDragging.value = dragging;
    }
  }

  /// 강제 해제 — 핸들 dispose/롤백 시 stale `true` 잔존 차단.
  void reset() => setPanelDragging(dragging: false);
}
