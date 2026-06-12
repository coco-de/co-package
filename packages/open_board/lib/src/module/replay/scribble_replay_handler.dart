import 'dart:async';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/managers/scribble_cache_manager.dart';
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
  StreamSubscription<void>? _resetSubscription;
  Timer? _animationTimer;

  /// 현재 애니메이션 중인 스트로크 정보
  String? _animatingPageId;
  int? _animatingStrokeIndex;

  /// 연결된 ReplayController (positionMicros 접근용)
  ScribbleReplayController? _replayController;

  /// attach 상태
  bool _isAttached = false;

  /// attach 이전의 자동 저장 상태 (detach 시 복원)
  bool? _previousAutoSaveEnabled;

  ScribbleReplayHandler({
    required ScribbleBookController bookController,
    required ScribblePageProvider pageProvider,
  }) : _bookController = bookController,
       _pageProvider = pageProvider;

  /// attach 상태 여부
  bool get isAttached => _isAttached;

  /// ReplayController의 onEvent 스트림 연결
  void attach(ScribbleReplayController replayController) {
    if (_isAttached) return;
    _isAttached = true;
    _replayController = replayController;
    _subscription = replayController.onEvent.listen(_handleEvent);
    _resetSubscription = replayController.onReset.listen(
      (_) => _resetDisplay(),
    );

    // 🚨 리플레이는 표시 전용 구동 — 영속화를 차단한다.
    // 차단하지 않으면 페이지 전환 이벤트가 리플레이 중간 캔버스를 사용자
    // 원본 .bin에 즉시 저장하고, 페이지 삭제 이벤트가 실제 저장소의
    // 필기 데이터를 영구 삭제한다.
    _bookController.suppressPersistence = true;
    final provider = _pageProvider;
    if (provider is ScribbleCacheManager) {
      _previousAutoSaveEnabled = provider.autoSaveEnabled;
      provider.autoSaveEnabled = false;
    }

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
    _resetSubscription?.cancel();
    _resetSubscription = null;
    _animationTimer?.cancel();
    _animationTimer = null;
    _replayController = null;
    _originalStrokes.clear();
    _animatingPageId = null;
    _animatingStrokeIndex = null;

    // 영속화 차단 해제 (자동 저장 상태 복원)
    _bookController.suppressPersistence = false;
    final provider = _pageProvider;
    if (provider is ScribbleCacheManager && _previousAutoSaveEnabled != null) {
      provider.autoSaveEnabled = _previousAutoSaveEnabled!;
      _previousAutoSaveEnabled = null;
    }
  }

  /// 표시 상태 초기화 (뒤로 seek / 완료 후 재시작)
  ///
  /// 컨트롤러가 인덱스 0부터 이벤트를 재발행하기 전에 호출되어,
  /// 기존 표시 상태 위에 이벤트가 이중 적용되는 것을 막는다.
  void _resetDisplay() {
    _animatingPageId = null;
    _animatingStrokeIndex = null;
    _bookController.activeController.loadScribble(
      Scribble(),
      resetHistory: false,
    );
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

    // StrokeAnimator는 Point.timestamp(절대 epoch 마이크로초)와 비교하므로
    // 상대 오프셋(positionMicros)에 타임라인 시작 시각을 더해 절대 시각으로
    // 변환한다. 상대 값을 그대로 넘기면 항상 첫 포인트 이전으로 판정되어
    // 재생 내내 스트로크가 전혀 렌더링되지 않는다.
    final currentTimeMicros =
        _replayController!.timelineStartMicros +
        _replayController!.positionMicros;

    // 현재 시각까지의 부분 스트로크 생성
    final displayStrokes = <Stroke>[];
    for (var i = 0; i <= _animatingStrokeIndex!; i++) {
      if (i >= strokes.length) break;
      final partial = StrokeAnimator.createPartialStroke(
        strokes[i],
        currentTimeMicros,
      );
      if (partial != null) displayStrokes.add(partial);
    }

    if (displayStrokes.isNotEmpty) {
      final scribble = Scribble()..strokes.addAll(displayStrokes);
      _bookController.activeController.loadScribble(
        scribble,
        resetHistory: false,
      );
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
      resetHistory: false,
    );
  }

  /// 페이지의 원본 Stroke 로드 (캐싱)
  Future<void> _ensurePageLoaded(String pageId) async {
    if (_originalStrokes.containsKey(pageId)) return;

    final key = '${_bookController.contentId}/$pageId';
    final scribble = await _pageProvider.loadScribble(key);
    if (scribble != null) {
      _originalStrokes[pageId] = List<Stroke>.of(scribble.strokes);
    }
  }
}
