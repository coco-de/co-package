# PRD: 실시간 1:1 온라인 튜터링 MVP (Phase 1)

> 문서 버전: 1.0.0
> 작성일: 2026-04-07
> 상태: Draft
> 기반 문서: [Discovery - 실시간 온라인 튜터링 플랫폼](./discovery-live-tutoring.md)

---

## 1. 제품 개요

### 1.1 비전

> "모든 수업이 다시 꺼내볼 수 있는 나만의 교재가 된다"

open-board 필기 엔진 위에 LiveKit 기반 실시간 통신을 결합하여, 선생님과 학생이 1:1로 필기 수업을 진행하고 그 수업 전체가 인터랙티브 리플레이 교재로 자동 변환되는 경험을 제공한다.

### 1.2 North Star Metric

**주간 리플레이 재생 수** -- 수업 후 학생이 실제로 복습하는 횟수

| 지표 유형 | 항목 |
|----------|------|
| Leading | 수업 완료율, .obt 파일 생성 수 |
| Lagging | 학생 성적 향상, 학부모 만족도, 선생님 재사용률 |

### 1.3 Phase 1 목표

선생님 1명과 학생 1명이 실시간으로 필기 수업을 진행하고, 수업 종료 후 리플레이로 복습할 수 있는 최소 기능 제품(MVP)을 구현한다.

| 목표 | 측정 기준 |
|------|----------|
| 실시간 필기 동기화 | 선생님 필기가 학생 화면에 100ms 이내 반영 |
| 음성 통화 | 수업 중 끊김 없는 양방향 음성 |
| 뷰포트 동기화 | 선생님의 확대/축소/이동이 학생에게 실시간 반영 |
| 세션 리플레이 | 수업 종료 후 .obt 파일로 전체 재생 가능 |
| PMF 검증 | 초기 10명의 선생님이 2주 이상 반복 사용 |

---

## 2. 사용자 스토리

### 2.1 선생님 (튜터)

| ID | 스토리 | 우선순위 |
|----|--------|---------|
| T-01 | 선생님으로서, 수업 세션을 생성하고 학생을 초대할 수 있어야 한다. 수업을 시작할 수 있도록. | Must |
| T-02 | 선생님으로서, 수업 중 펜/연필/마커/지우개/도형 도구로 필기할 수 있어야 한다. 풍부한 설명이 가능하도록. | Must |
| T-03 | 선생님으로서, 필기 내용이 학생 화면에 실시간으로 나타나야 한다. 함께 보며 설명할 수 있도록. | Must |
| T-04 | 선생님으로서, 캔버스를 확대/축소/이동하면 학생도 같은 영역을 보아야 한다. 시선을 맞추며 수업할 수 있도록. | Must |
| T-05 | 선생님으로서, 음성으로 학생과 대화할 수 있어야 한다. 필기와 함께 설명할 수 있도록. | Must |
| T-06 | 선생님으로서, 여러 페이지를 추가/전환하며 수업할 수 있어야 한다. 주제별로 내용을 정리할 수 있도록. | Must |
| T-07 | 선생님으로서, Undo/Redo를 사용할 수 있어야 한다. 실수를 바로잡을 수 있도록. | Must |
| T-08 | 선생님으로서, 수업을 종료하면 .obt 리플레이 파일이 자동 생성되어야 한다. 수업이 교재로 남도록. | Must |
| T-09 | 선생님으로서, 네트워크가 일시적으로 끊겨도 필기를 계속할 수 있어야 한다. 수업 흐름이 끊기지 않도록. | Should |
| T-10 | 선생님으로서, 재접속 시 학생과 상태가 자동 동기화되어야 한다. 수업을 이어갈 수 있도록. | Should |

### 2.2 학생

| ID | 스토리 | 우선순위 |
|----|--------|---------|
| S-01 | 학생으로서, 초대 링크/코드로 수업에 참가할 수 있어야 한다. 쉽게 접속할 수 있도록. | Must |
| S-02 | 학생으로서, 선생님의 필기를 실시간으로 볼 수 있어야 한다. 수업을 따라갈 수 있도록. | Must |
| S-03 | 학생으로서, 선생님의 뷰포트를 자동으로 따라가야 한다. 선생님이 보는 화면을 함께 볼 수 있도록. | Must |
| S-04 | 학생으로서, 음성으로 선생님에게 질문할 수 있어야 한다. 실시간 소통이 가능하도록. | Must |
| S-05 | 학생으로서, 수업 후 리플레이로 수업을 다시 볼 수 있어야 한다. 복습할 수 있도록. | Must |
| S-06 | 학생으로서, 리플레이에서 원하는 시점으로 seek할 수 있어야 한다. 이해 안 되는 부분을 다시 볼 수 있도록. | Must |
| S-07 | 학생으로서, 리플레이 재생 속도를 조절할 수 있어야 한다. 빠르게 훑거나 천천히 볼 수 있도록. | Should |
| S-08 | 학생으로서, 리플레이 시 선생님이 보던 화면 구도로 재현되어야 한다. 선생님의 시선을 따라갈 수 있도록. | Must |
| S-09 | 학생으로서, 내 디바이스에 맞게 리플레이 뷰포트가 적응되어야 한다. 어떤 기기에서든 편하게 볼 수 있도록. | Should |
| S-10 | 학생으로서, 늦게 참가해도 현재 수업 상태를 바로 볼 수 있어야 한다. 수업에 즉시 합류할 수 있도록. | Must |

---

## 3. 기능 요구사항

### 3.1 실시간 필기 동기화

#### 3.1.1 포인트 스트리밍 (Lossy)

- 선생님이 필기하는 동안 각 포인트를 Lossy Data Channel로 전송
- Topic: `stroke_stream`
- Payload: `{pageId, strokeId, x, y, pressure, timestamp}` (약 40B)
- 학생 측에서 수신된 포인트를 실시간 렌더링 (진행 중인 스트로크 시각화)
- 포인트 유실 시 최종 Stroke 완료 메시지로 보정

#### 3.1.2 스트로크 완료 (Reliable)

- 스트로크 완료 시 전체 Stroke Protobuf를 Reliable Data Channel로 전송
- Topic: `stroke_complete`
- Payload: 전체 Stroke protobuf (수 KB)
- 수신 측에서 스트리밍 미리보기를 완성된 스트로크로 교체
- 순서 보장 및 전달 보장

#### 3.1.3 이벤트 동기화 (Reliable)

- `ScribbleBookEvent` 8종 + `ViewportChangedEvent`를 Reliable Data Channel로 전송
- Topic: `scribble_event`
- StrokeRemoved, Undo, Redo, PageAdded, PageRemoved, PageCleared, PageChanged 포함
- 이벤트별 50~200B로 Data Channel MTU(15KiB) 내 충분

### 3.2 음성 통화

- LiveKit의 AudioTrack을 사용한 양방향 음성 통화
- Opus 코덱, 모노, 48kHz
- 마이크 음소거/해제 UI 제공
- 음성은 .obt 파일에 포함하지 않음 (Phase 1 범위)
- 음성 품질 지표: MOS 3.5 이상

### 3.3 뷰포트 동기화

#### 3.3.1 실시간 전송

- 선생님의 확대(scale), 이동(centerX, centerY), 화면 크기(viewportWidth, viewportHeight)를 전송
- Topic: `viewport`
- Lossy Data Channel, 100ms throttle
- Payload: 약 30B

#### 3.3.2 ViewportChangedEvent 추가

```dart
class ViewportChangedEvent extends ScribbleBookEvent {
  final String pageId;
  final double scale;
  final double centerX;
  final double centerY;
  final double viewportWidth;
  final double viewportHeight;
}
```

- `ScribbleBookEvent` sealed class에 추가
- `ScribbleEventBridge`에서 뷰포트 변경 감지 및 이벤트 발행
- 타임라인에 `TlViewportChanged` 이벤트로 기록

#### 3.3.3 멀티디바이스 적응 렌더링

- 선생님의 center 좌표를 기준점으로 사용
- 학생 디바이스 비율에 맞게 visible area 재계산
- 선생님 scale 유지, 가로/세로 여백 자동 조정
- 선생님이 가리킨 영역이 항상 화면 중심에 위치

### 3.4 세션 관리

#### 3.4.1 세션 생성

- 선생님이 세션을 생성하면 고유 세션 ID와 참가 코드/링크 발급
- LiveKit Room 생성 (1:1, 최대 2 participants)
- 세션 메타데이터: 선생님 ID, 과목, 시작 시각

#### 3.4.2 세션 참가

- 학생이 참가 코드/링크로 세션에 입장
- 입장 시 현재 캔버스 상태 풀 싱크 수신 (늦은 참가자 동기화)
- 역할 기반 권한: 선생님 = read/write, 학생 = read-only (Phase 1)

#### 3.4.3 세션 종료

- 선생님이 수업 종료 시 세션 종료 트리거
- 종료 시 .obt 타임라인 파일 자동 생성 및 저장
- 양측 연결 정리 (Data Channel, AudioTrack, Room)

### 3.5 늦은 참가자 동기화

- 학생이 수업 중간에 입장할 경우:
  1. 현재 활성 페이지의 전체 `Scribble` Protobuf 스냅샷 전송 (Reliable)
  2. 페이지 목록 및 현재 페이지 인덱스 전송
  3. 현재 뷰포트 상태 전송
  4. 이후 실시간 이벤트 스트림에 합류
- 스냅샷 전송 중에도 새 이벤트는 큐잉 후 순차 적용

### 3.6 세션 리플레이

- 기존 `ScribbleReplayController` + `ScribbleReplayHandler` 활용
- `ViewportChangedEvent`를 타임라인에 기록하여 리플레이 시 뷰포트 재현
- 재생 제어: play, pause, seek, speed (0.5x ~ 4x)
- 60fps 스트로크 애니메이션 유지
- 멀티디바이스 적응 렌더링 적용

### 3.7 Transport 추상화

```
LiveSessionTransport (abstract)
├── connect(sessionId, token) -> Future<void>
├── disconnect() -> Future<void>
├── sendEvent(ScribbleBookEvent) -> void
├── sendPointStream(PointStreamData) -> void
├── sendStrokeComplete(Stroke) -> void
├── sendViewport(ViewportData) -> void
├── sendSnapshot(Scribble) -> void
├── onEvent -> Stream<ScribbleBookEvent>
├── onPointStream -> Stream<PointStreamData>
├── onStrokeComplete -> Stream<Stroke>
├── onViewport -> Stream<ViewportData>
├── onSnapshot -> Stream<Scribble>
├── connectionState -> ValueListenable<ConnectionState>
└── dispose() -> void
```

- `LiveKitTransport`: LiveKit Data Channel 기반 구현
- `LocalReplayTransport`: .obt 파일 기반 로컬 리플레이 (향후)
- LiveKit 의존성은 `LiveKitTransport` 구현체에만 존재

---

## 4. 비기능 요구사항

### 4.1 성능

| 항목 | 기준 |
|------|------|
| 필기 포인트 전송 지연 | p95 < 100ms (LAN), p95 < 200ms (4G) |
| 스트로크 완료 전송 지연 | p95 < 300ms |
| 뷰포트 동기화 지연 | p95 < 200ms |
| 음성 지연 | p95 < 150ms |
| 리플레이 로딩 | 1시간 수업 기준 < 2초 |
| 프레임 레이트 | 필기 중 > 55fps |

### 4.2 네트워크

| 항목 | 기준 |
|------|------|
| 최소 대역폭 (필기만) | 50 Kbps |
| 최소 대역폭 (필기 + 음성) | 100 Kbps |
| 패킷 손실 허용 | 포인트 스트리밍 10%, 스트로크 완료 0% |
| 네트워크 끊김 허용 | 30초 이내 자동 재접속 |

### 4.3 안정성

| 항목 | 기준 |
|------|------|
| 세션 유지 시간 | 최대 120분 연속 |
| 메모리 사용 | 1시간 수업 기준 < 200MB |
| .obt 파일 크기 | 1시간 수업 기준 < 10MB |
| 크래시율 | < 0.1% per session |

### 4.4 Graceful Degradation

| 상황 | 대응 |
|------|------|
| 네트워크 끊김 (< 30초) | 로컬 필기 계속, 재접속 시 이벤트 큐 flush |
| 네트워크 끊김 (> 30초) | "연결 끊김" UI 표시, 로컬 필기 보존, 수동 재접속 |
| 음성만 끊김 | 필기 동기화 유지, 음성 재연결 시도 |
| 상대방 퇴장 | "상대방이 나갔습니다" 알림, 세션 유지 (재입장 가능) |

### 4.5 플랫폼 지원

| 플랫폼 | Phase 1 지원 |
|--------|-------------|
| iPad (iPadOS) | Must |
| Android Tablet | Must |
| iPhone | Should |
| Android Phone | Should |
| macOS Desktop | Could |
| Web | Won't (Phase 1) |

---

## 5. 범위 외 (Phase 1에서 하지 않는 것)

| 항목 | 이유 | 예정 Phase |
|------|------|-----------|
| 학생 필기 (양방향 필기) | 1:1 MVP에서 단방향으로 시작 | Phase 2 |
| 1:N 그룹 강의 | 아키텍처 복잡도, 1:1 검증 우선 | Phase 3 |
| 비디오 통화 | 필기 중심 수업에 불필요, 대역폭 절약 | Phase 2+ |
| 음성 녹화 | .obt에 음성 포함 시 파일 크기/저작권 이슈 | Phase 2 |
| 채팅 기능 | 음성으로 대체 가능, MVP 경량화 | Phase 2 |
| 학부모 접근 | 학부모 전용 리플레이 뷰 | Phase 2 |
| B2B SDK 패키징 | SDK 추상화 수준의 API | Phase 2 |
| Self-Hosting 가이드 | 고객 계약 시점에 제공 | Phase 2+ |
| 북마크/하이라이트 | 리플레이 내 중요 구간 표시 | Phase 2 |
| 결제/과금 시스템 | PMF 검증 단계, 무료 제공 | Phase 2 |
| 오프라인 모드 | 네트워크 필수, graceful degradation만 지원 | Phase 3 |
| .obt -> Protobuf 바이너리 전환 | JSON 기반으로 충분, 최적화 시점 판단 | Phase 2 |

---

## 6. 성공 기준

### 6.1 기술 검증 (Launch Gate)

- [ ] 필기 포인트 전송 p95 < 100ms 달성 (LAN 환경)
- [ ] 1시간 연속 세션에서 크래시 0건
- [ ] 늦은 참가자 동기화 3초 이내 완료
- [ ] .obt 리플레이 파일 정상 생성 및 재생 확인
- [ ] 뷰포트 동기화 시 선생님/학생 화면 일치율 > 95%

### 6.2 사용자 검증 (PMF Gate, Launch 후 4주)

- [ ] 선생님 10명 이상 2주 연속 사용
- [ ] 주간 리플레이 재생 수 > 학생 1인당 2회
- [ ] 수업 완료율 > 80% (시작된 세션 대비)
- [ ] NPS > 30 (선생님 기준)
- [ ] .obt 파일 생성률 > 95% (완료된 세션 대비)

---

## 7. 위험 요소 및 완화

| # | 위험 요소 | 영향 | 확률 | 완화 전략 |
|---|----------|------|------|----------|
| R1 | LiveKit 의존성 (라이선스 변경, API 변경) | 높 | 낮 | Transport 추상화 레이어로 격리. LiveKit은 Apache 2.0. |
| R2 | 포인트 스트리밍 지연이 100ms 초과 | 높 | 중 | Lossy 모드 사용, 포인트 배칭(3~5개), 네트워크 품질 모니터링 |
| R3 | 늦은 참가자 동기화 시 대량 데이터 전송 지연 | 중 | 중 | Protobuf 압축, 페이지 단위 점진적 로딩, 15KiB 청크 분할 |
| R4 | 멀티디바이스 뷰포트 렌더링 불일치 | 중 | 중 | center 좌표 기준 정규화, 다양한 디바이스 조합 테스트 |
| R5 | 장시간 세션(2시간+) 메모리 증가 | 중 | 중 | 비활성 페이지 스트로크 메모리 해제, 주기적 GC 트리거 |
| R6 | "더 좋은 필기"만으로는 선생님 전환 동기 부족 | 높 | 중 | "수업의 자산화"를 핵심 가치로 포지셔닝, 리플레이 경험 차별화 |
| R7 | 모바일 네트워크 품질 변동 | 중 | 높 | Adaptive bitrate, 포인트 간소화 fallback, 재접속 자동화 |
| R8 | 음성과 필기의 시간 동기화 불일치 | 낮 | 중 | 공통 타임스탬프 기반, NTP 보정은 Phase 2 |

---

## 8. 기술 아키텍처 개요

### 8.1 컴포넌트 다이어그램

```
선생님 디바이스                              학생 디바이스
┌──────────────────────┐                ┌──────────────────────┐
│ ScribbleBookController│                │ ScribbleBookController│
│ ScribbleEventBridge   │                │ (read-only mode)     │
│ ViewportTracker       │                │ ViewportFollower     │
└──────────┬───────────┘                └──────────▲───────────┘
           │                                       │
┌──────────▼───────────┐                ┌──────────┴───────────┐
│ LiveSessionTransport  │                │ LiveSessionTransport  │
│ (LiveKitTransport)    │                │ (LiveKitTransport)    │
└──────────┬───────────┘                └──────────▲───────────┘
           │                                       │
           └───────────── LiveKit SFU ─────────────┘
                     (Data Channel + Audio)
```

### 8.2 데이터 흐름

```
[필기 중]
선생님 터치 → Point 생성(timestamp) → Lossy DC("stroke_stream") → 학생 실시간 렌더링
선생님 손 뗌 → Stroke 완성 → Reliable DC("stroke_complete") → 학생 스트로크 교체
                            → 타임라인 기록 (StrokeAddedEvent)

[뷰포트 변경]
선생님 pinch/pan → ViewportChanged → 100ms throttle → Lossy DC("viewport") → 학생 뷰포트 적용
                                                     → 타임라인 기록 (ViewportChangedEvent)

[세션 종료]
선생님 종료 → 타임라인 finalize → .obt 파일 생성 → 로컬 저장
```

### 8.3 기존 코드 변경 범위

| 파일/모듈 | 변경 유형 | 내용 |
|----------|----------|------|
| `scribble_book_event.dart` | 수정 | `ViewportChangedEvent` 추가 |
| `scribble_event_bridge.dart` | 수정 | 뷰포트 변경 감지 및 이벤트 발행 |
| `timeline_models.dart` | 수정 | `TlViewportChanged` 추가 |
| `timeline_serializer.dart` | 수정 | viewport 이벤트 직렬화/역직렬화 |
| `scribble_replay_handler.dart` | 수정 | viewport 이벤트 처리 (뷰포트 재현) |
| `lib/src/module/transport/` | 신규 | Transport 추상화 레이어 |
| `lib/src/module/session/` | 신규 | 세션 관리 (생성, 참가, 종료) |
| `lib/src/module/viewport/` | 신규 | ViewportTracker, ViewportFollower |

---

## 부록 A. 용어 정의

| 용어 | 정의 |
|------|------|
| Lossy Data Channel | UDP 기반, 순서/전달 비보장, 저지연 전송 (< 1,300B/패킷) |
| Reliable Data Channel | SCTP 기반, 순서/전달 보장, 신뢰 전송 (< 15KiB/패킷) |
| .obt | Open Board Timeline -- 타임라인 기반 리플레이 파일 포맷 |
| ScribbleBookEvent | open-board의 sealed event class (9종, ViewportChanged 포함 시 10종) |
| Transport 추상화 | LiveKit 의존성을 격리하는 인터페이스 레이어 |
| 풀 싱크 | 늦은 참가자에게 현재 상태 전체를 전송하는 동기화 방식 |

## 부록 B. 관련 문서

- [Discovery: 실시간 온라인 튜터링 플랫폼](./discovery-live-tutoring.md)
- [BDD 시나리오: Phase 1](./bdd-live-tutoring-phase1.md)
