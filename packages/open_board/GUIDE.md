# Open Board Usage Guide

Flutter drawing & annotation library with multi-page support, recording, and replay.

## Installation

```yaml
dependencies:
  open_board:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/open_board
      ref: <commit or open_board-vX.Y.Z tag>
```

```dart
import 'package:open_board/open_board.dart';
```

## Quick Start

### 1. Single Page Drawing

The simplest way to add drawing capability:

```dart
class DrawingPage extends StatefulWidget {
  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final controller = ScribbleController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScribbleWidget(
      controller: controller,
      allowedPointersMode: ScribblePointerMode.all,
      child: Container(color: Colors.white),
    );
  }
}
```

### 2. Tool & Color Control

```dart
// Change drawing tool
controller.setTool(ScribbleTool.pen);      // pen, pencil, marker, fixedPen
controller.setTool(ScribbleTool.eraser);   // eraser
controller.setTool(ScribbleTool.shape);    // shape recognition
controller.setTool(ScribbleTool.lasso);    // lasso selection

// Change color & stroke width
controller.modeNotifier.setColor(Colors.red);
controller.modeNotifier.setStrokeWidth(3.0);

// Undo / Redo / Clear
controller.undo();
controller.redo();
controller.clear();
```

### 3. Drawing Over Content

Stack `SimpleScribbleWidget` on top of any widget:

```dart
SimpleScribbleWidget(
  controller: controller,
  child: Image.asset('assets/worksheet.png'),
)
```

## Multi-Page Management

### ScribbleBookController

Manages multiple pages with auto-save/load:

```dart
// Create a page provider (cache manager)
final cacheManager = ScribbleCacheManager(basePath: docsDir.path);

// Create book controller
final book = ScribbleBookController(
  pageIds: ['page1', 'page2', 'page3'],
  contentId: 'book123',
  pageProvider: cacheManager,
);

// Navigate pages
await book.goToPage(1);
await book.goToNextPage();
await book.goToPreviousPage();

// Add / remove pages
book.addPage(pageId: 'page4');
await book.removePage(2);

// Access current page controller
final currentController = book.activeController;
currentController.undo();
```

### Double-Page Mode

```dart
await book.setDoublePageMode(true);
print(book.currentSpreadIndex); // Spread index
print(book.spreadCount);        // Total spreads

// Navigate by spread
await book.goToSpread(2);

// Access right page controller
final rightPage = book.secondaryController;
```

## Recording & Replay

### Recording a Session

```dart
// 1. Set up recording
final bridge = ScribbleEventBridge(bookController);
final recorder = ScribbleTimelineRecorder(
  contentId: 'book123',
  pageIds: bookController.pageIds,
);

// 2. Start recording
bookController.startRecording();
bridge.attach();
recorder.start(bookController.eventStream);

// ... user draws ...

// 3. Stop & save
final timeline = await recorder.stopAndSave('/path/to/session.obt');
bridge.detach();
bookController.stopRecording();
```

### Replaying a Session

```dart
// 1. Load timeline
final replay = ScribbleReplayController();
await replay.loadFromFile('/path/to/session.obt');

// 2. Connect handler
final handler = ScribbleReplayHandler(
  bookController: bookController,
  pageProvider: cacheManager,
);
handler.attach(replay);

// 3. Control playback
replay.play();
replay.pause();
replay.seek(Duration(seconds: 30));
replay.setSpeed(1.5);

// 4. Listen to position changes (for UI slider)
replay.onPositionChanged.listen((micros) {
  // Update progress bar
});

// 5. Cleanup
handler.detach();
replay.dispose();
```

### Syncing with Audio

```dart
// Sync replay position to audio player
audioPlayer.onPositionChanged.listen((position) {
  replay.syncTo(position);
});
```

## Data Export & Import

```dart
// Export as protobuf bytes
final bytes = controller.exportAsBytes();

// Import from bytes
controller.importFromBytes(bytes);

// Capture as image
final image = await controller.captureAsImage(pixelRatio: 3.0);
final pngData = await controller.captureAsPng(pixelRatio: 3.0);
```

## Timeline File (.obt)

```dart
// Write
await TimelineFile.write('session.obt', timeline);

// Read
final timeline = await TimelineFile.read('session.obt');

// Quick validation
final isValid = await TimelineFile.isValidObtFile('session.obt');
final version = await TimelineFile.readFormatVersion('session.obt');
```

## Widget Reference

### SimpleScribbleWidget

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `controller` | `ScribbleController?` | auto | Drawing controller |
| `child` | `Widget` | required | Content to draw on |
| `allowedPointersMode` | `ScribblePointerMode` | `penOnly` | Input device filter |
| `maxScale` | `double` | `6.0` | Max zoom level |
| `panDirection` | `PanDirection` | `horizontal` | Pan direction constraint |
| `contentLogicalSize` | `Size?` | null | Fixed coordinate system |
| `isScribbleEnabled` | `bool` | `true` | Enable/disable drawing |

### ScribblePointerMode

| Mode | Description |
|------|-------------|
| `all` | Stylus + finger + mouse |
| `penOnly` | Stylus only (default) |
| `mouseOnly` | Mouse only |
| `mouseAndPen` | Mouse + stylus |

### ScribbleTool

| Tool | Constant | Description |
|------|----------|-------------|
| Pen | `ScribbleTool.pen` | Pressure-sensitive pen |
| Pencil | `ScribbleTool.pencil` | Textured pencil |
| Marker | `ScribbleTool.marker` | Semi-transparent marker |
| Fixed Pen | `ScribbleTool.fixedPen` | Fixed-width pen |
| Eraser | `ScribbleTool.eraser` | Stroke eraser |
| Shape | `ScribbleTool.shape` | Auto shape recognition |
| Text | `ScribbleTool.text` | Text annotation |
| Lasso | `ScribbleTool.lasso` | Lasso selection |

### ReplayState

| State | Description |
|-------|-------------|
| `idle` | No timeline loaded |
| `playing` | Playback in progress |
| `paused` | Playback paused |
| `completed` | Playback finished |
