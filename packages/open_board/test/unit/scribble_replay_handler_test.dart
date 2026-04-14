  import 'package:flutter_test/flutter_test.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/events/scribble_book_event.dart';
  import 'package:open_board/src/module/managers/scribble_book_controller.dart';
  import 'package:open_board/src/module/replay/scribble_replay_controller.dart';
  import 'package:open_board/src/module/replay/scribble_replay_handler.dart';
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
  }

  void main() {
    late FakePageProvider provider;
    late ScribbleBookController book;
    late ScribbleReplayController replay;
    late ScribbleReplayHandler handler;

    setUp(() {
      provider = FakePageProvider();
      book = ScribbleBookController(
        pageIds: ['page1', 'page2'],
        contentId: 'test',
        pageProvider: provider,
      );
      replay = ScribbleReplayController();
      handler = ScribbleReplayHandler(
        bookController: book,
        pageProvider: provider,
      );
    });

    tearDown(() {
      handler.detach();
      replay.dispose();
      book.dispose();
    });

    group('ScribbleReplayHandler', () {
      test('attach/detach 라이프사이클', () {
        expect(handler.isAttached, isFalse);

        handler.attach(replay);
        expect(handler.isAttached, isTrue);

        handler.detach();
        expect(handler.isAttached, isFalse);
      });

      test('중복 attach 무시', () {
        handler.attach(replay);
        handler.attach(replay);
        expect(handler.isAttached, isTrue);
      });

      test('PageChangedEvent 수신 시 페이지 전환', () async {
        handler.attach(replay);

        final now = ScribbleBookEvent.now();
        replay.loadTimeline([
          PageChangedEvent(
            fromIndex: 0,
            toIndex: 1,
            fromPageId: 'page1',
            toPageId: 'page2',
            timestampMicros: now,
          ),
        ]);

        // 재생 시작 후 이벤트 처리 대기
        replay.play();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // 페이지 전환 확인
        expect(book.currentPageIndex, 1);
      });

      test('detach 후에는 이벤트 처리하지 않음', () async {
        handler.attach(replay);
        handler.detach();

        final now = ScribbleBookEvent.now();
        replay.loadTimeline([
          PageChangedEvent(
            fromIndex: 0,
            toIndex: 1,
            fromPageId: 'page1',
            toPageId: 'page2',
            timestampMicros: now,
          ),
        ]);

        replay.play();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // 페이지 전환이 일어나지 않아야 함
        expect(book.currentPageIndex, 0);
      });
    });
  }
