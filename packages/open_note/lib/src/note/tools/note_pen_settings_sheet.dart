import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_tools_button.dart';
import 'package:open_note/src/note/tools/internal/note_tools_slider_row.dart';
import 'package:open_note/src/note/tools/note_pen_settings.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// The three pen sliders (motion smoothing 0–10, stabilization and pressure
/// sensitivity in percent) with live values and a `?` button showing each
/// one's help text.
///
/// [onChanged] fires while a slider moves and [onChangeEnd] once the gesture
/// ends (the moment to save). The sheet keeps its own copy, so it also works in
/// a route that is not rebuilt, and takes [settings] over again whenever that
/// property changes. It scrolls when it does not fit.
class NotePenSettingsSheet extends StatefulWidget {
  /// Creates the sheet.
  const NotePenSettingsSheet({
    required this.settings,
    required this.onChanged,
    super.key,
    this.onChangeEnd,
    this.strings = const NoteToolsStrings(),
    this.style = const NoteToolsStyle(),
  });

  /// Key of the motion smoothing row.
  static const Key motionSmoothingKey = ValueKey<String>(
    'notePenSettings.motionSmoothing',
  );

  /// Key of the stabilization row.
  static const Key stabilizationKey = ValueKey<String>(
    'notePenSettings.stabilization',
  );

  /// Key of the pressure sensitivity row.
  static const Key pressureSensitivityKey = ValueKey<String>(
    'notePenSettings.pressureSensitivity',
  );

  /// The settings to show.
  final NotePenSettings settings;

  /// Called with every change.
  final ValueChanged<NotePenSettings> onChanged;

  /// Called when a slider is released.
  final ValueChanged<NotePenSettings>? onChangeEnd;

  /// Texts.
  final NoteToolsStrings strings;

  /// Colours and sizes.
  final NoteToolsStyle style;

  @override
  State<NotePenSettingsSheet> createState() => _NotePenSettingsSheetState();
}

class _NotePenSettingsSheetState extends State<NotePenSettingsSheet> {
  late NotePenSettings _settings = widget.settings;
  final Set<Key> _openHelp = {};

  void _apply(NotePenSettings next) {
    if (next == _settings) return;
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  void _finish() => widget.onChangeEnd?.call(_settings);

  void _toggleHelp(Key row) => setState(() {
    if (!_openHelp.remove(row)) _openHelp.add(row);
  });

  @override
  void didUpdateWidget(NotePenSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final style = widget.style;
    final gap = SizedBox(height: style.spacing);

    return SingleChildScrollView(
      padding: EdgeInsets.all(style.spacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PenRow(
            key: NotePenSettingsSheet.motionSmoothingKey,
            label: strings.motionSmoothing,
            help: strings.motionSmoothingHelp,
            valueText: '${_settings.motionSmoothing}',
            value: _settings.motionSmoothing.toDouble(),
            max: NotePenSettings.maxMotionSmoothing.toDouble(),
            divisions: NotePenSettings.maxMotionSmoothing,
            onValue: (value) =>
                _apply(_settings.copyWith(motionSmoothing: value.round())),
            onEnd: _finish,
            showHelp: _openHelp.contains(
              NotePenSettingsSheet.motionSmoothingKey,
            ),
            onHelp: () => _toggleHelp(NotePenSettingsSheet.motionSmoothingKey),
            strings: strings,
            style: style,
          ),
          gap,
          _PenRow(
            key: NotePenSettingsSheet.stabilizationKey,
            label: strings.stabilization,
            help: strings.stabilizationHelp,
            valueText: strings.percent((_settings.stabilization * 100).round()),
            value: _settings.stabilization,
            onValue: (value) =>
                _apply(_settings.copyWith(stabilization: value)),
            onEnd: _finish,
            showHelp: _openHelp.contains(NotePenSettingsSheet.stabilizationKey),
            onHelp: () => _toggleHelp(NotePenSettingsSheet.stabilizationKey),
            strings: strings,
            style: style,
          ),
          gap,
          _PenRow(
            key: NotePenSettingsSheet.pressureSensitivityKey,
            label: strings.pressureSensitivity,
            help: strings.pressureSensitivityHelp,
            valueText: strings.percent(
              (_settings.pressureSensitivity * 100).round(),
            ),
            value: _settings.pressureSensitivity,
            onValue: (value) =>
                _apply(_settings.copyWith(pressureSensitivity: value)),
            onEnd: _finish,
            showHelp: _openHelp.contains(
              NotePenSettingsSheet.pressureSensitivityKey,
            ),
            onHelp: () =>
                _toggleHelp(NotePenSettingsSheet.pressureSensitivityKey),
            strings: strings,
            style: style,
          ),
        ],
      ),
    );
  }
}

class _PenRow extends StatelessWidget {
  const _PenRow({
    required this.label,
    required this.help,
    required this.valueText,
    required this.value,
    required this.onValue,
    required this.onEnd,
    required this.showHelp,
    required this.onHelp,
    required this.strings,
    required this.style,
    super.key,
    this.max = 1,
    this.divisions = 100,
  });

  final String label;
  final String help;
  final String valueText;
  final double value;
  final double max;
  final int divisions;
  final ValueChanged<double> onValue;
  final VoidCallback onEnd;
  final bool showHelp;
  final VoidCallback onHelp;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;

  @override
  Widget build(BuildContext context) => NoteToolsSliderRow(
    label: label,
    valueText: valueText,
    style: style,
    trailing: NoteToolsButton(
      label: strings.helpGlyph,
      semanticLabel: strings.helpLabel(label),
      tooltip: help,
      selected: showHelp,
      circular: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onPressed: onHelp,
      style: style,
    ),
    footer: showHelp ? help : null,
    slider: NoteSlider(
      value: value,
      max: max,
      divisions: divisions,
      semanticLabel: label,
      activeColor: style.accentColor,
      inactiveColor: style.borderColor,
      onChanged: onValue,
      onChangeEnd: (_) => onEnd(),
    ),
  );
}
