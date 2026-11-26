import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/table/table.dart';

import 'support/table_invariants.dart';

void main() {
  group('NoteTableCell', () {
    const full = NoteTableCell(
      text: 'a\nb',
      rowSpan: 2,
      columnSpan: 3,
      fillColor: Color(0x80FF0000),
      textColor: Color(0xFF00FF00),
      bold: true,
      align: NoteTableCellAlign.end,
    );

    test('round-trips through JSON', () {
      final json = jsonDecode(jsonEncode(full.toJson()));

      expect(NoteTableCell.fromJson(json), full);
      expect(NoteTableCell.fromJson(json).hashCode, full.hashCode);
    });

    test('omits default values', () {
      expect(NoteTableCell.empty.toJson(), isEmpty);
      expect(NoteTableCell.coveredCell.toJson(), {'covered': true});
      expect(NoteTableCell.fromJson(const <String, Object?>{}), isNot(full));
    });

    test('reads malformed input leniently', () {
      expect(NoteTableCell.fromJson(null), NoteTableCell.empty);
      expect(NoteTableCell.fromJson('nope'), NoteTableCell.empty);
      expect(NoteTableCell.fromJson(const [1, 2]), NoteTableCell.empty);
      final cell = NoteTableCell.fromJson(const {
        'text': 7,
        'rowSpan': -4,
        'columnSpan': 'two',
        'fillColor': 'red',
        'textColor': double.nan,
        'bold': 'yes',
        'align': 'justify',
      });

      expect(cell, NoteTableCell.empty);
    });

    test('copyWith replaces and clears fields', () {
      expect(full.copyWith(), full);
      expect(full.copyWith(text: 'x').text, 'x');
      final cleared = full.copyWith(clearFillColor: true, clearTextColor: true);

      expect(cleared.fillColor, isNull);
      expect(cleared.textColor, isNull);
      expect(cleared.bold, isTrue);
    });

    test('rejects spans below one', () {
      expect(() => NoteTableCell(rowSpan: 0), throwsAssertionError);
      expect(() => NoteTableCell(columnSpan: -1), throwsAssertionError);
    });
  });

  group('NoteTableRange', () {
    test('normalises corners given in any order and negative indices', () {
      expect(span(3, 4, 1, 0), span(1, 0, 3, 4));
      expect(span(-2, -1, 1, 2), span(0, 0, 1, 2));
      expect(span(-5, 0, -1, 0), const NoteTableRange.cell(0, 0));
      expect(const NoteTableRange.cell(-3, 2), span(0, 2, 0, 2));
    });

    test('reports its size', () {
      final range = span(1, 1, 2, 4);

      expect(range.rowCount, 2);
      expect(range.columnCount, 4);
      expect(range.isSingleCell, isFalse);
      expect(const NoteTableRange.cell(1, 1).isSingleCell, isTrue);
    });

    test('contains and intersects', () {
      final range = span(1, 1, 3, 3);

      expect(range.contains(1, 1), isTrue);
      expect(range.contains(3, 3), isTrue);
      expect(range.contains(0, 1), isFalse);
      expect(range.contains(1, 4), isFalse);
      expect(range.containsRange(span(2, 2, 3, 3)), isTrue);
      expect(range.containsRange(span(2, 2, 4, 3)), isFalse);
      expect(range.intersects(span(3, 3, 5, 5)), isTrue);
      expect(range.intersects(span(4, 1, 5, 3)), isFalse);
      expect(range.intersects(span(0, 0, 0, 9)), isFalse);
    });

    test('unions, shifts, clamps and transposes', () {
      final range = span(1, 2, 3, 4);

      expect(range.union(span(0, 5, 0, 6)), span(0, 2, 3, 6));
      expect(range.shift(rows: 1, columns: -1), span(2, 1, 4, 3));
      expect(range.shift(rows: -9), span(0, 2, 0, 4));
      expect(range.clampTo(3, 3), span(1, 2, 2, 2));
      expect(span(7, 7, 9, 9).clampTo(3, 4), span(2, 3, 2, 3));
      expect(range.transposed, span(2, 1, 4, 3));
      expect(range.copyWith(lastRow: 5), span(1, 2, 5, 4));
    });

    test('round-trips through JSON and reads garbage leniently', () {
      final range = span(1, 2, 3, 4);

      expect(NoteTableRange.fromJson(range.toJson()), range);
      expect(range.toJson(), {
        'firstRow': 1,
        'firstColumn': 2,
        'lastRow': 3,
        'lastColumn': 4,
      });
      expect(NoteTableRange.fromJson(null), const NoteTableRange.cell(0, 0));
      expect(
        NoteTableRange.fromJson(const {'firstRow': 2, 'firstColumn': 'x'}),
        const NoteTableRange.cell(2, 0),
      );
    });

    test('has value equality', () {
      expect(span(0, 0, 1, 1).hashCode, span(1, 1, 0, 0).hashCode);
      expect(span(0, 0, 1, 1), isNot(span(0, 0, 1, 2)));
    });
  });

  group('NoteTableStyle', () {
    const custom = NoteTableStyle(
      borderColor: Color(0xFF112233),
      borderWidth: 2.5,
      headerRow: true,
      headerFill: Color(0xFFABCDEF),
      cellPadding: 8,
      fontSize: 20,
      textColor: Color(0xFF445566),
    );

    test('has the documented defaults', () {
      const style = NoteTableStyle();

      expect(style.borderWidth, 1);
      expect(style.headerRow, isFalse);
      expect(style.cellPadding, 4);
      expect(style.fontSize, 12);
    });

    test('round-trips through JSON', () {
      final json = jsonDecode(jsonEncode(custom.toJson()));

      expect(NoteTableStyle.fromJson(json), custom);
      expect(NoteTableStyle.fromJson(json).hashCode, custom.hashCode);
    });

    test('clamps ranges and falls back on garbage', () {
      final clamped = NoteTableStyle.fromJson(const {
        'borderWidth': 99,
        'cellPadding': -3,
        'fontSize': 1,
        'headerRow': 'yes',
        'borderColor': 'blue',
      });

      expect(clamped.borderWidth, NoteTableStyle.maxBorderWidth);
      expect(clamped.cellPadding, 0);
      expect(clamped.fontSize, NoteTableStyle.minFontSize);
      expect(clamped.headerRow, isFalse);
      expect(clamped.borderColor, const NoteTableStyle().borderColor);
      expect(NoteTableStyle.fromJson(42), const NoteTableStyle());
    });

    test('copyWith replaces fields', () {
      expect(custom.copyWith(), custom);
      expect(custom.copyWith(fontSize: 30).fontSize, 30);
      expect(custom.copyWith(fontSize: 30), isNot(custom));
    });

    test('asserts its ranges', () {
      expect(() => NoteTableStyle(borderWidth: 9), throwsAssertionError);
      expect(() => NoteTableStyle(cellPadding: -1), throwsAssertionError);
      expect(() => NoteTableStyle(fontSize: 100), throwsAssertionError);
    });
  });

  group('NoteTableStrings', () {
    test('labels every action and describes cells', () {
      const strings = NoteTableStrings();

      for (final action in NoteTableAction.values) {
        expect(strings.labelFor(action), isNotEmpty);
      }
      expect(strings.cellLabel(2, 3), 'Row 2, column 3');
      expect(strings.tableLabel(4, 5), 'Table, 4 rows, 5 columns');
    });

    test('is translatable', () {
      const strings = NoteTableStrings(merge: '병합', split: '분할');

      expect(strings.labelFor(NoteTableAction.merge), '병합');
      expect(strings.labelFor(NoteTableAction.split), '분할');
    });
  });
}
