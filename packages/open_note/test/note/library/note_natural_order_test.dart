import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/library/library.dart';

List<String> _sorted(List<String> names) =>
    [...names]..sort(NoteNaturalOrder.compare);

void main() {
  group('NoteNaturalOrder', () {
    test('compares digit runs as numbers', () {
      expect(NoteNaturalOrder.compare('Note 2', 'Note 10'), isNegative);
      expect(NoteNaturalOrder.compare('Note 10', 'Note 2'), isPositive);
      expect(_sorted(['Note 10', 'Note 20', 'Note 1', 'Note 3', 'Note 2']), [
        'Note 1',
        'Note 2',
        'Note 3',
        'Note 10',
        'Note 20',
      ]);
    });

    test('handles several digit runs in one name', () {
      expect(_sorted(['v1.10.0', 'v1.2.1', 'v1.2.0', 'v10.0.0', 'v2.0.0']), [
        'v1.2.0',
        'v1.2.1',
        'v1.10.0',
        'v2.0.0',
        'v10.0.0',
      ]);
    });

    test('ignores case', () {
      expect(_sorted(['banana', 'Apple', 'cherry', 'BETA']), [
        'Apple',
        'banana',
        'BETA',
        'cherry',
      ]);
      expect(NoteNaturalOrder.compare('note 2', 'NOTE 10'), isNegative);
    });

    test('sorts Hangul by code point after Latin letters', () {
      expect(_sorted(['나무', 'zebra', '10월', '가방', 'Apple', '2월', '다리']), [
        '2월',
        '10월',
        'Apple',
        'zebra',
        '가방',
        '나무',
        '다리',
      ]);
      expect(NoteNaturalOrder.compare('노트 2', '노트 10'), isNegative);
    });

    test('compares by code point, not UTF-16 unit', () {
      // U+FF21 (a BMP character) comes before U+1F600 by code point although
      // the surrogate pair of the latter starts with a smaller code unit.
      expect(NoteNaturalOrder.compare('Ａ', '😀'), isNegative);
    });

    test('puts a prefix first', () {
      expect(_sorted(['Note 1', 'Note', 'Notebook', 'Not']), [
        'Not',
        'Note',
        'Note 1',
        'Notebook',
      ]);
    });

    test('orders equal numbers by their leading zeros', () {
      expect(_sorted(['8', '007', '7']), ['7', '007', '8']);
      expect(NoteNaturalOrder.compare('a007b', 'a7c'), isNegative);
      expect(NoteNaturalOrder.compare('a7b', 'a007c'), isNegative);
      expect(NoteNaturalOrder.compare('0', '00'), isNegative);
    });

    test('compares numbers too large for 64 bits', () {
      final bigger = '2${'0' * 30}';
      final smaller = '1${'9' * 29}';

      expect(NoteNaturalOrder.compare(smaller, bigger), isNegative);
    });

    test('is a total order: only equal strings compare as equal', () {
      const names = [
        '',
        'a',
        'A',
        'a1',
        'a01',
        'a2',
        'a10',
        'b',
        '1',
        '01',
        '2',
        '10',
        '가',
        '가2',
        '가10',
        ' ',
        '-1',
      ];
      for (final a in names) {
        for (final b in names) {
          final forward = NoteNaturalOrder.compare(a, b).sign;

          expect(forward == 0, a == b, reason: '"$a" "$b"');
          expect(NoteNaturalOrder.compare(b, a).sign, -forward);
        }
      }
      final ordered = _sorted(names);
      for (var i = 0; i < ordered.length; i++) {
        for (var j = i + 1; j < ordered.length; j++) {
          expect(
            NoteNaturalOrder.compare(ordered[i], ordered[j]),
            isNegative,
            reason: 'transitive: "${ordered[i]}" "${ordered[j]}"',
          );
        }
      }
    });
  });
}
