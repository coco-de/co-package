/// Egress 녹화 상태
enum EgressState {
  /// 녹화 대기
  idle,

  /// 녹화 시작 중
  starting,

  /// 녹화 진행 중
  recording,

  /// 녹화 중지 중
  stopping,

  /// 녹화 완료 (MP4 URL 획득 가능)
  completed,

  /// 녹화 실패
  failed,
}

/// 녹화 결과
class EgressResult {
  /// MP4 파일 URL
  final String? mp4Url;

  /// Egress 시작 시각 (마이크로초, epoch)
  final int startTimestamp;

  /// Egress 종료 시각 (마이크로초, epoch)
  final int endTimestamp;

  /// 녹화 시간 (마이크로초)
  int get durationMicros => endTimestamp - startTimestamp;

  const EgressResult({
    this.mp4Url,
    required this.startTimestamp,
    required this.endTimestamp,
  });
}

/// Egress 녹화 컨트롤러 추상 인터페이스
///
/// LiveKit Egress API를 통한 Room Composite 녹화를 관리한다.
/// 소비자 앱에서 LiveKit Server API에 맞게 구현한다.
///
/// 녹화 흐름:
/// 1. 세션 active 시 [startRecording] 호출
/// 2. 세션 종료 시 [stopRecording] 호출
/// 3. [result]에서 MP4 URL과 타임스탬프 획득
/// 4. [SessionStorage]를 통해 Object Store에 저장
abstract class EgressController {
  /// 현재 녹화 상태
  EgressState get state;

  /// 녹화 상태 스트림
  Stream<EgressState> get stateStream;

  /// Room Composite 녹화 시작
  ///
  /// [roomName] LiveKit Room 이름 (= sessionId)
  /// Returns: Egress 시작 시각 (마이크로초, epoch)
  Future<int> startRecording(String roomName);

  /// 녹화 중지 및 MP4 URL 획득
  ///
  /// Returns: 녹화 결과 (MP4 URL, 시작/종료 타임스탬프)
  Future<EgressResult> stopRecording();

  /// 리소스 해제
  void dispose();
}
