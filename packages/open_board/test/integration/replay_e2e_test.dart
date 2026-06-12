import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/events/scribble_event_bridge.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/replay/content_fingerprint_util.dart';
import 'package:open_board/src/module/replay/scribble_replay_controller.dart';
import 'package:open_board/src/module/replay/scribble_timeline_recorder.dart';
import 'package:open_board/src/module/replay/stroke_animator.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';
import 'package:open_board/src/module/replay/timeline_migrator.dart';
import 'package:open_board/src/module/scribble_controller.dart';

class FakePageProvider implements ScribblePageProvider {
  String? lastActiveKey;
  final Map<String, ScribbleController> _controllers = {};
  final Map<String, Scribble> _scribbles = {};

  @override
  ScribbleController getController(String key) {
    return _controllers.putIfAbsent(key, ScribbleController.new);
  }

  @override
  bool hasController(String key) => _controllers.containsKey(key);

  @override
  bool isPageEmpty(String key) {
    final controller = _controllers[key];
    if (controller == null) return true;
    return controller.isEmpty;
  }

  @override
  void setActiveController(String key) => lastActiveKey = key;

  @override
  Future<bool> saveScribble(
    String key,
    Scribble scribble, {
    bool immediate = false,
  }) async {
    _scribbles[key] = scribble;
    return true;
  }

  @override
  Future<Scribble?> loadScribble(String key) async => _scribbles[key];

  @override
  Future<bool> deleteScribble(String key) async {
    _controllers.remove(key);
    _scribbles.remove(key);
    return true;
  }

  @override
  void evictController(String key) {
    _controllers.remove(key)?.dispose();
    _scribbles.remove(key);
  }
}

void main() {
  group('Replay E2E — 녹화 → 저장 → 재생', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('replay_e2e_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('전체 파이프라인: 녹화 → .obt 저장 → .obt 로드 → 재생', () async {
      // === Phase 1: 녹화 ===
      final provider = FakePageProvider();
      final book = ScribbleBookController(
        pageIds: ['page1', 'page2'],
        contentId: 'book123',
        pageProvider: provider,
      );

      final recorder = ScribbleTimelineRecorder(
        contentId: 'book123',
        pageIds: ['page1', 'page2'],
      );

      // 녹화 시작
      book.startRecording();
      recorder.start(book.eventStream);

      // 이벤트 발행: 스트로크 추가
      book.emitEvent(
        StrokeAddedEvent(
          pageId: 'page1',
          stroke: Stroke(points: [Point(x: 10, y: 20)]),
          strokeIndex: 0,
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 페이지 전환
      book.emitEvent(
        PageChangedEvent(
          fromIndex: 0,
          toIndex: 1,
          fromPageId: 'page1',
          toPageId: 'page2',
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 스트로크 추가
      book.emitEvent(
        StrokeAddedEvent(
          pageId: 'page2',
          stroke: Stroke(points: [Point(x: 30, y: 40)]),
          strokeIndex: 0,
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // === Phase 2: .obt 저장 ===
      final obtPath = '${tempDir.path}/session.obt';
      final timeline = await recorder.stopAndSave(obtPath);
      book.stopRecording();

      // 저장 검증
      expect(await TimelineFile.isValidObtFile(obtPath), isTrue);
      expect(timeline.events.length, 3);
      expect(timeline.contentId, 'book123');
      expect(timeline.pageIds, ['page1', 'page2']);
      expect(timeline.snapshots.isNotEmpty, isTrue);

      // === Phase 3: .obt 로드 → 재생 ===
      final replay = ScribbleReplayController();
      await replay.loadFromFile(obtPath);

      expect(replay.state, ReplayState.paused);
      expect(replay.eventCount, 3);

      // 재생 시 이벤트 수집
      final replayedEvents = <ScribbleBookEvent>[];
      replay.onEvent.listen(replayedEvents.add);

      // seek으로 모든 이벤트 발행
      replay.seek(replay.duration);
      await Future<void>.delayed(.zero);

      // 원본과 재생된 이벤트 구조 일치 검증
      expect(replayedEvents.length, 3);
      expect(replayedEvents[0], isA<StrokeAddedEvent>());
      expect(replayedEvents[1], isA<PageChangedEvent>());
      expect(replayedEvents[2], isA<StrokeAddedEvent>());

      final pageEvent = replayedEvents[1] as PageChangedEvent;
      expect(pageEvent.fromPageId, 'page1');
      expect(pageEvent.toPageId, 'page2');

      // 정리
      replay.dispose();
      book.dispose();
    });

    test('.obt 파일 라운드트립 무결성', () async {
      final original = ScribbleTimeline(
        contentId: 'test-content',
        startTimestamp: Int64(1000),
        endTimestamp: Int64(5000),
        version: '1.0.0',
        pageIds: ['p1', 'p2', 'p3'],
        events: [
          TimelineEvent(
            timestamp: Int64(1000),
            event: const TlPageChanged(
              fromIndex: -1,
              toIndex: 0,
              fromPageId: '',
              toPageId: 'p1',
            ),
          ),
          TimelineEvent(
            timestamp: Int64(2000),
            event: const TlStrokeAdded(pageId: 'p1', strokeIndex: 0),
          ),
          TimelineEvent(
            timestamp: Int64(3000),
            event: const TlUndo(pageId: 'p1'),
          ),
          TimelineEvent(
            timestamp: Int64(4000),
            event: const TlRedo(pageId: 'p1'),
          ),
          TimelineEvent(
            timestamp: Int64(4500),
            event: const TlPageCleared(pageId: 'p1'),
          ),
        ],
        snapshots: [
          TimelineSnapshot(
            offsetMicros: Int64(0),
            activePageIndex: 0,
            pageStrokeCounts: {'p1': 0, 'p2': 0, 'p3': 0},
          ),
        ],
        contentFingerprint: const ContentFingerprint(
          hash: 'abc123',
          algorithm: 'sha256',
          metadata: {'bookId': 'test'},
        ),
      );

      final path = '${tempDir.path}/roundtrip.obt';
      await TimelineFile.write(path, original);
      final restored = await TimelineFile.read(path);

      expect(restored.contentId, original.contentId);
      expect(restored.version, original.version);
      expect(restored.pageIds, original.pageIds);
      expect(restored.events.length, original.events.length);
      expect(restored.snapshots.length, original.snapshots.length);
      expect(restored.contentFingerprint?.hash, 'abc123');

      // 이벤트 타입 보존
      expect(restored.events[0].event, isA<TlPageChanged>());
      expect(restored.events[1].event, isA<TlStrokeAdded>());
      expect(restored.events[2].event, isA<TlUndo>());
      expect(restored.events[3].event, isA<TlRedo>());
      expect(restored.events[4].event, isA<TlPageCleared>());
    });

    test('StrokeAnimator — 부분 스트로크 → 전체 스트로크 진행', () {
      final stroke = Stroke(
        points: [
          Point(x: 0, y: 0, timestamp: Int64(100)),
          Point(x: 10, y: 10, timestamp: Int64(200)),
          Point(x: 20, y: 20, timestamp: Int64(300)),
          Point(x: 30, y: 30, timestamp: Int64(400)),
          Point(x: 40, y: 40, timestamp: Int64(500)),
        ],
        color: 0xFF000000,
        ink: 'pen',
      );

      // 시작 전
      expect(StrokeAnimator.createPartialStroke(stroke, 50), isNull);
      expect(StrokeAnimator.getProgress(stroke, 50), 0);

      // 중간
      final partial = StrokeAnimator.createPartialStroke(stroke, 300);
      expect(partial, isNotNull);
      expect(partial!.points.length, 3);
      expect(StrokeAnimator.getProgress(stroke, 300), 0.5);

      // 완료
      final complete = StrokeAnimator.createPartialStroke(stroke, 500);
      expect(identical(complete, stroke), isTrue);
      expect(StrokeAnimator.getProgress(stroke, 500), 1.0);
    });

    test('TimelineMigrator — 현재 버전 호환성', () {
      expect(
        TimelineMigrator.canMigrate(TimelineFile.currentFormatVersion),
        isTrue,
      );

      final timeline = ScribbleTimeline(contentId: 'test');
      final result = TimelineMigrator.migrate(
        timeline,
        from: TimelineFile.currentFormatVersion,
      );
      expect(identical(result, timeline), isTrue);
    });

    test('ScribbleEventBridge — BookController 연동', () async {
      final provider = FakePageProvider();
      final book = ScribbleBookController(
        pageIds: ['page1'],
        contentId: 'test',
        pageProvider: provider,
      );

      final bridge = ScribbleEventBridge(book);
      book.startRecording();
      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      // 스트로크 추가로 이벤트 발행
      final scribble = Scribble(
        strokes: [
          Stroke(points: [Point(x: 5, y: 5)]),
        ],
      );
      book.activeController.loadScribble(scribble);

      await Future<void>.delayed(.zero);

      expect(events.whereType<StrokeAddedEvent>().length, 1);

      bridge.detach();
      book.dispose();
    });

    test('ContentFingerprintUtil — 생성/검증', () {
      final fp = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1024, 'p2': 2048},
      );

      expect(fp.hash, isNotEmpty);
      expect(fp.algorithm, 'fnv1a');

      // 동일 입력 → 동일 해시
      final fp2 = ContentFingerprintUtil.generate(
        contentId: 'book123',
        pageIds: ['p1', 'p2'],
        pageBinSizes: {'p1': 1024, 'p2': 2048},
      );
      expect(fp.hash, fp2.hash);

      // 검증 — 일치
      expect(
        ContentFingerprintUtil.verify(
          expected: fp,
          contentId: 'book123',
          pageIds: ['p1', 'p2'],
          pageBinSizes: {'p1': 1024, 'p2': 2048},
        ),
        isNull,
      );

      // 검증 — 불일치
      expect(
        ContentFingerprintUtil.verify(
          expected: fp,
          contentId: 'different',
          pageIds: ['p1', 'p2'],
          pageBinSizes: {'p1': 1024, 'p2': 2048},
        ),
        isNotNull,
      );
    });
  });
}
