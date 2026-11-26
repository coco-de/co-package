import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours and sizes shared by the tools widgets. Defaults are a plain light
/// look.
@immutable
class NoteToolsStyle {
  /// Colour of selections and sliders.
  final Color accentColor;

  /// Text on [accentColor].
  final Color onAccentColor;

  /// Primary text colour.
  final Color textColor;

  /// Secondary text colour.
  final Color mutedTextColor;

  /// Background of buttons.
  final Color surfaceColor;

  /// Outline of controls and swatches.
  final Color borderColor;

  /// Size of labels in logical pixels.
  final double fontSize;

  /// Gap between controls.
  final double spacing;

  /// Corner radius of controls.
  final double cornerRadius;

  /// Creates a style.
  const NoteToolsStyle({
    this.accentColor = const Color(0xFF2962FF),
    this.onAccentColor = const Color(0xFFFFFFFF),
    this.textColor = const Color(0xFF212121),
    this.mutedTextColor = const Color(0xFF616161),
    this.surfaceColor = const Color(0xFFF2F2F2),
    this.borderColor = const Color(0xFFBDBDBD),
    this.fontSize = 14,
    this.spacing = 12,
    this.cornerRadius = 8,
  });

  /// Style of labels.
  TextStyle get labelStyle => TextStyle(color: textColor, fontSize: fontSize);

  /// Style of numeric values.
  TextStyle get valueStyle => TextStyle(
    color: mutedTextColor,
    fontSize: fontSize,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Style of help and hint texts.
  TextStyle get helpStyle =>
      TextStyle(color: mutedTextColor, fontSize: fontSize - 2);

  @override
  int get hashCode => Object.hash(
    accentColor,
    onAccentColor,
    textColor,
    mutedTextColor,
    surfaceColor,
    borderColor,
    fontSize,
    spacing,
    cornerRadius,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteToolsStyle &&
      other.accentColor == accentColor &&
      other.onAccentColor == onAccentColor &&
      other.textColor == textColor &&
      other.mutedTextColor == mutedTextColor &&
      other.surfaceColor == surfaceColor &&
      other.borderColor == borderColor &&
      other.fontSize == fontSize &&
      other.spacing == spacing &&
      other.cornerRadius == cornerRadius;
}
