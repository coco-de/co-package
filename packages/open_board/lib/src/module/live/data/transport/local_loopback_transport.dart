import 'dart:async';
import 'dart:collection';

import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/live/domain/model/session_participant.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';
import 'package:open_board/src/module/live/domain/model/transport_state.dart';
import 'package:open_board/src/module/live/domain/transport/live_session_transport.dart';

/// 네트워크 없이 단일 프로세스 내에서 양방향 이벤트를 루프백하는 Transport
///
/// 통합 테스트 및 UI 프로토타이핑에 사용한다.
/// [linkPeer]로 두 인스턴스를 연결하면 한쪽의 send가 상대방의 stream에 나타난다.
///
/// 시뮬레이션 기능:
/// - [latency]: 인위적 지연 시간 (기본 10ms)
/// - [packetLossRate]: Lossy 채널 패킷 손실률 (0.0~1.0)
/// - [freezeConnection] / [resumeConnection]: 네트워크 단절 시뮬레이션
class LocalLoopbackTransport implements LiveSessionTransport {
  LocalLoopbackTransport({
    this.latency = const Duration(milliseconds: 10),
    this.packetLossRate = 0.0,
  });

  /// 인위적 네트워크 지연 시간
  Duration latency;

  /// Lossy 채널 패킷 손실률 (0.0 = 손실 없음, 1.0 = 전부 손실)
  double packetLossRate;

  LocalLoopbackTransport? _peer;
  bool _frozen = false;
  final Queue<void Function()> _frozenQueue = Queue();

  // ── 스트림 컨트롤러 ──

  final _connectionStateController =
      StreamController<TransportConnectionState>.broadcast();
  final _eventController = StreamController<ScribbleBookEvent>.broadcast();
  final _strokePointsController =
      StreamController<StrokePointsBatch>.broadcast();
  final _strokeCompleteController =
      StreamController<StrokeCompleteMessage>.broadcast();
  final _viewportController = StreamController<ViewportMessage>.broadcast();
  final _syncRequestController =
      StreamController<SyncRequestMessage>.broadcast();
  final _syncResponseController =
      StreamController<SyncResponseMessage>.broadcast();
  final _participantEventController =
      StreamController<ParticipantEvent>.broadcast();

  TransportConnectionState _currentState = TransportConnectionState.disconnected;
  final List<RemoteParticipant> _participants = [];

  /// 두 Transport를 연결한다. 양방향으로 설정됨.
  void linkPeer(LocalLoopbackTransport peer) {
    _peer = peer;
    peer._peer = this;
  }

  /// 네트워크 단절을 시뮬레이션한다. 전송이 큐에 쌓인다.
  void freezeConnection() {
    _frozen = true;
    _updateState(TransportConnectionState.reconnecting);
  }

  /// 네트워크 복구를 시뮬레이션한다. 큐에 쌓인 메시지를 순차 전달.
  void resumeConnection() {
    _frozen = false;
    _updateState(TransportConnectionState.connected);

    while (_frozenQueue.isNotEmpty) {
      _frozenQueue.removeFirst()();
    }
  }

  // ── LiveSessionTransport 구현 ──

  @override
  Future<void> connect(String sessionId, String token) async {
    _updateState(TransportConnectionState.connecting);
    await Future<void>.delayed(latency);
    _updateState(TransportConnectionState.connected);

    // 피어에게 참가 알림
    if (_peer != null) {
      final participant = RemoteParticipant(
        participantId: token,
        displayName: 'Loopback-$token',
        role: ParticipantRole.teacher,
      );
      _peer!._participants.add(participant);
      _peer!._participantEventController.add(ParticipantEvent(
        participant: participant,
        action: ParticipantAction.joined,
        timestampMicros: DateTime.now().microsecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> disconnect() async {
    _updateState(TransportConnectionState.disconnected);

    if (_peer != null) {
      final idx = _peer!._participants.indexWhere(
        (p) => p.participantId == _currentParticipantId,
      );
      if (idx >= 0) {
        final participant = _peer!._participants.removeAt(idx);
        _peer!._participantEventController.add(ParticipantEvent(
          participant: participant,
          action: ParticipantAction.left,
          timestampMicros: DateTime.now().microsecondsSinceEpoch,
        ));
      }
    }
  }

  String? _currentParticipantId;

  @override
  Stream<TransportConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  TransportConnectionState get currentConnectionState => _currentState;

  @override
  void sendEvent(ScribbleBookEvent event) {
    _deliverReliable(() {
      _peer?._eventController.add(event);
    });
  }

  @override
  void sendStrokePoints(StrokePointsBatch batch) {
    _deliverLossy(() {
      _peer?._strokePointsController.add(batch);
    });
  }

  @override
  void sendStrokeComplete(StrokeCompleteMessage message) {
    _deliverReliable(() {
      _peer?._strokeCompleteController.add(message);
    });
  }

  @override
  Stream<ScribbleBookEvent> get remoteEvents => _eventController.stream;

  @override
  Stream<StrokePointsBatch> get remoteStrokePoints =>
      _strokePointsController.stream;

  @override
  Stream<StrokeCompleteMessage> get remoteStrokeCompletes =>
      _strokeCompleteController.stream;

  @override
  void sendViewport(ViewportMessage message) {
    _deliverLossy(() {
      _peer?._viewportController.add(message);
    });
  }

  @override
  Stream<ViewportMessage> get remoteViewports => _viewportController.stream;

  @override
  Future<void> requestSync(SyncRequestMessage request) async {
    _deliverReliable(() {
      _peer?._syncRequestController.add(request);
    });
  }

  @override
  Future<void> sendSyncResponse(SyncResponseMessage response) async {
    _deliverReliable(() {
      _peer?._syncResponseController.add(response);
    });
  }

  @override
  Stream<SyncRequestMessage> get syncRequests =>
      _syncRequestController.stream;

  @override
  Stream<SyncResponseMessage> get syncResponses =>
      _syncResponseController.stream;

  @override
  List<RemoteParticipant> get participants =>
      List.unmodifiable(_participants);

  @override
  Stream<ParticipantEvent> get participantEvents =>
      _participantEventController.stream;

  @override
  void dispose() {
    _connectionStateController.close();
    _eventController.close();
    _strokePointsController.close();
    _strokeCompleteController.close();
    _viewportController.close();
    _syncRequestController.close();
    _syncResponseController.close();
    _participantEventController.close();
    _frozenQueue.clear();
  }

  // ── Private ──

  void _updateState(TransportConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  /// Reliable 채널: 순서/전달 보장. frozen 시 큐에 저장.
  void _deliverReliable(void Function() deliver) {
    if (_frozen) {
      _frozenQueue.add(deliver);
      return;
    }

    if (latency == Duration.zero) {
      deliver();
    } else {
      Future.delayed(latency, deliver);
    }
  }

  /// Lossy 채널: 패킷 손실 시뮬레이션. frozen 시 드롭.
  void _deliverLossy(void Function() deliver) {
    if (_frozen) return; // Lossy는 freeze 중 드롭

    // 패킷 손실 시뮬레이션
    if (packetLossRate > 0) {
      final random = DateTime.now().microsecondsSinceEpoch % 1000;
      if (random < (packetLossRate * 1000).toInt()) return;
    }

    if (latency == Duration.zero) {
      deliver();
    } else {
      Future.delayed(latency, deliver);
    }
  }
}
