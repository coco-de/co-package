// Public API — open_epub 1.0
// Story: S1.20 (#36) — EpubSource.file 의 dart:io 구현 (모바일/데스크톱)

import 'dart:io';
import 'dart:typed_data';

import '../domain/entity/epub_failure.dart';

/// 로컬 파일에서 EPUB 바이트를 읽는다. (조건부 import: VM/모바일/데스크톱)
Future<Uint8List> readFileBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw EpubInvalidFile('EPUB file not found: $path');
  }
  return file.readAsBytes();
}
