// Data — open_epub 1.0
// Story: S7.6 (E7) — 검색 매치 in-view 하이라이트
//
// 검색 결과(BookSearchHit)를 본문에 임시 강조로 렌더하기 위한 EpubHighlight로
// 변환한다. readSpineXhtmlWithHighlights에 그대로 넘겨 매치 구간을 칠한다.

import '../../domain/entity/epub_highlight.dart';
import '../../domain/usecase/build_search_index_use_case.dart';

/// 검색 hit → 임시 강조 변환 유틸.
class SearchHighlighter {
  const SearchHighlighter();

  /// 기본 검색 매치 강조색(연한 주황, ARGB).
  static const int defaultColorArgb = 0xFFFFE082;

  /// 각 [hits]를 길이 [queryLength] 구간 강조로 변환한다.
  /// id는 `search:N`(렌더 전용, 영속 대상 아님).
  List<EpubHighlight> highlightsForHits(
    Iterable<BookSearchHit> hits,
    int queryLength, {
    int colorArgb = defaultColorArgb,
  }) {
    final result = <EpubHighlight>[];
    var i = 0;
    for (final hit in hits) {
      result.add(
        EpubHighlight(
          id: 'search:${i++}',
          spineHref: hit.spineHref,
          start: hit.charOffset,
          end: hit.charOffset + (queryLength < 0 ? 0 : queryLength),
          selectedText: '',
          colorArgb: colorArgb,
        ),
      );
    }
    return result;
  }
}
