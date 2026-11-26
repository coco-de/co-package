import 'dart:math' as math;

/// Pure arithmetic on the size fractions of resizable panes. A fraction list
/// has one entry per pane, each at least the minimum, and sums to 1.
abstract final class NotePaneFractions {
  /// [count] equal fractions (an empty list for `count <= 0`).
  static List<double> equal(int count) =>
      count <= 0 ? [] : List<double>.filled(count, 1 / count, growable: true);

  /// The smallest fraction a pane may have: [minFraction] clamped into
  /// `[0, 1 / count]` (with more panes than the minimum allows, equal shares).
  static double effectiveMinimum(int count, double minFraction) {
    if (count <= 0 || !minFraction.isFinite || minFraction <= 0) return 0;

    return math.min(minFraction, 1 / count);
  }

  /// [input] turned into a valid list of [count] fractions: scaled to sum to 1
  /// and raised to the minimum (the other panes shrink proportionally). Equal
  /// shares when [input] is `null`, has another length, holds a negative or
  /// non-finite number or sums to 0.
  static List<double> normalize(
    List<double>? input,
    int count, {
    double minFraction = 0,
  }) {
    if (count <= 0) return [];
    if (input == null || input.length != count || !_isUsable(input)) {
      return equal(count);
    }
    final total = input.fold<double>(0, (sum, value) => sum + value);

    return _raiseToMinimum([
      for (final value in input) value / total,
    ], effectiveMinimum(count, minFraction));
  }

  /// Moves the divider after pane [divider] by [delta] (a fraction of the
  /// whole; positive moves it right or down). Only the two neighbouring panes
  /// change and both stay at least the minimum. An unknown divider or a
  /// non-finite [delta] returns an unchanged copy.
  static List<double> moveDivider(
    List<double> fractions,
    int divider,
    double delta, {
    double minFraction = 0,
  }) {
    final result = List<double>.of(fractions);
    if (divider < 0 || divider >= result.length - 1 || !delta.isFinite) {
      return result;
    }
    final sum = result[divider] + result[divider + 1];
    final minimum = math.min(
      effectiveMinimum(result.length, minFraction),
      sum / 2,
    );
    final first = (result[divider] + delta).clamp(minimum, sum - minimum);
    result[divider] = first;
    result[divider + 1] = sum - first;

    return result;
  }

  static bool _isUsable(List<double> values) {
    var total = 0.0;
    for (final value in values) {
      if (!value.isFinite || value < 0) return false;
      total += value;
    }

    return total > 0;
  }

  static List<double> _raiseToMinimum(List<double> values, double minimum) {
    final raised = <int>{};
    var result = values;
    while (true) {
      final low = [
        for (var i = 0; i < result.length; i++)
          if (!raised.contains(i) && result[i] < minimum - 1e-12) i,
      ];
      if (low.isEmpty) return result;
      raised.addAll(low);
      var rest = 0.0;
      for (var i = 0; i < values.length; i++) {
        if (!raised.contains(i)) rest += values[i];
      }
      final room = 1 - raised.length * minimum;
      result = [
        for (var i = 0; i < values.length; i++)
          raised.contains(i) || rest <= 0 ? minimum : values[i] * room / rest,
      ];
    }
  }
}
