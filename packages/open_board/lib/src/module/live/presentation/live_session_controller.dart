import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/live/data/renderer/remote_stroke_renderer.dart';
import 'package:open_board/src/module/live/domain/batcher/event_batcher.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';
import 'package:open_board/src/module/live/domain/model/transport_state.dart';
import 'package:open_board/src/module/live/domain/transport/live_session_transport.dart';
import 'package:open_board/src/module/managers/scribble_book_controller.dart';
import 'package:open_board/src/module/scribble_controller.dart';

/// 실시간 세션 오케스트레이터
///
/// [ScribbleBookController]의 이벤트 스트림을 구독하여 [LiveSessionTransport]를 통해
/// 원격으로 전송하고, 원격에서 수신한 이벤트를 로컬 캔버스에 적용한다.
///
/// 역할:
/// - 로컬 이벤트 → Transport 전송 (EventBatcher를 통한 포인트 배칭)
/// - 원격 이벤트 → 로컬 캔버스 적용 (RemoteStrokeRenderer를 통한 렌더링)
/// - 연결 상태 모니터링
///
/// 사용 예시:
/// ```dart
/// final controller = LiveSessionController(
///   bookController: bookController,
///   transport: transport,
///   isTeacher: true,
/// );
///
/// await controller.startSession('session-id', 'token');
/// // ... 세션 진행
/// await controller.endSession();
/// ```
class LiveSessionController extends ChangeNotifier {
  final ScribbleBookController bookController;
  final LiveSessionTransport transport;
  final bool isTeacher;

  late final RemoteStrokeRenderer _renderer;
  late final EventBatcher _batcher;

  StreamSubscription<ScribbleBookEvent>? _localEventSub;
  StreamSubscription<ScribbleBookEvent>? _remoteEventSub;
  StreamSubscription<StrokePointsBatch>? _remotePointsSub;
  StreamSubscription<StrokeCompleteMessage>? _remoteCompleteSub;
  StreamSubscription<TransportConnectionState>? _connectionSub;

  TransportConnectionState _connectionState =
      TransportConnectionState.disconnected;

  /// 원격 이벤트 적용을 억제하는 플래그 (동기화 중 등)
  bool _suppressRemoteEvents = false;

  /// 활성 스트로크 ID (로컬에서 진행 중인 스트로크)
  String? _activeStrokeId;
  int _strokeIdCounter = 0;

  LiveSessionController({
    required this.bookController,
    required this.transport,
    this.isTeacher = false,
  }) {
    _renderer = RemoteStrokeRenderer(
      onStrokesChanged: _onRemoteStrokesChanged,
    );
    _batcher = EventBatcher(
      onBatchReady: _onBatchReady,
    );
  }

  /// 현재 연결 상태
  TransportConnectionState get connectionState => _connectionState;

  /// 원격 진행 중 스트로크 (오버레이 렌더링용)
  List<Stroke> getRemoteInProgressStrokes(String pageId) =>
      _renderer.getInProgressStrokes(pageId);

  /// 세션 시작
  Future<void> startSession(String sessionId, String token) async {
    await transport.connect(sessionId, token);

    _subscribeToLocal();
    _subscribeToRemote();
    _subscribeToConnection();

    bookController.startRecording();
  }

  /// 세션 종료
  Future<void> endSession() async {
    bookController.stopRecording();

    _localEventSub?.cancel();
    _remoteEventSub?.cancel();
    _remotePointsSub?.cancel();
    _remoteCompleteSub?.cancel();
    _connectionSub?.cancel();

    _batcher.dispose();
    _renderer.dispose();

    await transport.disconnect();

    _connectionState = TransportConnectionState.disconnected;
    notifyListeners();
  }

  // ── 로컬 이벤트 → Transport 전송 ──

  void _subscribeToLocal() {
    _localEventSub = bookController.eventStream.listen(_handleLocalEvent);
  }

  void _handleLocalEvent(ScribbleBookEvent event) {
    if (_connectionState != TransportConnectionState.connected) return;

    switch (event) {
      case StrokeAddedEvent(:final pageId, :final stroke, :final strokeIndex):
        // 스트로크 완료 → Reliable 전송
        _batcher.finishStroke();

        transport.sendStrokeComplete(StrokeCompleteMessage(
          pageId: pageId,
          strokeId: _activeStrokeId ?? 'stroke-${_strokeIdCounter}',
          stroke: stroke,
          strokeIndex: strokeIndex,
          timestampMicros: event.timestampMicros,
        ));
        _activeStrokeId = null;

      case StrokeRemovedEvent():
      case UndoPerformedEvent():
      case RedoPerformedEvent():
      case PageChangedEvent():
      case PageAddedEvent():
      case PageRemovedEvent():
      case PageClearedEvent():
        // 상태 변경 이벤트 → Reliable 전송
        transport.sendEvent(event);

      case DoublePageToggledEvent():
      case ViewportChangedEvent():
      case SessionParticipantEvent():
        break; // 별도 처리 또는 무시
    }
  }

  /// 포인트 스트리밍 시작 (ScribbleWidget에서 호출)
  ///
  /// 선생님이 펜을 터치했을 때 호출된다.
  void onLocalStrokeBegin({
    required String pageId,
    required int color,
    required double width,
    required String ink,
  }) {
    _strokeIdCounter++;
    _activeStrokeId = 'stroke-$_strokeIdCounter';

    _batcher.beginStroke(
      pageId: pageId,
      strokeId: _activeStrokeId!,
      color: color,
      width: width,
      ink: ink,
    );
  }

  /// 포인트 추가 (ScribbleWidget에서 호출)
  void onLocalPointAdded(Point point) {
    _batcher.addPoint(point);
  }

  void _onBatchReady(StrokePointsBatch batch) {
    if (_connectionState == TransportConnectionState.connected) {
      transport.sendStrokePoints(batch);
    }
  }

  // ── 원격 이벤트 → 로컬 캔버스 적용 ──

  void _subscribeToRemote() {
    _remotePointsSub = transport.remoteStrokePoints.listen(
      _handleRemoteStrokePoints,
    );
    _remoteCompleteSub = transport.remoteStrokeCompletes.listen(
      _handleRemoteStrokeComplete,
    );
    _remoteEventSub = transport.remoteEvents.listen(
      _handleRemoteEvent,
    );
  }

  void _handleRemoteStrokePoints(StrokePointsBatch batch) {
    if (_suppressRemoteEvents) return;
    _renderer.appendPoints(batch);
  }

  void _handleRemoteStrokeComplete(StrokeCompleteMessage message) {
    if (_suppressRemoteEvents) return;

    final finalized = _renderer.finalizeStroke(message);
    if (finalized == null) return;

    // 완성된 스트로크를 ScribbleController에 적용
    _applyRemoteStroke(finalized);
  }

  void _handleRemoteEvent(ScribbleBookEvent event) {
    if (_suppressRemoteEvents) return;

    switch (event) {
      case PageChangedEvent(:final toIndex):
        bookController.goToPage(toIndex);

      case PageAddedEvent(:final pageId, :final atIndex):
        bookController.addPage(pageId: pageId, atIndex: atIndex);

      case PageRemovedEvent(:final atIndex):
        bookController.removePage(atIndex);

      case PageClearedEvent():
        bookController.activeController.clear();

      case UndoPerformedEvent():
        bookController.activeController.undo();

      case RedoPerformedEvent():
        bookController.activeController.redo();

      case StrokeRemovedEvent(:final pageId, :final strokeIndex):
        _removeRemoteStroke(pageId, strokeIndex);

      case StrokeAddedEvent():
      case DoublePageToggledEvent():
      case ViewportChangedEvent():
      case SessionParticipantEvent():
        break;
    }
  }

  void _applyRemoteStroke(FinalizedStroke finalized) {
    // 현재 페이지의 Scribble에 스트로크 추가
    final controller = _getControllerForPage(finalized.pageId);
    if (controller == null) return;

    final scribble = controller.currentScribble;
    final strokes = [...scribble.strokes, finalized.stroke];
    final updated = Scribble(
      strokes: strokes,
      width: scribble.width,
      height: scribble.height,
      textDrawables: scribble.textDrawables,
      createdAt: scribble.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    controller.loadScribble(updated);
  }

  void _removeRemoteStroke(String pageId, int strokeIndex) {
    final controller = _getControllerForPage(pageId);
    if (controller == null) return;

    final scribble = controller.currentScribble;
    if (strokeIndex < 0 || strokeIndex >= scribble.strokes.length) return;

    final strokes = [...scribble.strokes]..removeAt(strokeIndex);
    final updated = Scribble(
      strokes: strokes,
      width: scribble.width,
      height: scribble.height,
      textDrawables: scribble.textDrawables,
      createdAt: scribble.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    controller.loadScribble(updated);
  }

  ScribbleController? _getControllerForPage(String pageId) {
    // 현재 활성 페이지인지 확인
    if (bookController.currentPageId == pageId) {
      return bookController.activeController;
    }
    return null;
  }

  // ── 연결 상태 ──

  void _subscribeToConnection() {
    _connectionSub = transport.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  void _onRemoteStrokesChanged(String pageId) {
    notifyListeners();
  }

  @override
  void dispose() {
    _localEventSub?.cancel();
    _remoteEventSub?.cancel();
    _remotePointsSub?.cancel();
    _remoteCompleteSub?.cancel();
    _connectionSub?.cancel();
    _batcher.dispose();
    _renderer.dispose();
    super.dispose();
  }
}
