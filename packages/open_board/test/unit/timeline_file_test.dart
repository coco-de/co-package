import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/data/model/timeline/timeline_serializer.dart';
import 'package:open_board/src/module/replay/content_fingerprint_util.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';

ScribbleTimeline _createSampleTimeline() => .new(
  contentId: 'book123',
  startTimestamp: Int64(1000000),
  endTimestamp: Int64(61000000),
  version: '1.0.0',
  pageIds: ['page1', 'page2', 'page3'],
  events: [
    TimelineEvent(
      timestamp: Int64(1000000),
      event: const TlPageChanged(
        fromIndex: -1,
        toIndex: 0,
        fromPageId: '',
        toPageId: 'page1',
      ),
    ),
    TimelineEvent(
      timestamp: Int64(1100000),
      event: const TlStrokeAdded(pageId: 'page1', strokeIndex: 0),
    ),
    TimelineEvent(
      timestamp: Int64(30000000),
      event: const TlPageChanged(
        fromIndex: 0,
        toIndex: 1,
        fromPageId: 'page1',
        toPageId: 'page2',
      ),
    ),
    TimelineEvent(
      timestamp: Int64(31000000),
      event: const TlStrokeAdded(pageId: 'page2', strokeIndex: 0),
    ),
    TimelineEvent(
      timestamp: Int64(60000000),
      event: const TlUndo(pageId: 'page2'),
    ),
  ],
  snapshots: [
    TimelineSnapshot(
      offsetMicros: Int64(0),
      activePageIndex: 0,
      pageStrokeCounts: {'page1': 0, 'page2': 0},
    ),
    TimelineSnapshot(
      offsetMicros: Int64(30000000),
      activePageIndex: 0,
      pageStrokeCounts: {'page1': 1, 'page2': 0},
    ),
  ],
  pageUpdatedAt: {'page1': '2026-04-07T00:00:00Z'},
  contentFingerprint: const ContentFingerprint(
    hash: 'abc123',
    algorithm: 'sha256',
    metadata: {'bookId': 'abc', 'title': '수학1'},
  ),
);

void main() {
  group('TimelineSerializer', () {
    test('직렬화/역직렬화 라운드트립', () {
      final original = _createSampleTimeline();
      final bytes = TimelineSerializer.serialize(original);
      final restored = TimelineSerializer.deserialize(bytes);

      expect(restored.contentId, 'book123');
      expect(restored.startTimestamp, Int64(1000000));
      expect(restored.endTimestamp, Int64(61000000));
      expect(restored.version, '1.0.0');
      expect(restored.pageIds, ['page1', 'page2', 'page3']);
      expect(restored.events.length, 5);
      expect(restored.snapshots.length, 2);
      expect(restored.pageUpdatedAt['page1'], '2026-04-07T00:00:00Z');
    });

    test('이벤트 타입별 직렬화 검증', () {
      final original = _createSampleTimeline();
      final bytes = TimelineSerializer.serialize(original);
      final restored = TimelineSerializer.deserialize(bytes);

      expect(restored.events[0].event, isA<TlPageChanged>());
      expect(restored.events[1].event, isA<TlStrokeAdded>());
      expect(restored.events[2].event, isA<TlPageChanged>());
      expect(restored.events[3].event, isA<TlStrokeAdded>());
      expect(restored.events[4].event, isA<TlUndo>());

      final pageChanged = restored.events[0].event as TlPageChanged;
      expect(pageChanged.toIndex, 0);
      expect(pageChanged.toPageId, 'page1');

      final strokeAdded = restored.events[1].event as TlStrokeAdded;
      expect(strokeAdded.pageId, 'page1');
      expect(strokeAdded.strokeIndex, 0);
    });

    test('ContentFingerprint 직렬화', () {
      final original = _createSampleTimeline();
      final bytes = TimelineSerializer.serialize(original);
      final restored = TimelineSerializer.deserialize(bytes);

      expect(restored.contentFingerprint, isNotNull);
      expect(restored.contentFingerprint!.hash, 'abc123');
      expect(restored.contentFingerprint!.algorithm, 'sha256');
      expect(restored.contentFingerprint!.metadata['bookId'], 'abc');
      expect(restored.contentFingerprint!.metadata['title'], '수학1');
    });

    test('모든 이벤트 타입 라운드트립', () {
      final timeline = ScribbleTimeline(
        events: [
          TimelineEvent(
            timestamp: Int64(1),
            event: const TlPageChanged(
              fromIndex: 0,
              toIndex: 1,
              fromPageId: 'a',
              toPageId: 'b',
            ),
          ),
          TimelineEvent(
            timestamp: Int64(2),
            event: const TlStrokeAdded(pageId: 'a', strokeIndex: 0),
          ),
          TimelineEvent(
            timestamp: Int64(3),
            event: const TlStrokeRemoved(pageId: 'a', strokeIndex: 0),
          ),
          TimelineEvent(
            timestamp: Int64(4),
            event: const TlUndo(pageId: 'a'),
          ),
          TimelineEvent(
            timestamp: Int64(5),
            event: const TlRedo(pageId: 'a'),
          ),
          TimelineEvent(
            timestamp: Int64(6),
            event: const TlPageAdded(pageId: 'c', atIndex: 2),
          ),
          TimelineEvent(
            timestamp: Int64(7),
            event: const TlPageRemoved(pageId: 'c', atIndex: 2),
          ),
          TimelineEvent(
            timestamp: Int64(8),
            event: const TlPageCleared(pageId: 'a'),
          ),
        ],
      );

      final bytes = TimelineSerializer.serialize(timeline);
      final restored = TimelineSerializer.deserialize(bytes);

      expect(restored.events.length, 8);
      expect(restored.events[0].event, isA<TlPageChanged>());
      expect(restored.events[1].event, isA<TlStrokeAdded>());
      expect(restored.events[2].event, isA<TlStrokeRemoved>());
      expect(restored.events[3].event, isA<TlUndo>());
      expect(restored.events[4].event, isA<TlRedo>());
      expect(restored.events[5].event, isA<TlPageAdded>());
      expect(restored.events[6].event, isA<TlPageRemoved>());
      expect(restored.events[7].event, isA<TlPageCleared>());
    });
  });

  group('TimelineFile', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('obt_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('.obt 파일 쓰기/읽기 라운드트립', () async {
      final original = _createSampleTimeline();
      final path = '${tempDir.path}/test.obt';

      await TimelineFile.write(path, original);
      final restored = await TimelineFile.read(path);

      expect(restored.contentId, 'book123');
      expect(restored.events.length, 5);
      expect(restored.snapshots.length, 2);
    });

    test('Magic bytes 검증', () async {
      final path = '${tempDir.path}/invalid.obt';
      await File(
        path,
      ).writeAsBytes([0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00]);

      expect(
        () => TimelineFile.read(path),
        throwsA(isA<FormatException>()),
      );
    });

    test('미지원 포맷 버전 거부', () async {
      final path = '${tempDir.path}/future.obt';
      final bytes = BytesBuilder()
        ..add(TimelineFile.magicBytes)
        ..add([0xE7, 0x03, 0x00, 0x00]) // version 999
        ..add([0x00]);
      await File(path).writeAsBytes(bytes.toBytes());

      expect(
        () => TimelineFile.read(path),
        throwsA(isA<FormatException>()),
      );
    });

    test('readFormatVersion — 유효한 파일', () async {
      final path = '${tempDir.path}/valid.obt';
      await TimelineFile.write(path, _createSampleTimeline());

      final version = await TimelineFile.readFormatVersion(path);
      expect(version, TimelineFile.currentFormatVersion);
    });

    test('readFormatVersion — 존재하지 않는 파일', () async {
      final version = await TimelineFile.readFormatVersion(
        '${tempDir.path}/none.obt',
      );
      expect(version, -1);
    });

    test('isValidObtFile', () async {
      final validPath = '${tempDir.path}/valid.obt';
      await TimelineFile.write(validPath, _createSampleTimeline());
      expect(await TimelineFile.isValidObtFile(validPath), isTrue);

      final invalidPath = '${tempDir.path}/invalid.txt';
      await File(invalidPath).writeAsString('not an obt file');
      expect(await TimelineFile.isValidObtFile(invalidPath), isFalse);
    });

    test('.obt 파일 크기가 경량 (이벤트 메타만)', () async {
      final path = '${tempDir.path}/size_test.obt';
      await TimelineFile.write(path, _createSampleTimeline());

      final fileSize = await File(path).length();
      // 5개 이벤트 + 2개 스냅샷 + 메타 → 수 KB 이내
      expect(fileSize, lessThan(5000));
    });
  });

  group('ContentFingerprintUtil', () {
    test('동일 파라미터로 동일 해시 생성', () {
      final fp1 = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1000, 'p2': 2000},
      );

      final fp2 = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1000, 'p2': 2000},
      );

      expect(fp1.hash, equals(fp2.hash));
    });

    test('다른 contentId로 다른 해시', () {
      final fp1 = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1'],
        pageBinSizes: {'p1': 1000},
      );

      final fp2 = ContentFingerprintUtil.generate(
        contentId: 'book456',
        pageIds: ['p1'],
        pageBinSizes: {'p1': 1000},
      );

      expect(fp1.hash, isNot(equals(fp2.hash)));
    });

    test('verify — 일치', () {
      final fp = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1000, 'p2': 2000},
      );

      final result = ContentFingerprintUtil.verify(
        expected: fp,
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1000, 'p2': 2000},
      );

      expect(result, isNull); // null = 일치
    });

    test('verify — 불일치', () {
      final fp = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1000, 'p2': 2000},
      );

      final result = ContentFingerprintUtil.verify(
        expected: fp,
        contentId: 'book456',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1000, 'p2': 2000},
      );

      expect(result, isNotNull);
      expect(result, contains('mismatch'));
    });

    test('메타데이터 포함', () {
      final fp = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1'],
        pageBinSizes: {'p1': 1000},
        metadata: {'bookId': 'abc', 'title': '수학1'},
      );

      expect(fp.metadata['bookId'], 'abc');
      expect(fp.metadata['title'], '수학1');
    });
  });
}
