import 'dart:async';

import 'package:fixnum/fixnum.dart';

import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';

/// eventStream에서 이벤트를 수집하여 [ScribbleTimeline] 생성
///
/// [ScribbleBookController.eventStream]을 구독하고,
/// 이벤트를 타임라인 형태로 축적한 뒤 [stop]으로 결과를 반환한다.
///
/// ```dart
/// final recorder = ScribbleTimelineRecorder(
///   contentId: 'book123',
///   pageIds: ['page1', 'page2'],
/// );
/// recorder.start(bookController.eventStream);
/// // ... 필기 작업 ...
/// final timeline = recorder.stop();
/// await TimelineFile.write('session.obt', timeline);
/// ```
class ScribbleTimelineRecorder {
  /// 스냅샷 생성 간격 (30초)
  static const int snapshotIntervalMicros = 30 * 1000000;
  final String contentId;

  final List<String> pageIds;
  final List<TimelineEvent> _events = [];

  final List<TimelineSnapshot> _snapshots = [];
  int _startTimestamp = 0;
  int _lastSnapshotOffset = 0;

  StreamSubscription<ScribbleBookEvent>? _subscription;

  /// 현재 페이지별 스트로크 수 추적 (스냅샷용)
  final Map<String, int> _pageStrokeCounts = {};

  /// 현재 활성 페이지 인덱스
  int _activePageIndex = 0;

  /// 녹화 상태
  bool _isRecording = false;

  ScribbleTimelineRecorder({
    required this.contentId,
    required this.pageIds,
  }) {
    for (final pageId in pageIds) {
      _pageStrokeCounts[pageId] = 0;
    }
  }

  /// 녹화 중인지 여부
  bool get isRecording => _isRecording;

  /// 수집된 이벤트 수
  int get eventCount => _events.length;

  /// eventStream 구독 시작
  void start(Stream<ScribbleBookEvent> eventStream) {
    if (_isRecording) return;
    _isRecording = true;
    _startTimestamp = ScribbleBookEvent.now();
    _captureSnapshot(0);
    _subscription = eventStream.listen(_onEvent);
  }

  /// 녹화 종료 → [ScribbleTimeline] 반환
  ScribbleTimeline stop() {
    _subscription?.cancel();
    _subscription = null;
    _isRecording = false;

    return ScribbleTimeline(
      contentId: contentId,
      startTimestamp: Int64(_startTimestamp),
      endTimestamp: Int64(ScribbleBookEvent.now()),
      version: '1.0.0',
      pageIds: List.of(pageIds),
      events: List.of(_events),
      snapshots: List.of(_snapshots),
    );
  }

  /// 녹화 종료 후 .obt 파일로 저장
  Future<ScribbleTimeline> stopAndSave(String path) async {
    final timeline = stop();
    await TimelineFile.write(path, timeline);
    return timeline;
  }

  /// 이벤트 처리
  void _onEvent(ScribbleBookEvent event) {
    final offset = event.timestampMicros - _startTimestamp;

    _events.add(_convertToTimelineEvent(event));
    _updateTracking(event);

    // 스냅샷 간격 체크
    if (offset - _lastSnapshotOffset >= snapshotIntervalMicros) {
      _captureSnapshot(offset);
      _lastSnapshotOffset = offset;
    }
  }

  /// ScribbleBookEvent → TimelineEvent 변환
  TimelineEvent _convertToTimelineEvent(ScribbleBookEvent event) {
    final timestamp = Int64(event.timestampMicros);

    final data = switch (event) {
      PageChangedEvent(
        :final fromIndex,
        :final toIndex,
        :final fromPageId,
        :final toPageId,
      ) =>
        TlPageChanged(
          fromIndex: fromIndex,
          toIndex: toIndex,
          fromPageId: fromPageId,
          toPageId: toPageId,
        ),
      StrokeAddedEvent(:final pageId, :final strokeIndex) => TlStrokeAdded(
        pageId: pageId,
        strokeIndex: strokeIndex,
      ),
      StrokeRemovedEvent(:final pageId, :final strokeIndex) => TlStrokeRemoved(
        pageId: pageId,
        strokeIndex: strokeIndex,
      ),
      UndoPerformedEvent(:final pageId) => TlUndo(pageId: pageId),
      RedoPerformedEvent(:final pageId) => TlRedo(pageId: pageId),
      PageAddedEvent(:final pageId, :final atIndex) => TlPageAdded(
        pageId: pageId,
        atIndex: atIndex,
      ),
      PageRemovedEvent(:final pageId, :final atIndex) => TlPageRemoved(
        pageId: pageId,
        atIndex: atIndex,
      ),
      PageClearedEvent(:final pageId) => TlPageCleared(pageId: pageId),
      DoublePageToggledEvent() =>
        // DoublePageToggled는 타임라인에 기록하지 않음 (UI 전용)
        // 빈 PageChanged로 대체
        TlPageChanged(
          fromIndex: _activePageIndex,
          toIndex: _activePageIndex,
          fromPageId: pageIds.elementAtOrNull(_activePageIndex) ?? '',
          toPageId: pageIds.elementAtOrNull(_activePageIndex) ?? '',
        ),
      ViewportChangedEvent(:final pageId, :final scale, :final centerX,
          :final centerY, :final viewportWidth, :final viewportHeight) =>
        TlViewportChanged(
          pageId: pageId,
          scale: scale,
          centerX: centerX,
          centerY: centerY,
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
        ),
      SessionParticipantEvent(:final participantId, :final displayName,
          :final role, :final action) =>
        TlSessionParticipant(
          participantId: participantId,
          displayName: displayName,
          role: role.name,
          action: action.name,
        ),
    };

    return TimelineEvent(timestamp: timestamp, event: data);
  }

  /// 이벤트 기반 내부 상태 업데이트
  void _updateTracking(ScribbleBookEvent event) {
    switch (event) {
      case PageChangedEvent(:final toIndex):
        _activePageIndex = toIndex;
      case StrokeAddedEvent(:final pageId):
        _pageStrokeCounts[pageId] = (_pageStrokeCounts[pageId] ?? 0) + 1;
      case StrokeRemovedEvent(:final pageId):
        final count = _pageStrokeCounts[pageId] ?? 0;
        if (count > 0) _pageStrokeCounts[pageId] = count - 1;
      case PageClearedEvent(:final pageId):
        _pageStrokeCounts[pageId] = 0;
      case PageAddedEvent(:final pageId):
        _pageStrokeCounts[pageId] = 0;
      case PageRemovedEvent(:final pageId):
        _pageStrokeCounts.remove(pageId);
      case UndoPerformedEvent():
      case RedoPerformedEvent():
      case DoublePageToggledEvent():
      case ViewportChangedEvent():
      case SessionParticipantEvent():
        break;
    }
  }

  /// 현재 상태 스냅샷 캡처
  void _captureSnapshot(int offsetMicros) {
    _snapshots.add(
      TimelineSnapshot(
        offsetMicros: Int64(offsetMicros),
        activePageIndex: _activePageIndex,
        pageStrokeCounts: Map.of(_pageStrokeCounts),
      ),
    );
  }
}
