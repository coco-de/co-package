// Internal to the tools module; not exported from the barrel.

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// A plain text button: filled with the accent colour when [selected],
/// dimmed and inert when [onPressed] is `null`.
class NoteToolsButton extends StatelessWidget {
  /// Creates a button.
  const NoteToolsButton({
    required this.label,
    required this.onPressed,
    required this.style,
    super.key,
    this.selected = false,
    this.semanticLabel,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.circular = false,
  });

  /// Visible text.
  final String label;

  /// Called on tap; `null` disables the button.
  final VoidCallback? onPressed;

  /// Colours.
  final NoteToolsStyle style;

  /// Whether the button shows as chosen.
  final bool selected;

  /// Accessibility label, [label] when `null`.
  final String? semanticLabel;

  /// Accessibility tooltip.
  final String? tooltip;

  /// Space around the text.
  final EdgeInsetsGeometry padding;

  /// Whether the button is a circle (for one-character buttons).
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = selected ? style.onAccentColor : style.textColor;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel ?? label,
      tooltip: tooltip,
      onTap: onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? style.accentColor : style.surfaceColor,
                border: Border.all(
                  color: selected ? style.accentColor : style.borderColor,
                ),
                shape: circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circular
                    ? null
                    : BorderRadius.circular(style.cornerRadius),
              ),
              child: Padding(
                padding: padding,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: style.labelStyle.copyWith(color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
