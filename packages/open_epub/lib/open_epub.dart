// open_epub 1.0 public API entry.
//
// S11.1(#88): 레거시 0.1.x API(EpubReaderWidget 등)와 레거시 배럴을 제거하고,
// 1.0 코어를 이 파일(`package:open_epub/open_epub.dart`)로 승격했다. 이제
// 진입점은 하나뿐이라 이름 충돌 회피용 별도 entry가 필요없다.
//
// S10.3(#80): 순수-Dart 코어(파서·모델·코덱·도메인)는 open_epub_engine으로
// 추출됐다. 아래 이동 타입들은 엔진 배럴에서 재-export하며, 공개 표면(show 목록)은
// 이동 전과 동일하게 유지한다. Flutter 렌더/위젯/컨트롤러만 open_epub에 잔류한다.
//
// 핵심 흐름:
//   final session = await EpubBookSession.open(EpubSource.bytes(bytes));
//   session.book / session.position / session.lifecycleEvents ...
// 또는 위젯으로:
//   EpubReader(source: EpubSource.bytes(bytes))

// ── open_epub_engine 재-export (S10.3 이동 레이어) ─────────────────────────

// 세션 + 옵션
export 'package:open_epub_engine/open_epub_engine.dart'
    show EpubBookSession, EpubSessionOptions;

// 책 모델 + 도메인 엔티티
export 'package:open_epub_engine/open_epub_engine.dart' show EpubBook;
export 'package:open_epub_engine/open_epub_engine.dart'
    show EpubMetadata, EpubLayout, EpubSpread;
// 읽기 능력 신호 — RTL 페이지 방향 토글(S14.1)·MO 존재 확인 등.
export 'package:open_epub_engine/open_epub_engine.dart'
    show BookCapabilities, EpubPageProgression, EpubWritingMode;
// Media Overlays(SMIL) — session.loadMediaOverlay 반환 타입 (S15.1).
export 'package:open_epub_engine/open_epub_engine.dart'
    show EpubMediaOverlay, EpubMediaPar;
export 'package:open_epub_engine/open_epub_engine.dart'
    show EpubOutline, EpubOutlineItem;
export 'package:open_epub_engine/open_epub_engine.dart' show EpubSpineItem;
export 'package:open_epub_engine/open_epub_engine.dart'
    show EpubResource, EpubResourceReader;

// 선택 + 하이라이트 (E1.5)
export 'package:open_epub_engine/open_epub_engine.dart' show EpubSelection;
export 'package:open_epub_engine/open_epub_engine.dart' show EpubHighlight;
export 'package:open_epub_engine/open_epub_engine.dart' show SpineTextExtractor;

// Reader interop primitive — 엔진측 (E7)
export 'package:open_epub_engine/open_epub_engine.dart' show SearchHighlighter;

// 소스
export 'package:open_epub_engine/open_epub_engine.dart' show EpubSource;

// 위치 (BookPosition v1)
export 'package:open_epub_engine/open_epub_engine.dart'
    show
        EpubPosition,
        EpubReflowablePosition,
        EpubFixedPosition,
        EpubPositionTooLargeException,
        EpubPositionDecodeException;

// CFI 매퍼 + interop (S12, ADR-010) — 콘텐츠 교체 시 하이라이트/북마크 재앵커,
// 외부 CFI export/import. 위치 export/import는 EpubBookSession에도 있다.
export 'package:open_epub_engine/open_epub_engine.dart'
    show EpubCfiMapper, BookCfiParts;

// 분석 이벤트
export 'package:open_epub_engine/open_epub_engine.dart'
    show
        EpubBookSessionAnalytics,
        EpubLifecycleEvent,
        EpubSessionStarted,
        EpubSessionEnded,
        EpubProgressEvent,
        EpubToolUseEvent,
        EpubHighlightToolUse,
        EpubBookmarkToolUse;

// 보안
export 'package:open_epub_engine/open_epub_engine.dart' show EpubSecurityConfig;

// 실패 계층
export 'package:open_epub_engine/open_epub_engine.dart'
    show
        EpubFailure,
        EpubInvalidFile,
        EpubFileTooLarge,
        EpubNetworkFailure,
        EpubCorrupted,
        EpubUnknown;

// 보정 진단
export 'package:open_epub_engine/open_epub_engine.dart'
    show BookSessionDiagnostics, AppliedPatch, UnresolvedIssue, PatchSeverity;

// 검색
export 'package:open_epub_engine/open_epub_engine.dart'
    show BuildSearchIndexUseCase, BookSearchIndex, BookSearchHit;

// ── open_epub 잔류 (Flutter 렌더/위젯/컨트롤러/interop) ─────────────────────

// 1.0 reader 페이지 내비게이션 컨트롤러 (S8.1)
export 'src/api/epub_reader_controller.dart' show EpubViewController;

// Media Overlays 재생 (S15.2) — 추상 플레이어 + 기본 구현 + 재생 컨트롤러.
export 'src/presentation/media_overlay/media_audio_player.dart'
    show MediaAudioPlayer;
export 'src/presentation/media_overlay/just_audio_media_player.dart'
    show JustAudioMediaPlayer;
export 'src/presentation/media_overlay/media_overlay_controller.dart'
    show MediaOverlayController, MediaOverlayState, MediaOverlayAudioLoader;

// Reader interop primitive — Flutter측 (E7)
export 'src/presentation/interop/epub_selection_toolbar.dart'
    show EpubSelectionAction, epubSelectionButtonItems;

// 위젯 + 엔진
export 'src/presentation/widgets/epub_reader.dart'
    show
        EpubReader,
        EpubSessionReadyCallback,
        EpubPageChangedCallback,
        EpubPositionChangedCallback,
        EpubViewportChangedCallback;
export 'src/presentation/engine/reflowable/reflowable_engine.dart'
    show
        ReflowableEngine,
        XhtmlLoader,
        ImageLoader,
        EpubLinkTapCallback,
        SpineChangedCallback;
export 'src/presentation/engine/reflowable/reflowable_page_view.dart'
    show ReflowablePageView;
// 세로쓰기 실용 조판 위젯 (S15.4) — 호스트가 직접 세로 텍스트를 렌더할 때.
export 'src/presentation/engine/reflowable/vertical_text_block.dart'
    show VerticalTextBlock;
export 'src/presentation/engine/fixed_layout/fixed_layout_engine.dart'
    show
        FixedLayoutEngine,
        FixedLayoutPageData,
        FixedLayoutPageBuilder,
        FixedLayoutContentBuilder;
export 'src/presentation/engine/fixed_layout/fixed_layout_page.dart'
    show FixedLayoutPage;
export 'src/presentation/engine/fixed_layout/viewport_fitter.dart'
    show ViewportFitter;
