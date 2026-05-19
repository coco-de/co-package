/// Transport 연결 상태
///
/// 상태 전이:
/// ```
/// disconnected → connecting → connected ⇄ reconnecting
///                                         → disconnected (max retries 초과)
/// connected / reconnecting → disconnected (disconnect() 호출)
/// ```
enum TransportConnectionState {
  /// 연결 없음 (초기 상태 또는 연결 해제됨)
  disconnected,

  /// 연결 진행 중 (JWT 검증, 방 입장 시도)
  connecting,

  /// 연결 완료 (양방향 데이터 채널 활성)
  connected,

  /// 자동 재연결 중 (exponential backoff)
  reconnecting,
}
