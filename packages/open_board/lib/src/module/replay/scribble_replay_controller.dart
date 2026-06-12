import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart' show Stroke;
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
  /// 이벤트 타임라인 (시간순 정렬)
  List<ScribbleBookEvent> _timeline = [];

  /// 현재 재생 인덱스
  int _currentIndex = 0;

  /// 재생 상태
  ReplayState _state = ReplayState.idle;

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

  /// 스냅샷 간격 (마이크로초, 기본 30초)
  static const int _snapshotIntervalMicros = 30 * 1000000;

  /// 이벤트 발행 스트림 (리플레이 시 발생하는 이벤트)
  final StreamController<ScribbleBookEvent> _eventController =
      StreamController<ScribbleBookEvent>.broadcast();

  /// 재생 위치 스트림 (마이크로초 단위, 외부 동기화용)
  final StreamController<int> _positionController =
      StreamController<int>.broadcast();

  /// 상태 리셋 신호 스트림 (뒤로 seek / 완료 후 재시작)
  final StreamController<void> _resetController =
      StreamController<void>.broadcast();

  /// dispose 여부
  bool _isDisposed = false;

  // ===== 상태 접근자 =====

  /// 현재 재생 상태
  ReplayState get state => _state;

  /// 재생 중 여부
  bool get isPlaying => _state == ReplayState.playing;

  /// 재생 속도
  double get speed => _speed;

  /// 전체 재생 시간 (마이크로초)
  int get durationMicros {
    if (_timeline.isEmpty) return 0;
    return _timeline.last.timestampMicros - _timelineStartMicros;
  }

  /// 전체 재생 시간 (Duration)
  Duration get duration => Duration(microseconds: durationMicros);

  /// 현재 재생 위치 (마이크로초)
  int get positionMicros {
    if (_state == ReplayState.idle) return 0;
    if (_state == ReplayState.completed) return durationMicros;
    if (_state == ReplayState.paused) return _playStartOffsetMicros;

    // playing 상태: wall clock 기반 계산
    final elapsed =
        ((DateTime.now().microsecondsSinceEpoch - _playStartWallMicros) *
                _speed)
            .round();
    return (_playStartOffsetMicros + elapsed).clamp(0, durationMicros);
  }

  /// 현재 재생 위치 (Duration)
  Duration get position => Duration(microseconds: positionMicros);

  /// 타임라인 이벤트 수
  int get eventCount => _timeline.length;

  /// 현재 재생 인덱스
  int get currentIndex => _currentIndex;

  /// 타임라인 시작 시각 (마이크로초, 절대 epoch 기준)
  ///
  /// [positionMicros]는 시작 시각 기준 상대 오프셋이므로, Point.timestamp
  /// 같은 절대 타임스탬프와 비교하려면 이 값을 더해야 한다.
  int get timelineStartMicros => _timelineStartMicros;

  /// 리플레이 이벤트 스트림
  Stream<ScribbleBookEvent> get onEvent => _eventController.stream;

  /// 재생 위치 스트림 (마이크로초)
  Stream<int> get onPositionChanged => _positionController.stream;

  /// 상태 리셋 신호 스트림
  ///
  /// 뒤로 seek하거나 완료 후 재생을 다시 시작하면 인덱스 0부터 이벤트가
  /// 재발행된다. 소비자(핸들러)는 이 신호를 받으면 표시 상태를 초기화한
  /// 뒤 재발행되는 이벤트를 적용해야 한다. (신호 없이 재발행하면 기존
  /// 상태 위에 이벤트가 이중 적용되어 페이지 중복·상태 오염이 발생한다)
  Stream<void> get onReset => _resetController.stream;

  // ===== 타임라인 로드 =====

  /// 이벤트 타임라인 로드
  ///
  /// 타임라인은 타임스탬프 기준 오름차순으로 정렬됩니다.
  void loadTimeline(List<ScribbleBookEvent> events) {
    _stop();

    _timeline = List<ScribbleBookEvent>.from(events)
      ..sort(
        (a, b) => a.timestampMicros.compareTo(b.timestampMicros),
      );

    _currentIndex = 0;
    _state = _timeline.isEmpty ? ReplayState.idle : ReplayState.paused;
    _timelineStartMicros =
        _timeline.isEmpty ? 0 : _timeline.first.timestampMicros;
    _playStartOffsetMicros = 0;

    // 스냅샷 생성
    _buildSnapshots();

    notifyListeners();
  }

  /// [ScribbleTimeline]에서 타임라인 로드 (.obt 데이터)
  ///
  /// [ScribbleTimeline]의 이벤트를 [ScribbleBookEvent]로 변환 후 로드한다.
  void loadFromTimeline(ScribbleTimeline timeline) {
    final events = timeline.events
        .map(_convertFromTimelineEvent)
        .toList();
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

  /// [TimelineEvent] → [ScribbleBookEvent] 변환
  ScribbleBookEvent _convertFromTimelineEvent(TimelineEvent tlEvent) {
    final timestampMicros = tlEvent.timestamp.toInt();

    return switch (tlEvent.event) {
      TlPageChanged(:final fromIndex, :final toIndex, :final fromPageId, :final toPageId) =>
        PageChangedEvent(
          fromIndex: fromIndex,
          toIndex: toIndex,
          fromPageId: fromPageId,
          toPageId: toPageId,
          timestampMicros: timestampMicros,
        ),
      TlStrokeAdded(:final pageId, :final strokeIndex) =>
        StrokeAddedEvent(
          pageId: pageId,
          stroke: _emptyStroke,
          strokeIndex: strokeIndex,
          timestampMicros: timestampMicros,
        ),
      TlStrokeRemoved(:final pageId, :final strokeIndex) =>
        StrokeRemovedEvent(
          pageId: pageId,
          strokeIndex: strokeIndex,
          timestampMicros: timestampMicros,
        ),
      TlUndo(:final pageId) =>
        UndoPerformedEvent(pageId: pageId, timestampMicros: timestampMicros),
      TlRedo(:final pageId) =>
        RedoPerformedEvent(pageId: pageId, timestampMicros: timestampMicros),
      TlPageAdded(:final pageId, :final atIndex) =>
        PageAddedEvent(pageId: pageId, atIndex: atIndex, timestampMicros: timestampMicros),
      TlPageRemoved(:final pageId, :final atIndex) =>
        PageRemovedEvent(pageId: pageId, atIndex: atIndex, timestampMicros: timestampMicros),
      TlPageCleared(:final pageId) =>
        PageClearedEvent(pageId: pageId, timestampMicros: timestampMicros),
      TlViewportChanged(:final pageId, :final scale, :final centerX,
          :final centerY, :final viewportWidth, :final viewportHeight) =>
        ViewportChangedEvent(
          pageId: pageId,
          scale: scale,
          centerX: centerX,
          centerY: centerY,
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          timestampMicros: timestampMicros,
        ),
      TlSessionParticipant(:final participantId, :final displayName,
          :final role, :final action) =>
        SessionParticipantEvent(
          participantId: participantId,
          displayName: displayName,
          role: ParticipantRole.values.byName(role),
          action: ParticipantAction.values.byName(action),
          timestampMicros: timestampMicros,
        ),
    };
  }

  // ===== 재생 제어 =====

  /// 재생 시작/재개
  void play() {
    if (_timeline.isEmpty) return;
    if (_state == ReplayState.completed) {
      // 완료 상태에서 play → 소비자 상태 리셋 후 처음부터 재생
      // (리셋 없이 재발행하면 최종 상태 위에 전체 이벤트가 이중 적용된다)
      _emitReset();
      _currentIndex = 0;
      _playStartOffsetMicros = 0;
    }

    _state = ReplayState.playing;
    _playStartWallMicros = DateTime.now().microsecondsSinceEpoch;

    _startPlayTimer();
    notifyListeners();
  }

  /// 일시 정지
  void pause() {
    if (_state != ReplayState.playing) return;

    _playStartOffsetMicros = positionMicros;
    _state = ReplayState.paused;
    _playTimer?.cancel();

    notifyListeners();
  }

  /// 특정 위치로 이동
  void seek(Duration position) {
    final targetMicros = position.inMicroseconds.clamp(0, durationMicros);
    final beforeMicros = positionMicros;

    if (targetMicros >= beforeMicros && _state != ReplayState.completed) {
      // 전진 seek: 현재 커서 위치에서 그대로 fast-forward.
      // 커서를 스냅샷 인덱스로 되감으면 이미 발행한 구간이 중복 발행되어
      // PageAdded 재적용(assert 크래시)·인덱스 기반 삭제 오적용이 일어난다.
      _fastForwardTo(targetMicros);
    } else {
      // 후진 seek(또는 completed 후 재탐색): 소비자 상태를 리셋한 뒤
      // 처음부터 목표 위치까지 재발행한다. ReplaySnapshot은 이벤트
      // 인덱스만 보관할 뿐 보드 상태가 없으므로, 중간 인덱스에서
      // 재개하면 그 이전 이벤트가 누락된 잘못된 상태가 된다.
      _emitReset();
      _currentIndex = 0;
      _fastForwardTo(targetMicros);
    }

    _playStartOffsetMicros = targetMicros;
    if (_state == ReplayState.completed &&
        targetMicros < durationMicros) {
      _state = ReplayState.paused;
    }

    if (_state == ReplayState.playing) {
      _playStartWallMicros = DateTime.now().microsecondsSinceEpoch;
      _startPlayTimer();
    }

    _positionController.add(targetMicros);
    notifyListeners();
  }

  /// 재생 속도 변경
  void setSpeed(double speed) {
    assert(speed > 0, 'Speed must be positive');

    if (_state == ReplayState.playing) {
      _playStartOffsetMicros = positionMicros;
      _playStartWallMicros = DateTime.now().microsecondsSinceEpoch;
    }

    _speed = speed;

    if (_state == ReplayState.playing) {
      _startPlayTimer();
    }

    notifyListeners();
  }

  /// 외부(오디오 플레이어)에서 위치 동기화
  void syncTo(Duration position) {
    seek(position);
  }

  // ===== 내부 메서드 =====

  void _stop() {
    _playTimer?.cancel();
    _state = ReplayState.idle;
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
      _state = ReplayState.completed;
      notifyListeners();
    }
  }

  void _emitReset() {
    if (!_resetController.isClosed) {
      _resetController.add(null);
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

  // NOTE: ReplaySnapshot은 이벤트 인덱스만 보관할 뿐 보드 상태가 없어
  // 중간 인덱스에서 재개하면 그 이전 이벤트가 누락된 잘못된 상태가 된다.
  // 후진 seek는 리셋 후 처음부터 재발행하며, 스냅샷 기반 빠른 seek는
  // 녹화기의 TimelineSnapshot(pageStrokeCounts 등) 상태 복원이 구현될 때
  // 다시 활용한다.

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _playTimer?.cancel();
    _eventController.close();
    _positionController.close();
    _resetController.close();
    super.dispose();
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
