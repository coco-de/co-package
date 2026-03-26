<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# Open Board

[![pub package](https://img.shields.io/pub/v/open_board.svg)](https://pub.dev/packages/open_board)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A powerful and flexible Flutter package for adding drawing and annotation capabilities to any widget. Perfect for PDF viewers, image editors, note-taking apps, and educational tools.

## ✨ Features

### 🎨 Drawing Tools

- **Pen**: Smooth digital ink with pressure sensitivity
- **Pencil**: Natural pencil-like strokes
- **Marker**: Highlighted text effect with transparency
- **Eraser**: Smart erasing with customizable size
- **Shape**: Automatic shape recognition and correction
- **Text**: Rich text annotations with formatting options

### 🎯 Advanced Functionality

- **Lasso Selection**: Select multiple strokes for batch operations
- **Interactive Viewer**: Zoom, pan, and rotate with preserved drawing quality
- **Multi-touch Support**: Intelligent touch handling (stylus for drawing, finger for navigation)
- **Auto-save**: Automatic saving with debouncing
- **Undo/Redo**: Full history management
- **Export/Import**: Save and load drawings in multiple formats

### 📱 Smart Integration

- **Overlay Any Widget**: Add drawing capabilities to PDFs, images, or custom content
- **Responsive Design**: Automatically adapts to different screen sizes and orientations
- **Performance Optimized**: Efficient rendering with minimal impact on UI performance
- **Cross-platform**: Works on iOS, Android, Web, and Desktop

## 🚀 Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  open_board: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Basic Usage

#### Simple Drawing Widget

```dart
import 'package:open_board/open_board.dart';

class MyDrawingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Drawing App')),
      body: SimpleScribbleWidget(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Center(
            child: Text('Draw anywhere on this area!'),
          ),
        ),
        onScribbleChanged: (scribble) {
          print('Drawing updated: ${scribble.strokes.length} strokes');
        },
      ),
    );
  }
}
```

#### PDF Annotation

```dart
import 'package:open_board/open_board.dart';

class PDFAnnotationPage extends StatelessWidget {
  final ScribbleController controller = ScribbleController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimpleScribbleWidget(
        controller: controller,
        child: PdfViewer.asset('assets/document.pdf'),
        onScribbleChanged: (scribble) {
          // Auto-save annotations
          saveAnnotations(scribble);
        },
      ),
      floatingActionButton: ScribbleDrawingToolbar(
        controller: controller,
      ),
    );
  }
}
```

## 📖 Core Components

### ScribbleWidget

The main widget that provides drawing capabilities over any child widget.

```dart
ScribbleWidget(
  notifier: scribbleNotifier,
  modeNotifier: modeNotifier,
  child: YourContentWidget(),
  onScribble: (notifier) => handleDrawingStart(notifier),
  onScribbleFinished: (notifier) => handleDrawingEnd(notifier),
  isScribbleEnable: true,
  maxScale: 3.0,
)
```

### SimpleScribbleWidget

A simplified wrapper that handles all the complex setup internally.

```dart
SimpleScribbleWidget(
  controller: controller, // Optional - auto-created if not provided
  child: YourContentWidget(),
  onScribbleChanged: (scribble) => saveDrawing(scribble),
  initialTool: 'pen',
  initialColor: Colors.blue,
  maxScale: 4.0,
)
```

### ScribbleController

High-level controller for managing drawing state and tools.

```dart
final controller = ScribbleController();

// Tool control
controller.setPen();
controller.setColor(Colors.red);
controller.setStrokeWidth(3.0);

// Drawing control
controller.undo();
controller.redo();
controller.clear();

// Data management
final bytes = controller.exportAsBytes();
controller.importFromBytes(bytes);
```

### ScribbleCacheManager

Unified manager for both scribble data persistence and controller management with shared tool settings.

```dart
final manager = ScribbleCacheManager.instance;

// Get controller for specific page (with auto-loading)
final pageController = await manager.getControllerAsync('book_1/page_0');

// Get controller synchronously (without auto-loading)
final pageController = manager.getController('book_1/page_0');

// Shared tool settings across all pages
manager.setTool(ScribbleTool.marker);
manager.setColor(Colors.yellow);
manager.setStrokeWidth(3.0);

// Page operations
manager.clearPage('book_1/page_0');
manager.undoPage('book_1/page_0');
manager.redoPage('book_1/page_0');

// Check page state
bool isEmpty = manager.isPageEmpty('book_1/page_0');
bool canUndo = manager.canUndoPage('book_1/page_0');

// Data management
final bytes = manager.exportPageData('book_1/page_0');
manager.importPageData('book_1/page_0', bytes);

// Persistence (automatic with controllers)
await manager.saveScribble('book_1/page_0', scribble);
final scribble = await manager.loadScribble('book_1/page_0');
```

## 🎨 Drawing Tools

### Tool Selection

```dart
// Using controller
controller.setPen();        // Digital pen
controller.setPencil();     // Pencil effect
controller.setMarker();     // Highlighter
controller.setEraser();     // Eraser tool
controller.setText();       // Text tool
controller.setLasso();      // Selection tool

// Using tool constants
controller.setTool(ScribbleTool.pen);
controller.setTool(ScribbleTool.marker);
```

### Customization

```dart
// Colors
controller.setColor(Colors.blue);
controller.setColor(Color(0xFF123456));

// Stroke width
controller.setStrokeWidth(1.0);  // Thin
controller.setStrokeWidth(5.0);  // Thick

// Custom tool settings
final inkInfo = InkGroupInfo(
  selectedInk: 'pen',
  selectedColor: Colors.green,
  strokeWidth: 2.5,
);
```

## 📱 Advanced Features

### Multi-page Management

```dart
class NotebookApp extends StatefulWidget {
  @override
  _NotebookAppState createState() => _NotebookAppState();
}

class _NotebookAppState extends State<NotebookApp> {
  final ScribbleCacheManager manager = ScribbleCacheManager.instance;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ScribbleController>(
        future: manager.getControllerAsync('book_1/page_$currentPage'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          return SimpleScribbleWidget(
            controller: snapshot.data!,
            child: YourPageContent(currentPage),
            onScribbleChanged: (scribble) {
              // Auto-saved by ScribbleCacheManager
              print('Page $currentPage updated');
            },
          );
        },
      ),
      bottomNavigationBar: ScribbleDrawingToolbar(
        scribbleManager: manager,
        currentContentId: 'book_1',
        currentPageIndex: currentPagerror.toString(),
      ),
    );
  }
}
```

### Auto-save and Persistence

```dart
class AutoSaveExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleScribbleWidget(
      child: YourContent(),
      onScribbleChanged: (scribble) {
        // Manual save logic or use ScribbleController for auto-save
        print('Auto-saved: ${scribble.strokes.length} strokes');
        saveScribbleData(scribble);
      },
    );
  }

  void saveScribbleData(Scribble scribble) {
    // Implement your save logic here
    ScribbleCacheManager.instance.saveScribble('book_1', 'page_0', scribble);
  }
}
```

### Custom Tools and UI

```dart
class CustomToolbar extends StatelessWidget {
  final ScribbleController controller;

  const CustomToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => controller.setPen(),
        ),
        IconButton(
          icon: Icon(Icons.color_lens),
          onPressed: () => _showColorPicker(),
        ),
        IconButton(
          icon: Icon(Icons.undo),
          onPressed: controller.canUndo ? controller.undo : null,
        ),
      ],
    );
  }
}
```

## 🔧 Configuration

### Pointer Mode (Hand-writing Prevention)

```dart
SimpleScribbleWidget(
  allowedPointersMode: ScribblePointerMode.penOnly, // Only stylus/pen
  // allowedPointersMode: ScribblePointerMode.all,  // Touch + stylus
  child: YourWidget(),
)
```

### Performance Settings

```dart
ScribbleWidget(
  pressureFactor: 0.5,    // Pressure sensitivity
  speedFactor: 0.1,       // Speed-based stroke variation
  minWidthFactor: 0.3,    // Minimum stroke width
  maxScale: 4.0,          // Maximum zoom level
  child: YourWidget(),
)
```

### Custom Cache Management

```dart
// Access unified cache manager
final cacheManager = ScribbleCacheManager.instance;

// Controller management
final controller = await cacheManager.getControllerAsync('book_1/page_0');
final syncController = cacheManager.getController('book_1/page_0');

// Check controller existence
bool hasController = cacheManager.hasController('book_1/page_0');

// Remove specific controller
cacheManager.removeController('book_1/page_0');

// Manual save (auto-save is enabled by default)
await cacheManager.saveScribble('book_1/page_0', scribble);

// Load from cache
final scribble = await cacheManager.loadScribble('book_1/page_0');

// Bulk operations
final allData = cacheManager.exportAllPagesData();
cacheManager.importAllPagesData(allData);

// Cache management
await cacheManager.clearAllCache();
final cacheInfo = await cacheManager.getCacheInfo();

// Auto-save control
cacheManager.setAutoSaveEnabled(false);  // Disable auto-save
cacheManager.setAutoSaveEnabled(true);   // Enable auto-save
```

## 💾 Data Management

### Export Formats

```dart
// Binary format (protobuf)
final Uint8List bytes = controller.exportAsBytes();

// JSON format
final String json = controller.exportAsJson();

// Image export
final ByteData imageData = await scribbleWidget.renderImage(
  pixelRatio: 2.0,
  format: ui.ImageByteFormat.png,
);
```

### Import Data

```dart
// From bytes
controller.importFromBytes(bytes);

// From JSON
controller.importFromJson(jsonString);

// Load initial data
final controller = ScribbleController(
  initialScribble: loadedScribble,
);
```

## 🎯 Use Cases

### 1. PDF Annotation App

```dart
class PDFAnnotator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleScribbleWidget(
      child: PdfViewer.asset('assets/document.pdf'),
      allowedPointersMode: ScribblePointerMode.penOnly,
      onScribbleChanged: (scribble) => autoSaveAnnotations(scribble),
    );
  }
}
```

### 2. Digital Whiteboard

```dart
class Whiteboard extends StatelessWidget {
  final ScribbleController controller = ScribbleController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScribbleDrawingToolbar(controller: controller),
        Expanded(
          child: SimpleScribbleWidget(
            controller: controller,
            child: Container(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
```

### 3. Image Editor

```dart
class ImageEditor extends StatelessWidget {
  final String imagePath;

  const ImageEditor({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SimpleScribbleWidget(
      child: Image.file(File(imagePath)),
      onScribbleFinished: (scribble) => saveEditedImage(scribble),
    );
  }
}
```

### 4. Educational App

```dart
class MathWorksheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleScribbleWidget(
      child: WorksheetContent(),
      onScribbleChanged: (scribble) {
        trackStudentProgress(scribble);
        // Auto-save student's work
        ScribbleCacheManager.instance.saveScribble('worksheet_1', 'page_0', scribble);
      },
    );
  }
}
```

## 🔄 Migration Guide

### From version 0.0.1 to latest

If you're upgrading from an earlier version, here are the key changes:

```dart
// Old way
ScribbleWidget(
  notifier: ScribbleNotifier(),
  modeNotifier: ScribbleModeNotifier(),
  // ... complex setup
)

// New way
SimpleScribbleWidget(
  child: YourWidget(),
  // ... simple configuration
)
```

## 🧪 Testing

```dart
// Testing drawing functionality
testWidgets('Should allow drawing on widget', (WidgetTester tester) async {
  final controller = ScribbleController();

  await tester.pumpWidget(MaterialApp(
    home: SimpleScribbleWidget(
      controller: controller,
      child: Container(),
    ),
  ));

  // Simulate drawing gesture
  await tester.tapAt(Offset(100, 100));
  await tester.drag(find.byType(SimpleScribbleWidget), Offset(50, 50));

  expect(controller.currentScribble.strokes.length, greaterThan(0));
});
```

## 🐛 Troubleshooting

### Common Issues

**Q: Drawing doesn't work with finger touch**
A: This is intentional. Set `allowedPointersMode: ScribblePointerMode.all` to enable touch drawing.

**Q: Drawing performance is slow**
A: Try reducing `maxScale` or adjusting `pressureFactor` and `speedFactor`.

**Q: Drawings disappear after rotation**
A: Ensure you're using auto-save or manual save/restore functionality.

**Q: InteractiveViewer conflicts with drawing**
A: The package handles this automatically. Make sure you're not wrapping in additional InteractiveViewer.

### Performance Tips

1. Use `RepaintBoundary` around static content
2. Enable auto-save with appropriate debouncing
3. Limit maximum zoom level for complex drawings
4. Use `SimpleScribbleWidget` for better performance

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/your-org/open_board.git
cd open_board
flutter pub get
flutter test
```

### Building Proto Files

```bash
# Generate protobuf files
protoc --dart_out=lib/src/data/model/protobuf/ res/proto/scribble.proto
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Flutter and Dart
- Uses Protocol Buffers for efficient data serialization
- Inspired by modern digital note-taking applications

## 📞 Support

- 📧 Email: support@openboard.dev
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/open_board/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-org/open_board/discussions)

---

Made with ❤️ by the Open Board team
