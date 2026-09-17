import 'package:flutter/material.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

/// 🛠️ 도구 버튼 커스텀 빌더
typedef ToolButtonBuilder =
    Widget Function(
      BuildContext context,
      DrawingTool tool,
      bool selected,
      VoidCallback onTap,
    );

/// 🎨 색상 스와치 커스텀 빌더
typedef ColorSwatchBuilder =
    Widget Function(
      BuildContext context,
      Color color,
      bool selected,
      VoidCallback onTap,
    );

/// 📏 두께 슬라이더 커스텀 빌더
typedef ThicknessBuilder =
    Widget Function(
      BuildContext context,
      double value,
      ValueChanged<double> onChanged,
    );

/// 🧩 패널 셸(컨테이너) 커스텀 빌더 — CoUI 등 외부 디자인 시스템 주입 지점
typedef PanelContainerBuilder =
    Widget Function(BuildContext context, Widget content);

/// ✨ ScribbleFloatingToolbar - 드래그 가능한 플로팅 필기 도구 패널
///
/// 한 화면에 여러 독립 [ScribbleWidget]이 있어도 **하나의 플로팅 도구**로
/// 모든 영역에 일관되게 필기할 수 있습니다. 내부적으로 [DrawingState] 싱글톤의
/// `selectedTool`/`selectedColor`/`selectedThickness`를 읽고 쓰기만 하며,
/// 전 영역 동기화는 [DrawingState]가 자동으로 처리합니다.
///
/// **외부 의존성 0** — `flutter/material.dart`와 라이브러리 내부 상태만 사용합니다.
/// CoUI 등 디자인 시스템 룩앤필이 필요하면 [containerBuilder]/[toolButtonBuilder]
/// 등 builder 파라미터로 주입하세요(라이브러리는 CoUI를 의존하지 않습니다).
///
/// **배치:** 부모 [Stack] 안에 `Positioned.fill`로 놓는 것을 전제합니다.
/// 위젯은 부모 영역 전체를 차지하지만 패널 바깥 영역의 터치는 아래로 통과합니다.
///
/// ```dart
/// Stack(
///   children: [
///     Row(children: [ScribbleWidget(...), ScribbleWidget(...)]),
///     const Positioned.fill(child: ScribbleFloatingToolbar()),
///   ],
/// )
/// ```
class ScribbleFloatingToolbar extends StatefulWidget {
  const ScribbleFloatingToolbar({
    super.key,
    this.state,
    this.tools = kDefaultToolbarTools,
    this.colors = kDefaultToolbarColors,
    this.minThickness = 0.5,
    this.maxThickness = 10.0,
    this.initialPosition = const Offset(16, 16),
    this.draggable = true,
    this.showUndoRedo = true,
    this.containerBuilder,
    this.toolButtonBuilder,
    this.colorSwatchBuilder,
    this.thicknessBuilder,
  });

  /// 연동할 전역 상태. 미지정 시 [DrawingState] 싱글톤 사용.
  final DrawingState? state;

  /// 패널에 노출할 도구 목록.
  final List<DrawingTool> tools;

  /// 색상 스와치 목록.
  final List<Color> colors;

  /// 두께 슬라이더 최소/최대값.
  final double minThickness;
  final double maxThickness;

  /// 최초 패널 위치(부모 좌상단 기준).
  final Offset initialPosition;

  /// 드래그 이동 허용 여부. CoUI 셸의 드래그에 위임할 땐 false 권장.
  final bool draggable;

  /// undo/redo/clear 컨트롤 노출 여부.
  final bool showUndoRedo;

  /// 패널 셸 커스텀(예: CoUI `CoDraggablePanel` 주입).
  final PanelContainerBuilder? containerBuilder;

  /// 도구 버튼 커스텀.
  final ToolButtonBuilder? toolButtonBuilder;

  /// 색상 스와치 커스텀.
  final ColorSwatchBuilder? colorSwatchBuilder;

  /// 두께 슬라이더 커스텀.
  final ThicknessBuilder? thicknessBuilder;

  @override
  State<ScribbleFloatingToolbar> createState() =>
      _ScribbleFloatingToolbarState();
}

class _ScribbleFloatingToolbarState extends State<ScribbleFloatingToolbar> {
  late Offset _offset = widget.initialPosition;

  DrawingState get _state => widget.state ?? DrawingState();

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      final next = _offset + details.delta;
      // 패널이 부모 영역을 완전히 벗어나지 않도록 clamp(여유 마진 48).
      const margin = 48.0;
      _offset = Offset(
        next.dx.clamp(0.0, (constraints.maxWidth - margin).clamp(0.0, double.infinity)),
        next.dy.clamp(0.0, (constraints.maxHeight - margin).clamp(0.0, double.infinity)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: _offset.dx,
              top: _offset.dy,
              child: _buildPanel(context, constraints),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel(BuildContext context, BoxConstraints constraints) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.draggable) _buildDragHandle(constraints),
        _buildToolRow(context),
        const SizedBox(height: 8),
        _buildColorRow(context),
        const SizedBox(height: 8),
        _buildThicknessRow(context),
        if (widget.showUndoRedo) ...[
          const SizedBox(height: 8),
          _buildUndoRedoRow(context),
        ],
      ],
    );

    if (widget.containerBuilder != null) {
      return widget.containerBuilder!(context, content);
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: content,
        ),
      ),
    );
  }

  Widget _buildDragHandle(BoxConstraints constraints) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => _onPanUpdate(d, constraints),
      child: const SizedBox(
        height: 24,
        child: Center(
          child: Icon(Icons.drag_handle, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildToolRow(BuildContext context) {
    return ValueListenableBuilder<DrawingTool>(
      valueListenable: _state.selectedTool,
      builder: (context, selectedTool, _) {
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: widget.tools.map((tool) {
            final selected = tool == selectedTool;
            void onTap() => _state.selectedTool.value = tool;
            if (widget.toolButtonBuilder != null) {
              return widget.toolButtonBuilder!(context, tool, selected, onTap);
            }
            return _DefaultToolButton(
              tool: tool,
              selected: selected,
              onTap: onTap,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildColorRow(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: _state.selectedColor,
      builder: (context, selectedColor, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.colors.map((color) {
            final selected = color.toARGB32() == selectedColor.toARGB32();
            void onTap() => _state.selectedColor.value = color;
            if (widget.colorSwatchBuilder != null) {
              return widget.colorSwatchBuilder!(context, color, selected, onTap);
            }
            return _DefaultColorSwatch(
              color: color,
              selected: selected,
              onTap: onTap,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildThicknessRow(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _state.selectedThickness,
      builder: (context, thickness, _) {
        final value = thickness.clamp(widget.minThickness, widget.maxThickness);
        void onChanged(double v) => _state.selectedThickness.value = v;
        if (widget.thicknessBuilder != null) {
          return widget.thicknessBuilder!(context, value, onChanged);
        }
        return Row(
          children: [
            const Icon(Icons.line_weight, size: 18),
            Expanded(
              child: Slider(
                min: widget.minThickness,
                max: widget.maxThickness,
                value: value,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUndoRedoRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _state.canUndoNotifier,
          builder: (context, canUndo, _) => IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? _state.undo : null,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _state.canRedoNotifier,
          builder: (context, canRedo, _) => IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: canRedo ? _state.redo : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Clear',
          onPressed: _state.clearActive,
        ),
      ],
    );
  }
}

class _DefaultToolButton extends StatelessWidget {
  const _DefaultToolButton({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final DrawingTool tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: drawingToolLabel(tool),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Icon(
            drawingToolIcon(tool),
            size: 20,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DefaultColorSwatch extends StatelessWidget {
  const _DefaultColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// 🎨 기본 도구 목록 (text/shape/lasso 등 전체 노출은 소비처에서 선택).
const List<DrawingTool> kDefaultToolbarTools = [
  DrawingTool.pen,
  DrawingTool.pencil,
  DrawingTool.marker,
  DrawingTool.highlighter,
  DrawingTool.fixedPen,
  DrawingTool.erase,
  DrawingTool.shape,
  DrawingTool.lasso,
  DrawingTool.text,
];

/// 🎨 기본 색상 팔레트.
const List<Color> kDefaultToolbarColors = [
  Colors.black,
  Colors.red,
  Colors.orange,
  Colors.green,
  Colors.blue,
  Colors.purple,
];

/// [DrawingTool] → 표시 아이콘 매핑 (highlighter 포함 전체 커버).
IconData drawingToolIcon(DrawingTool tool) {
  switch (tool) {
    case DrawingTool.pen:
      return Icons.edit;
    case DrawingTool.pencil:
      return Icons.create;
    case DrawingTool.marker:
      return Icons.highlight;
    case DrawingTool.highlighter:
      return Icons.brush;
    case DrawingTool.fixedPen:
      return Icons.precision_manufacturing;
    case DrawingTool.uniformPen:
      return Icons.border_color;
    case DrawingTool.erase:
      return Icons.auto_fix_normal;
    case DrawingTool.text:
      return Icons.text_fields;
    case DrawingTool.shape:
      return Icons.crop_square;
    case DrawingTool.lasso:
      return Icons.gesture;
    case DrawingTool.image:
      return Icons.image;
  }
}

/// [DrawingTool] → 표시 라벨 매핑.
String drawingToolLabel(DrawingTool tool) {
  switch (tool) {
    case DrawingTool.pen:
      return 'Pen';
    case DrawingTool.pencil:
      return 'Pencil';
    case DrawingTool.marker:
      return 'Marker';
    case DrawingTool.highlighter:
      return 'Highlighter';
    case DrawingTool.fixedPen:
      return 'Fixed';
    case DrawingTool.uniformPen:
      return 'Uniform';
    case DrawingTool.erase:
      return 'Eraser';
    case DrawingTool.text:
      return 'Text';
    case DrawingTool.shape:
      return 'Shape';
    case DrawingTool.lasso:
      return 'Lasso';
    case DrawingTool.image:
      return 'Image';
  }
}
