import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/internal/note_tools_color_dot.dart';
import 'package:open_note/src/note/tools/note_tool_preset.dart';
import 'package:open_note/src/note/tools/note_tool_preset_store.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// The pen favourites of a [NoteToolPresetStore]: a swatch with its width
/// label per preset, the selected one highlighted.
///
/// A tap selects the preset in the store and calls [onSelected], also when it
/// was already selected, so the host can apply it again after another tool (the
/// eraser, say) was used. A long press (or secondary click) calls
/// [onEditRequested]; without that callback a long press counts as a tap, as on
/// any button. The bar rebuilds itself when the store changes and scrolls along
/// [axis].
class NoteToolPresetBar extends StatelessWidget {
  /// Creates the bar.
  const NoteToolPresetBar({
    required this.store,
    super.key,
    this.onSelected,
    this.onEditRequested,
    this.axis = Axis.horizontal,
    this.itemExtent = 56,
    this.swatchSize = 32,
    this.strings = const NoteToolsStrings(),
    this.style = const NoteToolsStyle(),
  });

  /// Key of the item of the preset [id].
  static Key itemKey(String id) => ValueKey<String>('noteToolPreset.$id');

  /// The presets shown.
  final NoteToolPresetStore store;

  /// Called with the tapped preset.
  final ValueChanged<NoteToolPreset>? onSelected;

  /// Called with the long pressed preset, to edit it.
  final ValueChanged<NoteToolPreset>? onEditRequested;

  /// Direction of the bar.
  final Axis axis;

  /// Width of an item.
  final double itemExtent;

  /// Diameter of a swatch.
  final double swatchSize;

  /// Texts.
  final NoteToolsStrings strings;

  /// Colours and sizes.
  final NoteToolsStyle style;

  void _select(NoteToolPreset preset) {
    store.select(preset.id);
    onSelected?.call(preset);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final presets = store.presets;
      if (presets.isEmpty) {
        return Text(strings.noPresets, style: style.helpStyle);
      }

      return SingleChildScrollView(
        scrollDirection: axis,
        child: Flex(
          direction: axis,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final preset in presets)
              _PresetItem(
                key: itemKey(preset.id),
                preset: preset,
                selected: preset.id == store.activeId,
                extent: itemExtent,
                swatchSize: swatchSize,
                strings: strings,
                style: style,
                onTap: () => _select(preset),
                onEdit: onEditRequested == null
                    ? null
                    : () => onEditRequested!(preset),
              ),
          ],
        ),
      );
    },
  );
}

class _PresetItem extends StatelessWidget {
  const _PresetItem({
    required this.preset,
    required this.selected,
    required this.extent,
    required this.swatchSize,
    required this.strings,
    required this.style,
    required this.onTap,
    required this.onEdit,
    super.key,
  });

  final NoteToolPreset preset;
  final bool selected;
  final double extent;
  final double swatchSize;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final name = preset.name.isEmpty
        ? strings.inkName(preset.ink)
        : preset.name;

    return Semantics(
      button: true,
      selected: selected,
      label: strings.presetDescription(name, preset.widthLabel),
      hint: onEdit == null ? null : strings.presetEditHint,
      onTap: onTap,
      onLongPress: onEdit,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onEdit,
          onSecondaryTap: onEdit,
          child: SizedBox(
            width: extent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? style.accentColor.withValues(alpha: 0.12)
                    : null,
                borderRadius: BorderRadius.circular(style.cornerRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NoteToolsColorDot(
                      color: preset.color,
                      size: swatchSize,
                      borderColor: style.borderColor,
                      ringColor: style.accentColor,
                      selected: selected,
                    ),
                    Text(preset.widthLabel, style: style.valueStyle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
