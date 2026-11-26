import 'package:flutter/widgets.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/note_slider.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/internal/note_editor_drawer_kind.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/style/note_image_crop.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_line_style_kind.dart';
import 'package:open_note/src/note/style/note_shape_kind.dart';
import 'package:open_note/src/note/style/note_shape_style.dart';
import 'package:open_note/src/note/style/note_text_box_border_style.dart';
import 'package:open_note/src/note/style/note_text_box_style.dart';
import 'package:open_note/src/note/tools/note_eraser_mode.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_lasso_shape.dart';
import 'package:open_note/src/note/tools/note_text_style_preset_store.dart';

/// The settings of the current drawing tool, and the actions on a lasso
/// selection or a selected picture.
class NoteToolOptions extends StatelessWidget {
  const NoteToolOptions({
    required this.controller,
    required this.strings,
    required this.style,
    required this.textStyles,
    required this.onDrawer,
    this.onAddImages,
    this.fontFamilies = const [],
    super.key,
  });

  /// The quick ink colours; the colour sheet offers any colour.
  static const List<Color> quickColors = [
    Color(0xFF000000),
    Color(0xFF616161),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  static const Color _outlineDark = Color(0xFF212121);
  static final NoteTextBoxStyle _fillBox = NoteTextBoxStyle(
    backgroundColor: const Color(0xFFFFF59D),
    cornerRadius: 6,
    padding: const EdgeInsets.all(6),
  );
  static final NoteTextBoxStyle _borderBox = NoteTextBoxStyle(
    borderColor: const Color(0xFF424242),
    borderWidth: 1.5,
    cornerRadius: 6,
    padding: const EdgeInsets.all(6),
  );
  static final NoteTextBoxStyle _dashedBox = _borderBox.copyWith(
    borderLineStyle: NoteTextBoxBorderStyle.dashed,
  );
  static const Color _outlineLight = Color(0xFFFFFFFF);

  /// Inks whose strokes take a line style.
  static const Set<String> _lineStyleInks = {
    NoteInkTypes.pen,
    NoteInkTypes.pencil,
    NoteInkTypes.marker,
    NoteInkTypes.fixedPen,
    NoteInkTypes.uniformPen,
  };

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final NoteTextStylePresetStore textStyles;
  final ValueChanged<NoteEditorDrawerKind> onDrawer;
  final VoidCallback? onAddImages;

  /// Fonts the host loaded, offered for the selected text boxes.
  final List<String> fontFamilies;

  @override
  Widget build(BuildContext context) => NoteEditorStrip(
    style: style,
    children: switch (controller.tools.currentTool) {
      NoteInkTypes.erase => _eraser(),
      NoteInkTypes.lasso => _lasso(),
      NoteInkTypes.shape => _shape(),
      NoteInkTypes.image => _image(),
      NoteInkTypes.text => _text(),
      _ => _pen(),
    },
  );

  List<Widget> _pen() {
    final tools = controller.tools;
    final ink = tools.currentTool;
    final isMarker = ink == NoteInkTypes.marker;

    return [
      ..._colors(tools.color, tools.setColor, opacity: isMarker ? 0.5 : 1),
      _slider(
        'width',
        strings.width,
        tools.width,
        0.5,
        isMarker ? 40 : 20,
        tools.setWidth,
      ),
      if (_lineStyleInks.contains(ink)) ..._lineStyles(),
      _button(
        'pen-settings',
        strings.penSettings,
        () => onDrawer(NoteEditorDrawerKind.penSettings),
      ),
      _button(
        'save-favorite',
        strings.saveFavorite,
        () => tools.saveAsPreset(),
      ),
      _toggle(
        'finger-drawing',
        strings.fingerDrawing,
        tools.fingerDrawing,
        (value) => tools.fingerDrawing = value,
      ),
      _toggle(
        'hold-to-snap',
        strings.holdToSnap,
        tools.holdToSnapShapes,
        (value) => tools.holdToSnapShapes = value,
      ),
      _button(
        'pencil-gestures',
        strings.tools.pencilGestures,
        () => onDrawer(NoteEditorDrawerKind.pencilGestures),
      ),
    ];
  }

  List<Widget> _text() {
    final tools = controller.tools;

    return [
      ..._colors(tools.color, tools.setColor),
      _slider(
        'font-size',
        strings.fontSize,
        tools.width,
        8,
        72,
        tools.setWidth,
      ),
    ];
  }

  List<Widget> _eraser() {
    final tools = controller.tools;
    final settings = tools.eraserSettings;

    return [
      _button(
        'stroke-eraser',
        strings.strokeEraser,
        () => tools.eraserSettings = settings.copyWith(
          mode: NoteEraserMode.stroke,
        ),
        selected: settings.mode == NoteEraserMode.stroke,
      ),
      _button(
        'pixel-eraser',
        strings.pixelEraser,
        () => tools.eraserSettings = settings.copyWith(
          mode: NoteEraserMode.pixel,
        ),
        selected: settings.mode == NoteEraserMode.pixel,
      ),
      _slider(
        'eraser-size',
        strings.width,
        settings.size,
        4,
        80,
        tools.setWidth,
      ),
      _button(
        'eraser-settings',
        strings.eraserSettings,
        () => onDrawer(NoteEditorDrawerKind.eraserSettings),
      ),
    ];
  }

  List<Widget> _lasso() {
    final tools = controller.tools;
    final settings = tools.lassoSettings;
    final selection = controller.lassoSelection;

    return [
      for (final (shape, label) in [
        (NoteLassoShape.freeform, strings.freeformLasso),
        (NoteLassoShape.rectangle, strings.rectangleLasso),
      ])
        _button(
          'lasso-${shape.name}',
          label,
          () => tools.lassoSettings = settings.copyWith(shape: shape),
          selected: settings.shape == shape,
        ),
      if (!selection.isEmpty) ..._selectionActions(),
    ];
  }

  List<Widget> _selectionActions() {
    final layers = controller.layers;
    final selection = controller.lassoSelection;
    final strokes = layers.activeNotifier.currentScribble.strokes;
    final picked = [
      for (final index in selection.strokeIndexes)
        if (index >= 0 && index < strokes.length) strokes[index],
    ];
    final width = picked.isEmpty ? null : _widthOf(picked.first);

    return [
      for (final color in quickColors)
        NoteEditorSwatch(
          key: ValueKey('note-recolor-${color.toARGB32()}'),
          color: color,
          label: '${strings.recolor} ${strings.colorName(color.toARGB32())}',
          style: style,
          onPressed: () => controller.restyleSelection(color: color),
        ),
      if (width != null) ...[
        _button(
          'thinner',
          strings.thinner,
          () =>
              controller.restyleSelection(width: (width * 0.75).clamp(0.5, 60)),
        ),
        _button(
          'thicker',
          strings.thicker,
          () =>
              controller.restyleSelection(width: (width * 1.35).clamp(0.5, 60)),
        ),
        for (final kind in NoteLineStyleKind.values)
          _button(
            'restyle-line-${kind.name}',
            _lineName(kind),
            () => controller.restyleSelection(
              lineStyle: kind == NoteLineStyleKind.solid
                  ? ''
                  : NoteLineStyle(kind: kind).encode(),
            ),
          ),
        _button('outline-effect', strings.outlineEffect, () {
          final ink = Color(picked.first.color);
          controller.outlineSelection(
            color: ink.computeLuminance() > 0.5 ? _outlineDark : _outlineLight,
          );
        }),
      ],
      if (selection.textIndexes.isNotEmpty) ...[
        for (final preset in textStyles.presets)
          _button(
            'text-style-${preset.id}',
            preset.name,
            () => controller.applyTextStyle(preset),
          ),
        for (final (key, label, box) in [
          ('text-box', strings.textBox, _fillBox),
          ('text-border', strings.textBorder, _borderBox),
          ('text-dashed-border', strings.textDashedBorder, _dashedBox),
        ])
          _textBoxButton(key, label, box),
        for (final family in fontFamilies)
          _button(
            'font-$family',
            family,
            () => controller.setSelectedTextFont(family),
          ),
      ],
      for (final layer in layers.layers)
        if (layer.id != layers.activeLayerId)
          _button(
            'move-to-${layer.id}',
            strings.moveToLayer(layer.name),
            () => controller.moveSelectionToLayer(layer.id),
          ),
      _button('deselect', strings.deselect, selection.clear),
    ];
  }

  Widget _textBoxButton(String key, String label, NoteTextBoxStyle box) {
    final current = _selectedTextBox();
    final selected = current.copyWith(lineHeight: 0) == box;

    return _button(
      key,
      label,
      () => controller.styleSelectedTextBoxes(
        (selected ? NoteTextBoxStyle.plain : box).copyWith(
          lineHeight: current.lineHeight,
        ),
      ),
      selected: selected,
    );
  }

  /// The box style of the first selected text.
  NoteTextBoxStyle _selectedTextBox() {
    final texts =
        controller.layers.activeNotifier.currentScribble.textDrawables;
    for (final index in controller.lassoSelection.textIndexes) {
      if (index >= 0 && index < texts.length) {
        return NoteTextBoxStyle.decode(texts[index].boxStyle);
      }
    }

    return NoteTextBoxStyle.plain;
  }

  List<Widget> _shape() {
    final tools = controller.tools;
    final target = tools.shapeTarget;
    final shape = NoteShapeStyle.decode(tools.shapeStyle);

    void restyle(NoteShapeStyle next) =>
        tools.setShapeStyle(next == NoteShapeStyle.plain ? '' : next.encode());

    return [
      _button(
        'shape-auto',
        strings.autoShape,
        () => tools.setShapeTarget(''),
        selected: target.isEmpty,
      ),
      for (final kind in NoteShapeKind.values)
        _button(
          'shape-${kind.name}',
          strings.shapeName(kind),
          () => tools.setShapeTarget(kind.name),
          selected: target == kind.name,
        ),
      ..._colors(tools.color, tools.setColor),
      _slider('width', strings.width, tools.width, 0.5, 20, tools.setWidth),
      _toggle(
        'shape-fill',
        strings.fill,
        shape.fillColor != null,
        (value) => restyle(
          value
              ? shape.copyWith(fillColor: tools.color, fillOpacity: 0.25)
              : shape.copyWith(clearFillColor: true, fillOpacity: 1),
        ),
      ),
      _toggle(
        'shape-rounded',
        strings.roundedCorners,
        shape.cornerRadius > 0,
        (value) => restyle(shape.copyWith(cornerRadius: value ? 16 : 0)),
      ),
      if (shape.cornerRadius > 0)
        _slider(
          'corner-radius',
          strings.cornerRadius,
          shape.cornerRadius,
          2,
          64,
          (value) => restyle(shape.copyWith(cornerRadius: value)),
        ),
      _slider(
        'shape-opacity',
        strings.opacity,
        shape.strokeOpacity,
        0.1,
        1,
        (value) => restyle(shape.copyWith(strokeOpacity: value)),
      ),
      if (shape.fillColor != null)
        _slider(
          'fill-opacity',
          strings.fillOpacity,
          shape.fillOpacity,
          0.05,
          1,
          (value) => restyle(shape.copyWith(fillOpacity: value)),
        ),
      for (final kind in [
        NoteLineStyleKind.solid,
        NoteLineStyleKind.dashed,
        NoteLineStyleKind.dotted,
      ])
        _button(
          'shape-line-${kind.name}',
          _lineName(kind),
          () => restyle(shape.copyWith(lineStyle: NoteLineStyle(kind: kind))),
          selected: shape.lineStyle.kind == kind,
        ),
    ];
  }

  List<Widget> _image() {
    final image = controller.selectedImage;

    return [
      if (onAddImages != null)
        _button('add-images', strings.addImages, onAddImages),
      if (image != null) ..._imageActions(image),
    ];
  }

  List<Widget> _imageActions(ImageDrawable image) {
    final current = NoteImageStyle.decode(image.imageStyle);
    final framed = current.borderColor != null;
    final rounded = current.cornerRadius > 0;

    return [
      _toggle(
        'image-frame',
        strings.imageFrame,
        framed,
        (value) => controller.styleSelectedImage(
          value
              ? current.copyWith(
                  borderColor: const Color(0xFFFFFFFF),
                  borderWidth: 8,
                )
              : current.copyWith(clearBorderColor: true),
        ),
      ),
      _toggle(
        'image-rounded',
        strings.roundedCorners,
        rounded,
        (value) => controller.styleSelectedImage(
          current.copyWith(cornerRadius: value ? 16 : 0),
        ),
      ),
      NoteEditorLabelled(
        label: strings.imageOpacity,
        style: style,
        child: _OpacitySlider(
          key: ValueKey('note-image-opacity-${image.id}'),
          value: current.opacity,
          label: strings.imageOpacity,
          onChangeEnd: (value) =>
              controller.styleSelectedImage(current.copyWith(opacity: value)),
        ),
      ),
      _button(
        'image-crop',
        strings.cropImage,
        () => onDrawer(NoteEditorDrawerKind.imageCrop),
      ),
      if (current.crop != NoteImageCrop.none)
        _button(
          'image-whole',
          strings.wholeImage,
          () => controller.styleSelectedImage(
            current.copyWith(crop: NoteImageCrop.none),
          ),
        ),
    ];
  }

  List<Widget> _colors(
    Color current,
    ValueChanged<Color> onColor, {
    double opacity = 1,
  }) => [
    for (final base in quickColors)
      NoteEditorSwatch(
        key: ValueKey('note-color-${base.toARGB32()}'),
        color: base.withValues(alpha: opacity),
        label: strings.colorName(base.toARGB32()),
        style: style,
        selected:
            (current.toARGB32() & 0xFFFFFF) == (base.toARGB32() & 0xFFFFFF),
        onPressed: () => onColor(base.withValues(alpha: opacity)),
      ),
    _button(
      'more-colors',
      strings.moreColors,
      () => onDrawer(NoteEditorDrawerKind.colors),
    ),
  ];

  List<Widget> _lineStyles() {
    final tools = controller.tools;
    final current = NoteLineStyle.decode(tools.lineStyle);

    void apply(NoteLineStyle next) => tools.setLineStyle(
      next.kind == NoteLineStyleKind.solid ? 'solid' : next.encode(),
    );

    return [
      for (final kind in NoteLineStyleKind.values)
        _button(
          'line-${kind.name}',
          _lineName(kind),
          () => apply(NoteLineStyle(kind: kind)),
          selected: current.kind == kind,
        ),
      ...switch (current.kind) {
        NoteLineStyleKind.dashed || NoteLineStyleKind.dotted => [
          if (current.kind == NoteLineStyleKind.dashed)
            _slider(
              'dash-length',
              strings.dashLength,
              current.dashLength,
              NoteLineStyle.minDash,
              NoteLineStyle.maxDash,
              (value) => apply(current.copyWith(dashLength: value)),
            ),
          _slider(
            'dash-gap',
            strings.dashGap,
            current.gap,
            NoteLineStyle.minDash,
            NoteLineStyle.maxDash,
            (value) => apply(current.copyWith(gap: value)),
          ),
        ],
        NoteLineStyleKind.wavy || NoteLineStyleKind.zigzag => [
          _slider(
            'wave-height',
            strings.waveHeight,
            current.amplitude,
            NoteLineStyle.minAmplitude,
            NoteLineStyle.maxAmplitude,
            (value) => apply(current.copyWith(amplitude: value)),
          ),
          _slider(
            'wave-length',
            strings.waveLength,
            current.wavelength,
            NoteLineStyle.minWavelength,
            NoteLineStyle.maxWavelength,
            (value) => apply(current.copyWith(wavelength: value)),
          ),
        ],
        NoteLineStyleKind.double => [
          _slider(
            'double-gap',
            strings.doubleSpacing,
            current.doubleGap,
            NoteLineStyle.minDoubleGap,
            NoteLineStyle.maxDoubleGap,
            (value) => apply(current.copyWith(doubleGap: value)),
          ),
        ],
        _ => const <Widget>[],
      },
    ];
  }

  String _lineName(NoteLineStyleKind kind) => switch (kind) {
    NoteLineStyleKind.solid => strings.solidLine,
    NoteLineStyleKind.dashed => strings.dashedLine,
    NoteLineStyleKind.dotted => strings.dottedLine,
    NoteLineStyleKind.wavy => strings.wavyLine,
    NoteLineStyleKind.zigzag => strings.zigzagLine,
    NoteLineStyleKind.double => strings.doubleLine,
  };

  Widget _button(
    String key,
    String label,
    VoidCallback? onPressed, {
    bool selected = false,
  }) => NoteEditorButton(
    key: ValueKey('note-option-$key'),
    label: label,
    style: style,
    onPressed: onPressed,
    selected: selected,
  );

  Widget _toggle(
    String key,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => _button(key, label, () => onChanged(!value), selected: value);

  Widget _slider(
    String key,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => NoteEditorLabelled(
    key: ValueKey('note-option-$key'),
    label: label,
    style: style,
    child: NoteSlider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      onChanged: onChanged,
      semanticLabel: label,
      activeColor: style.accentColor,
    ),
  );

  static double _widthOf(Stroke stroke) =>
      stroke.width > 0 ? stroke.width : stroke.options.size;
}

/// An opacity slider that applies once, when the drag ends.
class _OpacitySlider extends StatefulWidget {
  const _OpacitySlider({
    required this.value,
    required this.label,
    required this.onChangeEnd,
    super.key,
  });

  final double value;
  final String label;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_OpacitySlider> createState() => _OpacitySliderState();
}

class _OpacitySliderState extends State<_OpacitySlider> {
  double? _dragged;

  @override
  Widget build(BuildContext context) => NoteSlider(
    value: _dragged ?? widget.value,
    min: 0.1,
    semanticLabel: widget.label,
    onChanged: (value) => setState(() => _dragged = value),
    onChangeEnd: (value) {
      setState(() => _dragged = null);
      widget.onChangeEnd(value);
    },
  );
}
