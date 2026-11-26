import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// Horizontal alignment of the text inside a table cell. Persisted by `name`.
enum NoteTableCellAlign {
  /// Aligned to the start edge (left in left-to-right text).
  start,

  /// Centred.
  center,

  /// Aligned to the end edge (right in left-to-right text).
  end,
}

/// The content and formatting of one position of a table grid.
///
/// A merged region is described by its top-left cell, the *anchor*: its
/// [rowSpan] and [columnSpan] say how many rows and columns it occupies. Every
/// other position of the region holds [coveredCell] ([covered] is `true`), which
/// is never drawn. Cells that are not merged have both spans at 1.
///
/// JSON (every key is optional; default values are omitted when writing):
///
/// ```json
/// {"text": "…", "rowSpan": 2, "columnSpan": 1, "covered": true,
///  "fillColor": 4294967295, "textColor": 4278190080, "bold": true,
///  "align": "start|center|end"}
/// ```
///
/// Colours are 32-bit ARGB integers. A document that is not an object, a
/// missing key or a wrongly typed value falls back to the default; spans below 1
/// become 1 (spans that leave the grid are cut by the table that owns the cell).
@immutable
class NoteTableCell {
  /// Creates a cell. [rowSpan] and [columnSpan] must be at least 1.
  const NoteTableCell({
    this.text = '',
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.fillColor,
    this.textColor,
    this.bold = false,
    this.align = NoteTableCellAlign.start,
    this.covered = false,
  }) : assert(rowSpan >= 1, 'rowSpan must be at least 1'),
       assert(columnSpan >= 1, 'columnSpan must be at least 1');

  /// Reads a cell from its JSON form; never throws.
  factory NoteTableCell.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return empty;

    return NoteTableCell(
      text: NoteJson.string(json, 'text'),
      rowSpan: math.max(1, NoteJson.integer(json, 'rowSpan', 1)),
      columnSpan: math.max(1, NoteJson.integer(json, 'columnSpan', 1)),
      fillColor: _colorOrNull(json['fillColor']),
      textColor: _colorOrNull(json['textColor']),
      bold: NoteJson.boolean(json, 'bold'),
      align: NoteJson.enumByName(
        NoteTableCellAlign.values,
        json['align'],
        NoteTableCellAlign.start,
      ),
      covered: NoteJson.boolean(json, 'covered'),
    );
  }

  /// A blank, unmerged cell with default formatting.
  static const NoteTableCell empty = NoteTableCell();

  /// The canonical filler of the positions hidden by a merge.
  static const NoteTableCell coveredCell = NoteTableCell(covered: true);

  /// The cell's text; may contain line breaks. Empty means no text.
  final String text;

  /// Number of rows this anchor occupies (at least 1).
  final int rowSpan;

  /// Number of columns this anchor occupies (at least 1).
  final int columnSpan;

  /// Background colour of this cell, or `null` for none (the header fill of the
  /// table style still applies in the first row).
  final Color? fillColor;

  /// Text colour, or `null` to use the table style's text colour.
  final Color? textColor;

  /// Whether the text is drawn bold.
  final bool bold;

  /// Horizontal alignment of the text.
  final NoteTableCellAlign align;

  /// Whether this position is hidden because a merged region covers it.
  final bool covered;

  /// A copy with the given fields replaced. `null` keeps a field; pass
  /// [clearFillColor] / [clearTextColor] to reset a colour to `null`.
  NoteTableCell copyWith({
    String? text,
    int? rowSpan,
    int? columnSpan,
    Color? fillColor,
    Color? textColor,
    bool? bold,
    NoteTableCellAlign? align,
    bool? covered,
    bool clearFillColor = false,
    bool clearTextColor = false,
  }) => NoteTableCell(
    text: text ?? this.text,
    rowSpan: rowSpan ?? this.rowSpan,
    columnSpan: columnSpan ?? this.columnSpan,
    fillColor: clearFillColor ? null : fillColor ?? this.fillColor,
    textColor: clearTextColor ? null : textColor ?? this.textColor,
    bold: bold ?? this.bold,
    align: align ?? this.align,
    covered: covered ?? this.covered,
  );

  /// The JSON form documented on the class.
  JsonMap toJson() => {
    if (text.isNotEmpty) 'text': text,
    if (rowSpan != 1) 'rowSpan': rowSpan,
    if (columnSpan != 1) 'columnSpan': columnSpan,
    if (covered) 'covered': true,
    if (fillColor case final color?) 'fillColor': NoteJson.colorToJson(color),
    if (textColor case final color?) 'textColor': NoteJson.colorToJson(color),
    if (bold) 'bold': true,
    if (align != NoteTableCellAlign.start) 'align': align.name,
  };

  static Color? _colorOrNull(Object? value) => value is num && value.isFinite
      ? NoteJson.colorFromJson(value, const Color(0xFF000000))
      : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTableCell &&
          other.text == text &&
          other.rowSpan == rowSpan &&
          other.columnSpan == columnSpan &&
          other.fillColor == fillColor &&
          other.textColor == textColor &&
          other.bold == bold &&
          other.align == align &&
          other.covered == covered;

  @override
  int get hashCode => Object.hash(
    text,
    rowSpan,
    columnSpan,
    fillColor,
    textColor,
    bold,
    align,
    covered,
  );

  @override
  String toString() => covered
      ? 'NoteTableCell(covered)'
      : 'NoteTableCell("$text", $rowSpan x $columnSpan)';
}
