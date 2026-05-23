// Data Repository Impl — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.20, S1.21.

import '../../api/epub_book.dart';
import '../../api/epub_source.dart';
import '../../domain/repository/epub_repository.dart';

class EpubRepositoryImpl implements EpubRepository {
  @override
  Future<EpubBook> load(EpubSource source) {
    throw UnimplementedError('S1.20');
  }
}
