import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/table/note_table_fractions.dart';

double _sum(List<double> values) => values.fold(0, (a, b) => a + b);

void _expectValid(List<double> values, [String? reason]) => expect(
  NoteTableFractions.isValid(values, values.length),
  isTrue,
  reason: reason ?? '$values',
);

void main() {
  test('minimum is 0.05 up to twenty entries, then half an equal share', () {
    expect(NoteTableFractions.minimumFor(1), 0.05);
    expect(NoteTableFractions.minimumFor(20), 0.05);
    expect(NoteTableFractions.minimumFor(25), closeTo(0.02, 1e-12));
    expect(NoteTableFractions.minimumFor(100), closeTo(0.005, 1e-12));
  });

  group('normalize', () {
    test('keeps valid input unchanged', () {
      final values = [0.2, 0.3, 0.5];

      expect(NoteTableFractions.normalize(values, 3), values);
    });

    test('is idempotent', () {
      final once = NoteTableFractions.normalize([9, 1, 1], 3);

      expect(NoteTableFractions.normalize(once, 3), once);
      _expectValid(once);
    });

    test('scales to a total of one', () {
      final result = NoteTableFractions.normalize([2, 2, 4], 3);

      expect(result, [0.25, 0.25, 0.5]);
    });

    test('uses equal fractions for a list of the wrong length', () {
      expect(NoteTableFractions.normalize([1], 2), [0.5, 0.5]);
      expect(NoteTableFractions.normalize([], 4), [0.25, 0.25, 0.25, 0.25]);
    });

    test('gives unusable entries the average of the others', () {
      final result = NoteTableFractions.normalize([
        double.nan,
        3,
        -1,
        double.infinity,
      ], 4);

      expect(result, everyElement(closeTo(0.25, 1e-12)));
    });

    test('uses equal fractions when nothing is usable', () {
      expect(NoteTableFractions.normalize([0, -2], 2), [0.5, 0.5]);
    });

    test('does not overflow on huge entries', () {
      final result = NoteTableFractions.normalize([1e308, 1e308, 1e308], 3);

      expect(_sum(result), closeTo(1, 1e-9));
      expect(result, everyElement(closeTo(1 / 3, 1e-12)));
    });

    test('raises small entries to the minimum', () {
      final result = NoteTableFractions.normalize([1, 1000, 1000], 3);

      expect(result.first, closeTo(0.05, 1e-12));
      expect(result[1], closeTo(0.475, 1e-12));
      _expectValid(result);
    });

    test('works at the point where every entry must be the minimum', () {
      final skewed = [for (var i = 0; i < 20; i++) i.toDouble() + 1];

      final result = NoteTableFractions.normalize(skewed, 20);

      expect(result, everyElement(closeTo(0.05, 1e-9)));
      _expectValid(result);
    });

    test('stays valid for random input of any size', () {
      final random = math.Random(11);
      for (var trial = 0; trial < 500; trial++) {
        final count = 1 + random.nextInt(100);
        final raw = [
          for (var i = 0; i < count; i++)
            random.nextInt(8) == 0
                ? double.nan
                : math.pow(random.nextDouble() * 10, 3).toDouble(),
        ];

        _expectValid(
          NoteTableFractions.normalize(raw, count),
          'trial $trial with $count entries',
        );
      }
    });
  });

  test('insert copies the neighbour before and renormalises', () {
    expect(NoteTableFractions.insert([0.5, 0.5], 1), [
      closeTo(1 / 3, 1e-12),
      closeTo(1 / 3, 1e-12),
      closeTo(1 / 3, 1e-12),
    ]);
    final front = NoteTableFractions.insert([0.8, 0.2], 0);

    expect(front.first, closeTo(0.8 / 1.8, 1e-12));
    _expectValid(front);
    _expectValid(NoteTableFractions.insert([0.95, 0.05], 2));
  });

  test('removeAt shares the removed fraction', () {
    final result = NoteTableFractions.removeAt([0.5, 0.25, 0.25], 0);

    expect(result, [0.5, 0.5]);
  });

  group('resize', () {
    test('lets the next entry absorb the change', () {
      final result = NoteTableFractions.resize([0.25, 0.25, 0.5], 0, 0.4);

      expect(result, [0.4, closeTo(0.1, 1e-12), 0.5]);
    });

    test('lets the previous entry absorb it for the last one', () {
      final result = NoteTableFractions.resize([0.5, 0.25, 0.25], 2, 0.4);

      expect(result, [0.5, closeTo(0.1, 1e-12), 0.4]);
    });

    test('keeps both entries at or above the minimum', () {
      final grown = NoteTableFractions.resize([0.5, 0.5], 0, 3);
      final shrunk = NoteTableFractions.resize([0.5, 0.5], 0, -1);

      expect(grown, [closeTo(0.95, 1e-12), closeTo(0.05, 1e-12)]);
      expect(shrunk, [closeTo(0.05, 1e-12), closeTo(0.95, 1e-12)]);
    });

    test('returns the same list when nothing changes', () {
      final values = [0.5, 0.5];

      expect(NoteTableFractions.resize(values, 0, 0.5), same(values));
      expect(NoteTableFractions.resize(values, 5, 0.2), same(values));
      expect(NoteTableFractions.resize(values, -1, 0.2), same(values));
      expect(NoteTableFractions.resize(values, 0, double.nan), same(values));
      expect(NoteTableFractions.resize([1], 0, 0.5), [1]);
    });

    test('cannot move anything when every entry is at the minimum', () {
      final values = NoteTableFractions.equal(20);

      expect(NoteTableFractions.resize(values, 3, 0.2), same(values));
    });
  });
}
