import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

/// 포인터 이벤트 처리를 담당하는 핸들러 클래스
class PointerEventHandler {
  static const Duration kTouchDelay = Duration(milliseconds: 30);
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
  }

  void dispose() {
    _activeTouchCount = 0;
    _isDragging = false;
    _currentPointerKind = null;
    _palmIgnoredPointers.clear();
  }
}
