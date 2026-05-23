// Domain UseCase — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.19.
// BDD: F7 (본문 검색 인덱스 ≤ 3.0s)

import '../../api/epub_book.dart';

class BuildSearchIndexUseCase {
  Future<BookSearchIndex> call(EpubBook book) {
    throw UnimplementedError('S1.19');
  }
}

abstract class BookSearchIndex {
  Future<List<BookSearchHit>> search(String query);
}

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
