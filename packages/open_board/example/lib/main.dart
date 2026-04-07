import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:open_board/open_board.dart';
import 'package:path_provider/path_provider.dart';

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
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const MultiPageDrawingPage(),
    );
  }
}

// =============================================================================
// Sample markdown content for each page
// =============================================================================

const _samplePages = [
  (
    id: 'page1',
    title: 'Introduction',
    markdown: '''
# Welcome to Open Board

Open Board is a **Flutter drawing & annotation library** with:

- Multi-page support
- Recording & replay
- Pressure-sensitive stylus input

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  open_board:
    path: ../open-board
```

Then import and use:

```dart
import 'package:open_board/open_board.dart';

SimpleScribbleWidget(
  controller: controller,
  child: YourContent(),
)
```

> Try drawing on this page with your finger or stylus!
''',
  ),
  (
    id: 'page2',
    title: 'Math & Formulas',
    markdown: r'''
# Math Formulas

## Quadratic Formula

The solutions to $ax^2 + bx + c = 0$ are:

$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

## Pythagorean Theorem

$$a^2 + b^2 = c^2$$

## Euler's Identity

$$e^{i\pi} + 1 = 0$$

## Integration

$$\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}$$

---

*Annotate the formulas with your own notes!*
''',
  ),
  (
    id: 'page3',
    title: 'Code Examples',
    markdown: '''
# Code Examples

## ScribbleController

```dart
final controller = ScribbleController(
  initialTool: ScribbleTool.pen,
  initialColor: Colors.black,
  initialStrokeWidth: 2.0,
);

// Tool control
controller.setTool(ScribbleTool.marker);
controller.modeNotifier.setColor(Colors.red);

// History
controller.undo();
controller.redo();
controller.clear();
```

## Recording

```dart
final recorder = ScribbleTimelineRecorder(
  contentId: 'book123',
  pageIds: ['page1', 'page2'],
);

recorder.start(bookController.eventStream);
// ... drawing ...
final timeline = await recorder.stopAndSave('session.obt');
```

## Replay

```dart
final replay = ScribbleReplayController();
await replay.loadFromFile('session.obt');
replay.play();
replay.setSpeed(1.5);
```
''',
  ),
  (
    id: 'page4',
    title: 'Checklist',
    markdown: '''
# Study Checklist

## Chapter 1: Basics
- [x] Read introduction
- [x] Set up development environment
- [ ] Complete exercise 1
- [ ] Complete exercise 2

## Chapter 2: Advanced
- [ ] Multi-page management
- [ ] Recording & replay
- [ ] Audio synchronization
- [ ] Export & sharing

## Notes

| Feature | Status | Priority |
|---------|--------|----------|
| Drawing | Done | High |
| Pages | Done | High |
| Recording | Done | Medium |
| Sharing | Planned | Low |

---

*Check off items as you complete them!*
''',
  ),
];

// =============================================================================
// Recording Manager
// =============================================================================

class RecordingManager {
  final ScribbleBookController bookController;

  ScribbleEventBridge? _bridge;
  ScribbleTimelineRecorder? _recorder;
  bool _isRecording = false;
  String? lastObtPath;

  RecordingManager({required this.bookController});

  bool get isRecording => _isRecording;

  Future<void> start() async {
    _bridge = ScribbleEventBridge(bookController);
    _recorder = ScribbleTimelineRecorder(
      contentId: bookController.contentId,
      pageIds: bookController.pageIds,
    );

    bookController.startRecording();
    _bridge!.attach();
    _recorder!.start(bookController.eventStream);
    _isRecording = true;
  }

  Future<int> stop() async {
    if (!_isRecording) return 0;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.obt';

    await _recorder!.stopAndSave(path);
    _bridge!.detach();
    bookController.stopRecording();

    final eventCount = _recorder!.eventCount;
    lastObtPath = path;
    _isRecording = false;
    _bridge = null;
    _recorder = null;
    return eventCount;
  }
}

// =============================================================================
// Replay Manager — 포인트 타임스탬프 기반 실시간 애니메이션
// =============================================================================

class ReplayManager {
  final ScribbleBookController bookController;
  final PageController pageViewController;
  final VoidCallback onStateChanged;

  ScribbleReplayController? _controller;
  StreamSubscription<ScribbleBookEvent>? _eventSub;
  StreamSubscription<int>? _positionSub;
  Timer? _animationTimer;

  Map<String, List<Stroke>> _savedStrokes = {};
  int _recordingOriginMicros = 0;

  bool isReplaying = false;
  double progress = 0;

  ReplayManager({
    required this.bookController,
    required this.pageViewController,
    required this.onStateChanged,
  });

  ScribbleController? _controllerForPage(String pageId) {
    final index = bookController.pageIds.indexOf(pageId);
    if (index < 0) return null;
    return bookController.controllerAt(index);
  }

  Future<void> start(String obtPath) async {
    // 스트로크 백업
    _savedStrokes = {};
    _recordingOriginMicros = 0;
    for (var i = 0; i < bookController.pageCount; i++) {
      final pageId = bookController.pageIds[i];
      final scribble = bookController.controllerAt(i).currentScribble;
      _savedStrokes[pageId] = List<Stroke>.from(scribble.strokes);
    }

    // 클리어 & 첫 페이지로 이동
    for (var i = 0; i < bookController.pageCount; i++) {
      bookController.controllerAt(i).clear();
    }
    await bookController.goToPage(0);
    pageViewController.jumpToPage(0);

    // 타임라인 로드
    _controller = ScribbleReplayController();
    await _controller!.loadFromFile(obtPath);

    // 이벤트 스트림: 타임라인 시작 시각 캡처 + 페이지 전환
    _eventSub = _controller!.onEvent.listen((event) {
      if (_recordingOriginMicros == 0) {
        _recordingOriginMicros = event.timestampMicros;
      }
      if (event is PageChangedEvent) {
        bookController.goToPage(event.toIndex);
        pageViewController.jumpToPage(event.toIndex);
      }
    });

    // 60fps 애니메이션 타이머
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateAnimation(),
    );

    // 진행률
    _positionSub = _controller!.onPositionChanged.listen((micros) {
      final duration = _controller!.durationMicros;
      progress = duration > 0 ? micros / duration : 0;
      onStateChanged();
    });

    // 완료 감지
    _controller!.addListener(() {
      if (_controller!.state == ReplayState.completed) {
        _finalizeAllStrokes();
        isReplaying = false;
        onStateChanged();
      }
    });

    _controller!.play();
    isReplaying = true;
    onStateChanged();
  }

  void _updateAnimation() {
    if (_controller == null || _recordingOriginMicros == 0) return;

    final absoluteTime =
        _recordingOriginMicros + _controller!.positionMicros;

    for (final entry in _savedStrokes.entries) {
      final allStrokes = entry.value;
      if (allStrokes.isEmpty) continue;

      final controller = _controllerForPage(entry.key);
      if (controller == null) continue;

      final displayStrokes = <Stroke>[];
      for (final stroke in allStrokes) {
        final partial =
            StrokeAnimator.createPartialStroke(stroke, absoluteTime);
        if (partial != null) displayStrokes.add(partial);
      }

      controller.loadScribble(Scribble()..strokes.addAll(displayStrokes));
    }
  }

  void _finalizeAllStrokes() {
    for (final entry in _savedStrokes.entries) {
      final controller = _controllerForPage(entry.key);
      if (controller == null) continue;
      controller.loadScribble(Scribble()..strokes.addAll(entry.value));
    }
  }

  void stop() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
    _eventSub?.cancel();
    _eventSub = null;
    _controller?.dispose();
    _controller = null;
    isReplaying = false;
    progress = 0;
  }
}

// =============================================================================
// In-memory page provider
// =============================================================================

class _InMemoryPageProvider implements ScribblePageProvider {
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
  void setActiveController(String key) {}

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
    _scribbles.remove(key);
    return true;
  }
}

// =============================================================================
// Main Page
// =============================================================================

class MultiPageDrawingPage extends StatefulWidget {
  const MultiPageDrawingPage({super.key});

  @override
  State<MultiPageDrawingPage> createState() => _MultiPageDrawingPageState();
}

class _MultiPageDrawingPageState extends State<MultiPageDrawingPage> {
  late final DrawingState _drawingState;
  late final _InMemoryPageProvider _pageProvider;
  late final ScribbleBookController _bookController;
  late final PageController _pageViewController;
  late final RecordingManager _recording;
  late final ReplayManager _replay;

  String _currentTool = ScribbleTool.pen;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  bool _isDrawingEnabled = true;

  static const _toolToDrawingTool = {
    ScribbleTool.pen: DrawingTool.pen,
    ScribbleTool.pencil: DrawingTool.pencil,
    ScribbleTool.marker: DrawingTool.marker,
    ScribbleTool.fixedPen: DrawingTool.fixedPen,
    ScribbleTool.eraser: DrawingTool.erase,
  };

  @override
  void initState() {
    super.initState();

    _drawingState = DrawingState()
      ..pointerMode.value = DrawingPointerMode.mouseOnly
      ..selectedTool.value = DrawingTool.pen
      ..selectedColor.value = _currentColor
      ..selectedThickness.value = _currentStrokeWidth;

    _pageProvider = _InMemoryPageProvider();
    _bookController = ScribbleBookController(
      pageIds: _samplePages.map((p) => p.id).toList(),
      contentId: 'example-book',
      pageProvider: _pageProvider,
    );
    _pageViewController = PageController();
    _bookController.addListener(_onChanged);

    _recording = RecordingManager(bookController: _bookController);
    _replay = ReplayManager(
      bookController: _bookController,
      pageViewController: _pageViewController,
      onStateChanged: _onChanged,
    );
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopRecording();
    _replay.stop();
    _bookController.removeListener(_onChanged);
    _bookController.dispose();
    _pageViewController.dispose();
    super.dispose();
  }

  // ===== Tool Control =====

  void _selectTool(String tool) {
    setState(() => _currentTool = tool);
    final drawingTool = _toolToDrawingTool[tool];
    if (drawingTool != null) {
      _drawingState.selectedTool.value = drawingTool;
    }
  }

  void _selectColor(Color color) {
    setState(() => _currentColor = color);
    _drawingState.selectedColor.value = color;
  }

  void _setStrokeWidth(double width) {
    setState(() => _currentStrokeWidth = width);
    _drawingState.selectedThickness.value = width;
  }

  void _toggleDrawing() {
    setState(() => _isDrawingEnabled = !_isDrawingEnabled);
  }

  // ===== Page Navigation =====

  Future<void> _goToPage(int index) async {
    await _bookController.goToPage(index);
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ===== Recording =====

  Future<void> _startRecording() async {
    await _recording.start();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording started'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording.isRecording) return;
    try {
      final eventCount = await _recording.stop();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording saved ($eventCount events)'),
            action: SnackBarAction(
              label: 'Replay',
              onPressed: _startReplay,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  // ===== Replay =====

  Future<void> _startReplay() async {
    final path = _recording.lastObtPath;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording available. Record first!')),
      );
      return;
    }
    setState(() => _isDrawingEnabled = false);
    await _replay.start(path);
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    final currentIndex = _bookController.currentPageIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_samplePages[currentIndex].title),
        centerTitle: true,
        leading: _recording.isRecording
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  width: 12,
                  height: 12,
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _toggleDrawing,
            icon: Icon(_isDrawingEnabled ? Icons.draw : Icons.visibility),
            tooltip: _isDrawingEnabled ? 'View mode' : 'Draw mode',
          ),
          IconButton(
            onPressed: _bookController.activeController.canUndo
                ? _bookController.activeController.undo
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: _bookController.activeController.canRedo
                ? _bookController.activeController.redo
                : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            onPressed: () => _bookController.activeController.clear(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isDrawingEnabled && !_replay.isReplaying)
            _ToolBar(
              currentTool: _currentTool,
              currentColor: _currentColor,
              currentStrokeWidth: _currentStrokeWidth,
              onToolSelected: _selectTool,
              onColorSelected: _selectColor,
              onStrokeWidthChanged: _setStrokeWidth,
            ),
          if (_replay.isReplaying)
            _ReplayControls(
              progress: _replay.progress,
              onStop: () {
                _replay.stop();
                setState(() => _isDrawingEnabled = true);
              },
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageViewController,
              itemCount: _samplePages.length,
              onPageChanged: (index) async {
                if (index != _bookController.currentPageIndex) {
                  await _bookController.goToPage(index);
                }
              },
              physics: _isDrawingEnabled
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemBuilder: (context, index) {
                final page = _samplePages[index];
                return _DrawingPage(
                  markdown: page.markdown,
                  controller: _bookController.controllerAt(index),
                  isEnabled: _isDrawingEnabled && !_replay.isReplaying,
                );
              },
            ),
          ),
          _BottomBar(
            pageCount: _samplePages.length,
            currentIndex: currentIndex,
            isRecording: _recording.isRecording,
            isReplaying: _replay.isReplaying,
            hasRecording: _recording.lastObtPath != null,
            onPageTap: _goToPage,
            onRecordTap: _recording.isRecording
                ? _stopRecording
                : _startRecording,
            onReplayTap: _startReplay,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Extracted Widgets
// =============================================================================

class _DrawingPage extends StatelessWidget {
  const _DrawingPage({
    required this.markdown,
    required this.controller,
    required this.isEnabled,
  });

  final String markdown;
  final ScribbleController controller;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentSize = Size(constraints.maxWidth, constraints.maxHeight);
        return SimpleScribbleWidget(
          controller: controller,
          allowedPointersMode: ScribblePointerMode.all,
          isScribbleEnabled: isEnabled,
          maxScale: 4.0,
          panDirection: PanDirection.none,
          contentLogicalSize: contentSize,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SmoothMarkdown(
              data: markdown,
              styleSheet: MarkdownStyleSheet.github(),
            ),
          ),
        );
      },
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onStrokeWidthChanged,
  });

  final String currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final ValueChanged<String> onToolSelected;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onStrokeWidthChanged;

  static const _tools = [
    (ScribbleTool.pen, Icons.edit, 'Pen'),
    (ScribbleTool.pencil, Icons.create, 'Pencil'),
    (ScribbleTool.marker, Icons.highlight, 'Marker'),
    (ScribbleTool.fixedPen, Icons.precision_manufacturing, 'Fixed'),
    (ScribbleTool.eraser, Icons.auto_fix_normal, 'Eraser'),
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
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
                      onSelected: (_) => onToolSelected(tool),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              for (final color in _colors)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentColor == color
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: currentColor == color ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: currentStrokeWidth,
                  min: 0.5,
                  max: 8.0,
                  divisions: 15,
                  onChanged: onStrokeWidthChanged,
                ),
              ),
              Text(
                currentStrokeWidth.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplayControls extends StatelessWidget {
  const _ReplayControls({
    required this.progress,
    required this.onStop,
  });

  final double progress;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            'Replaying',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor:
                  colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              valueColor:
                  AlwaysStoppedAnimation(colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onStop,
            icon: Icon(Icons.stop, color: colorScheme.onPrimaryContainer),
            tooltip: 'Stop replay',
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.pageCount,
    required this.currentIndex,
    required this.isRecording,
    required this.isReplaying,
    required this.hasRecording,
    required this.onPageTap,
    required this.onRecordTap,
    required this.onReplayTap,
  });

  final int pageCount;
  final int currentIndex;
  final bool isRecording;
  final bool isReplaying;
  final bool hasRecording;
  final ValueChanged<int> onPageTap;
  final VoidCallback onRecordTap;
  final VoidCallback onReplayTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < pageCount; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => onPageTap(i),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i == currentIndex
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == currentIndex
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isReplaying) ...[
              FilledButton.tonalIcon(
                onPressed: onRecordTap,
                icon: Icon(
                  isRecording ? Icons.stop : Icons.fiber_manual_record,
                  color: isRecording ? Colors.red : null,
                  size: 16,
                ),
                label: Text(isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: hasRecording ? onReplayTap : null,
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Replay'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
