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
  });

  final EpubBook book;
  final XhtmlLoader xhtmlLoader;
  final ImageLoader? imageLoader;
  final int initialSpineIndex;
  final double fontSize;
  final double lineHeight;
  final PaginationStrategy paginationStrategy;
  final ValueChanged<int>? onPageChanged;

  @override
  State<ReflowablePageView> createState() => ReflowablePageViewState();
}

@visibleForTesting
class ReflowablePageViewState extends State<ReflowablePageView> {
  late PageController _controller;
  late int _pageIndex;

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
  }

  @override
  void didUpdateWidget(ReflowablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // fontSize/lineHeight만 바뀐 경우 PageController/page는 그대로 유지.
    // book이 바뀌면 controller 재생성.
    if (oldWidget.book != widget.book) {
      _pageIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _controller.dispose();
      _controller = PageController(initialPage: _pageIndex);
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
      itemBuilder: (context, index) {
        final spineItem = widget.book.spine[index];
        return FutureBuilder<String>(
          future: widget.xhtmlLoader(spineItem.href),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: buildReflowableHtml(
                data: snap.data ?? '',
                fontSize: widget.fontSize,
                lineHeight: widget.lineHeight,
                imageLoader: widget.imageLoader,
              ),
            );
          },
        );
      },
    );
  }
}
