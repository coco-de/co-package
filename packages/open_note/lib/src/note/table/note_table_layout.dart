import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_range.dart';

/// Where the cells of a table are inside a rectangle: used by the painter, by
/// hit testing and by anything that draws over a table (selection, editors,
/// resize handles).
///
/// The grid is inset by half the border width on every side, so border strokes
/// centred on the grid lines stay inside the rectangle.
@immutable
class NoteTableLayout {
  /// Lays out [table] inside [rect].
  factory NoteTableLayout(NoteTableObject table, Rect rect) {
    final inset = table.style.borderWidth / 2;
    final horizontal = math.max(0.0, math.min(inset, rect.width / 2));
    final vertical = math.max(0.0, math.min(inset, rect.height / 2));

    return NoteTableLayout._(
      table,
      _edges(
        rect.left + horizontal,
        math.max(0, rect.width - 2 * horizontal),
        table.columnWidths,
      ),
      _edges(
        rect.top + vertical,
        math.max(0, rect.height - 2 * vertical),
        table.rowHeights,
      ),
    );
  }

  const NoteTableLayout._(this.table, this.columnEdges, this.rowEdges);

  /// The table being laid out.
  final NoteTableObject table;

  /// The x coordinate of every vertical grid line (`columnCount + 1` values).
  final List<double> columnEdges;

  /// The y coordinate of every horizontal grid line (`rowCount + 1` values).
  final List<double> rowEdges;

  /// The rectangle covered by the grid lines.
  Rect get gridRect => Rect.fromLTRB(
    columnEdges.first,
    rowEdges.first,
    columnEdges.last,
    rowEdges.last,
  );

  /// The rectangle covered by [range] (clamped to the grid).
  Rect rectOf(NoteTableRange range) {
    final inside = range.clampTo(table.rowCount, table.columnCount);

    return Rect.fromLTRB(
      columnEdges[inside.firstColumn],
      rowEdges[inside.firstRow],
      columnEdges[inside.lastColumn + 1],
      rowEdges[inside.lastRow + 1],
    );
  }

  /// The rectangle of the cell that shows at ([row], [column]), which is the
  /// whole merged region when the position belongs to one.
  Rect cellRect(int row, int column) => rectOf(table.rangeAt(row, column));

  /// The grid position under [point]; points outside the grid give the nearest
  /// edge position. A point on a line belongs to the cell after it.
  ({int row, int column}) cellAt(Offset point) => (
    row: _indexAt(rowEdges, point.dy),
    column: _indexAt(columnEdges, point.dx),
  );

  static int _indexAt(List<double> edges, double value) {
    for (var index = 1; index < edges.length - 1; index++) {
      if (value < edges[index]) return index - 1;
    }

    return edges.length - 2;
  }

  static List<double> _edges(double start, double length, List<double> shares) {
    final edges = <double>[start];
    var used = 0.0;
    for (var index = 0; index < shares.length - 1; index++) {
      used += shares[index];
      edges.add(start + used * length);
    }
    edges.add(start + length);

    return List<double>.unmodifiable(edges);
  }
}
