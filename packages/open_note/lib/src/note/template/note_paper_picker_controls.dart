import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_slider.dart';
import 'package:open_note/src/note/template/note_paper_picker_style.dart';
import 'package:open_note/src/note/template/note_paper_strings.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// The spacing and line width sliders of the paper picker. Internal: not
/// exported by the module barrel.
class NotePaperPickerControls extends StatelessWidget {
  const NotePaperPickerControls({
    required this.template,
    required this.strings,
    required this.style,
    required this.showLineSpacing,
    required this.showLineWidth,
    required this.onChanged,
    super.key,
  });

  /// Step of the spacing slider (page units).
  static const double spacingStep = 1;

  /// Step of the line width slider (page units).
  static const double widthStep = 0.05;

  /// The paper being adjusted.
  final NotePaperTemplate template;

  /// Labels and units.
  final NotePaperStrings strings;

  /// Colours and sizes.
  final NotePaperPickerStyle style;

  /// Whether the spacing slider is shown.
  final bool showLineSpacing;

  /// Whether the line width slider is shown.
  final bool showLineWidth;

  /// Receives the adjusted paper.
  final ValueChanged<NotePaperTemplate> onChanged;

  static int _divisions(double min, double max, double step) =>
      ((max - min) / step).round();

  @override
  Widget build(BuildContext context) => Padding(
    padding: style.padding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLineSpacing)
          _NotePaperSliderRow(
            key: const ValueKey('note-paper-line-spacing'),
            title: strings.lineSpacing,
            valueText: strings.formatLength(template.lineSpacing),
            labelStyle: style.controlLabelStyle,
            slider: NoteSlider(
              value: template.lineSpacing,
              min: NotePaperTemplate.minLineSpacing,
              max: NotePaperTemplate.maxLineSpacing,
              divisions: _divisions(
                NotePaperTemplate.minLineSpacing,
                NotePaperTemplate.maxLineSpacing,
                spacingStep,
              ),
              activeColor: style.selectedColor,
              semanticLabel: strings.lineSpacing,
              onChanged: (value) =>
                  onChanged(template.copyWith(lineSpacing: value)),
            ),
          ),
        if (showLineWidth)
          _NotePaperSliderRow(
            key: const ValueKey('note-paper-line-width'),
            title: strings.lineWidth,
            valueText: strings.formatLength(template.lineWidth),
            labelStyle: style.controlLabelStyle,
            slider: NoteSlider(
              value: template.lineWidth,
              min: NotePaperTemplate.minLineWidth,
              max: NotePaperTemplate.maxLineWidth,
              divisions: _divisions(
                NotePaperTemplate.minLineWidth,
                NotePaperTemplate.maxLineWidth,
                widthStep,
              ),
              activeColor: style.selectedColor,
              semanticLabel: strings.lineWidth,
              onChanged: (value) =>
                  onChanged(template.copyWith(lineWidth: value)),
            ),
          ),
      ],
    ),
  );
}

class _NotePaperSliderRow extends StatelessWidget {
  const _NotePaperSliderRow({
    required this.title,
    required this.valueText,
    required this.labelStyle,
    required this.slider,
    super.key,
  });

  final String title;
  final String valueText;
  final TextStyle labelStyle;
  final Widget slider;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: labelStyle)),
          Text(valueText, style: labelStyle),
        ],
      ),
      slider,
    ],
  );
}
