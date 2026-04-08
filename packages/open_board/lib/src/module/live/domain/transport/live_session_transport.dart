import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/live/domain/model/session_participant.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';
import 'package:open_board/src/module/live/domain/model/transport_state.dart';

/// 실시간 세션 Transport 추상화
///
/// LiveKit, WebSocket, 로컬 루프백 등 다양한 구현을 교체 가능하게 한다.
/// open-board 코어 패키지에는 이 인터페이스만 포함되며,
/// LiveKit 구현은 소비자 앱에서 별도로 제공한다.
///
/// Topic별 데이터 채널:
/// | Topic            | 모드     | 용도                         |
/// |------------------|----------|------------------------------|
/// | stroke.points    | Lossy    | 진행 중 스트로크 포인트 스트리밍 |
/// | stroke.complete  | Reliable | 완료 스트로크 전체 데이터       |
/// | event            | Reliable | 페이지 전환, undo/redo 등      |
/// | viewport         | Lossy    | 뷰포트 변경                   |
/// | session          | Reliable | 세션 상태, 참가자 이벤트        |
/// | sync.request     | Reliable | 동기화 요청                   |
/// | sync.response    | Reliable | 스냅샷 응답 (분할)             |
abstract class LiveSessionTransport {
  /// 세션에 연결한다.
  ///
  /// [sessionId]는 LiveKit Room 이름과 1:1 매핑된다.
  /// [token]은 서버에서 발급한 LiveKit Access Token이다.
  Future<void> connect(String sessionId, String token);

  /// 연결을 해제한다.
  Future<void> disconnect();

  /// 연결 상태 스트림
  Stream<TransportConnectionState> get connectionState;

  /// 현재 연결 상태
  TransportConnectionState get currentConnectionState;

  // ── 필기 이벤트 ──

  /// 로컬 ScribbleBookEvent를 원격으로 전송한다 (Reliable).
  ///
  /// 페이지 전환, undo/redo, 페이지 추가/삭제 등의 이벤트를 전송한다.
  /// 스트로크 추가/삭제는 별도 메서드([sendStrokePoints], [sendStrokeComplete])를 사용한다.
  void sendEvent(ScribbleBookEvent event);

  /// 진행 중인 스트로크 포인트 배치를 전송한다 (Lossy).
  ///
  /// [EventBatcher]를 통해 100ms 윈도우로 배칭된 포인트를 전송한다.
  void sendStrokePoints(StrokePointsBatch batch);

  /// 완료된 스트로크 전체 데이터를 전송한다 (Reliable).
  void sendStrokeComplete(StrokeCompleteMessage message);

  /// 원격 필기 이벤트 수신 스트림
  Stream<ScribbleBookEvent> get remoteEvents;

  /// 원격 스트로크 포인트 배치 수신 스트림
  Stream<StrokePointsBatch> get remoteStrokePoints;

  /// 원격 스트로크 완료 수신 스트림
  Stream<StrokeCompleteMessage> get remoteStrokeCompletes;

  // ── 뷰포트 ──

  /// 뷰포트 변경을 전송한다 (Lossy).
  void sendViewport(ViewportMessage message);

  /// 원격 뷰포트 변경 수신 스트림
  Stream<ViewportMessage> get remoteViewports;

  // ── 동기화 ──

  /// 동기화 요청을 전송한다 (Reliable).
  Future<void> requestSync(SyncRequestMessage request);

  /// 동기화 응답을 전송한다 (Reliable, 분할 가능).
  Future<void> sendSyncResponse(SyncResponseMessage response);

  /// 동기화 요청 수신 스트림
  Stream<SyncRequestMessage> get syncRequests;

  /// 동기화 응답 수신 스트림
  Stream<SyncResponseMessage> get syncResponses;

  // ── 참가자 ──

  /// 현재 원격 참가자 목록
  List<RemoteParticipant> get participants;

  /// 참가자 변경 스트림
  Stream<ParticipantEvent> get participantEvents;

  /// 리소스 해제
  void dispose();
}
