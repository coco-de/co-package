// Geometry (NoteTableLayout) and drawing (NoteTablePainter, paintToCanvas).
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import 'support/table_invariants.dart';

const _header = Color(0xFF111111);
const _border = Color(0xFF222222);
const _fill = Color(0xFF333333);

NoteTableObject _table({
  NoteTableStyle style = const NoteTableStyle(
    borderColor: _border,
    headerFill: _header,
  ),
  Rect bounds = const Rect.fromLTWH(20, 30, 200, 80),
}) => NoteTableObject.grid(
  id: 't',
  bounds: bounds,
  rows: 2,
  columns: 2,
  style: style,
);

void Function(Canvas) _painting(NoteTableObject table) =>
    (canvas) => table.paintToCanvas(canvas, NoteObjectPaintContext.empty);

/// The RGBA of a pixel after painting [table] on a 260 x 140 canvas.
Future<List<int> Function(int, int)> _rasterise(NoteTableObject table) async {
  final recorder = ui.PictureRecorder();
  table.paintToCanvas(Canvas(recorder), NoteObjectPaintContext.empty);
  final picture = recorder.endRecording();
  final image = await picture.toImage(260, 140);
  final data = (await image.toByteData())!;
  picture.dispose();
  image.dispose();

  return (x, y) => data.buffer.asUint8List((y * 260 + x) * 4, 4);
}

void main() {
  group('NoteTableLayout', () {
    test('insets the grid by half the border', () {
      final layout = NoteTableLayout(
        _table(style: const NoteTableStyle(borderWidth: 4)),
        const Rect.fromLTWH(0, 0, 204, 84),
      );

      expect(layout.columnEdges, [2, 102, 202]);
      expect(layout.rowEdges, [2, 42, 82]);
      expect(layout.gridRect, const Rect.fromLTRB(2, 2, 202, 82));
    });

    test('uses the whole rectangle without borders', () {
      final layout = NoteTableLayout(
        _table(style: const NoteTableStyle(borderWidth: 0)),
        const Rect.fromLTWH(10, 10, 100, 50),
      );

      expect(layout.columnEdges, [10, 60, 110]);
      expect(layout.rowEdges, [10, 35, 60]);
    });

    test('follows the fractions and ends exactly on the far edge', () {
      final table = labelledTable().setColumnWidth(0, 0.5).setRowHeight(1, .2);

      final layout = NoteTableLayout(table, const Rect.fromLTWH(0, 0, 301, 91));

      expect(layout.columnEdges.first, 0.5);
      expect(layout.columnEdges[1], closeTo(150.5, 1e-9));
      expect(layout.columnEdges.last, 300.5);
      expect(layout.rowEdges.last, 90.5);
    });

    test('gives merged cells the whole region', () {
      final table = _table().mergeCells(span(0, 0, 1, 0));
      final layout = NoteTableLayout(table, const Rect.fromLTWH(0, 0, 101, 81));

      expect(layout.cellRect(1, 0), const Rect.fromLTRB(0.5, 0.5, 50.5, 80.5));
      expect(layout.rectOf(span(0, 0, 9, 9)), layout.gridRect);
    });

    test('maps points to positions, clamping outside ones', () {
      final layout = NoteTableLayout(
        labelledTable(style: const NoteTableStyle(borderWidth: 0)),
        const Rect.fromLTWH(0, 0, 300, 120),
      );

      expect(layout.cellAt(const Offset(0, 0)), (row: 0, column: 0));
      expect(layout.cellAt(const Offset(150, 100)), (row: 2, column: 1));
      expect(layout.cellAt(const Offset(100, 40)), (row: 1, column: 1));
      expect(layout.cellAt(const Offset(-50, 500)), (row: 2, column: 0));
      expect(layout.cellAt(const Offset(900, -9)), (row: 0, column: 2));
    });

    test('never produces negative sizes', () {
      final layout = NoteTableLayout(
        _table(style: const NoteTableStyle(borderWidth: 8)),
        const Rect.fromLTWH(0, 0, 3, 0),
      );

      expect(layout.gridRect.width, greaterThanOrEqualTo(0));
      expect(layout.gridRect.height, greaterThanOrEqualTo(0));
    });
  });

  group('paintToCanvas', () {
    test('draws fills, then text, then one border path', () {
      final table = _table(
        style: const NoteTableStyle(
          headerRow: true,
          headerFill: _header,
          borderColor: _border,
        ),
      ).setCell(1, 1, const NoteTableCell(text: 'hi', fillColor: _fill));

      expect(
        _painting(table),
        paints
          ..rect(color: _header)
          ..rect(color: _header)
          ..rect(color: _fill)
          ..paragraph()
          ..path(color: _border, strokeWidth: 1, style: PaintingStyle.stroke),
      );
    });

    test('lets a cell fill win over the header fill', () {
      final table = _table(
        style: const NoteTableStyle(headerRow: true, headerFill: _header),
      ).setCell(0, 0, const NoteTableCell(fillColor: _fill));

      expect(
        _painting(table),
        paints
          ..rect(color: _fill)
          ..rect(color: _header),
      );
    });

    test('has no header fill unless the style asks for it', () {
      expect(_painting(_table()), isNot(paints..rect()));
    });

    test('draws a merged cell once', () {
      final table = _table()
          .setCell(0, 0, const NoteTableCell(text: 'a', fillColor: _fill))
          .mergeCells(span(0, 0, 1, 1));

      expect(
        _painting(table),
        paints
          ..rect(color: _fill)
          ..paragraph(),
      );
      expect(
        _painting(table),
        isNot(
          paints
            ..rect()
            ..rect(),
        ),
      );
      expect(
        _painting(table),
        isNot(
          paints
            ..paragraph()
            ..paragraph(),
        ),
      );
    });

    test('draws no borders at width zero and no text when empty', () {
      final table = _table(style: const NoteTableStyle(borderWidth: 0));

      expect(_painting(table), isNot(paints..path()));
      expect(_painting(table), isNot(paints..paragraph()));
    });

    test('can leave one cell without text', () {
      final table = _table().setCellText(0, 0, 'edited');

      expect(
        (Canvas canvas) => NoteTablePainter.paintTable(
          canvas,
          table.bounds,
          table,
          hiddenTextCell: (row: 0, column: 0),
        ),
        isNot(paints..paragraph()),
      );
    });

    testWidgets('stays inside the bounds, borders included', (tester) async {
      const red = Color(0xFFFF0000);
      var table = _table(
        style: const NoteTableStyle(
          borderWidth: 4,
          borderColor: Color(0xFF000000),
        ),
      );
      for (var row = 0; row < 2; row++) {
        for (var column = 0; column < 2; column++) {
          table = table.setCell(
            row,
            column,
            const NoteTableCell(fillColor: red),
          );
        }
      }

      await tester.runAsync(() async {
        final pixel = await _rasterise(table);

        // Bounds are x 20..220, y 30..110.
        for (final (x, y) in [(19, 70), (220, 70), (120, 29), (120, 110)]) {
          expect(pixel(x, y)[3], 0, reason: 'painted outside at $x,$y');
        }
        expect(pixel(70, 50), [255, 0, 0, 255], reason: 'cell fill');
        expect(pixel(21, 70), [0, 0, 0, 255], reason: 'outer border');
        expect(pixel(120, 50), [0, 0, 0, 255], reason: 'inner border');
        expect(pixel(20, 30), [0, 0, 0, 255], reason: 'closed corner');
      });
    });

    testWidgets('paints text inside its cell', (tester) async {
      final table = _table(
        style: const NoteTableStyle(borderWidth: 0, fontSize: 20),
      ).setCellText(0, 0, 'MMMMMMMMMMMMMMMMMMMM\nMMMM\nMMMM\nMMMM');

      await tester.runAsync(() async {
        final pixel = await _rasterise(table);
        var inside = 0;
        var outside = 0;
        for (var y = 0; y < 140; y++) {
          for (var x = 0; x < 260; x++) {
            if (pixel(x, y)[3] == 0) continue;
            // Cell (0, 0) is x 20..120, y 30..70.
            x >= 20 && x < 120 && y >= 30 && y < 70 ? inside++ : outside++;
          }
        }

        expect(inside, greaterThan(0));
        expect(outside, 0, reason: 'long text must be clipped');
      });
    });
  });

  group('NoteTablePainter', () {
    test('maps cells to text styles and alignments', () {
      const style = NoteTableStyle(fontSize: 16, textColor: _border);

      final plain = NoteTablePainter.textStyleFor(style, NoteTableCell.empty);
      final custom = NoteTablePainter.textStyleFor(
        style,
        const NoteTableCell(bold: true, textColor: _fill),
      );

      expect(plain.color, _border);
      expect(plain.fontSize, 16);
      expect(plain.fontWeight, FontWeight.w400);
      expect(custom.color, _fill);
      expect(custom.fontWeight, FontWeight.w700);
      expect(NoteTableCellAlign.values.map(NoteTablePainter.textAlignFor), [
        TextAlign.start,
        TextAlign.center,
        TextAlign.end,
      ]);
    });

    test('shrinks the padding of tiny cells', () {
      const big = Rect.fromLTWH(0, 0, 100, 40);
      const small = Rect.fromLTWH(0, 0, 100, 8);

      expect(NoteTablePainter.paddingFor(big, 4), 4);
      expect(NoteTablePainter.paddingFor(small, 4), 2);
      expect(NoteTablePainter.paddingFor(Rect.zero, 4), 0);
    });

    test('repaints only when what it draws changes', () {
      final table = _table();
      final painter = NoteTablePainter(table: table);

      expect(painter.shouldRepaint(NoteTablePainter(table: _table())), isFalse);
      expect(
        painter.shouldRepaint(
          NoteTablePainter(table: table.setCellText(0, 0, 'x')),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          NoteTablePainter(table: table, textDirection: TextDirection.rtl),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          NoteTablePainter(table: table, hiddenTextCell: (row: 0, column: 0)),
        ),
        isTrue,
      );
    });

    test('rebuilds semantics when the selection changes', () {
      final table = _table();
      final painter = NoteTablePainter(table: table);

      expect(
        painter.shouldRebuildSemantics(NoteTablePainter(table: table)),
        isFalse,
      );
      expect(
        painter.shouldRebuildSemantics(
          NoteTablePainter(table: table, selection: span(0, 0, 0, 0)),
        ),
        isTrue,
      );
      expect(
        painter.shouldRebuildSemantics(
          NoteTablePainter(table: table, onCellTap: (_, _) {}),
        ),
        isTrue,
      );
    });
  });
}
