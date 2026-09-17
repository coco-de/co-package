# LiveKit 연동 가이드: 실시간 1:1 과외 구현

> open-board의 Live Session 모듈을 사용하여 소비자 앱에서 LiveKit 기반 실시간 과외를 구현하는 가이드

## 목차

1. [아키텍처 개요](#1-아키텍처-개요)
2. [의존성 설정](#2-의존성-설정)
3. [LiveKitTransport 구현](#3-livekittransport-구현)
4. [세션 UI 통합](#4-세션-ui-통합)
5. [서버측 토큰 발급](#5-서버측-토큰-발급)
6. [Egress 녹화 구현](#6-egress-녹화-구현)
7. [리플레이 구현](#7-리플레이-구현)
8. [에러 처리 및 재연결](#8-에러-처리-및-재연결)
9. [전체 통합 예시](#9-전체-통합-예시)

---

## 1. 아키텍처 개요

open-board는 Transport 추상화를 통해 네트워크 구현을 소비자 앱에 위임합니다.

```
┌─────────────────────────────────────────────────────────┐
│  소비자 앱 (your_app)                                    │
│                                                          │
│  ┌────────────────────┐   ┌───────────────────────────┐ │
│  │ LiveKitTransport    │   │ EgressControllerImpl      │ │
│  │ (구현)              │   │ (구현)                     │ │
│  └────────┬───────────┘   └───────────────────────────┘ │
│           │                                              │
├───────────┼──────────────────────────────────────────────┤
│  open-board (라이브러리)                                  │
│           │                                              │
│  ┌────────▼───────────┐   ┌───────────────────────────┐ │
│  │ LiveSessionTransport│   │ LiveSessionController     │ │
│  │ (추상 인터페이스)    │   │ (세션 오케스트레이터)      │ │
│  └────────────────────┘   └───────────────────────────┘ │
│                                                          │
│  ┌────────────────┐ ┌──────────────┐ ┌───────────────┐  │
│  │ EventBatcher   │ │ RemoteStroke │ │ Adaptive      │  │
│  │ (100ms 배칭)   │ │ Renderer     │ │ Viewport      │  │
│  └────────────────┘ └──────────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**소비자 앱이 구현해야 하는 것:**

| 인터페이스 | 용도 | 필수 |
|-----------|------|------|
| `LiveSessionTransport` | LiveKit Data Channel 기반 실시간 통신 | **필수** |
| `EgressController` | LiveKit Egress API 기반 녹화 | 선택 |
| `SessionStorage` | Object Store (.obt, .bin, MP4) 업로드/다운로드 | 선택 |
| `AudioPlayerDelegate` | 리플레이 시 오디오 재생 | 선택 |

---

## 2. 의존성 설정

### pubspec.yaml

```yaml
dependencies:
  open_board:
    path: ../open_board  # 또는 git/pub 경로

  # LiveKit SDK
  livekit_client: ^2.7.0

  # 오디오 재생 (리플레이용, 선택)
  just_audio: ^0.9.0
```

---

## 3. LiveKitTransport 구현

`LiveSessionTransport` 추상 인터페이스를 `livekit_client`로 구현합니다.

### 3.1 기본 구조

```dart
import 'dart:async';

import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:open_board/modules.dart';

class LiveKitTransport implements LiveSessionTransport {
  final String wsUrl; // LiveKit 서버 WebSocket URL

  lk.Room? _room;
  lk.LocalParticipant? _localParticipant;

  // 스트림 컨트롤러
  final _connectionController =
      StreamController<TransportConnectionState>.broadcast();
  final _eventController =
      StreamController<ScribbleBookEvent>.broadcast();
  final _strokePointsController =
      StreamController<StrokePointsBatch>.broadcast();
  final _strokeCompleteController =
      StreamController<StrokeCompleteMessage>.broadcast();
  final _viewportController =
      StreamController<ViewportMessage>.broadcast();
  final _syncRequestController =
      StreamController<SyncRequestMessage>.broadcast();
  final _syncResponseController =
      StreamController<SyncResponseMessage>.broadcast();
  final _participantEventController =
      StreamController<ParticipantEvent>.broadcast();

  TransportConnectionState _currentState =
      TransportConnectionState.disconnected;
  final List<RemoteParticipant> _participants = [];

  LiveKitTransport({required this.wsUrl});
```

### 3.2 connect / disconnect

```dart
  @override
  Future<void> connect(String sessionId, String token) async {
    _updateState(TransportConnectionState.connecting);

    try {
      _room = lk.Room();

      // 이벤트 리스너 등록
      _room!.addListener(_RoomListener(this));

      await _room!.connect(
        wsUrl,
        token,
        roomOptions: const lk.RoomOptions(
          adaptiveStream: false, // 영상 미사용
          dynacast: false,
        ),
      );

      _localParticipant = _room!.localParticipant;
      _updateState(TransportConnectionState.connected);
    } catch (e) {
      _updateState(TransportConnectionState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _room?.disconnect();
    _room?.dispose();
    _room = null;
    _localParticipant = null;
    _updateState(TransportConnectionState.disconnected);
  }
```

### 3.3 데이터 송신 (Topic 기반)

LiveKit Data Channel은 `topic` 파라미터로 메시지를 구분합니다.

```dart
  // ── 필기 이벤트 송신 ──

  @override
  void sendStrokePoints(StrokePointsBatch batch) {
    // Lossy 채널: 포인트 스트리밍 (손실 허용)
    _publishData(
      topic: 'stroke.points',
      data: _encodeStrokePoints(batch),
      reliable: false,
    );
  }

  @override
  void sendStrokeComplete(StrokeCompleteMessage message) {
    // Reliable 채널: 완료 스트로크 (전달 보장)
    _publishData(
      topic: 'stroke.complete',
      data: _encodeStrokeComplete(message),
      reliable: true,
    );
  }

  @override
  void sendEvent(ScribbleBookEvent event) {
    _publishData(
      topic: 'event',
      data: _encodeEvent(event),
      reliable: true,
    );
  }

  @override
  void sendViewport(ViewportMessage message) {
    _publishData(
      topic: 'viewport',
      data: _encodeViewport(message),
      reliable: false, // Lossy
    );
  }

  @override
  Future<void> requestSync(SyncRequestMessage request) async {
    _publishData(
      topic: 'sync.request',
      data: _encodeSyncRequest(request),
      reliable: true,
    );
  }

  @override
  Future<void> sendSyncResponse(SyncResponseMessage response) async {
    _publishData(
      topic: 'sync.response',
      data: _encodeSyncResponse(response),
      reliable: true,
    );
  }

  void _publishData({
    required String topic,
    required List<int> data,
    required bool reliable,
  }) {
    _localParticipant?.publishData(
      data,
      reliable: reliable,
      topic: topic,
    );
  }
```

### 3.4 데이터 수신

```dart
  /// LiveKit Room에서 데이터 수신 시 호출
  void _handleDataReceived(
    List<int> data,
    String? topic,
    lk.RemoteParticipant? participant,
  ) {
    switch (topic) {
      case 'stroke.points':
        _strokePointsController.add(_decodeStrokePoints(data));
      case 'stroke.complete':
        _strokeCompleteController.add(_decodeStrokeComplete(data));
      case 'event':
        _eventController.add(_decodeEvent(data));
      case 'viewport':
        _viewportController.add(_decodeViewport(data));
      case 'sync.request':
        _syncRequestController.add(_decodeSyncRequest(data));
      case 'sync.response':
        _syncResponseController.add(_decodeSyncResponse(data));
    }
  }
```

### 3.5 직렬화/역직렬화

메시지 직렬화는 JSON 또는 Protobuf를 사용할 수 있습니다. 아래는 간단한 JSON 예시입니다.

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

// ── StrokePointsBatch ──

List<int> _encodeStrokePoints(StrokePointsBatch batch) {
  return utf8.encode(jsonEncode({
    'pageId': batch.pageId,
    'strokeId': batch.strokeId,
    'points': batch.points
        .map((p) => {'x': p.x, 'y': p.y, 'p': p.p})
        .toList(),
    'color': batch.color,
    'width': batch.width,
    'ink': batch.ink,
    'seq': batch.sequenceNum,
  }));
}

StrokePointsBatch _decodeStrokePoints(List<int> data) {
  final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
  return StrokePointsBatch(
    pageId: map['pageId'] as String,
    strokeId: map['strokeId'] as String,
    points: (map['points'] as List)
        .map((p) => Point(
              x: (p['x'] as num).toDouble(),
              y: (p['y'] as num).toDouble(),
              p: (p['p'] as num?)?.toDouble() ?? 1.0,
            ))
        .toList(),
    color: map['color'] as int,
    width: (map['width'] as num).toDouble(),
    ink: map['ink'] as String,
    sequenceNum: map['seq'] as int,
  );
}

// ── StrokeCompleteMessage ──

List<int> _encodeStrokeComplete(StrokeCompleteMessage msg) {
  return utf8.encode(jsonEncode({
    'pageId': msg.pageId,
    'strokeId': msg.strokeId,
    'stroke': base64Encode(msg.stroke.writeToBuffer()),
    'strokeIndex': msg.strokeIndex,
    'ts': msg.timestampMicros,
  }));
}

StrokeCompleteMessage _decodeStrokeComplete(List<int> data) {
  final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
  return StrokeCompleteMessage(
    pageId: map['pageId'] as String,
    strokeId: map['strokeId'] as String,
    stroke: Stroke.fromBuffer(base64Decode(map['stroke'] as String)),
    strokeIndex: map['strokeIndex'] as int,
    timestampMicros: map['ts'] as int,
  );
}

// ── ScribbleBookEvent (페이지/undo/redo 이벤트) ──

List<int> _encodeEvent(ScribbleBookEvent event) {
  final map = <String, dynamic>{'ts': event.timestampMicros};

  switch (event) {
    case PageChangedEvent(:final fromIndex, :final toIndex,
        :final fromPageId, :final toPageId):
      map['type'] = 'pageChanged';
      map['fromIndex'] = fromIndex;
      map['toIndex'] = toIndex;
      map['fromPageId'] = fromPageId;
      map['toPageId'] = toPageId;
    case StrokeRemovedEvent(:final pageId, :final strokeIndex):
      map['type'] = 'strokeRemoved';
      map['pageId'] = pageId;
      map['strokeIndex'] = strokeIndex;
    case UndoPerformedEvent(:final pageId):
      map['type'] = 'undo';
      map['pageId'] = pageId;
    case RedoPerformedEvent(:final pageId):
      map['type'] = 'redo';
      map['pageId'] = pageId;
    case PageAddedEvent(:final pageId, :final atIndex):
      map['type'] = 'pageAdded';
      map['pageId'] = pageId;
      map['atIndex'] = atIndex;
    case PageRemovedEvent(:final pageId, :final atIndex):
      map['type'] = 'pageRemoved';
      map['pageId'] = pageId;
      map['atIndex'] = atIndex;
    case PageClearedEvent(:final pageId):
      map['type'] = 'pageCleared';
      map['pageId'] = pageId;
    default:
      return [];
  }

  return utf8.encode(jsonEncode(map));
}

ScribbleBookEvent _decodeEvent(List<int> data) {
  final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
  final ts = map['ts'] as int;

  return switch (map['type'] as String) {
    'pageChanged' => PageChangedEvent(
        fromIndex: map['fromIndex'] as int,
        toIndex: map['toIndex'] as int,
        fromPageId: map['fromPageId'] as String,
        toPageId: map['toPageId'] as String,
        timestampMicros: ts,
      ),
    'strokeRemoved' => StrokeRemovedEvent(
        pageId: map['pageId'] as String,
        strokeIndex: map['strokeIndex'] as int,
        timestampMicros: ts,
      ),
    'undo' => UndoPerformedEvent(
        pageId: map['pageId'] as String,
        timestampMicros: ts,
      ),
    'redo' => RedoPerformedEvent(
        pageId: map['pageId'] as String,
        timestampMicros: ts,
      ),
    'pageAdded' => PageAddedEvent(
        pageId: map['pageId'] as String,
        atIndex: map['atIndex'] as int,
        timestampMicros: ts,
      ),
    'pageRemoved' => PageRemovedEvent(
        pageId: map['pageId'] as String,
        atIndex: map['atIndex'] as int,
        timestampMicros: ts,
      ),
    'pageCleared' => PageClearedEvent(
        pageId: map['pageId'] as String,
        timestampMicros: ts,
      ),
    _ => throw FormatException('Unknown event type: ${map['type']}'),
  };
}

// ── ViewportMessage ──

List<int> _encodeViewport(ViewportMessage msg) {
  return utf8.encode(jsonEncode({
    'pageId': msg.pageId,
    'scale': msg.scale,
    'cx': msg.centerX,
    'cy': msg.centerY,
    'vw': msg.viewportWidth,
    'vh': msg.viewportHeight,
    'ts': msg.timestampMicros,
  }));
}

ViewportMessage _decodeViewport(List<int> data) {
  final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
  return ViewportMessage(
    pageId: map['pageId'] as String,
    scale: (map['scale'] as num).toDouble(),
    centerX: (map['cx'] as num).toDouble(),
    centerY: (map['cy'] as num).toDouble(),
    viewportWidth: (map['vw'] as num).toDouble(),
    viewportHeight: (map['vh'] as num).toDouble(),
    timestampMicros: map['ts'] as int,
  );
}

// ── Sync 메시지 (생략 — 동일 패턴) ──
```

### 3.6 스트림 / 참가자 / dispose

```dart
  // ── 스트림 getter ──

  @override
  Stream<TransportConnectionState> get connectionState =>
      _connectionController.stream;

  @override
  TransportConnectionState get currentConnectionState => _currentState;

  @override
  Stream<ScribbleBookEvent> get remoteEvents => _eventController.stream;

  @override
  Stream<StrokePointsBatch> get remoteStrokePoints =>
      _strokePointsController.stream;

  @override
  Stream<StrokeCompleteMessage> get remoteStrokeCompletes =>
      _strokeCompleteController.stream;

  @override
  Stream<ViewportMessage> get remoteViewports =>
      _viewportController.stream;

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

  // ── 내부 헬퍼 ──

  void _updateState(TransportConnectionState state) {
    _currentState = state;
    _connectionController.add(state);
  }

  @override
  void dispose() {
    _room?.dispose();
    _connectionController.close();
    _eventController.close();
    _strokePointsController.close();
    _strokeCompleteController.close();
    _viewportController.close();
    _syncRequestController.close();
    _syncResponseController.close();
    _participantEventController.close();
  }
}
```

### 3.7 Room 이벤트 리스너

```dart
class _RoomListener extends lk.RoomListener {
  final LiveKitTransport _transport;

  _RoomListener(this._transport);

  @override
  void onDataReceived(
    List<int> data,
    lk.RemoteParticipant? participant,
    String? topic,
  ) {
    _transport._handleDataReceived(data, topic, participant);
  }

  @override
  void onParticipantConnected(lk.RemoteParticipant participant) {
    final remote = RemoteParticipant(
      participantId: participant.identity,
      displayName: participant.name,
      role: _parseRole(participant.metadata),
    );
    _transport._participants.add(remote);
    _transport._participantEventController.add(ParticipantEvent(
      participant: remote,
      action: ParticipantAction.joined,
      timestampMicros: DateTime.now().microsecondsSinceEpoch,
    ));
  }

  @override
  void onParticipantDisconnected(lk.RemoteParticipant participant) {
    final idx = _transport._participants
        .indexWhere((p) => p.participantId == participant.identity);
    if (idx >= 0) {
      final remote = _transport._participants.removeAt(idx);
      _transport._participantEventController.add(ParticipantEvent(
        participant: remote,
        action: ParticipantAction.left,
        timestampMicros: DateTime.now().microsecondsSinceEpoch,
      ));
    }
  }

  @override
  void onReconnecting() {
    _transport._updateState(TransportConnectionState.reconnecting);
  }

  @override
  void onReconnected() {
    _transport._updateState(TransportConnectionState.connected);
  }

  @override
  void onDisconnected({lk.DisconnectReason? reason}) {
    _transport._updateState(TransportConnectionState.disconnected);
  }

  ParticipantRole _parseRole(String? metadata) {
    if (metadata == null) return ParticipantRole.student;
    try {
      final map = jsonDecode(metadata) as Map<String, dynamic>;
      return map['role'] == 'teacher'
          ? ParticipantRole.teacher
          : ParticipantRole.student;
    } catch (_) {
      return ParticipantRole.student;
    }
  }
}
```

---

## 4. 세션 UI 통합

### 4.1 세션 화면 구성

```dart
import 'package:flutter/material.dart';
import 'package:open_board/modules.dart';

class LiveTutoringPage extends StatefulWidget {
  final String sessionId;
  final String token;
  final bool isTeacher;
  final String livekitWsUrl;

  const LiveTutoringPage({
    required this.sessionId,
    required this.token,
    required this.isTeacher,
    required this.livekitWsUrl,
    super.key,
  });

  @override
  State<LiveTutoringPage> createState() => _LiveTutoringPageState();
}

class _LiveTutoringPageState extends State<LiveTutoringPage> {
  late final ScribbleCacheManager _cacheManager;
  late final ScribbleBookController _bookController;
  late final LiveKitTransport _transport;
  late final LiveSessionController _sessionController;

  @override
  void initState() {
    super.initState();

    // 1. 캐시 매니저 생성
    _cacheManager = ScribbleCacheManager();

    // 2. Book 컨트롤러 생성
    _bookController = ScribbleBookController(
      contentId: widget.sessionId,
      pageIds: ['page-1'],
      pageProvider: _cacheManager,
    );

    // 3. LiveKit Transport 생성
    _transport = LiveKitTransport(wsUrl: widget.livekitWsUrl);

    // 4. 세션 컨트롤러 생성
    _sessionController = LiveSessionController(
      bookController: _bookController,
      transport: _transport,
      isTeacher: widget.isTeacher,
    );

    // 5. 세션 시작
    _startSession();
  }

  Future<void> _startSession() async {
    await _sessionController.startSession(
      widget.sessionId,
      widget.token,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LiveSessionScope(
      controller: _sessionController,
      transport: _transport,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isTeacher ? '수업 진행 중' : '수업 듣는 중'),
          actions: [
            // 연결 상태 표시
            ListenableBuilder(
              listenable: _sessionController,
              builder: (context, _) {
                return _ConnectionIndicator(
                  state: _sessionController.connectionState,
                );
              },
            ),
          ],
        ),
        body: SimpleScribbleWidget(
          controller: _bookController.activeController,
          // 선생님만 필기 가능, 학생은 읽기 전용
          readOnly: !widget.isTeacher,
        ),
        floatingActionButton: widget.isTeacher
            ? FloatingActionButton(
                onPressed: _endSession,
                child: const Icon(Icons.stop),
              )
            : null,
      ),
    );
  }

  Future<void> _endSession() async {
    await _sessionController.endSession();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _transport.dispose();
    _bookController.dispose();
    super.dispose();
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final TransportConnectionState state;
  const _ConnectionIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      TransportConnectionState.connected => (Colors.green, '연결됨'),
      TransportConnectionState.connecting => (Colors.orange, '연결 중...'),
      TransportConnectionState.reconnecting => (Colors.orange, '재연결 중...'),
      TransportConnectionState.disconnected => (Colors.red, '연결 끊김'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
```

### 4.2 포인트 스트리밍 연동

선생님이 펜을 터치할 때 `LiveSessionController`에 포인트를 전달합니다.
`SimpleScribbleWidget`의 `onPointerDown` / `onPointerMove` 콜백을 활용합니다.

```dart
// ScribbleWidget의 콜백에서 포인트 전달
SimpleScribbleWidget(
  controller: _bookController.activeController,
  onStrokeBegin: (details) {
    // 선생님일 때만 포인트 전송
    if (widget.isTeacher) {
      _sessionController.onLocalStrokeBegin(
        pageId: _bookController.currentPageId,
        color: DrawingState().selectedColor.value.value,
        width: DrawingState().selectedThickness.value,
        ink: DrawingState().selectedTool.value,
      );
    }
  },
  onPointAdded: (point) {
    if (widget.isTeacher) {
      _sessionController.onLocalPointAdded(point);
    }
  },
)
```

---

## 5. 서버측 토큰 발급

### Serverpod Endpoint 예시

```dart
import 'package:livekit_server_sdk/livekit_server_sdk.dart';
import 'package:serverpod/serverpod.dart';

class LiveSessionEndpoint extends Endpoint {
  static const _apiKey = 'your-livekit-api-key';
  static const _apiSecret = 'your-livekit-api-secret';

  /// 세션 참가 토큰 발급
  Future<Map<String, String>> joinSession(
    Session session, {
    required String sessionId,
    required String participantId,
    required String displayName,
    required String role, // "teacher" | "student"
  }) async {
    final token = AccessToken(_apiKey, _apiSecret)
      ..identity = participantId
      ..name = displayName
      ..metadata = '{"role": "$role"}'
      ..addGrant(VideoGrant(
        roomJoin: true,
        room: sessionId,
        canPublish: true,
        canPublishData: true,
        canSubscribe: true,
      ))
      ..ttl = const Duration(hours: 4);

    return {
      'token': token.toJwt(),
      'wsUrl': 'wss://your-livekit-server.com',
      'sessionId': sessionId,
    };
  }
}
```

---

## 6. Egress 녹화 구현

### EgressController 구현

```dart
import 'package:http/http.dart' as http;
import 'package:open_board/modules.dart';

class LiveKitEgressController implements EgressController {
  final String livekitApiUrl;
  final String apiKey;
  final String apiSecret;

  EgressState _state = EgressState.idle;
  String? _egressId;
  int _startTimestamp = 0;

  final _stateController = StreamController<EgressState>.broadcast();

  LiveKitEgressController({
    required this.livekitApiUrl,
    required this.apiKey,
    required this.apiSecret,
  });

  @override
  EgressState get state => _state;

  @override
  Stream<EgressState> get stateStream => _stateController.stream;

  @override
  Future<int> startRecording(String roomName) async {
    _updateState(EgressState.starting);

    // LiveKit Egress API 호출
    final response = await http.post(
      Uri.parse('$livekitApiUrl/twirp/livekit.Egress/StartRoomCompositeEgress'),
      headers: _authHeaders(),
      body: jsonEncode({
        'room_name': roomName,
        'file_outputs': [
          {'file_type': 'MP4', 's3': _s3Config()},
        ],
      }),
    );

    final result = jsonDecode(response.body);
    _egressId = result['egress_id'];
    _startTimestamp = DateTime.now().microsecondsSinceEpoch;

    _updateState(EgressState.recording);
    return _startTimestamp;
  }

  @override
  Future<EgressResult> stopRecording() async {
    _updateState(EgressState.stopping);

    await http.post(
      Uri.parse('$livekitApiUrl/twirp/livekit.Egress/StopEgress'),
      headers: _authHeaders(),
      body: jsonEncode({'egress_id': _egressId}),
    );

    final endTimestamp = DateTime.now().microsecondsSinceEpoch;
    _updateState(EgressState.completed);

    return EgressResult(
      mp4Url: 'https://your-s3.com/recordings/$_egressId.mp4',
      startTimestamp: _startTimestamp,
      endTimestamp: endTimestamp,
    );
  }

  // ...
}
```

---

## 7. 리플레이 구현

### AudioPlayerDelegate 구현 (just_audio)

```dart
import 'package:just_audio/just_audio.dart';
import 'package:open_board/modules.dart';

class JustAudioDelegate implements AudioPlayerDelegate {
  final _player = AudioPlayer();

  @override
  Future<void> setSource(String source) async {
    if (source.startsWith('http')) {
      await _player.setUrl(source);
    } else {
      await _player.setFilePath(source);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void setSpeed(double speed) => _player.setSpeed(speed);

  @override
  int get currentPositionMicros =>
      _player.position.inMicroseconds;

  @override
  Future<void> dispose() => _player.dispose();
}
```

### 리플레이 화면

```dart
class ReplayPage extends StatefulWidget {
  final String obtPath;
  final String mp4Url;
  final int egressStartTimestamp;
  final int obtStartTimestamp;

  // ...
}

class _ReplayPageState extends State<ReplayPage> {
  late final ScribbleReplayController _replayController;
  late final SyncedReplayController _syncedController;

  @override
  void initState() {
    super.initState();

    _replayController = ScribbleReplayController();
    _syncedController = SyncedReplayController(
      replayController: _replayController,
      audioPlayer: JustAudioDelegate(),
    );

    _load();
  }

  Future<void> _load() async {
    await _syncedController.load(
      obtPath: widget.obtPath,
      audioSource: widget.mp4Url,
      egressStartTimestamp: widget.egressStartTimestamp,
      obtStartTimestamp: widget.obtStartTimestamp,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 필기 리플레이 영역
          Expanded(
            child: SimpleScribbleWidget(
              controller: /* replay에서 제공하는 controller */,
              readOnly: true,
            ),
          ),
          // 재생 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _syncedController.play,
                icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                onPressed: _syncedController.pause,
                icon: const Icon(Icons.pause),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 8. 에러 처리 및 재연결

### 연결 상태 모니터링

```dart
_sessionController.addListener(() {
  final state = _sessionController.connectionState;

  switch (state) {
    case TransportConnectionState.reconnecting:
      // 자동 재연결 중 — UI에 "재연결 중..." 표시
      _showReconnectingBanner();

    case TransportConnectionState.disconnected:
      // 30초 초과 또는 수동 종료
      // "연결 끊김" + "다시 연결" 버튼 표시
      _showDisconnectedDialog();

    case TransportConnectionState.connected:
      // 재연결 성공 — 배너 제거
      _hideReconnectingBanner();

    case TransportConnectionState.connecting:
      break;
  }
});
```

### 재연결 시 동기화

```dart
// Transport의 reconnected 이벤트 후 자동 sync
transport.connectionState.listen((state) {
  if (state == TransportConnectionState.connected && !isTeacher) {
    // 학생이 재연결되면 sync 요청
    transport.requestSync(SyncRequestMessage(
      participantId: myParticipantId,
      requestTimestamp: DateTime.now().microsecondsSinceEpoch,
    ));
  }
});
```

---

## 9. 전체 통합 예시

### 최소 구현 체크리스트

```
✅ 1. LiveKitTransport 클래스 구현
✅ 2. 서버에서 LiveKit 토큰 발급 API 구현
✅ 3. LiveSessionController로 세션 시작/종료
✅ 4. SimpleScribbleWidget에 포인트 콜백 연결
✅ 5. 연결 상태 UI 표시

선택사항:
☐ 6. EgressController로 녹화
☐ 7. SessionStorage로 .obt/.bin 업로드
☐ 8. SyncedReplayController로 리플레이
☐ 9. LateJoinSynchronizer로 중간 참가 처리
```

### 테스트 (LocalLoopbackTransport 활용)

LiveKit 서버 없이 단일 디바이스에서 전체 흐름을 테스트할 수 있습니다.

```dart
// 테스트 또는 데모용
final teacherTransport = LocalLoopbackTransport(
  latency: const Duration(milliseconds: 50),
);
final studentTransport = LocalLoopbackTransport(
  latency: const Duration(milliseconds: 50),
);
teacherTransport.linkPeer(studentTransport);

// 선생님
final teacherSession = LiveSessionController(
  bookController: teacherBookController,
  transport: teacherTransport,
  isTeacher: true,
);

// 학생
final studentSession = LiveSessionController(
  bookController: studentBookController,
  transport: studentTransport,
  isTeacher: false,
);

await teacherSession.startSession('test-session', 'teacher');
await studentSession.startSession('test-session', 'student');

// 이제 선생님이 필기하면 학생 화면에 실시간 표시됨!
```

---

## Topic별 데이터 채널 요약

| Topic | 모드 | MTU | 용도 |
|-------|------|-----|------|
| `stroke.points` | Lossy | 1,300B | 진행 중 스트로크 포인트 스트리밍 |
| `stroke.complete` | Reliable | 15KiB | 완료 스트로크 전체 데이터 |
| `event` | Reliable | 15KiB | 페이지 전환, undo/redo 등 |
| `viewport` | Lossy | 1,300B | 뷰포트 변경 (줌/팬) |
| `sync.request` | Reliable | 15KiB | 동기화 요청 |
| `sync.response` | Reliable | 15KiB (분할) | 스냅샷 응답 |

---

## 참고 문서

- [Tech Spec: Phase 1 기술 사양서](./tech-spec-live-tutoring-phase1.md)
- [Architecture: 실시간 튜터링 Live Session 모듈](./architecture-live-tutoring-phase1.md)
- [LiveKit Server Docs](https://docs.livekit.io/)
- [livekit_client Flutter SDK](https://pub.dev/packages/livekit_client)
