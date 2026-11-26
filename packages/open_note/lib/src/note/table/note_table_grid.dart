import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/table/note_table_cell.dart';
import 'package:open_note/src/note/table/note_table_range.dart';

/// A merged (or single) region of a grid together with the cell that holds its
/// content.
typedef NoteTableRegion = ({NoteTableRange range, NoteTableCell cell});

/// A `rows x columns` matrix of cells that always satisfies the structural
/// invariants of a table: it is rectangular, merged regions never overlap or
/// leave the grid, every position of a region except its top-left anchor holds
/// [NoteTableCell.coveredCell], and no other position is covered.
///
/// Internal to the table module (not exported by the barrel); `NoteTableObject`
/// is the public face. Every operation returns a new grid.
@immutable
class NoteTableCellGrid {
  NoteTableCellGrid._(
    this.rows,
    this.columns,
    List<NoteTableCell> cells,
    this._owners,
  ) : cells = List<NoteTableCell>.unmodifiable(cells);

  /// A grid of [rows] x [columns] (both at least 1) built from row-major
  /// [cells], repairing whatever is inconsistent: missing cells are blank and
  /// extra ones are dropped; spans are cut at the grid edge and where they would
  /// overlap an earlier region (earlier in row-major order wins); a covered flag
  /// that no region claims is dropped together with the spans of that cell.
  factory NoteTableCellGrid.sanitized(
    int rows,
    int columns,
    List<NoteTableCell> cells,
  ) {
    final claimed = List<bool>.filled(rows * columns, false);
    final regions = <NoteTableRegion>[];
    for (var index = 0; index < rows * columns; index++) {
      if (claimed[index]) continue;
      final cell = index < cells.length ? cells[index] : NoteTableCell.empty;
      final row = index ~/ columns;
      final column = index % columns;
      final range = _largestFreeRange(
        claimed,
        columns,
        NoteTableRange.cell(row, column),
        cell.covered ? 1 : cell.rowSpan.clamp(1, rows - row),
        cell.covered ? 1 : cell.columnSpan.clamp(1, columns - column),
      );
      _forEach(range, (r, c) => claimed[r * columns + c] = true);
      regions.add((range: range, cell: cell));
    }

    return _fromRegions(rows, columns, regions);
  }

  /// Number of rows (at least 1).
  final int rows;

  /// Number of columns (at least 1).
  final int columns;

  /// All positions in row-major order (`cells[row * columns + column]`);
  /// unmodifiable.
  final List<NoteTableCell> cells;

  /// For every position, the index of the anchor whose region holds it.
  final List<int> _owners;

  /// The stored cell at ([row], [column]), which is
  /// [NoteTableCell.coveredCell] for hidden positions.
  NoteTableCell cellAt(int row, int column) => cells[row * columns + column];

  /// The anchor of the region that holds ([row], [column]).
  ({int row, int column}) anchorOf(int row, int column) {
    final owner = _owners[row * columns + column];

    return (row: owner ~/ columns, column: owner % columns);
  }

  /// The merged (or single) region that holds ([row], [column]).
  NoteTableRange rangeAt(int row, int column) {
    final anchor = anchorOf(row, column);
    final cell = cellAt(anchor.row, anchor.column);

    return NoteTableRange(
      firstRow: anchor.row,
      firstColumn: anchor.column,
      lastRow: anchor.row + cell.rowSpan - 1,
      lastColumn: anchor.column + cell.columnSpan - 1,
    );
  }

  /// Every region in row-major order of its anchor.
  List<NoteTableRegion> get regions => [
    for (var index = 0; index < cells.length; index++)
      if (_owners[index] == index)
        (range: rangeAt(index ~/ columns, index % columns), cell: cells[index]),
  ];

  /// This grid with rows and columns swapped.
  NoteTableCellGrid get transposed => _fromRegions(columns, rows, [
    for (final region in regions)
      (range: region.range.transposed, cell: region.cell),
  ]);

  /// [range] brought inside the grid and grown until it cuts no merged region.
  NoteTableRange expand(NoteTableRange range) {
    var current = range.clampTo(rows, columns);
    while (true) {
      var grown = current;
      _forEach(current, (r, c) => grown = grown.union(rangeAt(r, c)));
      if (grown == current) return current;
      current = grown;
    }
  }

  /// A grid with a blank row before row [at] (`at == rows` appends). A region
  /// that spans the insertion line grows by one row.
  NoteTableCellGrid insertRow(int at) => _fromRegions(rows + 1, columns, [
    for (final region in regions)
      (range: _afterInsert(region.range, at), cell: region.cell),
  ]);

  /// A grid without row [index]. Regions through the row shrink; a region
  /// anchored on it keeps its content one row down; single-row regions of that
  /// row disappear. The grid must have at least two rows.
  NoteTableCellGrid removeRow(int index) => _fromRegions(rows - 1, columns, [
    for (final region in regions)
      if (region.range.rowCount > 1 || region.range.firstRow != index)
        (range: _afterRemove(region.range, index), cell: region.cell),
  ]);

  /// A grid where [range], which must already be [expand]ed, is one region. It
  /// keeps the formatting of its top-left cell; its text is the non-empty texts
  /// of the merged cells in row-major order, joined by line breaks.
  NoteTableCellGrid merge(NoteTableRange range) {
    final all = regions;
    final text = [
      for (final region in all)
        if (range.containsRange(region.range) && region.cell.text.isNotEmpty)
          region.cell.text,
    ].join('\n');
    final anchor = cellAt(range.firstRow, range.firstColumn);

    return _fromRegions(rows, columns, [
      for (final region in all)
        if (!range.containsRange(region.range)) region,
      (range: range, cell: anchor.copyWith(text: text)),
    ]);
  }

  /// A grid where the region holding ([row], [column]) is split into single
  /// cells. The top-left keeps the content; the others are blank copies with the
  /// same formatting.
  NoteTableCellGrid split(int row, int column) {
    final target = rangeAt(row, column);
    final content = cellAt(target.firstRow, target.firstColumn);
    final blank = content.copyWith(text: '');
    final singles = <NoteTableRegion>[];
    _forEach(target, (r, c) {
      final first = r == target.firstRow && c == target.firstColumn;
      singles.add((
        range: NoteTableRange.cell(r, c),
        cell: first ? content : blank,
      ));
    });

    return _fromRegions(rows, columns, [
      for (final region in regions)
        if (region.range != target) region,
      ...singles,
    ]);
  }

  /// A grid where the region holding ([row], [column]) has the content and
  /// formatting of [cell]; spans and the covered flag of [cell] are ignored.
  NoteTableCellGrid replace(int row, int column, NoteTableCell cell) {
    return _fromRegions(rows, columns, [
      for (final region in regions)
        (
          range: region.range,
          cell: region.range.contains(row, column) ? cell : region.cell,
        ),
    ]);
  }

  /// Assembles a grid from non-overlapping [regions]. Positions no region holds
  /// stay blank single cells. Spans and covered flags come from the ranges.
  static NoteTableCellGrid _fromRegions(
    int rows,
    int columns,
    List<NoteTableRegion> regions,
  ) {
    final cells = List<NoteTableCell>.filled(
      rows * columns,
      NoteTableCell.empty,
    );
    final owners = List<int>.generate(rows * columns, (index) => index);
    for (final region in regions) {
      final range = region.range;
      final anchor = range.firstRow * columns + range.firstColumn;
      _forEach(range, (r, c) {
        owners[r * columns + c] = anchor;
        cells[r * columns + c] = NoteTableCell.coveredCell;
      });
      cells[anchor] = region.cell.copyWith(
        rowSpan: range.rowCount,
        columnSpan: range.columnCount,
        covered: false,
      );
    }

    return NoteTableCellGrid._(rows, columns, cells, owners);
  }

  static void _forEach(NoteTableRange range, void Function(int, int) visit) {
    for (var r = range.firstRow; r <= range.lastRow; r++) {
      for (var c = range.firstColumn; c <= range.lastColumn; c++) {
        visit(r, c);
      }
    }
  }

  /// The largest rectangle at [origin], at most [height] x [width], made of
  /// positions that no region claimed yet; its width is chosen first.
  static NoteTableRange _largestFreeRange(
    List<bool> claimed,
    int columns,
    NoteTableRange origin,
    int height,
    int width,
  ) {
    final row = origin.firstRow;
    final column = origin.firstColumn;
    var columnsFree = 1;
    while (columnsFree < width &&
        !claimed[row * columns + column + columnsFree]) {
      columnsFree++;
    }
    var rowsFree = 1;
    while (rowsFree < height &&
        !claimed
            .skip((row + rowsFree) * columns + column)
            .take(columnsFree)
            .contains(true)) {
      rowsFree++;
    }

    return NoteTableRange(
      firstRow: row,
      firstColumn: column,
      lastRow: row + rowsFree - 1,
      lastColumn: column + columnsFree - 1,
    );
  }

  static NoteTableRange _afterInsert(NoteTableRange range, int at) {
    if (at <= range.firstRow) return range.shift(rows: 1);
    if (at <= range.lastRow) return range.copyWith(lastRow: range.lastRow + 1);

    return range;
  }

  static NoteTableRange _afterRemove(NoteTableRange range, int index) {
    return NoteTableRange(
      firstRow: range.firstRow > index ? range.firstRow - 1 : range.firstRow,
      firstColumn: range.firstColumn,
      lastRow: range.lastRow >= index ? range.lastRow - 1 : range.lastRow,
      lastColumn: range.lastColumn,
    );
  }
}
