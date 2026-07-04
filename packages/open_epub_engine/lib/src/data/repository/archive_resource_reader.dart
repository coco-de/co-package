// Data Repository — open_epub 1.0
// Story: S1.21 (#37) — 열린 ZIP 컨테이너를 OPF 기준 상대 href로 읽는 reader.
// Story: S9.1 (#65) — 압축 해제 캐시 무제한 누적(OOM 위험) 방지: LRU eviction.

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:meta/meta.dart';

import '../../domain/entity/epub_resource.dart';
import '../security/encryption_parser.dart';

/// 압축 해제 바이트 캐시 상한 기본값 (32MiB).
const int _defaultMaxCachedBytes = 32 * 1024 * 1024;

/// [Archive]를 감싸 OPF 디렉토리 기준 상대 href를 정규화하여 읽는다.
///
/// IDPF/Adobe 폰트 난독화가 걸린 리소스는 읽는 시점에 투명 해제한다
/// ([obfuscatedResources] = ZIP 루트 경로 → 난독화 알고리즘). (S13.5, gap #8)
///
/// `package:archive`의 `ArchiveFile.content`는 압축 해제 결과를 내부에
/// 영구 캐시하므로, 아무 조치가 없으면 세션 동안 읽은 모든 리소스의 압축
/// 해제 바이트가 무제한으로 누적된다(대형 이미지 중심 EPUB에서 OOM 위험).
/// 이를 막기 위해 접근 순서를 LRU로 추적하고, [maxCachedBytes]를 넘으면
/// 가장 오래전에 접근한 항목부터 `ArchiveFile.clear()`로 압축 해제 캐시를
/// 해제한다 — 이후 다시 읽으면 원본 압축 바이트에서 재압축해제되므로
/// 정확성에는 영향이 없다. (S9.1, #65)
class ArchiveResourceReader implements EpubResourceReader {
  ArchiveResourceReader(
    this._archive,
    this._baseDir, {
    Map<String, String> obfuscatedResources = const {},
    String? identifier,
    int maxCachedBytes = _defaultMaxCachedBytes,
  })  : _obfuscated = obfuscatedResources,
        _identifier = identifier,
        _maxCachedBytes = maxCachedBytes;

  final Archive _archive;

  /// OPF 패키지가 위치한 디렉토리 (`OEBPS/content.opf` → `OEBPS`).
  final String _baseDir;

  /// ZIP 루트 경로 → 폰트 난독화 알고리즘. 읽을 때 투명 해제한다.
  final Map<String, String> _obfuscated;
  final String? _identifier;

  final int _maxCachedBytes;

  /// 정규화된 href → 압축 해제된 바이트 크기. 삽입 순서 = LRU 순서
  /// (가장 최근 접근이 마지막).
  final LinkedHashMap<String, int> _lruSizes = LinkedHashMap<String, int>();
  int _cachedBytes = 0;

  /// 현재 캐시에 남아있는(압축 해제된 채인) 바이트 총합. 테스트 전용.
  @visibleForTesting
  int get debugCachedBytes => _cachedBytes;

  /// 현재 캐시에 남아있는 리소스 개수. 테스트 전용.
  @visibleForTesting
  int get debugCachedEntryCount => _lruSizes.length;

  @override
  Uint8List? readBytes(String href) {
    final path = resolveHref(_baseDir, href);
    final file = _archive.findFile(path);
    if (file == null) return null;
    final bytes = Uint8List.fromList(file.content as List<int>);
    _touch(path, bytes.length);
    _evictIfNeeded();
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

  void _touch(String key, int size) {
    final previous = _lruSizes.remove(key);
    if (previous != null) _cachedBytes -= previous;
    _lruSizes[key] = size;
    _cachedBytes += size;
  }

  void _evictIfNeeded() {
    while (_cachedBytes > _maxCachedBytes && _lruSizes.length > 1) {
      final oldestKey = _lruSizes.keys.first;
      final size = _lruSizes.remove(oldestKey);
      if (size != null) _cachedBytes -= size;
      _archive.findFile(oldestKey)?.clear();
    }
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
