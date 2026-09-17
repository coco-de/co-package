import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/events/scribble_event_bridge.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
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
  void setActiveController(String key) {
    lastActiveKey = key;
  }

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
  late FakePageProvider provider;
  late ScribbleBookController book;
  late ScribbleEventBridge bridge;

  setUp(() {
    provider = FakePageProvider();
    book = ScribbleBookController(
      pageIds: ['page1', 'page2'],
      contentId: 'test',
      pageProvider: provider,
    );
    bridge = ScribbleEventBridge(book);
  });

  tearDown(() {
    bridge.detach();
    book.dispose();
  });

  group('ScribbleEventBridge', () {
    test('attach/detach 상태 관리', () {
      expect(bridge.isAttached, isFalse);

      bridge.attach();
      expect(bridge.isAttached, isTrue);

      bridge.detach();
      expect(bridge.isAttached, isFalse);
    });

    test('중복 attach 무시', () {
      bridge.attach();
      bridge.attach(); // 두 번째 호출은 무시
      expect(bridge.isAttached, isTrue);

      bridge.detach();
      expect(bridge.isAttached, isFalse);
    });

    test('스트로크 추가 시 StrokeAddedEvent 발행', () async {
      book.startRecording();
      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      // 스트로크 추가
      final scribble = Scribble(
        strokes: [
          Stroke(points: [Point(x: 10, y: 20)]),
        ],
      );
      book.activeController.loadScribble(scribble);

      // 이벤트 전파 대기
      await Future<void>.delayed(.zero);

      final strokeEvents = events.whereType<StrokeAddedEvent>().toList();
      expect(strokeEvents, hasLength(1));
      expect(strokeEvents.first.pageId, 'page1');
      expect(strokeEvents.first.strokeIndex, 0);
    });

    test('스트로크 제거 시 StrokeRemovedEvent 발행', () async {
      book.startRecording();

      // 먼저 스트로크가 있는 상태로 시작
      final initialScribble = Scribble(
        strokes: [
          Stroke(points: [Point(x: 10, y: 20)]),
          Stroke(points: [Point(x: 30, y: 40)]),
        ],
      );
      book.activeController.loadScribble(initialScribble);

      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      // 스트로크 하나 제거 (1개로 줄임)
      final reducedScribble = Scribble(
        strokes: [
          Stroke(points: [Point(x: 10, y: 20)]),
        ],
      );
      book.activeController.loadScribble(reducedScribble);

      await Future<void>.delayed(.zero);

      final removeEvents = events.whereType<StrokeRemovedEvent>().toList();
      expect(removeEvents, hasLength(1));
      expect(removeEvents.first.pageId, 'page1');
      expect(removeEvents.first.strokeIndex, 1);
    });

    test('중간 스트로크 제거 시 실제 인덱스로 StrokeRemovedEvent 발행', () async {
      // 카운트 휴리스틱은 어떤 스트로크가 지워졌는지 모른 채 항상 마지막
      // 인덱스를 발행해, 리플레이/원격에서 엉뚱한 스트로크가 삭제됐다.
      book.startRecording();

      final s0 = Stroke(points: [Point(x: 10, y: 10)]);
      final s1 = Stroke(points: [Point(x: 20, y: 20)]);
      final s2 = Stroke(points: [Point(x: 30, y: 30)]);
      book.activeController.loadScribble(Scribble(strokes: [s0, s1, s2]));

      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      // 첫 번째(s0)만 제거 — 지우개로 중간 스트로크를 지운 상황
      book.activeController.loadScribble(
        Scribble(strokes: [s1.deepCopy(), s2.deepCopy()]),
      );

      await Future<void>.delayed(.zero);

      final removeEvents = events.whereType<StrokeRemovedEvent>().toList();
      expect(removeEvents, hasLength(1));
      expect(
        removeEvents.first.strokeIndex,
        0,
        reason: '항상 마지막 인덱스를 발행하면 수신 측에서 s0 대신 s2가 지워진다',
      );
    });

    test('비연속 다중 제거는 내림차순 인덱스로 발행', () async {
      book.startRecording();

      final s0 = Stroke(points: [Point(x: 10, y: 10)]);
      final s1 = Stroke(points: [Point(x: 20, y: 20)]);
      final s2 = Stroke(points: [Point(x: 30, y: 30)]);
      book.activeController.loadScribble(Scribble(strokes: [s0, s1, s2]));

      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      // s0, s2 제거 (비연속)
      book.activeController.loadScribble(
        Scribble(strokes: [s1.deepCopy()]),
      );

      await Future<void>.delayed(.zero);

      final removeEvents = events.whereType<StrokeRemovedEvent>().toList();
      expect(removeEvents.map((e) => e.strokeIndex).toList(), [2, 0]);
    });

    test('카운트 동률 교체(도형 인식)는 Removed+Added 쌍으로 발행', () async {
      // 도형 인식은 마지막 스트로크를 removeLast+add로 교체한다(net 0).
      // 카운트 휴리스틱은 이를 감지하지 못해 원격/녹화에 변환 전
      // 자유곡선이 남는 desync가 발생했다.
      book.startRecording();

      final raw = Stroke(points: [Point(x: 10, y: 10)]);
      book.activeController.loadScribble(Scribble(strokes: [raw]));

      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      // 같은 개수, 내용만 교체 (도형 변환 시뮬레이션)
      final shape = Stroke(
        points: [Point(x: 10, y: 10), Point(x: 50, y: 50)],
        shapeType: 'line',
      );
      book.activeController.loadScribble(Scribble(strokes: [shape]));

      await Future<void>.delayed(.zero);

      final removeEvents = events.whereType<StrokeRemovedEvent>().toList();
      final addEvents = events.whereType<StrokeAddedEvent>().toList();
      expect(removeEvents, hasLength(1));
      expect(removeEvents.first.strokeIndex, 0);
      expect(addEvents, hasLength(1));
      expect(
        addEvents.first.stroke.shapeType,
        'line',
        reason: '교체된 최종 스트로크(변환된 도형)가 발행되어야 한다',
      );
    });

    test('detach 후에는 이벤트 발행하지 않음', () async {
      book.startRecording();
      bridge.attach();

      final events = <ScribbleBookEvent>[];
      book.eventStream.listen(events.add);

      bridge.detach();

      // 스트로크 추가 — 이벤트 없어야 함
      final scribble = Scribble(
        strokes: [
          Stroke(points: [Point(x: 10, y: 20)]),
        ],
      );
      book.activeController.loadScribble(scribble);

      await Future<void>.delayed(.zero);

      final strokeEvents = events.whereType<StrokeAddedEvent>().toList();
      expect(strokeEvents, isEmpty);
    });
  });
}
