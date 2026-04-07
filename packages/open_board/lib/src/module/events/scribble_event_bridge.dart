import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/scribble_controller.dart';

/// ScribbleNotifier 상태 변경을 감지하여 [ScribbleBookEvent]로 변환
///
/// [ScribbleBookController]의 활성 페이지 Notifier를 감시하며,
/// 스트로크 수 변화를 통해 추가/삭제 이벤트를 자동 발행한다.
///
/// ```dart
/// final bridge = ScribbleEventBridge(bookController);
/// bridge.attach();
/// // ... 필기 작업 ...
/// bridge.detach();
/// ```
class ScribbleEventBridge {
  final ScribbleBookController _bookController;

  /// 페이지별 이전 스트로크 수 추적
  final Map<String, int> _previousStrokeCounts = {};

  /// 현재 감시 중인 컨트롤러 및 리스너
  ScribbleController? _activeController;
  VoidCallback? _activeListener;

  /// 페이지 전환 구독
  StreamSubscription<PageChangeEvent>? _pageChangeSubscription;

  /// attach 상태
  bool _isAttached = false;

  ScribbleEventBridge(this._bookController);

  /// attach 상태 여부
  bool get isAttached => _isAttached;

  /// 현재 활성 페이지의 Notifier 감시 시작
  ///
  /// [ScribbleBookController.startRecording]을 호출하지 않으므로,
  /// 녹화가 필요한 경우 외부에서 별도로 호출해야 한다.
  void attach() {
    if (_isAttached) return;
    _isAttached = true;

    // 초기 페이지 감시 시작
    _watchCurrentPage();

    // 페이지 전환 시 리스너 교체
    _pageChangeSubscription = _bookController.onPageChanged.listen((_) {
      _unwatchCurrentPage();
      _watchCurrentPage();
    });
  }

  /// 모든 리스너 해제
  void detach() {
    if (!_isAttached) return;
    _isAttached = false;

    _pageChangeSubscription?.cancel();
    _pageChangeSubscription = null;
    _unwatchCurrentPage();
    _previousStrokeCounts.clear();
  }

  /// 현재 활성 페이지의 ScribbleController를 감시
  void _watchCurrentPage() {
    final controller = _bookController.activeController;
    final pageId = _bookController.currentPageId;

    // 초기 스트로크 수 기록
    _previousStrokeCounts[pageId] = controller.currentScribble.strokes.length;

    _activeController = controller;
    _activeListener = () => _onScribbleStateChanged(pageId, controller);
    controller.scribbleNotifier.addListener(_activeListener!);
  }

  /// 현재 감시 중인 리스너 해제
  void _unwatchCurrentPage() {
    if (_activeController != null && _activeListener != null) {
      _activeController!.scribbleNotifier.removeListener(_activeListener!);
    }
    _activeController = null;
    _activeListener = null;
  }

  /// ScribbleNotifier 상태 변경 콜백
  void _onScribbleStateChanged(
    String pageId,
    ScribbleController controller,
  ) {
    final currentCount = controller.currentScribble.strokes.length;
    final previousCount = _previousStrokeCounts[pageId] ?? 0;

    if (currentCount > previousCount) {
      // 스트로크 추가됨
      for (var i = previousCount; i < currentCount; i++) {
        _bookController.emitEvent(StrokeAddedEvent(
          pageId: pageId,
          stroke: controller.currentScribble.strokes[i],
          strokeIndex: i,
          timestampMicros: ScribbleBookEvent.now(),
        ));
      }
    } else if (currentCount < previousCount) {
      // 스트로크 제거됨 (지우개, undo 등)
      for (var i = previousCount - 1; i >= currentCount; i--) {
        _bookController.emitEvent(StrokeRemovedEvent(
          pageId: pageId,
          strokeIndex: i,
          timestampMicros: ScribbleBookEvent.now(),
        ));
      }
    }

    _previousStrokeCounts[pageId] = currentCount;
  }
}
