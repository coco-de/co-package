  import 'dart:async';

  import 'package:flutter/foundation.dart';

  import 'package:open_board/src/core/utils/scribble_hash_util.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/events/scribble_book_event.dart';
  import 'package:open_board/src/module/scribble_controller.dart';

  /// [ScribbleBookController]가 사용하는 컨트롤러/캐시 관리 인터페이스
  ///
  /// [ScribbleCacheManager]가 이 인터페이스를 구현합니다.
  /// 테스트 시 Mock 구현을 주입할 수 있습니다.
  abstract class ScribblePageProvider {
    /// 키에 해당하는 ScribbleController를 반환 (없으면 생성)
    ScribbleController getController(String key);

    /// 키에 해당하는 컨트롤러가 캐시에 존재하는지
    bool hasController(String key);

    /// 키에 해당하는 페이지가 비어있는지
    bool isPageEmpty(String key);

    /// 활성 컨트롤러 설정
    void setActiveController(String key);

    /// 필기 데이터 저장
    Future<bool> saveScribble(String key, Scribble scribble, {bool immediate});

    /// 필기 데이터 로드
    Future<Scribble?> loadScribble(String key);

    /// 필기 데이터 삭제
    Future<bool> deleteScribble(String key);
  }

  /// 다중 페이지 필기 관리 컨트롤러
  ///
  /// [ScribblePageProvider] (일반적으로 ScribbleCacheManager)를 내부적으로
  /// 활용하여 페이지 순서, 전환, 자동 저장/로드를 관리합니다.
  ///
  /// ```dart
  /// final book = ScribbleBookController(
  ///   pageIds: ['page1', 'page2', 'page3'],
  ///   contentId: 'book123',
  ///   pageProvider: cacheManager,
  /// );
  ///
  /// // 페이지 전환 (자동 저장/로드)
  /// await book.goToPage(1);
  ///
  /// // 현재 페이지 컨트롤러 접근
  /// book.activeController.undo();
  ///
  /// // 페이지 추가
  /// book.addPage();
  /// ```
  class ScribbleBookController extends ChangeNotifier {
    /// 콘텐츠 식별자 (캐시 키 접두사)
    final String contentId;

    /// 외부 저장소 위임
    ScribblePersistenceDelegate? persistenceDelegate;

    /// 첫 페이지 단면 전략 (양면 모드에서 첫 페이지만 단면으로 표시)
    final bool firstPageSingle;

    // ===== 인접 페이지 중복 스트로크 제거 =====

    /// 중복 스트로크 자동 제거 활성화 여부
    bool enableDuplicateRemoval = false;

    /// 내부 페이지 프로바이더
    final ScribblePageProvider _pageProvider;

    /// 페이지 ID 목록 (순서 보장)
    final List<String> _pageIds;

    /// 현재 페이지 인덱스
    int _currentPageIndex;

    /// 양면 모드 여부
    bool _isDoublePageMode = false;

    /// 현재 저장/로드 진행 중 여부
    bool _isBusy = false;

    /// dispose 상태 추적
    bool _isDisposed = false;

    /// 페이지 변경 스트림 컨트롤러
    final StreamController<PageChangeEvent> _pageChangeController =
        StreamController<PageChangeEvent>.broadcast();

    /// 이벤트 스트림 컨트롤러 (리플레이/동기화용)
    final StreamController<ScribbleBookEvent> _eventController =
        StreamController<ScribbleBookEvent>.broadcast();

    /// 이벤트 기록 여부 (녹화 모드에서만 활성)
    bool _isRecording = false;

    ScribbleBookController({
      required List<String> pageIds,
      required this.contentId,
      required ScribblePageProvider pageProvider,
      int initialPageIndex = 0,
      this.persistenceDelegate,
      this.firstPageSingle = true,
    }) : assert(pageIds.isNotEmpty, 'pageIds must not be empty'),
         assert(
           initialPageIndex >= 0 && initialPageIndex < pageIds.length,
           'initialPageIndex out of range',
         ),
         _pageProvider = pageProvider,
         _pageIds = List<String>.of(pageIds),
         _currentPageIndex = initialPageIndex;

    // ===== 페이지 상태 접근자 =====

    /// 페이지 ID 목록 (읽기 전용)
    List<String> get pageIds => List<String>.unmodifiable(_pageIds);

    /// 현재 페이지 인덱스
    int get currentPageIndex => _currentPageIndex;

    /// 현재 페이지 ID
    String get currentPageId => _pageIds[_currentPageIndex];

    /// 전체 페이지 수
    int get pageCount => _pageIds.length;

    /// 다음 페이지 존재 여부
    bool get hasNextPage => _currentPageIndex < _pageIds.length - 1;

    /// 이전 페이지 존재 여부
    bool get hasPreviousPage => _currentPageIndex > 0;

    /// 저장/로드 진행 중 여부
    bool get isBusy => _isBusy;

    /// 페이지 변경 이벤트 스트림
    Stream<PageChangeEvent> get onPageChanged => _pageChangeController.stream;

    // ===== 이벤트 스트림 (리플레이/동기화) =====

    /// 모든 이벤트 스트림 (페이지 전환, 스트로크 추가/삭제, undo/redo 등)
    ///
    /// [startRecording]을 호출해야 이벤트가 발행됩니다.
    Stream<ScribbleBookEvent> get eventStream => _eventController.stream;

    /// 이벤트 기록 여부
    bool get isRecording => _isRecording;

    // ===== 양면 모드 =====

    /// 양면 모드 여부
    bool get isDoublePageMode => _isDoublePageMode;

    /// 양면 모드에서 현재 표시 단위(spread)의 인덱스
    ///
    /// 단면 모드: currentPageIndex와 동일
    /// 양면 모드: firstPageSingle인 경우 spread 0 = page 0 (단면), spread 1 = page 1,2 ...
    int get currentSpreadIndex {
      if (!_isDoublePageMode) return _currentPageIndex;
      if (firstPageSingle && _currentPageIndex == 0) return 0;
      if (firstPageSingle) return ((_currentPageIndex - 1) ~/ 2) + 1;
      return _currentPageIndex ~/ 2;
    }

    /// 양면 모드에서 전체 spread 수
    int get spreadCount {
      if (!_isDoublePageMode) return _pageIds.length;
      if (firstPageSingle) {
        return 1 + ((_pageIds.length - 1 + 1) ~/ 2); // 첫 페이지 + 나머지 쌍
      }
      return (_pageIds.length + 1) ~/ 2;
    }

    /// 양면 모드에서 두 번째 (오른쪽) 페이지의 ScribbleController
    ///
    /// 양면 모드가 아니거나, 오른쪽 페이지가 없으면 null을 반환합니다.
    ScribbleController? get secondaryController {
      if (!_isDoublePageMode) return null;

      final secondaryIndex = _getSecondaryPageIndex();
      if (secondaryIndex == null) return null;

      final key = _buildKey(_pageIds[secondaryIndex]);
      return _pageProvider.getController(key);
    }

    // ===== ScribbleController 접근 =====

    /// 현재 페이지의 ScribbleController
    ScribbleController get activeController {
      final key = _buildKey(currentPageId);
      return _pageProvider.getController(key);
    }

    /// 이벤트 기록 시작
    void startRecording() {
      _isRecording = true;
    }

    /// 이벤트 기록 중지
    void stopRecording() {
      _isRecording = false;
    }

    /// 이벤트 수동 발행 (외부에서 커스텀 이벤트 추가 시)
    void emitEvent(ScribbleBookEvent event) {
      if (_isRecording && !_eventController.isClosed) {
        _eventController.add(event);
      }
    }

    /// 양면 모드 토글
    ///
    /// 토글 시 현재 페이지를 저장하고, 필요한 경우 스트로크를 분할/병합합니다.
    Future<void> toggleDoublePageMode() async {
      if (_isBusy) return;
      _isBusy = true;

      try {
        // 현재 페이지 저장
        await _savePage(currentPageId);

        _isDoublePageMode = !_isDoublePageMode;

        emitEvent(
          DoublePageToggledEvent(
            enabled: _isDoublePageMode,
            timestampMicros: ScribbleBookEvent.now(),
          ),
        );

        notifyListeners();
      } finally {
        _isBusy = false;
      }
    }

    /// 양면 모드를 명시적으로 설정
    Future<void> setDoublePageMode(bool enabled) async {
      if (_isDoublePageMode == enabled) return;
      await toggleDoublePageMode();
    }

    /// 양면 모드에서 특정 spread로 이동
    ///
    /// spread 내 첫 번째 페이지로 이동합니다.
    Future<void> goToSpread(int spreadIndex) async {
      if (!_isDoublePageMode) {
        await goToPage(spreadIndex);
        return;
      }

      final pageIndex = _spreadIndexToPageIndex(spreadIndex);
      if (pageIndex != null) {
        await goToPage(pageIndex);
      }
    }

    /// 특정 페이지의 ScribbleController
    ScribbleController controllerAt(int index) {
      _assertValidIndex(index);
      final key = _buildKey(_pageIds[index]);
      return _pageProvider.getController(key);
    }

    // ===== 페이지 전환 =====

    /// 특정 페이지로 이동
    ///
    /// 이전 페이지를 자동 저장하고 새 페이지를 로드합니다.
    /// [persistenceDelegate]가 설정된 경우 외부 저장소와 연동합니다.
    Future<void> goToPage(int index) async {
      _assertValidIndex(index);
      if (index == _currentPageIndex) return;
      if (_isBusy) return;

      _isBusy = true;

      try {
        final previousIndex = _currentPageIndex;
        final previousPageId = _pageIds[previousIndex];
        final nextPageId = _pageIds[index];

        // 이전 페이지 저장
        await _savePage(previousPageId);

        // 새 페이지 로드
        await _loadPage(nextPageId);

        // 인덱스 업데이트
        _currentPageIndex = index;

        // 활성 컨트롤러 변경 알림
        _pageProvider.setActiveController(_buildKey(nextPageId));

        // 이벤트 발행
        _pageChangeController.add(
          PageChangeEvent(
            fromIndex: previousIndex,
            toIndex: index,
            fromPageId: previousPageId,
            toPageId: nextPageId,
          ),
        );

        emitEvent(
          PageChangedEvent(
            fromIndex: previousIndex,
            toIndex: index,
            fromPageId: previousPageId,
            toPageId: nextPageId,
            timestampMicros: ScribbleBookEvent.now(),
          ),
        );

        notifyListeners();
      } finally {
        _isBusy = false;
      }
    }

    /// 다음 페이지로 이동
    Future<void> goToNextPage() async {
      if (hasNextPage) await goToPage(_currentPageIndex + 1);
    }

    /// 이전 페이지로 이동
    Future<void> goToPreviousPage() async {
      if (hasPreviousPage) await goToPage(_currentPageIndex - 1);
    }

    // ===== 페이지 CRUD =====

    /// 새 페이지 추가
    ///
    /// [pageId]가 제공되지 않으면 자동 생성됩니다.
    /// [atIndex]가 제공되지 않으면 마지막에 추가됩니다.
    void addPage({String? pageId, int? atIndex}) {
      final id = pageId ?? _generatePageId();
      final insertIndex = atIndex ?? _pageIds.length;

      assert(
        insertIndex >= 0 && insertIndex <= _pageIds.length,
        'atIndex out of range',
      );
      assert(!_pageIds.contains(id), 'pageId "$id" already exists');

      _pageIds.insert(insertIndex, id);

      // 현재 페이지가 삽입 위치 이후면 인덱스 조정
      if (insertIndex <= _currentPageIndex) {
        _currentPageIndex++;
      }

      emitEvent(
        PageAddedEvent(
          pageId: id,
          atIndex: insertIndex,
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );

      notifyListeners();
    }

    /// 페이지 삭제
    ///
    /// 최소 1페이지는 유지됩니다.
    /// 현재 페이지 삭제 시 인접 페이지로 자동 전환됩니다.
    Future<void> removePage(int index) async {
      _assertValidIndex(index);
      if (_pageIds.length <= 1) return; // 최소 1페이지 보장

      final removedPageId = _pageIds[index];
      final removedKey = _buildKey(removedPageId);

      emitEvent(
        PageRemovedEvent(
          pageId: removedPageId,
          atIndex: index,
          timestampMicros: ScribbleBookEvent.now(),
        ),
      );

      // 캐시 정리
      _pageProvider.deleteScribble(removedKey);

      // 외부 저장소 정리
      if (persistenceDelegate != null) {
        await persistenceDelegate!.deleteScribble(removedKey);
      }

      _pageIds.removeAt(index);

      // 현재 페이지 인덱스 조정
      if (index < _currentPageIndex) {
        _currentPageIndex--;
      } else if (index == _currentPageIndex) {
        // 삭제된 페이지가 현재 페이지인 경우
        if (_currentPageIndex >= _pageIds.length) {
          _currentPageIndex = _pageIds.length - 1;
        }
        // 새 현재 페이지 로드
        await _loadPage(_pageIds[_currentPageIndex]);
        _pageProvider.setActiveController(
          _buildKey(_pageIds[_currentPageIndex]),
        );
      }

      notifyListeners();
    }

    /// 페이지 순서 변경
    void reorderPage(int oldIndex, int newIndex) {
      _assertValidIndex(oldIndex);
      assert(
        newIndex >= 0 && newIndex <= _pageIds.length,
        'newIndex out of range',
      );

      if (oldIndex == newIndex) return;

      final pageId = _pageIds.removeAt(oldIndex);

      // removeAt 후 인덱스 보정
      final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _pageIds.insert(adjustedNewIndex, pageId);

      // 현재 페이지 인덱스 업데이트
      if (_currentPageIndex == oldIndex) {
        _currentPageIndex = adjustedNewIndex;
      } else if (oldIndex < _currentPageIndex &&
          adjustedNewIndex >= _currentPageIndex) {
        _currentPageIndex--;
      } else if (oldIndex > _currentPageIndex &&
          adjustedNewIndex <= _currentPageIndex) {
        _currentPageIndex++;
      }

      notifyListeners();
    }

    // ===== 저장/로드 =====

    /// 현재 페이지를 즉시 저장
    Future<void> saveCurrentPage() async {
      await _savePage(currentPageId);
    }

    /// 모든 페이지를 저장
    Future<void> saveAllPages() async {
      for (final pageId in _pageIds) {
        final key = _buildKey(pageId);
        if (_pageProvider.hasController(key)) {
          await _savePage(pageId);
        }
      }
    }

    /// 인접 페이지에서 중복 스트로크 제거
    ///
    /// 현재 페이지에서 삭제된 스트로크가 인접 페이지에도 존재하면 자동 제거합니다.
    /// (양면 모드에서 페이지 경계를 넘어 그려진 스트로크의 동기화)
    ///
    /// [currentIndex] 현재 페이지 인덱스
    /// [previousScribble] 변경 전 필기 데이터 (삭제 감지용)
    /// [pageWidth] 페이지 너비 (좌표 변환에 사용)
    Future<int> removeDuplicatesFromAdjacentPages({
      required int currentIndex,
      required Scribble previousScribble,
      required double pageWidth,
    }) async {
      _assertValidIndex(currentIndex);
      if (pageWidth == 0) return 0;
      if (previousScribble.strokes.isEmpty) return 0;

      final currentKey = _buildKey(_pageIds[currentIndex]);
      final currentController = _pageProvider.getController(currentKey);
      final currentScribble = currentController.currentScribble;

      // 삭제된 스트로크 해시 계산
      final previousHashes = ScribbleHashUtil.generateStrokeHashSet(
        previousScribble.strokes,
      );
      final currentHashes = ScribbleHashUtil.generateStrokeHashSet(
        currentScribble.strokes,
      );
      final deletedHashes = previousHashes.difference(currentHashes);

      if (deletedHashes.isEmpty) return 0;

      var totalRemoved = 0;

      // 인접 페이지(앞/뒤)에서 중복 제거
      for (final adjacentIndex in [currentIndex - 1, currentIndex + 1]) {
        if (adjacentIndex < 0 || adjacentIndex >= _pageIds.length) continue;

        final adjacentKey = _buildKey(_pageIds[adjacentIndex]);
        final adjacentController = _pageProvider.getController(adjacentKey);
        final adjacentScribble = adjacentController.currentScribble;

        if (adjacentScribble.strokes.isEmpty) continue;

        // 좌표 변환 방향 결정
        final isRight = adjacentIndex > currentIndex;
        final xOffset = isRight ? pageWidth : -pageWidth;

        // 인접 페이지 스트로크를 현재 페이지 좌표계로 변환하여 해시 비교
        final filtered = <Stroke>[];

        for (final stroke in adjacentScribble.strokes) {
          final transformedStroke = _transformStroke(stroke, xOffset);
          final hash = ScribbleHashUtil.generateStrokeHash(transformedStroke);

          if (!deletedHashes.contains(hash)) {
            filtered.add(stroke); // 삭제 대상이 아닌 것만 유지
          }
        }

        final removedCount = adjacentScribble.strokes.length - filtered.length;
        if (removedCount > 0) {
          totalRemoved += removedCount;

          final newScribble = Scribble()
            ..strokes.addAll(filtered)
            ..textDrawables.addAll(adjacentScribble.textDrawables)
            ..width = adjacentScribble.width
            ..height = adjacentScribble.height;

          adjacentController.loadScribble(newScribble);
          await _pageProvider.saveScribble(
            adjacentKey,
            newScribble,
            immediate: true,
          );
        }
      }

      return totalRemoved;
    }

    // ===== 유틸리티 =====

    /// 특정 페이지가 비어있는지 확인
    bool isPageEmpty(int index) {
      _assertValidIndex(index);
      final key = _buildKey(_pageIds[index]);
      return _pageProvider.isPageEmpty(key);
    }

    /// 특정 페이지 ID의 인덱스 조회
    int indexOfPage(String pageId) => _pageIds.indexOf(pageId);

    @override
    void dispose() {
      if (_isDisposed) return;
      _isDisposed = true;
      _isRecording = false;
      _pageChangeController.close();
      _eventController.close();
      super.dispose();
    }

    /// 스트로크의 X 좌표를 오프셋만큼 이동
    Stroke _transformStroke(Stroke stroke, double xOffset) {
      final transformed = Stroke()
        ..ink = stroke.ink
        ..width = stroke.width
        ..color = stroke.color;

      for (final point in stroke.points) {
        transformed.points.add(
          Point()
            ..x = point.x + xOffset
            ..y = point.y
            ..p = point.p
            ..altitude = point.altitude
            ..azimuth = point.azimuth
            ..opacity = point.opacity
            ..timestamp = point.timestamp,
        );
      }

      return transformed;
    }

    // ===== 내부 메서드 =====

    /// 양면 모드에서 현재 페이지의 오른쪽 페이지 인덱스
    int? _getSecondaryPageIndex() {
      if (!_isDoublePageMode) return null;

      // firstPageSingle이고 현재 첫 페이지면 오른쪽 없음
      if (firstPageSingle && _currentPageIndex == 0) return null;

      // 현재 페이지가 spread의 왼쪽인 경우 오른쪽 반환
      int rightIndex;
      if (firstPageSingle) {
        // page 1,2 = spread 1, page 3,4 = spread 2 ...
        final isLeftPage = (_currentPageIndex - 1).isEven;
        rightIndex = isLeftPage
            ? _currentPageIndex + 1
            : _currentPageIndex; // 이미 오른쪽이면 자기 자신
        if (!isLeftPage) return null; // 오른쪽 페이지에서는 secondary 없음
      } else {
        final isLeftPage = _currentPageIndex.isEven;
        rightIndex = isLeftPage ? _currentPageIndex + 1 : _currentPageIndex;
        if (!isLeftPage) return null;
      }

      if (rightIndex >= _pageIds.length) return null;
      return rightIndex;
    }

    /// spread 인덱스를 페이지 인덱스로 변환
    int? _spreadIndexToPageIndex(int spreadIndex) {
      if (spreadIndex < 0 || spreadIndex >= spreadCount) return null;

      if (!_isDoublePageMode) return spreadIndex;

      if (firstPageSingle) {
        if (spreadIndex == 0) return 0;
        final pageIndex = 1 + (spreadIndex - 1) * 2;
        return pageIndex < _pageIds.length ? pageIndex : null;
      }
      final pageIndex = spreadIndex * 2;
      return pageIndex < _pageIds.length ? pageIndex : null;
    }

    String _buildKey(String pageId) => '$contentId/$pageId';

    void _assertValidIndex(int index) {
      assert(
        index >= 0 && index < _pageIds.length,
        'Page index $index out of range [0, ${_pageIds.length})',
      );
    }

    String _generatePageId() {
      var counter = _pageIds.length;
      var id = 'page_$counter';
      while (_pageIds.contains(id)) {
        counter++;
        id = 'page_$counter';
      }
      return id;
    }

    Future<void> _savePage(String pageId) async {
      final key = _buildKey(pageId);

      if (!_pageProvider.hasController(key)) return;

      final controller = _pageProvider.getController(key);
      final scribble = controller.currentScribble;

      // 로컬 캐시 저장
      await _pageProvider.saveScribble(key, scribble, immediate: true);

      // 외부 저장소 저장
      if (persistenceDelegate != null) {
        try {
          await persistenceDelegate!.saveScribble(key, scribble);
        } catch (e) {
          debugPrint('[ScribbleBookController] Save failed for $key: $e');
        }
      }
    }

    Future<void> _loadPage(String pageId) async {
      final key = _buildKey(pageId);
      final controller = _pageProvider.getController(key);

      // 이미 로드된 경우 스킵
      if (!controller.isEmpty) return;

      // 로컬 캐시에서 로드 시도
      final localScribble = await _pageProvider.loadScribble(key);
      if (localScribble != null) {
        controller.loadScribble(localScribble);
        return;
      }

      // 외부 저장소에서 로드
      if (persistenceDelegate != null) {
        try {
          final scribble = await persistenceDelegate!.loadScribble(key);
          if (scribble != null) {
            controller.loadScribble(scribble);
          }
        } catch (e) {
          debugPrint('[ScribbleBookController] Load failed for $key: $e');
        }
      }
    }
  }

  /// 페이지 전환 이벤트
  @immutable
  class PageChangeEvent {
    final int fromIndex;
    final int toIndex;
    final String fromPageId;
    final String toPageId;

    const PageChangeEvent({
      required this.fromIndex,
      required this.toIndex,
      required this.fromPageId,
      required this.toPageId,
    });

    @override
    String toString() =>
        'PageChangeEvent(from: $fromIndex($fromPageId) → to: $toIndex($toPageId))';
  }

  /// 외부 저장소 위임 인터페이스
  ///
  /// [ScribbleBookController]의 페이지 데이터를 외부 저장소
  /// (서버, S3, Serverpod 등)와 연동하기 위한 추상 인터페이스입니다.
  ///
  /// ```dart
  /// class ServerPersistenceDelegate implements ScribblePersistenceDelegate {
  ///   @override
  ///   Future<Scribble?> loadScribble(String key) async {
  ///     return await api.downloadScribble(key);
  ///   }
  ///   // ...
  /// }
  /// ```
  abstract class ScribblePersistenceDelegate {
    /// 외부 저장소에서 필기 데이터 로드
    Future<Scribble?> loadScribble(String key);

    /// 외부 저장소에 필기 데이터 저장
    Future<void> saveScribble(String key, Scribble scribble);

    /// 외부 저장소에서 필기 데이터 삭제
    Future<void> deleteScribble(String key);
  }
