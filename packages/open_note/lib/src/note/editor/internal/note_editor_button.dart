import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';

/// A text-labelled button of the editor, with an optional tooltip shown on
/// hover or long press.
class NoteEditorButton extends StatefulWidget {
  const NoteEditorButton({
    required this.label,
    required this.style,
    this.onPressed,
    this.selected = false,
    this.tooltip,
    this.semanticLabel,
    super.key,
  });

  final String label;

  /// Spoken instead of [label] (for symbol labels).
  final String? semanticLabel;
  final NoteEditorStyle style;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final bool selected;
  final String? tooltip;

  @override
  State<NoteEditorButton> createState() => _NoteEditorButtonState();
}

class _NoteEditorButtonState extends State<NoteEditorButton> {
  final OverlayPortalController _tooltip = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final enabled = widget.onPressed != null;
    final tooltip = widget.tooltip;
    final hasTooltip = tooltip != null && Overlay.maybeOf(context) != null;
    final button = Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel ?? widget.label,
      hint: tooltip,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: hasTooltip ? (_) => _tooltip.show() : null,
        onExit: hasTooltip ? (_) => _hide() : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onLongPress: hasTooltip ? _tooltip.show : null,
          onLongPressUp: hasTooltip ? _hide : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.selected
                  ? style.selectedColor
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(style.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                widget.label,
                maxLines: 1,
                softWrap: false,
                style: style.textStyle.copyWith(
                  color: !enabled
                      ? style.mutedColor
                      : widget.selected
                      ? style.accentColor
                      : style.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!hasTooltip) return button;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _tooltip,
        overlayChildBuilder: (context) => Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 4),
            showWhenUnlinked: false,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.tooltipColor,
                  borderRadius: BorderRadius.circular(style.radius / 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    tooltip,
                    textDirection: Directionality.of(this.context),
                    style: style.textStyle.copyWith(
                      color: style.tooltipTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: button,
      ),
    );
  }

  void _hide() {
    if (_tooltip.isShowing) _tooltip.hide();
  }
}

/// A round colour choice.
class NoteEditorSwatch extends StatelessWidget {
  const NoteEditorSwatch({
    required this.color,
    required this.label,
    required this.style,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final Color color;
  final String label;
  final NoteEditorStyle style;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? style.accentColor : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: style.dividerColor),
                ),
                child: SizedBox.square(dimension: style.swatchSize - 8),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A horizontal strip of controls that scrolls when it does not fit.
class NoteEditorStrip extends StatelessWidget {
  const NoteEditorStrip({
    required this.children,
    required this.style,
    this.axis = Axis.horizontal,
    super.key,
  });

  final List<Widget> children;
  final NoteEditorStyle style;
  final Axis axis;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: axis,
    padding: EdgeInsets.all(style.spacing),
    child: Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      spacing: style.spacing,
      children: children,
    ),
  );
}

/// A labelled slider of fixed width.
class NoteEditorLabelled extends StatelessWidget {
  const NoteEditorLabelled({
    required this.label,
    required this.child,
    required this.style,
    super.key,
  });

  final String label;
  final Widget child;
  final NoteEditorStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: style.spacing,
    children: [
      Text(label, style: style.textStyle),
      SizedBox(width: style.sliderWidth, child: child),
    ],
  );
}
