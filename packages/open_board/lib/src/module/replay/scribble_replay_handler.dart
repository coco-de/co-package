import 'dart:async';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/replay/scribble_replay_controller.dart';
import 'package:open_board/src/module/replay/stroke_animator.dart';

/// [ScribbleReplayController]의 이벤트를 받아 [ScribbleBookController]에 적용
///
/// 재생 시 발생하는 이벤트에 따라 페이지 전환, 스트로크 렌더링,
/// undo/redo 등을 BookController에 반영한다.
///
/// ```dart
/// final handler = ScribbleReplayHandler(
///   bookController: bookController,
///   pageProvider: cacheManager,
/// );
/// handler.attach(replayController);
/// // ... 재생 ...
/// handler.detach();
/// ```
class ScribbleReplayHandler {
  final ScribbleBookController _bookController;
  final ScribblePageProvider _pageProvider;

  /// 페이지별 로드된 원본 Stroke 캐시 (애니메이션용)
  final Map<String, List<Stroke>> _originalStrokes = {};

  StreamSubscription<ScribbleBookEvent>? _subscription;
  Timer? _animationTimer;

  /// 현재 애니메이션 중인 스트로크 정보
  String? _animatingPageId;
  int? _animatingStrokeIndex;

  /// 연결된 ReplayController (positionMicros 접근용)
  ScribbleReplayController? _replayController;

  /// attach 상태
  bool _isAttached = false;

  ScribbleReplayHandler({
    required ScribbleBookController bookController,
    required ScribblePageProvider pageProvider,
  })  : _bookController = bookController,
        _pageProvider = pageProvider;

  /// attach 상태 여부
  bool get isAttached => _isAttached;

  /// ReplayController의 onEvent 스트림 연결
  void attach(ScribbleReplayController replayController) {
    if (_isAttached) return;
    _isAttached = true;
    _replayController = replayController;
    _subscription = replayController.onEvent.listen(_handleEvent);

    // 16ms 주기로 애니메이션 업데이트 (~60fps)
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateAnimation(),
    );
  }

  /// 모든 리스너/타이머 해제
  void detach() {
    if (!_isAttached) return;
    _isAttached = false;
    _subscription?.cancel();
    _subscription = null;
    _animationTimer?.cancel();
    _animationTimer = null;
    _replayController = null;
    _originalStrokes.clear();
    _animatingPageId = null;
    _animatingStrokeIndex = null;
  }

  /// 이벤트 처리
  void _handleEvent(ScribbleBookEvent event) {
    switch (event) {
      case PageChangedEvent(:final toIndex, :final toPageId):
        _bookController.goToPage(toIndex);
        _ensurePageLoaded(toPageId);
      case StrokeAddedEvent(:final pageId, :final strokeIndex):
        _ensurePageLoaded(pageId);
        _animatingPageId = pageId;
        _animatingStrokeIndex = strokeIndex;
      case StrokeRemovedEvent(:final pageId, :final strokeIndex):
        _removeStrokeFromDisplay(pageId, strokeIndex);
      case UndoPerformedEvent():
        _bookController.activeController.undo();
      case RedoPerformedEvent():
        _bookController.activeController.redo();
      case PageClearedEvent():
        _bookController.activeController.clear();
      case PageAddedEvent(:final pageId, :final atIndex):
        _bookController.addPage(pageId: pageId, atIndex: atIndex);
      case PageRemovedEvent(:final atIndex):
        _bookController.removePage(atIndex);
      case DoublePageToggledEvent():
      case ViewportChangedEvent():
      case SessionParticipantEvent():
        break; // 리플레이 핸들러에서는 무시 (별도 처리)
    }
  }

  /// 애니메이션 프레임 업데이트
  void _updateAnimation() {
    if (_animatingPageId == null || _animatingStrokeIndex == null) return;
    if (_replayController == null) return;

    final strokes = _originalStrokes[_animatingPageId];
    if (strokes == null || _animatingStrokeIndex! >= strokes.length) return;

    final currentTimeMicros = _replayController!.positionMicros;

    // 현재 시각까지의 부분 스트로크 생성
    final displayStrokes = <Stroke>[];
    for (var i = 0; i <= _animatingStrokeIndex!; i++) {
      if (i >= strokes.length) break;
      final partial =
          StrokeAnimator.createPartialStroke(strokes[i], currentTimeMicros);
      if (partial != null) displayStrokes.add(partial);
    }

    if (displayStrokes.isNotEmpty) {
      final scribble = Scribble()..strokes.addAll(displayStrokes);
      _bookController.activeController.loadScribble(scribble);
    }
  }

  /// 표시된 스트로크에서 제거
  void _removeStrokeFromDisplay(String pageId, int strokeIndex) {
    final strokes = _originalStrokes[pageId];
    if (strokes == null || strokeIndex >= strokes.length) return;

    final currentScribble = _bookController.activeController.currentScribble;
    final filtered = <Stroke>[
      for (var i = 0; i < currentScribble.strokes.length; i++)
        if (i != strokeIndex) currentScribble.strokes[i],
    ];

    _bookController.activeController.loadScribble(
      Scribble()..strokes.addAll(filtered),
    );
  }

  /// 페이지의 원본 Stroke 로드 (캐싱)
  Future<void> _ensurePageLoaded(String pageId) async {
    if (_originalStrokes.containsKey(pageId)) return;

    final key = '${_bookController.contentId}/$pageId';
    final scribble = await _pageProvider.loadScribble(key);
    if (scribble != null) {
      _originalStrokes[pageId] = List<Stroke>.from(scribble.strokes);
    }
  }
}
