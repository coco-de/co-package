import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/internal/note_tool_options.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';

/// The tools and quick colours near the pen: what a Pencil squeeze shows.
/// Choosing a tool or colour closes it.
class NoteQuickPalette extends StatelessWidget {
  const NoteQuickPalette({
    required this.controller,
    required this.strings,
    required this.style,
    super.key,
  });

  /// The widest the card grows.
  static const double maxWidth = 360;

  /// Inks without a colour of their own.
  static const Set<String> _colourless = {
    NoteInkTypes.erase,
    NoteInkTypes.lasso,
    NoteInkTypes.image,
  };

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;

  @override
  Widget build(BuildContext context) {
    final tools = controller.tools;
    final current = tools.currentTool;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.panelColor,
        borderRadius: BorderRadius.circular(style.radius * 1.5),
        border: Border.all(color: style.dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _wrap([
              for (final (ink, label) in [
                (NoteInkTypes.pen, strings.pen),
                (NoteInkTypes.pencil, strings.pencil),
                (NoteInkTypes.marker, strings.marker),
                (NoteInkTypes.erase, strings.eraser),
                (NoteInkTypes.lasso, strings.lasso),
                (NoteInkTypes.shape, strings.shape),
              ])
                _button(ink, label, selected: current == ink, () {
                  tools.selectTool(ink);
                  controller.closePalette();
                }),
            ]),
            if (!_colourless.contains(current))
              _wrap([
                for (final (index, color)
                    in NoteToolOptions.quickColors.indexed)
                  _swatch(index, color),
              ]),
            _wrap([
              _button(
                'undo',
                strings.undo,
                controller.canUndo ? controller.undo : null,
              ),
              _button(
                'redo',
                strings.redo,
                controller.canRedo ? controller.redo : null,
              ),
              _button('close', strings.close, controller.closePalette),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _wrap(List<Widget> children) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: style.spacing,
    runSpacing: style.spacing,
    children: children,
  );

  Widget _button(
    String key,
    String label,
    VoidCallback? onPressed, {
    bool selected = false,
  }) => NoteEditorButton(
    key: ValueKey('note-palette-$key'),
    label: label,
    style: style,
    selected: selected,
    onPressed: onPressed,
  );

  /// The toolbar's quick colour [base]; the marker paints it half clear.
  Widget _swatch(int index, Color base) {
    final tools = controller.tools;
    final color = tools.currentTool == NoteInkTypes.marker
        ? base.withValues(alpha: 0.5)
        : base;

    return NoteEditorSwatch(
      key: ValueKey('note-palette-color-$index'),
      color: color,
      label: strings.colorName(base.toARGB32()),
      style: style,
      selected:
          (tools.color.toARGB32() & 0xFFFFFF) == (base.toARGB32() & 0xFFFFFF),
      onPressed: () {
        tools.setColor(color);
        controller.closePalette();
      },
    );
  }
}
