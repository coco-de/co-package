# open_epub 0.x → 1.0 마이그레이션 가이드

open_epub **1.0**은 [ADR-002](#근거--출처)에 따른 **breaking 재설계**다. 0.x가
"설정 UI·북마크·상단/하단 바까지 포함한 완성형 리더 위젯"을 제공했다면, 1.0은
**headless 세션 API(`EpubBookSession`) + 순수 렌더 위젯(`EpubReader`)**으로
분리하고, 파싱·모델·CFI 등 순수-Dart 코어를 별도 패키지
[`open_epub_engine`](https://pub.dev/packages/open_epub_engine)으로 추출했다
(ADR-002-a).

그 결과 0.x의 공개 심볼은 대부분 이름이 바뀌거나(치환), 컨셉 자체가 사라져
호스트 책임으로 넘어갔다(제거). 이 문서는 0.1.3 공개 API를 하나씩 1.0에
매핑한다.

> ⚠️ 표기 규칙
> - **치환**: 대응 심볼이 존재(이름/시그니처는 바뀔 수 있음).
> - **제거**: 1.0에 대응 심볼이 없음 → 호스트가 직접 구현.
> - **신설**: 0.x에 없던 1.0 전용 API.
> - **⚠️ 확인 필요**: 1:1 대응이 없거나, 의미/입력 타입이 달라져 기계적 치환이
>   불가능한 항목. 코드 마이그레이션 시 개별 검토가 필요하다.

---

## 목차

- [TL;DR (5분 요약)](#tldr-5분-요약)
- [import 경로 변경 (엔진 분리)](#import-경로-변경-엔진-분리)
- [Breaking 변경 3가지](#breaking-변경-3가지)
- [전체 API 매핑 표](#전체-api-매핑-표)
- [상세 매핑 + before/after](#상세-매핑--beforeafter)
  - [1. 리더 위젯: `EpubReaderWidget` → `EpubReader`](#1-리더-위젯-epubreaderwidget--epubreader)
  - [2. 컨트롤러: `EpubReaderController` → `EpubViewController`](#2-컨트롤러-epubreadercontroller--epubviewcontroller)
  - [3. 소스: `EpubSource*` → `EpubSource.*` factory](#3-소스-epubsource--epubsource-factory)
  - [4. 위치: `ReadingPosition` → `EpubPosition`](#4-위치-readingposition--epubposition)
  - [5. 로딩/에러: `EpubLoader`/`EpubLoadException` → 세션 + `EpubFailure`](#5-로딩에러-epubloaderepubloadexception--세션--epubfailure)
  - [6. 제거된 기능 (호스트 재구현)](#6-제거된-기능-호스트-재구현)
- [⚠️ 불확실 / 미검증 항목 모음](#️-불확실--미검증-항목-모음)
- [근거 / 출처](#근거--출처)

---

## TL;DR (5분 요약)

| 0.x | 1.0 |
| --- | --- |
| `EpubReaderWidget(...)` (설정·북마크·바 내장) | `EpubReader(...)` (순수 본문 렌더) + 호스트가 chrome/설정/북마크 구현 |
| `EpubReaderController` | `EpubViewController` (내비게이션만; 설정·북마크 제거) |
| `EpubSourceAsset('a.epub')` | ❌ 없음 → `EpubSource.bytes(await rootBundle.load(...))` |
| `EpubSourceBytes/File/Url(...)` | `EpubSource.bytes/file/url(...)` (factory, `url`은 `Uri`) |
| `ReadingPosition` (`toJson`) | `EpubPosition` (`toToken()`/`fromToken()`) |
| `ReaderSettings` / `ColorTheme` / `SettingsPanel` / `EpubReaderLocalization` | ❌ 제거 (호스트 소유) |
| `Bookmark` | ❌ 제거 (호스트가 `EpubPosition` 토큰으로 저장) |
| `EpubLoader` / `EpubLoadException` | `EpubBookSession.open()` / `EpubFailure` 계층 |
| — | 🆕 `EpubBookSession`, `EpubBook`, `EpubHighlight`, `EpubSelection`, `EpubCfiMapper`, analytics stream 등 |

import은 리더 소비자 기준 **그대로 한 줄**이다:

```dart
import 'package:open_epub/open_epub.dart';
```

---

## import 경로 변경 (엔진 분리)

ADR-002-a로 순수-Dart 코어(파서·모델·코덱·CFI·유즈케이스)가
`open_epub_engine`으로 분리되어 **pub.dev에 별도 발행**된다. `open_epub` 배럴이
이동한 타입을 `open_epub_engine`에서 re-export하므로, **Flutter 리더 소비자는
기존과 동일하게 한 줄만 import하면 된다.**

```dart
// 0.x — 그대로 1.0에서도 동작 (리더 위젯 + 재-export된 엔진 타입 모두 노출)
import 'package:open_epub/open_epub.dart';
```

`EpubBook`, `EpubBookSession`, `EpubSource`, `EpubPosition`, `EpubHighlight`,
`EpubFailure`, `EpubCfiMapper` 등 코어 타입은 실제로는 `open_epub_engine`에
살지만 `open_epub` 배럴이 re-export한다. 따라서 **개별 `src/...` 경로를
직접 import하지 말 것** — 항상 배럴을 쓴다.

Flutter에 의존하지 않는 순수-Dart 소비자(서버·CLI·백그라운드 파서 등)는
엔진만 직접 의존할 수 있다:

```yaml
# pubspec.yaml — Flutter 위젯이 필요 없는 순수 파싱 전용 소비자
dependencies:
  open_epub_engine: ^1.0.0   # ⚠️ 버전은 실제 발행 버전으로 확인 필요
```

```dart
import 'package:open_epub_engine/open_epub_engine.dart';
// EpubBookSession, EpubBook, EpubSource, EpubPosition ... (위젯/렌더는 없음)
```

> ⚠️ 확인 필요: `open_epub_engine`의 정확한 발행 버전 번호와 `open_epub`이
> 선언하는 의존 제약(`^1.0.0` 등)은 발행 시점 pubspec에서 확정된다. 이 문서의
> 버전 표기는 예시다.

---

## Breaking 변경 3가지

### (1) 위젯 결합도 해소 — chrome/설정/북마크가 위젯에서 빠졌다

0.x `EpubReaderWidget`은 상단/하단 바, 워터마크, 설정 모달(`SettingsPanel`),
설정 자동 저장(SharedPreferences), 북마크 관리, 다국어(`EpubReaderLocalization`),
미리보기 페이지 제한까지 **한 위젯 안에** 내장했다.

1.0 `EpubReader`는 **본문 렌더링과 페이지/위치 콜백만** 담당한다. 바·설정
UI·북마크 저장·로컬라이즈는 전부 호스트가 자신의 앱 디자인으로 구현한다.

**대응 지침**: `EpubReader`를 여러분의 `Scaffold`/`Stack` 안에 감싸고,
- AppBar/BottomBar → 호스트 위젯,
- 설정(폰트 크기·줄간격) → `EpubReader(fontSize:, lineHeight:)`를 상태로 관리,
- 북마크·진도 저장 → `onPositionChanged`/`onPageChanged` 콜백에서 직접 저장,
- 다국어 → 호스트 UI 문자열은 호스트의 l10n으로 처리.

### (2) source 추상화 도입 — 서브클래스 → factory, asset 제거

`EpubSource`가 sealed 서브클래스(`EpubSourceBytes` 등)에서 **factory
constructor**(`EpubSource.bytes` 등)로 바뀌었다. `readBytes()` 계약을 갖는 얇은
추상으로 재설계되어, 로딩이 세션(`EpubRepository`) 내부로 들어갔다.

**대응 지침**: 생성자 호출을 factory로 바꾼다. `EpubSourceAsset`은 사라졌으므로
(아래 §3) `rootBundle`로 바이트를 읽어 `EpubSource.bytes`에 넘긴다.

### (3) 엔진 분리 — 순수-Dart 코어가 별도 패키지

위 [import 경로 변경](#import-경로-변경-엔진-분리) 참고. 리더 소비자는 코드
변경이 없고, 순수-Dart 소비자만 `open_epub_engine`을 직접 의존할 수 있다.

---

## 전체 API 매핑 표

0.1.3 공개 배럴(`lib/open_epub.dart`)이 노출한 **24개 최상위 심볼** 전체를
매핑한다.

### 위젯 (7)

| 0.x 심볼 | 1.0 대응 | 상태 |
| --- | --- | --- |
| `EpubReaderWidget` | `EpubReader` | 치환 (대폭 축소) |
| `SettingsPanel` | — | 제거 |
| `OnPageChanged` `(int currentPage, int totalPages)` | `EpubPageChangedCallback` `(int spineIndex, int spineCount)` | 치환 ⚠️ (page→spine 의미 변화) |
| `OnLoadingProgress` `(double)` | — | 제거 ⚠️ |
| `OnError` `(String)` | (typed `EpubFailure` + 내부 에러뷰) | 치환 ⚠️ |
| `OnBookLoaded` `(String? title, String? author)` | `EpubSessionReadyCallback` + `session.book.metadata` | 치환 |
| `OnMaxPageReached` `(int, int)` | — | 제거 ⚠️ |

### 컨트롤러 (4)

| 0.x 심볼 | 1.0 대응 | 상태 |
| --- | --- | --- |
| `EpubReaderController` | `EpubViewController` | 치환 (대폭 축소) |
| `PositionChangedCallback` | `EpubPositionChangedCallback` (`EpubReader.onPositionChanged`) | 치환 |
| `SettingsChangedCallback` | — | 제거 |
| `BookmarkCallback` | — | 제거 |

### 소스 (5)

| 0.x 심볼 | 1.0 대응 | 상태 |
| --- | --- | --- |
| `EpubSource` (sealed) | `EpubSource` (abstract + factory) | 치환 (재설계) |
| `EpubSourceBytes(Uint8List)` | `EpubSource.bytes(Uint8List)` | 치환 |
| `EpubSourceFile(String)` | `EpubSource.file(String)` | 치환 |
| `EpubSourceUrl(String, {headers})` | `EpubSource.url(Uri, {headers})` | 치환 ⚠️ (`String`→`Uri`) |
| `EpubSourceAsset(String)` | — | 제거 ⚠️ |

### 모델 (6)

| 0.x 심볼 | 1.0 대응 | 상태 |
| --- | --- | --- |
| `ReaderSettings` | — | 제거 (→ `EpubReader.fontSize`/`lineHeight` px 파라미터) |
| `ColorTheme` | — | 제거 |
| `colorThemes` | — | 제거 |
| `EpubReaderLocalization` | — | 제거 |
| `Bookmark` | — | 제거 ⚠️ (→ 호스트 모델 + `EpubPosition` 토큰) |
| `ReadingPosition` | `EpubPosition` (`EpubReflowablePosition`/`EpubFixedPosition`) | 치환 ⚠️ (모델 상이) |

### 유틸 (2)

| 0.x 심볼 | 1.0 대응 | 상태 |
| --- | --- | --- |
| `EpubLoader` | — | 제거 (세션 내부) |
| `EpubLoadException` | `EpubFailure` 계층 | 치환 |

### 신설 (1.0 주요 전용 API, 발췌)

`EpubBookSession`, `EpubBook`, `EpubMetadata`, `EpubOutline`/`EpubOutlineItem`,
`EpubSpineItem`, `EpubResource`/`EpubResourceReader`, `BookCapabilities`,
`EpubHighlight`, `EpubSelection`, `EpubCfiMapper`, `EpubSecurityConfig`,
`EpubSessionOptions`, analytics 이벤트(`EpubLifecycleEvent`/`EpubProgressEvent`/
`EpubToolUseEvent` …), 검색(`BuildSearchIndexUseCase`/`BookSearchIndex`), Media
Overlay(`EpubMediaOverlay`/`MediaOverlayController`) 등. 전체 목록은
[`lib/open_epub.dart`](lib/open_epub.dart) 배럴 참고.

---

## 상세 매핑 + before/after

### 1. 리더 위젯: `EpubReaderWidget` → `EpubReader`

0.x `EpubReaderWidget`의 14개 생성자 파라미터별 대응:

| 0.x 파라미터 | 1.0 대응 | 비고 |
| --- | --- | --- |
| `source` | `source` | 타입 재설계 (§3) |
| `controller` | `controller` | `EpubReaderController`→`EpubViewController` (§2) |
| `initialSettings` (`ReaderSettings`) | `fontSize` / `lineHeight` | 개별 px 파라미터로 분해 |
| `onPageChanged(cur,total)` | `onPageChanged(spineIndex,spineCount)` | ⚠️ page→spine |
| `onLoadingProgress` | — | 제거 ⚠️ |
| `onError(String)` | — | 제거 (내부 에러뷰) ⚠️ |
| `onBookLoaded(title,author)` | `onSessionReady(session)` | `session.book.metadata.title/author` |
| `onMaxPageReached` | — | 제거 ⚠️ |
| `showTopBar` / `showBottomBar` | — | 제거 (chrome은 호스트) |
| `topBarBuilder` / `bottomBarBuilder` | — | 제거 |
| `title` | — | 제거 (`session.book.metadata.title` 활용) |
| `watermark` | — | 제거 ⚠️ (호스트가 `Stack`으로 오버레이) |
| `maxReadablePages` | — | 제거 ⚠️ |
| `settingsStorageKey` (자동 저장) | — | 제거 (자동 영속화 없음) |
| `localization` | — | 제거 |
| `progressBarColor` | `showProgressIndicator` (bool) | 색상 커스터마이즈 제거, 테마색 사용 ⚠️ |
| — | `initialPosition` (`EpubPosition`) | 🆕 위치 복원 |
| — | `options` (`EpubSessionOptions`) | 🆕 보안·throttle |
| — | `highlights`, `onLinkTap`, `paged`, `onPositionChanged`, `onViewportChanged`, `readingDirection`, `verticalWriting`, `fixedLayout*`, `mediaOverlayController` | 🆕 |

**Before (0.x)** — 완성형 리더:

```dart
import 'package:open_epub/open_epub.dart';

class ReaderPage extends StatefulWidget {
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _controller = EpubReaderController(
    onBookmarkAdded: (b) => db.saveBookmark(b.toJson()),
  );

  @override
  Widget build(BuildContext context) {
    return EpubReaderWidget(
      source: const EpubSourceAsset('assets/book.epub'),
      controller: _controller,
      settingsStorageKey: 'epub_reader_settings', // 자동 저장
      localization: EpubReaderLocalization.english,
      showTopBar: true,
      topBarBuilder: (context, settings) => AppBar(
        backgroundColor: settings.backgroundColor,
        title: const Text('My Reader'),
      ),
      onBookLoaded: (title, author) => print('Loaded $title / $author'),
      onPageChanged: (cur, total) => print('page $cur / $total'),
    );
  }
}
```

**After (1.0)** — 호스트가 chrome/설정을 소유:

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_epub/open_epub.dart';

class ReaderPage extends StatefulWidget {
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _controller = EpubViewController();
  Future<EpubSource>? _source;

  // 폰트·줄간격은 호스트가 상태로 관리(원한다면 자체 저장/복원).
  double _fontSize = 16;
  double _lineHeight = 1.5;

  @override
  void initState() {
    super.initState();
    // asset은 rootBundle로 바이트를 읽어 EpubSource.bytes로 넘긴다 (§3).
    _source = rootBundle
        .load('assets/book.epub')
        .then((d) => EpubSource.bytes(d.buffer.asUint8List()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 바 등 chrome은 호스트가 직접 그린다.
      appBar: AppBar(title: const Text('My Reader')),
      body: FutureBuilder<EpubSource>(
        future: _source,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return EpubReader(
            source: snap.data!,
            controller: _controller,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
            onSessionReady: (session) {
              final m = session.book.metadata;
              print('Loaded ${m.title} / ${m.author}');
            },
            onPageChanged: (spineIndex, spineCount) =>
                print('spine $spineIndex / $spineCount'),
            onPositionChanged: (pos) => db.saveProgress(pos.toToken()),
          );
        },
      ),
    );
  }
}
```

> ⚠️ 확인 필요 — **동적 source 교체**: 0.x는 `EpubReaderWidget.source` prop을
> 바꾸면 `didUpdateWidget`으로 자동 재로드했다. 1.0 `EpubReader`는 현재
> `source` prop 변경을 `didUpdateWidget`에서 처리하지 않는다(초기 `source`로만
> 세션을 연다). 따라서 책을 바꾸려면 **(a)** `EpubReader`에
> `key: ValueKey(source)`를 주어 위젯을 재생성하거나, **(b)** `onSessionReady`로
> 세션을 받아 `session.swapSource(newSource)`를 직접 호출한다(위치 보존
> hot-swap). 어느 쪽을 표준으로 안내할지는 리더 팀 확인이 필요하다.

### 2. 컨트롤러: `EpubReaderController` → `EpubViewController`

내비게이션 핸들만 남고, 설정·북마크·진도 상태는 전부 빠졌다.

| 0.x 멤버 | 1.0 대응 | 상태 |
| --- | --- | --- |
| `nextPage()` / `previousPage()` | `nextPage()` / `previousPage()` | 유지 (반환 `void`→`Future<void>`) |
| `goToPage(int pageIndex)` | `goToSpine(int index)` | ⚠️ 절대 page → spine(챕터) 인덱스 |
| `goToProgress(double)` | — | 제거 ⚠️ |
| `goToBookmark(Bookmark)` | — | 제거 (`goToSpine`/`session.jumpTo`) |
| `currentPage` | `currentSpineIndex` | ⚠️ page→spine |
| `totalPages` | `spineCount` | ⚠️ page→spine |
| `progress` | — | 제거 (`session.progress` / `onPositionChanged`) |
| `currentPosition` (`ReadingPosition`) | `session.position` (`EpubPosition`) | 치환 (§4) |
| `currentSettings` / `updateSettings()` / `showSettings()` | — | 제거 |
| `bookmarks` / `addBookmark()` / `removeBookmark()` / `toggleBookmark()` / `isCurrentPageBookmarked` / `isPageBookmarked()` / `getBookmarkForPage()` | — | 제거 (§6) |
| `isLoading` / `error` | — | 제거 (`EpubReader` 내부 처리) |
| ctor 콜백 `onPositionChanged` | `EpubReader.onPositionChanged` | 위젯으로 이동 |
| ctor 콜백 `onSettingsChanged` / `onBookmarkAdded` / `onBookmarkRemoved` | — | 제거 |
| ctor `initialProgress` (`double`) | `EpubReader.initialPosition` (`EpubPosition`) | ⚠️ double→토큰 |
| ctor `initialSettings` / `initialBookmarks` | — | 제거 |
| — | `hasNext` / `hasPrevious` | 🆕 |
| — | `windowIndex` / `windowCount` | 🆕 (paged 화면 단위 윈도잉) |
| — | `goToSpine()` / `syncState()` | 🆕 |

**Before (0.x)**:

```dart
final controller = EpubReaderController(
  initialProgress: 0.5,
  initialBookmarks: savedBookmarks,
  onPositionChanged: (pos) => db.saveProgress(pos.progress),
  onBookmarkAdded: (b) => db.saveBookmark(b.toJson()),
);

// 외부 버튼 배선
IconButton(onPressed: controller.previousPage, icon: ...);
IconButton(onPressed: controller.nextPage, icon: ...);
Text('${controller.currentPage + 1} / ${controller.totalPages}');
controller.goToProgress(0.25);
controller.addBookmark();
```

**After (1.0)**:

```dart
final controller = EpubViewController();

// 위치 복원은 위젯 파라미터로, 콜백도 위젯으로.
EpubReader(
  source: source,
  controller: controller,
  initialPosition: savedToken == null ? null : EpubPosition.fromToken(savedToken),
  onPositionChanged: (pos) => db.saveProgress(pos.toToken()),
);

// 외부 버튼 배선 — hasNext/hasPrevious로 활성/비활성.
AnimatedBuilder(
  animation: controller,
  builder: (_, __) => Row(children: [
    IconButton(
      onPressed: controller.hasPrevious ? controller.previousPage : null,
      icon: const Icon(Icons.chevron_left),
    ),
    Text('${controller.currentSpineIndex + 1} / ${controller.spineCount}'),
    IconButton(
      onPressed: controller.hasNext ? controller.nextPage : null,
      icon: const Icon(Icons.chevron_right),
    ),
  ]),
);

// 챕터(목차) 점프
controller.goToSpine(3);
```

> ⚠️ 확인 필요 — **`goToProgress`/`goToPage` 등가물 없음**: 1.0 내비게이션은
> **spine(챕터)·window(화면) 단위**이지 0.x의 "절대 페이지 번호"나 "임의 진행률
> 0.0~1.0 점프"가 아니다. `goToProgress(0.5)`처럼 챕터 중간 임의 지점으로
> 점프하려면 별도 계산이 필요하고, 표준 API가 없다. 정확한 charOffset 위치로
> 가려면 `session.jumpTo(EpubReflowablePosition(spineHref: ..., progress: ...,
> charOffset: ...))`를 쓴다. 진행률→위치 역산 방식은 리더 팀 확인이 필요하다.

### 3. 소스: `EpubSource*` → `EpubSource.*` factory

**Before (0.x)**:

```dart
EpubSourceAsset('assets/books/sample.epub');
EpubSourceFile('/path/to/book.epub');
EpubSourceUrl('https://example.com/book.epub', headers: {'Authorization': 'Bearer x'});
EpubSourceBytes(bytes);
```

**After (1.0)**:

```dart
// asset: 전용 소스가 없어졌다 — rootBundle로 읽어 bytes로.
final data = await rootBundle.load('assets/books/sample.epub');
EpubSource.bytes(data.buffer.asUint8List());

EpubSource.file('/path/to/book.epub');

// ⚠️ url은 String이 아니라 Uri.
EpubSource.url(Uri.parse('https://example.com/book.epub'),
    headers: {'Authorization': 'Bearer x'});

EpubSource.bytes(bytes);
```

> ⚠️ 확인 필요 — **`EpubSourceAsset` 제거**: 1.0 `EpubSource`에는 asset factory가
> 없다(`bytes`/`file`/`url` 3종). asset EPUB은 `rootBundle.load(...)`로 바이트를
> 읽어 `EpubSource.bytes`에 넘기는 것이 위 예제의 패턴이나, "1.0이 asset 편의
> 생성자를 의도적으로 제외한 것"인지 리더 팀 확인이 필요하다.

### 4. 위치: `ReadingPosition` → `EpubPosition`

모델이 다르다. 0.x `ReadingPosition`은 `pageIndex`/`totalPages`/`progress`
기반(페이지네이션 종속)이고, 1.0 `EpubPosition`은 `spineHref`+`charOffset`
기반(재페이지네이션에도 보존되는 canonical 토큰, [ADR-001](#근거--출처)).

| 0.x (`ReadingPosition`) | 1.0 (`EpubPosition`) |
| --- | --- |
| `pageIndex`, `totalPages`, `progress`, `updatedAt` | `spineHref`, `progress`, (+`charOffset` reflowable / `pageIndex` fixed) |
| `toJson()` / `ReadingPosition.fromJson(map)` | `toToken()` / `EpubPosition.fromToken(string)` |
| 단일 클래스 | sealed: `EpubReflowablePosition` / `EpubFixedPosition` |

**Before (0.x)**:

```dart
onPositionChanged: (ReadingPosition pos) {
  db.save(jsonEncode(pos.toJson()));   // {pageIndex,totalPages,progress,updatedAt}
}
// 복원
final pos = ReadingPosition.fromJson(jsonDecode(saved));
```

**After (1.0)**:

```dart
onPositionChanged: (EpubPosition pos) {
  db.save(pos.toToken());              // JSON 토큰 문자열(≤512B)
}
// 복원 — EpubReader.initialPosition으로 전달
final pos = EpubPosition.fromToken(saved); // 실패 시 EpubPositionDecodeException
EpubReader(source: source, initialPosition: pos);
```

> 참고: `toToken()`은 512바이트 초과 시 `EpubPositionTooLargeException`,
> `fromToken()`은 손상/버전불일치 시 `EpubPositionDecodeException`을 던진다.
> 저장/복원 코드에서 예외 처리를 추가하라.

### 5. 로딩/에러: `EpubLoader`/`EpubLoadException` → 세션 + `EpubFailure`

0.x는 `EpubLoader.load(source)`로 바이트를 직접 얻고 실패 시 단일
`EpubLoadException`을 던졌다. 1.0은 로딩이 `EpubBookSession.open()`(내부
`EpubRepository`) 안으로 들어갔고, 실패는 **sealed `EpubFailure` 계층**으로
세분화된다.

| 0.x | 1.0 |
| --- | --- |
| `EpubLoader.load(source) → Uint8List` | (세션 내부) `EpubBookSession.open(source)` |
| `EpubLoadException` (단일) | `EpubFailure`: `EpubInvalidFile` · `EpubFileTooLarge` · `EpubNetworkFailure` · `EpubCorrupted` · `EpubUnknown` |

**Before (0.x)**:

```dart
try {
  final bytes = await EpubLoader.load(source);
} on EpubLoadException catch (e) {
  showError(e.message);
}
```

**After (1.0)** — 세션을 직접 열 때 typed 분기:

```dart
try {
  final session = await EpubBookSession.open(source);
  // ... use session
} on EpubFileTooLarge {
  showError('파일이 너무 큽니다');
} on EpubNetworkFailure {
  showError('네트워크 오류');
} on EpubCorrupted {
  showError('손상된 EPUB');
} on EpubFailure catch (e) {
  showError('열기 실패: $e');
}
```

> ⚠️ 확인 필요 — **`EpubReader` 사용 시 에러 콜백 부재**: `EpubReader`는 세션
> 열기 실패를 **내부 에러뷰**(`파일이 너무 커서...` 등 한국어 고정 문구)로
> 표시하며, 0.x의 `onError(String)` 같은 콜백 파라미터가 없다. 에러를 호스트가
> 직접 처리(로깅·재시도·커스텀 UI)하려면 `EpubReader`에 위임하지 말고 위처럼
> `EpubBookSession.open()`을 직접 호출해 세션을 관리해야 한다. `EpubReader`에
> 에러 콜백을 추가할지는 리더 팀 확인이 필요하다.

### 6. 제거된 기능 (호스트 재구현)

1.0에 **대응 심볼이 없고** 호스트 책임으로 넘어간 기능들. 각각 재구현 지침만
제시한다(1.0 내장 API 없음).

#### (a) 설정 UI + 자동 저장 — `ReaderSettings`/`ColorTheme`/`colorThemes`/`SettingsPanel`/`settingsStorageKey`

- 1.0 `EpubReader`는 `fontSize`(px)·`lineHeight`(배수)만 받는다. 테마 색·폰트
  패밀리·여백·페이지/스크롤 모드 등은 위젯이 관리하지 않는다.
- **재구현**: 호스트가 설정 모델·설정 패널·영속화(SharedPreferences 등)를 직접
  두고, 값을 `EpubReader(fontSize:, lineHeight:, paged:, ...)` 및 감싸는
  컨테이너 색으로 반영한다.
- ⚠️ 확인 필요: 0.x `ReaderSettings.fontSize`(1~9 정수 → 12~28px)와 1.0
  `fontSize`(직접 px)는 스케일이 다르다. 저장된 0.x 설정을 1.0으로 이관하려면
  `actualFontSize = 10 + fontSize*2` 공식으로 px 변환이 필요하다(마이그레이션
  코드에서 처리).

#### (b) 북마크 — `Bookmark` + 컨트롤러 북마크 메서드

- 1.0에는 북마크 저장/관리 API가 없다. `session.recordBookmark()`는 **분석
  이벤트(toolUse)만** 발사할 뿐 북마크를 저장하지 않는다.
- **재구현**: 호스트가 자체 북마크 모델을 두고, 현재 위치를
  `session.position.toToken()`(또는 `EpubReader.onPositionChanged`의
  `pos.toToken()`)으로 저장한다. 복원은 `EpubPosition.fromToken` +
  `session.jumpTo`/`controller.goToSpine`.
- ⚠️ 확인 필요: 0.x `Bookmark`(pageIndex/progress/title/excerpt/createdAt)를
  1.0으로 이관하려면 pageIndex 기반 앵커를 `EpubPosition` 토큰으로 재매핑해야
  하는데, 페이지 인덱스↔spine/charOffset 변환은 자명하지 않다. 이관 전략은
  리더 팀 확인이 필요하다.

#### (c) 다국어 — `EpubReaderLocalization`

- 0.x는 내장 설정 패널·에러 문구를 위해 11개 언어 프리셋을 제공했다. 1.0은
  그 내장 UI 자체가 없어졌으므로 로컬라이즈 대상도 사라졌다.
- **재구현**: 호스트 UI 문자열은 호스트의 l10n(intl/flutter_localizations 등)으로
  처리. (`EpubReader` 내부 에러뷰 문구는 현재 한국어 고정 — ⚠️ 위 §5 참고.)

#### (d) 미리보기 페이지 제한 — `maxReadablePages`/`onMaxPageReached`

- 1.0 `EpubReader`에 페이지 제한 파라미터/콜백이 없다.
- **재구현**: 호스트가 `onPageChanged`/`controller.currentSpineIndex`를 관찰해
  한도 도달 시 내비게이션 버튼을 비활성화하거나 결제 안내를 띄운다.
- ⚠️ 확인 필요: 0.x는 "페이지" 단위 제한이었으나 1.0은 spine/window 단위라
  동일한 "N페이지까지만" 시맨틱을 그대로 재현하기 어렵다. 대체 정책 확인 필요.

#### (e) 상단/하단 바·워터마크·제목 — chrome 파라미터

- `showTopBar`/`showBottomBar`/`topBarBuilder`/`bottomBarBuilder`/`title`/
  `watermark`/`progressBarColor` 모두 제거.
- **재구현**: `EpubReader`를 `Scaffold`(appBar/bottomNavigationBar)와 `Stack`
  (워터마크 오버레이) 안에 감싼다. 제목은 `session.book.metadata.title`.

---

## ⚠️ 불확실 / 미검증 항목 모음

리뷰어가 개별 검토해야 할, 이 문서가 **추측 없이 정직하게 남긴** 항목:

1. **`open_epub_engine` 발행 버전/의존 제약** — `^1.0.0` 등 표기는 예시. 실제
   발행 pubspec에서 확정.
2. **동적 source 교체** — `EpubReader`는 `source` prop 변경을 자동 재로드하지
   않는다(코드상 `didUpdateWidget` 미처리 확인). `ValueKey` 재생성 vs
   `session.swapSource` 중 표준 안내 방식 미확정.
3. **`goToProgress`/`goToPage`(절대 페이지) 등가물 없음** — 1.0은 spine/window
   단위 내비게이션. 임의 진행률/절대 페이지 점프 표준 API 부재.
4. **`EpubSourceAsset` 제거 의도** — asset 편의 생성자가 의도적으로 빠진
   것인지, `rootBundle`+`bytes` 우회가 공식 권장인지 확인 필요.
5. **`EpubReader`의 `onError` 부재** — 에러를 호스트가 받으려면 세션 직접 관리
   필요. 위젯에 에러 콜백 추가 여부 미확정.
6. **`onLoadingProgress` 등가물 없음** — 1.0은 내부
   `CircularProgressIndicator`만. 로딩 진행률 노출 API 부재.
7. **내부 에러뷰 문구 한국어 고정** — `EpubReader`의 `_OpenErrorView` 문구가
   하드코딩 한국어. 다국어 앱에서 문제 가능(로컬라이즈 훅 없음).
8. **0.x→1.0 데이터 이관 변환** — 저장된 `ReaderSettings`(fontSize 1~9),
   `Bookmark`(pageIndex), `ReadingPosition`(pageIndex/totalPages)을 1.0 모델로
   옮기는 변환 로직은 이 문서 범위 밖(호스트 마이그레이션 코드 필요).
9. **`progressBarColor` → `showProgressIndicator`** — 색상 커스터마이즈가
   테마색 고정으로 축소. 색 지정이 필요하면 대체 수단 없음.
10. **0.x API 재구성 근거** — git 태그가 없어 0.1.3 표면은 초기 커밋
    `a39fb5a`(pubspec `version: 0.1.3` 확인)의 `lib/`에서 재구성했다. pub.dev의
    open_epub 0.1.3 페이지와의 교차 대조는 수행하지 않았다(네트워크 미확인).

---

## 근거 / 출처

- **0.x(0.1.3) 공개 API**: 초기 커밋 `a39fb5a`의 `lib/open_epub.dart` 배럴 및
  `lib/src/**`. 해당 커밋 `pubspec.yaml`의 `version: 0.1.3`로 버전 확정. 레거시
  배럴은 초기 커밋부터 S11.1(#88) 제거 직전까지 export 목록이 동일함을 확인.
  `CHANGELOG.md`의 0.0.2~0.1.3 이력으로 교차 확인.
- **1.0 공개 API**: 현재 [`lib/open_epub.dart`](lib/open_epub.dart) 배럴 +
  [`open_epub_engine`](../open_epub_engine/lib/open_epub_engine.dart) 배럴,
  `EpubReader`/`EpubViewController`/`EpubBookSession`/`EpubSource`/
  `EpubPosition` 소스, [`README.md`](README.md), `example/lib/v1_demo_page.dart`.
- **ADR-002 / ADR-002-a**: 위젯 결합도 해소 + source 추상화(1.0 breaking 재설계),
  순수-Dart 엔진 `open_epub_engine` 별도 발행.
- **ADR-001**: BookPosition v1 canonical 토큰(CFI 미채택, JSON ≤512B).
- **ADR-010**: CFI 보충 매퍼(콘텐츠 교체 시 재앵커, 외부 CFI interop).
