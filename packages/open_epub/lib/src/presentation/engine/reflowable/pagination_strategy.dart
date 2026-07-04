// Presentation Engine — open_epub 1.0
// Story: S1.6 (#12) — Reflowable 페이지네이션
//
// 페이지 분할 전략의 추상 인터페이스. 정확한 viewport 기반 페이지 분할은
// 렌더러(flutter_widget_from_html, S11.3)의 렌더 height 측정이 필요하여 본 Story
// 범위 외 (S4.10 성능 벤치 단계와 함께 더 정교한 strategy 추가 예정).
//
// 본 Story에서는 [SinglePagePerSpineStrategy] (1 spine = 1 page)를 default로
// 제공한다. 사용자 입장에서 "다음 페이지"는 곧 "다음 spine 항목"이고, 한
// spine 내부는 SingleChildScrollView로 스크롤된다.

import 'package:open_epub_engine/open_epub_engine.dart';

/// 페이지 분할 결과. 각 페이지는 spine 인덱스 + spine 내부 offset 범위를 갖는다.
class PaginationResult {
  const PaginationResult({required this.pages});

  /// 전체 페이지 목록. 외부에서 page index로 인덱싱한다.
  final List<PageSlice> pages;

  int get pageCount => pages.length;
}

/// 한 페이지가 가리키는 spine + 내부 슬라이스.
class PageSlice {
  const PageSlice({
    required this.spineIndex,
    required this.startCharOffset,
    required this.endCharOffset,
  });

  final int spineIndex;
  final int startCharOffset;

  /// exclusive end. spine 끝까지면 [endCharOffset]은 [int.maxFinite]에 가깝게
  /// 두거나 sentinel(-1)을 쓰는 대신, 본 stub에서는 spine 전체일 때
  /// `startCharOffset = 0`, `endCharOffset = -1`로 표현한다 (정확한 측정은
  /// 미구현 → S4.10).
  final int endCharOffset;
}

/// 분할 전략 추상.
abstract class PaginationStrategy {
  const PaginationStrategy();

  PaginationResult paginate({
    required List<EpubSpineItem> spine,
    required double viewportWidth,
    required double viewportHeight,
    required double fontSize,
    required double lineHeight,
  });
}

/// Default: 1 spine = 1 page. Viewport 측정 불필요. spine 내부는 외부
/// widget이 스크롤로 표시.
class SinglePagePerSpineStrategy extends PaginationStrategy {
  const SinglePagePerSpineStrategy();

  @override
  PaginationResult paginate({
    required List<EpubSpineItem> spine,
    required double viewportWidth,
    required double viewportHeight,
    required double fontSize,
    required double lineHeight,
  }) {
    return PaginationResult(
      pages: List.generate(
        spine.length,
        (i) => PageSlice(
          spineIndex: i,
          startCharOffset: 0,
          endCharOffset: -1, // 전체 spine
        ),
        growable: false,
      ),
    );
  }
}
