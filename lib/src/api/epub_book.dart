// Public API — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.4, S1.21.
// BDD: F1.1 (OPF parse), F3 (rendition:layout)

import '../domain/entity/epub_metadata.dart';
import '../domain/entity/epub_outline.dart';
import '../domain/entity/epub_spine_item.dart';

/// 파싱 완료된 EPUB. 메타데이터·spine·outline을 노출.
abstract class EpubBook {
  EpubMetadata get metadata;
  List<EpubSpineItem> get spine;
  EpubOutline get outline;
  EpubLayout get layout;
}

enum EpubLayout { reflowable, fixedLayout }
