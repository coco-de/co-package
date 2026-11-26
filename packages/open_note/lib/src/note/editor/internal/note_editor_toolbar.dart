import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_mode.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_toolbar_item_ids.dart';
import 'package:open_note/src/note/tools/note_toolbar_layout.dart';

/// The tool bar: the visible items of a [NoteToolbarLayout], in order.
class NoteEditorToolbar extends StatelessWidget {
  const NoteEditorToolbar({
    required this.controller,
    required this.layout,
    required this.strings,
    required this.style,
    required this.axis,
    required this.onToggleLayers,
    required this.onTogglePresets,
    this.layersShown = false,
    this.presetsShown = false,
    super.key,
  });

  static const Map<String, String> _tools = {
    NoteToolbarItemIds.pen: NoteInkTypes.pen,
    NoteToolbarItemIds.pencil: NoteInkTypes.pencil,
    NoteToolbarItemIds.marker: NoteInkTypes.marker,
    NoteToolbarItemIds.eraser: NoteInkTypes.erase,
    NoteToolbarItemIds.lasso: NoteInkTypes.lasso,
    NoteToolbarItemIds.shape: NoteInkTypes.shape,
    NoteToolbarItemIds.text: NoteInkTypes.text,
    NoteToolbarItemIds.image: NoteInkTypes.image,
  };

  final NoteEditorController controller;
  final NoteToolbarLayout layout;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final Axis axis;
  final VoidCallback onToggleLayers;
  final VoidCallback onTogglePresets;
  final bool layersShown;
  final bool presetsShown;

  @override
  Widget build(BuildContext context) => NoteEditorStrip(
    style: style,
    axis: axis,
    children: [
      for (final item in layout.visibleItems)
        if (_button(item.id) case final Widget button) button,
    ],
  );

  Widget? _button(String id) {
    final ink = _tools[id];
    if (ink != null) {
      return NoteEditorButton(
        key: ValueKey('note-tool-$id'),
        label: labelOf(id, strings),
        style: style,
        selected:
            controller.mode == NoteEditorMode.draw &&
            controller.tools.currentTool == ink,
        onPressed: () => controller.selectTool(ink),
      );
    }

    return switch (id) {
      NoteToolbarItemIds.undo => NoteEditorButton(
        key: const ValueKey('note-tool-undo'),
        label: strings.undo,
        style: style,
        onPressed: controller.canUndo ? controller.undo : null,
      ),
      NoteToolbarItemIds.redo => NoteEditorButton(
        key: const ValueKey('note-tool-redo'),
        label: strings.redo,
        style: style,
        onPressed: controller.canRedo ? controller.redo : null,
      ),
      NoteToolbarItemIds.layers => NoteEditorButton(
        key: const ValueKey('note-tool-layers'),
        label: strings.layersPanel,
        style: style,
        selected: layersShown,
        onPressed: onToggleLayers,
      ),
      NoteToolbarItemIds.presets => NoteEditorButton(
        key: const ValueKey('note-tool-presets'),
        label: strings.presets,
        style: style,
        selected: presetsShown,
        onPressed: onTogglePresets,
      ),
      _ => null,
    };
  }

  /// The label of a toolbar item.
  static String labelOf(String id, NoteEditorStrings strings) => switch (id) {
    NoteToolbarItemIds.pen => strings.pen,
    NoteToolbarItemIds.pencil => strings.pencil,
    NoteToolbarItemIds.marker => strings.marker,
    NoteToolbarItemIds.eraser => strings.eraser,
    NoteToolbarItemIds.lasso => strings.lasso,
    NoteToolbarItemIds.shape => strings.shape,
    NoteToolbarItemIds.text => strings.text,
    NoteToolbarItemIds.image => strings.image,
    NoteToolbarItemIds.undo => strings.undo,
    NoteToolbarItemIds.redo => strings.redo,
    NoteToolbarItemIds.layers => strings.layersPanel,
    NoteToolbarItemIds.presets => strings.presets,
    _ => id,
  };
}
