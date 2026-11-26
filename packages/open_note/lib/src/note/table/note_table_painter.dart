import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:open_note/src/note/table/note_table_cell.dart';
import 'package:open_note/src/note/table/note_table_layout.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_range.dart';
import 'package:open_note/src/note/table/note_table_strings.dart';
import 'package:open_note/src/note/table/note_table_style.dart';

/// Draws a table: fills, cell text, then grid lines. It has no background of its
/// own, so the page shows through cells without a fill.
///
/// The widget view and `NoteTableObject.paintToCanvas` share [paintTable], so
/// the screen and an export look the same. Text never follows the platform's
/// text scale: table content is page content.
class NoteTablePainter extends CustomPainter {
  /// A painter that fills its canvas with [table]. Cells are exposed to
  /// accessibility with labels from [strings].
  const NoteTablePainter({
    required this.table,
    this.textDirection = TextDirection.ltr,
    this.hiddenTextCell,
    this.selection,
    this.strings = const NoteTableStrings(),
    this.onCellTap,
  });

  /// Paints [table] inside [rect]. [hiddenTextCell] is the anchor whose text is
  /// left out (the view does that for the cell being edited).
  static void paintTable(
    Canvas canvas,
    Rect rect,
    NoteTableObject table, {
    TextDirection textDirection = TextDirection.ltr,
    ({int row, int column})? hiddenTextCell,
  }) {
    final layout = NoteTableLayout(table, rect);
    _paintFills(canvas, layout);
    for (var row = 0; row < table.rowCount; row++) {
      for (var column = 0; column < table.columnCount; column++) {
        final cell = table.cellAt(row, column);
        if (cell.covered || cell.text.isEmpty) continue;
        if (hiddenTextCell == (row: row, column: column)) continue;
        _paintText(canvas, layout.cellRect(row, column), (
          style: table.style,
          cell: cell,
          direction: textDirection,
        ));
      }
    }
    _paintBorders(canvas, layout);
  }

  /// The text style of [cell] in a table styled by [style]; the cell editor uses
  /// it too.
  static TextStyle textStyleFor(NoteTableStyle style, NoteTableCell cell) =>
      TextStyle(
        color: cell.textColor ?? style.textColor,
        fontSize: style.fontSize,
        fontWeight: cell.bold ? FontWeight.w700 : FontWeight.w400,
      );

  /// The Flutter alignment for [align].
  static TextAlign textAlignFor(NoteTableCellAlign align) => switch (align) {
    NoteTableCellAlign.start => TextAlign.start,
    NoteTableCellAlign.center => TextAlign.center,
    NoteTableCellAlign.end => TextAlign.end,
  };

  /// The space between the border of a cell of size [rect] and its text:
  /// [padding], reduced to a quarter of the cell's smaller side for tiny cells.
  static double paddingFor(Rect rect, double padding) =>
      math.max(0, math.min(padding, math.min(rect.width, rect.height) / 4));

  /// The table to draw.
  final NoteTableObject table;

  /// Reading direction of cell text and of `start` / `end` alignment.
  final TextDirection textDirection;

  /// Anchor of the cell whose text is not drawn.
  final ({int row, int column})? hiddenTextCell;

  /// Selected cells, reported to accessibility.
  final NoteTableRange? selection;

  /// Accessibility labels.
  final NoteTableStrings strings;

  /// Called with the position of a cell activated through accessibility; `null`
  /// makes cells read-only for assistive technology.
  final void Function(int row, int column)? onCellTap;

  @override
  void paint(Canvas canvas, Size size) => paintTable(
    canvas,
    Offset.zero & size,
    table,
    textDirection: textDirection,
    hiddenTextCell: hiddenTextCell,
  );

  @override
  SemanticsBuilderCallback get semanticsBuilder => _semantics;

  @override
  bool shouldRepaint(NoteTablePainter oldDelegate) =>
      oldDelegate.table != table ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.hiddenTextCell != hiddenTextCell;

  @override
  bool shouldRebuildSemantics(NoteTablePainter oldDelegate) =>
      oldDelegate.table != table ||
      oldDelegate.selection != selection ||
      oldDelegate.textDirection != textDirection ||
      !identical(oldDelegate.strings, strings) ||
      (oldDelegate.onCellTap == null) != (onCellTap == null);

  List<CustomPainterSemantics> _semantics(Size size) {
    final layout = NoteTableLayout(table, Offset.zero & size);

    return [
      for (var row = 0; row < table.rowCount; row++)
        for (var column = 0; column < table.columnCount; column++)
          if (!table.cellAt(row, column).covered)
            CustomPainterSemantics(
              key: ValueKey<String>('note-table-cell-$row-$column'),
              rect: layout.cellRect(row, column),
              properties: _cellProperties(row, column),
            ),
    ];
  }

  SemanticsProperties _cellProperties(int row, int column) {
    final tap = onCellTap;

    return SemanticsProperties(
      label: strings.cellLabel(row + 1, column + 1),
      value: table.cellAt(row, column).text,
      selected: selection?.contains(row, column) ?? false,
      textDirection: textDirection,
      onTap: tap == null ? null : () => tap(row, column),
    );
  }

  static void _paintFills(Canvas canvas, NoteTableLayout layout) {
    final table = layout.table;
    final style = table.style;
    for (var row = 0; row < table.rowCount; row++) {
      for (var column = 0; column < table.columnCount; column++) {
        final cell = table.cellAt(row, column);
        if (cell.covered) continue;
        final header = style.headerRow && row == 0 ? style.headerFill : null;
        final fill = cell.fillColor ?? header;
        if (fill == null) continue;
        canvas.drawRect(layout.cellRect(row, column), Paint()..color = fill);
      }
    }
  }

  static void _paintText(
    Canvas canvas,
    Rect rect,
    ({NoteTableStyle style, NoteTableCell cell, TextDirection direction}) text,
  ) {
    final inner = rect.deflate(paddingFor(rect, text.style.cellPadding));
    if (inner.width <= 0 || inner.height <= 0) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text.cell.text,
        style: textStyleFor(text.style, text.cell),
      ),
      textAlign: textAlignFor(text.cell.align),
      textDirection: text.direction,
    )..layout(minWidth: inner.width, maxWidth: inner.width);
    // Centred vertically; text taller than the cell starts at the top.
    final offset = math.max(0.0, (inner.height - painter.height) / 2);
    canvas
      ..save()
      ..clipRect(rect);
    painter.paint(canvas, inner.topLeft + Offset(0, offset));
    canvas.restore();
    painter.dispose();
  }

  /// Draws every grid line once: the top and left edge of each region plus the
  /// outer right and bottom edges, as one path (translucent borders do not
  /// darken where lines meet).
  static void _paintBorders(Canvas canvas, NoteTableLayout layout) {
    final table = layout.table;
    final width = table.style.borderWidth;
    if (width <= 0) return;
    final grid = layout.gridRect;
    final path = Path()
      ..moveTo(grid.right, grid.top)
      ..lineTo(grid.right, grid.bottom)
      ..moveTo(grid.left, grid.bottom)
      ..lineTo(grid.right, grid.bottom);
    for (var row = 0; row < table.rowCount; row++) {
      for (var column = 0; column < table.columnCount; column++) {
        if (table.cellAt(row, column).covered) continue;
        final rect = layout.cellRect(row, column);
        path
          ..moveTo(rect.left, rect.bottom)
          ..lineTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.square
        ..color = table.style.borderColor,
    );
  }
}
