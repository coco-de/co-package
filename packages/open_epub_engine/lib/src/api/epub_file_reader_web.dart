// Public API — open_epub 1.0
// Story: S1.20 (#36) — EpubSource.file 의 web stub (dart:io 미지원)

import 'dart:typed_data';

/// web에는 로컬 파일시스템 접근이 없다. (조건부 import: web)
Future<Uint8List> readFileBytes(String path) async {
  throw UnsupportedError(
    'EpubSource.file is not supported on web. '
    'Use EpubSource.bytes or EpubSource.url instead.',
  );
}
