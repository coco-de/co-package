# Phase 1 기술 사양서: 1:1 실시간 과외 MVP

> Open-Board 필기 엔진 + LiveKit Data Channel 기반 실시간 튜터링

- **범위**: 선생님 1명 + 학생 1명, 실시간 필기 동기화 + 음성 통화 + 리플레이
- **기간**: 0~3개월
- **상위 문서**: [Discovery: 실시간 온라인 튜터링 플랫폼](./discovery-live-tutoring.md)

---

## 1. 시스템 아키텍처

### 1.1 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Flutter Client (Teacher / Student)           │
│                                                                     │
│  ┌──────────────────┐   ┌──────────────────┐   ┌────────────────┐  │
│  │ ScribbleBook      │   │ Viewport         │   │ Audio/Video    │  │
│  │ Controller        │   │ Tracker          │   │ (LiveKit)      │  │
│  └────────┬─────────┘   └────────┬─────────┘   └───────┬────────┘  │
│           │ eventStream           │                      │          │
│  ┌────────▼─────────┐            │                      │          │
│  │ ScribbleEvent     │            │                      │          │
│  │ Bridge            │            │                      │          │
│  └────────┬─────────┘            │                      │          │
│           │ ScribbleBookEvent     │ ViewportChangedEvent │          │
│  ┌────────▼──────────────────────▼──────────────────────▼────────┐ │
│  │                  LiveSessionController                         │ │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐  │ │
│  │  │ EventBatcher │  │ Viewport     │  │ Timeline             │  │ │
│  │  │ (100ms)      │  │ Throttler    │  │ Recorder             │  │ │
│  │  └──────┬──────┘  └──────┬───────┘  └──────────────────────┘  │ │
│  └─────────┼────────────────┼────────────────────────────────────┘ │
│            │                │                                       │
│  ┌─────────▼────────────────▼──────────────────────────────────┐   │
│  │              LiveSessionTransport (abstract)                 │   │
│  └─────────────────────────┬───────────────────────────────────┘   │
└────────────────────────────┼───────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  LiveKit SFU     │
                    │  Server          │
                    │                  │
                    │  Data Channels:  │
                    │  - Lossy         │
                    │  - Reliable      │
                    │  Audio Track     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼───┐  ┌──────▼─────┐  ┌────▼──────────┐
     │ App Server  │  │ LiveKit     │  │ Object Store  │
     │ (Serverpod) │  │ Egress      │  │ (S3/R2)       │
     │             │  │ (녹화)      │  │ .obt + .bin   │
     │ - 세션 관리  │  │ → MP4       │  │               │
     │ - 토큰 발급  │  │             │  │               │
     │ - 스냅샷    │  └─────────────┘  └───────────────┘
     └─────────────┘
```

### 1.2 클라이언트-서버 역할 분리

| 컴포넌트 | 역할 | 기술 |
|---------|------|------|
| **Flutter Client** | 필기 입력/렌더링, 실시간 전송/수신, 리플레이 재생 | open-board (인터페이스), livekit_client v2.7.0 (소비자 앱에서 Transport 구현) |
| **App Server** | 세션 CRUD, LiveKit 토큰 발급, 스냅샷 저장/조회, .obt 업로드 | Serverpod |
| **LiveKit SFU** | Data Channel 중계, 음성 트랙 중계, Egress 녹화 | LiveKit Server (Self-Host 또는 Cloud) |
| **Object Store** | .obt 타임라인 + .bin 필기 데이터 영구 저장, 녹화 MP4 저장 | S3-compatible (R2, MinIO) |

### 1.3 Transport 추상화 레이어 설계

기존 open-board 코드베이스의 `ScribbleBookController`, `ScribbleEventBridge`는 변경하지 않는다. 새로 추가하는 `LiveSessionTransport` 추상화 레이어가 이벤트 스트림을 구독하여 네트워크로 전송한다.

```
기존 코드 (변경 없음)              새로 추가
─────────────────────          ─────────────────────
ScribbleBookController  ──eventStream──▶  LiveSessionController
ScribbleEventBridge                       ├── LiveSessionTransport
ScribbleReplayController                  │   ├── LiveKitTransport
ScribbleTimelineRecorder                  │   ├── WebSocketTransport (향후)
StrokeAnimator                            │   └── LocalLoopbackTransport (테스트)
                                          ├── EventBatcher
                                          ├── ViewportThrottler
                                          └── LateJoinSynchronizer
```

---

## 2. 데이터 모델

### 2.1 새로운 이벤트 타입

기존 `ScribbleBookEvent` sealed class(8종)에 다음을 추가한다.

```dart
/// 뷰포트(줌/팬) 변경 이벤트
class ViewportChangedEvent extends ScribbleBookEvent {
  final String pageId;
  final double scale;        // 확대 배율 (1.0 = 100%)
  final double centerX;      // 캔버스 좌표계 중심 X
  final double centerY;      // 캔버스 좌표계 중심 Y
  final double viewportWidth;  // 논리 뷰포트 너비 (dp)
  final double viewportHeight; // 논리 뷰포트 높이 (dp)

  const ViewportChangedEvent({
    required this.pageId,
    required this.scale,
    required this.centerX,
    required this.centerY,
    required this.viewportWidth,
    required this.viewportHeight,
    required super.timestampMicros,
  });
}

/// 세션 참가자 이벤트 (세션 레벨, 타임라인 기록용)
class SessionParticipantEvent extends ScribbleBookEvent {
  final String participantId;
  final String displayName;
  final ParticipantRole role;
  final ParticipantAction action; // joined, left

  const SessionParticipantEvent({
    required this.participantId,
    required this.displayName,
    required this.role,
    required this.action,
    required super.timestampMicros,
  });
}

enum ParticipantRole { teacher, student }
enum ParticipantAction { joined, left }
```

### 2.2 timeline.proto 확장

기존 `TimelineEvent.oneof`에 field number 10~12를 예약하여 추가한다.

```protobuf
message TimelineEvent {
  int64 timestamp = 1;
  oneof event {
    // 기존 8종 (2~9)
    TlPageChanged    pageChanged    = 2;
    TlStrokeAdded    strokeAdded    = 3;
    TlStrokeRemoved  strokeRemoved  = 4;
    TlUndo           undo           = 5;
    TlRedo           redo           = 6;
    TlPageAdded      pageAdded      = 7;
    TlPageRemoved    pageRemoved    = 8;
    TlPageCleared    pageCleared    = 9;

    // Phase 1 추가
    TlViewportChanged viewportChanged = 10;
    TlSessionParticipant sessionParticipant = 11;
  }
}

message TlViewportChanged {
  string pageId       = 1;
  double scale        = 2;
  double centerX      = 3;
  double centerY      = 4;
  double viewportWidth  = 5;
  double viewportHeight = 6;
}

message TlSessionParticipant {
  string participantId = 1;
  string displayName   = 2;
  string role          = 3;  // "teacher" | "student"
  string action        = 4;  // "joined" | "left"
}
```

### 2.3 LiveSession 모델

```dart
class LiveSession {
  final String sessionId;       // UUID v4
  final String contentId;       // ScribbleBook contentId와 일치
  final String roomName;        // LiveKit Room 이름 (= sessionId)
  final SessionState state;
  final DateTime createdAt;
  final DateTime? startedAt;    // 선생님이 수업 시작한 시각
  final DateTime? endedAt;
  final List<SessionParticipant> participants;
  final SessionConfig config;
}

enum SessionState {
  created,    // 세션 생성됨, 아직 아무도 입장하지 않음
  waiting,    // 선생님 입장, 학생 대기 중
  active,     // 양측 모두 입장, 수업 진행 중
  ended,      // 수업 종료
}

class SessionParticipant {
  final String participantId;
  final String displayName;
  final ParticipantRole role;
  final String token;          // LiveKit access token
}

class SessionConfig {
  final bool audioEnabled;      // 음성 통화 활성화 (기본 true)
  final bool videoEnabled;      // 영상 통화 활성화 (Phase 1: false)
  final bool egressEnabled;     // 녹화 활성화 (기본 true)
  final int maxParticipants;    // Phase 1: 2
}
```

### 2.4 메시지 프로토콜: Topic별 페이로드 스키마

LiveKit Data Channel의 Topic 시스템을 활용한다. 모든 페이로드는 Protobuf 바이너리로 인코딩한다.

| Topic | 모드 | MTU 제한 | 페이로드 | 용도 |
|-------|------|----------|---------|------|
| `stroke.points` | Lossy | 1,300B | `StrokePointsBatch` | 진행 중인 스트로크 포인트 스트리밍 |
| `stroke.complete` | Reliable | 15KiB | `StrokeCompleteMessage` | 스트로크 완료 시 전체 데이터 |
| `event` | Reliable | 15KiB | `ScribbleEventMessage` | 페이지 전환, undo/redo, 페이지 추가/삭제 등 |
| `viewport` | Lossy | 1,300B | `ViewportMessage` | 뷰포트 변경 |
| `session` | Reliable | 15KiB | `SessionControlMessage` | 세션 상태, 참가자 이벤트 |
| `sync.request` | Reliable | 15KiB | `SyncRequestMessage` | 늦은 참가자 동기화 요청 |
| `sync.response` | Reliable | 15KiB (분할) | `SyncResponseMessage` | 스냅샷 응답 (분할 전송) |

```protobuf
// 메시지 프로토콜 정의
syntax = "proto3";

message StrokePointsBatch {
  string pageId = 1;
  string strokeId = 2;        // 임시 ID (진행 중인 스트로크 식별)
  repeated Point points = 3;  // 배치된 포인트들
  uint32 color = 4;
  double width = 5;
  string ink = 6;
  int64 sequenceNum = 7;      // 패킷 순서 (Lossy 복구용)
}

message StrokeCompleteMessage {
  string pageId = 1;
  string strokeId = 2;
  Stroke stroke = 3;          // 전체 Stroke protobuf
  int32 strokeIndex = 4;
  int64 timestampMicros = 5;
}

message ScribbleEventMessage {
  int64 timestampMicros = 1;
  oneof event {
    PageChangedPayload pageChanged = 2;
    StrokeRemovedPayload strokeRemoved = 3;
    UndoPayload undo = 4;
    RedoPayload redo = 5;
    PageAddedPayload pageAdded = 6;
    PageRemovedPayload pageRemoved = 7;
    PageClearedPayload pageCleared = 8;
  }
}

message ViewportMessage {
  string pageId = 1;
  double scale = 2;
  double centerX = 3;
  double centerY = 4;
  double viewportWidth = 5;
  double viewportHeight = 6;
  int64 timestampMicros = 7;
}

message SyncRequestMessage {
  string participantId = 1;
  int64 requestTimestamp = 2;
}

message SyncResponseMessage {
  int32 chunkIndex = 1;
  int32 totalChunks = 2;
  bytes scribbleSnapshot = 3;   // 전체 Scribble protobuf (분할)
  repeated string pageIds = 4;
  int32 activePageIndex = 5;
  ViewportMessage lastViewport = 6;
  int64 snapshotTimestamp = 7;
}
```

---

## 3. 실시간 필기 동기화 상세 설계

### 3.1 포인트 스트리밍 흐름 (Lossy)

선생님이 펜을 대고 움직이는 순간부터 학생 화면에 나타나기까지의 흐름이다.

```
선생님 디바이스                                학생 디바이스
─────────────                              ─────────────
Pointer Event (6ms 간격, Apple Pencil)
    │
    ▼
ScribbleController.addPoint()
    │
    ▼
EventBatcher (100ms 윈도우)
    │  10~16개 포인트 축적
    ▼
StrokePointsBatch protobuf 직렬화 (~200B)
    │
    ▼
LiveKitTransport.sendLossy(
  topic: "stroke.points",
  data: bytes
)
    │
    ▼ Lossy Data Channel (sub-50ms)
    │
    ▼
LiveKit SFU ────────────────────────────▶ LiveKitTransport.onData()
                                              │
                                              ▼
                                         StrokePointsBatch 역직렬화
                                              │
                                              ▼
                                         RemoteStrokeRenderer
                                         .appendPoints(batch)
                                              │
                                              ▼
                                         Canvas repaint (vsync)
```

**배치 전략 상세:**

```dart
class EventBatcher {
  static const _batchWindowMs = 100;      // 배치 윈도우
  static const _maxPointsPerBatch = 20;   // 최대 포인트 수/배치
  static const _maxBatchSizeBytes = 1200; // Lossy MTU(1,300B) 미만 유지

  Timer? _batchTimer;
  final List<Point> _pendingPoints = [];

  void addPoint(Point point) {
    _pendingPoints.add(point);

    // 즉시 플러시 조건: 포인트 수 초과 또는 크기 초과
    if (_pendingPoints.length >= _maxPointsPerBatch) {
      _flush();
      return;
    }

    // 타이머 기반 플러시
    _batchTimer ??= Timer(
      Duration(milliseconds: _batchWindowMs),
      _flush,
    );
  }

  void _flush() {
    _batchTimer?.cancel();
    _batchTimer = null;
    if (_pendingPoints.isEmpty) return;

    final batch = StrokePointsBatch()
      ..points.addAll(_pendingPoints)
      ..sequenceNum = Int64(_nextSequence++);
    _pendingPoints.clear();

    _onBatchReady(batch);
  }
}
```

### 3.2 스트로크 완료 흐름 (Reliable)

```
선생님 디바이스                                학생 디바이스
─────────────                              ─────────────
Pointer Up / Stylus Lift
    │
    ▼
ScribbleController.finishStroke()
    │
    ▼
ScribbleEventBridge
  → StrokeAddedEvent(pageId, stroke, strokeIndex)
    │
    ▼
LiveSessionController
    │
    ├── TimelineRecorder.record(event)    // .obt 타임라인 기록
    │
    ▼
StrokeCompleteMessage protobuf
    │
    ▼
LiveKitTransport.sendReliable(
  topic: "stroke.complete",
  data: bytes
)
    │
    ▼ Reliable Data Channel (순서/전달 보장)
    │
    ▼
LiveKit SFU ────────────────────────────▶ LiveKitTransport.onData()
                                              │
                                              ▼
                                         StrokeCompleteMessage 역직렬화
                                              │
                                              ▼
                                         RemoteStrokeRenderer
                                         .finalizeStroke(stroke)
                                              │
                                         1. 포인트 스트리밍 잔여분 보정
                                         2. 전체 Stroke로 교체 렌더링
                                              │
                                              ▼
                                         ScribbleController
                                         .addRemoteStroke(stroke)
```

### 3.3 이벤트 배칭 전략

| 이벤트 유형 | 채널 | 배칭 | 이유 |
|------------|------|------|------|
| 포인트 스트리밍 | Lossy | 100ms 윈도우, 최대 20개/배치 | 네트워크 효율, Lossy 손실 허용 |
| 스트로크 완료 | Reliable | 즉시 전송 | 데이터 정합성 필수 |
| 페이지 전환/추가/삭제 | Reliable | 즉시 전송 | 상태 동기화 필수 |
| Undo/Redo | Reliable | 즉시 전송 | 상태 동기화 필수 |
| 뷰포트 변경 | Lossy | 100ms 쓰로틀 (최신값만) | 중간값 불필요 |

### 3.4 충돌 해결

Phase 1은 1:1이므로 복잡한 CRDT나 OT는 불필요하다. 다음 원칙으로 단순화한다.

| 원칙 | 설명 |
|------|------|
| **선생님 필기 우선** | 선생님만 필기 권한을 가진다. 학생은 읽기 전용이다. |
| **단일 쓰기자** | 동시에 한 명만 쓴다. 향후 Phase 3에서 권한 토글로 확장 가능. |
| **서버 비개입** | LiveKit SFU는 릴레이만 수행. 서버에서 충돌 해결 로직 없음. |
| **Last-Write-Wins** | 네트워크 지연으로 순서 역전 시 timestampMicros 기준으로 정렬. |

---

## 4. 뷰포트 동기화 설계

### 4.1 ViewportChangedEvent 구조

```dart
class ViewportChangedEvent extends ScribbleBookEvent {
  final String pageId;
  final double scale;           // 1.0 = 원본 크기
  final double centerX;         // 캔버스 좌표계 기준 중심점 X
  final double centerY;         // 캔버스 좌표계 기준 중심점 Y
  final double viewportWidth;   // 현재 디바이스의 논리 뷰포트 너비 (dp)
  final double viewportHeight;  // 현재 디바이스의 논리 뷰포트 높이 (dp)

  const ViewportChangedEvent({
    required this.pageId,
    required this.scale,
    required this.centerX,
    required this.centerY,
    required this.viewportWidth,
    required this.viewportHeight,
    required super.timestampMicros,
  });

  /// 캔버스 좌표계에서의 가시 영역 (선생님 디바이스 기준)
  Rect get visibleRect => Rect.fromCenter(
    center: Offset(centerX, centerY),
    width: viewportWidth / scale,
    height: viewportHeight / scale,
  );
}
```

### 4.2 쓰로틀링 전략 (100ms)

뷰포트 변경은 pinch-zoom, pan 제스처 중 초당 60~120회 발생할 수 있다. 네트워크 효율을 위해 100ms 간격으로 쓰로틀링하며, 윈도우 내 최신 값만 전송한다.

```dart
class ViewportThrottler {
  static const _throttleMs = 100;

  Timer? _timer;
  ViewportChangedEvent? _pending;

  void onViewportChanged(ViewportChangedEvent event) {
    _pending = event;  // 항상 최신값으로 덮어쓰기

    _timer ??= Timer(
      Duration(milliseconds: _throttleMs),
      _flush,
    );
  }

  void _flush() {
    _timer = null;
    if (_pending == null) return;

    final event = _pending!;
    _pending = null;

    _onThrottled(event);  // Transport로 전송
  }
}
```

### 4.3 멀티디바이스 어댑티브 렌더링 알고리즘

선생님과 학생의 디바이스 화면 비율이 다를 때, 선생님이 보는 영역의 중심을 기준으로 학생 디바이스에 최적화된 뷰포트를 계산한다.

```dart
/// 선생님 뷰포트를 학생 디바이스에 적응 변환
class AdaptiveViewportCalculator {
  /// [teacherViewport] 선생님의 ViewportChangedEvent
  /// [studentScreenSize] 학생 디바이스의 논리 화면 크기 (dp)
  ///
  /// Returns: 학생 디바이스에 적용할 (center, scale) 쌍
  static ({Offset center, double scale}) calculate({
    required ViewportChangedEvent teacherViewport,
    required Size studentScreenSize,
  }) {
    // 1. 선생님의 캔버스 좌표 기준 가시 영역 계산
    final teacherVisibleWidth =
        teacherViewport.viewportWidth / teacherViewport.scale;
    final teacherVisibleHeight =
        teacherViewport.viewportHeight / teacherViewport.scale;

    // 2. 학생 디바이스 비율로 가시 영역 재계산
    //    선생님의 가시 영역을 모두 포함하면서 학생 비율에 맞춤
    final studentAspect =
        studentScreenSize.width / studentScreenSize.height;
    final teacherAspect = teacherVisibleWidth / teacherVisibleHeight;

    double studentVisibleWidth;
    double studentVisibleHeight;

    if (studentAspect > teacherAspect) {
      // 학생이 더 넓음 → 높이 기준, 좌우 여백
      studentVisibleHeight = teacherVisibleHeight;
      studentVisibleWidth = teacherVisibleHeight * studentAspect;
    } else {
      // 학생이 더 좁음 → 너비 기준, 상하 여백
      studentVisibleWidth = teacherVisibleWidth;
      studentVisibleHeight = teacherVisibleWidth / studentAspect;
    }

    // 3. 학생 scale 계산
    final scale = studentScreenSize.width / studentVisibleWidth;

    // 4. 중심점은 선생님과 동일 (핵심: 선생님이 가리키는 곳이 화면 중심)
    final center = Offset(
      teacherViewport.centerX,
      teacherViewport.centerY,
    );

    return (center: center, scale: scale);
  }
}
```

**동작 예시:**

```
선생님 iPad (4:3, 1024x768 dp)
  scale: 2.0, center: (500, 300)
  → 캔버스 가시 영역: 512 x 384 (center 기준)

학생 iPhone (19.5:9, 390x844 dp 기준 가로모드 844x390)
  → 학생 aspect: 2.164
  → 선생님 aspect: 1.333
  → 학생이 더 넓으므로 높이 기준
  → studentVisibleHeight = 384
  → studentVisibleWidth = 384 * 2.164 = 831.0
  → scale = 844 / 831.0 = 1.016
  → center: (500, 300) (동일)
  → 결과: 선생님이 가리킨 (500,300) 영역이 학생 화면 중심에 위치
          좌우로 선생님보다 더 넓은 영역이 보이지만 핵심 영역은 정중앙
```

---

## 5. 세션 라이프사이클

### 5.1 상태 흐름

```
                    App Server
                    ──────────
  [POST /session]       │
        │               ▼
        │         ┌───────────┐
        │         │  created   │
        │         └─────┬─────┘
        │               │ 선생님 joinRoom()
        │               ▼
        │         ┌───────────┐
        │         │  waiting   │   선생님이 필기 준비 가능
        │         └─────┬─────┘   (아직 이벤트 전송 안 함)
        │               │ 학생 joinRoom()
        │               ▼
        │         ┌───────────┐
        │         │  active    │   양방향 데이터 채널 활성
        │         └─────┬─────┘   타임라인 녹화 시작
        │               │
        │    ┌──────────┤
        │    │          │ 학생 일시 이탈 (네트워크 끊김)
        │    │          ▼
        │    │    ┌───────────┐
        │    │    │  active    │   선생님은 계속 필기 가능
        │    │    └─────┬─────┘   학생 재입장 시 sync
        │    │          │
        │    └──────────┘
        │               │ 선생님 endSession()
        │               ▼
        │         ┌───────────┐
        │         │  ended     │   .obt + .bin 업로드
        │         └─────┬─────┘   Egress 녹화 종료
        │               │
        │               ▼
        │         리플레이 가능 (.obt + MP4)
        ▼
```

### 5.2 LiveKit Room 매핑

| LiveSession 필드 | LiveKit 매핑 |
|-----------------|-------------|
| `sessionId` | `Room.name` (1:1 매핑) |
| `participant.token` | LiveKit Access Token (API Key + Secret으로 서명) |
| `participant.role` | Token의 `metadata` 필드에 JSON 인코딩 |
| `state: active` | Room에 2명 이상 연결 |
| `state: ended` | Room 삭제 + Egress 종료 |

**토큰 생성 (서버측):**

```dart
// Serverpod Endpoint
class LiveSessionEndpoint extends Endpoint {
  Future<SessionJoinResponse> joinSession(
    Session session,
    String sessionId,
    String participantId,
    String role,
  ) async {
    final liveSession = await _sessionRepo.findById(sessionId);

    // LiveKit Access Token 생성
    final token = LiveKitTokenBuilder()
      .setIdentity(participantId)
      .setName(displayName)
      .setMetadata(jsonEncode({'role': role}))
      .addGrant(RoomGrant(
        roomJoin: true,
        room: sessionId,
        canPublish: true,       // data channel publish
        canPublishData: true,
        canSubscribe: true,
      ))
      .setTtl(Duration(hours: 4))
      .build(apiKey, apiSecret);

    return SessionJoinResponse(
      token: token,
      wsUrl: livekitWsUrl,
      sessionId: sessionId,
    );
  }
}
```

### 5.3 늦은 참가자 동기화 전략

학생이 중간에 입장하거나 네트워크 끊김 후 재접속할 때, 현재 상태를 빠르게 동기화해야 한다.

**전략: Scribble 스냅샷 + 이벤트 리플레이**

```
학생 재접속 흐름:

  학생 Client                선생님 Client / Server
  ───────────              ──────────────────────
  joinRoom()
      │
      ▼
  SyncRequestMessage ──────▶ onSyncRequest()
  (topic: "sync.request")       │
                                ▼
                           1. 현재 Scribble 스냅샷 생성
                              (모든 페이지의 Scribble protobuf)
                           2. 현재 뷰포트 상태
                           3. 현재 페이지 인덱스
                                │
                                ▼
                           SyncResponseMessage (분할 전송)
  ◀──────────────────────  (topic: "sync.response")
      │
      ▼
  1. 청크 조립
  2. 각 페이지 Scribble 로드
     ScribbleController.loadScribble()
  3. 뷰포트 적용
  4. 이후 실시간 이벤트 수신 시작
```

**분할 전송**: Scribble 스냅샷이 15KiB를 초과할 수 있으므로, `chunkIndex`/`totalChunks` 필드로 분할한다. Reliable 채널을 사용하므로 순서와 전달이 보장된다.

**동기화 윈도우**: SyncRequest ~ SyncResponse 사이에 발생한 이벤트는 학생 Client에서 버퍼링한다. 스냅샷 적용 후 버퍼링된 이벤트를 순차 적용하여 누락 없이 동기화한다.

```dart
class LateJoinSynchronizer {
  final Queue<ScribbleBookEvent> _eventBuffer = Queue();
  bool _isSyncing = false;

  void onRemoteEvent(ScribbleBookEvent event) {
    if (_isSyncing) {
      _eventBuffer.add(event);  // 동기화 중에는 버퍼링
      return;
    }
    _applyEvent(event);
  }

  Future<void> onSyncResponse(SyncResponseMessage response) async {
    // 스냅샷 적용
    await _applySnapshot(response);

    // 버퍼링된 이벤트 순차 적용
    while (_eventBuffer.isNotEmpty) {
      final event = _eventBuffer.removeFirst();
      // snapshotTimestamp 이후 이벤트만 적용
      if (event.timestampMicros > response.snapshotTimestamp) {
        _applyEvent(event);
      }
    }

    _isSyncing = false;
  }
}
```

---

## 6. 리플레이 확장

### 6.1 기존 .obt에 ViewportEvent 추가

기존 `ScribbleTimelineRecorder`를 확장하여 `ViewportChangedEvent`와 `SessionParticipantEvent`를 타임라인에 기록한다.

```dart
// ScribbleTimelineRecorder._convertToTimelineEvent 확장
TimelineEvent _convertToTimelineEvent(ScribbleBookEvent event) {
  final timestamp = Int64(event.timestampMicros);

  final data = switch (event) {
    // 기존 8종 ...
    ViewportChangedEvent(:final pageId, :final scale,
        :final centerX, :final centerY,
        :final viewportWidth, :final viewportHeight) =>
      TlViewportChanged(
        pageId: pageId,
        scale: scale,
        centerX: centerX,
        centerY: centerY,
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
      ),
    SessionParticipantEvent(:final participantId,
        :final displayName, :final role, :final action) =>
      TlSessionParticipant(
        participantId: participantId,
        displayName: displayName,
        role: role.name,
        action: action.name,
      ),
    // ...
  };

  return TimelineEvent(timestamp: timestamp, event: data);
}
```

### 6.2 리플레이 시 뷰포트 재현 흐름

```
.obt 파일 로드
    │
    ▼
ScribbleReplayController.loadFromFile()
    │
    ▼
이벤트 스트림 재생 (60fps 타이머)
    │
    ├── StrokeAddedEvent → StrokeAnimator.createPartialStroke()
    │                      (기존 로직, 변경 없음)
    │
    ├── ViewportChangedEvent ─────▶ 새로 추가
    │       │
    │       ▼
    │   AdaptiveViewportCalculator.calculate(
    │     teacherViewport: event,
    │     studentScreenSize: currentDeviceSize,
    │   )
    │       │
    │       ▼
    │   TransformationController.value = Matrix4(...)
    │   (줌/팬 애니메이션으로 부드럽게 전환)
    │
    └── PageChangedEvent → 페이지 전환 (기존 로직)
```

**뷰포트 애니메이션**: 뷰포트가 급격하게 변할 때(페이지 전환 직후 등) 사용자 경험을 위해 200ms `AnimationController`로 부드럽게 전환한다.

```dart
class ViewportAnimator {
  late final AnimationController _controller;
  Offset _fromCenter = Offset.zero;
  Offset _toCenter = Offset.zero;
  double _fromScale = 1.0;
  double _toScale = 1.0;

  void animateTo({
    required Offset center,
    required double scale,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    _fromCenter = _currentCenter;
    _fromScale = _currentScale;
    _toCenter = center;
    _toScale = scale;

    _controller.duration = duration;
    _controller.forward(from: 0);
  }

  // _controller.addListener에서 Offset.lerp, lerpDouble로 보간
}
```

### 6.3 오디오 동기화 (LiveKit Egress MP4 + .obt 타임라인)

세션 종료 시 두 개의 파일이 생성된다.

| 파일 | 내용 | 시간 기준 |
|------|------|----------|
| `.obt` | 필기 + 뷰포트 타임라인 | `startTimestamp` (epoch 마이크로초) |
| `.mp4` | 음성 녹화 (LiveKit Egress) | Egress 시작 시각 (epoch) |

**동기화 전략:**

```dart
class SyncedReplayController {
  final ScribbleReplayController _replayController;
  final AudioPlayer _audioPlayer;  // just_audio 등

  /// .obt startTimestamp와 MP4 시작 시각의 차이 (마이크로초)
  late final int _offsetMicros;

  Future<void> load({
    required String obtPath,
    required String mp4Url,
    required int egressStartTimestamp,  // 서버에서 제공
  }) async {
    await _replayController.loadFromFile(obtPath);
    await _audioPlayer.setUrl(mp4Url);

    // 오프셋 계산: .obt 시작 시각 - Egress 시작 시각
    final obtStart = _replayController.timeline.startTimestamp;
    _offsetMicros = obtStart - egressStartTimestamp;
  }

  void play() {
    _replayController.play();
    // 오디오는 오프셋만큼 조정하여 재생
    final audioPosition = Duration(
      microseconds: _replayController.positionMicros - _offsetMicros,
    );
    _audioPlayer.seek(audioPosition.isNegative ? Duration.zero : audioPosition);
    _audioPlayer.play();
  }

  void seek(Duration position) {
    _replayController.seek(position);
    final audioPosition = Duration(
      microseconds: position.inMicroseconds - _offsetMicros,
    );
    _audioPlayer.seek(audioPosition.isNegative ? Duration.zero : audioPosition);
  }

  /// 주기적 드리프트 보정 (500ms 간격)
  void _correctDrift() {
    final replayPos = _replayController.positionMicros;
    final audioPos = _audioPlayer.position.inMicroseconds + _offsetMicros;
    final drift = (replayPos - audioPos).abs();

    if (drift > 200000) {  // 200ms 초과 드리프트
      _audioPlayer.seek(Duration(
        microseconds: replayPos - _offsetMicros,
      ));
    }
  }
}
```

---

## 7. Transport 추상화 인터페이스

### 7.1 핵심 인터페이스

```dart
/// 실시간 세션 Transport 추상화
///
/// LiveKit, WebSocket, 로컬 루프백 등 다양한 구현을 교체 가능하게 한다.
/// open-board 코어 패키지에는 이 인터페이스만 포함되며,
/// LiveKit 구현은 별도 패키지(open_board_livekit)로 분리한다.
abstract class LiveSessionTransport {
  /// 세션 연결
  Future<void> connect(String sessionId, String token);

  /// 연결 해제
  Future<void> disconnect();

  /// 연결 상태
  Stream<TransportConnectionState> get connectionState;

  // ── 필기 이벤트 ──

  /// 로컬 ScribbleBookEvent 전송
  void sendEvent(ScribbleBookEvent event);

  /// 진행 중인 스트로크 포인트 배치 전송 (Lossy)
  void sendStrokePoints(StrokePointsBatch batch);

  /// 완료된 스트로크 전송 (Reliable)
  void sendStrokeComplete(StrokeCompleteMessage message);

  /// 원격 필기 이벤트 수신 스트림
  Stream<ScribbleBookEvent> get remoteEvents;

  /// 원격 스트로크 포인트 배치 수신 스트림
  Stream<StrokePointsBatch> get remoteStrokePoints;

  /// 원격 스트로크 완료 수신 스트림
  Stream<StrokeCompleteMessage> get remoteStrokeCompletes;

  // ── 뷰포트 ──

  /// 뷰포트 변경 전송 (Lossy)
  void sendViewport(ViewportChangedEvent event);

  /// 원격 뷰포트 변경 수신 스트림
  Stream<ViewportChangedEvent> get remoteViewports;

  // ── 동기화 ──

  /// 동기화 요청 전송
  Future<void> requestSync();

  /// 동기화 응답 전송
  Future<void> sendSyncResponse(SyncResponseMessage response);

  /// 동기화 요청 수신 스트림
  Stream<SyncRequestMessage> get syncRequests;

  /// 동기화 응답 수신 스트림
  Stream<SyncResponseMessage> get syncResponses;

  // ── 메타 ──

  /// 현재 참가자 목록
  List<RemoteParticipant> get participants;

  /// 참가자 변경 스트림
  Stream<ParticipantEvent> get participantEvents;
}

enum TransportConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
```

### 7.2 LiveKit 구현 스켈레톤

```dart
class LiveKitTransport implements LiveSessionTransport {
  Room? _room;
  final _eventController = StreamController<ScribbleBookEvent>.broadcast();
  final _viewportController = StreamController<ViewportChangedEvent>.broadcast();
  final _strokePointsController = StreamController<StrokePointsBatch>.broadcast();
  final _strokeCompleteController = StreamController<StrokeCompleteMessage>.broadcast();

  @override
  Future<void> connect(String sessionId, String token) async {
    _room = Room();
    await _room!.connect(
      wsUrl,
      token,
      roomOptions: const RoomOptions(
        adaptiveStream: false,  // 영상 미사용
        dynacast: false,
      ),
    );

    _room!.onDataReceived = _handleDataReceived;
  }

  void _handleDataReceived(
    List<int> data,
    String? topic,
    RemoteParticipant? participant,
  ) {
    switch (topic) {
      case 'stroke.points':
        final batch = StrokePointsBatch.fromBuffer(data);
        _strokePointsController.add(batch);
      case 'stroke.complete':
        final msg = StrokeCompleteMessage.fromBuffer(data);
        _strokeCompleteController.add(msg);
        // ScribbleBookEvent로도 변환하여 발행
        _eventController.add(StrokeAddedEvent(
          pageId: msg.pageId,
          stroke: msg.stroke,
          strokeIndex: msg.strokeIndex,
          timestampMicros: msg.timestampMicros.toInt(),
        ));
      case 'viewport':
        final msg = ViewportMessage.fromBuffer(data);
        _viewportController.add(_toViewportEvent(msg));
      case 'event':
        final msg = ScribbleEventMessage.fromBuffer(data);
        _eventController.add(_toBookEvent(msg));
      // ...
    }
  }

  @override
  void sendStrokePoints(StrokePointsBatch batch) {
    _room?.localParticipant?.publishData(
      batch.writeToBuffer(),
      reliable: false,  // Lossy
      topic: 'stroke.points',
    );
  }

  @override
  void sendStrokeComplete(StrokeCompleteMessage message) {
    _room?.localParticipant?.publishData(
      message.writeToBuffer(),
      reliable: true,   // Reliable
      topic: 'stroke.complete',
    );
  }

  @override
  void sendViewport(ViewportChangedEvent event) {
    final msg = _toViewportMessage(event);
    _room?.localParticipant?.publishData(
      msg.writeToBuffer(),
      reliable: false,  // Lossy
      topic: 'viewport',
    );
  }

  // ... 나머지 구현
}
```

### 7.3 테스트용 LocalLoopbackTransport

```dart
/// 네트워크 없이 단일 프로세스 내에서 양방향 이벤트를 루프백하는 Transport
///
/// 통합 테스트 및 UI 프로토타이핑에 사용한다.
class LocalLoopbackTransport implements LiveSessionTransport {
  LocalLoopbackTransport? _peer;

  void linkPeer(LocalLoopbackTransport peer) {
    _peer = peer;
    peer._peer = this;
  }

  @override
  void sendEvent(ScribbleBookEvent event) {
    // 10ms 지연 시뮬레이션 후 peer에게 전달
    Future.delayed(Duration(milliseconds: 10), () {
      _peer?._eventController.add(event);
    });
  }
  // ...
}
```

---

## 8. 시퀀스 다이어그램

### 8.1 선생님 필기 -> 학생 화면에 나타나기까지

```
  선생님 Client        LiveKit SFU        학생 Client
  ─────────────       ──────────         ─────────────
       │                   │                   │
  [Pen Down]               │                   │
       │                   │                   │
  addPoint(p1)             │                   │
  addPoint(p2)             │                   │
  addPoint(p3)             │                   │
       │                   │                   │
  ── 100ms 배치 윈도우 ──   │                   │
       │                   │                   │
  StrokePointsBatch ──────▶│                   │
  (Lossy, topic:           │                   │
   stroke.points)          │──────────────────▶│
                           │  (Lossy relay)     │
                           │                   │ appendPoints()
                           │                   │ canvas repaint
  addPoint(p4..p7)         │                   │
       │                   │                   │
  ── 100ms 배치 윈도우 ──   │                   │
       │                   │                   │
  StrokePointsBatch ──────▶│──────────────────▶│
                           │                   │ appendPoints()
  [Pen Up]                 │                   │
       │                   │                   │
  finishStroke()           │                   │
       │                   │                   │
  StrokeCompleteMsg ──────▶│                   │
  (Reliable, topic:        │──────────────────▶│
   stroke.complete)        │                   │ finalizeStroke()
                           │                   │ 전체 Stroke 교체
       │                   │                   │
  총 지연: ~100ms(배치) + ~50ms(네트워크) = ~150ms (P95)
```

### 8.2 세션 시작 -> 참가 -> 필기 -> 종료 -> 리플레이

```
  선생님 Client      App Server       LiveKit SFU      학생 Client
  ─────────────     ──────────       ──────────       ─────────────
       │                │                │                │
  POST /session ──────▶ │                │                │
       │                │ createRoom() ──▶                │
       │◀── sessionId ──│                │                │
       │                │                │                │
  POST /join ──────────▶│                │                │
       │◀── token ──────│                │                │
       │                │                │                │
  room.connect(token) ──┼───────────────▶│                │
       │                │  state:waiting │                │
       │                │                │                │
       │                │                │    POST /join ─┤
       │                │                │◀── token ──────│
       │                │                │                │
       │                │  room.connect()│◀───────────────│
       │                │  state:active  │                │
       │                │                │                │
  startRecording()      │                │                │
  TimelineRecorder      │                │                │
  .start()              │                │                │
       │                │                │                │
  ─── 필기 시작 ───      │                │                │
       │                │                │                │
  [StrokePoints] ──────▶│ ──────────────▶│ ──────────────▶│ render
  [StrokeComplete] ────▶│ ──────────────▶│ ──────────────▶│ add
  [Viewport] ──────────▶│ ──────────────▶│ ──────────────▶│ zoom/pan
  [PageChanged] ───────▶│ ──────────────▶│ ──────────────▶│ navigate
       │                │                │                │
  ─── 수업 종료 ───      │                │                │
       │                │                │                │
  endSession() ────────▶│                │                │
       │                │ stopEgress() ──▶ → MP4 저장     │
       │                │                │                │
  timeline = recorder   │                │                │
    .stop()             │                │                │
  .obt 파일 저장         │                │                │
  upload(.obt) ────────▶│ → Object Store │                │
       │                │                │                │
  room.disconnect()     │                │  disconnect()  │
       │                │  deleteRoom() ▶│                │
       │                │                │                │
  ═══ 리플레이 ═══       │                │                │
       │                │                │                │
       │                │                │  GET /replay ──│
       │                │                │◀── .obt URL ───│
       │                │                │◀── MP4 URL ────│
       │                │                │                │
       │                │                │  SyncedReplay   │
       │                │                │  Controller     │
       │                │                │  .load(obt,mp4) │
       │                │                │  .play()        │
```

---

## 9. 비기능 요구사항

### 9.1 성능

| 항목 | 목표 | 측정 방법 |
|------|------|----------|
| **필기 동기화 지연** | < 150ms (P95) | 선생님 penDown ~ 학생 화면 첫 렌더링 |
| **뷰포트 동기화 지연** | < 200ms (P95) | 선생님 제스처 ~ 학생 뷰포트 변경 |
| **스트로크 완료 보장** | 100% 전달 | Reliable 채널 + 재전송 |
| **리플레이 로드 시간** | < 2초 (60분 수업) | .obt 파일 파싱 ~ 첫 프레임 |
| **메모리 사용량** | < 100MB (60분 수업) | 타임라인 + Scribble 데이터 |

### 9.2 네트워크

| 항목 | 수치 |
|------|------|
| **최소 대역폭** | 1 Mbps (양방향) |
| **권장 대역폭** | 5 Mbps (양방향, 음성 포함) |
| **포인트 배치 크기** | ~200B / 100ms |
| **스트로크 완료 크기** | ~1-5 KB / 스트로크 |
| **뷰포트 메시지 크기** | ~40B / 100ms |
| **예상 총 트래픽** | ~50 KB/min (필기만), ~500 KB/min (음성 포함) |

### 9.3 오프라인 / Graceful Degradation

```
네트워크 품질 감지
    │
    ├── Good (RTT < 100ms, loss < 1%)
    │   └── 정상 동작: Lossy + Reliable 병행
    │
    ├── Degraded (RTT 100-500ms, loss 1-5%)
    │   ├── 배치 윈도우 200ms로 확대 (트래픽 감소)
    │   ├── 뷰포트 쓰로틀 300ms로 확대
    │   └── UI에 "네트워크 불안정" 인디케이터 표시
    │
    ├── Poor (RTT > 500ms, loss > 5%)
    │   ├── Lossy 포인트 스트리밍 중단
    │   ├── Reliable 스트로크 완료만 전송
    │   ├── 뷰포트 동기화 중단
    │   └── UI에 "연결 불안정, 스트로크 단위 동기화" 표시
    │
    └── Disconnected
        ├── 로컬 필기/타임라인 녹화 계속 (선생님)
        ├── 로컬 이벤트 큐에 축적
        ├── 재연결 시 LateJoinSynchronizer로 상태 복구
        └── UI에 "오프라인 모드, 재연결 시도 중" 표시
```

### 9.4 보안

| 항목 | 구현 |
|------|------|
| **인증** | App Server JWT → LiveKit Access Token 변환 |
| **인가** | Token metadata의 role 필드로 권한 제어 (teacher/student) |
| **전송 암호화** | LiveKit DTLS-SRTP (Data Channel), TLS 1.3 (Signaling) |
| **데이터 저장** | .obt, .bin은 사용자 ID 기반 접근 제어 (S3 IAM Policy) |
| **토큰 만료** | Access Token TTL 4시간, Refresh 메커니즘 |

### 9.5 관측성 (Observability)

| 레이어 | 메트릭 | 수집 |
|--------|--------|------|
| **클라이언트** | 포인트 배치 전송 수, 스트로크 완료 수, 동기화 지연, 메모리 사용량 | 앱 내 수집 → 서버 리포트 |
| **Transport** | RTT, 패킷 손실률, 재연결 횟수, Data Channel 처리량 | LiveKit Client Stats API |
| **서버** | 활성 세션 수, 토큰 발급 수, 스냅샷 크기, .obt 업로드 성공률 | Serverpod 로깅 |
| **LiveKit** | Room 참가자 수, Egress 상태, SFU 리소스 사용량 | LiveKit Dashboard / Prometheus |

---

## 10. 구현 우선순위 및 이슈 분해

### 10.1 Epic -> Story -> Task 분해

#### Epic 1: Transport 추상화 및 LiveKit 연결 (2주)

| Story | Task | 예상 |
|-------|------|------|
| **S1.1** LiveSessionTransport 인터페이스 정의 | T1. 인터페이스 설계 및 코드 작성 | 2d |
| | T2. TransportConnectionState 상태 머신 | 1d |
| | T3. LocalLoopbackTransport 구현 + 단위 테스트 | 2d |
| **S1.2** LiveKitTransport 레퍼런스 구현 (Example 앱) | T1. Room 연결/해제 | 1d |
| | T2. Topic별 Lossy/Reliable 데이터 송수신 | 2d |
| | T3. 재연결 로직 (exponential backoff) | 1d |
| | T4. 연결 상태 모니터링 + 메트릭 수집 | 1d |
| | *Note: open_board 패키지가 아닌 Example 앱에 구현. 소비자 앱 레퍼런스로 제공.* | |
| **S1.3** Protobuf 메시지 정의 | T1. message.proto 작성 (StrokePointsBatch, StrokeCompleteMessage 등) | 1d |
| | T2. protoc 코드 생성 설정 | 0.5d |
| | T3. 직렬화/역직렬화 벤치마크 | 0.5d |

#### Epic 2: 실시간 필기 동기화 (2주)

| Story | Task | 예상 |
|-------|------|------|
| **S2.1** 포인트 스트리밍 (Lossy) | T1. EventBatcher 구현 (100ms 윈도우) | 1d |
| | T2. 선생님 → 학생 포인트 전송 | 1d |
| | T3. RemoteStrokeRenderer (수신 포인트 실시간 렌더링) | 2d |
| | T4. 패킷 손실 시 부분 스트로크 렌더링 처리 | 1d |
| **S2.2** 스트로크 완료 (Reliable) | T1. StrokeCompleteMessage 전송 로직 | 1d |
| | T2. 수신 측 전체 Stroke 교체 렌더링 | 1d |
| | T3. 포인트 스트리밍 → 완료 전환 시 시각적 글리치 방지 | 1d |
| **S2.3** 페이지/기타 이벤트 동기화 | T1. PageChanged, PageAdded, PageRemoved 동기화 | 1d |
| | T2. Undo/Redo 동기화 | 0.5d |
| | T3. PageCleared 동기화 | 0.5d |

#### Epic 3: 뷰포트 동기화 (1주)

| Story | Task | 예상 |
|-------|------|------|
| **S3.1** ViewportChangedEvent 추가 | T1. ScribbleBookEvent에 ViewportChangedEvent 추가 | 0.5d |
| | T2. ViewportTracker (제스처 → 이벤트 변환) | 1d |
| | T3. ViewportThrottler (100ms) | 0.5d |
| **S3.2** 멀티디바이스 어댑티브 렌더링 | T1. AdaptiveViewportCalculator 구현 | 1d |
| | T2. ViewportAnimator (부드러운 전환) | 1d |
| | T3. 다양한 디바이스 비율 테스트 (4:3, 16:9, 19.5:9) | 0.5d |

#### Epic 4: 세션 라이프사이클 (1.5주)

| Story | Task | 예상 |
|-------|------|------|
| **S4.1** 서버: 세션 CRUD API | T1. LiveSession 모델 + DB 마이그레이션 | 1d |
| | T2. 세션 생성/조회/종료 Endpoint | 1d |
| | T3. LiveKit 토큰 발급 | 0.5d |
| **S4.2** 클라이언트: 세션 참가 흐름 | T1. LiveSessionController (상태 머신) | 1d |
| | T2. 세션 참가 UI (대기실) | 1d |
| **S4.3** 늦은 참가자 동기화 | T1. SyncRequest/Response 메시지 구현 | 1d |
| | T2. LateJoinSynchronizer 구현 | 1.5d |
| | T3. 스냅샷 분할 전송 | 0.5d |

#### Epic 5: 타임라인 녹화 + 리플레이 확장 (1.5주)

| Story | Task | 예상 |
|-------|------|------|
| **S5.1** 타임라인에 ViewportEvent 추가 | T1. timeline.proto 확장 (TlViewportChanged) | 0.5d |
| | T2. timeline_models.dart 확장 | 0.5d |
| | T3. ScribbleTimelineRecorder 확장 | 0.5d |
| | T4. ScribbleReplayController 확장 | 0.5d |
| **S5.2** 리플레이 뷰포트 재현 | T1. 리플레이 시 AdaptiveViewportCalculator 적용 | 1d |
| | T2. 뷰포트 애니메이션 재생 | 0.5d |
| **S5.3** 오디오 동기화 리플레이 | T1. SyncedReplayController 구현 | 1d |
| | T2. 오디오-타임라인 오프셋 계산 | 0.5d |
| | T3. 드리프트 보정 로직 | 0.5d |
| **S5.4** .obt 업로드/다운로드 | T1. Object Store 업로드 API | 0.5d |
| | T2. .obt + MP4 다운로드 + 리플레이 로드 | 0.5d |

#### Epic 6: Egress 녹화 연동 (0.5주)

| Story | Task | 예상 |
|-------|------|------|
| **S6.1** LiveKit Egress 설정 | T1. Egress API 연동 (startRoomCompositeEgress) | 1d |
| | T2. 세션 종료 시 Egress 중지 + MP4 URL 획득 | 0.5d |
| | T3. MP4를 Object Store에 저장 | 0.5d |

### 10.2 예상 구현 순서

```
Week 1-2:  Epic 1 (Transport 추상화 + LiveKit 연결)
           ├── 인터페이스 확정 → 이후 Epic이 병렬 진행 가능
           └── PoC: Data Channel 왕복 지연 측정

Week 3-4:  Epic 2 (실시간 필기 동기화)
           ├── 포인트 스트리밍 + 스트로크 완료 흐름 구현
           └── 마일스톤: 선생님 필기가 학생 화면에 실시간 표시

Week 5:    Epic 3 (뷰포트 동기화)
           ├── ViewportChangedEvent + 어댑티브 렌더링
           └── 마일스톤: 선생님 줌/팬이 학생 화면에 반영

Week 5-6:  Epic 4 (세션 라이프사이클) -- Epic 3과 병렬 진행
           ├── 서버 API + 토큰 발급 + 세션 참가 흐름
           └── 마일스톤: 세션 생성~참가~종료 전체 흐름

Week 7:    Epic 5 (리플레이 확장)
           ├── .obt에 뷰포트 이벤트 추가
           ├── 오디오 동기화 리플레이
           └── 마일스톤: 수업 종료 후 리플레이 재생 가능

Week 8:    Epic 6 (Egress 녹화) + 통합 테스트 + 버그 픽스
           └── 최종 마일스톤: End-to-End 1:1 과외 + 리플레이 완동
```

### 10.3 핵심 마일스톤 체크포인트

| 주차 | 마일스톤 | 검증 기준 |
|------|---------|----------|
| **Week 2** | Transport PoC | Data Channel RTT < 100ms, LocalLoopback 테스트 통과 |
| **Week 4** | 실시간 필기 데모 | 선생님 필기 → 학생 화면 동기화, 지연 < 150ms |
| **Week 5** | 뷰포트 동기화 | 선생님 줌/팬 → 학생 화면 적응 렌더링 |
| **Week 6** | 세션 관리 | 세션 생성 → 참가 → 종료 전체 흐름 |
| **Week 7** | 리플레이 | 수업 종료 → .obt 저장 → 리플레이 재생 (뷰포트 + 오디오) |
| **Week 8** | MVP 완성 | 1:1 과외 전체 시나리오 E2E 테스트 통과 |
