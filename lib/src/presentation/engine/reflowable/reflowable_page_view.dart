// Presentation Engine — open_epub 1.0
// Story: S1.6 (#12) — Reflowable 페이지뷰
// BDD: F2.2 (글자 크기), F2.3 (줄간격), F2.4 (페이지 전환 ≤ 150ms)
//
// spine 단위 PageView 기반 페이지 모드. 한 spine = 한 페이지 (default
// SinglePagePerSpineStrategy). 실제 viewport 분할 페이지네이션은 추후
// 더 정교한 PaginationStrategy로 추가 예정 (S4.10 성능 벤치와 함께).
//
// 글자 크기·줄간격 변경 시 현재 spineIndex가 보존된다 (PageController.page
// 유지 + Html style만 갱신).

import 'package:flutter/material.dart';

import '../../../api/epub_book.dart';
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
    this.contentRevision,
  });

  final EpubBook book;
  final XhtmlLoader xhtmlLoader;
  final ImageLoader? imageLoader;
  final int initialSpineIndex;
  final double fontSize;
  final double lineHeight;
  final PaginationStrategy paginationStrategy;
  final ValueChanged<int>? onPageChanged;

  /// 본문 링크/하이라이트 탭 콜백. (S7.3/S7.5)
  final EpubLinkTapCallback? onLinkTap;

  /// 마운트 시 페이지 이동 함수(goToPage)를 부모에게 넘긴다 — 부모(EpubReader)가
  /// EpubViewController에 연결해 prev/next 등 프로그램적 내비게이션을 제공. (S8.1)
  final void Function(Future<void> Function(int index) goToPage)?
      onNavigatorReady;

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

  /// spine href별 XHTML 로드 future 캐시 — 매 rebuild마다 loader를 재호출해
  /// FutureBuilder가 스피너로 리셋되던 안티패턴 해소. (open-epub#62)
  final Map<String, Future<String>> _loads = {};

  int get pageIndex => _pageIndex;
  int get pageCount => widget.book.spine.length;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    _controller = PageController(initialPage: _pageIndex);
    widget.onNavigatorReady?.call(goToPage);
  }

  @override
  void didUpdateWidget(ReflowablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // fontSize/lineHeight만 바뀐 경우 PageController/page는 그대로 유지.
    // book이 바뀌면 controller 재생성.
    if (oldWidget.book != widget.book) {
      _loads.clear();
      _pageIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _controller.dispose();
      _controller = PageController(initialPage: _pageIndex);
    } else if (!identical(oldWidget.contentRevision, widget.contentRevision)) {
      // 하이라이트 등 콘텐츠 revision 변경 — 캐시를 버리고 재로드. 각 페이지는
      // 재로드 동안 직전 콘텐츠를 유지한다(_SpinePageView). (open-epub#62)
      _loads.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 페이지 이동 (animation). animation 종료를 기다리려면 반환 Future를 await.
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

  @override
  Widget build(BuildContext context) {
    if (widget.book.spine.isEmpty) {
      return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
    }

    return PageView.builder(
      controller: _controller,
      itemCount: pageCount,
      onPageChanged: (i) {
        setState(() => _pageIndex = i);
        widget.onPageChanged?.call(i);
      },
      itemBuilder: (context, index) => _SpinePageView(
        // 같은 href가 spine에 중복 등장할 수 있어 index로 구분.
        key: ValueKey('reflowable-page-$index'),
        load: _loadSpine(widget.book.spine[index].href),
        fontSize: widget.fontSize,
        lineHeight: widget.lineHeight,
        imageLoader: widget.imageLoader,
        onLinkTap: widget.onLinkTap,
      ),
    );
  }
}

/// 단일 spine 페이지 뷰 — 콘텐츠 revision 변경으로 [load]가 교체되면 새 로드가
/// 끝날 때까지 직전 콘텐츠를 유지한다(스피너 flash 방지). (open-epub#62)
class _SpinePageView extends StatefulWidget {
  const _SpinePageView({
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
  State<_SpinePageView> createState() => _SpinePageViewState();
}

class _SpinePageViewState extends State<_SpinePageView> {
  /// 마지막으로 성공 로드된 XHTML — 재로드 동안 표시 유지용.
  String? _lastData;

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
        return SingleChildScrollView(
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
