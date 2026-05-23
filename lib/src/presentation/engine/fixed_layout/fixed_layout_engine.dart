// Presentation Engine — open_epub 1.0
// Story: S1.7 (#13) — Fixed Layout 엔진 + viewport fit (단일 페이지)
// Story: S1.8 (#14) — 핀치 줌 (별도 PR)
// Story: S1.9 (#15) — spread 자동 분기 (별도 PR)
// BDD: F3 (Fixed Layout 본문 렌더링)
//
// 본 widget은 단일 페이지 1-page 모드만 처리. spine 이동(next/previous),
// 페이지 빌더 호출, viewport fit이 책임 범위. spread / zoom은 후속 Story.

import 'package:flutter/material.dart';

import '../../../api/epub_book.dart';
import '../../../domain/entity/epub_spine_item.dart';
import 'fixed_layout_page.dart';
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

class FixedLayoutEngine extends StatefulWidget {
  const FixedLayoutEngine({
    super.key,
    required this.book,
    required this.pageBuilder,
    this.initialSpineIndex = 0,
    this.fitter = const ViewportFitter(),
  });

  final EpubBook book;
  final FixedLayoutPageBuilder pageBuilder;
  final int initialSpineIndex;
  final ViewportFitter fitter;

  @override
  State<FixedLayoutEngine> createState() => FixedLayoutEngineState();
}

@visibleForTesting
class FixedLayoutEngineState extends State<FixedLayoutEngine> {
  late int _spineIndex;
  late Future<FixedLayoutPageData> _currentLoad;

  int get spineIndex => _spineIndex;
  int get spineCount => widget.book.spine.length;

  @override
  void initState() {
    super.initState();
    _spineIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    _currentLoad = _loadCurrent();
  }

  Future<FixedLayoutPageData> _loadCurrent() {
    if (widget.book.spine.isEmpty) {
      return Future.value(
        const FixedLayoutPageData(
          logicalSize: Size(1, 1),
          content: SizedBox.shrink(),
        ),
      );
    }
    return widget.pageBuilder(widget.book.spine[_spineIndex]);
  }

  bool nextSpine() {
    if (_spineIndex >= spineCount - 1) return false;
    setState(() {
      _spineIndex++;
      _currentLoad = _loadCurrent();
    });
    return true;
  }

  bool previousSpine() {
    if (_spineIndex <= 0) return false;
    setState(() {
      _spineIndex--;
      _currentLoad = _loadCurrent();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.spine.isEmpty) {
      return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
    }
    return FutureBuilder<FixedLayoutPageData>(
      future: _currentLoad,
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
        return FixedLayoutPage(
          logicalSize: page.logicalSize,
          content: page.content,
          fitter: widget.fitter,
        );
      },
    );
  }
}
