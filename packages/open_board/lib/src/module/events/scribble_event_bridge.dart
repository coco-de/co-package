import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/scribble_controller.dart';

/// ScribbleNotifier 상태 변경을 감지하여 [ScribbleBookEvent]로 변환
///
/// [ScribbleBookController]의 활성 페이지 Notifier를 감시하며,
/// 이전/현재 스트로크 목록의 diff를 통해 추가/삭제 이벤트를 자동 발행한다.
///
/// ```dart
/// final bridge = ScribbleEventBridge(bookController);
/// bridge.attach();
/// // ... 필기 작업 ...
/// bridge.detach();
/// ```
class ScribbleEventBridge {
  final ScribbleBookController _bookController;

  /// 페이지별 이전 스트로크 목록 스냅샷 (protobuf 객체 참조 보관)
  ///
  /// 스트로크 '수'만 추적하면 (1) 중간 스트로크가 지워져도 항상 마지막
  /// 인덱스를 StrokeRemovedEvent로 발행해 리플레이/원격에서 엉뚱한
  /// 스트로크가 삭제되고, (2) 도형 인식·올가미 교체처럼 개수가 같은
  /// 내용 변경은 이벤트가 아예 누락된다.
  final Map<String, List<Stroke>> _previousStrokes = {};

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
    _previousStrokes.clear();
  }

  /// 현재 활성 페이지의 ScribbleController를 감시
  void _watchCurrentPage() {
    final controller = _bookController.activeController;
    final pageId = _bookController.currentPageId;

    // 초기 스트로크 목록 스냅샷 기록
    _previousStrokes[pageId] = List<Stroke>.of(
      controller.currentScribble.strokes,
    );

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
    final current = controller.currentScribble.strokes;
    final previous = _previousStrokes[pageId] ?? const <Stroke>[];

    final (removedIndices, addedIndices) = _diffStrokes(previous, current);
    if (removedIndices.isEmpty && addedIndices.isEmpty) return;

    // 제거는 원본 인덱스 내림차순으로 발행 — 소비 측이 순차 적용해도
    // 인덱스 시프트 없이 정확한 스트로크가 제거된다.
    for (final index in removedIndices.reversed) {
      _bookController.emitEvent(
        StrokeRemovedEvent(
          pageId: pageId,
          strokeIndex: index,
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );
    }
    // 추가는 현재 인덱스 오름차순으로 발행
    for (final index in addedIndices) {
      _bookController.emitEvent(
        StrokeAddedEvent(
          pageId: pageId,
          stroke: current[index],
          strokeIndex: index,
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );
    }

    _previousStrokes[pageId] = List<Stroke>.of(current);
  }

  /// 이전/현재 스트로크 목록의 순서 보존 diff
  ///
  /// 스트로크 목록 연산(추가/지우개 삭제/도형 교체)은 모두 순서를
  /// 보존하므로 greedy 매칭으로 충분하다. protobuf GeneratedMessage의
  /// `==`는 identical 단락 후 deep equality라 변경되지 않은 스트로크는
  /// 참조 비교로 빠르게 매칭된다.
  ///
  /// Returns: (previous 기준 제거 인덱스 오름차순, current 기준 추가 인덱스 오름차순)
  static (List<int>, List<int>) _diffStrokes(
    List<Stroke> previous,
    List<Stroke> current,
  ) {
    final removed = <int>[];
    final added = <int>[];
    var i = 0;
    var j = 0;

    while (i < previous.length || j < current.length) {
      if (i < previous.length &&
          j < current.length &&
          previous[i] == current[j]) {
        i++;
        j++;
      } else if (i < previous.length &&
          (j >= current.length ||
              !current.skip(j).any((s) => s == previous[i]))) {
        // previous[i]가 current 잔여 구간에 없음 → 제거된 스트로크
        removed.add(i);
        i++;
      } else if (j < current.length) {
        // current[j]가 새로 등장 → 추가된 스트로크
        added.add(j);
        j++;
      } else {
        break;
      }
    }

    return (removed, added);
  }
}
