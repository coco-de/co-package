# Phase 1 아키텍처 설계: 실시간 튜터링 Live Session 모듈

> open-board 필기 엔진 위에 Clean Architecture 기반 실시간 세션 모듈을 추가하는 설계 문서

- **상위 문서**: [Tech Spec: Phase 1 기술 사양서](./tech-spec-live-tutoring-phase1.md)
- **범위**: `lib/src/module/live/` 신규 모듈 전체 아키텍처
- **원칙**: 기존 open-board 코어 코드 최소 변경, Transport 추상화 기반 교체 가능성 확보

---

## 1. Clean Architecture 레이어 설계

### 1.1 설계 원칙

기존 open-board는 `lib/src/module/` 아래에 기능별 flat 구조(`events/`, `managers/`, `replay/`, `state/`, `widgets/`)로 구성되어 있다. 이 구조를 변경하지 않는다.

새로 추가하는 live session 모듈은 `lib/src/module/live/` 하위에 Clean Architecture 3-Layer로 설계한다. 이유는 다음과 같다.

| 이유 | 설명 |
|------|------|
| **외부 의존성 격리** | LiveKit SDK는 domain/presentation에 직접 노출되지 않아야 한다. Transport 추상화로 격리한다. |
| **테스트 용이성** | `LocalLoopbackTransport`로 네트워크 없이 전체 흐름을 단위 테스트할 수 있어야 한다. |
| **교체 가능성** | LiveKit -> WebSocket, gRPC 등으로 Transport 구현체만 교체 가능해야 한다. |
| **기존 코드 비침투** | `ScribbleBookController`, `ScribbleEventBridge` 등 기존 코드는 수정하지 않는다. |

### 1.2 레이어 구조도

```
lib/src/module/live/
├── domain/                          # 비즈니스 규칙 (외부 의존성 zero)
│   ├── transport/
│   │   └── live_session_transport.dart    # Transport 추상 인터페이스
│   ├── model/
│   │   ├── live_session.dart              # LiveSession, SessionState, SessionConfig
│   │   ├── session_participant.dart       # SessionParticipant, ParticipantRole
│   │   ├── transport_state.dart           # TransportConnectionState enum
│   │   └── sync_models.dart              # SyncRequest, SyncResponse 도메인 모델
│   ├── batcher/
│   │   ├── event_batcher.dart            # 100ms 포인트 배칭 로직
│   │   └── viewport_throttler.dart       # 100ms 뷰포트 쓰로틀링
│   └── sync/
│       └── late_join_synchronizer.dart    # 늦은 참가자 동기화 로직
│
├── data/                            # 내부 구현체 (Protobuf 직렬화, 테스트용 Transport)
│   ├── transport/
│   │   └── local_loopback_transport.dart  # 테스트/데모용 로컬 루프백
│   ├── serializer/
│   │   └── message_serializer.dart        # Protobuf encode/decode (Topic별)
│   └── renderer/
│       └── remote_stroke_renderer.dart    # 원격 스트로크 점진적 렌더링
│   # NOTE: LiveKitTransport는 open_board에 포함하지 않음
│   # 소비자 앱에서 LiveSessionTransport 인터페이스를 구현하여 주입
│
├── presentation/                    # Controller, Widget
│   ├── live_session_controller.dart       # 세션 오케스트레이터
│   ├── live_scribble_widget.dart          # SimpleScribbleWidget 확장
│   └── adaptive_viewport_calculator.dart  # 멀티디바이스 뷰포트 변환
│
└── di/                              # 의존성 주입
    └── live_session_scope.dart            # InheritedWidget 기반 DI
```

### 1.3 레이어 간 의존성 방향

```
presentation ──▶ domain ◀── data
     │                         │
     │                         │
     └── Flutter SDK           └── protobuf (livekit_client는 소비자 앱에서 구현)
```

**핵심 규칙:**
- `domain/`은 Flutter SDK, livekit_client, protobuf 등 어떤 외부 패키지에도 의존하지 않는다. 순수 Dart만 사용한다.
- `data/`는 `domain/`의 인터페이스를 구현한다. protobuf 의존성은 여기에만 존재한다. `livekit_client`는 open_board에 포함하지 않으며, 소비자 앱에서 `LiveSessionTransport`를 구현하여 주입한다.
- `presentation/`은 `domain/`의 모델과 인터페이스만 참조한다. `data/`의 구체 구현체를 직접 참조하지 않는다 (DI를 통해 주입).

### 1.4 레이어별 상세 책임

#### domain/ -- 비즈니스 규칙

| 파일 | 책임 |
|------|------|
| `live_session_transport.dart` | Transport 추상 인터페이스. `connect()`, `disconnect()`, `sendEvent()`, `sendStrokePoints()`, `sendStrokeComplete()`, `sendViewport()`, `requestSync()`, `sendSyncResponse()` 및 원격 이벤트 수신 Stream 정의. |
| `live_session.dart` | `LiveSession` 값 객체. `sessionId`, `contentId`, `roomName`, `state`, `participants`, `config` 포함. |
| `session_participant.dart` | `SessionParticipant` 값 객체. `participantId`, `displayName`, `role`, `token` 포함. `ParticipantRole` enum (`teacher`, `student`). |
| `transport_state.dart` | `TransportConnectionState` enum: `disconnected`, `connecting`, `connected`, `reconnecting`. |
| `sync_models.dart` | `SyncRequest`, `SyncResponse` 도메인 모델. chunk 분할 메타데이터 포함. |
| `event_batcher.dart` | 포인트 스트리밍용 100ms 배칭 로직. 최대 20포인트/배치, 1,200B MTU 제한. Timer 기반 flush. callback 패턴으로 Transport에 비의존. |
| `viewport_throttler.dart` | 뷰포트 변경 100ms 쓰로틀링. 윈도우 내 최신값만 유지 (last-write-wins). callback 패턴. |
| `late_join_synchronizer.dart` | 동기화 중 이벤트 버퍼링. `snapshotTimestamp` 이후 이벤트만 적용. Queue 기반 구현. |

#### data/ -- 외부 구현체

| 파일 | 책임 |
|------|------|
| ~~`livekit_transport.dart`~~ | **open_board에 포함하지 않음**. 소비자 앱에서 `LiveSessionTransport` 인터페이스를 구현. LiveKit, WebSocket, gRPC 등 자유롭게 선택 가능. |
| `local_loopback_transport.dart` | `LiveSessionTransport` 구현. 네트워크 없이 `StreamController`로 송수신 루프백. 단위 테스트 및 Example 앱용. |
| `message_serializer.dart` | 7개 Topic별 Protobuf encode/decode 유틸리티. `StrokePointsBatch`, `StrokeCompleteMessage`, `ScribbleEventMessage`, `ViewportMessage`, `SyncRequestMessage`, `SyncResponseMessage` 처리. |
| `remote_stroke_renderer.dart` | Lossy 포인트 배치를 받아 임시 스트로크를 점진적으로 렌더링하고, Reliable 완료 메시지 수신 시 전체 Stroke로 교체하는 렌더러. |

#### presentation/ -- Controller, Widget

| 파일 | 책임 |
|------|------|
| `live_session_controller.dart` | 세션 전체 오케스트레이터. `EventBatcher`, `ViewportThrottler`, `TimelineRecorder`를 조율. `ScribbleBookController.eventStream`을 구독하여 Transport로 전달. 선생님/학생 역할별 동작 분기. |
| `live_scribble_widget.dart` | `SimpleScribbleWidget`을 감싸는(wrapping) StatefulWidget. `LiveSessionController`를 받아 원격 스트로크 오버레이 렌더링, 뷰포트 동기화 적용. 학생 측에서는 `isScribbleEnabled: false`로 읽기 전용. |
| `adaptive_viewport_calculator.dart` | 선생님 뷰포트를 학생 디바이스 화면 비율에 맞게 변환하는 순수 계산 유틸리티. |

#### di/ -- 의존성 주입

| 파일 | 책임 |
|------|------|
| `live_session_scope.dart` | `InheritedWidget` 기반 DI 컨테이너. `LiveSessionTransport`, `LiveSessionController`를 위젯 트리 하위에 제공. `LiveSessionScope.of(context)` 패턴. |

---

## 2. DI 구조: InheritedWidget 기반

### 2.1 설계 이유

| 선택지 | 판단 |
|--------|------|
| get_it / injectable | open-board는 라이브러리 패키지이므로 앱 수준 DI 프레임워크에 의존하면 안 된다. |
| Riverpod | 소비자 앱이 Riverpod을 사용하지 않을 수 있다. 라이브러리가 강제하면 안 된다. |
| **InheritedWidget** | Flutter 표준. 외부 의존성 zero. 소비자가 원하는 DI 프레임워크로 감싸 사용 가능. |

### 2.2 LiveSessionScope 설계

```dart
/// 라이브 세션의 의존성을 위젯 트리에 제공하는 InheritedWidget
///
/// [LiveSessionController]와 [LiveSessionTransport]를 하위 위젯에서
/// `LiveSessionScope.of(context)`로 접근할 수 있다.
///
/// ```dart
/// LiveSessionScope(
///   controller: sessionController,
///   transport: liveKitTransport,
///   child: MaterialApp(...),
/// )
///
/// // 하위 위젯에서 접근
/// final session = LiveSessionScope.of(context);
/// session.controller.disconnect();
/// ```
class LiveSessionScope extends InheritedWidget {
  final LiveSessionController controller;
  final LiveSessionTransport transport;

  const LiveSessionScope({
    super.key,
    required this.controller,
    required this.transport,
    required super.child,
  });

  static LiveSessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LiveSessionScope>();
    assert(scope != null, 'LiveSessionScope not found in widget tree');
    return scope!;
  }

  static LiveSessionScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LiveSessionScope>();
  }

  @override
  bool updateShouldNotify(LiveSessionScope oldWidget) {
    return controller != oldWidget.controller ||
           transport != oldWidget.transport;
  }
}
```

### 2.3 소비자 앱에서의 사용 패턴

```dart
// 소비자 앱 (예: Riverpod 사용 시)
final liveSessionProvider = Provider<LiveSessionController>((ref) {
  // LiveSessionTransport 구현은 소비자 앱에서 제공
  // 예: LiveKitTransport, WebSocketTransport 등
  final transport = ref.watch(transportProvider);
  final bookController = ref.watch(bookControllerProvider);
  return LiveSessionController(
    bookController: bookController,
    transport: transport,
    role: ParticipantRole.teacher,
  );
});

// Widget 트리
LiveSessionScope(
  controller: ref.watch(liveSessionProvider),
  transport: ref.watch(transportProvider),
  child: LiveScribbleWidget(
    controller: bookController.controllerAt(0),
    child: pdfPage,
  ),
)
```

---

## 3. 소비자(앱 개발자) 공개 API 설계

### 3.1 Minimal API Surface

소비자가 실시간 튜터링을 통합하기 위해 사용하는 최소 API 목록이다.

```dart
// ============================================================
// Step 1: Transport 생성 (구현체 선택)
// ============================================================
final transport = LiveKitTransport(wsUrl: 'wss://livekit.example.com');

// 또는 테스트용:
// final transport = LocalLoopbackTransport();

// ============================================================
// Step 2: 세션 컨트롤러 생성
// ============================================================
final sessionController = LiveSessionController(
  bookController: bookController,       // 기존 ScribbleBookController
  transport: transport,
  role: ParticipantRole.teacher,        // 또는 .student
  config: SessionConfig(
    audioEnabled: true,
    egressEnabled: true,
  ),
);

// ============================================================
// Step 3: 세션 연결
// ============================================================
await sessionController.connect(
  sessionId: 'session-uuid',
  token: 'livekit-access-token',       // 서버에서 발급받은 토큰
);

// ============================================================
// Step 4: 위젯 트리 구성
// ============================================================
LiveSessionScope(
  controller: sessionController,
  transport: transport,
  child: Scaffold(
    body: PageView.builder(
      itemCount: bookController.pageCount,
      itemBuilder: (context, index) => LiveScribbleWidget(
        controller: bookController.controllerAt(index),
        child: pdfPages[index],
      ),
    ),
  ),
);

// ============================================================
// Step 5: 세션 종료 + 타임라인 저장
// ============================================================
final timeline = await sessionController.disconnect();

// .obt 파일로 저장 (리플레이용)
await TimelineFile.write('session.obt', timeline);

// ============================================================
// Step 6: 리플레이 (기존 API 그대로 사용)
// ============================================================
final replayController = ScribbleReplayController();
await replayController.loadFromFile('session.obt');
replayController.play();
```

### 3.2 API Surface 요약

| 클래스 | 용도 | 패키지 위치 |
|--------|------|------------|
| `LiveSessionTransport` | Transport 추상 인터페이스 | open_board (core) |
| `LiveKitTransport` | LiveKit 구현체 | **소비자 앱에서 구현** (open_board는 인터페이스만 제공) |
| `LocalLoopbackTransport` | 테스트/데모용 루프백 | open_board (core) |
| `LiveSessionController` | 세션 오케스트레이터 | open_board (core) |
| `LiveScribbleWidget` | 실시간 필기 위젯 | open_board (core) |
| `LiveSessionScope` | DI InheritedWidget | open_board (core) |
| `ParticipantRole` | 역할 enum | open_board (core) |
| `SessionConfig` | 세션 설정 | open_board (core) |
| `LiveSession` | 세션 모델 | open_board (core) |
| `TransportConnectionState` | 연결 상태 enum | open_board (core) |

### 3.3 공개 API Export

`modules.dart`에 다음 export를 추가한다.

```dart
// 실시간 튜터링 세션
export 'src/module/live/domain/transport/live_session_transport.dart';
export 'src/module/live/domain/model/live_session.dart';
export 'src/module/live/domain/model/session_participant.dart';
export 'src/module/live/domain/model/transport_state.dart';
export 'src/module/live/presentation/live_session_controller.dart';
export 'src/module/live/presentation/live_scribble_widget.dart';
export 'src/module/live/di/live_session_scope.dart';
// LiveKitTransport는 소비자 앱에서 구현 — open_board에서 export하지 않음
export 'src/module/live/data/transport/local_loopback_transport.dart';
```

---

## 4. 시퀀스 다이어그램 (ASCII)

### 4.1 전체 흐름: 세션 생성 -> 필기 -> 종료 -> 리플레이

```
 App Server        Teacher Client              LiveKit SFU          Student Client
 ──────────        ──────────────              ───────────          ──────────────
     │                   │                          │                     │
     │◀── POST /session ─┤                          │                     │
     │── SessionJoinResp ▶│                          │                     │
     │   (token, wsUrl)   │                          │                     │
     │                    │                          │                     │
     │                    │── connect(token) ────────▶│                     │
     │                    │◀─── Room.joined ─────────┤                     │
     │                    │                          │                     │
     │                    │  startRecording()        │                     │
     │                    │  EventBatcher.init()     │                     │
     │                    │                          │                     │
     │◀── POST /session ──┼──────────────────────────┼──── GET /session ──▶│
     │── SessionJoinResp ─┼──────────────────────────┼──────── token ─────▶│
     │                    │                          │                     │
     │                    │                          │◀── connect(token) ──┤
     │                    │                          │── Room.joined ──────▶│
     │                    │                          │                     │
     │                    │◀─ sync.request ──────────┼─── SyncRequest ────┤
     │                    │                          │                     │
     │                    │  Scribble snapshot       │                     │
     │                    │── sync.response ─────────┼───────────────────▶│
     │                    │  (chunked)               │                     │
     │                    │                          │    loadScribble()   │
     │                    │                          │    applyViewport()  │
     │                    │                          │                     │
     │                    │                          │                     │
     │            ┌───────┴───────┐                  │                     │
     │            │ 선생님 필기    │                  │                     │
     │            │ Pointer Event │                  │                     │
     │            └───────┬───────┘                  │                     │
     │                    │                          │                     │
     │                    │── stroke.points ─────────▶── stroke.points ──▶│
     │                    │  (Lossy, 100ms batch)    │  RemoteStroke       │
     │                    │                          │  Renderer.append()  │
     │                    │                          │                     │
     │                    │── stroke.complete ───────▶── stroke.complete ─▶│
     │                    │  (Reliable)              │  finalizeStroke()   │
     │                    │                          │                     │
     │                    │  TimelineRecorder         │                     │
     │                    │  .record(event)          │                     │
     │                    │                          │                     │
     │                    │── viewport ──────────────▶── viewport ────────▶│
     │                    │  (Lossy, 100ms throttle) │  Adaptive           │
     │                    │                          │  Viewport.calc()    │
     │                    │                          │                     │
     │            ┌───────┴───────┐                  │                     │
     │            │ 세션 종료      │                  │                     │
     │            └───────┬───────┘                  │                     │
     │                    │                          │                     │
     │                    │  disconnect()            │                     │
     │                    │  TimelineRecorder.stop()  │                     │
     │                    │  → ScribbleTimeline      │                     │
     │                    │                          │                     │
     │                    │── session.end ───────────▶── session.end ─────▶│
     │                    │                          │                     │
     │◀── PUT /session ───┤  .obt upload             │                     │
     │    (ended + .obt)  │                          │                     │
     │                    │                          │                     │
     │                    │                          │                     │
     │             ┌──────┴──────┐                   │                     │
     │             │ 리플레이     │                   │                     │
     │             └──────┬──────┘                   │                     │
     │                    │                          │                     │
     │                    │  ScribbleReplayController │                     │
     │                    │  .loadFromFile('x.obt')  │                     │
     │                    │  .play()                 │                     │
     │                    │                          │                     │
```

### 4.2 늦은 참가자 동기화 시퀀스

```
Student Client               Teacher Client
──────────────               ──────────────
     │                            │
     │── SyncRequest ────────────▶│
     │   {participantId, ts}      │
     │                            │  1. 현재 필기 계속 진행
     │                            │  2. 백그라운드에서 스냅샷 생성
     │                            │
     │   이 사이에 도착하는         │
     │   stroke.points,           │
     │   stroke.complete 등       │
     │   → eventBuffer에 버퍼링    │
     │                            │
     │◀── SyncResponse [1/3] ─────┤  Scribble snapshot chunk 1
     │◀── SyncResponse [2/3] ─────┤  Scribble snapshot chunk 2
     │◀── SyncResponse [3/3] ─────┤  Scribble snapshot chunk 3
     │                            │
     │  1. chunk 조립              │
     │  2. loadScribble()         │
     │  3. applyViewport()        │
     │  4. 버퍼 이벤트 순차 적용    │
     │     (snapshotTs 이후만)     │
     │  5. 실시간 수신 시작        │
     │                            │
```

---

## 5. 디렉토리/파일 구조

### 5.1 신규 파일 전체 목록

```
lib/src/module/live/
│
├── domain/
│   ├── transport/
│   │   └── live_session_transport.dart       [신규] Transport 추상 인터페이스
│   ├── model/
│   │   ├── live_session.dart                 [신규] LiveSession, SessionState, SessionConfig
│   │   ├── session_participant.dart           [신규] SessionParticipant, ParticipantRole, ParticipantAction
│   │   ├── transport_state.dart              [신규] TransportConnectionState enum
│   │   └── sync_models.dart                  [신규] SyncRequest, SyncResponse 도메인 모델
│   ├── batcher/
│   │   ├── event_batcher.dart                [신규] 100ms 포인트 배칭
│   │   └── viewport_throttler.dart           [신규] 100ms 뷰포트 쓰로틀링
│   └── sync/
│       └── late_join_synchronizer.dart        [신규] 늦은 참가자 동기화
│
├── data/
│   ├── transport/
│   │   # livekit_transport.dart는 소비자 앱에서 구현
│   │   └── local_loopback_transport.dart      [신규] 테스트/데모용 로컬 루프백
│   ├── serializer/
│   │   └── message_serializer.dart            [신규] Topic별 Protobuf encode/decode
│   └── renderer/
│       └── remote_stroke_renderer.dart        [신규] 원격 스트로크 점진적 렌더링
│
├── presentation/
│   ├── live_session_controller.dart           [신규] 세션 오케스트레이터
│   ├── live_scribble_widget.dart              [신규] 실시간 필기 위젯
│   └── adaptive_viewport_calculator.dart      [신규] 뷰포트 어댑티브 변환
│
└── di/
    └── live_session_scope.dart                [신규] InheritedWidget DI
```

**총 15개 신규 파일.**

### 5.2 각 파일의 주요 클래스 및 책임 요약

| # | 파일 | 주요 클래스 | 핵심 책임 |
|---|------|-----------|----------|
| 1 | `live_session_transport.dart` | `LiveSessionTransport` (abstract) | 7개 Topic의 send/receive 메서드 정의. `connect()`, `disconnect()`, 연결 상태 Stream |
| 2 | `live_session.dart` | `LiveSession`, `SessionState`, `SessionConfig` | 세션 메타데이터 값 객체. `created`/`waiting`/`active`/`ended` 상태 머신 |
| 3 | `session_participant.dart` | `SessionParticipant`, `ParticipantRole` | 참가자 정보. `teacher`/`student` 역할 구분 |
| 4 | `transport_state.dart` | `TransportConnectionState` | `disconnected`/`connecting`/`connected`/`reconnecting` |
| 5 | `sync_models.dart` | `SyncRequest`, `SyncResponse` | chunk 분할 메타, 스냅샷 타임스탬프, 페이지 상태 |
| 6 | `event_batcher.dart` | `EventBatcher` | 100ms Timer 기반 Point 배칭. `addPoint()` -> `onBatchReady` callback |
| 7 | `viewport_throttler.dart` | `ViewportThrottler` | 100ms 쓰로틀. `onViewportChanged()` -> `onThrottled` callback |
| 8 | `late_join_synchronizer.dart` | `LateJoinSynchronizer` | Queue 기반 이벤트 버퍼링. `isSyncing` 플래그 관리 |
| ~~9~~ | ~~`livekit_transport.dart`~~ | ~~`LiveKitTransport`~~ | **소비자 앱에서 구현** |
| 10 | `local_loopback_transport.dart` | `LocalLoopbackTransport` | `StreamController` 쌍으로 teacher/student 루프백 |
| 11 | `message_serializer.dart` | `MessageSerializer` | `StrokePointsBatch`, `StrokeCompleteMessage` 등 Protobuf encode/decode |
| 12 | `remote_stroke_renderer.dart` | `RemoteStrokeRenderer` | Lossy 포인트 누적 -> 임시 Path 렌더링 -> Reliable 완료 시 Stroke 교체 |
| 13 | `live_session_controller.dart` | `LiveSessionController` | `eventStream` 구독, `EventBatcher`/`ViewportThrottler`/`TimelineRecorder` 조율, 역할별 분기 |
| 14 | `live_scribble_widget.dart` | `LiveScribbleWidget` | `SimpleScribbleWidget` wrapping, 원격 스트로크 오버레이, 뷰포트 동기화 |
| 15 | `live_session_scope.dart` | `LiveSessionScope` | `InheritedWidget`. `of(context)` 패턴으로 controller/transport 접근 |

---

## 6. 기존 코드 변경 범위

### 6.1 최소 변경 원칙

Tech Spec에 명시된 대로 기존 open-board 코어 코드의 변경을 최소화한다. `LiveSessionController`가 기존 클래스들의 public API만 사용하여 통합한다.

### 6.2 변경 필요 파일 목록

| # | 파일 | 변경 내용 | 변경 수준 |
|---|------|----------|----------|
| 1 | `lib/modules.dart` | live 모듈 export 10줄 추가 | **추가만** (기존 코드 수정 없음) |
| 2 | `lib/src/module/events/scribble_book_event.dart` | `ViewportChangedEvent`, `SessionParticipantEvent` 2개 sealed class 멤버 추가 | **확장** (기존 이벤트 변경 없음) |
| 3 | `lib/src/data/model/timeline/timeline_models.dart` | `TlViewportChanged`, `TlSessionParticipant` 2개 sealed class 멤버 추가 | **확장** (기존 모델 변경 없음) |
| 4 | `lib/src/module/replay/scribble_timeline_recorder.dart` | `_convertToTimelineEvent`에 `ViewportChangedEvent`, `SessionParticipantEvent` case 추가 | **확장** (기존 case 변경 없음) |
| 5 | `lib/src/module/replay/scribble_replay_controller.dart` | `_convertFromTimelineEvent`에 `TlViewportChanged`, `TlSessionParticipant` case 추가 | **확장** (기존 case 변경 없음) |
| 6 | `lib/src/data/model/timeline/timeline_serializer.dart` | 새 이벤트 타입의 직렬화/역직렬화 추가 | **확장** |
| ~~7~~ | ~~`pubspec.yaml`~~ | ~~`livekit_client: ^2.7.0`~~ | **불필요** — 소비자 앱에서 직접 의존 |

### 6.3 변경하지 않는 파일 (명시적 보호)

다음 핵심 파일들은 변경하지 않는다.

- `ScribbleBookController` -- `eventStream`만 구독하여 사용
- `ScribbleEventBridge` -- 그대로 이벤트 변환 수행
- `ScribbleController` -- 기존 필기 입력/렌더링 담당
- `SimpleScribbleWidget` -- `LiveScribbleWidget`이 wrapping만 함
- `ScribbleNotifier`, `ScribbleModeNotifier` -- 기존 상태 관리 유지
- `StrokeAnimator`, `ScribbleReplayHandler` -- 리플레이 기존 로직 유지

### 6.4 변경 영향도 분석

```
변경 파일 수:       7개 (기존 6개 + pubspec.yaml)
신규 파일 수:      15개
기존 코드 수정량:  ~50줄 (모두 sealed class 확장 또는 export 추가)
신규 코드량:       ~2,000줄 (추정)
```

기존 코드 변경은 모두 **추가(additive)** 성격이며, 기존 동작을 변경하는 수정은 없다. sealed class에 새 멤버를 추가하면 기존 exhaustive switch에서 컴파일 에러가 발생하므로, 항목 4, 5의 case 추가는 필수다.

---

## 7. Solutioning Gate 체크리스트

### 7.1 Clean Architecture 준수

| 항목 | 상태 | 근거 |
|------|------|------|
| domain 레이어가 외부 의존성에 의존하지 않는가? | PASS | domain/에 import되는 패키지: 없음 (순수 Dart, dart:async만 사용) |
| data -> domain 의존 방향이 올바른가? | PASS | `LocalLoopbackTransport implements LiveSessionTransport` (LiveKit 구현은 소비자 앱) |
| presentation -> domain 의존 방향이 올바른가? | PASS | `LiveSessionController`는 `LiveSessionTransport` 인터페이스만 참조 |
| presentation이 data를 직접 참조하지 않는가? | PASS | DI (`LiveSessionScope`)를 통해 구체 구현체 주입 |
| 기존 open-board 모듈의 flat 구조를 유지하는가? | PASS | 기존 `module/events/`, `module/replay/` 등 변경 없음 |

### 7.2 DI 구조 적절성

| 항목 | 상태 | 근거 |
|------|------|------|
| 외부 DI 프레임워크에 의존하지 않는가? | PASS | Flutter 표준 `InheritedWidget`만 사용 |
| 소비자 앱이 자체 DI와 통합할 수 있는가? | PASS | `LiveSessionScope`를 Riverpod/Provider 등으로 감쌀 수 있음 |
| 테스트에서 Transport 교체가 용이한가? | PASS | `LocalLoopbackTransport`로 네트워크 없이 전체 흐름 테스트 가능 |
| Widget 트리에서 접근이 자연스러운가? | PASS | `LiveSessionScope.of(context)` 패턴 |

### 7.3 API 설계 검토

| 항목 | 상태 | 근거 |
|------|------|------|
| 소비자 코드 최소 줄 수로 통합 가능한가? | PASS | 핵심 흐름 6단계, ~20줄 코드 |
| 기존 open-board API와 일관성이 있는가? | PASS | `ScribbleBookController`, `SimpleScribbleWidget` 패턴 답습 |
| Breaking change가 없는가? | PASS | 기존 public API 변경 없음. sealed class 확장은 소비자 측 exhaustive switch에서 컴파일 에러 발생 가능 -- 이는 의도된 동작이며, live 이벤트를 처리하지 않으면 무시 가능하도록 default case 가이드 제공 |
| barrel export가 정리되어 있는가? | PASS | `modules.dart`에 live 모듈 export 일괄 추가 |

### 7.4 보안 (토큰 관리, 데이터 암호화)

| 항목 | 상태 | 근거 |
|------|------|------|
| LiveKit 토큰이 클라이언트에 하드코딩되지 않는가? | PASS | 토큰은 App Server (Serverpod)에서 발급. 클라이언트는 서버 API를 통해 수신 |
| 토큰 TTL이 설정되어 있는가? | PASS | Tech Spec에서 4시간 TTL 명시 |
| Transport 연결 시 토큰 기반 인증인가? | PASS | `connect(sessionId, token)` -- LiveKit Room 접속 시 서명된 JWT 사용 |
| Data Channel 전송 데이터에 민감 정보가 없는가? | PASS | 필기 좌표, 뷰포트 정보만 전송. 개인정보 미포함 |
| DTLS 암호화가 적용되는가? | PASS | LiveKit Data Channel은 WebRTC 기반이므로 DTLS 암호화가 기본 적용 |
| 참가자 역할(teacher/student) 검증이 서버 측인가? | PASS | 토큰 metadata에 role 인코딩, 서버에서 서명. 클라이언트 조작 불가 |

### 7.5 성능 및 확장성

| 항목 | 상태 | 근거 |
|------|------|------|
| 포인트 스트리밍이 MTU(1,300B) 이내인가? | PASS | EventBatcher의 `_maxBatchSizeBytes = 1200` |
| Lossy/Reliable 채널이 용도에 맞게 분리되어 있는가? | PASS | 포인트/뷰포트 = Lossy, 스트로크 완료/이벤트 = Reliable |
| 늦은 참가자 동기화가 이벤트 누락 없이 동작하는가? | PASS | `LateJoinSynchronizer`의 버퍼링 + snapshotTimestamp 필터링 |
| 10x 성장 (1:N, 다중 세션) 대비가 되어 있는가? | PASS | Transport 추상화로 구현체 교체 가능. Phase 3에서 권한 토글 확장 설계 반영 |

### 7.6 미결 사항 (향후 결정 필요)

| 항목 | 설명 | 결정 시점 |
|------|------|----------|
| ~~`livekit_client` 패키지 분리~~ | **결정 완료**: open_board는 인터페이스만 제공. LiveKit 구현은 소비자 앱에서 담당. | 해결됨 |
| sealed class 확장의 하위 호환성 | `ViewportChangedEvent` 추가 시 소비자의 기존 switch 문에서 컴파일 에러 발생 가능. `@Deprecated` 가이드 또는 minor version bump 필요 | Phase 1 착수 전 |
| Egress 녹화 트리거 | 서버 측에서 자동 시작할지, 클라이언트에서 요청할지 | Tech Spec 리뷰 시 |
| 오디오 동기화 정밀도 | .obt + MP4 동기화 드리프트 허용 범위 (현재 200ms) | 사용자 테스트 후 |

---

## 부록 A: LiveSessionController 내부 구조

```
LiveSessionController (presentation)
│
├── 입력 (구독)
│   ├── ScribbleBookController.eventStream ──▶ ScribbleBookEvent 수신
│   └── LiveSessionTransport.remoteEvents   ──▶ 원격 이벤트 수신
│
├── 내부 컴포넌트 (조율)
│   ├── EventBatcher (domain)
│   │   └── addPoint() → onBatchReady → transport.sendStrokePoints()
│   │
│   ├── ViewportThrottler (domain)
│   │   └── onViewportChanged() → onThrottled → transport.sendViewport()
│   │
│   ├── ScribbleTimelineRecorder (기존, 재사용)
│   │   └── .start(eventStream) → .stop() → ScribbleTimeline
│   │
│   └── LateJoinSynchronizer (domain)
│       └── onSyncRequest() → snapshot 생성 → transport.sendSyncResponse()
│
├── 출력 (전송)
│   ├── transport.sendEvent()           [Reliable] 페이지 전환, undo/redo 등
│   ├── transport.sendStrokePoints()    [Lossy]    배칭된 포인트
│   ├── transport.sendStrokeComplete()  [Reliable] 완료 스트로크
│   └── transport.sendViewport()        [Lossy]    쓰로틀된 뷰포트
│
└── 상태
    ├── LiveSession (현재 세션 메타데이터)
    ├── TransportConnectionState (연결 상태)
    └── ParticipantRole (teacher/student 분기)
```

## 부록 B: 기존 코드와의 통합 지점

```
기존 open-board 코드                        live 모듈 통합 지점
──────────────────                         ─────────────────────

ScribbleBookController                     LiveSessionController가
  .eventStream ──────────────────────────▶ 구독하여 Transport로 전달
  .controllerAt(index) ─────────────────▶ LiveScribbleWidget에서 사용
  .startRecording() ────────────────────▶ connect() 시 자동 호출
  .stopRecording() ─────────────────────▶ disconnect() 시 자동 호출

ScribbleEventBridge                        변경 없음. 기존처럼
  (Notifier → BookEvent 변환) ───────────▶ eventStream으로 이벤트 공급

ScribbleTimelineRecorder                   LiveSessionController가
  .start(eventStream) ──────────────────▶ connect() 시 자동 시작
  .stop() → ScribbleTimeline ───────────▶ disconnect() 시 자동 호출

ScribbleReplayController                   세션 종료 후 .obt 리플레이
  .loadFromFile() ──────────────────────▶ 기존 API 그대로 사용
  (ViewportChangedEvent 추가 처리만 확장)

SimpleScribbleWidget                       LiveScribbleWidget이
  (필기 입력/렌더링) ───────────────────▶ wrapping하여 원격 오버레이 추가
```
