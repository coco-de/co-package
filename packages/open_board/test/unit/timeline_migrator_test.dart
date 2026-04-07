import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';
import 'package:open_board/src/module/replay/timeline_migrator.dart';

ScribbleTimeline _createSampleTimeline() => ScribbleTimeline(
      contentId: 'book123',
      startTimestamp: Int64(1000000),
      endTimestamp: Int64(61000000),
      version: '1.0.0',
      pageIds: ['page1', 'page2'],
      events: [
        TimelineEvent(
          timestamp: Int64(1000000),
          event: const TlStrokeAdded(pageId: 'page1', strokeIndex: 0),
        ),
      ],
      snapshots: [
        TimelineSnapshot(
          offsetMicros: Int64(0),
          activePageIndex: 0,
          pageStrokeCounts: {'page1': 0},
        ),
      ],
    );

void main() {
  group('TimelineMigrator', () {
    test('현재 버전 타임라인은 그대로 반환', () {
      final timeline = _createSampleTimeline();
      final result = TimelineMigrator.migrate(
        timeline,
        from: TimelineFile.currentFormatVersion,
      );

      expect(identical(result, timeline), isTrue);
    });

    test('잘못된 버전(0 이하)은 FormatException', () {
      expect(
        () => TimelineMigrator.migrate(_createSampleTimeline(), from: 0),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => TimelineMigrator.migrate(_createSampleTimeline(), from: -1),
        throwsA(isA<FormatException>()),
      );
    });

    test('canMigrate — 현재 버전은 true', () {
      expect(
        TimelineMigrator.canMigrate(TimelineFile.currentFormatVersion),
        isTrue,
      );
    });

    test('canMigrate — 잘못된 버전은 false', () {
      expect(TimelineMigrator.canMigrate(0), isFalse);
      expect(TimelineMigrator.canMigrate(-1), isFalse);
    });
  });

  group('TimelineFile + Migrator 통합', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('migrator_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('현재 버전 .obt 파일은 마이그레이션 없이 정상 로드', () async {
      final path = '${tempDir.path}/current.obt';
      final original = _createSampleTimeline();

      await TimelineFile.write(path, original);
      final restored = await TimelineFile.read(path);

      expect(restored.contentId, 'book123');
      expect(restored.events.length, 1);
      expect(restored.events[0].event, isA<TlStrokeAdded>());
    });

    test('미래 버전 .obt 파일은 FormatException', () async {
      final path = '${tempDir.path}/future.obt';
      final bytes = BytesBuilder()
        ..add(TimelineFile.magicBytes)
        ..add(_uint32ToBytes(999))
        ..add([0x00]);
      await File(path).writeAsBytes(bytes.toBytes());

      expect(
        () => TimelineFile.read(path),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported'),
          ),
        ),
      );
    });
  });
}

List<int> _uint32ToBytes(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}
