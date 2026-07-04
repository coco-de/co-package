// Public API — open_epub 1.0
// Story: S1.4 (#10) — Spine 파싱 + rendition:layout 감지 일부
// BDD: F1.1 (OPF parse), F3 (rendition:layout)

import '../domain/entity/epub_metadata.dart';
import '../domain/entity/epub_outline.dart';
import '../domain/entity/epub_spine_item.dart';

// EpubLayout enum은 domain에서 정의하고 public API로 re-export한다.
// (api → domain 의존만 허용되는 Clean Architecture 원칙)
export '../domain/entity/epub_metadata.dart' show EpubLayout, EpubSpread;

/// 파싱 완료된 EPUB. 메타데이터·spine·outline·layout을 노출.
abstract class EpubBook {
  EpubMetadata get metadata;
  List<EpubSpineItem> get spine;
  EpubOutline get outline;

  /// 책의 layout. [EpubMetadata.layout]을 위임한 편의 getter로 구현하는 것이
  /// 일반적이다 (S1.21 EpubBookSession.open()에서 concrete impl 제공).
  EpubLayout get layout;
}
