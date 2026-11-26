import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/table/note_table_cell.dart';
import 'package:open_note/src/note/table/note_table_fractions.dart';
import 'package:open_note/src/note/table/note_table_grid.dart';
import 'package:open_note/src/note/table/note_table_painter.dart';
import 'package:open_note/src/note/table/note_table_range.dart';
import 'package:open_note/src/note/table/note_table_style.dart';

/// A table on a note page: a grid of [rowCount] x [columnCount] cells laid out
/// inside [bounds].
///
/// Column widths and row heights are fractions of the table's size that each sum
/// to 1; no fraction is below [minimumFractionFor] the number of entries. Cells
/// are stored row-major; a merged region is held by its top-left anchor cell and
/// every other position of it is [NoteTableCell.coveredCell]. Every instance
/// satisfies these rules: the constructors repair inconsistent input.
///
/// Every operation returns a new table and leaves this one untouched. An
/// operation that changes nothing (an index out of range, merging a single cell,
/// deleting the last row…) returns `this`. Operations never change [bounds]: the
/// new set of fractions is spread over the same size, so a host that wants a
/// taller table after inserting a row resizes it itself.
///
/// JSON payload (the shared object fields are written by [toJson]):
///
/// ```json
/// {"rows": 2, "columns": 3, "columnWidths": [0.5, 0.25, 0.25],
///  "rowHeights": [0.5, 0.5], "cells": [{…NoteTableCell…}, …rows*columns],
///  "style": {…NoteTableStyle…}}
/// ```
///
/// [fromPayload] never throws: counts are clamped to 1…[maxRows] and
/// 1…[maxColumns] (read from the lists when missing), fraction lists of the wrong
/// length become equal fractions, missing or malformed cells are blank and
/// inconsistent spans are cut.
@immutable
class NoteTableObject extends NoteObject {
  /// Creates a table with `rowHeights.length` rows and `columnWidths.length`
  /// columns (clamped to 1…[maxRows] and 1…[maxColumns]).
  ///
  /// [cells] is row-major; missing entries are blank and extra ones ignored. The
  /// fraction lists and cell spans are normalised.
  factory NoteTableObject({
    required String id,
    required Rect bounds,
    required List<double> columnWidths,
    required List<double> rowHeights,
    List<NoteTableCell> cells = const [],
    NoteTableStyle style = const NoteTableStyle(),
    double rotation = 0,
    double opacity = 1,
    bool locked = false,
  }) {
    final rows = rowHeights.length.clamp(1, maxRows);
    final columns = columnWidths.length.clamp(1, maxColumns);

    return NoteTableObject._(
      id: id,
      bounds: bounds,
      rotation: rotation,
      opacity: opacity,
      locked: locked,
      columnWidths: NoteTableFractions.normalize(
        columnWidths.take(columns).toList(),
        columns,
      ),
      rowHeights: NoteTableFractions.normalize(
        rowHeights.take(rows).toList(),
        rows,
      ),
      grid: NoteTableCellGrid.sanitized(rows, columns, cells),
      style: style,
    );
  }

  /// A blank table of [rows] x [columns] equal cells (both clamped to their
  /// limits).
  factory NoteTableObject.grid({
    required String id,
    required Rect bounds,
    int rows = 3,
    int columns = 3,
    NoteTableStyle style = const NoteTableStyle(),
  }) => NoteTableObject(
    id: id,
    bounds: bounds,
    rowHeights: NoteTableFractions.equal(rows.clamp(1, maxRows)),
    columnWidths: NoteTableFractions.equal(columns.clamp(1, maxColumns)),
    style: style,
  );

  NoteTableObject._({
    required super.id,
    required super.bounds,
    required List<double> columnWidths,
    required List<double> rowHeights,
    required NoteTableCellGrid grid,
    required this.style,
    super.rotation,
    super.opacity,
    super.locked,
  }) : columnWidths = List<double>.unmodifiable(columnWidths),
       rowHeights = List<double>.unmodifiable(rowHeights),
       _grid = grid;

  /// The persisted `kind` of tables.
  static const String kindName = 'table';

  /// Largest number of rows.
  static const int maxRows = 100;

  /// Largest number of columns.
  static const int maxColumns = 50;

  /// Smallest width or height fraction in tables of up to 20 columns or rows.
  static const double minFraction = NoteTableFractions.minimum;

  /// The smallest fraction allowed among [count] rows or columns: [minFraction],
  /// or half an equal share when [count] is above 20.
  static double minimumFractionFor(int count) =>
      NoteTableFractions.minimumFor(count);

  /// Rebuilds a table from its shared [base] fields and JSON [payload]; never
  /// throws. This is the decoder registered by `registerNoteTableObject`.
  static NoteTableObject fromPayload(NoteObjectBase base, JsonMap payload) {
    final widths = _shares(NoteJson.list(payload, 'columnWidths'));
    final heights = _shares(NoteJson.list(payload, 'rowHeights'));
    final declaredRows = _count(payload, 'rows', heights.length);
    final declaredColumns = _count(payload, 'columns', widths.length);
    final rows = math.min(declaredRows, maxRows);
    final columns = math.min(declaredColumns, maxColumns);
    final stored = NoteJson.list(payload, 'cells');

    return NoteTableObject._(
      id: base.id,
      bounds: base.bounds,
      rotation: base.rotation,
      opacity: base.opacity,
      locked: base.locked,
      columnWidths: NoteTableFractions.normalize(
        widths.take(columns).toList(),
        columns,
      ),
      rowHeights: NoteTableFractions.normalize(
        heights.take(rows).toList(),
        rows,
      ),
      grid: NoteTableCellGrid.sanitized(rows, columns, [
        for (var row = 0; row < rows; row++)
          for (var column = 0; column < columns; column++)
            _storedCell(stored, row * declaredColumns + column),
      ]),
      style: NoteTableStyle.fromJson(payload['style']),
    );
  }

  /// Column widths as fractions of the table width, left to right;
  /// unmodifiable.
  final List<double> columnWidths;

  /// Row heights as fractions of the table height, top to bottom; unmodifiable.
  final List<double> rowHeights;

  /// Borders, header row and text defaults.
  final NoteTableStyle style;

  final NoteTableCellGrid _grid;

  /// Number of rows (at least 1).
  int get rowCount => _grid.rows;

  /// Number of columns (at least 1).
  int get columnCount => _grid.columns;

  /// All positions in row-major order (`cells[row * columnCount + column]`);
  /// unmodifiable.
  List<NoteTableCell> get cells => _grid.cells;

  /// The stored cell at ([row], [column]) ([NoteTableCell.coveredCell] for a
  /// position hidden by a merge). Throws a [RangeError] outside the grid.
  NoteTableCell cellAt(int row, int column) {
    _checkPosition(row, column);

    return _grid.cellAt(row, column);
  }

  /// The position of the anchor cell that shows at ([row], [column]) — itself
  /// unless the position is covered. Throws a [RangeError] outside the grid.
  ({int row, int column}) anchorOf(int row, int column) {
    _checkPosition(row, column);

    return _grid.anchorOf(row, column);
  }

  /// The merged region (or single cell) that shows at ([row], [column]). Throws
  /// a [RangeError] outside the grid.
  NoteTableRange rangeAt(int row, int column) {
    _checkPosition(row, column);

    return _grid.rangeAt(row, column);
  }

  /// [range] brought inside the grid and grown until it cuts no merged region
  /// (this is what a selection looks like).
  NoteTableRange expandToMerges(NoteTableRange range) => _grid.expand(range);

  /// Whether [mergeCells] with [range] would change the table, that is, the
  /// expanded range is larger than a single region.
  bool canMerge(NoteTableRange range) {
    final expanded = expandToMerges(range);

    return expanded != _grid.rangeAt(expanded.firstRow, expanded.firstColumn);
  }

  /// A table with a blank row inserted before row [at]. [at] is clamped to
  /// 0…[rowCount] (`rowCount` appends). The new row copies the height fraction of
  /// the row above (of the first row when [at] is 0), then all heights are
  /// rescaled. A merge that crosses the insertion line grows by one row. No-op at
  /// [maxRows].
  NoteTableObject insertRow(int at) {
    if (rowCount >= maxRows) return this;
    final index = at.clamp(0, rowCount);

    return _with(
      rowHeights: NoteTableFractions.insert(rowHeights, index),
      grid: _grid.insertRow(index),
    );
  }

  /// A table with a blank column inserted before column [at]; the column
  /// counterpart of [insertRow]. No-op at [maxColumns].
  NoteTableObject insertColumn(int at) {
    if (columnCount >= maxColumns) return this;
    final index = at.clamp(0, columnCount);

    return _with(
      columnWidths: NoteTableFractions.insert(columnWidths, index),
      grid: _grid.transposed.insertRow(index).transposed,
    );
  }

  /// A table without row [index]; its fraction is shared among the others.
  /// Merges through the row shrink; a merge starting on it keeps its content one
  /// row down. The text of single-row cells in the row is dropped. No-op for an
  /// index out of range or when only one row is left.
  NoteTableObject deleteRow(int index) {
    if (rowCount <= 1 || index < 0 || index >= rowCount) return this;

    return _with(
      rowHeights: NoteTableFractions.removeAt(rowHeights, index),
      grid: _grid.removeRow(index),
    );
  }

  /// A table without column [index]; the column counterpart of [deleteRow].
  NoteTableObject deleteColumn(int index) {
    if (columnCount <= 1 || index < 0 || index >= columnCount) return this;

    return _with(
      columnWidths: NoteTableFractions.removeAt(columnWidths, index),
      grid: _grid.transposed.removeRow(index).transposed,
    );
  }

  /// A table where [range] — first clamped to the grid and grown to contain
  /// every merge it cuts — is one merged cell. It keeps the formatting of the
  /// top-left cell; its text is every non-empty text of the range in row-major
  /// order, joined by line breaks, so merging loses no text. No-op when the
  /// grown range is already a single region (see [canMerge]).
  NoteTableObject mergeCells(NoteTableRange range) {
    if (!canMerge(range)) return this;

    return _with(grid: _grid.merge(expandToMerges(range)));
  }

  /// A table where the merged region showing at ([row], [column]) — which may be
  /// a covered position — is split into single cells. The top-left keeps the
  /// content; the others are blank with the same formatting. No-op for a cell
  /// that is not merged or a position outside the grid.
  NoteTableObject splitCell(int row, int column) {
    if (!_isInside(row, column) || _grid.rangeAt(row, column).isSingleCell) {
      return this;
    }

    return _with(grid: _grid.split(row, column));
  }

  /// A table where the cell showing at ([row], [column]) has [text]. A covered
  /// position edits its anchor. No-op outside the grid.
  NoteTableObject setCellText(int row, int column, String text) {
    if (!_isInside(row, column)) return this;
    final anchor = _grid.anchorOf(row, column);
    final cell = _grid.cellAt(anchor.row, anchor.column);

    return setCell(row, column, cell.copyWith(text: text));
  }

  /// A table where the cell showing at ([row], [column]) takes the content and
  /// formatting of [cell]. The spans and covered flag of [cell] are ignored:
  /// only [mergeCells] and [splitCell] change the structure. No-op outside the
  /// grid.
  NoteTableObject setCell(int row, int column, NoteTableCell cell) {
    if (!_isInside(row, column)) return this;
    final anchor = _grid.anchorOf(row, column);
    final next = _grid.replace(row, column, cell);
    final before = _grid.cellAt(anchor.row, anchor.column);
    if (next.cellAt(anchor.row, anchor.column) == before) return this;

    return _with(grid: next);
  }

  /// A table where column [index] has the width [fraction]. The next column (the
  /// previous one for the last) absorbs the difference, so only those two
  /// change; neither goes below [minimumFractionFor] [columnCount]. No-op for an
  /// index out of range, a single column or a [fraction] that is not finite.
  NoteTableObject setColumnWidth(int index, double fraction) {
    final widths = NoteTableFractions.resize(columnWidths, index, fraction);

    return identical(widths, columnWidths) ? this : _with(columnWidths: widths);
  }

  /// A table where row [index] has the height [fraction]; the row counterpart of
  /// [setColumnWidth].
  NoteTableObject setRowHeight(int index, double fraction) {
    final heights = NoteTableFractions.resize(rowHeights, index, fraction);

    return identical(heights, rowHeights) ? this : _with(rowHeights: heights);
  }

  /// A table of [rows] x [columns] (clamped to the limits): rows and columns are
  /// appended with [insertRow] / [insertColumn] or removed from the end with
  /// [deleteRow] / [deleteColumn].
  NoteTableObject withSize(int rows, int columns) {
    final targetRows = rows.clamp(1, maxRows);
    final targetColumns = columns.clamp(1, maxColumns);
    var result = this;
    while (result.rowCount < targetRows) {
      result = result.insertRow(result.rowCount);
    }
    while (result.rowCount > targetRows) {
      result = result.deleteRow(result.rowCount - 1);
    }
    while (result.columnCount < targetColumns) {
      result = result.insertColumn(result.columnCount);
    }
    while (result.columnCount > targetColumns) {
      result = result.deleteColumn(result.columnCount - 1);
    }

    return result;
  }

  /// A copy with the given fields replaced. It cannot change the number of rows
  /// or columns: fraction lists of another length are ignored (use [withSize] or
  /// the insert/delete operations). Fractions and [cells] are normalised as in
  /// the constructor.
  NoteTableObject copyWith({
    String? id,
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    List<double>? columnWidths,
    List<double>? rowHeights,
    List<NoteTableCell>? cells,
    NoteTableStyle? style,
  }) {
    final widths = columnWidths?.length == columnCount ? columnWidths : null;
    final heights = rowHeights?.length == rowCount ? rowHeights : null;

    return NoteTableObject(
      id: id ?? this.id,
      bounds: bounds ?? this.bounds,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      locked: locked ?? this.locked,
      columnWidths: widths ?? this.columnWidths,
      rowHeights: heights ?? this.rowHeights,
      cells: cells ?? this.cells,
      style: style ?? this.style,
    );
  }

  @override
  String get kind => kindName;

  @override
  NoteTableObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => _with(
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
  );

  @override
  JsonMap payloadToJson() => {
    'rows': rowCount,
    'columns': columnCount,
    'columnWidths': columnWidths,
    'rowHeights': rowHeights,
    'cells': [for (final cell in cells) cell.toJson()],
    'style': style.toJson(),
  };

  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) =>
      NoteTablePainter.paintTable(canvas, bounds, this);

  NoteTableObject _with({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    List<double>? columnWidths,
    List<double>? rowHeights,
    NoteTableCellGrid? grid,
  }) => NoteTableObject._(
    id: id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    columnWidths: columnWidths ?? this.columnWidths,
    rowHeights: rowHeights ?? this.rowHeights,
    grid: grid ?? _grid,
    style: style,
  );

  bool _isInside(int row, int column) =>
      row >= 0 && row < rowCount && column >= 0 && column < columnCount;

  void _checkPosition(int row, int column) {
    RangeError.checkValidIndex(row, rowHeights, 'row');
    RangeError.checkValidIndex(column, columnWidths, 'column');
  }

  /// The row or column count stored under [key], at least 1 and at most 2^20
  /// (so that index arithmetic cannot overflow).
  static int _count(JsonMap payload, String key, int fallback) =>
      NoteJson.integer(payload, key, fallback).clamp(1, 1 << 20);

  static List<double> _shares(List<Object?> raw) => [
    for (final value in raw)
      value is num && value.isFinite ? value.toDouble() : double.nan,
  ];

  static NoteTableCell _storedCell(List<Object?> stored, int index) =>
      index < stored.length
      ? NoteTableCell.fromJson(stored[index])
      : NoteTableCell.empty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTableObject &&
          other.id == id &&
          other.bounds == bounds &&
          other.rotation == rotation &&
          other.opacity == opacity &&
          other.locked == locked &&
          other.style == style &&
          listEquals(other.columnWidths, columnWidths) &&
          listEquals(other.rowHeights, rowHeights) &&
          listEquals(other.cells, cells);

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    style,
    Object.hashAll(columnWidths),
    Object.hashAll(rowHeights),
    Object.hashAll(cells),
  );

  @override
  String toString() => 'NoteTableObject($id, $rowCount x $columnCount)';
}
