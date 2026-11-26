import 'package:flutter/widgets.dart';

/// Colours used by the view widgets (split dividers, drop zones, thumbnail
/// grid, ruler, magnifier and tab bar). Every widget takes a `style` that
/// defaults to `const NoteViewStyle()`.
@immutable
class NoteViewStyle {
  /// The default light palette unless overridden.
  const NoteViewStyle({
    this.accentColor = const Color(0xFF2962FF),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.barColor = const Color(0xFFEEEEEE),
    this.borderColor = const Color(0xFFD6D6D6),
    this.textColor = const Color(0xFF212121),
    this.mutedTextColor = const Color(0xFF757575),
    this.dividerColor = const Color(0xFFBDBDBD),
    this.dropZoneColor = const Color(0x1A2962FF),
    this.dropZoneActiveColor = const Color(0x592962FF),
    this.rulerColor = const Color(0xD9FFF4CC),
    this.rulerMarkColor = const Color(0xFF4E342E),
    this.magnifierBorderColor = const Color(0xFF455A64),
  });

  /// Current-page ring, selection marks and the active tab underline.
  final Color accentColor;

  /// Background of the active tab and of the thumbnail frames.
  final Color surfaceColor;

  /// Background of the tab bar and of labels floating over a page.
  final Color barColor;

  /// Outlines of thumbnails and tabs.
  final Color borderColor;

  /// Primary text.
  final Color textColor;

  /// Secondary text (page numbers, inactive tabs).
  final Color mutedTextColor;

  /// Lines and grips of the pane dividers.
  final Color dividerColor;

  /// Fill of the drop zones that are shown but not hovered.
  final Color dropZoneColor;

  /// Fill of the hovered drop zone.
  final Color dropZoneActiveColor;

  /// Fill of the ruler body (translucent so ink stays visible).
  final Color rulerColor;

  /// Ruler ticks, numbers and outline.
  final Color rulerMarkColor;

  /// Rim of the magnifier lens.
  final Color magnifierBorderColor;

  /// A copy with the given colours replaced.
  NoteViewStyle copyWith({
    Color? accentColor,
    Color? surfaceColor,
    Color? barColor,
    Color? borderColor,
    Color? textColor,
    Color? mutedTextColor,
    Color? dividerColor,
    Color? dropZoneColor,
    Color? dropZoneActiveColor,
    Color? rulerColor,
    Color? rulerMarkColor,
    Color? magnifierBorderColor,
  }) => NoteViewStyle(
    accentColor: accentColor ?? this.accentColor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    barColor: barColor ?? this.barColor,
    borderColor: borderColor ?? this.borderColor,
    textColor: textColor ?? this.textColor,
    mutedTextColor: mutedTextColor ?? this.mutedTextColor,
    dividerColor: dividerColor ?? this.dividerColor,
    dropZoneColor: dropZoneColor ?? this.dropZoneColor,
    dropZoneActiveColor: dropZoneActiveColor ?? this.dropZoneActiveColor,
    rulerColor: rulerColor ?? this.rulerColor,
    rulerMarkColor: rulerMarkColor ?? this.rulerMarkColor,
    magnifierBorderColor: magnifierBorderColor ?? this.magnifierBorderColor,
  );

  List<Color> get _colors => [
    accentColor,
    surfaceColor,
    barColor,
    borderColor,
    textColor,
    mutedTextColor,
    dividerColor,
    dropZoneColor,
    dropZoneActiveColor,
    rulerColor,
    rulerMarkColor,
    magnifierBorderColor,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteViewStyle) return false;
    final mine = _colors;
    final theirs = other._colors;
    for (var i = 0; i < mine.length; i++) {
      if (mine[i] != theirs[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(_colors);
}
