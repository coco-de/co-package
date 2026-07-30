import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

/// pointer-down 이 지연 시작(defer) 대상으로 보류된 스트로크 후보 (kobic UB-188).
///
/// [ScribbleWidget.shouldDeferDrawStart] 가 true 를 반환한 down 이벤트는
/// activeLine 을 즉시 생성하지 않고 이 값으로 버퍼링된다. promote 되면
/// [downEvent] 로 그리기를 시작한 뒤 [bufferedMoves] 를 순서대로 재생한다.
class PendingDeferredStroke {
  PendingDeferredStroke({required this.downEvent});

  /// 보류를 시작시킨 원본 pointer-down 이벤트. promote 시 이 이벤트로
  /// activeLine 의 첫 점/시작 시각을 결정해, 사용자가 실제로 누른 지점과
  /// 시각을 그대로 반영한다 (진짜 down 시점보다 늦게 시작된 것처럼 보이지
  /// 않도록).
  final PointerDownEvent downEvent;

  /// 보류 중 도착한 move 이벤트. slop 초과로 promote 되면 이 순서 그대로
  /// [PointerEventHandler.handlePointerMove] 에 재생해, 버퍼링 중에도
  /// 이동 경로를 그대로 복원한다.
  final List<PointerMoveEvent> bufferedMoves = <PointerMoveEvent>[];
}

/// 포인터 이벤트 처리를 담당하는 핸들러 클래스
class PointerEventHandler {
  static const Duration kTouchDelay = Duration(milliseconds: 30);

  /// 지연 시작(deferred start) 판정 임계값 (kobic UB-188).
  ///
  /// pointer-down 이 [ScribbleWidget.shouldDeferDrawStart] 에 의해 보류되면,
  /// 이동이 이 거리(논리 픽셀)를 넘거나 [kDeferStartTimeout] 이 경과할
  /// 때까지 실제 activeLine 을 생성하지 않는다. 두 값 모두 도달하기 전에
  /// pointer-up/cancel 이 오면 아무 것도 그리지 않은 채 폐기(discard)한다.
  ///
  /// ⚠️ 호스트 앱(kobic)의 탭 판정 임계값과 반드시 같은 값을 유지할 것 —
  /// 두 레이어가 "이것이 탭이었는가"를 각자 독립적으로 판정하므로, 값이
  /// 어긋나면 한쪽은 탭으로 다른 쪽은 드래그로 판정하는 모순이 생긴다
  /// (kobic `_PdfLinkTapListener._tapMaxDistance`/`_tapMaxDuration` 참조).
  static const double kDeferStartSlop = 15;

  /// 위 [kDeferStartSlop] 과 짝을 이루는 시간 임계값. 이동 없이 이 시간이
  /// 지나면 "정지된 채 오래 누름"으로 보고 그리기를 승격한다 — 짧은 탭은
  /// 폐기하되, 의도적인 장시간 정지 필기(점 찍기)는 기존과 동일하게
  /// 보존하기 위함이다.
  static const Duration kDeferStartTimeout = Duration(milliseconds: 300);
  final ScribbleNotifier scribbleNotifier;
  final ScribbleModeNotifier modeNotifier;
  final VoidCallback onStateChanged;
  final Function(ScribbleNotifier) onScribble;
  final TransformationController? transformationController;

  final Function(ScribbleNotifier) onScribbleFinished; // 터치 관련 상태
  int _activeTouchCount = 0;
  bool _isDragging = false;

  ui.PointerDeviceKind? _currentPointerKind;

  /// 🖐️ 팜 리젝션(kobic UB-219): 손모드 필기가 이미 진행 중일 때 도착한 추가
  /// 터치 포인터 id 집합. 의도적 두 손가락 핀치줌과 구분하기 위해, 필기 중
  /// 우연히 닿은 팜/보조손가락으로 판정된 포인터를 여기 등록하고
  /// [isEffectiveMultiTouch] 판정에서 제외한다.
  final Set<int> _palmIgnoredPointers = <int>{};

  /// 지연 시작 보류 중인 스트로크 (kobic UB-188). 한 번에 하나만 보류할 수
  /// 있다 — 두 손가락이 동시에 링크 위를 누르는 것은 지원 대상이 아니다.
  PendingDeferredStroke? _pendingDeferredStroke;

  /// [_pendingDeferredStroke] 의 [kDeferStartTimeout] 타임아웃 타이머.
  /// promote/discard 로 보류가 먼저 해소되면 반드시 취소한다 — 취소하지
  /// 않으면 widget 테스트의 "dispose 후 pending timer 없음" 불변식을
  /// 위반하고, 실제 앱에서도 이미 끝난 제스처에 대한 콜백이 불필요하게
  /// 예약된 채로 남는다.
  Timer? _pendingDeferredTimeoutTimer;

  PointerEventHandler({
    required this.scribbleNotifier,
    required this.modeNotifier,
    required this.onStateChanged,
    required this.onScribble,
    required this.onScribbleFinished,
    this.transformationController,
  });

  bool get isDragging => _isDragging;
  set isDragging(bool value) {
    _isDragging = value;
    onStateChanged();
  }

  ui.PointerDeviceKind? get currentPointerKind => _currentPointerKind;

  /// 현재 화면에 닿아 있는 하드웨어 터치 포인터 수 (kobic UB-219 2차).
  ///
  /// 새 down 이벤트 처리 전에 "이 down 이전에 다른 터치가 없었는가"를
  /// 판정해 up/cancel 유실로 잔존한 상태(고착)를 자가치유하는 데 쓴다.
  int get activeTouchCount => _activeTouchCount;

  void incrementTouch() => _activeTouchCount++;

  void decrementTouch() =>
      _activeTouchCount = (_activeTouchCount - 1).clamp(0, 10);

  /// 포인터 이벤트를 스케일 조정된 좌표로 변환
  T adjustPointerEvent<T extends PointerEvent>(T event) {
    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    // Transform.scale(1.0) + 페인터 기반 버튼은 화면 좌표계에서 동작

    // 변환 없이 원본 이벤트 반환
    return event;
  }

  /// 일반 그리기 모드 처리
  void handleNormalDrawingMode(PointerDownEvent event) {
    _currentPointerKind = event.kind;
    isDragging = true;

    // 🎯 필기 시작 시 이 ScribbleNotifier를 활성으로 설정 (undo/redo 대상)
    final drawingState = DrawingState();
    drawingState.setLastActiveScribbleNotifier(scribbleNotifier);

    // 🖊️ 실제 사용자 획 시작 = 필기 활동. 프로그램적 페이지/탭 전환
    // (setActiveController)이 아닌 이 pointer-down 경로에서만 발화한다(#7496).
    drawingState.markDrawingActivity();

    // 🎯 전역 상태를 현재 modeNotifier에 즉시 적용 (도구 상태 동기화)
    drawingState.applyToModeNotifier(modeNotifier);

    // 🔧 ScribbleNotifier 상태 동기화 (modeNotifier 상태 기준)
    // applyToModeNotifier() 호출 후 실제 modeNotifier 상태를 기준으로 ScribbleNotifier 동기화
    final currentInk = modeNotifier.state.inkGroupInfo.selectedInk;

    if (currentInk == 'erase') {
      scribbleNotifier.setEraser();
    } else {
      scribbleNotifier.setStrokeInk();
    }

    // 🎯 Undo/Redo 상태 업데이트
    drawingState.updateUndoRedoState();

    onScribble(scribbleNotifier);

    final adjustedEvent = adjustPointerEvent(event);
    scribbleNotifier.onPointerDown(adjustedEvent, modeNotifier.state);
  }

  /// 포인터 이동 처리
  bool handlePointerMove(PointerMoveEvent event) {
    final adjustedEvent = adjustPointerEvent(event);
    return scribbleNotifier.onPointerUpdate(
      adjustedEvent,
      modeNotifier.state,
    );
  }

  /// 포인터 업 처리
  void handlePointerUp(PointerUpEvent event) {
    isDragging = false;
    _currentPointerKind = null;

    final adjustedEvent = adjustPointerEvent(event);
    scribbleNotifier.onPointerUp(adjustedEvent, modeNotifier.state);
    onScribbleFinished(scribbleNotifier);
  }

  /// 포인터 취소 처리
  ///
  /// 시스템 제스처/팜 리젝션 등으로 포인터가 탈취되면 up 대신 cancel이 온다.
  /// notifier에 전달하지 않으면 activePointerIds에 해당 id가 영구 잔류하여
  /// 이후 해당 페이지에서 터치 필기가 차단된다.
  void handlePointerCancel(PointerCancelEvent event) {
    isDragging = false;
    _currentPointerKind = null;

    final adjustedEvent = adjustPointerEvent(event);
    scribbleNotifier.onPointerCancel(adjustedEvent, modeNotifier.state);
  }

  /// 멀티터치 확인
  bool isMultiTouch() => _activeTouchCount >= 2;

  /// 보류 중인 지연 시작 스트로크가 있는지 여부 (kobic UB-188).
  bool get hasPendingDeferredStroke => _pendingDeferredStroke != null;

  /// 보류 중인 스트로크의 포인터 id. 보류가 없으면 null.
  int? get pendingDeferredPointerId => _pendingDeferredStroke?.downEvent.pointer;

  /// down 시점 실제 그리기를 보류하고 버퍼링을 시작한다 (kobic UB-188).
  ///
  /// 이 호출은 notifier 에 어떤 영향도 주지 않는다 — activeLine 은 아직
  /// 생성되지 않으므로 화면에 아무 것도 그려지지 않는다. [onTimeout] 은
  /// [kDeferStartTimeout] 이 지나도록 이 보류가 promote/discard 되지
  /// 않았을 때 정확히 한 번 호출된다("정지된 채 오래 누름" 승격용).
  ///
  /// 이미 다른 포인터의 보류가 있다면(멀티터치) 그 보류를 먼저 폐기한다 —
  /// 두 손가락이 동시에 링크 위를 누르는 모호한 상황을 그리기로 이어가지
  /// 않기 위함이다.
  void beginDeferredStroke(
    PointerDownEvent event, {
    required VoidCallback onTimeout,
  }) {
    _clearPendingDeferredStroke();
    _pendingDeferredStroke = PendingDeferredStroke(downEvent: event);
    _pendingDeferredTimeoutTimer = Timer(kDeferStartTimeout, () {
      _pendingDeferredTimeoutTimer = null;
      onTimeout();
    });
  }

  /// 보류 상태와 그 타임아웃 타이머를 함께 정리한다 — 스트로크 자체를
  /// 지우지는 않고(호출자가 이미 값을 꺼내갔을 수 있으므로) 참조만 비운다.
  void _clearPendingDeferredStroke() {
    _pendingDeferredStroke = null;
    _pendingDeferredTimeoutTimer?.cancel();
    _pendingDeferredTimeoutTimer = null;
  }

  /// move 이벤트를 보류 버퍼에 추가하거나, slop 초과로 즉시 승격이
  /// 필요함을 판정한다 (kobic UB-188).
  ///
  /// 이 포인터에 대한 보류가 없으면 아무 것도 하지 않고 false 를 반환한다
  /// (호출자는 평소처럼 [handlePointerMove] 를 그대로 사용하면 된다).
  /// 반환값 true 는 호출자가 [takePendingDeferredStroke] 로 즉시 promote
  /// 처리를 수행해야 함을 의미한다 — 이 메서드 자체는 승격을 수행하지
  /// 않는다(실제 그리기 시작에 필요한 `_hideAllOverlays`/`setState` 등은
  /// 위젯 레벨 책임이기 때문).
  bool bufferOrShouldPromoteDeferredMove(PointerMoveEvent event) {
    final pending = _pendingDeferredStroke;
    if (pending == null || pending.downEvent.pointer != event.pointer) {
      return false;
    }
    final delta = event.position - pending.downEvent.position;
    if (delta.distance > kDeferStartSlop) {
      return true;
    }
    pending.bufferedMoves.add(event);
    return false;
  }

  /// 보류 중이던 스트로크를 꺼내고 내부 상태를 비운다 (kobic UB-188).
  ///
  /// 반환값이 null 이면 이 [pointerId] 에 대한 보류가 없던 것 — 호출자는
  /// 평소 경로(즉시 그리기 또는 보류 없음)를 그대로 따르면 된다. non-null
  /// 이면 호출자가 [PendingDeferredStroke.downEvent] 로
  /// [handleNormalDrawingMode] 를 호출해 그리기를 시작(promote)하거나,
  /// 아무 그리기도 하지 않은 채 폐기(discard)해야 한다 — 어느 쪽이든 이
  /// 메서드가 반환한 시점에 내부 보류 상태는 이미 정리되어 있다.
  PendingDeferredStroke? takePendingDeferredStroke(int pointerId) {
    final pending = _pendingDeferredStroke;
    if (pending == null || pending.downEvent.pointer != pointerId) {
      return null;
    }
    _clearPendingDeferredStroke();
    return pending;
  }

  /// 팜으로 무시된 포인터로 등록한다 (kobic UB-219).
  void markPalmIgnored(int pointerId) => _palmIgnoredPointers.add(pointerId);

  /// 팜 무시 등록을 해제한다 (up/cancel 시 카운트 정리용).
  void clearPalmIgnored(int pointerId) =>
      _palmIgnoredPointers.remove(pointerId);

  /// 주어진 포인터가 팜으로 무시된 상태인지 확인한다.
  bool isPalmIgnored(int pointerId) => _palmIgnoredPointers.contains(pointerId);

  /// 팜으로 무시된 포인터를 제외한 실질 동시 터치 수 기준 멀티터치 판정
  /// (kobic UB-219).
  ///
  /// [isMultiTouch] 는 하드웨어 터치 포인터 총합만 세므로, 손모드로 필기
  /// 중 팜/보조손가락이 우연히 닿아도 즉시 true 가 되어 진행 중이던
  /// 스트로크의 갱신(move)과 스크롤 차단이 끊긴다. 이 getter 는
  /// [_palmIgnoredPointers] 를 뺀 "유효" 터치 수로 판정해, 필기 시작 전
  /// 동시에 닿은 진짜 두 손가락 핀치줌은 그대로 인정하면서 필기 중 팜
  /// 접촉만 배제한다.
  bool get isEffectiveMultiTouch =>
      (_activeTouchCount - _palmIgnoredPointers.length) >= 2;

  /// 터치 카운트 초기화
  ///
  /// isScribbleEnable 토글 등으로 up/cancel 핸들러가 끊겨
  /// 카운트가 고착되는 것을 복구할 때 사용한다.
  void resetTouch() {
    _activeTouchCount = 0;
    _palmIgnoredPointers.clear();
    _clearPendingDeferredStroke();
  }

  void dispose() {
    _activeTouchCount = 0;
    _isDragging = false;
    _currentPointerKind = null;
    _palmIgnoredPointers.clear();
    // 보류 중이던 지연 시작 스트로크와 그 타임아웃 타이머도 정리한다
    // (kobic UB-188) — 취소하지 않으면 dispose 후에도 타이머가 남아
    // 위젯 테스트의 pending-timer 불변식을 위반한다.
    _clearPendingDeferredStroke();
  }
}
