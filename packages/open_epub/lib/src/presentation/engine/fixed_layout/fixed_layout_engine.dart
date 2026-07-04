// Presentation Engine — open_epub 1.0
// Story: S1.7 (#13) — Fixed Layout 엔진 + viewport fit (단일 페이지)
// Story: S1.8 (#14) — 핀치 줌 (FixedLayoutPage에 통합 완료)
// Story: S1.9 (#15) — spread 자동 분기 (1/2-page) + page-spread-left/right
// kobic#7576 — 페이지 내비게이션(스와이프·jumpToSpine·onSpineChanged) 배선
// BDD: F3 (Fixed Layout 본문 렌더링)
//
// 본 engine은:
// - 단일 페이지 1-page 모드 (S1.7)
// - 줌은 FixedLayoutPage가 책임 (S1.8)
// - spread 모드 (2-page) — screen width + rendition:spread에 따라 자동 분기,
//   page-spread-left/right 슬롯 존중 (S1.9, BDD F3.3/F3.5)
// - 페이지 넘김 — 수평 스와이프(줌 1.0x일 때) + [FixedLayoutEngineState.jumpToSpine]
//   프로그램적 이동. spread 렌더 중에는 row 단위로 이동한다 (kobic#7576)

import 'package:flutter/material.dart';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'fixed_layout_page.dart';
import 'fixed_layout_spread.dart';
import 'viewport_fitter.dart';

/// Fixed Layout 페이지 데이터. [FixedLayoutPageBuilder]가 반환한다.
class FixedLayoutPageData {
  const FixedLayoutPageData({
    required this.logicalSize,
    required this.content,
  });

  /// EPUB 메타 또는 페이지 XHTML viewport 속성으로 결정된 논리 크기.
  final Size logicalSize;

  /// 페이지 콘텐츠 widget (SVG/Image/XHTML 등).
  final Widget content;
}

typedef FixedLayoutPageBuilder = Future<FixedLayoutPageData> Function(
  EpubSpineItem item,
);

/// fixed-layout 페이지 콘텐츠를 논리 좌표 공간에서 감싸는 빌더(open-board
/// 절대좌표 필기 캔버스가 [content]를 child로 받는 용도 등, S8.6). [item]은 해당
/// spine, [logicalSize]는 페이지 논리 크기(=절대좌표 공간), [content]는 원본
/// 페이지 위젯.
typedef FixedLayoutContentBuilder = Widget Function(
  BuildContext context,
  EpubSpineItem item,
  Size logicalSize,
  Widget content,
);

class FixedLayoutEngine extends StatefulWidget {
  const FixedLayoutEngine({
    super.key,
    required this.book,
    required this.pageBuilder,
    this.initialSpineIndex = 0,
    this.fitter = const ViewportFitter(),
    this.spreadOverride,
    this.contentBuilder,
    this.enableZoom = true,
    this.onSpineChanged,
    this.onNavigatorReady,
    this.rightToLeft = false,
  });

  final EpubBook book;
  final FixedLayoutPageBuilder pageBuilder;
  final int initialSpineIndex;
  final ViewportFitter fitter;

  /// 우→좌 진행(RTL, `page-progression-direction=rtl`). true면 2-page spread
  /// 내부 좌우 배치를 뒤집고(먼저 읽는 페이지가 오른쪽), 수평 스와이프→페이지
  /// 매핑을 반전한다(오른쪽 스와이프=다음). (S14.1, gap #4)
  final bool rightToLeft;

  /// 표시 spine이 바뀔 때 호출된다(스와이프·프로그램적 이동). 인자는 새 spine
  /// 인덱스(0-based). 호스트가 세션 위치·진행률 동기화에 사용 (kobic#7576).
  final ValueChanged<int>? onSpineChanged;

  /// 프로그램적 spine 이동 함수를 호스트에 넘겨준다 — [ReflowablePageView]의
  /// onNavigatorReady와 동일 패턴(`EpubViewController.attachNavigator` 시그니처).
  final void Function(Future<void> Function(int index) navigate)?
      onNavigatorReady;

  /// null이면 [EpubBook.metadata.spread]를 사용. 테스트 / 사용자 설정으로
  /// 강제 변경하려면 [EpubSpread]를 명시 (예: [EpubSpread.none]).
  final EpubSpread? spreadOverride;

  /// 각 페이지 콘텐츠를 논리 좌표 공간에서 감싼다(필기 등). null이면 원본 그대로.
  /// 반환 위젯의 로컬 좌표가 곧 페이지 절대좌표이며 fit·zoom·pan과 함께 변환된다(S8.6).
  final FixedLayoutContentBuilder? contentBuilder;

  /// false면 페이지 줌/팬을 비활성화한다(드로잉 중 pan 충돌 방지). default true.
  final bool enableZoom;

  @override
  State<FixedLayoutEngine> createState() => FixedLayoutEngineState();
}

@visibleForTesting
class FixedLayoutEngineState extends State<FixedLayoutEngine> {
  late int _spineIndex;
  List<SpreadRow> _spreadRows = const [];
  int _rowIndex = 0;

  /// 마지막 build가 2-page spread로 렌더했는지 — 페이지 이동 단위(row/spine)
  /// 결정에 사용한다 (kobic#7576).
  bool _renderedSpread = false;

  int get spineIndex => _spineIndex;
  int get spineCount => widget.book.spine.length;
  int get rowIndex => _rowIndex;
  int get rowCount => _spreadRows.length;

  EpubSpread get effectiveSpread =>
      widget.spreadOverride ?? widget.book.metadata.spread;

  @override
  void initState() {
    super.initState();
    _spineIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    _spreadRows = buildSpreadRows(
      widget.book.spine,
      rightToLeft: widget.rightToLeft,
    );
    _rowIndex = _findRowIndexForSpine(_spineIndex);
    widget.onNavigatorReady?.call((index) async => jumpToSpine(index));
  }

  @override
  void didUpdateWidget(FixedLayoutEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) {
      _spineIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _spreadRows = buildSpreadRows(
        widget.book.spine,
        rightToLeft: widget.rightToLeft,
      );
      _rowIndex = _findRowIndexForSpine(_spineIndex);
    } else if (oldWidget.rightToLeft != widget.rightToLeft) {
      // 방향만 토글 — 현재 위치는 유지하고 row 좌우 배치만 다시 구성한다.
      _spreadRows = buildSpreadRows(
        widget.book.spine,
        rightToLeft: widget.rightToLeft,
      );
      _rowIndex = _findRowIndexForSpine(_spineIndex);
    }
  }

  int _findRowIndexForSpine(int spineIdx) {
    if (widget.book.spine.isEmpty) return 0;
    final target = widget.book.spine[spineIdx];
    for (var i = 0; i < _spreadRows.length; i++) {
      final r = _spreadRows[i];
      if (r.center == target || r.left == target || r.right == target) {
        return i;
      }
    }
    return 0;
  }

  /// spine 인덱스를 갱신하고 호스트에 통지한다. 모든 이동 경로의 단일 진입점.
  void _setSpine(int index) {
    setState(() {
      _spineIndex = index;
      _rowIndex = _findRowIndexForSpine(index);
    });
    widget.onSpineChanged?.call(index);
  }

  /// [index] spine으로 이동한다(범위 클램프). 동일 인덱스면 no-op.
  /// spread 렌더 중이면 해당 spine이 속한 row가 표시된다 (kobic#7576).
  void jumpToSpine(int index) {
    if (widget.book.spine.isEmpty) return;
    final clamped = index.clamp(0, spineCount - 1);
    if (clamped == _spineIndex) return;
    _setSpine(clamped);
  }

  bool nextSpine() {
    if (_spineIndex >= spineCount - 1) return false;
    _setSpine(_spineIndex + 1);
    return true;
  }

  bool previousSpine() {
    if (_spineIndex <= 0) return false;
    _setSpine(_spineIndex - 1);
    return true;
  }

  /// 다음 표시 단위로 이동 — spread 렌더 중이면 다음 row(한 스와이프에 두
  /// 페이지), 아니면 다음 spine (kobic#7576).
  bool nextPage() {
    if (_renderedSpread && _spreadRows.isNotEmpty) {
      return _jumpToRow(_rowIndex + 1);
    }
    return nextSpine();
  }

  /// 이전 표시 단위로 이동 — [nextPage]와 대칭.
  bool previousPage() {
    if (_renderedSpread && _spreadRows.isNotEmpty) {
      return _jumpToRow(_rowIndex - 1);
    }
    return previousSpine();
  }

  bool _jumpToRow(int rowIdx) {
    if (rowIdx < 0 || rowIdx >= _spreadRows.length) return false;
    final row = _spreadRows[rowIdx];
    final target = row.center ?? row.left ?? row.right;
    if (target == null) return false;
    final idx = widget.book.spine.indexOf(target);
    if (idx < 0) return false;
    _setSpine(idx);
    return true;
  }

  /// FixedLayoutPage가 줌 1.0x에서 감지한 수평 fling. LTR은 좌 fling=다음,
  /// RTL([rightToLeft])은 우 fling=다음으로 반전한다. (S14.1, gap #4)
  void _onSwipeLeft() => widget.rightToLeft ? previousPage() : nextPage();

  void _onSwipeRight() => widget.rightToLeft ? nextPage() : previousPage();

  @override
  Widget build(BuildContext context) {
    if (widget.book.spine.isEmpty) {
      return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final useSpread = widget.fitter.shouldUseTwoPageSpread(
          screenWidth: constraints.maxWidth,
          screenHeight: constraints.maxHeight,
          spread: effectiveSpread,
        );
        _renderedSpread = useSpread && _spreadRows.isNotEmpty;

        if (!_renderedSpread) {
          return _buildSinglePage(widget.book.spine[_spineIndex]);
        }

        final row = _spreadRows[_rowIndex.clamp(0, _spreadRows.length - 1)];
        return FixedLayoutSpreadRow(
          row: row,
          pageBuilder: _buildSinglePage,
        );
      },
    );
  }

  Widget _buildSinglePage(EpubSpineItem item) {
    return _AsyncFixedLayoutPage(
      key: ValueKey(item.idref),
      item: item,
      pageBuilder: widget.pageBuilder,
      fitter: widget.fitter,
      contentBuilder: widget.contentBuilder,
      enableZoom: widget.enableZoom,
      onSwipeLeft: _onSwipeLeft,
      onSwipeRight: _onSwipeRight,
    );
  }
}

class _AsyncFixedLayoutPage extends StatefulWidget {
  const _AsyncFixedLayoutPage({
    super.key,
    required this.item,
    required this.pageBuilder,
    required this.fitter,
    this.contentBuilder,
    this.enableZoom = true,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  final EpubSpineItem item;
  final FixedLayoutPageBuilder pageBuilder;
  final ViewportFitter fitter;
  final FixedLayoutContentBuilder? contentBuilder;
  final bool enableZoom;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  @override
  State<_AsyncFixedLayoutPage> createState() => _AsyncFixedLayoutPageState();
}

class _AsyncFixedLayoutPageState extends State<_AsyncFixedLayoutPage> {
  late Future<FixedLayoutPageData> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.pageBuilder(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FixedLayoutPageData>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '페이지를 불러올 수 없습니다.\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final page = snap.data!;
        final wrap = widget.contentBuilder;
        return FixedLayoutPage(
          logicalSize: page.logicalSize,
          content: page.content,
          fitter: widget.fitter,
          enableZoom: widget.enableZoom,
          onSwipeLeft: widget.onSwipeLeft,
          onSwipeRight: widget.onSwipeRight,
          contentBuilder: wrap == null
              ? null
              : (ctx, logicalSize, content) =>
                  wrap(ctx, widget.item, logicalSize, content),
        );
      },
    );
  }
}
