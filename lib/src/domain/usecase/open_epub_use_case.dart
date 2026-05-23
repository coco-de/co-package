// Domain UseCase — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.21.
// BDD: F1 (EPUB 책 열기)

import '../../api/epub_book.dart';
import '../../api/epub_source.dart';
import '../repository/epub_repository.dart';

class OpenEpubUseCase {
  OpenEpubUseCase(this._repository);

  final EpubRepository _repository;

  Future<EpubBook> call(EpubSource source) {
    throw UnimplementedError('S1.21');
  }
}
