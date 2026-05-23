// Domain Entity — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.4.

import 'dart:typed_data';

/// EPUB 내부 리소스 (이미지/CSS/폰트 등). path normalization 적용 후 노출.
class EpubResource {
  const EpubResource({
    required this.href,
    required this.mediaType,
    required this.bytes,
  });

  final String href;
  final String mediaType;
  final Uint8List bytes;
}
