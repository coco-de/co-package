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

    final Function(ScribbleNotifier) onScribbleFinished; // 터치 관련 상태
    int _activeTouchCount = 0;
    bool _isDragging = false;

    ui.PointerDeviceKind? _currentPointerKind;

    PointerEventHandler({
      required this.scribbleNotifier,
      required this.modeNotifier,
      required this.onStateChanged,
      required this.onScribble,
      required this.onScribbleFinished,
    });

    bool get isDragging => _isDragging;
    set isDragging(bool value) {
      _isDragging = value;
      onStateChanged();
    }

    ui.PointerDeviceKind? get currentPointerKind => _currentPointerKind;
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

    /// 멀티터치 확인
    bool isMultiTouch() => _activeTouchCount >= 2;

    void dispose() {
      _activeTouchCount = 0;
      _isDragging = false;
      _currentPointerKind = null;
    }
  }
