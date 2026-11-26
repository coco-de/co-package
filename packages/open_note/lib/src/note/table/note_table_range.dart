import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// A rectangle of grid positions, with inclusive 0-based row and column
/// indices.
///
/// The constructor normalises its input: the two corners may be given in any
/// order and negative indices become 0, so `firstRow <= lastRow` and
/// `firstColumn <= lastColumn` always hold. The range does not know the size of
/// a table; use [clampTo] to bring it inside a grid.
///
/// JSON: `{"firstRow": 0, "firstColumn": 0, "lastRow": 1, "lastColumn": 2}`.
/// Missing or wrongly typed keys read as 0 for the first indices and as the
/// first index for the last ones.
@immutable
class NoteTableRange {
  /// The rectangle spanned by two corners (both inclusive, in any order).
  const NoteTableRange({
    required int firstRow,
    required int firstColumn,
    required int lastRow,
    required int lastColumn,
  }) : firstRow = (firstRow < lastRow ? firstRow : lastRow) < 0
           ? 0
           : (firstRow < lastRow ? firstRow : lastRow),
       firstColumn = (firstColumn < lastColumn ? firstColumn : lastColumn) < 0
           ? 0
           : (firstColumn < lastColumn ? firstColumn : lastColumn),
       lastRow = (firstRow > lastRow ? firstRow : lastRow) < 0
           ? 0
           : (firstRow > lastRow ? firstRow : lastRow),
       lastColumn = (firstColumn > lastColumn ? firstColumn : lastColumn) < 0
           ? 0
           : (firstColumn > lastColumn ? firstColumn : lastColumn);

  /// The single position ([row], [column]); negative values become 0.
  const NoteTableRange.cell(int row, int column)
    : firstRow = row < 0 ? 0 : row,
      firstColumn = column < 0 ? 0 : column,
      lastRow = row < 0 ? 0 : row,
      lastColumn = column < 0 ? 0 : column;

  /// Reads a range from its JSON form; never throws.
  factory NoteTableRange.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};
    final row = NoteJson.integer(json, 'firstRow');
    final column = NoteJson.integer(json, 'firstColumn');

    return NoteTableRange(
      firstRow: row,
      firstColumn: column,
      lastRow: NoteJson.integer(json, 'lastRow', row),
      lastColumn: NoteJson.integer(json, 'lastColumn', column),
    );
  }

  /// First row of the range (inclusive).
  final int firstRow;

  /// First column of the range (inclusive).
  final int firstColumn;

  /// Last row of the range (inclusive).
  final int lastRow;

  /// Last column of the range (inclusive).
  final int lastColumn;

  /// Number of rows.
  int get rowCount => lastRow - firstRow + 1;

  /// Number of columns.
  int get columnCount => lastColumn - firstColumn + 1;

  /// Whether the range is exactly one grid position.
  bool get isSingleCell => rowCount == 1 && columnCount == 1;

  /// This range with rows and columns swapped.
  NoteTableRange get transposed => NoteTableRange(
    firstRow: firstColumn,
    firstColumn: firstRow,
    lastRow: lastColumn,
    lastColumn: lastRow,
  );

  /// Whether the position ([row], [column]) lies inside the range.
  bool contains(int row, int column) =>
      row >= firstRow &&
      row <= lastRow &&
      column >= firstColumn &&
      column <= lastColumn;

  /// Whether [other] lies completely inside this range.
  bool containsRange(NoteTableRange other) =>
      contains(other.firstRow, other.firstColumn) &&
      contains(other.lastRow, other.lastColumn);

  /// Whether the two ranges share at least one position.
  bool intersects(NoteTableRange other) =>
      firstRow <= other.lastRow &&
      other.firstRow <= lastRow &&
      firstColumn <= other.lastColumn &&
      other.firstColumn <= lastColumn;

  /// The smallest range that contains both ranges.
  NoteTableRange union(NoteTableRange other) => NoteTableRange(
    firstRow: math.min(firstRow, other.firstRow),
    firstColumn: math.min(firstColumn, other.firstColumn),
    lastRow: math.max(lastRow, other.lastRow),
    lastColumn: math.max(lastColumn, other.lastColumn),
  );

  /// This range moved by [rows] and [columns] (indices stop at 0).
  NoteTableRange shift({int rows = 0, int columns = 0}) => NoteTableRange(
    firstRow: firstRow + rows,
    firstColumn: firstColumn + columns,
    lastRow: lastRow + rows,
    lastColumn: lastColumn + columns,
  );

  /// This range with every index brought into a grid of [rows] x [columns]
  /// (both at least 1). A range entirely outside collapses onto the nearest
  /// edge cells.
  NoteTableRange clampTo(int rows, int columns) {
    final maxRow = math.max(rows - 1, 0);
    final maxColumn = math.max(columns - 1, 0);

    return NoteTableRange(
      firstRow: math.min(firstRow, maxRow),
      firstColumn: math.min(firstColumn, maxColumn),
      lastRow: math.min(lastRow, maxRow),
      lastColumn: math.min(lastColumn, maxColumn),
    );
  }

  /// A copy with the given indices replaced (and normalised again).
  NoteTableRange copyWith({
    int? firstRow,
    int? firstColumn,
    int? lastRow,
    int? lastColumn,
  }) => NoteTableRange(
    firstRow: firstRow ?? this.firstRow,
    firstColumn: firstColumn ?? this.firstColumn,
    lastRow: lastRow ?? this.lastRow,
    lastColumn: lastColumn ?? this.lastColumn,
  );

  /// The JSON form documented on the class.
  JsonMap toJson() => {
    'firstRow': firstRow,
    'firstColumn': firstColumn,
    'lastRow': lastRow,
    'lastColumn': lastColumn,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTableRange &&
          other.firstRow == firstRow &&
          other.firstColumn == firstColumn &&
          other.lastRow == lastRow &&
          other.lastColumn == lastColumn;

  @override
  int get hashCode => Object.hash(firstRow, firstColumn, lastRow, lastColumn);

  @override
  String toString() =>
      'NoteTableRange($firstRow, $firstColumn -> $lastRow, $lastColumn)';
}
