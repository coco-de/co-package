## 1.0.0

open_epub_engine 1.0 — **순수-Dart EPUB 2/3 엔진의 첫 안정 릴리스**. 리더
[`open_epub`](https://pub.dev/packages/open_epub)에서 파서·객체 모델·CFI 로케이터를
분리해 헤드리스(CLI·서버) 소비가 가능하도록 별도 발행한다 (ADR-002-a: pub.dev 독립
발행 + lockstep 버저닝, 모노레포 pub workspace).

이 버전에서 **공개 API를 동결**했다(S6.1). 배럴
`package:open_epub_engine/open_epub_engine.dart`의 export가 곧 semver 계약이며,
1.0.x 동안 호환을 유지한다. 테스트 픽스처는 별도 배럴
`package:open_epub_engine/testing.dart`로 분리돼 프로덕션 표면에 포함되지 않는다.

### 동결된 공개 API (semver 계약)

- **Session** — 고수준 진입점 `EpubBookSession.open(EpubSource)`. open / jumpTo /
  페이지 이동 / hot-swap(`swapSource`) / lifecycle·progress·tool-use analytics.
  소스 추상화 `EpubSource`(`bytes` / `file` / `url` factory), `EpubBook`,
  sealed `EpubPosition`(`EpubReflowablePosition` / `EpubFixedPosition`).
- **Parsers** — `OpfParser`, `NcxParser`, `NavParser`, `ContainerParser`,
  `SmilParser`.
- **Domain 모델** — `EpubMetadata`(+ `EpubLayout` / `EpubSpread` /
  `EpubOrientation` / `EpubViewport`), `EpubSpineItem`, `EpubOutline`,
  `EpubNavigation`, `EpubRendition`, `BookCapabilities`, `EpubMediaOverlay`,
  `EpubHighlight`, `EpubSelection`, `EpubResource`, `EpubFailure`,
  `TextLayerVerdict`, `LoadedEpub`. 도메인 계약 `EpubRepository`.
- **CFI** (ADR-010) — `EpubCfiMapper`(`charOffset ↔ 문서-내 CFI`) + 표준 전체-책
  CFI import/export(`BookCfiParts`). 세션 레벨 `exportPositionCfi` /
  `importPositionCfi`로 상호운용.
- **Search** — `BuildSearchIndexUseCase` / `TextIndexBuilder`로 spine 본문 인덱스
  빌드, `BookSearchIndex.search(query)` → `BookSearchHit`. 세션의
  `buildSearchIndex()` / `positionForHit(hit)`로 점프 위치 산출.
- **Codec** — `BookPositionCodec` + `EpubPosition.toToken()` / `fromToken()`
  (BookPosition v1: JSON ≤ 512 bytes, round-trip 무손실).
- **Schema** — `EpubVersion` enum + `EpubVersionDetection`(nav/NCX 교차검증).
- **Security / compat / text** — `HtmlSanitizer`(script/iframe 차단),
  `EncryptionParser`(`encryption.xml` + IDPF/Adobe 폰트 난독화 해제),
  `PatchCatalog`(호환성 보정) + `BookSessionDiagnostics`,
  `SpineTextExtractor`, `SearchHighlighter`,
  공개 유스케이스 `DetectTextLayerUseCase`.

### 비공개(내부 구현)

리포지토리 구현(`EpubRepositoryImpl`)과 세션이 내부에서 오케스트레이션하는 유스케이스
(open / apply-patches / resolve-position)는 배럴에서 제외한다 — 소비자는
`EpubBookSession.open()`으로 진입하고, 타입이 필요하면 도메인 계약 `EpubRepository`를
쓴다.

### 문서

- README에 용도·직접 의존 가이드(대부분의 소비자는 리더 `open_epub`를 쓰고, 엔진 직접
  의존은 CLI·서버 등 헤드리스 전용)·핵심 사용 예·리더 크로스링크를 추가.
- `example/`에 순수-Dart 실행 CLI(`dart run`) 추가 — `.epub` 경로를 받아 메타데이터·
  목차·검색·CFI를 출력.

## 0.0.1

- 초기 스캐폴드 (S10.2). pub workspace 멤버, 공개 배럴, `EpubVersion` enum.
