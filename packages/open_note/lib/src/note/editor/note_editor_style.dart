import 'package:flutter/painting.dart';

/// Colours and sizes of `NoteEditorView`.
class NoteEditorStyle {
  const NoteEditorStyle({
    this.barColor = const Color(0xFFF7F7F8),
    this.canvasColor = const Color(0xFFE6E6EA),
    this.panelColor = const Color(0xFFFFFFFF),
    this.dividerColor = const Color(0xFFD6D6DB),
    this.textColor = const Color(0xFF1F1F24),
    this.mutedColor = const Color(0xFF8A8A93),
    this.accentColor = const Color(0xFF2962FF),
    this.selectedColor = const Color(0x1F2962FF),
    this.tooltipColor = const Color(0xF0212121),
    this.tooltipTextColor = const Color(0xFFFFFFFF),
    this.fontSize = 13,
    this.radius = 8,
    this.spacing = 4,
    this.swatchSize = 26,
    this.sliderWidth = 150,
    this.panelWidth = 280,
    this.drawerMaxHeight = 300,
    this.fontFamily,
  });

  final Color barColor;

  /// Around the page.
  final Color canvasColor;
  final Color panelColor;
  final Color dividerColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final Color selectedColor;
  final Color tooltipColor;
  final Color tooltipTextColor;
  final double fontSize;
  final double radius;
  final double spacing;
  final double swatchSize;
  final double sliderWidth;
  final double panelWidth;

  /// The most height a menu or settings drawer takes below the bars.
  final double drawerMaxHeight;

  /// The font of the editor's own text; the platform default when null.
  final String? fontFamily;

  TextStyle get textStyle => TextStyle(
    fontFamily: fontFamily,
    color: textColor,
    fontSize: fontSize,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w400,
  );
}
