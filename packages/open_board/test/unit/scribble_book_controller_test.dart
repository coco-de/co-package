import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/scribble_controller.dart';

/// 테스트용 ScribblePageProvider
class FakePageProvider implements ScribblePageProvider {
  String? lastActiveKey;
  int saveCount = 0;
  int deleteCount = 0;
  int evictCount = 0;
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
    saveCount++;
    _scribbles[key] = scribble;
    return true;
  }

  @override
  Future<Scribble?> loadScribble(String key) async {
    return _scribbles[key];
  }

  @override
  Future<bool> deleteScribble(String key) async {
    deleteCount++;
    _controllers.remove(key);
    _scribbles.remove(key);
    return true;
  }

  @override
  void evictController(String key) {
    evictCount++;
    _controllers.remove(key)?.dispose();
    _scribbles.remove(key);
  }
}

/// 테스트용 PersistenceDelegate
class FakePersistenceDelegate implements ScribblePersistenceDelegate {
  final Map<String, Scribble> storage = {};
  int loadCount = 0;
  int saveCount = 0;
  int deleteCount = 0;

  @override
  Future<Scribble?> loadScribble(String key) async {
    loadCount++;
    return storage[key];
  }

  @override
  Future<void> saveScribble(String key, Scribble scribble) async {
    saveCount++;
    storage[key] = scribble;
  }

  @override
  Future<void> deleteScribble(String key) async {
    deleteCount++;
    storage.remove(key);
  }
}

void main() {
  late FakePageProvider provider;

  setUp(() {
    provider = FakePageProvider();
  });

  group('ScribbleBookController', () {
    group('초기화', () {
      test('pageIds와 contentId로 생성할 수 있다', () {
        final book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'book123',
          pageProvider: provider,
        );

        expect(book.pageCount, 3);
        expect(book.currentPageIndex, 0);
        expect(book.currentPageId, 'page1');
        expect(book.contentId, 'book123');

        book.dispose();
      });

      test('initialPageIndex를 지정할 수 있다', () {
        final book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'book123',
          pageProvider: provider,
          initialPageIndex: 1,
        );

        expect(book.currentPageIndex, 1);
        expect(book.currentPageId, 'page2');

        book.dispose();
      });

      test('빈 pageIds로 생성하면 assert 에러가 발생한다', () {
        expect(
          () => ScribbleBookController(
            pageIds: [],
            contentId: 'book123',
            pageProvider: provider,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('범위 밖 initialPageIndex로 생성하면 assert 에러가 발생한다', () {
        expect(
          () => ScribbleBookController(
            pageIds: ['page1'],
            contentId: 'book123',
            pageProvider: provider,
            initialPageIndex: 5,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('페이지 상태 접근자', () {
      late ScribbleBookController book;

      setUp(() {
        book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'test',
          pageProvider: provider,
        );
      });

      tearDown(() => book.dispose());

      test('pageIds는 읽기 전용 복사본을 반환한다', () {
        final ids = book.pageIds;
        expect(ids, ['page1', 'page2', 'page3']);

        expect(() => ids.add('page4'), throwsA(isA<UnsupportedError>()));
      });

      test('hasNextPage / hasPreviousPage', () {
        expect(book.hasPreviousPage, isFalse);
        expect(book.hasNextPage, isTrue);
      });
    });

    group('activeController 접근', () {
      test('현재 페이지의 ScribbleController를 반환한다', () {
        final book = ScribbleBookController(
          pageIds: ['page1', 'page2'],
          contentId: 'test',
          pageProvider: provider,
        );

        final controller = book.activeController;
        expect(controller, isNotNull);
        expect(controller, isA<ScribbleController>());

        book.dispose();
      });

      test('controllerAt으로 특정 페이지 컨트롤러를 얻는다', () {
        final book = ScribbleBookController(
          pageIds: ['page1', 'page2'],
          contentId: 'test',
          pageProvider: provider,
        );

        final c0 = book.controllerAt(0);
        final c1 = book.controllerAt(1);
        expect(c0, isNotNull);
        expect(c1, isNotNull);

        book.dispose();
      });
    });

    group('페이지 전환 (goToPage)', () {
      late ScribbleBookController book;

      setUp(() {
        book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'nav_test',
          pageProvider: provider,
        );
      });

      tearDown(() => book.dispose());

      test('goToPage로 페이지를 전환할 수 있다', () async {
        await book.goToPage(2);

        expect(book.currentPageIndex, 2);
        expect(book.currentPageId, 'page3');
      });

      test('같은 페이지로 전환 시 무시된다', () async {
        var notified = false;
        book.addListener(() => notified = true);

        await book.goToPage(0);

        expect(notified, isFalse);
      });

      test('goToNextPage / goToPreviousPage', () async {
        await book.goToNextPage();
        expect(book.currentPageIndex, 1);

        await book.goToPreviousPage();
        expect(book.currentPageIndex, 0);

        // 첫 페이지에서 이전 페이지 이동 무시
        await book.goToPreviousPage();
        expect(book.currentPageIndex, 0);
      });

      test('페이지 전환 시 이벤트가 발행된다', () async {
        final events = <PageChangeEvent>[];
        book.onPageChanged.listen(events.add);

        await book.goToPage(1);
        await pumpEventQueue();

        expect(events.length, 1);
        expect(events[0].fromIndex, 0);
        expect(events[0].toIndex, 1);
        expect(events[0].fromPageId, 'page1');
        expect(events[0].toPageId, 'page2');
      });

      test('페이지 전환 시 활성 컨트롤러가 변경된다', () async {
        await book.goToPage(1);

        expect(provider.lastActiveKey, 'nav_test/page2');
      });
    });

    group('페이지 CRUD', () {
      late ScribbleBookController book;

      setUp(() {
        book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'crud_test',
          pageProvider: provider,
        );
      });

      tearDown(() => book.dispose());

      test('addPage — 마지막에 추가', () {
        book.addPage(pageId: 'page4');

        expect(book.pageCount, 4);
        expect(book.pageIds.last, 'page4');
      });

      test('addPage — 특정 위치에 삽입', () {
        book.addPage(pageId: 'inserted', atIndex: 1);

        expect(book.pageCount, 4);
        expect(book.pageIds[1], 'inserted');
        expect(book.pageIds[2], 'page2');
      });

      test('addPage — 현재 페이지 앞에 삽입 시 인덱스 조정', () async {
        await book.goToPage(2); // page3에 위치
        book.addPage(pageId: 'inserted', atIndex: 0);

        expect(book.currentPageIndex, 3); // 2 → 3으로 조정됨
        expect(book.currentPageId, 'page3');
      });

      test('addPage — pageId 미제공 시 자동 생성', () {
        book.addPage();

        expect(book.pageCount, 4);
        expect(book.pageIds.last, startsWith('page_'));
      });

      test('removePage — 다른 페이지 삭제', () async {
        await book.removePage(2);

        expect(book.pageCount, 2);
        expect(book.pageIds, ['page1', 'page2']);
        expect(book.currentPageIndex, 0);
      });

      test('removePage — 현재 페이지 앞 삭제 시 인덱스 조정', () async {
        await book.goToPage(2);
        await book.removePage(0);

        expect(book.currentPageIndex, 1); // 2 → 1로 조정됨
        expect(book.currentPageId, 'page3');
      });

      test('removePage — 마지막 1페이지는 삭제 불가', () async {
        final singleBook = ScribbleBookController(
          pageIds: ['only'],
          contentId: 'single',
          pageProvider: provider,
        );

        await singleBook.removePage(0);
        expect(singleBook.pageCount, 1);

        singleBook.dispose();
      });

      test('removePage — 캐시 정리 확인', () async {
        await book.removePage(2);
        expect(provider.deleteCount, 1);
      });

      test('reorderPage — 순서 변경', () {
        book.reorderPage(0, 3); // page1을 맨 끝으로

        expect(book.pageIds, ['page2', 'page3', 'page1']);
      });

      test('reorderPage — 현재 페이지 이동 시 인덱스 추적', () {
        // page1(0)이 현재 → page1을 뒤로 이동
        book.reorderPage(0, 3);

        expect(book.currentPageIndex, 2); // page1의 새 위치
        expect(book.currentPageId, 'page1');
      });
    });

    group('PersistenceDelegate', () {
      late ScribbleBookController book;
      late FakePersistenceDelegate delegate;

      setUp(() {
        delegate = FakePersistenceDelegate();
        book = ScribbleBookController(
          pageIds: ['page1', 'page2'],
          contentId: 'persist_test',
          pageProvider: provider,
          persistenceDelegate: delegate,
        );
      });

      tearDown(() => book.dispose());

      test('goToPage 시 delegate.saveScribble이 호출된다', () async {
        // activeController 접근하여 컨트롤러 생성
        book.activeController;
        await book.goToPage(1);

        expect(delegate.saveCount, greaterThanOrEqualTo(1));
      });

      test('removePage 시 delegate.deleteScribble이 호출된다', () async {
        book.addPage(pageId: 'page3');
        await book.removePage(2);

        expect(delegate.deleteCount, 1);
      });

      test('removePage는 provider 컨트롤러 캐시도 정리한다 (필기 부활 방지)', () async {
        book.addPage(pageId: 'page3');
        await book.removePage(2);

        expect(
          provider.evictCount,
          1,
          reason: '컨트롤러 캐시를 정리하지 않으면 동일 키 재사용 시 삭제된 필기가 부활한다',
        );
      });

      test('suppressPersistence 모드에서는 페이지 전환/삭제가 저장소를 건드리지 않는다', () async {
        // 리플레이 핸들러가 이 컨트롤러를 구동할 때, 리플레이의 중간 캔버스
        // 상태가 원본 .bin을 덮어쓰거나 실제 페이지 데이터를 삭제하면 안 된다.
        book.suppressPersistence = true;
        book.activeController;

        final saveBefore = delegate.saveCount;
        await book.goToPage(1);
        expect(delegate.saveCount, saveBefore, reason: '전환 저장이 차단되어야 한다');

        book.addPage(pageId: 'replay_page');
        final deleteBefore = delegate.deleteCount;
        final evictBefore = provider.evictCount;
        await book.removePage(book.pageCount - 1);

        expect(delegate.deleteCount, deleteBefore, reason: '저장소 삭제 차단');
        expect(provider.evictCount, evictBefore, reason: '컨트롤러 캐시 보존');
        expect(book.pageIds, isNot(contains('replay_page')), reason: '표시 목록은 갱신');
      });

      test('마지막 페이지 삭제 후 addPage가 삭제된 pageId를 재사용하지 않는다', () async {
        // 자동 생성 id로 페이지 추가 → 삭제 → 다시 추가
        book.addPage();
        final generatedId = book.pageIds.last;
        await book.removePage(book.pageCount - 1);

        book.addPage();
        expect(
          book.pageIds.last,
          isNot(generatedId),
          reason: 'pageId 재사용 시 캐시에 남은 삭제된 필기가 새 페이지에 표시된다',
        );
      });
    });

    group('indexOfPage', () {
      test('pageId로 인덱스를 조회할 수 있다', () {
        final book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'test',
          pageProvider: provider,
        );

        expect(book.indexOfPage('page2'), 1);
        expect(book.indexOfPage('unknown'), -1);

        book.dispose();
      });
    });

    group('양면 모드 (Double Page)', () {
      late ScribbleBookController book;

      setUp(() {
        // 5페이지: page1(단면), page2+page3, page4+page5
        book = ScribbleBookController(
          pageIds: ['p1', 'p2', 'p3', 'p4', 'p5'],
          contentId: 'double_test',
          pageProvider: provider,
          firstPageSingle: true,
        );
      });

      tearDown(() => book.dispose());

      test('기본값은 단면 모드', () {
        expect(book.isDoublePageMode, isFalse);
      });

      test('toggleDoublePageMode로 양면 모드 전환', () async {
        await book.toggleDoublePageMode();
        expect(book.isDoublePageMode, isTrue);

        await book.toggleDoublePageMode();
        expect(book.isDoublePageMode, isFalse);
      });

      test('setDoublePageMode로 명시적 설정', () async {
        await book.setDoublePageMode(true);
        expect(book.isDoublePageMode, isTrue);

        // 같은 값으로 설정 시 무시
        await book.setDoublePageMode(true);
        expect(book.isDoublePageMode, isTrue);
      });

      group('spreadCount 계산 (firstPageSingle: true)', () {
        test('단면 모드에서는 페이지 수와 동일', () {
          expect(book.spreadCount, 5);
        });

        test('양면 모드: 첫 페이지 단면 + 나머지 쌍', () async {
          await book.toggleDoublePageMode();
          // spread 0 = p1, spread 1 = p2+p3, spread 2 = p4+p5
          expect(book.spreadCount, 3);
        });
      });

      group('currentSpreadIndex', () {
        test('단면 모드에서는 currentPageIndex와 동일', () {
          expect(book.currentSpreadIndex, 0);
        });

        test('양면 모드: 첫 페이지는 spread 0', () async {
          await book.toggleDoublePageMode();
          expect(book.currentSpreadIndex, 0);
        });

        test('양면 모드: page2(index 1)는 spread 1', () async {
          await book.goToPage(1);
          await book.toggleDoublePageMode();
          expect(book.currentSpreadIndex, 1);
        });

        test('양면 모드: page4(index 3)는 spread 2', () async {
          await book.goToPage(3);
          await book.toggleDoublePageMode();
          expect(book.currentSpreadIndex, 2);
        });
      });

      group('secondaryController', () {
        test('단면 모드에서는 null', () {
          expect(book.secondaryController, isNull);
        });

        test('양면 모드: 첫 페이지(단면)에서는 null', () async {
          await book.toggleDoublePageMode();
          expect(book.secondaryController, isNull);
        });

        test('양면 모드: page2에서 page3 컨트롤러 반환', () async {
          await book.goToPage(1);
          await book.toggleDoublePageMode();
          expect(book.secondaryController, isNotNull);
        });

        test('양면 모드: 마지막 홀수 페이지에서는 null', () async {
          // 6페이지로 테스트: p1(단면), p2+p3, p4+p5, p6(단면)
          final book6 = ScribbleBookController(
            pageIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
            contentId: 'test6',
            pageProvider: provider,
            firstPageSingle: true,
          );
          await book6.goToPage(5); // p6
          await book6.toggleDoublePageMode();
          expect(book6.secondaryController, isNull);
          book6.dispose();
        });
      });

      group('goToSpread', () {
        test('단면 모드에서는 goToPage와 동일', () async {
          await book.goToSpread(2);
          expect(book.currentPageIndex, 2);
        });

        test('양면 모드: spread 0 → page 0', () async {
          await book.goToPage(2);
          await book.toggleDoublePageMode();
          await book.goToSpread(0);
          expect(book.currentPageIndex, 0);
        });

        test('양면 모드: spread 1 → page 1', () async {
          await book.toggleDoublePageMode();
          await book.goToSpread(1);
          expect(book.currentPageIndex, 1);
        });

        test('양면 모드: spread 2 → page 3', () async {
          await book.toggleDoublePageMode();
          await book.goToSpread(2);
          expect(book.currentPageIndex, 3);
        });
      });

      group('firstPageSingle: false', () {
        late ScribbleBookController bookNoSingle;

        setUp(() {
          bookNoSingle = ScribbleBookController(
            pageIds: ['p1', 'p2', 'p3', 'p4'],
            contentId: 'no_single_test',
            pageProvider: provider,
            firstPageSingle: false,
          );
        });

        tearDown(() => bookNoSingle.dispose());

        test('spreadCount: 페이지/2 올림', () async {
          await bookNoSingle.toggleDoublePageMode();
          // spread 0 = p1+p2, spread 1 = p3+p4
          expect(bookNoSingle.spreadCount, 2);
        });

        test('currentSpreadIndex: index 0 → spread 0', () async {
          await bookNoSingle.toggleDoublePageMode();
          expect(bookNoSingle.currentSpreadIndex, 0);
        });

        test('currentSpreadIndex: index 2 → spread 1', () async {
          await bookNoSingle.goToPage(2);
          await bookNoSingle.toggleDoublePageMode();
          expect(bookNoSingle.currentSpreadIndex, 1);
        });

        test('goToSpread(1) → page 2', () async {
          await bookNoSingle.toggleDoublePageMode();
          await bookNoSingle.goToSpread(1);
          expect(bookNoSingle.currentPageIndex, 2);
        });
      });
    });

    group('이벤트 스트림 (ScribbleBookEvent)', () {
      late ScribbleBookController book;

      setUp(() {
        book = ScribbleBookController(
          pageIds: ['page1', 'page2', 'page3'],
          contentId: 'event_test',
          pageProvider: provider,
        );
      });

      tearDown(() => book.dispose());

      test('기본 상태에서는 이벤트가 발행되지 않는다', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);

        await book.goToPage(1);

        expect(events, isEmpty);
      });

      test('startRecording 후 이벤트가 발행된다', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        await book.goToPage(1);
        await pumpEventQueue();

        expect(events.length, 1);
        expect(events[0], isA<PageChangedEvent>());
        final event = events[0] as PageChangedEvent;
        expect(event.fromIndex, 0);
        expect(event.toIndex, 1);
        expect(event.timestampMicros, greaterThan(0));
      });

      test('stopRecording 후 이벤트가 중단된다', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        await book.goToPage(1);
        book.stopRecording();
        await book.goToPage(2);

        expect(events.length, 1); // 첫 번째 전환만
      });

      test('addPage 시 PageAddedEvent', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        book.addPage(pageId: 'page4');
        await pumpEventQueue();

        expect(events.length, 1);
        expect(events[0], isA<PageAddedEvent>());
        final event = events[0] as PageAddedEvent;
        expect(event.pageId, 'page4');
        expect(event.atIndex, 3);
      });

      test('removePage 시 PageRemovedEvent', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        await book.removePage(2);

        expect(events.length, 1);
        expect(events[0], isA<PageRemovedEvent>());
        final event = events[0] as PageRemovedEvent;
        expect(event.pageId, 'page3');
        expect(event.atIndex, 2);
      });

      test('toggleDoublePageMode 시 DoublePageToggledEvent', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        await book.toggleDoublePageMode();
        await pumpEventQueue();

        expect(events.length, 1);
        expect(events[0], isA<DoublePageToggledEvent>());
        final event = events[0] as DoublePageToggledEvent;
        expect(event.enabled, isTrue);
      });

      test('emitEvent로 커스텀 이벤트 발행', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        book.emitEvent(
          PageClearedEvent(
            pageId: 'page1',
            timestampMicros: ScribbleBookEvent.now(),
          ),
        );
        await pumpEventQueue();

        expect(events.length, 1);
        expect(events[0], isA<PageClearedEvent>());
      });

      test('isRecording 상태 추적', () {
        expect(book.isRecording, isFalse);
        book.startRecording();
        expect(book.isRecording, isTrue);
        book.stopRecording();
        expect(book.isRecording, isFalse);
      });

      test('여러 이벤트의 타임스탬프가 단조 증가한다', () async {
        final events = <ScribbleBookEvent>[];
        book.eventStream.listen(events.add);
        book.startRecording();

        await book.goToPage(1);
        book.addPage(pageId: 'page4');
        await book.goToPage(2);
        await pumpEventQueue();

        expect(events.length, 3);
        expect(
          events[0].timestampMicros,
          lessThanOrEqualTo(events[1].timestampMicros),
        );
        expect(
          events[1].timestampMicros,
          lessThanOrEqualTo(events[2].timestampMicros),
        );
      });
    });

    group('PageChangeEvent', () {
      test('toString 포맷', () {
        const event = PageChangeEvent(
          fromIndex: 0,
          toIndex: 1,
          fromPageId: 'page1',
          toPageId: 'page2',
        );

        expect(
          event.toString(),
          'PageChangeEvent(from: 0(page1) → to: 1(page2))',
        );
      });
    });
  });
}
