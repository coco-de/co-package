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
