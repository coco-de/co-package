import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

/// Colours and sizes of the nav panels (plain widgets, no design system).
@immutable
class NoteNavStyle {
  /// Creates a style; every argument has a light default.
  const NoteNavStyle({
    this.textStyle = const TextStyle(fontSize: 14, color: Color(0xFF212121)),
    this.secondaryTextStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF757575),
    ),
    this.titleTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF212121),
    ),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.accentColor = const Color(0xFF2962FF),
    this.selectedColor = const Color(0x1F2962FF),
    this.iconColor = const Color(0xFF616161),
    this.dividerColor = const Color(0xFFE0E0E0),
    this.chipColor = const Color(0xFFF1F3F4),
    this.highlightColor = const Color(0xFFFFE082),
    this.rowHeight = 40,
    this.indentWidth = 16,
    this.iconSize = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  /// Row titles.
  final TextStyle textStyle;

  /// Page labels and other secondary text.
  final TextStyle secondaryTextStyle;

  /// Panel headers.
  final TextStyle titleTextStyle;

  /// Panel background.
  final Color backgroundColor;

  /// Text buttons, selected chips and the cursor.
  final Color accentColor;

  /// Background of the current row.
  final Color selectedColor;

  /// Icon buttons.
  final Color iconColor;

  /// Lines between rows.
  final Color dividerColor;

  /// Background of unselected chips.
  final Color chipColor;

  /// Background of matched search text, and the swatch of excerpts without a
  /// colour.
  final Color highlightColor;

  /// Minimum height of a row.
  final double rowHeight;

  /// Indentation per outline level.
  final double indentWidth;

  /// Size of an icon button.
  final double iconSize;

  /// Horizontal padding of rows and sections.
  final EdgeInsets padding;

  /// A copy with the given fields replaced.
  NoteNavStyle copyWith({
    TextStyle? textStyle,
    TextStyle? secondaryTextStyle,
    TextStyle? titleTextStyle,
    Color? backgroundColor,
    Color? accentColor,
    Color? selectedColor,
    Color? iconColor,
    Color? dividerColor,
    Color? chipColor,
    Color? highlightColor,
    double? rowHeight,
    double? indentWidth,
    double? iconSize,
    EdgeInsets? padding,
  }) => NoteNavStyle(
    textStyle: textStyle ?? this.textStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    accentColor: accentColor ?? this.accentColor,
    selectedColor: selectedColor ?? this.selectedColor,
    iconColor: iconColor ?? this.iconColor,
    dividerColor: dividerColor ?? this.dividerColor,
    chipColor: chipColor ?? this.chipColor,
    highlightColor: highlightColor ?? this.highlightColor,
    rowHeight: rowHeight ?? this.rowHeight,
    indentWidth: indentWidth ?? this.indentWidth,
    iconSize: iconSize ?? this.iconSize,
    padding: padding ?? this.padding,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteNavStyle &&
      other.textStyle == textStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.titleTextStyle == titleTextStyle &&
      other.backgroundColor == backgroundColor &&
      other.accentColor == accentColor &&
      other.selectedColor == selectedColor &&
      other.iconColor == iconColor &&
      other.dividerColor == dividerColor &&
      other.chipColor == chipColor &&
      other.highlightColor == highlightColor &&
      other.rowHeight == rowHeight &&
      other.indentWidth == indentWidth &&
      other.iconSize == iconSize &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(
    textStyle,
    secondaryTextStyle,
    titleTextStyle,
    backgroundColor,
    accentColor,
    selectedColor,
    iconColor,
    dividerColor,
    chipColor,
    highlightColor,
    rowHeight,
    indentWidth,
    iconSize,
    padding,
  );
}
