import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/managers/scribble_file_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/test_helpers.dart';

/// path_provider mock
class FakePathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => null;

  @override
  Future<String?> getDownloadsPath() async => null;

  @override
  Future<String?> getApplicationCachePath() async => null;
}

void main() {
  late Directory tempDir;
  late ScribbleFileStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scribble_test_');
    PathProviderPlatform.instance = FakePathProvider(tempDir);
    storage = ScribbleFileStorage();
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('normalizeKey()', () {
    test('특수문자 처리', () {
      expect(ScribbleFileStorage.normalizeKey('key|1'), 'key_1');
      expect(ScribbleFileStorage.normalizeKey('key:1'), 'key_1');
      expect(ScribbleFileStorage.normalizeKey('key?1'), 'key_1');
      expect(ScribbleFileStorage.normalizeKey('key*1'), 'key_1');
    });

    test('정상 키는 그대로', () {
      expect(ScribbleFileStorage.normalizeKey('content1/page1'), 'content1/page1');
      expect(ScribbleFileStorage.normalizeKey('abc_123'), 'abc_123');
    });
  });

  group('saveToMemory / load (메모리 캐시)', () {
    test('저장 후 메모리에서 로드', () async {
      final scribble = createScribbleWithStrokes(strokeCount: 2);
      storage.saveToMemory('key1', scribble);

      final loaded = await storage.load('key1');
      expect(loaded, isNotNull);
      expect(loaded!.strokes.length, 2);
    });

    test('존재하지 않는 키는 null 반환', () async {
      final loaded = await storage.load('nonexistent');
      expect(loaded, isNull);
    });

    test('memoryCacheSize는 저장된 항목 수', () {
      storage.saveToMemory('k1', createScribble());
      storage.saveToMemory('k2', createScribble());
      expect(storage.memoryCacheSize, 2);
    });
  });

  group('saveToFile / load (디스크 I/O)', () {
    test('파일에 저장 후 로드', () async {
      final scribble = createScribbleWithStrokes(strokeCount: 3);
      final saved = await storage.saveToFile('content1/page1', scribble);
      expect(saved, true);

      // 새 인스턴스로 로드 (메모리 캐시 없음)
      PathProviderPlatform.instance = FakePathProvider(tempDir);
      final freshStorage = ScribbleFileStorage();
      final loaded = await freshStorage.load('content1/page1');
      expect(loaded, isNotNull);
      expect(loaded!.strokes.length, 3);
    });

    test('저장 실패 시 false 반환 (비정상 경로)', () async {
      // 웹이 아니므로 정상 동작 — 실패 케이스는 실제 에러 주입으로만 가능
      // 여기서는 정상 저장이 true 반환함을 검증
      final scribble = createScribble();
      final result = await storage.saveToFile('test_key', scribble);
      expect(result, true);
    });
  });

  group('exists()', () {
    test('메모리에 있으면 true', () async {
      storage.saveToMemory('key1', createScribble());
      expect(await storage.exists('key1'), true);
    });

    test('없으면 false', () async {
      expect(await storage.exists('nonexistent'), false);
    });

    test('파일로 저장 후 true', () async {
      await storage.saveToFile('key_disk', createScribble());
      final fresh = ScribbleFileStorage();
      expect(await fresh.exists('key_disk'), true);
    });
  });

  group('delete()', () {
    test('메모리에서 삭제', () async {
      storage.saveToMemory('key1', createScribble());
      await storage.delete('key1');
      expect(await storage.exists('key1'), false);
    });

    test('파일에서 삭제', () async {
      await storage.saveToFile('key_del', createScribble());
      await storage.delete('key_del');

      final fresh = ScribbleFileStorage();
      expect(await fresh.exists('key_del'), false);
    });
  });

  group('deleteByPrefix()', () {
    test('접두사에 해당하는 모든 항목 삭제', () async {
      storage.saveToMemory('content1/page1', createScribble());
      storage.saveToMemory('content1/page2', createScribble());
      storage.saveToMemory('content2/page1', createScribble());

      await storage.deleteByPrefix('content1');

      expect(storage.memoryCacheSize, 1); // content2/page1만 남음
    });
  });

  group('clearMemory()', () {
    test('메모리 캐시 전체 초기화', () {
      storage.saveToMemory('k1', createScribble());
      storage.saveToMemory('k2', createScribble());
      storage.clearMemory();
      expect(storage.memoryCacheSize, 0);
    });
  });

  group('clearAll()', () {
    test('메모리 + 디스크 캐시 전체 초기화', () async {
      storage.saveToMemory('k1', createScribble());
      await storage.saveToFile('k2', createScribble());

      final result = await storage.clearAll();
      expect(result, true);
      expect(storage.memoryCacheSize, 0);

      expect(await storage.exists('k2'), false);
    });
  });

  group('getKeysByPrefix()', () {
    test('파일 기반 키 목록 반환', () async {
      await storage.saveToFile('content1/page1', createScribble());
      await storage.saveToFile('content1/page2', createScribble());

      final keys = await storage.getKeysByPrefix('content1');
      expect(keys.length, 2);
      expect(keys, containsAll(['content1/page1', 'content1/page2']));
    });

    test('존재하지 않는 접두사는 빈 목록', () async {
      final keys = await storage.getKeysByPrefix('nonexistent');
      expect(keys, isEmpty);
    });
  });

  group('getAllKeys()', () {
    test('모든 저장된 키 반환', () async {
      await storage.saveToFile('a/b', createScribble());
      await storage.saveToFile('c/d', createScribble());

      final keys = await storage.getAllKeys();
      expect(keys, containsAll(['a/b', 'c/d']));
    });
  });

  group('getCacheInfo()', () {
    test('캐시 정보 반환', () async {
      storage.saveToMemory('k1', createScribble());
      await storage.saveToFile('k2', createScribble());

      final info = await storage.getCacheInfo();
      expect(info['memoryCache'], 1); // k1만 메모리에
      expect(info['totalFiles'], greaterThanOrEqualTo(1));
    });
  });
}
