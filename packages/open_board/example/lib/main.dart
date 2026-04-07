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
// Main Page — Multi-page Markdown + Drawing + Record/Replay
// =============================================================================

class MultiPageDrawingPage extends StatefulWidget {
  const MultiPageDrawingPage({super.key});

  @override
  State<MultiPageDrawingPage> createState() => _MultiPageDrawingPageState();
}

class _MultiPageDrawingPageState extends State<MultiPageDrawingPage> {
  // Page management
  late final _FakePageProvider _pageProvider;
  late final ScribbleBookController _bookController;
  late final PageController _pageViewController;

  // Drawing tools
  String _currentTool = ScribbleTool.pen;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  bool _isDrawingEnabled = true;

  // Recording
  ScribbleEventBridge? _bridge;
  ScribbleTimelineRecorder? _recorder;
  bool _isRecording = false;

  // Replay
  ScribbleReplayController? _replayController;
  bool _isReplaying = false;
  double _replayProgress = 0;
  String? _lastObtPath;

  static const _tools = [
    (ScribbleTool.pen, Icons.edit, 'Pen'),
    (ScribbleTool.pencil, Icons.create, 'Pencil'),
    (ScribbleTool.marker, Icons.highlight, 'Marker'),
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
  void initState() {
    super.initState();
    _pageProvider = _FakePageProvider();
    _bookController = ScribbleBookController(
      pageIds: _samplePages.map((p) => p.id).toList(),
      contentId: 'example-book',
      pageProvider: _pageProvider,
    );
    _pageViewController = PageController();
    _bookController.addListener(_onBookChanged);
  }

  void _onBookChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopRecording();
    _stopReplay();
    _bookController.removeListener(_onBookChanged);
    _bookController.dispose();
    _pageViewController.dispose();
    super.dispose();
  }

  // ===== Tool Control =====

  void _selectTool(String tool) {
    setState(() => _currentTool = tool);
    _bookController.activeController.setTool(tool);
  }

  void _selectColor(Color color) {
    setState(() => _currentColor = color);
    _bookController.activeController.modeNotifier.setColor(color);
  }

  void _setStrokeWidth(double width) {
    setState(() => _currentStrokeWidth = width);
    _bookController.activeController.modeNotifier.setStrokeWidth(width);
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
    _bridge = ScribbleEventBridge(_bookController);
    _recorder = ScribbleTimelineRecorder(
      contentId: 'example-book',
      pageIds: _bookController.pageIds,
    );

    _bookController.startRecording();
    _bridge!.attach();
    _recorder!.start(_bookController.eventStream);

    setState(() => _isRecording = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording started'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.obt';

      await _recorder!.stopAndSave(path);
      _bridge!.detach();
      _bookController.stopRecording();

      _lastObtPath = path;
      setState(() => _isRecording = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording saved (${_recorder!.eventCount} events)'),
            action: SnackBarAction(
              label: 'Replay',
              onPressed: _startReplay,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }

    _bridge = null;
    _recorder = null;
  }

  // ===== Replay =====

  Future<void> _startReplay() async {
    if (_lastObtPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording available. Record first!')),
      );
      return;
    }

    // Clear all pages for clean replay
    for (var i = 0; i < _bookController.pageCount; i++) {
      _bookController.controllerAt(i).clear();
    }
    await _bookController.goToPage(0);
    _pageViewController.jumpToPage(0);

    _replayController = ScribbleReplayController();
    await _replayController!.loadFromFile(_lastObtPath!);

    // Listen to position changes
    _replayController!.onPositionChanged.listen((micros) {
      if (!mounted) return;
      final duration = _replayController!.durationMicros;
      setState(() {
        _replayProgress = duration > 0 ? micros / duration : 0;
      });
    });

    _replayController!.addListener(() {
      if (!mounted) return;
      if (_replayController!.state == ReplayState.completed) {
        setState(() => _isReplaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replay completed')),
        );
      }
    });

    _replayController!.play();
    setState(() {
      _isReplaying = true;
      _isDrawingEnabled = false;
    });
  }

  void _stopReplay() {
    _replayController?.dispose();
    _replayController = null;
    setState(() {
      _isReplaying = false;
      _replayProgress = 0;
      _isDrawingEnabled = true;
    });
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentIndex = _bookController.currentPageIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_samplePages[currentIndex].title),
        centerTitle: true,
        leading: _isRecording
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
          // Drawing toggle
          IconButton(
            onPressed: _toggleDrawing,
            icon: Icon(
              _isDrawingEnabled ? Icons.draw : Icons.visibility,
            ),
            tooltip: _isDrawingEnabled ? 'View mode' : 'Draw mode',
          ),
          // Undo / Redo
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
          // Clear
          IconButton(
            onPressed: () => _bookController.activeController.clear(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tool bar (visible only in draw mode)
          if (_isDrawingEnabled && !_isReplaying) _buildToolBar(colorScheme),

          // Replay controls
          if (_isReplaying) _buildReplayControls(colorScheme),

          // Page content
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
                return _buildPage(page, index);
              },
            ),
          ),

          // Page indicator + Record/Replay buttons
          _buildBottomBar(colorScheme, currentIndex),
        ],
      ),
    );
  }

  Widget _buildPage(
    ({String id, String title, String markdown}) page,
    int index,
  ) {
    return Stack(
      children: [
        // Markdown content layer
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SmoothMarkdown(
              data: page.markdown,
              styleSheet: MarkdownStyleSheet.github(),
            ),
          ),
        ),

        // Drawing overlay
        Positioned.fill(
          child: SimpleScribbleWidget(
            controller: _bookController.controllerAt(index),
            allowedPointersMode: ScribblePointerMode.all,
            isScribbleEnabled: _isDrawingEnabled && !_isReplaying,
            maxScale: 4.0,
            panDirection: PanDirection.none,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildToolBar(ColorScheme colorScheme) {
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
          // Tools
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
                      selected: _currentTool == tool,
                      onSelected: (_) => _selectTool(tool),
                    ),
                  ),
              ],
            ),
          ),
          // Colors & width
          Row(
            children: [
              for (final color in _colors)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _selectColor(color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentColor == color
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: _currentColor == color ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _currentStrokeWidth,
                  min: 0.5,
                  max: 8.0,
                  divisions: 15,
                  onChanged: _setStrokeWidth,
                ),
              ),
              Text(
                _currentStrokeWidth.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplayControls(ColorScheme colorScheme) {
    final replay = _replayController;
    if (replay == null) return const SizedBox.shrink();

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
              value: _replayProgress.clamp(0.0, 1.0),
              backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _stopReplay,
            icon: Icon(Icons.stop, color: colorScheme.onPrimaryContainer),
            tooltip: 'Stop replay',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme, int currentIndex) {
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
            // Page indicator
            for (var i = 0; i < _samplePages.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => _goToPage(i),
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

            const Spacer(),

            // Record / Replay buttons
            if (!_isReplaying) ...[
              FilledButton.tonalIcon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  color: _isRecording ? Colors.red : null,
                  size: 16,
                ),
                label: Text(_isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _lastObtPath != null ? _startReplay : null,
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

// =============================================================================
// Simple in-memory page provider for the example
// =============================================================================

class _FakePageProvider implements ScribblePageProvider {
  final Map<String, ScribbleController> _controllers = {};

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
  }) async => true;

  @override
  Future<Scribble?> loadScribble(String key) async => null;

  @override
  Future<bool> deleteScribble(String key) async => true;
}
