import 'package:flutter/widgets.dart';

/// Colors and sizes shared by the study-utility widgets (timer, stopwatch,
/// calculator, scratchpad and recording list). All sizes are logical pixels.
@immutable
class NoteStudyUtilitiesStyle {
  /// Light default colors and sizes.
  const NoteStudyUtilitiesStyle({
    this.background = const Color(0xFFFFFFFF),
    this.foreground = const Color(0xFF212121),
    this.mutedForeground = const Color(0xFF757575),
    this.accent = const Color(0xFF2962FF),
    this.onAccent = const Color(0xFFFFFFFF),
    this.danger = const Color(0xFFC62828),
    this.buttonBackground = const Color(0xFFF1F3F4),
    this.border = const Color(0xFFE0E0E0),
    this.cornerRadius = 8,
    this.fontSize = 14,
    this.digitFontSize = 40,
    this.keyHeight = 44,
    this.spacing = 8,
  });

  /// Fill behind a utility panel.
  final Color background;

  /// Text and icon color.
  final Color foreground;

  /// Secondary text such as subtitles.
  final Color mutedForeground;

  /// Primary buttons, operator keys and progress.
  final Color accent;

  /// Text on [accent].
  final Color onAccent;

  /// Errors and destructive actions.
  final Color danger;

  /// Fill of a secondary button.
  final Color buttonBackground;

  /// Hairlines around panels and rows.
  final Color border;

  /// Corner radius of buttons and panels.
  final double cornerRadius;

  /// Size of ordinary text.
  final double fontSize;

  /// Size of the timer, stopwatch and calculator digits.
  final double digitFontSize;

  /// Height of a calculator key when the view's height is unbounded.
  final double keyHeight;

  /// Gap between neighbouring elements.
  final double spacing;

  /// Ordinary text in [color] (default [foreground]).
  TextStyle text({Color? color}) =>
      TextStyle(color: color ?? foreground, fontSize: fontSize, height: 1.25);

  /// Large tabular digits in [color] (default [foreground]).
  TextStyle digits({Color? color}) => TextStyle(
    color: color ?? foreground,
    fontSize: digitFontSize,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  bool operator ==(Object other) =>
      other is NoteStudyUtilitiesStyle &&
      other.background == background &&
      other.foreground == foreground &&
      other.mutedForeground == mutedForeground &&
      other.accent == accent &&
      other.onAccent == onAccent &&
      other.danger == danger &&
      other.buttonBackground == buttonBackground &&
      other.border == border &&
      other.cornerRadius == cornerRadius &&
      other.fontSize == fontSize &&
      other.digitFontSize == digitFontSize &&
      other.keyHeight == keyHeight &&
      other.spacing == spacing;

  @override
  int get hashCode => Object.hash(
    background,
    foreground,
    mutedForeground,
    accent,
    onAccent,
    danger,
    buttonBackground,
    border,
    cornerRadius,
    fontSize,
    digitFontSize,
    keyHeight,
    spacing,
  );
}
