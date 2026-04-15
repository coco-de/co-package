import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart'
    show Stroke;
import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';

/// 타임라인에서 변환 시 사용하는 빈 Stroke 플레이스홀더
///
/// .obt 타임라인은 Stroke 데이터를 포함하지 않으므로
/// StrokeAddedEvent 변환 시 빈 Stroke를 사용한다.
/// 실제 Stroke 데이터는 [ScribbleReplayHandler]에서 .bin 파일로부터 로드한다.
final Stroke _emptyStroke = Stroke();

/// 필기 리플레이 상태
enum ReplayState {
  /// 초기 상태 (타임라인 미로드)
  idle,

  /// 재생 중
  playing,

  /// 일시 정지
  paused,

  /// 재생 완료
  completed,
}

/// 필기 리플레이 엔진
///
/// [ScribbleBookEvent] 타임라인을 기반으로 필기를 순차 재생합니다.
/// 외부 오디오 플레이어와 동기화할 수 있는 인터페이스를 제공합니다.
///
/// ```dart
/// final replay = ScribbleReplayController();
/// replay.loadTimeline(events);
///
/// // 재생 제어
/// replay.play();
/// replay.pause();
/// replay.seek(Duration(seconds: 30));
/// replay.setSpeed(1.5);
///
/// // 외부 동기화
/// replay.syncTo(audioPlayer.position);
///
/// // 이벤트 처리
/// replay.onEvent.listen((event) {
///   // 이벤트에 따라 ScribbleBookController 조작
/// });
/// ```
class ScribbleReplayController extends ChangeNotifier {
  /// 스냅샷 간격 (마이크로초, 기본 30초)
  static const int _snapshotIntervalMicros = 30 * 1000000;

  /// 이벤트 타임라인 (시간순 정렬)
  List<ScribbleBookEvent> _timeline = [];

  /// 현재 재생 인덱스
  int _currentIndex = 0;

  /// 재생 상태
  ReplayState _state = .idle;

  /// 재생 속도 배율
  double _speed = 1.0;

  /// 타임라인 시작 시각 (마이크로초)
  int _timelineStartMicros = 0;

  /// 재생 시작 wall clock (마이크로초)
  int _playStartWallMicros = 0;

  /// 재생 시작 시점의 타임라인 오프셋 (마이크로초)
  int _playStartOffsetMicros = 0;

  /// 재생 타이머
  Timer? _playTimer;

  /// 스냅샷 체크포인트 (seek 최적화)
  final Map<int, ReplaySnapshot> _snapshots = {};

  /// 이벤트 발행 스트림 (리플레이 시 발생하는 이벤트)
  final StreamController<ScribbleBookEvent> _eventController =
      StreamController<ScribbleBookEvent>.broadcast();

  /// 재생 위치 스트림 (마이크로초 단위, 외부 동기화용)
  final StreamController<int> _positionController =
      StreamController<int>.broadcast();

  /// dispose 여부
  bool _isDisposed = false;

  // ===== 상태 접근자 =====

  /// 현재 재생 상태
  ReplayState get state => _state;

  /// 재생 중 여부
  bool get isPlaying => _state == .playing;

  /// 재생 속도
  double get speed => _speed;

  /// 전체 재생 시간 (마이크로초)
  int get durationMicros {
    if (_timeline.isEmpty) return 0;
    return _timeline.last.timestampMicros - _timelineStartMicros;
  }

  /// 전체 재생 시간 (Duration)
  Duration get duration => .new(microseconds: durationMicros);

  /// 현재 재생 위치 (마이크로초)
  int get positionMicros {
    if (_state == .idle) return 0;
    if (_state == .completed) return durationMicros;
    if (_state == .paused) return _playStartOffsetMicros;

    // playing 상태: wall clock 기반 계산
    final elapsed =
        ((DateTime.now().microsecondsSinceEpoch - _playStartWallMicros) *
                _speed)
            .round();
    return (_playStartOffsetMicros + elapsed).clamp(0, durationMicros);
  }

  /// 현재 재생 위치 (Duration)
  Duration get position => .new(microseconds: positionMicros);

  /// 타임라인 이벤트 수
  int get eventCount => _timeline.length;

  /// 현재 재생 인덱스
  int get currentIndex => _currentIndex;

  /// 리플레이 이벤트 스트림
  Stream<ScribbleBookEvent> get onEvent => _eventController.stream;

  /// 재생 위치 스트림 (마이크로초)
  Stream<int> get onPositionChanged => _positionController.stream;

  // ===== 타임라인 로드 =====

  /// 이벤트 타임라인 로드
  ///
  /// 타임라인은 타임스탬프 기준 오름차순으로 정렬됩니다.
  void loadTimeline(List<ScribbleBookEvent> events) {
    _stop();

    _timeline = List<ScribbleBookEvent>.of(events)
      ..sort(
        (a, b) => a.timestampMicros.compareTo(b.timestampMicros),
      );

    _currentIndex = 0;
    _state = _timeline.isEmpty ? .idle : .paused;
    _timelineStartMicros = _timeline.isEmpty
        ? 0
        : _timeline.first.timestampMicros;
    _playStartOffsetMicros = 0;

    // 스냅샷 생성
    _buildSnapshots();

    notifyListeners();
  }

  /// [ScribbleTimeline]에서 타임라인 로드 (.obt 데이터)
  ///
  /// [ScribbleTimeline]의 이벤트를 [ScribbleBookEvent]로 변환 후 로드한다.
  void loadFromTimeline(ScribbleTimeline timeline) {
    final events = timeline.events.map(_convertFromTimelineEvent).toList();
    loadTimeline(events);
  }

  /// .obt 파일에서 타임라인 로드
  ///
  /// [TimelineFile.read]로 파일을 읽고 [loadFromTimeline]으로 로드한다.
  /// Throws [FormatException] if file is invalid.
  Future<void> loadFromFile(String path) async {
    final timeline = await TimelineFile.read(path);
    loadFromTimeline(timeline);
  }

  // ===== 재생 제어 =====

  /// 재생 시작/재개
  void play() {
    if (_timeline.isEmpty) return;
    if (_state == .completed) {
      // 완료 상태에서 play → 처음부터 재생
      _currentIndex = 0;
      _playStartOffsetMicros = 0;
    }

    _state = .playing;
    _playStartWallMicros = DateTime.now().microsecondsSinceEpoch;

    _startPlayTimer();
    notifyListeners();
  }

  /// 일시 정지
  void pause() {
    if (_state != .playing) return;

    _playStartOffsetMicros = positionMicros;
    _state = .paused;
    _playTimer?.cancel();

    notifyListeners();
  }

  /// 특정 위치로 이동
  void seek(Duration position) {
    final targetMicros = position.inMicroseconds.clamp(0, durationMicros);

    // 가장 가까운 스냅샷 찾기
    final snapshotEntry = _findNearestSnapshot(targetMicros);

    _currentIndex = snapshotEntry != null
        ? snapshotEntry.value.eventIndex
        : 0; // 스냅샷 이후 ~ 목표 위치까지 이벤트 빠르게 발행
    _fastForwardTo(targetMicros);

    _playStartOffsetMicros = targetMicros;

    if (_state == .playing) {
      _playStartWallMicros = DateTime.now().microsecondsSinceEpoch;
      _startPlayTimer();
    }

    _positionController.add(targetMicros);
    notifyListeners();
  }

  /// 재생 속도 변경
  void setSpeed(double speed) {
    assert(speed > 0, 'Speed must be positive');

    if (_state == .playing) {
      _playStartOffsetMicros = positionMicros;
      _playStartWallMicros = DateTime.now().microsecondsSinceEpoch;
    }

    _speed = speed;

    if (_state == .playing) {
      _startPlayTimer();
    }

    notifyListeners();
  }

  /// 외부(오디오 플레이어)에서 위치 동기화
  void syncTo(Duration position) {
    seek(position);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _playTimer?.cancel();
    _eventController.close();
    _positionController.close();
    super.dispose();
  }

  /// [TimelineEvent] → [ScribbleBookEvent] 변환
  ScribbleBookEvent _convertFromTimelineEvent(TimelineEvent tlEvent) {
    final timestampMicros = tlEvent.timestamp.toInt();

    return switch (tlEvent.event) {
      TlPageChanged(
        :final fromIndex,
        :final toIndex,
        :final fromPageId,
        :final toPageId,
      ) =>
        PageChangedEvent(
          fromIndex: fromIndex,
          toIndex: toIndex,
          fromPageId: fromPageId,
          toPageId: toPageId,
          timestampMicros: timestampMicros,
        ),
      TlStrokeAdded(:final pageId, :final strokeIndex) => StrokeAddedEvent(
        pageId: pageId,
        stroke: _emptyStroke,
        strokeIndex: strokeIndex,
        timestampMicros: timestampMicros,
      ),
      TlStrokeRemoved(:final pageId, :final strokeIndex) => StrokeRemovedEvent(
        pageId: pageId,
        strokeIndex: strokeIndex,
        timestampMicros: timestampMicros,
      ),
      TlUndo(:final pageId) => UndoPerformedEvent(
        pageId: pageId,
        timestampMicros: timestampMicros,
      ),
      TlRedo(:final pageId) => RedoPerformedEvent(
        pageId: pageId,
        timestampMicros: timestampMicros,
      ),
      TlPageAdded(:final pageId, :final atIndex) => PageAddedEvent(
        pageId: pageId,
        atIndex: atIndex,
        timestampMicros: timestampMicros,
      ),
      TlPageRemoved(:final pageId, :final atIndex) => PageRemovedEvent(
        pageId: pageId,
        atIndex: atIndex,
        timestampMicros: timestampMicros,
      ),
      TlPageCleared(:final pageId) => PageClearedEvent(
        pageId: pageId,
        timestampMicros: timestampMicros,
      ),
    };
  }

  // ===== 내부 메서드 =====

  void _stop() {
    _playTimer?.cancel();
    _state = .idle;
    _currentIndex = 0;
    _playStartOffsetMicros = 0;
    _snapshots.clear();
  }

  void _startPlayTimer() {
    _playTimer?.cancel();

    // 16ms 간격으로 다음 이벤트 체크 (~60fps)
    _playTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_isDisposed) {
        _playTimer?.cancel();
        return;
      }

      _processEvents();
    });
  }

  void _processEvents() {
    final currentPos = positionMicros;

    // 현재 위치까지의 이벤트 발행
    while (_currentIndex < _timeline.length) {
      final event = _timeline[_currentIndex];
      final eventOffset = event.timestampMicros - _timelineStartMicros;

      if (eventOffset > currentPos) break;

      if (!_eventController.isClosed) {
        _eventController.add(event);
      }
      _currentIndex++;
    }

    // 위치 스트림 업데이트
    if (!_positionController.isClosed) {
      _positionController.add(currentPos);
    }

    // 재생 완료 체크
    if (_currentIndex >= _timeline.length) {
      _playTimer?.cancel();
      _state = .completed;
      notifyListeners();
    }
  }

  void _fastForwardTo(int targetMicros) {
    while (_currentIndex < _timeline.length) {
      final event = _timeline[_currentIndex];
      final eventOffset = event.timestampMicros - _timelineStartMicros;

      if (eventOffset > targetMicros) break;

      if (!_eventController.isClosed) {
        _eventController.add(event);
      }
      _currentIndex++;
    }
  }

  void _buildSnapshots() {
    _snapshots.clear();
    if (_timeline.isEmpty) return;

    for (int i = 0; i < _timeline.length; i++) {
      final event = _timeline[i];
      final offset = event.timestampMicros - _timelineStartMicros;

      // 스냅샷 간격마다 체크포인트 생성
      final snapshotKey = (offset ~/ _snapshotIntervalMicros);
      if (!_snapshots.containsKey(snapshotKey)) {
        _snapshots[snapshotKey] = ReplaySnapshot(
          eventIndex: i,
          offsetMicros: offset,
        );
      }
    }
  }

  MapEntry<int, ReplaySnapshot>? _findNearestSnapshot(int targetMicros) {
    if (_snapshots.isEmpty) return null;

    // 목표 이전의 가장 가까운 스냅샷 찾기
    MapEntry<int, ReplaySnapshot>? nearest;
    for (final entry in _snapshots.entries) {
      if (entry.value.offsetMicros <= targetMicros) {
        if (nearest == null ||
            entry.value.offsetMicros > nearest.value.offsetMicros) {
          nearest = entry;
        }
      }
    }

    return nearest;
  }
}

/// 리플레이 스냅샷 (seek 최적화용 체크포인트)
class ReplaySnapshot {
  /// 이 스냅샷 시점의 이벤트 인덱스
  final int eventIndex;

  /// 이 스냅샷의 타임라인 오프셋 (마이크로초)
  final int offsetMicros;

  const ReplaySnapshot({
    required this.eventIndex,
    required this.offsetMicros,
  });
}
