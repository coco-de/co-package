import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_tools_button.dart';
import 'package:open_note/src/note/tools/internal/note_tools_numbers.dart';
import 'package:open_note/src/note/tools/internal/note_tools_slider_row.dart';
import 'package:open_note/src/note/tools/internal/note_tools_switch.dart';
import 'package:open_note/src/note/tools/note_eraser_mode.dart';
import 'package:open_note/src/note/tools/note_eraser_settings.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// Eraser type, size (with a preview circle), the pressure switch and its
/// threshold (inactive while the switch is off).
///
/// [onChanged] fires with every change; [onChangeEnd] once a slider is
/// released and right after a button or switch change. Like the pen settings
/// sheet it keeps its own copy and takes [settings] over again whenever that
/// property changes. It scrolls when it does not fit.
class NoteEraserSettingsPanel extends StatefulWidget {
  /// Creates the panel.
  const NoteEraserSettingsPanel({
    required this.settings,
    required this.onChanged,
    super.key,
    this.onChangeEnd,
    this.strings = const NoteToolsStrings(),
    this.style = const NoteToolsStyle(),
  });

  /// Key of the stroke eraser button.
  static const Key strokeModeKey = ValueKey<String>('noteEraser.mode.stroke');

  /// Key of the pixel eraser button.
  static const Key pixelModeKey = ValueKey<String>('noteEraser.mode.pixel');

  /// Key of the size row.
  static const Key sizeKey = ValueKey<String>('noteEraser.size');

  /// Key of the size preview circle.
  static const Key previewKey = ValueKey<String>('noteEraser.preview');

  /// Key of the pressure switch.
  static const Key pressureSwitchKey = ValueKey<String>(
    'noteEraser.pressureSwitch',
  );

  /// Key of the pressure threshold row.
  static const Key thresholdKey = ValueKey<String>('noteEraser.threshold');

  /// The settings to show.
  final NoteEraserSettings settings;

  /// Called with every change.
  final ValueChanged<NoteEraserSettings> onChanged;

  /// Called when a change is complete.
  final ValueChanged<NoteEraserSettings>? onChangeEnd;

  /// Texts.
  final NoteToolsStrings strings;

  /// Colours and sizes.
  final NoteToolsStyle style;

  @override
  State<NoteEraserSettingsPanel> createState() =>
      _NoteEraserSettingsPanelState();
}

class _NoteEraserSettingsPanelState extends State<NoteEraserSettingsPanel> {
  late NoteEraserSettings _settings = widget.settings;

  void _apply(NoteEraserSettings next, {bool complete = false}) {
    if (next == _settings) return;
    setState(() => _settings = next);
    widget.onChanged(next);
    if (complete) _finish();
  }

  void _finish() => widget.onChangeEnd?.call(_settings);

  @override
  void didUpdateWidget(NoteEraserSettingsPanel oldWidget) {
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
          _ModeSelector(
            mode: _settings.mode,
            strings: strings,
            style: style,
            onSelected: (mode) =>
                _apply(_settings.copyWith(mode: mode), complete: true),
          ),
          gap,
          NoteToolsSliderRow(
            key: NoteEraserSettingsPanel.sizeKey,
            label: strings.eraserSize,
            valueText: noteTrimNumber(_settings.size),
            style: style,
            slider: NoteSlider(
              value: _settings.size,
              min: NoteEraserSettings.minSize,
              max: NoteEraserSettings.maxSize,
              divisions:
                  (NoteEraserSettings.maxSize - NoteEraserSettings.minSize)
                      .round(),
              semanticLabel: strings.eraserSize,
              activeColor: style.accentColor,
              inactiveColor: style.borderColor,
              onChanged: (size) => _apply(_settings.copyWith(size: size)),
              onChangeEnd: (_) => _finish(),
            ),
          ),
          _SizePreview(size: _settings.size, style: style),
          gap,
          _PressureSwitchRow(
            value: _settings.pressureSwitchEnabled,
            strings: strings,
            style: style,
            onChanged: (value) => _apply(
              _settings.copyWith(pressureSwitchEnabled: value),
              complete: true,
            ),
          ),
          gap,
          _ThresholdRow(
            key: NoteEraserSettingsPanel.thresholdKey,
            settings: _settings,
            strings: strings,
            style: style,
            onChanged: (threshold) =>
                _apply(_settings.copyWith(pressureThreshold: threshold)),
            onChangeEnd: _finish,
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.strings,
    required this.style,
    required this.onSelected,
  });

  final NoteEraserMode mode;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final ValueChanged<NoteEraserMode> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: strings.eraserMode,
    child: Row(
      children: [
        Expanded(
          child: NoteToolsButton(
            key: NoteEraserSettingsPanel.strokeModeKey,
            label: strings.strokeEraser,
            selected: mode == NoteEraserMode.stroke,
            onPressed: () => onSelected(NoteEraserMode.stroke),
            style: style,
          ),
        ),
        SizedBox(width: style.spacing / 2),
        Expanded(
          child: NoteToolsButton(
            key: NoteEraserSettingsPanel.pixelModeKey,
            label: strings.pixelEraser,
            selected: mode == NoteEraserMode.pixel,
            onPressed: () => onSelected(NoteEraserMode.pixel),
            style: style,
          ),
        ),
      ],
    ),
  );
}

class _SizePreview extends StatelessWidget {
  const _SizePreview({required this.size, required this.style});

  final double size;
  final NoteToolsStyle style;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: NoteEraserSettings.maxSize,
    child: Center(
      child: SizedBox.square(
        key: NoteEraserSettingsPanel.previewKey,
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.surfaceColor,
            border: Border.all(color: style.mutedTextColor),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

class _PressureSwitchRow extends StatelessWidget {
  const _PressureSwitchRow({
    required this.value,
    required this.strings,
    required this.style,
    required this.onChanged,
  });

  final bool value;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(strings.pressureSwitch, style: style.labelStyle)),
      NoteToolsSwitch(
        key: NoteEraserSettingsPanel.pressureSwitchKey,
        value: value,
        semanticLabel: strings.pressureSwitch,
        semanticValue: value ? strings.switchOn : strings.switchOff,
        onChanged: onChanged,
        style: style,
      ),
    ],
  );
}

class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({
    required this.settings,
    required this.strings,
    required this.style,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  static const _divisions = 90;

  final NoteEraserSettings settings;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.pressureSwitchEnabled;

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: NoteToolsSliderRow(
          label: strings.pressureThreshold,
          valueText: strings.percent(
            (settings.pressureThreshold * 100).round(),
          ),
          style: style,
          slider: NoteSlider(
            value: settings.pressureThreshold,
            min: NoteEraserSettings.minPressureThreshold,
            max: NoteEraserSettings.maxPressureThreshold,
            divisions: _divisions,
            semanticLabel: strings.pressureThreshold,
            activeColor: style.accentColor,
            inactiveColor: style.borderColor,
            onChanged: onChanged,
            onChangeEnd: (_) => onChangeEnd(),
          ),
        ),
      ),
    );
  }
}
