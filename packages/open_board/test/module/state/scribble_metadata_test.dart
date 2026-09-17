import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/scribble_metadata.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ScribbleSyncSource', () {
    test('모든 소스 존재', () {
      expect(ScribbleSyncSource.values, contains(ScribbleSyncSource.local));
      expect(ScribbleSyncSource.values, contains(ScribbleSyncSource.server));
      expect(ScribbleSyncSource.values, contains(ScribbleSyncSource.merged));
    });
  });

  group('ConflictResolution', () {
    test('모든 해결 방식 존재', () {
      expect(ConflictResolution.values, contains(ConflictResolution.none));
      expect(
        ConflictResolution.values,
        contains(ConflictResolution.localWins),
      );
      expect(ConflictResolution.values, contains(ConflictResolution.manual));
    });
  });

  group('ScribbleMetadata', () {
    late ScribbleMetadata metadata;

    setUp(() {
      metadata = ScribbleMetadata(
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-02T00:00:00Z',
        version: 'v1',
        hash: 'abc123',
        strokeCount: 5,
      );
    });

    test('기본 생성', () {
      expect(metadata.createdAt, '2024-01-01T00:00:00Z');
      expect(metadata.updatedAt, '2024-01-02T00:00:00Z');
      expect(metadata.version, 'v1');
      expect(metadata.hash, 'abc123');
      expect(metadata.strokeCount, 5);
      expect(metadata.syncSource, ScribbleSyncSource.local);
      expect(metadata.conflictResolution, ConflictResolution.none);
      expect(metadata.lastSyncTime, isNull);
    });

    group('needsSync', () {
      test('서버 메타데이터 null이면 true', () {
        expect(metadata.needsSync(null), true);
      });

      test('같은 해시면 false', () {
        final serverMeta = ScribbleMetadata(
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-02T00:00:00Z',
          version: 'v1',
          hash: 'abc123',
          strokeCount: 5,
        );
        expect(metadata.needsSync(serverMeta), false);
      });

      test('다른 해시면 true', () {
        final serverMeta = ScribbleMetadata(
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-02T00:00:00Z',
          version: 'v1',
          hash: 'different',
          strokeCount: 5,
        );
        expect(metadata.needsSync(serverMeta), true);
      });
    });

    group('fromScribble', () {
      test('Scribble에서 메타데이터 생성', () {
        final scribble = createScribbleWithStrokes(strokeCount: 3);
        final meta = ScribbleMetadata.fromScribble(scribble);
        expect(meta.strokeCount, 3);
        expect(meta.hash, isNotEmpty);
        expect(meta.version, isNotEmpty);
      });

      test('빈 Scribble', () {
        final scribble = createScribble();
        final meta = ScribbleMetadata.fromScribble(scribble);
        expect(meta.strokeCount, 0);
      });

      test('null Scribble', () {
        final meta = ScribbleMetadata.fromScribble(null);
        expect(meta.strokeCount, 0);
      });
    });

    group('fromJson / toJson', () {
      test('직렬화 왕복', () {
        final json = metadata.toJson();
        final restored = ScribbleMetadata.fromJson(json);
        expect(restored.createdAt, metadata.createdAt);
        expect(restored.hash, metadata.hash);
        expect(restored.strokeCount, metadata.strokeCount);
      });
    });

    group('resolveConflict', () {
      test('충돌 해결', () {
        final serverMeta = ScribbleMetadata(
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-03T00:00:00Z',
          version: 'v2',
          hash: 'server_hash',
          strokeCount: 10,
        );
        final resolved = ScribbleMetadata.resolveConflict(
          metadata,
          serverMeta,
        );
        expect(resolved, isNotNull);
      });
    });
  });
}
