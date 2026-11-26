import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_slider.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/layer/note_layer.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';
import 'package:open_note/src/note/layer/note_layer_strings.dart';

/// Lists the layers of a [NoteLayerStack], top first, with show/hide, lock,
/// reorder, rename, duplicate, merge, delete and the active layer's opacity.
/// Every change goes through the stack, so it can be undone.
class NoteLayerPanel extends StatefulWidget {
  const NoteLayerPanel({
    required this.layers,
    super.key,
    this.strings = const NoteLayerStrings(),
    this.accentColor = const Color(0xFF2962FF),
    this.textStyle = const TextStyle(fontSize: 13, color: Color(0xFF212121)),
  });

  final NoteLayerStack layers;
  final NoteLayerStrings strings;
  final Color accentColor;
  final TextStyle textStyle;

  @override
  State<NoteLayerPanel> createState() => _NoteLayerPanelState();
}

class _NoteLayerPanelState extends State<NoteLayerPanel> {
  String? _renaming;

  /// Opacity before the current slider drag, so undo returns to it.
  double? _opacityBeforeDrag;

  NoteLayerStack get _stack => widget.layers;

  NoteLayerStrings get _strings => widget.strings;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _stack,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        for (final layer in _stack.layers.reversed) _row(layer),
        _footer(),
      ],
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _strings.title,
            style: widget.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _button(_strings.add, _stack.addLayer),
      ],
    ),
  );

  Widget _row(NoteLayer layer) {
    final isActive = layer.id == _stack.activeLayerId;
    final index = _stack.indexOf(layer.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _stack.setActive(layer.id),
      child: ColoredBox(
        key: ValueKey('note-layer-row-${layer.id}'),
        color: isActive
            ? widget.accentColor.withValues(alpha: 0.12)
            : const Color(0x00000000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              _button(
                layer.visible ? _strings.hide : _strings.show,
                () => _stack.setVisible(layer.id, !layer.visible),
              ),
              SizedBox(width: 120, child: _name(layer)),
              _button(
                layer.locked ? _strings.unlock : _strings.lock,
                () => _stack.setLocked(layer.id, !layer.locked),
              ),
              _button(
                _strings.moveUp,
                index < _stack.length - 1
                    ? () => _stack.moveLayer(layer.id, index + 1)
                    : null,
              ),
              _button(
                _strings.moveDown,
                index > 0 ? () => _stack.moveLayer(layer.id, index - 1) : null,
              ),
              _button(
                _strings.duplicate,
                () => _stack.duplicateLayer(layer.id),
              ),
              _button(
                _strings.mergeDown,
                index > 0 ? () => _stack.mergeDown(layer.id) : null,
              ),
              _button(
                _strings.delete,
                _stack.length > 1 ? () => _stack.removeLayer(layer.id) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _name(NoteLayer layer) {
    if (_renaming == layer.id) {
      return NoteTextField(
        initialText: layer.name,
        autofocus: true,
        submitOnBlur: true,
        onSubmitted: (name) {
          if (_renaming != layer.id) return;
          setState(() => _renaming = null);
          _stack.renameLayer(layer.id, name);
        },
      );
    }

    return Semantics(
      hint: _strings.rename,
      child: GestureDetector(
        onTap: () => _stack.setActive(layer.id),
        onDoubleTap: () => setState(() => _renaming = layer.id),
        child: Text(
          layer.name,
          overflow: TextOverflow.ellipsis,
          style: widget.textStyle,
        ),
      ),
    );
  }

  Widget _footer() {
    final active = _stack.activeLayer;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_strings.opacity} ${(active.opacity * 100).round()}%',
            style: widget.textStyle,
          ),
          NoteSlider(
            value: active.opacity,
            semanticLabel: _strings.opacity,
            activeColor: widget.accentColor,
            onChanged: (value) {
              _opacityBeforeDrag ??= active.opacity;
              _stack.previewOpacity(active.id, value);
            },
            onChangeEnd: (_) {
              final before = _opacityBeforeDrag;
              _opacityBeforeDrag = null;
              if (before == null) return;
              _stack.setOpacity(
                active.id,
                _stack.activeLayer.opacity,
                from: before,
              );
            },
          ),
          _button(
            _strings.mergeVisible,
            _stack.layers.where((layer) => layer.visible).length > 1
                ? _stack.mergeVisible
                : null,
          ),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback? onTap) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: widget.textStyle.copyWith(
            color: onTap == null ? const Color(0xFFBDBDBD) : widget.accentColor,
          ),
        ),
      ),
    ),
  );
}
