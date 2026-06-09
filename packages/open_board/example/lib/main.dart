import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';

import 'split_drawing_page.dart';

void main() {
  runApp(const OpenBoardExampleApp());
}

class OpenBoardExampleApp extends StatelessWidget {
  const OpenBoardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Board Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const SplitDrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  // === 필기 인프라 ===
  final _cacheManager = ScribbleCacheManager();
  late final ScribbleBookController _bookController;
  ScribbleEventBridge? _eventBridge;
  final _transformController = TransformationController();

  // === 녹화 ===
  ScribbleTimelineRecorder? _recorder;
  bool _isRecording = false;

  // === 리플레이 ===
  bool _hasRecording = false;
  bool _isReplaying = false;
  List<ScribbleBookEvent> _recordedEvents = [];
  final Map<String, List<Stroke>> _recordedStrokes = {};
  Timer? _replayTimer;
  int _replayEventIndex = 0;   // 다음 처리할 이벤트 인덱스
  int _replayStartMicros = 0;  // 녹화 시작 시각 (마이크로초)
  int _replayWallStartMicros = 0; // 리플레이 시작 wall clock
  // 페이지별 완성된 스트로크 관리
  final Map<String, List<Stroke>> _replayPageStrokes = {};
  Stroke? _animatingStroke;     // 현재 점진적으로 그리고 있는 전체 스트로크
  int _animatingPointIndex = 0; // 현재까지 그린 포인트 수

  // === UI 상태 ===
  final DrawingState _drawingState = DrawingState();
  int _currentPageIndex = 0;

  static const _pageIds = ['page-0', 'page-1', 'page-2'];
  static const _contentId = 'demo-book';

  static const _tools = <(DrawingTool, IconData, String)>[
    (DrawingTool.pen, Icons.edit, 'Pen'),
    (DrawingTool.pencil, Icons.create, 'Pencil'),
    (DrawingTool.marker, Icons.highlight, 'Marker'),
    (DrawingTool.fixedPen, Icons.precision_manufacturing, 'Fixed'),
    (DrawingTool.erase, Icons.auto_fix_normal, 'Eraser'),
    (DrawingTool.shape, Icons.crop_square, 'Shape'),
    (DrawingTool.lasso, Icons.gesture, 'Lasso'),
    (DrawingTool.text, Icons.text_fields, 'Text'),
  ];

  static const _colors = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();

    // BookController 초기화
    _bookController = ScribbleBookController(
      pageIds: _pageIds,
      contentId: _contentId,
      pageProvider: _cacheManager,
    );
    _bookController.addListener(_refresh);

    // DrawingState 기본값
    _drawingState.selectedTool.value = DrawingTool.pen;
    _drawingState.selectedColor.value = Colors.black;
    _drawingState.selectedThickness.value = 2.0;
    _drawingState.pointerMode.value = DrawingPointerMode.mouseOnly;

    _drawingState.selectedTool.addListener(_refresh);
    _drawingState.selectedColor.addListener(_refresh);
    _drawingState.selectedThickness.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _drawingState.selectedTool.removeListener(_refresh);
    _drawingState.selectedColor.removeListener(_refresh);
    _drawingState.selectedThickness.removeListener(_refresh);
    _stopRecording();
    _stopReplay();
    _eventBridge?.detach();
    _bookController.removeListener(_refresh);
    _bookController.dispose();
    super.dispose();
  }

  // === 현재 페이지 컨트롤러 접근 ===

  ScribbleController get _activeController => _bookController.activeController;
  ScribbleNotifier get _notifier => _activeController.scribbleNotifier;
  ScribbleModeNotifier get _modeNotifier => _activeController.modeNotifier;

  // === 도구/색상/두께 ===

  void _selectTool(DrawingTool tool) {
    _drawingState.selectedTool.value = tool;
  }

  void _selectColor(Color color) {
    _drawingState.selectedColor.value = color;
  }

  void _setWidth(double width) {
    _drawingState.selectedThickness.value = width;
  }

  // === 페이지 네비게이션 ===

  Future<void> _goToPage(int index) async {
    if (index < 0 || index >= _pageIds.length) return;
    await _bookController.goToPage(index);
    setState(() => _currentPageIndex = index);
  }

  // === 녹화 ===

  void _toggleRecording() {
    debugPrint('_toggleRecording called, _isRecording=$_isRecording');
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    // 이전 리플레이 정리
    _stopReplay();

    // BookController 녹화 시작
    _bookController.startRecording();

    // EventBridge: ScribbleNotifier 변경 → ScribbleBookEvent 자동 발행
    _eventBridge = ScribbleEventBridge(_bookController);
    _eventBridge!.attach();

    // Recorder: eventStream 구독하여 타임라인 수집
    _recorder = ScribbleTimelineRecorder(
      contentId: _contentId,
      pageIds: _pageIds,
    );
    _recorder!.start(_bookController.eventStream);

    setState(() => _isRecording = true);
  }

  void _stopRecording() {
    if (!_isRecording) return;

    try {
      // 녹화 중단 전 각 페이지의 스트로크를 직접 캡처
      _recordedStrokes.clear();
      for (int i = 0; i < _pageIds.length; i++) {
        final controller = _bookController.controllerAt(i);
        final strokes = controller.currentScribble.strokes;
        if (strokes.isNotEmpty) {
          _recordedStrokes[_pageIds[i]] = List<Stroke>.from(strokes);
        }
      }

      // Recorder 정지 → 이벤트 수집
      final timeline = _recorder?.stop();
      _recorder = null;

      // EventBridge 해제
      _eventBridge?.detach();
      _eventBridge = null;

      // BookController 녹화 중지
      _bookController.stopRecording();

      // 타임라인의 이벤트를 ScribbleBookEvent로 변환 저장
      if (timeline != null && timeline.events.isNotEmpty) {
        _recordedEvents = _convertTimelineEvents(timeline);
        _hasRecording = _recordedEvents.isNotEmpty;
        debugPrint('Recording stopped: ${_recordedEvents.length} events, '
            'strokes: ${_recordedStrokes.map((k, v) => MapEntry(k, v.length))}');
      } else {
        debugPrint('Recording stopped: no events captured');
      }
    } catch (e, st) {
      debugPrint('stopRecording error: $e\n$st');
      _recorder = null;
      _eventBridge?.detach();
      _eventBridge = null;
    }

    setState(() => _isRecording = false);
  }

  /// Timeline → ScribbleBookEvent 리스트 변환 (스트로크 데이터 포함)
  List<ScribbleBookEvent> _convertTimelineEvents(ScribbleTimeline timeline) {
    final events = <ScribbleBookEvent>[];
    for (final tlEvent in timeline.events) {
      final ts = tlEvent.timestamp.toInt();
      final evt = tlEvent.event;
      if (evt is TlStrokeAdded) {
        // 캡처한 원본 스트로크 데이터 연결
        final strokes = _recordedStrokes[evt.pageId];
        final stroke = (strokes != null && evt.strokeIndex < strokes.length)
            ? strokes[evt.strokeIndex]
            : Stroke();
        // 스트로크의 첫 포인트 타임스탬프를 이벤트 시간으로 사용
        // → 스트로크 시작 시점부터 포인트 애니메이션이 시작됨
        final strokeStartTs = (stroke.points.isNotEmpty &&
                stroke.points.first.timestamp.toInt() > 0)
            ? stroke.points.first.timestamp.toInt()
            : ts;
        events.add(StrokeAddedEvent(
          pageId: evt.pageId,
          stroke: stroke,
          strokeIndex: evt.strokeIndex,
          timestampMicros: strokeStartTs,
        ));
      } else if (evt is TlStrokeRemoved) {
        events.add(StrokeRemovedEvent(
          pageId: evt.pageId,
          strokeIndex: evt.strokeIndex,
          timestampMicros: ts,
        ));
      } else if (evt is TlPageChanged) {
        events.add(PageChangedEvent(
          fromIndex: evt.fromIndex,
          toIndex: evt.toIndex,
          fromPageId: evt.fromPageId,
          toPageId: evt.toPageId,
          timestampMicros: ts,
        ));
      } else if (evt is TlUndo) {
        events.add(UndoPerformedEvent(pageId: evt.pageId, timestampMicros: ts));
      } else if (evt is TlRedo) {
        events.add(RedoPerformedEvent(pageId: evt.pageId, timestampMicros: ts));
      } else if (evt is TlPageCleared) {
        events.add(PageClearedEvent(pageId: evt.pageId, timestampMicros: ts));
      } else if (evt is TlViewportChanged) {
        events.add(ViewportChangedEvent(
          pageId: evt.pageId,
          scale: evt.scale,
          centerX: evt.centerX,
          centerY: evt.centerY,
          viewportWidth: evt.viewportWidth,
          viewportHeight: evt.viewportHeight,
          timestampMicros: ts,
        ));
      }
    }
    events.sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));
    return events;
  }

  // === 리플레이 ===

  void _toggleReplay() {
    if (_isReplaying) {
      _stopReplay();
    } else {
      _startReplay();
    }
    setState(() {});
  }

  Future<void> _startReplay() async {
    if (!_hasRecording || _recordedEvents.isEmpty) return;

    // 첫 페이지로 이동
    if (_currentPageIndex != 0) {
      await _goToPage(0);
    }

    // 모든 페이지 캔버스 + 캐시 초기화 (페이지 이동 시 이전 데이터 로드 방지)
    for (int i = 0; i < _pageIds.length; i++) {
      final key = '$_contentId/${_pageIds[i]}';
      _bookController.controllerAt(i).loadScribble(Scribble());
      await _cacheManager.saveScribble(key, Scribble(), immediate: true);
    }
    setState(() {});

    // 리플레이 시작
    _replayEventIndex = 0;
    _replayPageStrokes.clear();
    _animatingStroke = null;
    _animatingPointIndex = 0;
    _replayStartMicros = _recordedEvents.first.timestampMicros;
    _replayWallStartMicros = DateTime.now().microsecondsSinceEpoch;
    _transformController.value = Matrix4.identity();
    _isReplaying = true;

    // 16ms 주기로 프레임 업데이트 (~60fps)
    _replayTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _processReplayFrame();
    });

    debugPrint('Replay started: ${_recordedEvents.length} events');
  }

  /// 현재 wall clock 기준으로 녹화 시간 내 위치 계산
  int get _currentReplayMicros {
    final elapsed = DateTime.now().microsecondsSinceEpoch - _replayWallStartMicros;
    return _replayStartMicros + elapsed;
  }

  void _processReplayFrame() {
    if (!_isReplaying) return;

    final targetMicros = _currentReplayMicros;

    // 1) 시간이 도달한 이벤트를 순서대로 처리
    while (_replayEventIndex < _recordedEvents.length &&
        _recordedEvents[_replayEventIndex].timestampMicros <= targetMicros) {
      _applyReplayEvent(_recordedEvents[_replayEventIndex]);
      _replayEventIndex++;
    }

    // 2) 현재 애니메이션 중인 스트로크의 포인트를 시간에 맞게 점진적으로 노출
    if (_animatingStroke != null) {
      _advanceStrokeAnimation(targetMicros);
    }

    // 3) 모든 이벤트 소진 + 애니메이션 완료 시 종료
    if (_replayEventIndex >= _recordedEvents.length && _animatingStroke == null) {
      _stopReplay();
    }
  }

  /// 현재 페이지의 완성된 스트로크 리스트
  List<Stroke> get _currentPageCompleted =>
      _replayPageStrokes.putIfAbsent(_pageIds[_currentPageIndex], () => []);

  void _applyReplayEvent(ScribbleBookEvent event) {
    switch (event) {
      case StrokeAddedEvent(:final stroke):
        _finishCurrentAnimation();
        _animatingStroke = stroke;
        _animatingPointIndex = 0;
      case StrokeRemovedEvent(:final strokeIndex):
        _finishCurrentAnimation();
        final strokes = _currentPageCompleted;
        if (strokeIndex < strokes.length) {
          strokes.removeAt(strokeIndex);
          _updateCanvas();
        }
      case PageChangedEvent(:final toIndex):
        _finishCurrentAnimation();
        _goToPage(toIndex);
      case UndoPerformedEvent():
        _finishCurrentAnimation();
        _activeController.undo();
        _replayPageStrokes[_pageIds[_currentPageIndex]] = List.from(
          _activeController.scribbleNotifier.currentScribble.strokes,
        );
      case RedoPerformedEvent():
        _finishCurrentAnimation();
        _activeController.redo();
        _replayPageStrokes[_pageIds[_currentPageIndex]] = List.from(
          _activeController.scribbleNotifier.currentScribble.strokes,
        );
      case PageClearedEvent():
        _finishCurrentAnimation();
        _replayPageStrokes[_pageIds[_currentPageIndex]]?.clear();
        _activeController.clear();
      case ViewportChangedEvent(:final scale, :final centerX, :final centerY):
        // 녹화된 확대/축소/이동을 transformationController에 적용
        final matrix = Matrix4.identity()
          ..setEntry(0, 3, centerX)
          ..setEntry(1, 3, centerY)
          ..setEntry(0, 0, scale)
          ..setEntry(1, 1, scale);
        _transformController.value = matrix;
      default:
        break;
    }
  }

  /// 애니메이션 중인 스트로크의 포인트를 현재 시간까지 노출
  void _advanceStrokeAnimation(int targetMicros) {
    final stroke = _animatingStroke;
    if (stroke == null || stroke.points.isEmpty) {
      _finishCurrentAnimation();
      return;
    }

    // 포인트의 timestamp로 현재 시간까지 보여줄 포인트 수 결정
    int visibleCount = _animatingPointIndex;
    for (int i = _animatingPointIndex; i < stroke.points.length; i++) {
      final ptTimestamp = stroke.points[i].timestamp.toInt();
      if (ptTimestamp == 0 || ptTimestamp <= targetMicros) {
        visibleCount = i + 1;
      } else {
        break;
      }
    }

    if (visibleCount != _animatingPointIndex) {
      _animatingPointIndex = visibleCount;
      _updateCanvas();
    }

    // 모든 포인트 노출 완료 → 스트로크 완성
    if (_animatingPointIndex >= stroke.points.length) {
      _finishCurrentAnimation();
    }
  }

  /// 현재 애니메이션 중인 스트로크를 완성 처리
  void _finishCurrentAnimation() {
    if (_animatingStroke != null) {
      _currentPageCompleted.add(_animatingStroke!);
      _animatingStroke = null;
      _animatingPointIndex = 0;
      _updateCanvas();
    }
  }

  /// completedStrokes + 부분 애니메이션 스트로크를 캔버스에 반영
  void _updateCanvas() {
    final allStrokes = <Stroke>[..._currentPageCompleted];

    // 부분 스트로크 추가 (현재 그리는 중인 선)
    if (_animatingStroke != null && _animatingPointIndex > 0) {
      final partial = Stroke()
        ..points.addAll(_animatingStroke!.points.take(_animatingPointIndex))
        ..color = _animatingStroke!.color
        ..ink = _animatingStroke!.ink
        ..width = _animatingStroke!.width
        ..options = _animatingStroke!.options;
      allStrokes.add(partial);
    }

    final scribble = Scribble()..strokes.addAll(allStrokes);
    _activeController.scribbleNotifier.setScribble(
      scribble: scribble,
      addToUndoHistory: false,
    );
  }

  void _stopReplay() {
    _replayTimer?.cancel();
    _replayTimer = null;
    _animatingStroke = null;
    _isReplaying = false;
    setState(() {});
  }

  // === 뷰포트 변경 이벤트 (확대/축소) ===

  void _onTransformChanged(Matrix4 transform) {
    if (!_isRecording) return;
    final scale = transform.getMaxScaleOnAxis();
    final translation = transform.getTranslation();
    _bookController.emitEvent(ViewportChangedEvent(
      pageId: _bookController.currentPageId,
      scale: scale,
      centerX: translation.x,
      centerY: translation.y,
      viewportWidth: 0,
      viewportHeight: 0,
      timestampMicros: ScribbleBookEvent.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentTool = _drawingState.selectedTool.value;
    final currentColor = _drawingState.selectedColor.value;
    final currentWidth = _drawingState.selectedThickness.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Board Demo'),
        actions: [
          IconButton(
            onPressed: () => _notifier.undo(),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: () => _notifier.redo(),
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            onPressed: () => _notifier.clear(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // === Tool Selection ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: cs.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (tool, icon, label) in _tools)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FilterChip(
                        avatar: Icon(icon, size: 18),
                        label: Text(label),
                        selected: currentTool == tool,
                        onSelected: (_) => _selectTool(tool),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // === Color & Width Selection ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                for (final c in _colors)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _selectColor(c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentColor == c
                                ? cs.primary
                                : cs.outlineVariant,
                            width: currentColor == c ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: currentWidth,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    onChanged: _setWidth,
                  ),
                ),
                Text(currentWidth.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          // === Page Navigation ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: cs.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      _currentPageIndex > 0 ? () => _goToPage(_currentPageIndex - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 20,
                ),
                for (int i = 0; i < _pageIds.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: Text('${i + 1}'),
                      selected: _currentPageIndex == i,
                      onSelected: (_) => _goToPage(i),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                  onPressed: _currentPageIndex < _pageIds.length - 1
                      ? () => _goToPage(_currentPageIndex + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          // === Canvas ===
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return ScribbleWidget(
                  key: ValueKey('page-$_currentPageIndex'),
                  notifier: _notifier,
                  modeNotifier: _modeNotifier,
                  repaintBoundaryKey: _activeController.repaintBoundaryKey,
                  contentLogicalSize: size,
                  isScribbleEnable: !_isReplaying,
                  drawPen: true,
                  drawEraser: true,
                  maxScale: 3.0,
                  panDirection: PanDirection.both,
                  onTransformChanged: _onTransformChanged,
                  transformationController: _transformController,
                  child: SizedBox.fromSize(
                    size: size,
                    child: _SampleContent(pageIndex: _currentPageIndex),
                  ),
                );
              },
            ),
          ),
          // === Recording / Replay Controls ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: cs.surfaceContainerLow,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Record button
                  IconButton.filled(
                    onPressed: _isReplaying ? null : _toggleRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.fiber_manual_record,
                      color: _isRecording ? Colors.white : Colors.red,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.red
                          : cs.surfaceContainerHighest,
                    ),
                    tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
                  ),
                  const SizedBox(width: 8),
                  // Replay button
                  IconButton.filled(
                    onPressed:
                        (_hasRecording && !_isRecording) ? _toggleReplay : null,
                    icon: Icon(
                      _isReplaying ? Icons.stop : Icons.play_arrow,
                    ),
                    tooltip: _isReplaying ? 'Stop Replay' : 'Replay',
                  ),
                  const SizedBox(width: 12),
                  // Status
                  Expanded(
                    child: _buildRecordingStatus(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStatus(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;

    if (_isRecording) {
      return Row(
        children: [
          const Icon(Icons.circle, color: Colors.red, size: 10),
          const SizedBox(width: 6),
          Text('REC  ${_recorder?.eventCount ?? 0} events',
              style: style?.copyWith(color: Colors.red)),
        ],
      );
    }

    if (_isReplaying) {
      return Text(
        'Playing ${_replayEventIndex}/${_recordedEvents.length} events',
        style: style,
      );
    }

    if (_hasRecording) {
      return Text(
        'Ready: ${_recordedEvents.length} events',
        style: style,
      );
    }

    return Text('No recording', style: style);
  }

}

/// 페이지별 샘플 컨텐츠
class _SampleContent extends StatelessWidget {
  final int pageIndex;
  const _SampleContent({required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page ${pageIndex + 1}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            if (pageIndex == 0) ..._page1Content(context),
            if (pageIndex == 1) ..._page2Content(context),
            if (pageIndex == 2) ..._page3Content(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _page1Content(BuildContext context) {
    return [
      Text('Features',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...[
        'Pen, Pencil, Marker, Fixed Pen drawing tools',
        'Color selection with 6 preset colors',
        'Adjustable stroke width (0.5 - 10.0)',
        'Eraser for removing strokes',
        'Shape recognition (circle, rectangle, line)',
        'Lasso selection for moving strokes',
        'Text tool for adding text annotations',
        'Undo / Redo support',
      ].map((item) => _bullet(item)),
    ];
  }

  List<Widget> _page2Content(BuildContext context) {
    return [
      Text('Recording & Replay',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...[
        'Press the red record button to start recording',
        'Draw, switch pages, zoom in/out - all events are captured',
        'Press stop to end recording',
        'Press play to replay the entire session',
        'Strokes, page changes, and viewport changes are recorded',
      ].map((item) => _bullet(item)),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'recorder.start(bookController.eventStream);\n'
          '// ... draw, navigate pages ...\n'
          'final timeline = recorder.stop();\n'
          'replayController.loadFromTimeline(timeline);',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
      ),
    ];
  }

  List<Widget> _page3Content(BuildContext context) {
    return [
      Text('Multi-Page Support',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...[
        'Navigate between pages using the page bar above',
        'Each page has independent strokes and undo history',
        'ScribbleBookController manages all pages',
        'ScribbleCacheManager provides caching and persistence',
        'Try drawing on different pages and switching between them!',
      ].map((item) => _bullet(item)),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.indigo.shade300, width: 4),
          ),
          color: Colors.indigo.shade50,
        ),
        child: Text(
          'Tip: Draw on this page, then switch to another page and draw there. '
          'Come back to verify your strokes are preserved!',
          style: TextStyle(
            color: Colors.indigo.shade700,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ),
    ];
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  \u2022  ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
