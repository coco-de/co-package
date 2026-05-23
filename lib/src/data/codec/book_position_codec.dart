// Data Codec — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.10.
// BDD: F1.2 (BookPosition v1 encode/decode round-trip)
// ADR-001: JSON ≤ 512 bytes

import '../../api/epub_position.dart';

class BookPositionCodec {
  String encode(EpubPosition position) {
    throw UnimplementedError('S1.10');
  }

  EpubPosition decode(String token) {
    throw UnimplementedError('S1.10');
  }
}
