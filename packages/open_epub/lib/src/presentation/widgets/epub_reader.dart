// Presentation Top-level Widget — open_epub 1.0
// Story: S1.21 (#37) — EpubBookSession.open() 기반 최상위 reader
// BDD: F1 (책 열고 첫 페이지 표시), F1.2 (진도 인디케이터), F1.3 (복원 실패 안내)
//
// 최상위 entry widget. 내부적으로 EpubBookSession을 관리하고 ReflowableEngine
// 또는 FixedLayoutEngine으로 분기. 선택적 사용 — kobic은 자체 BLoC을 통해
// EpubBookSession을 직접 다룬다.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:open_epub_engine/open_epub_engine.dart';

import '../../api/epub_reader_controller.dart';
import '../engine/fixed_layout/fixed_layout_engine.dart';
import '../engine/reflowable/reflowable_engine.dart';
import '../engine/reflowable/reflowable_page_view.dart';
import '../media_overlay/media_overlay_controller.dart';
import '../media_overlay/media_overlay_highlight.dart';

/// 세션 open 완료 시점에 호출 — 호출자가 analytics 스트림 구독·위치 저장 등
/// 세션 수준 기능에 접근할 수 있게 한다.
typedef EpubSessionReadyCallback = void Function(EpubBookSession session);

/// 페이지(spine) 전환 콜백. (spineIndex, spineCount). open-board 필기
/// 오버레이가 페이지별 필기 저장/복원에 사용한다. (S8.1)
typedef EpubPageChangedCallback = void Function(int spineIndex, int spineCount);

/// 현재 읽기 위치 변경 콜백. position.toToken()은 필기·주석의 안정 앵커
/// (page-index 대신 — repagination에도 보존, S8.4).
typedef EpubPositionChangedCallback = void Function(EpubPosition position);

/// 본문 viewport 크기 변경 콜백. 오버레이 정합에 사용. (S8.2)
typedef EpubViewportChangedCallback = void Function(Size viewportSize);

/// open_epub 1.0 최상위 reader widget.
///
/// [source]로 세션을 열어 책의 layout에 따라 [ReflowableEngine] 또는
/// [FixedLayoutEngine]으로 본문을 표시한다. 위치 복원 실패 시 안내 배너
/// (BDD F1.3), 하단에 진도 인디케이터(BDD F1.2)를 표시한다.
class EpubReader extends StatefulWidget {
  const EpubReader({
    super.key,
    required this.source,
    this.initialPosition,
    this.options = const EpubSessionOptions(),
    this.onSessionReady,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.showProgressIndicator = true,
    this.highlights = const [],
    this.onLinkTap,
    this.paged = false,
    this.onPageChanged,
    this.onPositionChanged,
    this.onViewportChanged,
    this.controller,
    this.fixedLayoutContentBuilder,
    this.fixedLayoutZoomEnabled = true,
    this.fixedLayoutSpreadOverride,
    this.readingDirection,
    this.mediaOverlayController,
    this.verticalWriting = false,
  });

  final EpubSource source;

  /// 저장된 위치(BookPosition v1). 복원 실패 시 첫 페이지 fallback + 배너.
  final EpubPosition? initialPosition;

  final EpubSessionOptions options;
  final EpubSessionReadyCallback? onSessionReady;

  /// Reflowable 본문 글자 크기 (px).
  final double fontSize;

  /// Reflowable 본문 줄간격 (배수).
  final double lineHeight;

  /// 하단 진도 인디케이터("45%") 표시 여부.
  final bool showProgressIndicator;

  /// 본문에 렌더할 하이라이트(Reflowable). 변경 시 본문이 다시 그려진다. (S7)
  final List<EpubHighlight> highlights;

  /// 본문 링크/하이라이트 탭 콜백. href가 `openepub-hl:ID`면
  /// [SpineTextExtractor.highlightIdFromHref]로 하이라이트 id를, 그 외는
  /// [EpubBookSession.resolveLink]로 책 내부 위치를 얻는다(호스트 라우팅). (S7.3/S7.5)
  final EpubLinkTapCallback? onLinkTap;

  /// Reflowable을 spine 단위 PageView(스와이프)로 표시한다. open-board 필기
  /// 오버레이처럼 페이지 전환 이벤트가 필요한 호스트가 사용. (S8.1)
  final bool paged;

  /// 페이지(spine) 전환 콜백. (S8.1)
  final EpubPageChangedCallback? onPageChanged;

  /// 위치 변경 콜백 — position.toToken()을 필기 앵커로 사용. (S8.4)
  final EpubPositionChangedCallback? onPositionChanged;

  /// 본문 viewport 크기 변경 콜백. (S8.2)
  final EpubViewportChangedCallback? onViewportChanged;

  /// 페이지 내비게이션 컨트롤러(prev/next 등). 지정 시 자동으로 paged 모드로
  /// 표시된다. 레거시 EpubReaderController가 아닌 1.0 전용 타입. (S8.1)
  final EpubViewController? controller;

  /// fixed-layout 페이지 콘텐츠를 논리 좌표 공간에서 감싸는 빌더(open-board
  /// 절대좌표 필기 캔버스가 페이지 content를 child로 받는 용도 등, S8.6). 반환
  /// 위젯의 로컬 좌표가 곧 페이지 절대좌표이며 fit·zoom·pan과 함께 변환된다.
  /// reflowable 본문에는 적용되지 않는다.
  final FixedLayoutContentBuilder? fixedLayoutContentBuilder;

  /// fixed-layout 페이지 줌/팬 활성 여부. 필기(드로잉) 중에는 false로 두어
  /// InteractiveViewer pan과 드로잉 제스처 충돌을 막는다. default true. (S8.6)
  final bool fixedLayoutZoomEnabled;

  /// fixed-layout spread(양면/단면) 강제 설정. null이면 EPUB의
  /// `rendition:spread` 메타데이터를 따른다. 호스트의 양면/단면 토글이 사용
  /// — 예: [EpubSpread.none]=항상 단면, [EpubSpread.landscape]=가로에서만
  /// 양면. reflowable 본문에는 영향 없음. (kobic#7576)
  final EpubSpread? fixedLayoutSpreadOverride;

  /// 페이지 넘김 방향 강제. null이면 책의 `page-progression-direction`
  /// (`session.capabilities.pageProgressionDirection`)을 따른다(auto). 호스트의
  /// 방향 토글이 [EpubPageProgression.ltr]/[EpubPageProgression.rtl]을 명시해
  /// 덮어쓴다. [EpubPageProgression.rtl]이면 reflowable(paged)·fixed-layout 모두
  /// 넘김/스와이프 방향이 우→좌로 반전된다. (S14.1, gap #4)
  final EpubPageProgression? readingDirection;

  /// Media Overlays 낭독 컨트롤러. 지정 시 현재 재생 중인 par(활성 문장)의
  /// 텍스트 fragment를 본문에 하이라이트한다(낭독 하이라이트, 사용자 하이라이트와
  /// 공존). 재생 제어(start/pause)는 호스트가 이 컨트롤러로 직접 한다. reflowable
  /// 본문에만 적용된다. (S15.3, gap #6 동기화분)
  final MediaOverlayController? mediaOverlayController;

  /// 세로쓰기(vertical-rl/lr) 조판 강제. 스타일시트로만 writing-mode를 선언해
  /// 본문 인라인 감지가 안 되는 책용(호스트가 capabilities/자체 판단으로 지정).
  /// 본문이 인라인으로 vertical-*를 선언하면 이 값과 무관하게 자동 세로 조판된다.
  /// 단순 텍스트 spine에만 적용되고 이미지·수식 등 복잡 콘텐츠는 가로로 폴백한다.
  /// reflowable 본문에만 적용. (S15.4, gap #4 조판분, 실용 구현)
  final bool verticalWriting;

  @override
  State<EpubReader> createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> {
  late Future<EpubBookSession> _open;
  EpubBookSession? _session;

  @override
  void initState() {
    super.initState();
    _open = _openSession();
  }

  Future<EpubBookSession> _openSession() async {
    final session = await EpubBookSession.open(
      widget.source,
      initialPosition: widget.initialPosition,
      options: widget.options,
    );
    _session = session;
    widget.onSessionReady?.call(session);
    return session;
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EpubBookSession>(
      future: _open,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _OpenErrorView(error: snapshot.error!);
        }
        return _SessionView(
          session: snapshot.data!,
          fontSize: widget.fontSize,
          lineHeight: widget.lineHeight,
          showProgressIndicator: widget.showProgressIndicator,
          highlights: widget.highlights,
          onLinkTap: widget.onLinkTap,
          // controller가 있으면 프로그램적 내비게이션을 위해 paged 강제.
          paged: widget.paged || widget.controller != null,
          onPageChanged: widget.onPageChanged,
          onPositionChanged: widget.onPositionChanged,
          onViewportChanged: widget.onViewportChanged,
          controller: widget.controller,
          fixedLayoutContentBuilder: widget.fixedLayoutContentBuilder,
          fixedLayoutZoomEnabled: widget.fixedLayoutZoomEnabled,
          fixedLayoutSpreadOverride: widget.fixedLayoutSpreadOverride,
          readingDirection: widget.readingDirection,
          mediaOverlayController: widget.mediaOverlayController,
          verticalWriting: widget.verticalWriting,
        );
      },
    );
  }
}

class _SessionView extends StatefulWidget {
  const _SessionView({
    required this.session,
    required this.fontSize,
    required this.lineHeight,
    required this.showProgressIndicator,
    required this.highlights,
    required this.onLinkTap,
    required this.paged,
    required this.onPageChanged,
    required this.onPositionChanged,
    required this.onViewportChanged,
    required this.controller,
    required this.fixedLayoutContentBuilder,
    required this.fixedLayoutZoomEnabled,
    required this.fixedLayoutSpreadOverride,
    required this.readingDirection,
    required this.mediaOverlayController,
    required this.verticalWriting,
  });

  final EpubBookSession session;
  final double fontSize;
  final double lineHeight;
  final bool showProgressIndicator;
  final List<EpubHighlight> highlights;
  final EpubLinkTapCallback? onLinkTap;
  final bool paged;
  final EpubPageChangedCallback? onPageChanged;
  final EpubPositionChangedCallback? onPositionChanged;
  final EpubViewportChangedCallback? onViewportChanged;
  final EpubViewController? controller;
  final FixedLayoutContentBuilder? fixedLayoutContentBuilder;
  final bool fixedLayoutZoomEnabled;
  final EpubSpread? fixedLayoutSpreadOverride;
  final EpubPageProgression? readingDirection;
  final MediaOverlayController? mediaOverlayController;
  final bool verticalWriting;

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
  Size? _lastViewport;

  /// 본문 재로드 트리거 토큰 — 하이라이트 목록 또는 낭독 활성 par가 바뀌면
  /// identity를 새로 만들어 엔진이 spine XHTML을 다시 로드(=낭독 하이라이트 갱신)
  /// 하게 한다. (S15.3)
  Object _contentRevision = Object();
  List<EpubHighlight>? _revHighlights;
  String? _revActiveTextSrc;

  EpubBookSession get _session => widget.session;

  int get _initialSpineIndex {
    final spine = _session.book.spine;
    final i = spine.indexWhere((s) => s.href == _session.position.spineHref);
    return i < 0 ? 0 : i;
  }

  String? get _restoreFailedMessage {
    for (final issue in _session.diagnostics.unresolvedIssues) {
      if (issue.code == 'position-restore-failed') return issue.message;
    }
    return null;
  }

  /// 유효 읽기 방향이 RTL인지 — override(readingDirection)가 있으면 그것을,
  /// 없으면 책의 `page-progression-direction`(capabilities)을 따른다(auto).
  /// auto/ltr은 false. (S14.1, gap #4)
  bool get _isRtl {
    final direction =
        widget.readingDirection ?? _session.capabilities.pageProgressionDirection;
    return direction == EpubPageProgression.rtl;
  }

  @override
  void initState() {
    super.initState();
    // 초기 위치/페이지를 한 번 보고(open-board가 첫 페이지 필기를 로드, S8.1).
    // 내부 PageView 이동 함수는 ReflowablePageView가 onNavigatorReady로 넘겨준다.
    final count = _session.book.spine.length;
    widget.controller?.syncState(
      currentSpineIndex: _initialSpineIndex,
      spineCount: count,
    );
    if (widget.onPositionChanged != null || widget.onPageChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPositionChanged?.call(_session.position);
        widget.onPageChanged?.call(_initialSpineIndex, count);
      });
    }
    widget.mediaOverlayController?.activeParIndex
        .addListener(_onMediaOverlayChanged);
  }

  @override
  void didUpdateWidget(_SessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.mediaOverlayController,
      widget.mediaOverlayController,
    )) {
      oldWidget.mediaOverlayController?.activeParIndex
          .removeListener(_onMediaOverlayChanged);
      widget.mediaOverlayController?.activeParIndex
          .addListener(_onMediaOverlayChanged);
    }
  }

  /// 낭독 활성 par가 바뀌면 rebuild — build에서 contentRevision을 갱신해 본문이
  /// 새 하이라이트로 다시 로드된다. (S15.3)
  void _onMediaOverlayChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.mediaOverlayController?.activeParIndex
        .removeListener(_onMediaOverlayChanged);
    widget.controller?.detachNavigator();
    super.dispose();
  }

  EpubPosition _positionForSpine(int index) {
    final spine = _session.book.spine;
    final href = spine[index].href;
    final denom = spine.length <= 1 ? 1 : spine.length - 1;
    final p = index / denom;
    if (_session.book.layout == EpubLayout.fixedLayout) {
      return EpubFixedPosition(spineHref: href, progress: p, pageIndex: 0);
    }
    return EpubReflowablePosition(spineHref: href, progress: p, charOffset: 0);
  }

  void _handlePageChanged(int index) {
    final pos = _positionForSpine(index);
    // 세션 위치를 동기화(progress/analytics 일관) — 결과는 기다리지 않는다.
    unawaited(_session.jumpTo(pos));
    widget.controller?.syncState(
      currentSpineIndex: index,
      spineCount: _session.book.spine.length,
    );
    widget.onPositionChanged?.call(pos);
    widget.onPageChanged?.call(index, _session.book.spine.length);
  }

  @override
  Widget build(BuildContext context) {
    _syncContentRevision();
    final book = _session.book;
    final Widget engine;
    if (book.layout == EpubLayout.fixedLayout) {
      engine = FixedLayoutEngine(
        book: book,
        initialSpineIndex: _initialSpineIndex,
        pageBuilder: _buildFixedPage,
        contentBuilder: widget.fixedLayoutContentBuilder,
        enableZoom: widget.fixedLayoutZoomEnabled,
        spreadOverride: widget.fixedLayoutSpreadOverride,
        // RTL이면 spread 좌우 배치·스와이프 방향 반전. (S14.1)
        rightToLeft: _isRtl,
        // 스와이프·프로그램적 이동을 reflowable paged와 동일 계약으로 배선
        // — 세션 위치/컨트롤러/onPageChanged 동기화 (kobic#7576).
        onSpineChanged: _handlePageChanged,
        onNavigatorReady: (navigate) =>
            widget.controller?.attachNavigator(navigate),
      );
    } else if (widget.paged) {
      engine = ReflowablePageView(
        book: book,
        initialSpineIndex: _initialSpineIndex,
        xhtmlLoader: _loadXhtml,
        imageLoader: _loadImage,
        fontSize: widget.fontSize,
        lineHeight: widget.lineHeight,
        onLinkTap: widget.onLinkTap,
        onPageChanged: _handlePageChanged,
        // RTL이면 PageView 스크롤 방향 반전(다음=좌향). (S14.1)
        reverse: _isRtl,
        // 세로쓰기 강제(단순 텍스트 spine 세로 조판). (S15.4)
        forceVertical: widget.verticalWriting,
        onNavigatorReady: (navigate) =>
            widget.controller?.attachNavigator(navigate),
        // 하이라이트 목록/낭독 활성 par가 바뀌면 spine XHTML을 다시 로드해 본문에
        // 즉시 반영한다. (open-epub#62, S15.3)
        contentRevision: _contentRevision,
      );
    } else {
      engine = ReflowableEngine(
        book: book,
        initialSpineIndex: _initialSpineIndex,
        xhtmlLoader: _loadXhtml,
        imageLoader: _loadImage,
        fontSize: widget.fontSize,
        lineHeight: widget.lineHeight,
        onLinkTap: widget.onLinkTap,
        // 스크롤로 spine이 넘어가면 paged와 동일하게 세션 위치·컨트롤러를
        // 동기화하고 호스트에 보고한다 (kobic#7572 — 진행률·챕터명 갱신).
        onSpineChanged: _handlePageChanged,
        // 하이라이트 목록/낭독 활성 par가 바뀌면 spine XHTML을 다시 로드해 본문에
        // 즉시 반영한다. (open-epub#62, S15.3)
        contentRevision: _contentRevision,
        // 세로쓰기 강제(단순 텍스트 spine 세로 조판). (S15.4)
        forceVertical: widget.verticalWriting,
      );
    }

    final restoreMessage = _restoreFailedMessage;
    return Column(
      children: [
        if (restoreMessage != null)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(restoreMessage)),
                ],
              ),
            ),
          ),
        Expanded(child: _maybeReportViewport(engine)),
        if (widget.showProgressIndicator)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${(_session.progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  /// onViewportChanged가 있으면 LayoutBuilder로 본문 영역 크기를 관찰해
  /// 변경 시 보고한다(빌드 중 콜백 회피 — post-frame). (S8.2)
  Widget _maybeReportViewport(Widget child) {
    if (widget.onViewportChanged == null) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _lastViewport) {
          _lastViewport = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onViewportChanged?.call(size);
          });
        }
        return child;
      },
    );
  }

  Future<String> _loadXhtml(String spineHref) async {
    String base;
    if (widget.highlights.isEmpty) {
      base = _session.readSpineXhtml(spineHref) ?? '';
    } else {
      // 하이라이트가 있으면 코어 렌더 경로로 주입. onLinkTap이 있으면 탭 가능
      // 링크로 감싸 하이라이트 탭(S7.3)을 받는다.
      base = _session.readSpineXhtmlWithHighlights(
            spineHref,
            widget.highlights,
            tappable: widget.onLinkTap != null,
          ) ??
          '';
    }
    // 낭독 하이라이트 — 이 spine이 현재 활성 par를 담고 있으면 fragment 강조.
    // (S15.3) 사용자 하이라이트 위에 별개 레이어로 얹는다.
    final fragment = _activeMediaOverlayFragment(spineHref);
    if (fragment != null) {
      base = injectMediaOverlayHighlight(base, fragment);
    }
    return base;
  }

  /// 현재 낭독 활성 par가 [spineHref] 문서를 가리키면 그 fragment id, 아니면 null.
  /// (S15.3)
  String? _activeMediaOverlayFragment(String spineHref) {
    final par = widget.mediaOverlayController?.activePar;
    if (par == null) return null;
    final split = splitTextSrc(par.textSrc);
    if (split.fragment == null) return null;
    return _sameSpineFile(split.path, spineHref) ? split.fragment : null;
  }

  /// 두 OPF 기준 상대 경로가 같은 문서를 가리키는지(경로 표기 차이 폴백 포함).
  static bool _sameSpineFile(String a, String b) {
    if (a == b) return true;
    return a.split('/').last == b.split('/').last;
  }

  /// build 시 하이라이트/낭독 활성 par 변경을 감지해 [_contentRevision] identity를
  /// 갱신한다 — 바뀌지 않으면 identity 유지(불필요 재로드 방지). (S15.3)
  void _syncContentRevision() {
    final activeTextSrc = widget.mediaOverlayController?.activePar?.textSrc;
    if (!identical(_revHighlights, widget.highlights) ||
        _revActiveTextSrc != activeTextSrc) {
      _revHighlights = widget.highlights;
      _revActiveTextSrc = activeTextSrc;
      _contentRevision = Object();
    }
  }

  Future<Uint8List?> _loadImage(String src) async =>
      _session.resources.readBytes(src);

  Future<FixedLayoutPageData> _buildFixedPage(EpubSpineItem item) async {
    final xhtml = _session.readSpineXhtml(item.href) ?? '';
    return FixedLayoutPageData(
      logicalSize: _viewportSize(xhtml),
      content: buildReflowableHtml(
        data: xhtml,
        fontSize: widget.fontSize,
        lineHeight: widget.lineHeight,
        imageLoader: _loadImage,
      ),
    );
  }

  /// `<meta name="viewport" content="width=600, height=800"/>`에서 논리
  /// 크기를 파싱한다. 없거나 비정상이면 기본 600×800.
  static Size _viewportSize(String xhtml) {
    final width = _viewportDimension(xhtml, 'width');
    final height = _viewportDimension(xhtml, 'height');
    if (width == null || height == null || width <= 0 || height <= 0) {
      return const Size(600, 800);
    }
    return Size(width, height);
  }

  static double? _viewportDimension(String xhtml, String name) {
    final match = RegExp('$name\\s*=\\s*(\\d+(?:\\.\\d+)?)').firstMatch(xhtml);
    return match == null ? null : double.tryParse(match.group(1)!);
  }
}

class _OpenErrorView extends StatelessWidget {
  const _OpenErrorView({required this.error});

  final Object error;

  String get _message => switch (error) {
        EpubFileTooLarge() => '파일이 너무 커서 열 수 없습니다.',
        EpubNetworkFailure() => '네트워크 오류로 책을 가져오지 못했습니다.',
        EpubCorrupted() || EpubInvalidFile() => '손상되었거나 올바르지 않은 EPUB입니다.',
        _ => '책을 여는 중 오류가 발생했습니다.',
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('$_message\n$error', textAlign: TextAlign.center),
      ),
    );
  }
}
