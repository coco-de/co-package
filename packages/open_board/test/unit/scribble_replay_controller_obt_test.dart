import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/replay/scribble_replay_controller.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';

ScribbleTimeline _createTestTimeline() => ScribbleTimeline(
      contentId: 'book123',
      startTimestamp: Int64(1000000),
      endTimestamp: Int64(5000000),
      version: '1.0.0',
      pageIds: ['page1', 'page2'],
      events: [
        TimelineEvent(
          timestamp: Int64(1000000),
          event: const TlPageChanged(
            fromIndex: -1, toIndex: 0,
            fromPageId: '', toPageId: 'page1',
          ),
        ),
        TimelineEvent(
          timestamp: Int64(2000000),
          event: const TlStrokeAdded(pageId: 'page1', strokeIndex: 0),
        ),
        TimelineEvent(
          timestamp: Int64(3000000),
          event: const TlPageChanged(
            fromIndex: 0, toIndex: 1,
            fromPageId: 'page1', toPageId: 'page2',
          ),
        ),
        TimelineEvent(
          timestamp: Int64(4000000),
          event: const TlStrokeAdded(pageId: 'page2', strokeIndex: 0),
        ),
      ],
      snapshots: [
        TimelineSnapshot(
          offsetMicros: Int64(0),
          activePageIndex: 0,
          pageStrokeCounts: {'page1': 0, 'page2': 0},
        ),
      ],
    );

void main() {
  group('ScribbleReplayController — .obt 로드 확장', () {
    late ScribbleReplayController replay;

    setUp(() {
      replay = ScribbleReplayController();
    });

    tearDown(() {
      replay.dispose();
    });

    test('loadFromTimeline — ScribbleTimeline에서 로드', () {
      final timeline = _createTestTimeline();
      replay.loadFromTimeline(timeline);

      expect(replay.state, ReplayState.paused);
      expect(replay.eventCount, 4);
    });

    test('loadFromTimeline — 이벤트 타입 변환 검증', () async {
      final timeline = _createTestTimeline();
      replay.loadFromTimeline(timeline);

      final events = <ScribbleBookEvent>[];
      replay.onEvent.listen(events.add);

      // seek을 끝까지 이동하여 모든 이벤트 즉시 발행
      replay.seek(replay.duration);
      await Future<void>.delayed(Duration.zero);

      // 4개 이벤트가 모두 발행되어야 함
      expect(events.length, 4);

      // 첫 번째 이벤트는 PageChanged
      expect(events[0], isA<PageChangedEvent>());
      final pageChanged = events[0] as PageChangedEvent;
      expect(pageChanged.toIndex, 0);
      expect(pageChanged.toPageId, 'page1');

      // 두 번째 이벤트는 StrokeAdded
      expect(events[1], isA<StrokeAddedEvent>());
      final strokeAdded = events[1] as StrokeAddedEvent;
      expect(strokeAdded.pageId, 'page1');
      expect(strokeAdded.strokeIndex, 0);
    });

    test('loadFromFile — .obt 파일에서 로드', () async {
      final tempDir = await Directory.systemTemp.createTemp('obt_replay_');
      try {
        final path = '${tempDir.path}/test.obt';
        await TimelineFile.write(path, _createTestTimeline());

        await replay.loadFromFile(path);

        expect(replay.state, ReplayState.paused);
        expect(replay.eventCount, 4);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadFromFile — 잘못된 파일은 FormatException', () async {
      final tempDir = await Directory.systemTemp.createTemp('obt_replay_');
      try {
        final path = '${tempDir.path}/invalid.obt';
        await File(path).writeAsString('not an obt file');

        expect(
          () => replay.loadFromFile(path),
          throwsA(isA<FormatException>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadFromTimeline — 빈 타임라인', () {
      final empty = ScribbleTimeline();
      replay.loadFromTimeline(empty);

      expect(replay.state, ReplayState.idle);
      expect(replay.eventCount, 0);
    });

    test('loadFromTimeline — 모든 이벤트 타입 변환', () {
      final timeline = ScribbleTimeline(
        events: [
          TimelineEvent(
            timestamp: Int64(1),
            event: const TlPageChanged(
              fromIndex: 0, toIndex: 1,
              fromPageId: 'a', toPageId: 'b',
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

      replay.loadFromTimeline(timeline);
      expect(replay.eventCount, 8);
    });
  });
}
