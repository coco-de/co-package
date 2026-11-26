import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

void expectFractions(List<double> actual, List<double> expected) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], 1e-9), reason: 'pane $i: $actual');
  }
}

void main() {
  test('equal shares', () {
    expectFractions(NotePaneFractions.equal(4), [0.25, 0.25, 0.25, 0.25]);
    expect(NotePaneFractions.equal(0), isEmpty);
  });

  test('effective minimum is capped by the pane count', () {
    expect(NotePaneFractions.effectiveMinimum(2, 0.2), 0.2);
    expect(NotePaneFractions.effectiveMinimum(10, 0.2), 0.1);
    expect(NotePaneFractions.effectiveMinimum(3, -1), 0);
    expect(NotePaneFractions.effectiveMinimum(0, 0.2), 0);
  });

  group('normalize', () {
    test('scales to a sum of 1', () {
      expectFractions(NotePaneFractions.normalize([2, 2], 2), [0.5, 0.5]);
      expectFractions(NotePaneFractions.normalize([1, 3], 2), [0.25, 0.75]);
    });

    test('falls back to equal shares for unusable input', () {
      for (final input in <List<double>?>[
        null,
        [1],
        [1, -1],
        [0, 0],
        [double.nan, 1],
        [double.infinity, 1],
      ]) {
        expectFractions(NotePaneFractions.normalize(input, 2), [0.5, 0.5]);
      }
    });

    test('raises small panes to the minimum', () {
      expectFractions(
        NotePaneFractions.normalize([0.05, 0.95], 2, minFraction: 0.15),
        [0.15, 0.85],
      );
      expectFractions(
        NotePaneFractions.normalize([0.01, 0.01, 0.98], 3, minFraction: 0.2),
        [0.2, 0.2, 0.6],
      );
    });

    test('gives equal shares when the minimum cannot fit', () {
      expectFractions(
        NotePaneFractions.normalize([0.1, 0.1, 0.8], 3, minFraction: 0.5),
        [1 / 3, 1 / 3, 1 / 3],
      );
    });
  });

  group('moveDivider', () {
    test('moves size from one neighbour to the other', () {
      expectFractions(NotePaneFractions.moveDivider([0.5, 0.5], 0, 0.1), [
        0.6,
        0.4,
      ]);
    });

    test('stops at the minimum on both sides', () {
      expectFractions(
        NotePaneFractions.moveDivider([0.5, 0.5], 0, -1, minFraction: 0.2),
        [0.2, 0.8],
      );
      expectFractions(
        NotePaneFractions.moveDivider([0.5, 0.5], 0, 1, minFraction: 0.2),
        [0.8, 0.2],
      );
    });

    test('changes only the panes next to the divider', () {
      expectFractions(NotePaneFractions.moveDivider([0.3, 0.3, 0.4], 1, 0.1), [
        0.3,
        0.4,
        0.3,
      ]);
    });

    test('ignores bad dividers and deltas without sharing the list', () {
      final original = [0.5, 0.5];

      final unknown = NotePaneFractions.moveDivider(original, 1, 0.1);
      final nan = NotePaneFractions.moveDivider(original, 0, double.nan);

      expect(unknown, original);
      expect(nan, original);
      expect(identical(unknown, original), isFalse);
    });
  });
}
