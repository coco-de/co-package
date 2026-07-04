// Presentation Engine — open_epub 1.0
// Story: S1.5 (#11) — Reflowable XHTML 렌더
// Story: S1.6 (#12) — 글자 크기·줄간격 + BookPosition(spineIndex) 보존
// Fix: kobic#7572 — 스크롤 모드 전체 spine 연속 세로 스크롤
// BDD: F2.1 / F2.2 / F2.3 / F2.5
//
// 본 widget은 책 전체 spine을 하나의 연속 세로 스크롤로 표시한다
// (kobic#7572). 이전 구현은 현재 spine 하나만 SingleChildScrollView로
// 렌더해, spine 콘텐츠가 뷰포트보다 짧으면 스크롤할 것이 없고 다음 spine으로
// 갈 제스처도 없어 스크롤 모드가 dead-end였다. 각 spine은 lazy load되며,
// 화면 상단에 보이는 spine이 바뀌면 [ReflowableEngine.onSpineChanged]로
// 알린다(위치 동기화·진행률용).
//
// 페이지 모드(spine 단위 PageView)는 [ReflowablePageView]에서 처리.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_svg/fwfh_svg.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:open_epub_engine/open_epub_engine.dart';

import 'mathml_to_tex.dart';

/// spine href를 받아 해당 XHTML 콘텐츠 문자열을 비동기 로드.
typedef XhtmlLoader = Future<String> Function(String spineHref);

/// 이미지 src(XHTML 내 `<img src>`)를 받아 바이트를 비동기 로드.
/// null 반환 또는 throw 시 placeholder가 표시된다.
typedef ImageLoader = Future<Uint8List?> Function(String src);

/// 본문 내 링크(`<a href>`) 탭 콜백. href는 책 내부 상대 경로(예: "ch2.xhtml"),
/// 외부 URL, 또는 하이라이트 링크(openepub-hl:ID)일 수 있다. (S7.3/S7.5)
typedef EpubLinkTapCallback = void Function(String href);

/// 화면 상단에 보이는 spine 인덱스가 바뀔 때 호출된다. (kobic#7572)
typedef SpineChangedCallback = void Function(int spineIndex);

/// Reflowable EPUB 책의 본문을 표시하는 최상위 엔진 widget (스크롤 모드).
///
/// 전체 spine을 [ScrollablePositionedList]로 연속 표시한다. 페이지 내 분할
/// 없이 spine 단위로 lazy load하며, 스크롤로 자연스럽게 다음/이전 spine으로
/// 이어진다. 프로그램적 이동은 [ReflowableEngineState.nextSpine] /
/// [ReflowableEngineState.previousSpine]으로 가능하다.
class ReflowableEngine extends StatefulWidget {
  const ReflowableEngine({
    super.key,
    required this.book,
    required this.xhtmlLoader,
    this.imageLoader,
    this.initialSpineIndex = 0,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.onLinkTap,
    this.onSpineChanged,
    this.contentRevision,
  });

  final EpubBook book;
  final XhtmlLoader xhtmlLoader;
  final ImageLoader? imageLoader;
  final int initialSpineIndex;

  /// 본문 글자 크기 (px). BDD F2.2 — 변경 시 본문 재배치 + spineIndex 보존.
  final double fontSize;

  /// 본문 줄간격 (배수). BDD F2.3 — 변경 시 본문 재배치.
  final double lineHeight;

  /// 본문 링크/하이라이트 탭 콜백. (S7.3/S7.5)
  final EpubLinkTapCallback? onLinkTap;

  /// 스크롤로 화면 상단 spine이 바뀔 때 알림 (위치 동기화·진행률, kobic#7572).
  /// 초기 spine에 대해서는 호출하지 않는다.
  final SpineChangedCallback? onSpineChanged;

  /// [xhtmlLoader] 결과에 영향을 주는 외부 상태의 revision(예: 하이라이트
  /// 목록). identity가 바뀌면 캐시된 spine XHTML을 버리고 다시 로드한다 —
  /// 하이라이트 저장/삭제·늦게 도착한 복원이 본문에 즉시 반영되도록.
  /// (open-epub#62)
  final Object? contentRevision;

  @override
  State<ReflowableEngine> createState() => ReflowableEngineState();
}

@visibleForTesting
class ReflowableEngineState extends State<ReflowableEngine> {
  late int _spineIndex;
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  /// spine href별 XHTML 로드 future 캐시 — 스크롤로 재방문 시 재로드 방지.
  final Map<String, Future<String>> _loads = {};

  /// 사용자 드래그(+관성)로 스크롤 중인지. 위치 리스너 기반 spine 판정은
  /// 사용자 스크롤 중에만 적용한다 — 초기 진입/프로그램적 jump/Html 확장
  /// 재배치가 만들어내는 stale 위치 보고가 현재 spine을 덮어쓰지 않도록.
  bool _userScrolling = false;

  int get spineIndex => _spineIndex;
  int get spineCount => widget.book.spine.length;

  /// 현재 spine 기준 앞뒤로 선제 로드할 spine 수 (부드러운 스크롤, kobic#7572).
  static const int _prefetchRadius = 2;

  @override
  void initState() {
    super.initState();
    _spineIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    _positionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _prefetchAround(_spineIndex);
  }

  @override
  void didUpdateWidget(ReflowableEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) {
      _loads.clear();
      _spineIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _prefetchAround(_spineIndex);
    } else if (!identical(oldWidget.contentRevision, widget.contentRevision)) {
      // 하이라이트 등 콘텐츠 revision 변경 — 캐시를 버리고 현재 위치 주변부터
      // 재로드한다. 각 item은 재로드 동안 직전 콘텐츠를 유지해(_SpineItemView)
      // 스크롤 점프 없이 교체된다. (open-epub#62)
      _loads.clear();
      _prefetchAround(_spineIndex);
    }
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    super.dispose();
  }

  Future<String> _loadSpine(String href) =>
      _loads.putIfAbsent(href, () => widget.xhtmlLoader(href));

  /// [center] 주변 spine의 XHTML 로드를 미리 시작한다 — 스크롤이 다음 spine에
  /// 닿기 전에 데이터가 준비되어 로딩 끊김을 줄인다 (kobic#7572).
  void _prefetchAround(int center) {
    final spine = widget.book.spine;
    if (spine.isEmpty) return;
    final start = (center - _prefetchRadius).clamp(0, spine.length - 1);
    final end = (center + _prefetchRadius).clamp(0, spine.length - 1);
    for (var i = start; i <= end; i++) {
      // 결과는 캐시에만 적재 — 실패는 item 빌드 시 FutureBuilder가 표시.
      _loadSpine(spine[i].href).ignore();
    }
  }

  /// 화면에 보이는 item 중 가장 위(최소 leading edge)의 spine을 현재로 판정.
  void _onItemPositionsChanged() {
    if (!_userScrolling) return;
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    ItemPosition? top;
    for (final position in positions) {
      // 뷰포트에 실제로 걸쳐 있는 item만 (trailing이 0 이하면 위로 지나감).
      if (position.itemTrailingEdge <= 0 || position.itemLeadingEdge >= 1) {
        continue;
      }
      if (top == null || position.itemLeadingEdge < top.itemLeadingEdge) {
        top = position;
      }
    }
    if (top == null || top.index == _spineIndex) return;
    _spineIndex = top.index;
    _prefetchAround(top.index);
    widget.onSpineChanged?.call(top.index);
  }

  /// 드래그로 시작된 스크롤(+이어지는 관성)만 사용자 스크롤로 표시한다.
  /// 프로그램적 jump나 레이아웃 재배치의 스크롤 알림은 제외된다.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _userScrolling = notification.dragDetails != null;
    } else if (notification is ScrollEndNotification) {
      // 마지막 위치 보고는 postFrame으로 늦게 도착하므로 여기서 한 번 더 판정.
      _onItemPositionsChanged();
      _userScrolling = false;
    }
    return false;
  }

  /// 프로그램적 spine 이동 — 대상 item이 아직 layout에 없으면
  /// [ItemScrollController.scrollTo]의 crossfade 전환이 불안정하므로
  /// 결정적인 [ItemScrollController.jumpTo]로 재앵커하고 상태를 직접 갱신한다.
  void _jumpToSpine(int index) {
    if (_scrollController.isAttached) {
      _scrollController.jumpTo(index: index);
    }
    if (index == _spineIndex) return;
    _spineIndex = index;
    _prefetchAround(index);
    widget.onSpineChanged?.call(index);
  }

  /// 다음 spine 항목으로 이동. 마지막이면 false.
  bool nextSpine() {
    if (_spineIndex >= spineCount - 1) return false;
    _jumpToSpine(_spineIndex + 1);
    return true;
  }

  /// 이전 spine 항목으로 이동. 처음이면 false.
  bool previousSpine() {
    if (_spineIndex <= 0) return false;
    _jumpToSpine(_spineIndex - 1);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final spine = widget.book.spine;
    if (spine.isEmpty) {
      return const _EmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: LayoutBuilder(
        builder: (context, constraints) => ScrollablePositionedList.builder(
          itemCount: spine.length,
          initialScrollIndex: _spineIndex,
          itemScrollController: _scrollController,
          itemPositionsListener: _positionsListener,
          // 뷰포트 밖 2화면 분량을 미리 빌드해 스크롤 중 로딩 끊김을 줄인다
          // (kobic#7572). Html 파싱이 스크롤 도달 전에 끝나도록.
          minCacheExtent: constraints.maxHeight * 2,
          itemBuilder: (context, index) => _SpineItemView(
            // 같은 href가 spine에 중복 등장할 수 있어 index로 구분.
            key: ValueKey('reflowable-spine-$index'),
            load: _loadSpine(spine[index].href),
            fontSize: widget.fontSize,
            lineHeight: widget.lineHeight,
            imageLoader: widget.imageLoader,
            onLinkTap: widget.onLinkTap,
          ),
        ),
      ),
    );
  }
}

/// 단일 spine 항목 뷰 — lazy load + 로딩/에러 상태를 item 단위로 표시.
///
/// 콘텐츠 revision 변경으로 [load]가 교체되면 새 로드가 끝날 때까지 직전
/// 콘텐츠를 유지한다 — item 높이가 스피너로 무너지며 생기는 스크롤 점프 방지.
/// (open-epub#62)
class _SpineItemView extends StatefulWidget {
  const _SpineItemView({
    super.key,
    required this.load,
    required this.fontSize,
    required this.lineHeight,
    required this.imageLoader,
    required this.onLinkTap,
  });

  final Future<String> load;
  final double fontSize;
  final double lineHeight;
  final ImageLoader? imageLoader;
  final EpubLinkTapCallback? onLinkTap;

  @override
  State<_SpineItemView> createState() => _SpineItemViewState();
}

class _SpineItemViewState extends State<_SpineItemView> {
  /// 마지막으로 성공 로드된 XHTML — 재로드 동안 표시 유지용.
  String? _lastData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.load,
      builder: (context, snapshot) {
        if (snapshot.hasData) _lastData = snapshot.data;
        final data = snapshot.hasData ? snapshot.data : _lastData;
        if (data == null) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!);
          }
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: buildReflowableHtml(
            data: data,
            fontSize: widget.fontSize,
            lineHeight: widget.lineHeight,
            imageLoader: widget.imageLoader,
            onLinkTap: widget.onLinkTap,
          ),
        );
      },
    );
  }
}

/// fwfh WidgetFactory + `<svg>` 렌더(fwfh_svg). ADR-009.
///
/// 인라인 `<svg>`(EPUB3 커버·수식 폴백)를 [SvgFactory]가 처리한다. `<img>`는
/// [buildReflowableHtml]의 customWidgetBuilder가 EPUB 아카이브 로더로 가로채므로
/// 여기서 별도 처리하지 않는다.
class _EpubWidgetFactory extends WidgetFactory with SvgFactory {}

/// 사용자 글자 크기·줄간격이 적용된 본문 렌더 widget(fwfh)을 빌드한다.
/// [ReflowablePageView]와 공유하는 internal helper.
///
/// S11.3(#90): flutter_html → flutter_widget_from_html 교체(ADR-009).
/// - textStyle: base 글자 크기(px)·줄간격(height 배수)
/// - onTapUrl: 본문 링크·하이라이트(openepub-hl:) 탭 라우팅(S7.3/S7.5)
/// - customWidgetBuilder: 모든 `<img>`를 [ImageLoader] 경로로 가로채 아카이브
///   바이트를 렌더하고, 실패/빈 src는 alt 텍스트→placeholder로 대체
/// - buildAsync=false: 렌더를 동기화해 페이지 전환·회귀 테스트가 결정적이도록
///
/// S11.4(#91): never-empty 계약(ADR-009).
/// - 렌더 가능한 콘텐츠가 전혀 없으면 공백 대신 안내 위젯([_BlankContentNotice]).
/// - `<img>` 실패: alt 텍스트가 있으면 우선 표시, 없으면 아이콘 placeholder.
/// - `<math>`: [mathmlToTex]로 TeX 변환 후 [Math.tex] 렌더(S14.2, gap #5).
///   변환 불가/파싱 실패 시 [_FormulaPlaceholder]로 폴백(never-empty).
/// - 인라인 `<svg>`: [SvgFactory](fwfh_svg)가 렌더.
Widget buildReflowableHtml({
  required String data,
  required double fontSize,
  required double lineHeight,
  required ImageLoader? imageLoader,
  EpubLinkTapCallback? onLinkTap,
}) {
  // never-empty: 렌더 가능한 콘텐츠(텍스트·이미지·svg·math)가 없으면 공백 금지.
  if (_isBlankContent(data)) {
    return const _BlankContentNotice();
  }
  return HtmlWidget(
    data,
    buildAsync: false,
    textStyle: TextStyle(fontSize: fontSize, height: lineHeight),
    factoryBuilder: () => _EpubWidgetFactory(),
    onTapUrl: (url) {
      if (url.isNotEmpty) onLinkTap?.call(url);
      // 항상 handled로 표시 — 외부 url_launcher 시도(미의존)를 막는다.
      return true;
    },
    customWidgetBuilder: (element) {
      switch (element.localName) {
        case 'img':
          final src = element.attributes['src'];
          final alt = element.attributes['alt'];
          if (src == null || src.isEmpty) {
            return _ImagePlaceholder(reason: 'missing src', alt: alt);
          }
          return _RemoteImage(src: src, loader: imageLoader, alt: alt);
        case 'math':
          // MathML → TeX 변환 후 flutter_math_fork로 렌더(S14.2, gap #5).
          // 변환 불가(null)면 placeholder, TeX 파싱 실패는 위젯이 폴백.
          final tex = mathmlToTex(element);
          final alt = element.attributes['alttext'];
          if (tex == null) return _FormulaPlaceholder(alt: alt);
          return _MathFormula(tex: tex, fontSize: fontSize, alt: alt);
        default:
          return null;
      }
    },
  );
}

/// never-empty 계약(ADR-009): 렌더 가능한 콘텐츠가 하나도 없으면 true.
///
/// 시각 요소(`<img>`/`<svg>`/`<image>`/`<math>`)가 있으면 비어있지 않다. 없으면
/// 태그·공백 엔티티를 제거해 실제 텍스트가 남는지 본다. (F2 빈 렌더 재발 방지)
bool _isBlankContent(String html) {
  final lower = html.toLowerCase();
  if (lower.contains('<img') ||
      lower.contains('<svg') ||
      lower.contains('<image') ||
      lower.contains('<math')) {
    return false;
  }
  final text = html
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAll(RegExp(r'&nbsp;|&#160;|&#xa0;', caseSensitive: false), ' ')
      .trim();
  return text.isEmpty;
}

@visibleForTesting
class RemoteImageState extends State<_RemoteImage> {
  late Future<Uint8List?> _load;

  @override
  void initState() {
    super.initState();
    _load = _resolve();
  }

  Future<Uint8List?> _resolve() async {
    final loader = widget.loader;
    if (loader == null) return null;
    try {
      return await loader(widget.src);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 32,
            width: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final bytes = snap.data;
        if (bytes == null) {
          return _ImagePlaceholder(reason: 'image load failed', alt: widget.alt);
        }
        return Image.memory(
          bytes,
          errorBuilder: (_, __, ___) =>
              _ImagePlaceholder(reason: 'image decode failed', alt: widget.alt),
        );
      },
    );
  }
}

class _RemoteImage extends StatefulWidget {
  const _RemoteImage({required this.src, required this.loader, this.alt});
  final String src;
  final ImageLoader? loader;

  /// `<img alt>` — 로드 실패 시 아이콘 대신/함께 표시할 대체 텍스트.
  final String? alt;

  @override
  State<_RemoteImage> createState() => RemoteImageState();
}

/// 이미지 로드 실패·미지원 콘텐츠의 placeholder. never-empty 계약(ADR-009):
/// [alt] 텍스트가 있으면 아이콘과 함께 표시해 공백을 남기지 않는다.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.reason, this.alt});
  final String reason;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final altText = alt?.trim();
    final hasAlt = altText != null && altText.isNotEmpty;
    return Semantics(
      label: hasAlt ? altText : 'image placeholder ($reason)',
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: scheme.onSurfaceVariant,
            ),
            if (hasAlt) ...[
              const SizedBox(height: 8),
              Text(
                altText,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// MathML → TeX 변환 결과를 flutter_math_fork로 렌더한다(S14.2, gap #5).
/// TeX 파싱/빌드 실패 시 [Math.tex]의 onErrorFallback이 [_FormulaPlaceholder]로
/// 폴백해 never-empty 계약(ADR-009)을 유지한다.
class _MathFormula extends StatelessWidget {
  const _MathFormula({required this.tex, required this.fontSize, this.alt});

  final String tex;
  final double fontSize;

  /// alttext — 렌더 실패 시 placeholder에 표시할 대체 텍스트.
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final altText = alt?.trim();
    return Semantics(
      label: (altText != null && altText.isNotEmpty) ? altText : '수식',
      child: Math.tex(
        tex,
        mathStyle: MathStyle.text,
        textStyle: TextStyle(fontSize: fontSize),
        onErrorFallback: (_) => _FormulaPlaceholder(alt: alt),
      ),
    );
  }
}

/// `<math>`(MathML) placeholder. 변환/렌더 실패 시 never-empty 계약상 공백 대신
/// [alt](alttext)나 "수식" 안내를 표시한다. (S14.2)
class _FormulaPlaceholder extends StatelessWidget {
  const _FormulaPlaceholder({this.alt});
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final altText = alt?.trim();
    final label = (altText != null && altText.isNotEmpty) ? altText : '수식';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.functions, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// never-empty 계약(ADR-009): 렌더 가능한 콘텐츠가 전혀 없는 spine에 표시되는
/// 안내. 빈 화면(공백) 대신 사용자에게 상태를 명확히 알린다.
class _BlankContentNotice extends StatelessWidget {
  const _BlankContentNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          '이 페이지에는 표시할 내용이 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '본문을 불러올 수 없습니다.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
