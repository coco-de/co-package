import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';

/// 보드/EPUB 데모에서 공용으로 사용하는 필기 도구 툴바.
///
/// 도구 칩 한 줄 + 색상·두께 슬라이더 한 줄의 2단 구성으로,
/// 두 데모가 동일한 도구 UI를 갖도록 통일한다. 도구 이름은 패키지 문구
/// 묶음([OpenBoardStringsScope])에서 읽어 앱 언어를 따른다.
class DrawingToolbar extends StatelessWidget {
  static const defaultTools = <(DrawingTool, IconData)>[
    (DrawingTool.pen, Icons.edit),
    (DrawingTool.pencil, Icons.create),
    (DrawingTool.marker, Icons.highlight),
    (DrawingTool.fixedPen, Icons.precision_manufacturing),
    (DrawingTool.erase, Icons.auto_fix_normal),
    (DrawingTool.shape, Icons.crop_square),
    (DrawingTool.lasso, Icons.gesture),
    (DrawingTool.text, Icons.text_fields),
  ];

  static const defaultColors = <Color>[
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  final List<(DrawingTool, IconData)> tools;
  final List<Color> colors;
  final DrawingTool selectedTool;
  final Color selectedColor;
  final double selectedWidth;
  final ValueChanged<DrawingTool> onToolSelected;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onWidthChanged;

  const DrawingToolbar({
    super.key,
    required this.selectedTool,
    required this.selectedColor,
    required this.selectedWidth,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onWidthChanged,
    this.tools = defaultTools,
    this.colors = defaultColors,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = OpenBoardStringsScope.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // === Tool Selection ===
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: cs.surfaceContainerLow,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (tool, icon) in tools)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FilterChip(
                      avatar: Icon(icon, size: 18),
                      label: Text(strings.toolLabel(tool)),
                      selected: selectedTool == tool,
                      onSelected: (_) => onToolSelected(tool),
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
              for (final c in colors)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => onColorSelected(c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == c
                              ? cs.primary
                              : cs.outlineVariant,
                          width: selectedColor == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: selectedWidth.clamp(0.5, 10.0),
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  onChanged: onWidthChanged,
                ),
              ),
              Text(selectedWidth.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
