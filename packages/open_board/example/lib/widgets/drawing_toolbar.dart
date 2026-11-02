import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';
import 'package:open_board_example/i18n/strings.g.dart';

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
    required this.selectedTool,
    required this.selectedColor,
    required this.selectedWidth,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onWidthChanged,
    this.tools = defaultTools,
    this.colors = defaultColors,
    super.key,
  });

  /// Custom swatches use lossless CSS hex notation, including alpha when set.
  String _hexLabel(Color color) {
    final argb = color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    final rgb = argb.substring(2);
    return argb.startsWith('FF') ? '#$rgb' : '#$rgb${argb.substring(0, 2)}';
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: cs.surfaceContainerLow,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final t = context.t.toolbar;
              final names = <Color, String>{
                Colors.black: t.colors.black,
                Colors.red: t.colors.red,
                Colors.orange: t.colors.orange,
                Colors.green: t.colors.green,
                Colors.blue: t.colors.blue,
                Colors.purple: t.colors.purple,
              };
              final palette = Wrap(
                children: [
                  for (final (index, c) in colors.indexed)
                    Semantics(
                      selected: selectedColor == c,
                      child: IconButton(
                        key: ValueKey('drawing-color-$index'),
                        tooltip: '${t.color}: ${names[c] ?? _hexLabel(c)}',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => onColorSelected(c),
                        icon: Container(
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
                          child: selectedColor == c
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color:
                                      ThemeData.estimateBrightnessForColor(
                                            Color.alphaBlend(
                                              c,
                                              cs.surfaceContainerLow,
                                            ),
                                          ) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              );
              final width = Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: t.width,
                      child: Slider(
                        key: const ValueKey('drawing-stroke-width'),
                        value: selectedWidth.clamp(0.5, 10.0),
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label: selectedWidth.toStringAsFixed(1),
                        onChanged: onWidthChanged,
                      ),
                    ),
                  ),
                  Text(
                    selectedWidth.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
              return constraints.maxWidth < 600
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [palette, width],
                    )
                  : Row(
                      children: [
                        Flexible(child: palette),
                        const SizedBox(width: 12),
                        Expanded(child: width),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }
}
