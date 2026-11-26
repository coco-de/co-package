import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_hue_strip_painter.dart';
import 'package:open_note/src/note/tools/internal/note_saturation_value_painter.dart';
import 'package:open_note/src/note/tools/internal/note_tools_button.dart';
import 'package:open_note/src/note/tools/internal/note_tools_color_dot.dart';
import 'package:open_note/src/note/tools/internal/note_tools_drag_area.dart';
import 'package:open_note/src/note/tools/note_color_utils.dart';
import 'package:open_note/src/note/tools/note_hsv.dart';
import 'package:open_note/src/note/tools/note_tools_strings.dart';
import 'package:open_note/src/note/tools/note_tools_style.dart';

/// A colour picker: saturation/brightness plane, hue strip, hex field, an
/// optional eyedropper and swatches.
///
/// [onChanged] fires while the user changes the colour and [onChangeEnd] once
/// when a drag ends or a swatch, hex text or eyedropper result is applied (a
/// good moment to remember a recent colour). Neither fires without a real
/// change, except [onChangeEnd] after a drag.
///
/// The opacity is kept by the plane, the strip and by `#RRGGBB` input;
/// `#AARRGGBB` input, swatches and the eyedropper set their own. The hue (and
/// for black the saturation) survives greys while the picker is open. The
/// shown colour follows [color] whenever that property changes. The hex field
/// is applied when submitted or when it loses focus; unreadable text is
/// replaced by the current colour.
///
/// It needs a bounded width (280 is used otherwise) and an `Overlay` and
/// `MediaQuery` above it, as any app provides.
class NoteColorPicker extends StatefulWidget {
  /// Creates a picker showing [color].
  const NoteColorPicker({
    required this.color,
    required this.onChanged,
    super.key,
    this.onChangeEnd,
    this.onEyedropper,
    this.swatches = defaultSwatches,
    this.planeHeight = 160,
    this.hueStripHeight = 24,
    this.swatchSize = 32,
    this.strings = const NoteToolsStrings(),
    this.style = const NoteToolsStyle(),
  });

  /// The default [swatches].
  static const List<Color> defaultSwatches = [
    Color(0xFF000000),
    Color(0xFF616161),
    Color(0xFFFFFFFF),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF00897B),
    Color(0xFF1E88E5),
    Color(0xFF3949AB),
    Color(0xFF8E24AA),
    Color(0xFFD81B60),
  ];

  /// Key of the saturation/brightness plane.
  static const Key planeKey = ValueKey<String>('noteColorPicker.plane');

  /// Key of the hue strip.
  static const Key hueKey = ValueKey<String>('noteColorPicker.hue');

  /// Key of the hex field.
  static const Key hexFieldKey = ValueKey<String>('noteColorPicker.hex');

  /// Key of the eyedropper button.
  static const Key eyedropperKey = ValueKey<String>(
    'noteColorPicker.eyedropper',
  );

  /// Key of the swatch at [index] of [swatches].
  static Key swatchKey(int index) =>
      ValueKey<String>('noteColorPicker.swatch.$index');

  /// The colour to show.
  final Color color;

  /// Called with every new colour.
  final ValueChanged<Color> onChanged;

  /// Called once when a change is complete.
  final ValueChanged<Color>? onChangeEnd;

  /// Picks a colour from the screen; the button shows only when this is given.
  /// A `null` result is ignored. Its errors are not caught.
  final Future<Color?> Function()? onEyedropper;

  /// Colours offered below the controls (for example favourites); empty hides
  /// the row.
  final List<Color> swatches;

  /// Height of the saturation/brightness plane.
  final double planeHeight;

  /// Height of the hue strip.
  final double hueStripHeight;

  /// Diameter of a swatch.
  final double swatchSize;

  /// Texts.
  final NoteToolsStrings strings;

  /// Colours and sizes.
  final NoteToolsStyle style;

  @override
  State<NoteColorPicker> createState() => _NoteColorPickerState();
}

class _NoteColorPickerState extends State<NoteColorPicker> {
  static const _fallbackWidth = 280.0;
  static const _hueLimit = 359.9;
  static const _hueStep = 15.0;

  late NoteHsv _hsv = NoteHsv.fromColor(widget.color);

  /// Hex text of [color], with the alpha only when it is not opaque.
  static String _hexOf(Color color) =>
      NoteColorUtils.toHex(color, alpha: color.toARGB32() >>> 24 != 0xFF);
  late final TextEditingController _hex = TextEditingController(
    text: _hexOf(widget.color),
  );
  final FocusNode _hexFocus = FocusNode();

  bool _picking = false;

  /// Keeps what RGB cannot express: the hue of a grey, the saturation of black.
  NoteHsv _adopt(NoteHsv next) {
    if (next.v == 0) return next.copyWith(h: _hsv.h, s: _hsv.s);

    return next.s == 0 ? next.copyWith(h: _hsv.h) : next;
  }

  void _syncHex() {
    final text = _hexOf(_hsv.toColor());
    if (_hex.text == text) return;
    _hex.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _setHsv(NoteHsv next) {
    if (next == _hsv) return;
    final changed = next.toColor().toARGB32() != _hsv.toColor().toARGB32();
    setState(() => _hsv = next);
    _syncHex();
    if (changed) widget.onChanged(next.toColor());
  }

  void _finish() => widget.onChangeEnd?.call(_hsv.toColor());

  void _choose(Color color) {
    if (color.toARGB32() == _hsv.toColor().toARGB32()) {
      _syncHex();

      return;
    }
    _setHsv(_adopt(NoteHsv.fromColor(color)));
    _finish();
  }

  void _submitHex(String input) {
    final parsed = NoteColorUtils.parseHex(input);
    if (parsed == null) {
      _syncHex();

      return;
    }
    final hasAlpha = input.trim().replaceFirst('#', '').length == 8;
    _choose(hasAlpha ? parsed : parsed.withValues(alpha: _hsv.a));
  }

  void _onPlane(Offset fraction) =>
      _setHsv(_hsv.copyWith(s: fraction.dx, v: 1 - fraction.dy));

  void _onHue(Offset fraction) =>
      _setHsv(_hsv.copyWith(h: math.min(fraction.dx * 360, _hueLimit)));

  void _nudgeHue(double degrees) {
    _setHsv(_hsv.copyWith(h: (_hsv.h + degrees) % 360));
    _finish();
  }

  // Errors of the eyedropper are left unhandled on purpose (see
  // [NoteColorPicker.onEyedropper]).
  void _startEyedropper() => unawaited(_useEyedropper());

  Future<void> _useEyedropper() async {
    final pick = widget.onEyedropper;
    if (pick == null || _picking) return;
    setState(() => _picking = true);
    try {
      final color = await pick();
      if (mounted && color != null) _choose(color);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  void didUpdateWidget(NoteColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.color.toARGB32();
    if (next != oldWidget.color.toARGB32() &&
        next != _hsv.toColor().toARGB32()) {
      _hsv = _adopt(NoteHsv.fromColor(widget.color));
      _syncHex();
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: widget.style.spacing);
    final current = _hsv.toColor();

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _fallbackWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Plane(
              color: _hsv,
              height: widget.planeHeight,
              radius: widget.style.cornerRadius,
              strings: widget.strings,
              onPosition: _onPlane,
              onEnd: _finish,
            ),
            gap,
            _HueStrip(
              hue: _hsv.h,
              height: widget.hueStripHeight,
              strings: widget.strings,
              onPosition: _onHue,
              onEnd: _finish,
              onNudge: _nudgeHue,
              step: _hueStep,
            ),
            gap,
            _HexRow(
              color: current,
              controller: _hex,
              focusNode: _hexFocus,
              strings: widget.strings,
              style: widget.style,
              onSubmitted: _submitHex,
              onEyedropper: widget.onEyedropper == null
                  ? null
                  : _startEyedropper,
              picking: _picking,
            ),
            if (widget.swatches.isNotEmpty) ...[
              gap,
              _Swatches(
                swatches: widget.swatches,
                current: current,
                size: widget.swatchSize,
                strings: widget.strings,
                style: widget.style,
                onSelected: _choose,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Plane extends StatelessWidget {
  const _Plane({
    required this.color,
    required this.height,
    required this.radius,
    required this.strings,
    required this.onPosition,
    required this.onEnd,
  });

  final NoteHsv color;
  final double height;
  final double radius;
  final NoteToolsStrings strings;
  final ValueChanged<Offset> onPosition;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => Semantics(
    label: strings.saturationAndBrightness,
    value: strings.saturationBrightnessValue(
      (color.s * 100).round(),
      (color.v * 100).round(),
    ),
    child: SizedBox(
      key: NoteColorPicker.planeKey,
      height: height,
      child: NoteToolsDragArea(
        onPosition: onPosition,
        onEnd: onEnd,
        child: CustomPaint(
          size: Size.infinite,
          painter: NoteSaturationValuePainter(color, radius: radius),
        ),
      ),
    ),
  );
}

class _HueStrip extends StatelessWidget {
  const _HueStrip({
    required this.hue,
    required this.height,
    required this.strings,
    required this.onPosition,
    required this.onEnd,
    required this.onNudge,
    required this.step,
  });

  final double hue;
  final double height;
  final NoteToolsStrings strings;
  final ValueChanged<Offset> onPosition;
  final VoidCallback onEnd;
  final ValueChanged<double> onNudge;
  final double step;

  @override
  Widget build(BuildContext context) => Semantics(
    slider: true,
    label: strings.hue,
    value: '${hue.round()}°',
    increasedValue: '${((hue + step) % 360).round()}°',
    decreasedValue: '${((hue - step) % 360).round()}°',
    onIncrease: () => onNudge(step),
    onDecrease: () => onNudge(-step),
    child: SizedBox(
      key: NoteColorPicker.hueKey,
      height: height,
      child: NoteToolsDragArea(
        onPosition: onPosition,
        onEnd: onEnd,
        child: CustomPaint(
          size: Size.infinite,
          painter: NoteHueStripPainter(hue),
        ),
      ),
    ),
  );
}

class _HexRow extends StatelessWidget {
  const _HexRow({
    required this.color,
    required this.controller,
    required this.focusNode,
    required this.strings,
    required this.style,
    required this.onSubmitted,
    required this.onEyedropper,
    required this.picking,
  });

  final Color color;
  final TextEditingController controller;
  final FocusNode focusNode;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onEyedropper;
  final bool picking;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Semantics(
        label: strings.currentColor(NoteColorUtils.toHex(color)),
        child: NoteToolsColorDot(
          color: color,
          size: 40,
          borderColor: style.borderColor,
          ringColor: style.accentColor,
        ),
      ),
      SizedBox(width: style.spacing),
      Expanded(
        child: Semantics(
          label: strings.hexColor,
          child: NoteTextField(
            key: NoteColorPicker.hexFieldKey,
            controller: controller,
            focusNode: focusNode,
            hintText: strings.hexHint,
            submitOnBlur: true,
            onSubmitted: onSubmitted,
            style: style.labelStyle,
            cursorColor: style.accentColor,
          ),
        ),
      ),
      if (onEyedropper != null) ...[
        SizedBox(width: style.spacing),
        NoteToolsButton(
          key: NoteColorPicker.eyedropperKey,
          label: strings.eyedropper,
          tooltip: strings.eyedropperTooltip,
          onPressed: picking ? null : onEyedropper,
          style: style,
        ),
      ],
    ],
  );
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.swatches,
    required this.current,
    required this.size,
    required this.strings,
    required this.style,
    required this.onSelected,
  });

  final List<Color> swatches;
  final Color current;
  final double size;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: style.spacing / 2,
    runSpacing: style.spacing / 2,
    children: [
      for (var index = 0; index < swatches.length; index++)
        _Swatch(
          key: NoteColorPicker.swatchKey(index),
          color: swatches[index],
          selected: swatches[index].toARGB32() == current.toARGB32(),
          size: size,
          strings: strings,
          style: style,
          onSelected: onSelected,
        ),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.size,
    required this.strings,
    required this.style,
    required this.onSelected,
    super.key,
  });

  final Color color;
  final bool selected;
  final double size;
  final NoteToolsStrings strings;
  final NoteToolsStyle style;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: strings.colorSwatch(NoteColorUtils.toHex(color)),
    onTap: () => onSelected(color),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(color),
      child: NoteToolsColorDot(
        color: color,
        size: size,
        borderColor: style.borderColor,
        ringColor: style.accentColor,
        selected: selected,
      ),
    ),
  );
}
