// Domain UseCase — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.10~S1.12.
// BDD: F1.2, F1.3 (위치 복원 + lossy fallback)

import '../../api/epub_book.dart';
import '../../api/epub_position.dart';

class ResolvePositionUseCase {
  Future<EpubPosition> call(EpubBook book, EpubPosition target) {
    throw UnimplementedError('S1.10');
  }
}
