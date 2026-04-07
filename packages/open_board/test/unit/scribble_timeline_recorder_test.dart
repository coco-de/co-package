import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/replay/scribble_timeline_recorder.dart';

void main() {
  group('ScribbleTimelineRecorder', () {
    late ScribbleTimelineRecorder recorder;
    late StreamController<ScribbleBookEvent> eventController;

    setUp(() {
      recorder = ScribbleTimelineRecorder(
        contentId: 'book123',
        pageIds: ['page1', 'page2'],
      );
      eventController = StreamController<ScribbleBookEvent>.broadcast();
    });

    tearDown(() {
      if (recorder.isRecording) recorder.stop();
      eventController.close();
    });

    test('start/stop 라이프사이클', () {
      expect(recorder.isRecording, isFalse);

      recorder.start(eventController.stream);
      expect(recorder.isRecording, isTrue);

      final timeline = recorder.stop();
      expect(recorder.isRecording, isFalse);
      expect(timeline.contentId, 'book123');
      expect(timeline.version, '1.0.0');
      expect(timeline.pageIds, ['page1', 'page2']);
    });

    test('중복 start 무시', () {
      recorder.start(eventController.stream);
      recorder.start(eventController.stream); // 무시
      expect(recorder.isRecording, isTrue);
    });

    test('이벤트 수집 — StrokeAdded', () async {
      recorder.start(eventController.stream);

      eventController.add(StrokeAddedEvent(
        pageId: 'page1',
        stroke: _fakeStroke(),
        strokeIndex: 0,
        timestampMicros: ScribbleBookEvent.now(),
      ));

      await Future<void>.delayed(Duration.zero);
      expect(recorder.eventCount, 1);

      final timeline = recorder.stop();
      expect(timeline.events.length, 1);
      expect(timeline.events[0].event, isA<TlStrokeAdded>());

      final event = timeline.events[0].event as TlStrokeAdded;
      expect(event.pageId, 'page1');
      expect(event.strokeIndex, 0);
    });

    test('이벤트 수집 — PageChanged', () async {
      recorder.start(eventController.stream);

      eventController.add(PageChangedEvent(
        fromIndex: 0,
        toIndex: 1,
        fromPageId: 'page1',
        toPageId: 'page2',
        timestampMicros: ScribbleBookEvent.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      final timeline = recorder.stop();
      expect(timeline.events[0].event, isA<TlPageChanged>());

      final event = timeline.events[0].event as TlPageChanged;
      expect(event.fromIndex, 0);
      expect(event.toIndex, 1);
    });

    test('이벤트 수집 — 모든 이벤트 타입', () async {
      recorder.start(eventController.stream);

      final now = ScribbleBookEvent.now();
      final events = <ScribbleBookEvent>[
        PageChangedEvent(
          fromIndex: 0, toIndex: 1,
          fromPageId: 'page1', toPageId: 'page2',
          timestampMicros: now,
        ),
        StrokeAddedEvent(
          pageId: 'page1', stroke: _fakeStroke(), strokeIndex: 0,
          timestampMicros: now + 1,
        ),
        StrokeRemovedEvent(
          pageId: 'page1', strokeIndex: 0,
          timestampMicros: now + 2,
        ),
        UndoPerformedEvent(pageId: 'page1', timestampMicros: now + 3),
        RedoPerformedEvent(pageId: 'page1', timestampMicros: now + 4),
        PageAddedEvent(pageId: 'page3', atIndex: 2, timestampMicros: now + 5),
        PageRemovedEvent(pageId: 'page3', atIndex: 2, timestampMicros: now + 6),
        PageClearedEvent(pageId: 'page1', timestampMicros: now + 7),
      ];

      for (final event in events) {
        eventController.add(event);
      }

      await Future<void>.delayed(Duration.zero);

      final timeline = recorder.stop();
      expect(timeline.events.length, 8);
      expect(timeline.events[0].event, isA<TlPageChanged>());
      expect(timeline.events[1].event, isA<TlStrokeAdded>());
      expect(timeline.events[2].event, isA<TlStrokeRemoved>());
      expect(timeline.events[3].event, isA<TlUndo>());
      expect(timeline.events[4].event, isA<TlRedo>());
      expect(timeline.events[5].event, isA<TlPageAdded>());
      expect(timeline.events[6].event, isA<TlPageRemoved>());
      expect(timeline.events[7].event, isA<TlPageCleared>());
    });

    test('초기 스냅샷 생성', () {
      recorder.start(eventController.stream);

      final timeline = recorder.stop();
      expect(timeline.snapshots.length, 1);
      expect(timeline.snapshots[0].offsetMicros, Int64(0));
      expect(timeline.snapshots[0].activePageIndex, 0);
      expect(timeline.snapshots[0].pageStrokeCounts['page1'], 0);
      expect(timeline.snapshots[0].pageStrokeCounts['page2'], 0);
    });

    test('스냅샷 — 스트로크 카운트 추적', () async {
      recorder.start(eventController.stream);

      eventController.add(StrokeAddedEvent(
        pageId: 'page1',
        stroke: _fakeStroke(),
        strokeIndex: 0,
        timestampMicros: ScribbleBookEvent.now(),
      ));
      eventController.add(StrokeAddedEvent(
        pageId: 'page1',
        stroke: _fakeStroke(),
        strokeIndex: 1,
        timestampMicros: ScribbleBookEvent.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      final timeline = recorder.stop();
      // 초기 스냅샷만 존재 (30초 미경과)
      expect(timeline.snapshots.length, 1);
      // 이벤트 카운트 검증
      expect(timeline.events.length, 2);
    });

    test('start/end timestamp 설정', () {
      final beforeStart = ScribbleBookEvent.now();
      recorder.start(eventController.stream);
      final afterStart = ScribbleBookEvent.now();

      final timeline = recorder.stop();
      final afterStop = ScribbleBookEvent.now();

      expect(
        timeline.startTimestamp.toInt(),
        greaterThanOrEqualTo(beforeStart),
      );
      expect(
        timeline.startTimestamp.toInt(),
        lessThanOrEqualTo(afterStart),
      );
      expect(
        timeline.endTimestamp.toInt(),
        lessThanOrEqualTo(afterStop),
      );
    });
  });
}

Stroke _fakeStroke() => Stroke(points: [Point(x: 10, y: 20)]);
