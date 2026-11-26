import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture.dart';

/// Every user-visible text of the tools widgets and the names of the default
/// presets. Defaults are English; pass your own instance to translate.
@immutable
class NoteToolsStrings {
  /// Label of the motion smoothing slider.
  final String motionSmoothing;

  /// Help text of the motion smoothing slider.
  final String motionSmoothingHelp;

  /// Label of the stabilization slider.
  final String stabilization;

  /// Help text of the stabilization slider.
  final String stabilizationHelp;

  /// Label of the pressure sensitivity slider.
  final String pressureSensitivity;

  /// Help text of the pressure sensitivity slider.
  final String pressureSensitivityHelp;

  /// Text of the help button.
  final String helpGlyph;

  /// Accessibility label of the help button of the setting named `label`.
  final String Function(String label) helpLabel;

  /// Formats a whole percentage such as 20 as `20%`.
  final String Function(int value) percent;

  /// Accessibility label of the hue strip.
  final String hue;

  /// Accessibility label of the saturation and brightness plane.
  final String saturationAndBrightness;

  /// Accessibility value of the plane, from two percentages.
  final String Function(int saturation, int brightness)
  saturationBrightnessValue;

  /// Accessibility label of the hex field.
  final String hexColor;

  /// Placeholder of the hex field.
  final String hexHint;

  /// Text of the eyedropper button.
  final String eyedropper;

  /// Tooltip of the eyedropper button.
  final String eyedropperTooltip;

  /// Accessibility label of the color preview, from its hex text.
  final String Function(String hex) currentColor;

  /// Accessibility label of a swatch, from its hex text.
  final String Function(String hex) colorSwatch;

  /// Shown instead of the preset bar when there are no presets.
  final String noPresets;

  /// Accessibility label of a preset from its name and width label.
  final String Function(String name, String width) presetDescription;

  /// Accessibility hint that long pressing a preset edits it.
  final String presetEditHint;

  /// Name of the pen ink.
  final String penInk;

  /// Name of the pencil ink.
  final String pencilInk;

  /// Name of the marker ink.
  final String markerInk;

  /// Name of the fixed-width pen ink.
  final String fixedPenInk;

  /// Name of the uniform pen ink.
  final String uniformPenInk;

  /// Name of the shape ink.
  final String shapeInk;

  /// Name of the text ink.
  final String textInk;

  /// Accessibility label of the eraser type selector.
  final String eraserMode;

  /// Name of the stroke eraser.
  final String strokeEraser;

  /// Name of the pixel eraser.
  final String pixelEraser;

  /// Label of the eraser size slider.
  final String eraserSize;

  /// Label of the pressure switch toggle.
  final String pressureSwitch;

  /// Label of the pressure threshold slider.
  final String pressureThreshold;

  /// Text of a switch that is on.
  final String switchOn;

  /// Text of a switch that is off.
  final String switchOff;

  /// Default name of the black pen preset.
  final String blackPen;

  /// Default name of the red pen preset.
  final String redPen;

  /// Default name of the blue pen preset.
  final String bluePen;

  /// Default name of the white pen preset.
  final String whitePen;

  /// Default name of the yellow marker preset.
  final String yellowMarker;

  /// Default name of the title text style.
  final String titleStyle;

  /// Default name of the heading text style.
  final String headingStyle;

  /// Default name of the body text style.
  final String bodyStyle;

  /// Default name of the caption text style.
  final String captionStyle;

  /// Creates strings; every argument defaults to English.
  /// The title and the two gesture rows of `NotePencilGesturePanel`.
  final String pencilGestures;
  final String pencilDoubleTap;
  final String pencilSqueeze;

  /// The actions a gesture can run.
  final String pencilNothing;
  final String pencilPreviousTool;
  final String pencilEraser;
  final String pencilUndo;
  final String pencilRedo;
  final String pencilToolPalette;
  final String pencilNextFavourite;

  const NoteToolsStrings({
    this.motionSmoothing = 'Motion smoothing',
    this.motionSmoothingHelp =
        'Softens the edges of the line. Higher values look smoother but '
        'follow the pen less exactly.',
    this.stabilization = 'Stroke stabilization',
    this.stabilizationHelp =
        'Steadies a shaky hand by letting the line trail behind the pen. '
        'Higher values are steadier but lag more.',
    this.pressureSensitivity = 'Pressure sensitivity',
    this.pressureSensitivityHelp =
        'How pressure changes the line width. 50% leaves pressure as it is; '
        'lower values make light touches thicker, higher values thinner.',
    this.helpGlyph = '?',
    this.helpLabel = _helpLabel,
    this.percent = _percent,
    this.hue = 'Hue',
    this.saturationAndBrightness = 'Saturation and brightness',
    this.saturationBrightnessValue = _saturationBrightnessValue,
    this.hexColor = 'Hex color',
    this.hexHint = '#RRGGBB',
    this.eyedropper = 'Eyedropper',
    this.eyedropperTooltip = 'Pick a color from the screen',
    this.currentColor = _currentColor,
    this.colorSwatch = _colorSwatch,
    this.noPresets = 'No presets',
    this.presetDescription = _presetDescription,
    this.presetEditHint = 'Long press to edit',
    this.penInk = 'Pen',
    this.pencilInk = 'Pencil',
    this.markerInk = 'Marker',
    this.fixedPenInk = 'Fixed-width pen',
    this.uniformPenInk = 'Uniform pen',
    this.shapeInk = 'Shape',
    this.textInk = 'Text',
    this.eraserMode = 'Eraser type',
    this.strokeEraser = 'Stroke eraser',
    this.pixelEraser = 'Pixel eraser',
    this.eraserSize = 'Eraser size',
    this.pressureSwitch = 'Erase when pressing hard',
    this.pressureThreshold = 'Pressure threshold',
    this.switchOn = 'On',
    this.switchOff = 'Off',
    this.blackPen = 'Black pen',
    this.redPen = 'Red pen',
    this.bluePen = 'Blue pen',
    this.whitePen = 'White pen',
    this.yellowMarker = 'Yellow marker',
    this.titleStyle = 'Title',
    this.headingStyle = 'Heading',
    this.bodyStyle = 'Body',
    this.captionStyle = 'Caption',
    this.pencilGestures = 'Apple Pencil gestures',
    this.pencilDoubleTap = 'Double tap',
    this.pencilSqueeze = 'Squeeze',
    this.pencilNothing = 'Nothing',
    this.pencilPreviousTool = 'Previous tool',
    this.pencilEraser = 'Eraser on/off',
    this.pencilUndo = 'Undo',
    this.pencilRedo = 'Redo',
    this.pencilToolPalette = 'Tool palette',
    this.pencilNextFavourite = 'Next favourite',
  });

  /// The name of what a gesture runs.
  String pencilActionName(NotePencilAction action) => switch (action) {
    NotePencilAction.none => pencilNothing,
    NotePencilAction.switchPreviousTool => pencilPreviousTool,
    NotePencilAction.toggleEraser => pencilEraser,
    NotePencilAction.undo => pencilUndo,
    NotePencilAction.redo => pencilRedo,
    NotePencilAction.showToolPalette => pencilToolPalette,
    NotePencilAction.cyclePreset => pencilNextFavourite,
  };

  /// The name of the ink [ink]; unknown inks are returned unchanged.
  String inkName(String ink) => switch (ink) {
    NoteInkTypes.pen => penInk,
    NoteInkTypes.pencil => pencilInk,
    NoteInkTypes.marker => markerInk,
    NoteInkTypes.fixedPen => fixedPenInk,
    NoteInkTypes.uniformPen => uniformPenInk,
    NoteInkTypes.shape => shapeInk,
    NoteInkTypes.text => textInk,
    _ => ink,
  };

  static String _helpLabel(String label) => 'Help: $label';

  static String _percent(int value) => '$value%';

  static String _saturationBrightnessValue(int saturation, int brightness) =>
      'Saturation $saturation%, brightness $brightness%';

  static String _currentColor(String hex) => 'Current color $hex';

  static String _colorSwatch(String hex) => 'Color $hex';

  static String _presetDescription(String name, String width) =>
      '$name, width $width';
}
