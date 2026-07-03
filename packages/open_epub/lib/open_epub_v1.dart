// open_epub 1.0 public API entry.
//
// 레거시 0.1.x API(`package:open_epub/open_epub.dart`)와 이름이 겹치는 타입
// (`EpubSource` 등)이 있어 1.0 코어는 별도 entry로 노출한다. 한 파일에서 두
// entry를 동시에 import하면 충돌하므로 둘 중 하나만 사용한다.
//
// 핵심 흐름:
//   final session = await EpubBookSession.open(EpubSource.bytes(bytes));
//   session.book / session.position / session.lifecycleEvents ...
// 또는 위젯으로:
//   EpubReader(source: EpubSource.bytes(bytes))

// 세션 + 옵션
export 'src/api/epub_book_session.dart'
    show EpubBookSession, EpubSessionOptions;

// 1.0 reader 페이지 내비게이션 컨트롤러 (S8.1)
export 'src/api/epub_reader_controller.dart' show EpubViewController;

// 책 모델 + 도메인 엔티티
export 'src/api/epub_book.dart' show EpubBook;
export 'src/domain/entity/epub_metadata.dart'
    show EpubMetadata, EpubLayout, EpubSpread;
export 'src/domain/entity/epub_outline.dart' show EpubOutline, EpubOutlineItem;
export 'src/domain/entity/epub_spine_item.dart' show EpubSpineItem;
export 'src/domain/entity/epub_resource.dart'
    show EpubResource, EpubResourceReader;

// 선택 + 하이라이트 (E1.5)
export 'src/domain/entity/epub_selection.dart' show EpubSelection;
export 'src/domain/entity/epub_highlight.dart' show EpubHighlight;
export 'src/data/text/spine_text_extractor.dart' show SpineTextExtractor;

// Reader interop primitives (E7)
export 'src/data/text/search_highlighter.dart' show SearchHighlighter;
export 'src/presentation/interop/epub_selection_toolbar.dart'
    show EpubSelectionAction, epubSelectionButtonItems;

// 소스
export 'src/api/epub_source.dart' show EpubSource;

// 위치 (BookPosition v1)
export 'src/api/epub_position.dart'
    show
        EpubPosition,
        EpubReflowablePosition,
        EpubFixedPosition,
        EpubPositionTooLargeException,
        EpubPositionDecodeException;

// 분석 이벤트
export 'src/api/epub_analytics.dart'
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
export 'src/api/epub_security_config.dart' show EpubSecurityConfig;

// 실패 계층
export 'src/domain/entity/epub_failure.dart'
    show
        EpubFailure,
        EpubInvalidFile,
        EpubFileTooLarge,
        EpubNetworkFailure,
        EpubCorrupted,
        EpubUnknown;

// 보정 진단
export 'src/data/compat/patch_catalog.dart'
    show BookSessionDiagnostics, AppliedPatch, UnresolvedIssue, PatchSeverity;

// 검색
export 'src/domain/usecase/build_search_index_use_case.dart'
    show BuildSearchIndexUseCase, BookSearchIndex, BookSearchHit;

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
