## Unreleased — 1.0 core (E1)

새 1.0 코어 엔진을 별도 entry `package:open_epub/open_epub_v1.dart`로 도입.
기존 `package:open_epub/open_epub.dart`(0.1.x API)는 그대로 유지된다. 정식
1.0 릴리스(버전 bump + MIGRATION.md)는 E6에서 진행.

### New (1.0 core, `open_epub_v1.dart`)
- fixed-layout 양면/단면 토글 + 페이지 내비게이션 (kobic#7576)
  - `EpubReader.fixedLayoutSpreadOverride` — 호스트가 `EpubSpread`를 강제해
    양면(landscape)/단면(none) 사용자 토글을 구동. null이면 기존처럼
    `rendition:spread` 메타데이터를 따른다
  - fixed-layout에도 reflowable paged와 동일한 내비게이션 계약 배선 —
    `EpubViewController.goToSpine`(목차 점프), `onPageChanged` /
    `onPositionChanged`(진행률·위치 영속화) 동작
  - 수평 스와이프 페이지 넘김 — `InteractiveViewer.onInteractionEnd` 속도
    기반이라 팬/줌 제스처와 아레나 경합 없음. 줌 1.0x에서만 동작, spread
    렌더 중에는 row 단위 이동
- `EpubBookSession.open()` — EPUB ZIP 해제 → OPF/NCX/nav 파싱 → 호환성 보정 →
  `EpubBook` 조립 end-to-end. 위치 복원(BookPosition v1 토큰, 실패 시 첫 페이지
  fallback + `position-restore-failed` 진단), hot-swap(`swapSource`), 분석 스트림
  (lifecycle/progress/toolUse, progress throttle), 보안 가드(크기 제한, script/iframe
  sanitize) 포함
- `EpubReader` 위젯 — layout(reflowable/pre-paginated)에 따라 `ReflowableEngine` /
  `FixedLayoutEngine` 자동 분기, 복원 실패 안내 배너, 진도 인디케이터
- `EpubResourceReader` — 컨테이너 내부 리소스(본문/이미지) 접근, `..` 경로 정규화
- BDD widget 테스트 11 feature 활성화 (skip 해제), patrol E2E 스텁은 E4 범위로 명시

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
