// Domain UseCase — open_epub 1.0
// Story: S1.19 (#35) — 본문 검색 인덱스 빌드
// BDD: F7 (본문 검색 인덱스 ≤ 3.0s)
//
// 참고: EpubBook은 메타/spine/목차만 노출하고 본문 bytes를 갖지 않으므로,
// 본문 평문은 [spineTexts](spineHref→평문 텍스트)로 주입받는다. 실제 본문
// 추출(XHTML→평문)·연결은 엔진/세션 위젯 통합 단계의 책임이다.

import '../../api/epub_book.dart';
import '../../data/search/text_index_builder.dart';

class BuildSearchIndexUseCase {
  const BuildSearchIndexUseCase({TextIndexBuilder builder = const TextIndexBuilder()})
      : _builder = builder;

  final TextIndexBuilder _builder;

  Future<BookSearchIndex> call(
    EpubBook book, {
    required Map<String, String> spineTexts,
  }) =>
      _builder.build(book, spineTexts: spineTexts);
}

/// 빌드된 검색 인덱스. [search]로 질의한다.
abstract class BookSearchIndex {
  Future<List<BookSearchHit>> search(String query);
}

/// 검색 결과 1건 — 위치(spineHref + charOffset) + 미리보기 snippet.
class BookSearchHit {
  const BookSearchHit({
    required this.spineHref,
    required this.charOffset,
    required this.snippet,
  });

  final String spineHref;
  final int charOffset;
  final String snippet;
}
