import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Sizes and colours of `NotePaperPicker`.
@immutable
class NotePaperPickerStyle {
  const NotePaperPickerStyle({
    this.tileExtent = 132,
    this.tileAspectRatio = 0.68,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(12),
    this.borderColor = const Color(0xFFD5D9DE),
    this.selectedColor = const Color(0xFF2962FF),
    this.selectedBorderWidth = 2,
    this.labelStyle = const TextStyle(fontSize: 12, color: Color(0xFF424242)),
    this.selectedLabelStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF2962FF),
    ),
    this.controlLabelStyle = const TextStyle(
      fontSize: 13,
      color: Color(0xFF212121),
    ),
  }) : assert(tileExtent > 0),
       assert(tileAspectRatio > 0);

  /// Largest width of a tile.
  final double tileExtent;

  /// Width over height of a tile (preview plus label).
  final double tileAspectRatio;

  /// Space between tiles.
  final double spacing;

  /// Space around the grid and the controls.
  final EdgeInsets padding;

  /// Frame of an unselected preview.
  final Color borderColor;

  /// Frame of the selected preview.
  final Color selectedColor;

  /// Width of the preview frame.
  final double selectedBorderWidth;

  /// Tile label.
  final TextStyle labelStyle;

  /// Label of the selected tile.
  final TextStyle selectedLabelStyle;

  /// Labels of the sliders.
  final TextStyle controlLabelStyle;

  @override
  bool operator ==(Object other) =>
      other is NotePaperPickerStyle &&
      other.tileExtent == tileExtent &&
      other.tileAspectRatio == tileAspectRatio &&
      other.spacing == spacing &&
      other.padding == padding &&
      other.borderColor == borderColor &&
      other.selectedColor == selectedColor &&
      other.selectedBorderWidth == selectedBorderWidth &&
      other.labelStyle == labelStyle &&
      other.selectedLabelStyle == selectedLabelStyle &&
      other.controlLabelStyle == controlLabelStyle;

  @override
  int get hashCode => Object.hash(
    tileExtent,
    tileAspectRatio,
    spacing,
    padding,
    borderColor,
    selectedColor,
    selectedBorderWidth,
    labelStyle,
    selectedLabelStyle,
    controlLabelStyle,
  );
}
