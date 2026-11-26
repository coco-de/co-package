import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// The persisted look of a table: borders, header row and text defaults. All
/// lengths are page units (PDF points).
///
/// JSON (every key is optional):
///
/// ```json
/// {"borderColor": 4285887861, "borderWidth": 1, "headerRow": false,
///  "headerFill": 4293848814, "cellPadding": 4, "fontSize": 12,
///  "textColor": 4280361249}
/// ```
///
/// [NoteTableStyle.fromJson] never throws: wrongly typed values fall back to the
/// defaults and numbers are clamped to the documented ranges.
@immutable
class NoteTableStyle {
  /// Creates a style. [borderWidth], [cellPadding] and [fontSize] must be
  /// inside their documented ranges.
  const NoteTableStyle({
    this.borderColor = const Color(0xFF757575),
    this.borderWidth = 1,
    this.headerRow = false,
    this.headerFill = const Color(0xFFEEEEEE),
    this.cellPadding = 4,
    this.fontSize = 12,
    this.textColor = const Color(0xFF212121),
  }) : assert(borderWidth >= 0 && borderWidth <= maxBorderWidth),
       assert(cellPadding >= 0 && cellPadding <= maxCellPadding),
       assert(fontSize >= minFontSize && fontSize <= maxFontSize);

  /// Reads a style from its JSON form; never throws.
  factory NoteTableStyle.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};
    const fallback = NoteTableStyle();

    return NoteTableStyle(
      borderColor: NoteJson.color(json, 'borderColor', fallback.borderColor),
      borderWidth: NoteJson.number(
        json,
        'borderWidth',
        fallback.borderWidth,
      ).clamp(0.0, maxBorderWidth),
      headerRow: NoteJson.boolean(json, 'headerRow', fallback.headerRow),
      headerFill: NoteJson.color(json, 'headerFill', fallback.headerFill),
      cellPadding: NoteJson.number(
        json,
        'cellPadding',
        fallback.cellPadding,
      ).clamp(0.0, maxCellPadding),
      fontSize: NoteJson.number(
        json,
        'fontSize',
        fallback.fontSize,
      ).clamp(minFontSize, maxFontSize),
      textColor: NoteJson.color(json, 'textColor', fallback.textColor),
    );
  }

  /// Largest allowed [borderWidth].
  static const double maxBorderWidth = 8;

  /// Largest allowed [cellPadding].
  static const double maxCellPadding = 32;

  /// Smallest allowed [fontSize].
  static const double minFontSize = 4;

  /// Largest allowed [fontSize].
  static const double maxFontSize = 96;

  /// Colour of all grid lines.
  final Color borderColor;

  /// Width of all grid lines, 0 to 8. 0 draws no borders.
  final double borderWidth;

  /// Whether the first row is a header row, filled with [headerFill] (a cell's
  /// own fill colour wins).
  final bool headerRow;

  /// Background of the header row cells when [headerRow] is `true`.
  final Color headerFill;

  /// Space between a cell border and its text, 0 to 32. Small cells use less.
  final double cellPadding;

  /// Text size of every cell, 4 to 96.
  final double fontSize;

  /// Default text colour; a cell's own text colour wins.
  final Color textColor;

  /// A copy with the given fields replaced.
  NoteTableStyle copyWith({
    Color? borderColor,
    double? borderWidth,
    bool? headerRow,
    Color? headerFill,
    double? cellPadding,
    double? fontSize,
    Color? textColor,
  }) => NoteTableStyle(
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    headerRow: headerRow ?? this.headerRow,
    headerFill: headerFill ?? this.headerFill,
    cellPadding: cellPadding ?? this.cellPadding,
    fontSize: fontSize ?? this.fontSize,
    textColor: textColor ?? this.textColor,
  );

  /// The JSON form documented on the class.
  JsonMap toJson() => {
    'borderColor': NoteJson.colorToJson(borderColor),
    'borderWidth': borderWidth,
    'headerRow': headerRow,
    'headerFill': NoteJson.colorToJson(headerFill),
    'cellPadding': cellPadding,
    'fontSize': fontSize,
    'textColor': NoteJson.colorToJson(textColor),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTableStyle &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.headerRow == headerRow &&
          other.headerFill == headerFill &&
          other.cellPadding == cellPadding &&
          other.fontSize == fontSize &&
          other.textColor == textColor;

  @override
  int get hashCode => Object.hash(
    borderColor,
    borderWidth,
    headerRow,
    headerFill,
    cellPadding,
    fontSize,
    textColor,
  );
}
