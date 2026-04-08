import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';

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
      home: const DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late final ScribbleController _controller;
  String _currentTool = ScribbleTool.pen;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;

  static const _tools = [
    (ScribbleTool.pen, Icons.edit, 'Pen'),
    (ScribbleTool.pencil, Icons.create, 'Pencil'),
    (ScribbleTool.marker, Icons.highlight, 'Marker'),
    (ScribbleTool.fixedPen, Icons.brush, 'Fixed Pen'),
    (ScribbleTool.eraser, Icons.auto_fix_normal, 'Eraser'),
    (ScribbleTool.shape, Icons.crop_square, 'Shape'),
    (ScribbleTool.text, Icons.text_fields, 'Text'),
    (ScribbleTool.lasso, Icons.select_all, 'Lasso'),
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
    _controller = ScribbleController(
      initialTool: ScribbleTool.pen,
      initialColor: Colors.black,
      initialStrokeWidth: 2.0,
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _selectTool(String tool) {
    setState(() => _currentTool = tool);
    _controller.setTool(tool);
  }

  void _selectColor(Color color) {
    setState(() => _currentColor = color);
    _controller.modeNotifier.setColor(color);
  }

  void _setStrokeWidth(double width) {
    setState(() => _currentStrokeWidth = width);
    _controller.modeNotifier.setStrokeWidth(width);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Board Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _controller.canUndo ? _controller.undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),
          IconButton(
            onPressed: _controller.canRedo ? _controller.redo : null,
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
          ),
          IconButton(
            onPressed: () => _controller.clear(),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tool bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (tool, icon, label) in _tools)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: label,
                        child: FilterChip(
                          avatar: Icon(icon, size: 18),
                          label: Text(label),
                          selected: _currentTool == tool,
                          onSelected: (_) => _selectTool(tool),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Color & stroke width bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                for (final color in _colors)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _selectColor(color),
                      child: Container(
                        width: 28,
                        height: 28,
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
                const SizedBox(width: 16),
                const Icon(Icons.line_weight, size: 18),
                Expanded(
                  child: Slider(
                    value: _currentStrokeWidth,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    label: _currentStrokeWidth.toStringAsFixed(1),
                    onChanged: _setStrokeWidth,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _currentStrokeWidth.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SimpleScribbleWidget(
                  controller: _controller,
                  allowedPointersMode: ScribblePointerMode.all,
                  maxScale: 6.0,
                  panDirection: PanDirection.both,
                  contentLogicalSize: Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                  child: Container(color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
