// Data Repository — open_epub 1.0
// Story: S1.21 (#37) — 열린 ZIP 컨테이너를 OPF 기준 상대 href로 읽는 reader.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../domain/entity/epub_resource.dart';
import '../security/encryption_parser.dart';

/// [Archive]를 감싸 OPF 디렉토리 기준 상대 href를 정규화하여 읽는다.
///
/// IDPF/Adobe 폰트 난독화가 걸린 리소스는 읽는 시점에 투명 해제한다
/// ([obfuscatedResources] = ZIP 루트 경로 → 난독화 알고리즘). (S13.5, gap #8)
class ArchiveResourceReader implements EpubResourceReader {
  const ArchiveResourceReader(
    this._archive,
    this._baseDir, {
    Map<String, String> obfuscatedResources = const {},
    String? identifier,
  })  : _obfuscated = obfuscatedResources,
        _identifier = identifier;

  final Archive _archive;

  /// OPF 패키지가 위치한 디렉토리 (`OEBPS/content.opf` → `OEBPS`).
  final String _baseDir;

  /// ZIP 루트 경로 → 폰트 난독화 알고리즘. 읽을 때 투명 해제한다.
  final Map<String, String> _obfuscated;
  final String? _identifier;

  @override
  Uint8List? readBytes(String href) {
    final path = resolveHref(_baseDir, href);
    final file = _archive.findFile(path);
    if (file == null) return null;
    final bytes = Uint8List.fromList(file.content as List<int>);
    final algorithm = _obfuscated[path];
    if (algorithm != null && _identifier != null) {
      return FontObfuscation.deobfuscate(
        data: bytes,
        algorithm: algorithm,
        identifier: _identifier,
      );
    }
    return bytes;
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
