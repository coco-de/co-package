// Public API — open_epub 1.0
// Story: S1.21 (#37) — EpubBookSession.open() lifecycle + position + analytics
// Story: S1.22 (#38) — swapSource() 위치 보존 hot-swap
// BDD: F1 (책 열기), F1.2/F1.3 (위치 복원/fallback), F10 (hot-swap), F11 (analytics)

import 'dart:async';

import 'package:collection/collection.dart';

import '../cfi/epub_cfi_mapper.dart';
import '../data/compat/patch_catalog.dart'
    show BookSessionDiagnostics, BookSessionDiagnosticsData, UnresolvedIssue;
import '../data/parser/smil_parser.dart';
import '../data/repository/archive_resource_reader.dart' show resolveHref;
import '../data/repository/epub_repository_impl.dart';
import '../data/security/html_sanitizer.dart';
import '../data/text/spine_text_extractor.dart';
import '../domain/entity/epub_capabilities.dart';
import '../domain/entity/epub_highlight.dart';
import '../domain/entity/epub_media_overlay.dart';
import '../domain/entity/epub_navigation.dart';
import '../domain/entity/epub_outline.dart';
import '../domain/entity/epub_rendition.dart';
import '../domain/entity/epub_resource.dart';
import '../domain/entity/epub_selection.dart';
import '../domain/usecase/build_search_index_use_case.dart';
import '../domain/usecase/open_epub_use_case.dart';
import '../domain/usecase/resolve_position_use_case.dart';
import 'epub_analytics.dart';
import 'epub_book.dart';
import 'epub_position.dart';
import 'epub_security_config.dart';
import 'epub_source.dart';

/// EPUB 책 런타임 세션. open/jumpTo/page navigation/hot-swap/dispose 책임.
///
/// [open]은 [EpubSource]로부터 책을 조립하고(파싱 + 호환성 보정), 저장된
/// [initialPosition]을 복원하며(실패 시 첫 페이지로 fallback), lifecycle 분석
/// 이벤트([EpubSessionStarted])를 발사한다.
abstract class EpubBookSession implements EpubBookSessionAnalytics {
  static Future<EpubBookSession> open(
    EpubSource source, {
    EpubPosition? initialPosition,
    EpubSessionOptions options = const EpubSessionOptions(),
  }) {
    return _EpubBookSessionImpl.open(source, initialPosition, options);
  }

  /// 조립·보정 완료된 책.
  EpubBook get book;

  /// 적용된 보정 + 미해결 이슈(예: position-restore-failed) 진단.
  BookSessionDiagnostics get diagnostics;

  /// 책 내부 리소스 reader (OPF 기준 상대 href — 이미지/CSS 등).
  EpubResourceReader get resources;

  /// [spineHref]의 본문 XHTML을 읽어 보안 sanitize(script/iframe 차단) 후
  /// 반환한다. 해당 리소스가 없으면 null.
  String? readSpineXhtml(String spineHref);

  /// [spineHref] 본문을 sanitize한 뒤 [highlights]를 배경색으로 주입해
  /// 반환한다. 코어 하이라이트 렌더 경로(데모의 host-측 DOM 주입 대체).
  /// 다른 spine의 하이라이트는 무시한다. 리소스가 없으면 null. (S1.5-4)
  ///
  /// [tappable]이 true면 하이라이트를 탭 가능한 링크로 감싸 엔진 `onLinkTap`
  /// → [SpineTextExtractor.highlightIdFromHref]로 식별할 수 있다. (S7.3)
  String? readSpineXhtmlWithHighlights(
    String spineHref,
    Iterable<EpubHighlight> highlights, {
    bool tappable = false,
  });

  /// 본문 링크 href를 책 내부 점프 위치로 변환한다. (S7.5)
  ///
  /// `ch2.xhtml`·`ch2.xhtml#frag` 같은 책 내부 상대 경로는 해당 spine의
  /// [EpubReflowablePosition]으로, 외부 URL(http/https/mailto 등)이나 알 수
  /// 없는 대상은 null로 반환한다(호스트가 외부 처리). fragment는 현재 무시.
  EpubPosition? resolveLink(String href, {String? fromSpineHref});

  /// 책 목차(설계 §4.3 — 세션 레벨 노출). (S1.5-8)
  EpubOutline get outline;

  /// toc 외 보조 내비게이션 — landmarks(주요 위치 바로가기) / page-list(인쇄
  /// 페이지 번호). EPUB 2 또는 부재 시 [EpubNavigation.empty]. (S13.1, gap #2)
  EpubNavigation get navigation;

  /// 책의 읽기전용 능력 신호 — 진행 방향(PPD)·writingMode·미디어오버레이 존재.
  /// 호스트가 RTL/MO를 파싱 없이 확인한다. (S13.3, gap #3, 아키텍처 §4.4)
  BookCapabilities get capabilities;

  /// [spineHref] 문서에 연결된 Media Overlay(.smil)를 온디맨드로 읽어 파싱한다.
  /// spine item의 `mediaOverlayHref`(manifest `media-overlay` 해석)로 SMIL을
  /// 찾아 [SmilParser]로 파싱하고, 각 par의 `textSrc`/`audioSrc`를 OPF 기준 상대
  /// 경로로 정규화해(리소스 reader가 바로 소비 가능) 반환한다. MO가 없거나 리소스
  /// 부재/파싱 실패면 [EpubMediaOverlay.empty]. (S15.1, gap #6 배선분)
  Future<EpubMediaOverlay> loadMediaOverlay(String spineHref);

  /// container.xml의 모든 rendition(복수 rootfile). 기본 rendition만 현재 세션에
  /// 열려 있으며, 호스트는 다른 rendition을 골라 새 세션을 열 수 있다. 단일
  /// rendition이면 항목 1개(default). (S13.4, gap #7)
  List<EpubRendition> get renditions;

  /// 현재 선택 영역 stream. 호스트(UI)가 [reportSelection]로 push한다.
  /// 선택 해제 시 null. (S1.5-2, 설계 §4.3)
  Stream<EpubSelection?> get selectionStream;

  /// 시각 선택 변경을 코어로 전달한다 → [selectionStream]에 발사. (S1.5-2)
  void reportSelection(EpubSelection? selection);

  /// [spineHref] 본문에서 [selectedText]를 찾아 [EpubSelection]으로 변환한다.
  /// 일치하지 않으면 null. [occurrence]로 N번째 일치 선택. (S1.5-3)
  EpubSelection? resolveSelection(
    String spineHref,
    String selectedText, {
    int occurrence = 0,
  });

  /// 전체 spine 본문을 추출해 검색 인덱스를 빌드한다. (S1.5-5/8)
  Future<BookSearchIndex> buildSearchIndex();

  /// 검색 결과 1건을 점프 가능한 [EpubReflowablePosition]으로 변환한다. (S1.5-6)
  EpubReflowablePosition positionForHit(BookSearchHit hit);

  /// 현재 읽기 위치.
  EpubPosition get position;

  /// 현재 진도(0.0~1.0). [position]의 progress를 위임.
  double get progress;

  Future<void> jumpTo(EpubPosition position);
  Future<void> nextPage();
  Future<void> previousPage();

  /// reflowable [position]을 외부 상호운용용 표준 CFI 문자열로 내보낸다(export).
  /// `epubcfi(/6/N[idref]!/docpath:offset)` 형식. FXL/미해석 위치는 null.
  /// canonical 토큰과 별개인 additive interop API다(토큰 스키마 무변경). (S12.4)
  String? exportPositionCfi(EpubReflowablePosition position);

  /// 표준 CFI 문자열을 이 책의 reflowable 위치로 가져온다(import). spine step으로
  /// spineHref를, 문서-내 경로로 charOffset을 해석한다. 해석 실패 시 null. (S12.4)
  EpubReflowablePosition? importPositionCfi(String bookCfi);

  /// 현재 위치에서 하이라이트 도구 사용 이벤트를 발사한다(분석용, F11).
  void recordHighlight();

  /// 현재 위치에서 북마크 도구 사용 이벤트를 발사한다(분석용, F11).
  void recordBookmark();

  /// 현재 위치를 최대한 보존하며 [newSource]로 책을 교체한다(hot-swap).
  /// 같은 spineHref가 새 책에 있으면 위치를 그대로 복원하고, 없으면 첫
  /// 페이지로 fallback하며 진단에 기록한다. (BDD F10)
  Future<void> swapSource(EpubSource newSource);

  Future<void> dispose();
}

class EpubSessionOptions {
  const EpubSessionOptions({
    this.security = const EpubSecurityConfig(),
    this.progressThrottle = const Duration(seconds: 30),
  });

  /// 책 열기 시 적용할 보안 가드(크기 제한 등).
  final EpubSecurityConfig security;

  /// progressEvents 발사 최소 간격(BDD F11 — 기본 30초마다 1회).
  final Duration progressThrottle;
}

/// 책 1권을 조립·복원한 결과(open/swap 공통). 세션 내부 상태의 스냅샷.
class _SessionState {
  _SessionState({
    required this.book,
    required this.diagnostics,
    required this.position,
    required this.navHrefs,
    required this.resources,
    this.navigation = EpubNavigation.empty,
    this.capabilities = BookCapabilities.defaults,
    this.renditions = const [],
  });

  final EpubBook book;
  final BookSessionDiagnostics diagnostics;
  final EpubPosition position;
  final List<String> navHrefs;
  final EpubResourceReader resources;
  final EpubNavigation navigation;
  final BookCapabilities capabilities;
  final List<EpubRendition> renditions;
}

class _EpubBookSessionImpl implements EpubBookSession {
  _EpubBookSessionImpl._(_SessionState state, this._security, this._throttle)
      : _state = state,
        _position = state.position;

  static Future<EpubBookSession> open(
    EpubSource source,
    EpubPosition? initialPosition,
    EpubSessionOptions options,
  ) async {
    final state = await _assemble(source, initialPosition, options.security);
    final session = _EpubBookSessionImpl._(
      state,
      options.security,
      options.progressThrottle,
    );

    // SessionStarted는 listener가 아직 없을 수 있으므로 버퍼에 쌓고
    // 첫 구독 시 재생한다(broadcast stream은 과거 이벤트를 보관하지 않음).
    session._emitLifecycle(
      EpubSessionStarted(epubVersion: state.book.metadata.epubVersion),
    );
    return session;
  }

  /// source → 보정 완료 책 + [target] 위치 복원/fallback → 세션 상태.
  ///
  /// [oldContent]가 주어지면(hot-swap) reflowable charOffset이 새 콘텐츠 범위를
  /// 벗어날 때 CFI로 재앵커한다(ADR-010). 없으면(최초 open) 범위 밖 charOffset을
  /// clamp한다. charOffset이 유효 범위면 그대로 유지(anchor-of-record).
  static Future<_SessionState> _assemble(
    EpubSource source,
    EpubPosition? target,
    EpubSecurityConfig security, {
    Map<String, String>? oldContent,
  }) async {
    final loaded = await OpenEpubUseCase(
      EpubRepositoryImpl(security: security),
    ).call(source);
    final book = loaded.book;

    if (book.spine.isEmpty) {
      throw StateError('EPUB has no spine items; cannot open a session');
    }

    final resolved = const ResolvePositionUseCase().call(book, target);
    final position = _reanchorReflowable(
      resolved,
      loaded.resources,
      security,
      oldContent,
    );

    // 페이지 이동에 사용할 linear spine href 순서(없으면 전체 spine).
    final linear = [
      for (final s in book.spine)
        if (s.linear) s.href
    ];
    final navHrefs =
        linear.isNotEmpty ? linear : [for (final s in book.spine) s.href];

    // 위치 복원 실패 시 진단에 기록(BDD F1.3 — position-restore-failed).
    var diagnostics = loaded.diagnostics;
    if (resolved.wasFallback) {
      diagnostics = BookSessionDiagnosticsData(
        appliedPatches: diagnostics.appliedPatches,
        unresolvedIssues: [
          ...diagnostics.unresolvedIssues,
          const UnresolvedIssue(
            code: 'position-restore-failed',
            message: '마지막 위치를 찾을 수 없어 처음부터 표시합니다',
          ),
        ],
      );
    }

    return _SessionState(
      book: book,
      diagnostics: diagnostics,
      position: position,
      navHrefs: navHrefs,
      resources: loaded.resources,
      navigation: loaded.navigation,
      capabilities: loaded.capabilities,
      renditions: loaded.renditions,
    );
  }

  static const EpubCfiMapper _cfiMapper = EpubCfiMapper();

  /// reflowable 위치의 charOffset을 새 콘텐츠에 맞춰 재앵커한다(ADR-010).
  /// [oldContent]가 있으면 CFI fuzzy fallback, 없으면 clamp. fallback 위치나
  /// non-reflowable은 그대로 반환.
  static EpubPosition _reanchorReflowable(
    ResolvedPosition resolved,
    EpubResourceReader resources,
    EpubSecurityConfig security,
    Map<String, String>? oldContent,
  ) {
    final position = resolved.position;
    if (resolved.wasFallback || position is! EpubReflowablePosition) {
      return position;
    }
    final newXhtml = _readSanitized(resources, position.spineHref, security);
    if (newXhtml == null) return position;

    final oldXhtml = oldContent?[position.spineHref];
    final newOffset = oldXhtml != null
        ? _cfiMapper.reanchorAcrossContent(
            oldXhtml: oldXhtml,
            oldCharOffset: position.charOffset,
            newXhtml: newXhtml,
          )
        : _cfiMapper.clampCharOffset(newXhtml, position.charOffset);
    if (newOffset == position.charOffset) return position;
    return EpubReflowablePosition(
      spineHref: position.spineHref,
      progress: position.progress,
      charOffset: newOffset,
      pageIndex: position.pageIndex,
      scrollAlignment: position.scrollAlignment,
    );
  }

  static String? _readSanitized(
    EpubResourceReader resources,
    String spineHref,
    EpubSecurityConfig security,
  ) {
    final raw = resources.readString(spineHref);
    if (raw == null) return null;
    return HtmlSanitizer(security).sanitize(raw);
  }

  _SessionState _state;
  final EpubSecurityConfig _security;
  final Duration _throttle;
  final Stopwatch _clock = Stopwatch()..start();
  Duration? _lastProgressAt;
  bool _disposed = false;

  late final StreamController<EpubLifecycleEvent> _lifecycle =
      StreamController<EpubLifecycleEvent>.broadcast(onListen: _flushLifecycle);
  final StreamController<EpubProgressEvent> _progress =
      StreamController<EpubProgressEvent>.broadcast();
  final StreamController<EpubToolUseEvent> _toolUse =
      StreamController<EpubToolUseEvent>.broadcast();
  final StreamController<EpubSelection?> _selection =
      StreamController<EpubSelection?>.broadcast();

  final List<EpubLifecycleEvent> _lifecycleBuffer = [];

  static const SpineTextExtractor _extractor = SpineTextExtractor();

  @override
  EpubBook get book => _state.book;
  @override
  BookSessionDiagnostics get diagnostics => _state.diagnostics;
  @override
  EpubResourceReader get resources => _state.resources;

  @override
  String? readSpineXhtml(String spineHref) {
    final raw = _state.resources.readString(spineHref);
    if (raw == null) return null;
    return HtmlSanitizer(_security).sanitize(raw);
  }

  static const SmilParser _smilParser = SmilParser();

  @override
  Future<EpubMediaOverlay> loadMediaOverlay(String spineHref) async {
    final spine = _state.book.spine;
    final item = spine.firstWhereOrNull((s) => s.href == spineHref);
    final smilHref = item?.mediaOverlayHref;
    if (smilHref == null) return EpubMediaOverlay.empty;

    final smilXml = _state.resources.readString(smilHref);
    if (smilXml == null) return EpubMediaOverlay.empty;

    final parsed = _smilParser.parse(smilXml);
    if (parsed.isEmpty) return EpubMediaOverlay.empty;

    // par src는 SMIL 파일 기준 상대경로 → OPF 기준 상대경로로 정규화해
    // 리소스 reader(readBytes/readString)가 바로 읽을 수 있게 한다.
    final smilDir = _dirname(smilHref);
    return EpubMediaOverlay(
      pars: [
        for (final par in parsed.pars)
          EpubMediaPar(
            textSrc: _resolveRelative(smilDir, par.textSrc),
            audioSrc: par.audioSrc == null
                ? null
                : _resolveRelative(smilDir, par.audioSrc!),
            clipBegin: par.clipBegin,
            clipEnd: par.clipEnd,
          ),
      ],
    );
  }

  /// SMIL 디렉토리 기준 상대 [src]를 OPF 기준 상대 경로로 정규화한다. `#fragment`
  /// (예: ch1.xhtml#s1)는 경로만 해석하고 fragment는 보존한다. (S15.1)
  static String _resolveRelative(String baseDir, String src) {
    final hash = src.indexOf('#');
    final path = hash < 0 ? src : src.substring(0, hash);
    final fragment = hash < 0 ? '' : src.substring(hash);
    return resolveHref(baseDir, path) + fragment;
  }

  static String _dirname(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  @override
  String? readSpineXhtmlWithHighlights(
    String spineHref,
    Iterable<EpubHighlight> highlights, {
    bool tappable = false,
  }) {
    final sanitized = readSpineXhtml(spineHref);
    if (sanitized == null) return null;
    final forSpine = [
      for (final h in highlights)
        if (h.spineHref == spineHref) h,
    ];
    if (forSpine.isEmpty) return sanitized;
    return _extractor.injectHighlights(sanitized, forSpine, tappable: tappable);
  }

  @override
  EpubPosition? resolveLink(String href, {String? fromSpineHref}) {
    final trimmed = href.trim();
    if (trimmed.isEmpty) return null;
    // 외부 스킴(http/https/mailto/tel 등)·하이라이트 링크는 책 내부 대상 아님.
    if (trimmed.contains('://') ||
        trimmed.startsWith('mailto:') ||
        trimmed.startsWith('tel:') ||
        SpineTextExtractor.highlightIdFromHref(trimmed) != null) {
      return null;
    }
    // fragment 제거 (#frag는 현재 무시 — spine 단위 점프).
    final path = trimmed.split('#').first;
    if (path.isEmpty) return null; // 같은 문서 내 앵커("#frag")는 위치 유지.
    final match = _matchSpineHref(path);
    if (match == null) return null;
    final i = _navHrefs.indexOf(match);
    final index = i < 0 ? 0 : i;
    final denom = _navHrefs.length <= 1 ? 1 : _navHrefs.length - 1;
    return EpubReflowablePosition(
      spineHref: match,
      progress: index / denom,
      charOffset: 0,
    );
  }

  /// 링크 경로를 spine href로 매칭한다. 정확 일치 우선, 없으면 파일명 일치.
  String? _matchSpineHref(String path) {
    for (final item in _state.book.spine) {
      if (item.href == path) return item.href;
    }
    final file = path.split('/').last;
    for (final item in _state.book.spine) {
      if (item.href.split('/').last == file) return item.href;
    }
    return null;
  }

  @override
  EpubOutline get outline => _state.book.outline;

  @override
  EpubNavigation get navigation => _state.navigation;

  @override
  BookCapabilities get capabilities => _state.capabilities;

  @override
  List<EpubRendition> get renditions => _state.renditions;

  @override
  Stream<EpubSelection?> get selectionStream => _selection.stream;

  @override
  void reportSelection(EpubSelection? selection) {
    _ensureActive();
    if (!_selection.isClosed) _selection.add(selection);
  }

  @override
  EpubSelection? resolveSelection(
    String spineHref,
    String selectedText, {
    int occurrence = 0,
  }) {
    final xhtml = readSpineXhtml(spineHref);
    if (xhtml == null) return null;
    return _extractor.resolveSelection(
      spineHref: spineHref,
      xhtml: xhtml,
      selectedText: selectedText,
      occurrence: occurrence,
    );
  }

  @override
  Future<BookSearchIndex> buildSearchIndex() async {
    final spineTexts = <String, String>{};
    for (final item in _state.book.spine) {
      final xhtml = readSpineXhtml(item.href);
      if (xhtml == null) continue;
      spineTexts[item.href] = _extractor.extractPlainText(xhtml);
    }
    return const BuildSearchIndexUseCase().call(
      _state.book,
      spineTexts: spineTexts,
    );
  }

  @override
  EpubReflowablePosition positionForHit(BookSearchHit hit) {
    final i = _navHrefs.indexOf(hit.spineHref);
    final index = i < 0 ? 0 : i;
    final denom = _navHrefs.length <= 1 ? 1 : _navHrefs.length - 1;
    return EpubReflowablePosition(
      spineHref: hit.spineHref,
      progress: index / denom,
      charOffset: hit.charOffset,
    );
  }

  @override
  Stream<EpubLifecycleEvent> get lifecycleEvents => _lifecycle.stream;
  @override
  Stream<EpubProgressEvent> get progressEvents => _progress.stream;
  @override
  Stream<EpubToolUseEvent> get toolUseEvents => _toolUse.stream;

  EpubPosition _position;

  @override
  EpubPosition get position => _position;

  @override
  double get progress => _position.progress;

  List<String> get _navHrefs => _state.navHrefs;

  int get _index {
    final i = _navHrefs.indexOf(_position.spineHref);
    return i < 0 ? 0 : i;
  }

  @override
  Future<void> jumpTo(EpubPosition position) async {
    _ensureActive();
    _position = position;
    _emitProgress();
  }

  @override
  String? exportPositionCfi(EpubReflowablePosition position) {
    final spineIndex =
        book.spine.indexWhere((s) => s.href == position.spineHref);
    if (spineIndex < 0) return null;
    final xhtml = readSpineXhtml(position.spineHref);
    if (xhtml == null) return null;
    final docCfi = _cfiMapper.charOffsetToCfi(xhtml, position.charOffset);
    if (docCfi == null) return null;
    return _cfiMapper.toBookCfi(
      docCfi,
      spineIndex: spineIndex,
      idref: book.spine[spineIndex].idref,
    );
  }

  @override
  EpubReflowablePosition? importPositionCfi(String bookCfi) {
    final parts = _cfiMapper.splitBookCfi(bookCfi);
    if (parts == null) return null;
    // spineIndex 우선, 범위 밖이거나 없으면 idref로 매칭.
    var idx = parts.spineIndex;
    if ((idx == null || idx < 0 || idx >= book.spine.length) &&
        parts.idref != null) {
      final byIdref = book.spine.indexWhere((s) => s.idref == parts.idref);
      if (byIdref >= 0) idx = byIdref;
    }
    if (idx == null || idx < 0 || idx >= book.spine.length) return null;
    final href = book.spine[idx].href;
    final xhtml = readSpineXhtml(href);
    if (xhtml == null) return null;
    final charOffset = _cfiMapper.cfiToCharOffset(xhtml, parts.docCfi);
    if (charOffset == null) return null;
    final denom = book.spine.length <= 1 ? 1 : book.spine.length - 1;
    return EpubReflowablePosition(
      spineHref: href,
      progress: idx / denom,
      charOffset: charOffset,
    );
  }

  @override
  Future<void> nextPage() async {
    _ensureActive();
    final next = _index + 1;
    if (next >= _navHrefs.length) return;
    _position = _positionAt(next);
    _emitProgress();
  }

  @override
  Future<void> previousPage() async {
    _ensureActive();
    final prev = _index - 1;
    if (prev < 0) return;
    _position = _positionAt(prev);
    _emitProgress();
  }

  EpubPosition _positionAt(int index) {
    final href = _navHrefs[index];
    final denom = _navHrefs.length <= 1 ? 1 : _navHrefs.length - 1;
    final p = index / denom;
    if (book.layout == EpubLayout.fixedLayout) {
      return EpubFixedPosition(spineHref: href, progress: p, pageIndex: 0);
    }
    return EpubReflowablePosition(spineHref: href, progress: p, charOffset: 0);
  }

  @override
  void recordHighlight() {
    _ensureActive();
    if (!_toolUse.isClosed) {
      _toolUse.add(EpubHighlightToolUse(position: _position));
    }
  }

  @override
  void recordBookmark() {
    _ensureActive();
    if (!_toolUse.isClosed) {
      _toolUse.add(EpubBookmarkToolUse(position: _position));
    }
  }

  @override
  Future<void> swapSource(EpubSource newSource) async {
    _ensureActive();
    // 현재 위치를 보존 대상으로 전달 → 새 책에 같은 spineHref가 있으면 복원,
    // 없으면 첫 페이지 fallback + position-restore-failed 진단. (BDD F10)
    //
    // reflowable이면 현재 spine의 (구)콘텐츠를 함께 넘겨, charOffset이 새
    // 콘텐츠 범위를 벗어날 때 CFI로 재앵커한다(ADR-010, S12.3).
    final pos = _position;
    Map<String, String>? oldContent;
    if (pos is EpubReflowablePosition) {
      final oldXhtml = readSpineXhtml(pos.spineHref);
      if (oldXhtml != null) oldContent = {pos.spineHref: oldXhtml};
    }
    final next = await _assemble(newSource, _position, _security,
        oldContent: oldContent);
    _ensureActive();
    _state = next;
    _position = next.position;
    _emitProgress();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _clock.stop();
    _emitLifecycle(EpubSessionEnded(sessionElapsed: _clock.elapsed));
    // close()의 done future는 fake-async 환경(widget test 본문)에서 완료되지
    // 않을 수 있다 — 닫기만 시작하고 완료를 기다리지 않는다. 이벤트 전달은
    // microtask로 이미 보장된다.
    unawaited(_lifecycle.close());
    unawaited(_progress.close());
    unawaited(_toolUse.close());
    unawaited(_selection.close());
  }

  void _emitLifecycle(EpubLifecycleEvent event) {
    if (_lifecycle.isClosed) return;
    if (_lifecycle.hasListener) {
      _lifecycle.add(event);
    } else {
      _lifecycleBuffer.add(event);
    }
  }

  void _flushLifecycle() {
    // 첫 listener 구독 시점에 버퍼된 이벤트(SessionStarted 등)를 재생한다.
    scheduleMicrotask(() {
      for (final event in _lifecycleBuffer) {
        if (!_lifecycle.isClosed) _lifecycle.add(event);
      }
      _lifecycleBuffer.clear();
    });
  }

  void _emitProgress() {
    if (_progress.isClosed) return;
    final now = _clock.elapsed;
    // throttle: 직전 발사 이후 [_throttle] 미만이면 억제(위치는 이미 갱신됨).
    if (_lastProgressAt != null && now - _lastProgressAt! < _throttle) return;
    _lastProgressAt = now;
    _progress.add(
      EpubProgressEvent(progress: _position.progress, sessionElapsed: now),
    );
  }

  void _ensureActive() {
    if (_disposed) throw StateError('EpubBookSession already disposed');
  }
}
