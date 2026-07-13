## Unreleased

### Added
- `EpubReader`/`ReflowablePageView`에 `spread`(`EpubSpread?`) 옵션 추가(kobic#8203)
  — reflowable(흐름형) EPUB **페이지(paged) 모드에서 단면/양면(2-up spread)** 을
  지원한다. 그동안 `fixedLayoutSpreadOverride`는 fixed-layout 엔진에만 전달되어
  reflowable paged 는 spread 설정이 무시됐다(open-epub#221 이후 미구현). fixed-layout
  처럼 spine 을 쌍짓는 게 아니라, 같은 spine 내 **연속 두 윈도우(왼쪽=W, 오른쪽=W+1)**
  를 좌우 컬럼으로 배치한다. `ViewportFitter.shouldUseTwoPageSpread`(뷰포트+spread)로
  활성 여부를 판정하고, 각 컬럼은 반폭 뷰포트로 렌더된다(non-fixed 는 반폭 리플로우,
  `fixedPageSize` A4 는 반폭 컬럼에 contain-fit). 페이지 넘김(`_advance`)은 spread 시
  두 윈도우씩 이동하고 윈도우 상태 보고는 스프레드(pair) 단위로 환산되며, RTL 은 좌우
  컬럼이 반전된다. 각 컬럼이 기존 `_SpinePageView` 를 재사용하므로 윈도우별 필기
  캔버스 seam(`{href}#p{windowIndex}`)이 컬럼별로 그대로 유지된다. `spread` 가
  null(기본값)이면 기존 단면 동작이 완전히 그대로 유지된다.
- `EpubReader`/`ReflowablePageView`에 `fixedPageSize` 옵션 추가(kobic Epic #7964
  S1) — reflowable(흐름형) EPUB 본문을 논리 고정 크기(예: A4 210:297 근사)로
  강제 페이지네이션한다. 값이 있으면 화면 단위 윈도잉(open-epub#221)이 이
  고정 크기를 기준으로 이루어지고, 결과가 실제 화면에 contain-fit
  스케일된다(fixed-layout 엔진과 동일한 좌표 안정성). `fixedLayoutContentBuilder`가
  각 가상 페이지(윈도우)마다 `{href}#p{windowIndex}` 형태의 합성 `EpubSpineItem`으로
  호출되어, 호스트가 페이지별 독립 필기 캔버스를 마운트할 수 있다(진짜
  fixed-layout 페이지와 동일 계약 재사용). `EpubViewController`의 위치 복원도
  `EpubReflowablePosition.pageIndex` 힌트로 확장해 재진입 시 같은 가상
  페이지로 복원한다. 이 모드는 핀치 줌을 제공하지 않는다(스와이프 페이지
  넘김 제스처와의 경합 회피). `fixedPageSize`가 null(기본값)이면 기존 동작이
  완전히 그대로 유지된다.

### Fixed
- 목차(TOC) 항목을 탭해도 실제 화면이 이동하지 않던 문제 수정 — `EpubViewController`에
  `goToHref(String href)`를 추가해 `EpubOutlineItem.spineHref`를 그대로 넘겨 해당
  spine으로 이동할 수 있게 했다. 기존에는 화면을 실제로 이동시키는 유일한 API인
  `EpubViewController.goToSpine`이 정수 spine 인덱스만 받아, 목차 데이터(href)와
  연결할 방법이 없었다.
- 뷰어 재진입 시 위치 복원이 챕터(spine) 단위로만 동작하던 문제 수정 —
  `EpubReader.onPositionChanged`가 실제로는 항상 챕터 시작(`charOffset: 0`)만
  보고했고, 그마저도 (1) 스크롤 모드는 화면 최상단 spine이 바뀔 때만, (2) paged
  (스와이프) 모드는 `fixedPageSize`를 지정하지 않는 한 같은 챕터 내 윈도우
  이동에서 전혀 보고되지 않아, 재진입 시 항상 마지막 챕터의 시작으로만
  복원됐다.
  - paged 모드: 이미 `fixedPageSize` 전용으로 구현돼 있던 윈도우(가상 페이지)
    단위 위치 저장/복원(`EpubReflowablePosition.pageIndex`)을 `fixedPageSize`
    유무와 무관하게 모든 paged 모드로 확장.
  - 스크롤 모드(기본값): `scrollable_positioned_list`의
    `ItemPosition.itemLeadingEdge`/`initialAlignment`를 이용해 챕터 내부
    스크롤 위치를 캡처·복원하는 신규 `EpubReflowablePosition.scrollAlignment`
    hint 추가. 스크롤이 정착(사용자 드래그 종료)할 때마다 spine 전환 여부와
    무관하게 위치를 보고한다.
  - 저장 시점과 크게 다른 뷰포트·폰트 크기로 복원하면 여전히 근사치다(같은
    기기·세션 재진입을 전제).

## 1.0.0

open_epub 1.0 — **ADR-002 breaking 재설계**. 리더 패키지를 Flutter 렌더/위젯/컨트롤러
계층으로 좁히고, 순수-Dart EPUB 2/3 파서·객체 모델·CFI 로케이터를 **별도 패키지
[`open_epub_engine`](https://pub.dev/packages/open_epub_engine)** 로 분리했다
(ADR-002-a: pub.dev 독립 발행 + lockstep 버저닝, 모노레포 pub workspace). 0.x에서
올라오는 사용자는 [`MIGRATION.md`](MIGRATION.md)의 0.x → 1.0 API 매핑을 참고.

진입점은 `package:open_epub/open_epub.dart` 하나로 통일된다. 엔진에서 이동한
타입(`EpubBook`·`EpubSource`·`EpubPosition`·`EpubMetadata` 등)은 이 배럴에서
재-export 하므로 대부분의 소비자는 import 한 줄만 유지하면 된다.

### Breaking Changes
- 공개 API 전면 재설계 — 세션 기반 모델(`EpubBookSession`) + `EpubReader` 위젯 +
  `EpubViewController`로 대체. 0.x 위젯 API(`EpubReaderWidget`·`EpubReaderController`·
  `ReaderSettings`·`EpubReaderLocalization`)는 제거됐다. (E1, E11)
- 파서·모델·코덱·도메인 계층을 별도 패키지 `open_epub_engine`으로 이관. 순수-Dart
  소비자는 리더(Flutter) 의존 없이 엔진만 직접 의존할 수 있다. (E10, ADR-002-a)
- 소스 추상화 `EpubSource`(`bytes`/`file`/`url` factory) 도입 — 0.x `EpubSourceAsset`
  등 구체 클래스 대체. 에셋은 `rootBundle`로 바이트를 읽어 `EpubSource.bytes(...)`로 연다.
- 위치 복원을 **BookPosition v1 토큰**(`EpubPosition.toToken()` / `fromToken()`)으로
  통일 — 0.x page-index / progress 기반 API 제거.
- 렌더 파라미터(`fontSize`·`lineHeight` 등)를 위젯 인자로 직접 주입. 0.x의 설정
  자동 영속화(SharedPreferences)는 제거됐고, 영속화는 호스트 책임이다.

### Added
- **엔진 분리** — `open_epub_engine`: Flutter 무의존 순수-Dart EPUB 2/3 파서·객체 모델·
  CFI 로케이터. `epubx`/`epub_view`를 대체한다. (E10)
- **Reflowable 엔진** — spine XHTML 렌더, 글자 크기·줄간격 페이지네이션, 스크롤/페이지
  모드, 페이지 모드 화면 단위 윈도잉. (E1; #221, #223, #230, #234)
- **Fixed-layout 엔진** — SVG/XHTML viewport fit, 핀치 줌(`InteractiveViewer`), 양면/단면
  spread 자동 분기 + 강제 토글(`fixedLayoutSpreadOverride`). (E1, kobic#7576)
- **선택·하이라이트** — `SelectionArea` 기반 선택, 정확 일치 실패 시 정규화 매칭 폴백
  (`SpineTextExtractor.resolveSelection`), 콘텐츠 hot-swap 재렌더. (E1, #62)
- **CFI 보충 매퍼** — epub_pro CFI 프리미티브 이식, charOffset ↔ 문서-내 CFI, 콘텐츠
  교체 시 하이라이트/북마크 재앵커, 외부 표준 전체-책 CFI export/import
  (`EpubCfiMapper`). (E12, ADR-010)
- **EPUB3 파싱 확장** — landmarks/page-list, `rendition:viewport`/`orientation`,
  page-progression-direction + `BookCapabilities`, multiple renditions + 확장 메타데이터,
  `encryption.xml` + IDPF/Adobe 폰트 난독화 해제, SMIL(Media Overlay) 파서. (E13)
- **EPUB3 렌더 확장** — RTL page-progression 페이지 넘김 방향(`readingDirection`),
  MathML → TeX 자체 폴백 렌더(`flutter_math_fork`). (E14)
- **Media Overlays 낭독** — manifest → SMIL → spine 배선, `just_audio` 재생 컨트롤러
  (`MediaOverlayController`), 낭독 하이라이트 동기화. (E15)
- **세로쓰기(vertical-rl)** 실용 조판(`verticalWriting`, `VerticalTextBlock`). (E15)
- **인라인 SVG** 렌더(`fwfh_svg`) + never-empty 렌더 계약. (E11, ADR-009)
- 분석 이벤트 스트림(lifecycle / progress / toolUse), 보정 진단
  (`BookSessionDiagnostics`), 보안 설정(`EpubSecurityConfig` — 파일 크기 제한,
  script/iframe sanitize, zip-slip 경로 정규화).

### Changed
- 본문 렌더러 교체: `flutter_html` → `flutter_widget_from_html_core`(+`fwfh_svg`).
  유지보수성·즉시 SVG 지원, WebView/스크립트 스택 미유입으로 보안 모델과 정합.
  (E11, ADR-009)
- 모노레포 pub workspace 전환(`resolution: workspace`) + CI 두 잡 병렬
  (engine `dart test` / reader `flutter test`). (E10)
- 성능 — EPUB open 시 ZIP/XML 파싱 isolate 오프로딩, `ArchiveResourceReader` LRU
  eviction, OPF 다중 재파싱 → 단일 파싱 통합, 검색 인덱스 소문자 변환 build 캐싱,
  진행률 `ValueListenable` 분리. (E9)
- 하위 폴더 본문의 이미지 상대경로 해석. (#115)

### Removed
- 0.x 레거시 위젯/컨트롤러/모델/로컬라이제이션(`EpubReaderWidget`·`EpubReaderController`·
  `ReaderSettings`·`EpubReaderLocalization`)과 레거시 배럴. (E11)
- 레거시 의존성 — `epubx`·`epub_view`·`flutter_html`(레거시 파서·렌더),
  `google_fonts`·`shared_preferences`·`http`(레거시 위젯·설정). `xml`·`archive`는
  엔진 패키지로 이동했다. (E11)
- **JavaScript 런타임 미포함** — EPUB3 Scripted Content(`<script>`·`<iframe>`·inline
  event handler·`javascript:`)는 보안상 의도적 미지원. 정적 폴백을 렌더한다. (E14)

## 0.1.3

### Bug Fixes
- Fix content failing to load for EPUBs with a sparse or incomplete `toc.ncx` (common with Calibre-generated files) — reader now falls back to the spine, which is the authoritative reading order per the EPUB spec, so books where NCX only references the title page now render all content

### New Features
- Skip the cover/title page from the reading flow — detects cover via `<guide type="cover">`, EPUB 3 `properties="cover-image"`, and EPUB 2 `<meta name="cover">` so the reader opens on actual content instead of the cover image

## 0.1.2

### New Features
- Add `progressBarColor` parameter to customize the reading progress bar color

## 0.1.1

### Bug Fixes
- Fix page content changing when toggling top/bottom bars — reader now uses stable viewport constraints regardless of bar visibility, preventing unnecessary repagination

### New Features
- Add reading progress bar at the top of the screen when bars are hidden (2px thin indicator)
- Top/bottom bars now render as overlays instead of resizing the reader content area (iBooks/Kindle-style UX)

## 0.1.0

### Bug Fixes
- Fix pagination freeze — `_isPaginating` flag now resets on cancelled pagination runs, preventing permanent loading screen
- Fix paragraph index gaps in EPUBs with multi-row tables, which caused scroll-mode page tracking errors
- Fix settings panel overflow on small screens — Color Theme, Font Family, View Mode selectors now use `Wrap`/`Column` layout
- Fix `_buildControlRow` label overflow with long localized strings — label now uses `Flexible` with ellipsis
- Fix `onSettingsChanged` callback firing on every scroll/page turn — now only fires on actual settings changes
- Fix content area wasting 56px when bottom bar is hidden — layout now adapts dynamically to bar visibility
- Fix `Bookmark.copyWith` unable to clear nullable `title`/`excerpt` fields — uses sentinel pattern

### New Features
- Support swapping EPUB source without recreating the widget (`didUpdateWidget`)
- Add `==`/`hashCode` to `ReaderSettings`, `EpubSource` subclasses, and `Bookmark.copyWith` sentinel support

### Performance
- Parallelize settings storage load and EPUB parsing on startup (previously sequential)
- Eliminate redundant `setSettings` calls on every scroll tick

### Internal
- Extract `_buildSection` helper in settings panel to reduce layout duplication
- Unify duplicated table-splitting logic into single loop in `_loadBookContent`

## 0.0.9

- Add multi-language localization support with `EpubReaderLocalization`
- Built-in translations for 11 languages: Korean (default), English, Chinese (Simplified), Hindi, Spanish, Arabic, French, Portuguese, Russian, Japanese, German
- All UI strings (settings panel labels, error messages) are fully localizable
- Custom translations supported via constructor with Korean defaults for backwards compatibility
- Fix `fontSansSerif` English value from `'Gothic'` to `'Sans-serif'`
- Fix non-`EpubLoadException` errors displaying raw `e.toString()` instead of localized unknown error message
- Localize Noto Sans font button label via `fontNotoSans` field for consistency
- Change `ColorTheme.name` values from Korean to English

## 0.0.8

- Fix images not rendering in EPUB files — image-only elements (e.g. `<img>` directly in `<body>`) were misclassified as spacing and silently dropped
- Fix `getElementsByTagName` not matching when the element itself is the `<img>` tag — now also checks `element.localName`
- Fix image paragraphs being filtered out due to empty `plainText` — `richContent` type now bypasses text-based filtering
- Fix pagination for image-heavy EPUBs — each image paragraph is allocated a full page instead of near-zero height
- Add `blockTags` support for `img`, `image`, `svg` in `_splitIntoBlockElements`
- Wrap standalone `<img>` elements in `<div>` for correct `flutter_html` `TagExtension` handling
- Improve EPUB image path resolution with filename-based and case-insensitive fallback matching

## 0.0.7

- Fix pagination density: pages no longer show only 1-2 lines or half-empty content
- Add `_ParagraphType` classification (plainText, dialogue, richContent, spacing) for accurate per-type measurement and rendering
- Fix dialogue table rendering: measure and render with matching two-column layout (name + text)
- Fix `requiresRichContent` always being true — plain text paragraphs now use `Text` widget instead of `Html`
- Preserve spacing paragraphs (`&#160;`) for proper section gaps
- Split multi-row dialogue tables into individual paragraph items
- Reduce safe margin from 2x to 1x line height for better page utilization
- Remove unsupported platform files (linux, macos, windows) from example app

## 0.0.6

- Add comprehensive example app with feature configuration screen
- Add page/scroll mode toggle to settings panel
- Example app demonstrates all widget features: source types, watermark, max pages, persistence, resume position, custom bars, initial bookmarks

## 0.0.5

- Remove flutter_riverpod dependency to prevent version conflicts with user apps
- Replace Riverpod with Flutter's built-in ChangeNotifier for internal state management
- Remove unused bookmarks_provider.dart

## 0.0.3

- Remove unused platform runners (linux, macos, windows)
- Update README for pub.dev installation

## 0.0.2

- Initial release
- EPUB reader widget with pagination and scroll modes
- Customizable themes and fonts
- Bookmark management
- Settings persistence
- Support for iOS, Android, and Web platforms
