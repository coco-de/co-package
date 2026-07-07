// Presentation Engine — open_epub 1.0
// Story: S1.6 (#12) — Reflowable 페이지뷰
// BDD: F2.2 (글자 크기), F2.3 (줄간격), F2.4 (페이지 전환 ≤ 150ms)
//
// spine 단위 PageView + 화면 단위 윈도잉 기반 페이지 모드 (open-epub#221).
// spine(chapter) 콘텐츠는 한 번만 렌더링하고, 실제 렌더 높이를 측정해
// [OverflowBox]+[Transform.translate]로 화면 높이만큼의 "창"만 보여준다 —
// 텍스트를 실제로 재분할하지 않으므로 이미지·표·링크가 그대로 유지된다.
// 화면 하나(윈도우)가 좌우 스와이프 1회에 대응하고, spine의 첫/마지막
// 윈도우에서 계속 스와이프하면 다음/이전 spine으로 자연스럽게 넘어간다.
// 문단이 윈도우 경계에서 그대로 잘릴 수 있음(스크롤이 아닌 절단).
//
// spine 간 이동은 여전히 [PageView]가 담당하지만, 사용자 스와이프는 윈도우
// 이동과 spine 이동을 함께 판단해야 하므로 PageView 자체의 드래그
// (physics)는 끄고 최상위 [GestureDetector] 하나가 두 이동을 모두 구동한다
// (같은 축의 중첩 PageView 제스처 경합을 피하기 위함).
//
// 글자 크기·줄간격 변경 시 현재 spineIndex가 보존된다 (PageController.page
// 유지 + Html style만 갱신, 윈도우 수는 새 크기로 재측정).

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'pagination_strategy.dart';
import 'reflowable_engine.dart';

class ReflowablePageView extends StatefulWidget {
  const ReflowablePageView({
    super.key,
    required this.book,
    required this.xhtmlLoader,
    this.imageLoader,
    this.initialSpineIndex = 0,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.paginationStrategy = const SinglePagePerSpineStrategy(),
    this.onPageChanged,
    this.onLinkTap,
    this.onNavigatorReady,
    this.onPageStepReady,
    this.onWindowChanged,
    this.contentRevision,
    this.reverse = false,
    this.forceVertical = false,
  });

  final EpubBook book;
  final XhtmlLoader xhtmlLoader;
  final ImageLoader? imageLoader;
  final int initialSpineIndex;
  final double fontSize;
  final double lineHeight;

  /// 미사용 — 화면 단위 윈도잉(open-epub#221)은 [PaginationStrategy] 없이
  /// 렌더 높이 측정으로 직접 처리한다. 향후 정밀 페이지네이션(문단 단위 재분할)
  /// 도입 시 재사용을 위해 필드만 유지.
  final PaginationStrategy paginationStrategy;
  final ValueChanged<int>? onPageChanged;

  /// 우→좌 진행(RTL, `page-progression-direction=rtl`). true면 PageView 스크롤
  /// 방향을 반전해 다음 페이지가 왼쪽에서 나타난다. 페이지 인덱스 계약(다음=+1)은
  /// 불변이며 시각적 방향만 바뀐다. (S14.1, gap #4)
  final bool reverse;

  /// 세로쓰기 강제 — 단순 텍스트 spine을 [VerticalTextBlock]으로 렌더. (S15.4)
  final bool forceVertical;

  /// 본문 링크/하이라이트 탭 콜백. (S7.3/S7.5)
  final EpubLinkTapCallback? onLinkTap;

  /// 마운트 시 페이지 이동 함수(goToPage)를 부모에게 넘긴다 — 부모(EpubReader)가
  /// EpubViewController에 연결해 prev/next 등 프로그램적 내비게이션을 제공. (S8.1)
  final void Function(Future<void> Function(int index) goToPage)?
      onNavigatorReady;

  /// 마운트 시 "한 페이지(윈도우) 이동" 함수([_advance])를 부모에게 넘긴다 —
  /// [onNavigatorReady](spine 단위 goToPage)와 별개로, EpubViewController의
  /// nextPage()/previousPage()가 spine 전체가 아닌 화면 단위 윈도우로 이동하게
  /// 한다. 인자는 +1(다음)/-1(이전). (open-epub#221 후속 — 페이지 버튼이
  /// 챕터 단위로 건너뛰던 문제)
  final void Function(Future<void> Function(int direction) step)?
      onPageStepReady;

  /// (spine 인덱스, 윈도우 인덱스, 현재 spine의 윈도우 수)가 바뀔 때마다
  /// 호출된다 — 부모(EpubReader)가 EpubViewController.syncState에 윈도우
  /// 정보를 함께 반영해 hasNext/hasPrevious/windowIndex/windowCount가 화면
  /// 단위 윈도잉을 정확히 반영하도록 한다. 마운트 시 초기값(측정 전)으로도
  /// 한 번 호출되고, 측정 완료·윈도우 이동·spine 전환마다 다시 호출된다.
  /// (open-epub#228 — 이전엔 창 이동이 controller에 전혀 반영되지 않아
  /// hasNext 등이 stale했다)
  final void Function(int spineIndex, int windowIndex, int windowCount)?
      onWindowChanged;

  /// [xhtmlLoader] 결과에 영향을 주는 외부 상태의 revision(예: 하이라이트
  /// 목록). identity가 바뀌면 캐시된 spine XHTML을 버리고 다시 로드한다.
  /// (open-epub#62)
  final Object? contentRevision;

  @override
  State<ReflowablePageView> createState() => ReflowablePageViewState();
}

@visibleForTesting
class ReflowablePageViewState extends State<ReflowablePageView> {
  late PageController _controller;
  late int _pageIndex;

  /// 현재 spine 내 윈도우(화면 단위 페이지) 인덱스. spine 콘텐츠가 화면보다
  /// 길면 0..[windowCount)-1 사이를 좌우 스와이프로 이동한다. (open-epub#221)
  int _windowIndex = 0;

  /// spine별 측정된 윈도우 수 캐시. 아직 측정 전이면 1(창 없음)로 취급.
  final Map<int, int> _windowCounts = {};

  /// spine 경계를 넘는 스와이프(`_advance`) 직후, 대상 spine에 착지할 윈도우
  /// 인덱스를 한 번만 소비하기 위한 슬롯. 프로그램적 이동(controller 등)은
  /// 항상 0으로 착지한다.
  int? _pendingLandingWindow;

  /// spine 경계를 넘는(비동기) 이동이 진행 중인지 — 진행 중에 또 다른 이동
  /// 요청(중복 탭/스와이프)이 오면 무시해, 애니메이션 도중 재진입해 동일
  /// 목표로 두 번째 이동이 겹쳐 걸리는 것을 막는다. 같은 spine 내 윈도우
  /// 이동(동기)은 이 가드가 필요 없다. (open-epub#228)
  bool _crossingSpine = false;

  static const double _swipeVelocityThreshold = 250;

  /// spine href별 XHTML 로드 future 캐시 — 매 rebuild마다 loader를 재호출해
  /// FutureBuilder가 스피너로 리셋되던 안티패턴 해소. (open-epub#62)
  final Map<String, Future<String>> _loads = {};

  int get pageIndex => _pageIndex;
  int get pageCount => widget.book.spine.length;

  /// 현재 spine 내 윈도우 인덱스(0-based). 테스트 전용 노출.
  @visibleForTesting
  int get windowIndex => _windowIndex;

  /// 현재 spine의 측정된 윈도우 수(아직 미측정이면 1). 테스트 전용 노출.
  @visibleForTesting
  int get windowCount => _windowCounts[_pageIndex] ?? 1;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    _controller = PageController(initialPage: _pageIndex);
    widget.onNavigatorReady?.call(goToPage);
    widget.onPageStepReady?.call(_advance);
    // 측정 전 초기값(윈도우 0/1개)으로 우선 보고 — 측정이 끝나면
    // _handleWindowMeasured가 정확한 windowCount로 다시 보고한다.
    _reportWindowState();
  }

  /// 현재 (spine, 윈도우 인덱스, 윈도우 수)를 부모에 보고한다 — 측정 완료·
  /// 윈도우 이동·spine 전환마다 호출해 EpubViewController의
  /// hasNext/hasPrevious/windowIndex/windowCount를 최신 상태로 유지한다.
  /// (open-epub#228)
  void _reportWindowState() {
    widget.onWindowChanged?.call(_pageIndex, _windowIndex, windowCount);
  }

  @override
  void didUpdateWidget(ReflowablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // fontSize/lineHeight만 바뀐 경우 PageController/page는 그대로 유지.
    // book이 바뀌면 controller 재생성.
    if (oldWidget.book != widget.book) {
      _loads.clear();
      _windowCounts.clear();
      _windowIndex = 0;
      _pageIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _controller.dispose();
      _controller = PageController(initialPage: _pageIndex);
      _reportWindowState();
      return;
    }
    if (!identical(oldWidget.contentRevision, widget.contentRevision)) {
      // 하이라이트 등 콘텐츠 revision 변경 — 캐시를 버리고 재로드. 각 페이지는
      // 재로드 동안 직전 콘텐츠를 유지한다(_SpinePageView). (open-epub#62)
      _loads.clear();
      _windowCounts.clear();
    }
    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.lineHeight != widget.lineHeight) {
      // 글자 크기·줄간격이 바뀌면 렌더 높이가 달라지므로 윈도우 수를
      // 재측정한다 — 이전 윈도우 경계는 새 크기에서 더 이상 유효하지 않다.
      _windowCounts.clear();
      _windowIndex = 0;
      _reportWindowState();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 페이지 이동 (animation). animation 종료를 기다리려면 반환 Future를 await.
  /// 항상 대상 spine의 첫 윈도우(0)로 착지한다.
  Future<void> goToPage(int index) async {
    if (index < 0 || index >= pageCount) return;
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  /// 즉시 페이지 이동 (animation 없음). 테스트·외부 직접 점프 시 유리.
  void jumpToPage(int index) {
    if (index < 0 || index >= pageCount) return;
    _controller.jumpToPage(index);
  }

  Future<void> nextPage() => goToPage(_pageIndex + 1);
  Future<void> previousPage() => goToPage(_pageIndex - 1);

  Future<String> _loadSpine(String href) =>
      _loads.putIfAbsent(href, () => widget.xhtmlLoader(href));

  void _handleWindowMeasured(int spineIndex, int measuredCount) {
    if (!mounted || _windowCounts[spineIndex] == measuredCount) return;
    _windowCounts[spineIndex] = measuredCount;
    if (spineIndex != _pageIndex) return;
    if (_windowIndex >= measuredCount) {
      setState(() => _windowIndex = measuredCount - 1);
    }
    _reportWindowState();
  }

  /// 좌우 스와이프 종료 시 윈도우/spine 이동을 함께 판단한다. 같은 축으로
  /// 중첩된 PageView 제스처 경합을 피하기 위해 [PageView] 자체 드래그는
  /// 꺼두고(physics) 이 한 곳에서만 이동을 구동한다. (open-epub#221)
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity.abs() < _swipeVelocityThreshold) return;
    final swipedLeft = velocity < 0;
    // reverse(RTL)면 스와이프 방향의 의미가 반전된다(다음=좌향 진행이 아닌
    // 우향 진행). fixed_layout_page의 rightToLeft 처리와 동일 원칙. (S14.1)
    final forward = widget.reverse ? !swipedLeft : swipedLeft;
    unawaited(_advance(forward ? 1 : -1));
  }

  /// [direction] = +1(다음)/-1(이전)로 한 윈도우 이동한다. 현재 spine의
  /// 윈도우 범위를 벗어나면 다음/이전 spine으로 넘어가 그 spine의 첫(다음
  /// 방향) 또는 마지막(이전 방향, 캐시된 경우) 윈도우에 착지한다.
  Future<void> _advance(int direction) async {
    final count = _windowCounts[_pageIndex] ?? 1;
    final next = _windowIndex + direction;
    if (next >= 0 && next < count) {
      setState(() => _windowIndex = next);
      _reportWindowState();
      return;
    }
    // 이미 진행 중인 spine 전환(애니메이션)이 있으면 중복 요청은 무시한다 —
    // 없으면 빠른 연속 탭/스와이프가 같은 목표로 두 번 걸려 하나를 삼킨다.
    // (open-epub#228)
    if (_crossingSpine) return;
    final targetSpine = _pageIndex + direction;
    if (targetSpine < 0 || targetSpine >= pageCount) return;
    _crossingSpine = true;
    _pendingLandingWindow =
        direction > 0 ? 0 : (_windowCounts[targetSpine] ?? 1) - 1;
    try {
      await goToPage(targetSpine);
    } finally {
      _crossingSpine = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.spine.isEmpty) {
      return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = constraints.biggest;
        return GestureDetector(
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: PageView.builder(
            controller: _controller,
            reverse: widget.reverse,
            // 스와이프는 위 GestureDetector가 전담(윈도우/spine 이동 통합
            // 판단) — PageView 자체 드래그는 꺼서 같은 축 제스처 경합을 막는다.
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageCount,
            onPageChanged: (i) {
              setState(() {
                _pageIndex = i;
                _windowIndex = _pendingLandingWindow ?? 0;
                _pendingLandingWindow = null;
              });
              widget.onPageChanged?.call(i);
              _reportWindowState();
            },
            itemBuilder: (context, index) => _SpinePageView(
              // 같은 href가 spine에 중복 등장할 수 있어 index로 구분.
              key: ValueKey('reflowable-page-$index'),
              load: _loadSpine(widget.book.spine[index].href),
              baseHref: widget.book.spine[index].href,
              fontSize: widget.fontSize,
              lineHeight: widget.lineHeight,
              imageLoader: widget.imageLoader,
              onLinkTap: widget.onLinkTap,
              forceVertical: widget.forceVertical,
              viewportSize: viewportSize,
              windowIndex: index == _pageIndex ? _windowIndex : 0,
              onWindowCountMeasured: (count) =>
                  _handleWindowMeasured(index, count),
            ),
          ),
        );
      },
    );
  }
}

/// 단일 spine 페이지 뷰 — spine 콘텐츠를 한 번 렌더링해 실제 높이를 측정하고,
/// [OverflowBox]+[Transform.translate]로 화면 크기([viewportSize]) 만큼의
/// "윈도우"만 잘라 보여준다(open-epub#221). 텍스트를 재분할하지 않으므로
/// 이미지·표·링크는 그대로 유지되며, 문단은 윈도우 경계에서 시각적으로 잘릴
/// 수 있다(스크롤이 아닌 절단 — 다음 윈도우로 스와이프해야 이어서 보인다).
///
/// 콘텐츠 revision 변경으로 [load]가 교체되면 새 로드가 끝날 때까지 직전
/// 콘텐츠를 유지한다(스피너 flash 방지). (open-epub#62)
class _SpinePageView extends StatefulWidget {
  const _SpinePageView({
    super.key,
    required this.load,
    required this.baseHref,
    required this.fontSize,
    required this.lineHeight,
    required this.imageLoader,
    required this.onLinkTap,
    required this.forceVertical,
    required this.viewportSize,
    required this.windowIndex,
    required this.onWindowCountMeasured,
  });

  final Future<String> load;

  /// 이 spine 문서의 OPF 기준 href — 본문 내 상대 리소스(`<img>`) 해석 기준.
  final String baseHref;
  final double fontSize;
  final double lineHeight;
  final ImageLoader? imageLoader;
  final EpubLinkTapCallback? onLinkTap;
  final bool forceVertical;

  /// 화면(페이지) 크기 — 이 크기만큼씩 콘텐츠를 잘라 보여준다.
  final Size viewportSize;

  /// 지금 보여줄 윈도우 인덱스(0-based).
  final int windowIndex;

  /// 콘텐츠 전체 높이 측정이 끝나면(또는 갱신되면) 호출 — 윈도우 수 =
  /// `ceil(측정높이 / viewportSize.height)`.
  final ValueChanged<int> onWindowCountMeasured;

  @override
  State<_SpinePageView> createState() => _SpinePageViewState();
}

class _SpinePageViewState extends State<_SpinePageView> {
  /// 마지막으로 성공 로드된 XHTML — 재로드 동안 표시 유지용.
  String? _lastData;

  /// 콘텐츠 실제 렌더 높이 측정용 키. 패딩을 포함한 전체 콘텐츠에 부착한다.
  final GlobalKey _measureKey = GlobalKey();
  double? _measuredHeight;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.load,
      builder: (context, snap) {
        if (snap.hasData) _lastData = snap.data;
        final data = snap.hasData ? snap.data : _lastData;
        if (data == null) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '본문을 불러올 수 없습니다.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        // SizeChangedLayoutNotifier로 감싸 콘텐츠 실제 렌더 높이가 바뀔 때마다
        // 알림을 받는다 — 이미지가 placeholder(32x32)로 먼저 그려졌다가 비동기
        // 로드 후 실제 크기로 바뀌는 경우처럼, 이 위젯이 다시 build되지 않아도
        // (오직 하위 _RemoteImage만 rebuild) 레이아웃 크기는 바뀌므로 재측정이
        // 필요하다. 이게 없으면 이미지가 있는 spine에서 윈도우 수가 과소
        // 측정돼 뒷부분 콘텐츠에 영영 스와이프로 도달할 수 없다.
        final content = SizeChangedLayoutNotifier(
          key: _measureKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: buildReflowableHtml(
              data: data,
              baseHref: widget.baseHref,
              fontSize: widget.fontSize,
              lineHeight: widget.lineHeight,
              imageLoader: widget.imageLoader,
              onLinkTap: widget.onLinkTap,
              forceVertical: widget.forceVertical,
            ),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

        final viewportWidth = widget.viewportSize.width;
        final viewportHeight = widget.viewportSize.height;
        return NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (notification) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
            return false;
          },
          child: ClipRect(
            child: SizedBox(
              width: viewportWidth,
              height: viewportHeight,
              child: OverflowBox(
                minWidth: viewportWidth,
                maxWidth: viewportWidth,
                minHeight: 0,
                maxHeight: double.infinity,
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: Offset(0, -widget.windowIndex * viewportHeight),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 콘텐츠(패딩 포함) 렌더 높이를 읽어 윈도우 수를 계산해 보고한다. 초기
  /// 빌드 후(post-frame)와 [SizeChangedLayoutNotification] 수신 시(비동기
  /// 이미지 로드 등으로 렌더 높이가 바뀔 때) 모두 호출된다. 결과가 같으면
  /// [onWindowCountMeasured]를 다시 호출하지 않으므로(부모의 캐시 비교)
  /// 반복 호출 비용이 크지 않다.
  void _measure() {
    if (!mounted) return;
    final renderObject = _measureKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final height = renderObject.size.height;
    if (height == _measuredHeight) return;
    _measuredHeight = height;
    final viewportHeight = widget.viewportSize.height;
    final windowCount = viewportHeight <= 0
        ? 1
        : (height / viewportHeight).ceil().clamp(1, 1 << 20).toInt();
    widget.onWindowCountMeasured(windowCount);
  }
}
