// Data Repository — open_epub 1.0
// Story: S1.21 (#37) — 열린 ZIP 컨테이너를 OPF 기준 상대 href로 읽는 reader.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../domain/entity/epub_resource.dart';

/// [Archive]를 감싸 OPF 디렉토리 기준 상대 href를 정규화하여 읽는다.
class ArchiveResourceReader implements EpubResourceReader {
  const ArchiveResourceReader(this._archive, this._baseDir);

  final Archive _archive;

  /// OPF 패키지가 위치한 디렉토리 (`OEBPS/content.opf` → `OEBPS`).
  final String _baseDir;

  @override
  Uint8List? readBytes(String href) {
    final file = _archive.findFile(resolveHref(_baseDir, href));
    if (file == null) return null;
    return Uint8List.fromList(file.content as List<int>);
  }

  @override
  String? readString(String href) {
    final bytes = readBytes(href);
    if (bytes == null) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// [baseDir] 기준 상대 [href]를 결합하고 `.`/`..`를 정규화한다.
/// zip slip 방어: `..`가 루트 위로 올라가는 경우 해당 세그먼트를 무시한다.
String resolveHref(String baseDir, String href) {
  final combined = baseDir.isEmpty ? href : '$baseDir/$href';
  final parts = <String>[];
  for (final seg in combined.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(seg);
  }
  return parts.join('/');
}
