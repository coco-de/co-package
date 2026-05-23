// Data Search — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.19.
// BDD: F7.1 (검색 인덱스 빌드 ≤ 3.0s)

import '../../api/epub_book.dart';
import '../../domain/usecase/build_search_index_use_case.dart';

class TextIndexBuilder {
  Future<BookSearchIndex> build(EpubBook book) {
    throw UnimplementedError('S1.19');
  }
}
