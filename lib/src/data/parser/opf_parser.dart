// Data Parser — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.1, S1.4.
// BDD: F1.1 (OPF 메타데이터 파싱)

import '../../domain/entity/epub_metadata.dart';
import '../../domain/entity/epub_spine_item.dart';

class OpfParser {
  /// OPF XML 문자열에서 metadata + spine을 추출.
  ({EpubMetadata metadata, List<EpubSpineItem> spine}) parse(String opfXml) {
    throw UnimplementedError('S1.1');
  }
}
