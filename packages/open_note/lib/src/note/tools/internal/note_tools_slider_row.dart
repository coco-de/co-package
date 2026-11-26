// Internal to the tools module; not exported from the barrel.

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// A slider under its label and live value, with an optional button after the
/// value and an optional text below.
class NoteToolsSliderRow extends StatelessWidget {
  /// Creates a row.
  const NoteToolsSliderRow({
    required this.label,
    required this.valueText,
    required this.slider,
    required this.style,
    super.key,
    this.trailing,
    this.footer,
  });

  /// Name of the setting.
  final String label;

  /// Current value as text.
  final String valueText;

  /// The slider.
  final Widget slider;

  /// Colours and sizes.
  final NoteToolsStyle style;

  /// Widget after the value.
  final Widget? trailing;

  /// Text below the slider.
  final String? footer;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: style.labelStyle)),
          Text(valueText, style: style.valueStyle),
          if (trailing != null) ...[
            SizedBox(width: style.spacing / 2),
            trailing!,
          ],
        ],
      ),
      slider,
      if (footer != null) Text(footer!, style: style.helpStyle),
    ],
  );
}
