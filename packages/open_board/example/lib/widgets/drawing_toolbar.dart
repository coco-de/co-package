import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart' as co;
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
                    child: Semantics(
                      selected: selectedTool == tool,
                      child: co.Button(
                        size: co.CoreComponentSize.sm,
                        variant: selectedTool == tool
                            ? co.CoreButtonVariant.primary
                            : co.CoreButtonVariant.ghost,
                        leading: Icon(icon, size: 18),
                        onPressed: () => onToolSelected(tool),
                        child: Text(strings.toolLabel(tool)),
                      ),
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
          child: LayoutBuilder(builder: (context, constraints) {
            final palette = Wrap(
              children: [
                for (final c in colors)
                  Semantics(
                    selected: selectedColor == c,
                    child: IconButton(
                      tooltip: '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                      onPressed: () => onColorSelected(c),
                      icon: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: selectedColor == c ? cs.primary : cs.outlineVariant, width: selectedColor == c ? 3 : 1),
                        ),
                        child: selectedColor == c ? Icon(Icons.check, size: 16, color: c.computeLuminance() > .4 ? Colors.black : Colors.white) : null,
                      ),
                    ),
                  ),
              ],
            );
            final widthControl = Row(children: [
              Expanded(
                child: Slider(
                  value: selectedWidth.clamp(0.5, 10.0),
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  label: '${selectedWidth.toStringAsFixed(1)} px',
                  onChanged: onWidthChanged,
                ),
              ),
              SizedBox(width: 48, child: Text('${selectedWidth.toStringAsFixed(1)} px', style: Theme.of(context).textTheme.bodySmall)),
            ]);
            return constraints.maxWidth < 520
                ? Column(mainAxisSize: MainAxisSize.min, children: [palette, widthControl])
                : Row(children: [palette, const SizedBox(width: 16), Expanded(child: widthControl)]);
          }),
        ),
      ],
    );
  }
}
