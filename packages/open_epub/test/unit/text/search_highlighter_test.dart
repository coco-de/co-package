// Story: S7.6 (E7) — SearchHighlighter 단위 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/data/text/search_highlighter.dart';
import 'package:open_epub/src/domain/usecase/build_search_index_use_case.dart';

void main() {
  const sh = SearchHighlighter();

  test('hit을 queryLength 길이의 강조로 변환', () {
    final hits = [
      const BookSearchHit(spineHref: 'ch1.xhtml', charOffset: 4, snippet: '…'),
      const BookSearchHit(spineHref: 'ch2.xhtml', charOffset: 10, snippet: '…'),
    ];
    final highlights = sh.highlightsForHits(hits, 2, colorArgb: 0xFFFFE082);

    expect(highlights, hasLength(2));
    expect(highlights[0].spineHref, 'ch1.xhtml');
    expect(highlights[0].start, 4);
    expect(highlights[0].end, 6);
    expect(highlights[0].colorArgb, 0xFFFFE082);
    expect(highlights[1].start, 10);
    expect(highlights[1].end, 12);
    // id는 고유(렌더 전용)
    expect(highlights[0].id, isNot(highlights[1].id));
  });

  test('빈 hits는 빈 목록', () {
    expect(sh.highlightsForHits(const [], 3), isEmpty);
  });
}
