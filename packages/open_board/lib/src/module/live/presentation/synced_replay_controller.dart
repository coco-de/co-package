import 'dart:async';

import 'package:open_board/src/module/replay/scribble_replay_controller.dart';

/// 오디오-타임라인 동기 리플레이 컨트롤러
///
/// .obt 타임라인과 LiveKit Egress MP4 오디오를 동기화하여 재생한다.
///
/// 동기화 전략:
/// - .obt의 `startTimestamp`와 Egress 시작 시각의 오프셋을 계산
/// - 재생/시크 시 오프셋을 적용하여 양측을 동기화
/// - 500ms 간격 드리프트 보정 (200ms 초과 시 오디오 시크)
///
/// 오디오 재생은 소비자 앱에서 [AudioPlayerDelegate]를 구현하여 주입한다.
/// open-board 패키지는 오디오 의존성을 포함하지 않는다.
class SyncedReplayController {
  final ScribbleReplayController replayController;
  final AudioPlayerDelegate audioPlayer;

  /// .obt startTimestamp와 Egress 시작 시각의 오프셋 (마이크로초)
  int _offsetMicros = 0;

  /// 드리프트 보정 타이머
  Timer? _driftTimer;

  /// 드리프트 보정 허용 임계값 (마이크로초)
  static const _driftThresholdMicros = 200000; // 200ms

  /// 드리프트 보정 주기 (밀리초)
  static const _driftCheckIntervalMs = 500;

  SyncedReplayController({
    required this.replayController,
    required this.audioPlayer,
  });

  /// 오디오와 타임라인을 로드한다.
  ///
  /// [obtPath] .obt 타임라인 파일 경로
  /// [audioSource] 오디오 소스 (URL 또는 파일 경로)
  /// [egressStartTimestamp] Egress 시작 시각 (마이크로초, epoch)
  /// [obtStartTimestamp] .obt 타임라인 시작 시각 (마이크로초, epoch)
  Future<void> load({
    required String obtPath,
    required String audioSource,
    required int egressStartTimestamp,
    required int obtStartTimestamp,
  }) async {
    await replayController.loadFromFile(obtPath);
    await audioPlayer.setSource(audioSource);

    // 오프셋 계산: .obt 시작 시각 - Egress 시작 시각
    _offsetMicros = obtStartTimestamp - egressStartTimestamp;
  }

  /// 동기 재생 시작
  void play() {
    replayController.play();

    final audioPositionMicros = replayController.positionMicros - _offsetMicros;
    if (audioPositionMicros > 0) {
      audioPlayer.seek(Duration(microseconds: audioPositionMicros));
    }
    audioPlayer.play();

    _startDriftCorrection();
  }

  /// 일시 정지
  void pause() {
    replayController.pause();
    audioPlayer.pause();
    _stopDriftCorrection();
  }

  /// 특정 위치로 시크
  void seek(Duration position) {
    replayController.seek(position);

    final audioPositionMicros = position.inMicroseconds - _offsetMicros;
    audioPlayer.seek(Duration(
      microseconds: audioPositionMicros < 0 ? 0 : audioPositionMicros,
    ));
  }

  /// 재생 속도 설정
  void setSpeed(double speed) {
    replayController.setSpeed(speed);
    audioPlayer.setSpeed(speed);
  }

  void _startDriftCorrection() {
    _driftTimer?.cancel();
    _driftTimer = Timer.periodic(
      const Duration(milliseconds: _driftCheckIntervalMs),
      (_) => _correctDrift(),
    );
  }

  void _stopDriftCorrection() {
    _driftTimer?.cancel();
    _driftTimer = null;
  }

  void _correctDrift() {
    final replayPos = replayController.positionMicros;
    final audioPos = audioPlayer.currentPositionMicros + _offsetMicros;
    final drift = (replayPos - audioPos).abs();

    if (drift > _driftThresholdMicros) {
      audioPlayer.seek(Duration(
        microseconds: replayPos - _offsetMicros,
      ));
    }
  }

  void dispose() {
    _stopDriftCorrection();
  }
}

/// 오디오 재생 위임 인터페이스
///
/// 소비자 앱에서 just_audio 등의 오디오 라이브러리로 구현한다.
abstract class AudioPlayerDelegate {
  /// 오디오 소스를 설정한다 (URL 또는 파일 경로)
  Future<void> setSource(String source);

  /// 재생 시작
  Future<void> play();

  /// 일시 정지
  Future<void> pause();

  /// 특정 위치로 시크
  Future<void> seek(Duration position);

  /// 재생 속도 설정
  void setSpeed(double speed);

  /// 현재 재생 위치 (마이크로초)
  int get currentPositionMicros;

  /// 리소스 해제
  Future<void> dispose();
}
