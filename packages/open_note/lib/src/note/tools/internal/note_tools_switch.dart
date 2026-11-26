// Internal to the tools module; not exported from the barrel.

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// A plain on/off switch.
class NoteToolsSwitch extends StatelessWidget {
  /// Creates a switch.
  const NoteToolsSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    required this.semanticValue,
    required this.style,
    super.key,
  });

  static const _duration = Duration(milliseconds: 150);

  /// Whether the switch is on.
  final bool value;

  /// Called with the new state on tap.
  final ValueChanged<bool> onChanged;

  /// Accessibility label.
  final String semanticLabel;

  /// Accessibility value, such as "On".
  final String semanticValue;

  /// Colours.
  final NoteToolsStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: semanticLabel,
    value: semanticValue,
    onTap: () => onChanged(!value),
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: _duration,
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? style.accentColor : style.borderColor,
            borderRadius: const BorderRadius.all(Radius.circular(13)),
          ),
          child: const SizedBox.square(
            dimension: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
