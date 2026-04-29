# Discovery: 실시간 온라인 튜터링 플랫폼

> Open-Board 필기 엔진 + LiveKit 실시간 인프라 기반 온라인 강의 플랫폼

---

## 1. 사용자 리서치

### 타겟 페르소나

| 페르소나 | 역할 | 핵심 니즈 | Pain Point |
|---------|------|----------|-----------|
| **선생님 (튜터)** | 서비스 선택자 | 자연스러운 필기, 수업 재활용 | 매번 같은 내용 반복 설명, 수업 자산화 불가 |
| **학생** | 사용자 | 이해 안 되는 부분 다시 보기 | 90분 녹화 영상에서 핵심 찾기 어려움 |
| **학부모** | 결제자 | 수업 품질 확인 | 수업 내용 파악 불가, 투자 대비 효과 불명확 |
| **학원/플랫폼** | B2B 고객 | 관리 편의성, 데이터 주권 | 높은 인프라 비용, 벤더 종속 |

### 핵심 인사이트

1. **수업이 끝나면 남는 것이 없다**: 녹화 영상은 거의 다시 보지 않음 → "수업의 자산화"가 미충족 니즈
2. **선생님의 시선이 곧 교수법**: 어디를 확대하고 가리키며 설명하는지가 학습의 결정적 순간
3. **의사결정 삼각구조**: 선생님이 도구를 선택 → 학생이 사용 → 학부모가 결제

### 검증할 가정

| 가정 | 리스크 | 검증 방법 |
|------|--------|----------|
| 선생님은 네이티브 필기 품질을 WebView보다 선호한다 | 중 | A/B 사용성 테스트 |
| 학생은 리플레이 교재를 실제로 복습에 활용한다 | 높 | MVP 사용 데이터 측정 |
| 학부모는 리플레이 접근권에 추가 비용을 지불한다 | 높 | 가격 민감도 인터뷰 |
| 1:1 과외 시장이 충분한 초기 시장이다 | 낮 | 시장 규모 데이터 |

---

## 2. 시장 분석

### 경쟁 환경

#### Pagecall (직접 경쟁)

| 항목 | 상세 |
|------|------|
| **규모** | 누적 2억 분, 33개국, 웅진/대교/콴다 등 대형 고객 |
| **기술** | WebGL + Delta Sync, SFU (mediasoup), WebRTC Data Channel |
| **강점** | 9년 기술 축적, 자동 녹화, 풍부한 SDK (Web/iOS/Android/RN/Flutter) |
| **약점** | 네이티브 SDK = WebView 래퍼 (비디오 미지원), 10Mbps/75ms 높은 네트워크 요구, 가격 비공개, 브라우저 호환성 제한 |
| **리플레이** | 녹화 영상 기반 (인터랙티브 필기 재현 포함하나 스트로크 단위 seek/편집 불가) |

#### 간접 경쟁

| 서비스 | 포지션 | 한계 |
|--------|--------|------|
| Zoom + 화면공유 | 범용 화상회의 | 필기 없음, 대체재로 "충분히 좋음" |
| Miro / FigJam | 협업 화이트보드 | 교육 특화 아님, 리플레이 없음 |
| 클래스101 | 녹화 강의 판매 | 실시간 상호작용 없음 |

### 차별화 포인트

```
Pagecall이 할 수 없는 것:
1. 네이티브 Flutter 렌더링 (6개 플랫폼, WebView 아님)
2. 스트로크/포인트 단위 인터랙티브 리플레이 (seek, speed, 부분 재생)
3. 선생님 뷰포트(카메라) 재현 → "선생님이 보던 화면" 그대로 복습
4. .obt 타임라인 = 편집/재활용 가능한 교재 자산
5. Self-Hosting 가능 (LiveKit 오픈소스) → 데이터 주권
```

---

## 3. 기술 분석

### 기존 보유 자산 (open-board)

#### 이벤트 시스템 — 실시간 전송 적합성: **매우 높음**

```
ScribbleBookEvent (sealed, 8종)
├── PageChangedEvent      ~100-200B   뷰포트 전환
├── StrokeAddedEvent      ~50-100B    획 추가 (메타만, 데이터 별도)
├── StrokeRemovedEvent    ~50-100B    획 삭제
├── UndoPerformedEvent    ~30-50B     undo
├── RedoPerformedEvent    ~30-50B     redo
├── PageAddedEvent        ~50-100B    페이지 추가
├── PageRemovedEvent      ~50-100B    페이지 삭제
└── PageClearedEvent      ~30-50B     페이지 초기화
```

- 모든 이벤트 마이크로초 타임스탬프 포함
- Data Channel MTU(1,300B) 대비 충분히 작음
- SCTP 순서 보장과 호환

#### 현재 저장되지 않는 정보 (추가 필요)

| 정보 | 현재 | 필요 |
|------|------|------|
| 뷰포트 스케일 (zoom) | X | O — 리플레이 시 선생님 화면 재현 |
| 캔버스 오프셋 (pan) | X | O — 선생님이 보던 영역 추적 |
| 뷰포트 center 좌표 | X | O — 멀티디바이스 적응 렌더링 기준점 |
| 디바이스 화면 비율 | X | O — 리플레이 시 적응형 뷰포트 계산 |

#### Protobuf 스키마 — 확장 용이

```protobuf
// Point: 이미 timestamp(int64) 포함 → 실시간 스트리밍 가능
message Point {
  double x, y, p;           // 좌표 + 압력
  int64 timestamp = 9;      // 절대 마이크로초
}

// 추가 필요:
message ViewportEvent {
  double scale = 1;          // 확대/축소 비율
  double centerX = 2;        // 중심 X 좌표
  double centerY = 3;        // 중심 Y 좌표
  double viewportWidth = 4;  // 뷰포트 논리 너비
  double viewportHeight = 5; // 뷰포트 논리 높이
  int64 timestamp = 6;       // 타임스탬프
  string pageId = 7;         // 페이지 ID
}
```

### LiveKit 기술 적합성

| 항목 | 평가 | 근거 |
|------|------|------|
| Flutter SDK | **매우 적합** | `livekit_client` v2.7.0, 6개 플랫폼 공식 지원, pub.dev 258 likes |
| Data Channel | **매우 적합** | Reliable/Lossy 모드, Topic 시스템, 대상 지정 가능 |
| 1:1/1:N/N:N | **모두 지원** | SFU 아키텍처, 수평 확장 가능 |
| 녹화 | **부분 적합** | Egress로 영상 녹화 가능, Data Channel(필기)은 별도 저장 필요 |
| 비용 | **유리** | Self-Host 무료(Apache 2.0), Cloud/Self-Host 무전환 코드 |
| 지연시간 | **적합** | sub-100ms (SFU 경유) |

#### 실시간 필기 전송 설계

```
스트로크 진행 중 (포인트 스트리밍)
  → Lossy 모드, topic: "stroke_stream"
  → 페이로드: {pageId, x, y, pressure, timestamp} (~40B)
  → 지연: sub-100ms

스트로크 완료
  → Reliable 모드, topic: "stroke_complete"
  → 페이로드: 전체 Stroke protobuf (~수KB)
  → 순서/전달 보장

뷰포트 변경
  → Lossy 모드, topic: "viewport"
  → 페이로드: {scale, centerX, centerY, timestamp} (~30B)
  → 100ms 쓰로틀링
```

### 아키텍처 핵심 원칙

```
Transport 추상화 (LiveKit 의존성 격리)
┌──────────────────────────────┐
│  ScribbleBookController      │ ← 기존 코드 변경 없음
│  ScribbleEventBridge         │
└──────────┬───────────────────┘
           │ ScribbleBookEvent stream
┌──────────▼───────────────────┐
│  LiveSessionTransport        │ ← 새로 추가할 추상화 레이어
│  ├─ LiveKitTransport         │   (LiveKit 구현)
│  ├─ WebSocketTransport       │   (향후 대체 가능)
│  └─ LocalReplayTransport     │   (오프라인 리플레이)
└──────────────────────────────┘
```

---

## 4. 비전

### 비전 스테이트먼트

> **"모든 수업이 다시 꺼내볼 수 있는 나만의 교재가 된다"**
>
> 선생님의 필기와 시선이 살아있는 인터랙티브 수업 리플레이 — 단순 녹화가 아닌, 학습의 결정적 순간으로 직행하는 경험

### North Star Metric

**"주간 리플레이 재생 수"** — 수업 후 학생이 실제로 복습하는 횟수

- Leading indicator: 수업 완료율, .obt 파일 생성 수
- Lagging indicator: 학생 성적 향상, 학부모 만족도, 선생님 재사용률

### 포지셔닝

```
Pagecall: "실시간 화이트보드 강의실" (인프라)
우리:     "수업이 교재가 되는 튜터링 플랫폼" (교육 경험)
```

---

## 5. 전략 로드맵

### Phase 1: 1:1 과외 MVP (0-3개월)

| 항목 | 내용 |
|------|------|
| **목표** | 선생님 1명 + 학생 1명의 실시간 필기 수업 + 리플레이 |
| **구현** | LiveKit Data Channel 필기 동기화, 음성 통화, .obt 자동 저장 |
| **뷰포트** | ViewportEvent 추가 (scale, center, timestamp) |
| **리플레이** | 선생님 뷰포트 재현 + 멀티디바이스 적응 렌더링 |
| **수익** | 무료 (PMF 검증) |

### Phase 2: B2B SDK SaaS (3-6개월)

| 항목 | 내용 |
|------|------|
| **목표** | 기존 교육 플랫폼/학원에 SDK 제공 |
| **구현** | Transport 추상화, 세션 관리 API, 관리자 대시보드 |
| **수익** | MAU 기반 월 구독 (예: 동시접속 100명 월 30만원) |

### Phase 3: 1:N 그룹 강의 (6-12개월)

| 항목 | 내용 |
|------|------|
| **목표** | 선생님 1명 + 학생 N명 (최대 30명) |
| **구현** | 참가자별 커서, 권한 관리, 선택적 필기 허용 |
| **수익** | 그룹 수업 프리미엄 과금 |

### Phase 4: 콘텐츠 마켓플레이스 (12개월+)

| 항목 | 내용 |
|------|------|
| **목표** | .obt 리플레이 교재 판매 플랫폼 |
| **구현** | 교재 검색, 미리보기, 구매, 선생님 수익 정산 |
| **수익** | 판매 수수료 30% |

### 하지 않을 것 (Via Negativa)

- N:N 스터디그룹 (수익 모델 불명확, 기술 복잡도 O(N^2))
- Self-Hosting 실제 구현 (고객이 계약서에 서명할 때까지)
- 분당 과금 모델 (인프라 비즈니스가 아님)
- 고해상도 실시간 비디오 의존 (필기에 불필요한 경우)

---

## 6. 데이터 구조 확장 제안

### 새로운 이벤트 타입

```dart
// ScribbleBookEvent에 추가
class ViewportChangedEvent extends ScribbleBookEvent {
  final String pageId;
  final double scale;
  final double centerX;
  final double centerY;
  final double viewportWidth;
  final double viewportHeight;
}

class BookmarkAddedEvent extends ScribbleBookEvent {
  final String pageId;
  final String label;     // "중요!", "여기 시험에 나와요" 등
}

class ParticipantJoinedEvent extends ScribbleBookEvent {
  final String participantId;
  final String role;      // "teacher", "student"
}
```

### timeline.proto 확장

```protobuf
message TimelineEvent {
  int64 timestamp = 1;
  oneof event {
    // 기존 8종...
    TlViewportChanged viewportChanged = 10;  // 새로 추가
    TlBookmark bookmark = 11;                // 새로 추가
  }
}

message TlViewportChanged {
  string pageId = 1;
  double scale = 2;
  double centerX = 3;
  double centerY = 4;
  double viewportWidth = 5;
  double viewportHeight = 6;
}
```

### 멀티디바이스 뷰포트 어댑티브 렌더링

```
선생님 iPad (4:3)에서 녹화:
  viewport: {scale: 2.0, center: (500, 300), width: 1024, height: 768}

학생 iPhone (19.5:9)에서 리플레이:
  1. 선생님 center 좌표를 기준점으로 사용
  2. 학생 디바이스 비율에 맞게 visible area 재계산
  3. 선생님 scale을 유지하되, 가로/세로 여백 자동 조정
  → 선생님이 가리킨 영역이 항상 화면 중심에 위치
```

---

## 7. 리스크 및 완화 전략

| 리스크 | 영향 | 완화 |
|--------|------|------|
| LiveKit 의존성 (라이선스 변경, API 변경) | 높 | Transport 추상화 레이어로 격리 |
| Pagecall의 네이티브 SDK 강화 | 중 | 리플레이/교재화 = Pagecall이 따라오기 어려운 영역에 집중 |
| "더 좋은 필기"만으로는 전환 동기 부족 | 높 | 필기 품질이 아닌 "수업의 자산화"를 핵심 가치로 마케팅 |
| 늦게 입장한 참가자 상태 동기화 | 중 | 서버사이드 스냅샷 + 풀싱크 메커니즘 설계 |
| 대규모 그룹에서 동기화 복잡도 폭발 | 중 | 1:1에서 시작, 아키텍처만 multi-participant 고려 |

---

## 8. 권고사항: Planning 스테이지 입력 사항

### 즉시 시작

1. **ViewportChangedEvent** 이벤트 타입을 ScribbleBookEvent에 추가
2. **Transport 추상화 인터페이스** 설계 (LiveKit 의존성 격리)
3. LiveKit Flutter SDK PoC — Data Channel로 포인트 스트리밍 왕복 지연 측정

### 설계 결정 필요

- 뷰포트 이벤트 쓰로틀링 간격 (50ms vs 100ms vs 200ms)
- 늦은 참가자 동기화 전략 (전체 Scribble 스냅샷 vs 이벤트 리플레이)
- .obt 파일 포맷을 JSON → Protobuf 바이너리로 전환하는 시점

### 다음 스테이지

`/project:plan` — Phase 1 (1:1 과외 MVP) 상세 기술 설계 및 이슈 분해
