// Presentation Engine — open_epub 1.0
// Story: S1.7 (#13) — Fixed Layout 엔진 + viewport fit (단일 페이지)
// Story: S1.8 (#14) — 핀치 줌 (FixedLayoutPage에 통합 완료)
// Story: S1.9 (#15) — spread 자동 분기 (1/2-page) + page-spread-left/right
// BDD: F3 (Fixed Layout 본문 렌더링)
//
// 본 engine은:
// - 단일 페이지 1-page 모드 (S1.7)
// - 줌은 FixedLayoutPage가 책임 (S1.8)
// - spread 모드 (2-page) — screen width + rendition:spread에 따라 자동 분기,
//   page-spread-left/right 슬롯 존중 (S1.9, BDD F3.3/F3.5)

import 'package:flutter/material.dart';

import '../../../api/epub_book.dart';
import '../../../domain/entity/epub_spine_item.dart';
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

/// fixed-layout 페이지 위에 같은 논리 좌표 공간으로 합성되는 전경 오버레이
/// 빌더(open-board 절대좌표 필기 캔버스 등, S8.6). [item]은 해당 spine,
/// [logicalSize]는 페이지 논리 크기(=절대좌표 공간).
typedef FixedLayoutForegroundBuilder = Widget Function(
  BuildContext context,
  EpubSpineItem item,
  Size logicalSize,
);

class FixedLayoutEngine extends StatefulWidget {
  const FixedLayoutEngine({
    super.key,
    required this.book,
    required this.pageBuilder,
    this.initialSpineIndex = 0,
    this.fitter = const ViewportFitter(),
    this.spreadOverride,
    this.foregroundBuilder,
    this.enableZoom = true,
  });

  final EpubBook book;
  final FixedLayoutPageBuilder pageBuilder;
  final int initialSpineIndex;
  final ViewportFitter fitter;

  /// null이면 [EpubBook.metadata.spread]를 사용. 테스트 / 사용자 설정으로
  /// 강제 변경하려면 [EpubSpread]를 명시 (예: [EpubSpread.none]).
  final EpubSpread? spreadOverride;

  /// 각 페이지 위에 전경 오버레이(필기 등)를 합성한다. null이면 오버레이 없음.
  /// 빌더의 로컬 좌표가 곧 페이지 절대좌표이며 fit·zoom·pan과 함께 변환된다(S8.6).
  final FixedLayoutForegroundBuilder? foregroundBuilder;

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
    _spreadRows = buildSpreadRows(widget.book.spine);
    _rowIndex = _findRowIndexForSpine(_spineIndex);
  }

  @override
  void didUpdateWidget(FixedLayoutEngine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) {
      _spineIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _spreadRows = buildSpreadRows(widget.book.spine);
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

  bool nextSpine() {
    if (_spineIndex >= spineCount - 1) return false;
    setState(() {
      _spineIndex++;
      _rowIndex = _findRowIndexForSpine(_spineIndex);
    });
    return true;
  }

  bool previousSpine() {
    if (_spineIndex <= 0) return false;
    setState(() {
      _spineIndex--;
      _rowIndex = _findRowIndexForSpine(_spineIndex);
    });
    return true;
  }

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

        if (!useSpread || _spreadRows.isEmpty) {
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
      foregroundBuilder: widget.foregroundBuilder,
      enableZoom: widget.enableZoom,
    );
  }
}

class _AsyncFixedLayoutPage extends StatefulWidget {
  const _AsyncFixedLayoutPage({
    super.key,
    required this.item,
    required this.pageBuilder,
    required this.fitter,
    this.foregroundBuilder,
    this.enableZoom = true,
  });

  final EpubSpineItem item;
  final FixedLayoutPageBuilder pageBuilder;
  final ViewportFitter fitter;
  final FixedLayoutForegroundBuilder? foregroundBuilder;
  final bool enableZoom;

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
        final fg = widget.foregroundBuilder;
        return FixedLayoutPage(
          logicalSize: page.logicalSize,
          content: page.content,
          fitter: widget.fitter,
          enableZoom: widget.enableZoom,
          foregroundBuilder: fg == null
              ? null
              : (ctx, logicalSize) => fg(ctx, widget.item, logicalSize),
        );
      },
    );
  }
}
