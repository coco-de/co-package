import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// 필기 데이터 파일 I/O 담당 클래스
///
/// 메모리 캐시와 디스크(바이너리 파일) 저장/로드를 관리합니다.
/// 웹 플랫폼에서는 메모리 캐시만 사용합니다.
class ScribbleFileStorage {
  /// 메모리 캐시 (normalizedKey -> Scribble)
  final Map<String, Scribble> _memoryCache = {};

  /// 디스크 캐시 디렉토리
  Directory? _cacheDirectory;

  /// 웹 플랫폼 여부
  bool get isWeb => kIsWeb;

  // ===== 캐시 키 관리 =====

  /// 캐시 키 정규화 (특수 문자 처리)
  static String normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[<>:"|?*]'), '_');
  }

  // ===== 디렉토리 / 경로 관리 =====

  /// 캐시 디렉토리 (초기화 포함)
  Future<Directory> get cacheDirectory async {
    if (isWeb) {
      throw UnsupportedError('File I/O is not supported on web');
    }
    if (_cacheDirectory != null) return _cacheDirectory!;

    final documentsDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${documentsDir.path}/scribbles');

    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }

    return _cacheDirectory!;
  }

  /// 파일 경로 생성
  /// key 형식: 'contentId/pageId' → {cacheDir}/contentId/pageId.bin
  Future<String> getFilePath(String normalizedKey) async {
    final dir = await cacheDirectory;
    final keyParts = normalizedKey.split('/');

    if (keyParts.length > 1) {
      final subDirPath = keyParts.sublist(0, keyParts.length - 1).join('/');
      final subDir = Directory('${dir.path}/$subDirPath');
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }
    }

    return '${dir.path}/$normalizedKey.bin';
  }

  // ===== 저장 =====

  /// 파일에 즉시 저장 (웹에서는 no-op)
  Future<bool> saveToFile(String normalizedKey, Scribble scribble) async {
    if (isWeb) return true;

    try {
      final filePath = await getFilePath(normalizedKey);
      final buffer = scribble.writeToBuffer();
      final file = File(filePath);
      await file.writeAsBytes(buffer);
      return true;
    } on Exception catch (error) {
      debugPrint('ScribbleFileStorage: 파일 저장 실패 - $normalizedKey: $error');
      return false;
    }
  }

  /// 메모리 캐시에 저장
  void saveToMemory(String normalizedKey, Scribble scribble) {
    _memoryCache[normalizedKey] = scribble;
  }

  // ===== 로드 =====

  /// 메모리 캐시 → 디스크 순서로 로드
  Future<Scribble?> load(String key) async {
    try {
      final normalizedKey = normalizeKey(key);

      if (_memoryCache.containsKey(normalizedKey)) {
        return _memoryCache[normalizedKey];
      }

      if (isWeb) return null;

      final filePath = await getFilePath(normalizedKey);
      final file = File(filePath);

      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final scribble = Scribble.fromBuffer(bytes);
      _memoryCache[normalizedKey] = scribble;
      return scribble;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return null;
    }
  }

  /// Assets에서 필기 데이터 로드
  Future<Scribble?> loadFromAssets(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return Scribble.fromBuffer(data.buffer.asUint8List());
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return null;
    }
  }

  // ===== 삭제 =====

  /// 메모리 + 디스크에서 삭제
  Future<bool> delete(String key) async {
    try {
      final normalizedKey = normalizeKey(key);
      _memoryCache.remove(normalizedKey);

      if (isWeb) return true;

      final filePath = await getFilePath(normalizedKey);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return false;
    }
  }

  /// 접두사에 해당하는 모든 데이터 삭제
  Future<bool> deleteByPrefix(String keyPrefix) async {
    try {
      final normalizedPrefix = normalizeKey(keyPrefix);
      _memoryCache.removeWhere(
        (key, _) => key.startsWith('$normalizedPrefix/'),
      );

      if (isWeb) return true;

      final dir = await cacheDirectory;
      final targetDir = Directory('${dir.path}/$normalizedPrefix');
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      return true;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return false;
    }
  }

  // ===== 조회 =====

  /// 특정 키의 데이터 존재 여부 확인
  Future<bool> exists(String key) async {
    final normalizedKey = normalizeKey(key);
    if (_memoryCache.containsKey(normalizedKey)) return true;
    if (isWeb) return false;
    final filePath = await getFilePath(normalizedKey);
    return File(filePath).exists();
  }

  /// 접두사에 해당하는 모든 키 목록
  Future<List<String>> getKeysByPrefix(String keyPrefix) async {
    if (isWeb) {
      return _memoryCache.keys
          .where((k) => k.startsWith(normalizeKey(keyPrefix)))
          .toList();
    }
    try {
      final dir = await cacheDirectory;
      final normalizedPrefix = normalizeKey(keyPrefix);
      final targetDir = Directory('${dir.path}/$normalizedPrefix');
      if (!await targetDir.exists()) return [];

      final keys = <String>[];
      await for (final entity in targetDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.bin')) {
          final relativePath = entity.path
              .replaceFirst('${dir.path}/', '')
              .replaceAll('.bin', '');
          keys.add(relativePath);
        }
      }
      keys.sort();
      return keys;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return [];
    }
  }

  /// 모든 키 목록
  Future<List<String>> getAllKeys() async {
    if (isWeb) return _memoryCache.keys.toList()..sort();
    try {
      final dir = await cacheDirectory;
      final keys = <String>[];
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.bin')) {
          final relativePath = entity.path
              .replaceFirst('${dir.path}/', '')
              .replaceAll('.bin', '');
          keys.add(relativePath);
        }
      }
      keys.sort();
      return keys;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return [];
    }
  }

  /// 캐시 정보 (파일 수, 크기 등)
  Future<Map<String, dynamic>> getCacheInfo() async {
    if (isWeb) {
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'totalSizeFormatted': '0 B (web)',
        'memoryCache': _memoryCache.length,
      };
    }
    try {
      final dir = await cacheDirectory;
      int totalFiles = 0;
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalFiles++;
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeFormatted': _formatBytes(totalSize),
        'memoryCache': _memoryCache.length,
      };
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'totalSizeFormatted': '0 B',
        'memoryCache': _memoryCache.length,
      };
    }
  }

  // ===== 캐시 정리 =====

  /// 메모리 캐시 초기화
  void clearMemory() {
    _memoryCache.clear();
  }

  /// 메모리 + 디스크 캐시 전체 초기화
  Future<bool> clearAll() async {
    try {
      clearMemory();
      if (isWeb) return true;
      final dir = await cacheDirectory;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
      return true;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return false;
    }
  }

  /// 메모리 캐시 크기
  int get memoryCacheSize => _memoryCache.length;

  // ===== 내부 유틸 =====

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
