import 'dart:math' as math;

/// Maths on the row-height and column-width fraction lists of a table.
///
/// Internal to the table module (not exported by the barrel); `NoteTableObject`
/// is the public face. A list is valid when its entries sum to 1 and none is
/// below [minimumFor] its length.
abstract final class NoteTableFractions {
  /// The smallest fraction of a row or column in tables of up to 20 entries.
  static const double minimum = 0.05;

  static const double _tolerance = 1e-9;

  /// The smallest fraction allowed when there are [count] entries: 0.05, or half
  /// an equal share when more than 20 entries could not all reach 0.05.
  static double minimumFor(int count) => count <= 20 ? minimum : 0.5 / count;

  /// [count] equal fractions.
  static List<double> equal(int count) => List<double>.filled(count, 1 / count);

  /// Whether [values] is a valid list of [count] fractions.
  static bool isValid(List<double> values, int count) {
    if (values.length != count) return false;
    final floor = minimumFor(count) - _tolerance;
    var total = 0.0;
    for (final value in values) {
      if (!value.isFinite || value < floor) return false;
      total += value;
    }

    return (total - 1).abs() <= _tolerance;
  }

  /// A valid list of [count] fractions based on [values].
  ///
  /// Already valid input is returned unchanged (so this is idempotent). A list
  /// of another length yields equal fractions. Entries that are not positive
  /// finite numbers take the average of the others; then the total is scaled to
  /// 1 and entries below the minimum are raised to it, the others shrinking in
  /// proportion.
  static List<double> normalize(List<double> values, int count) {
    if (isValid(values, count)) return List<double>.of(values);
    if (values.length != count) return equal(count);
    final usable = values.where(_isShare).toList();
    if (usable.isEmpty) return equal(count);
    // Dividing by the largest value first keeps the sum from overflowing.
    final largest = usable.reduce(math.max);
    final average = _sum([for (final v in usable) v / largest]) / usable.length;
    final scaled = [
      for (final v in values) _isShare(v) ? v / largest : average,
    ];
    final total = _sum(scaled);

    return _raiseToMinimum([
      for (final v in scaled) v / total,
    ], minimumFor(count));
  }

  /// [values] with a new entry before index [at] (`values.length` appends),
  /// copied from the entry before it (the first when [at] is 0), then
  /// normalised.
  static List<double> insert(List<double> values, int at) {
    final copied = values[at > 0 ? at - 1 : 0];
    final raw = List<double>.of(values)..insert(at, copied);

    return normalize(raw, raw.length);
  }

  /// [values] without entry [index], normalised.
  static List<double> removeAt(List<double> values, int index) {
    final raw = List<double>.of(values)..removeAt(index);

    return normalize(raw, raw.length);
  }

  /// [values] with entry [index] set to [fraction]. The next entry (the previous
  /// one for the last) absorbs the difference: the total of the two is kept and
  /// neither goes below the minimum.
  ///
  /// Returns [values] itself when nothing changes: a single entry, an index out
  /// of range, a [fraction] that is not finite or a value equal to the current.
  static List<double> resize(List<double> values, int index, double fraction) {
    final count = values.length;
    if (count < 2 || index < 0 || index >= count || !fraction.isFinite) {
      return values;
    }
    final neighbour = index == count - 1 ? index - 1 : index + 1;
    final pair = values[index] + values[neighbour];
    final floor = minimumFor(count);
    final double ceiling = math.max(floor, pair - floor);
    final target = fraction.clamp(floor, ceiling);
    if ((target - values[index]).abs() <= _tolerance) return values;

    return List<double>.of(values)
      ..[index] = target
      ..[neighbour] = pair - target;
  }

  static bool _isShare(double value) => value.isFinite && value > 0;

  static double _sum(List<double> values) =>
      values.fold(0, (total, value) => total + value);

  static List<double> _raiseToMinimum(List<double> shares, double floor) {
    final raised = <int>{};
    var result = shares;
    while (true) {
      final below = [
        for (var i = 0; i < result.length; i++)
          if (!raised.contains(i) && result[i] < floor) i,
      ];
      if (below.isEmpty) return result;
      raised.addAll(below);
      var free = 0.0;
      for (var i = 0; i < shares.length; i++) {
        if (!raised.contains(i)) free += shares[i];
      }
      final remaining = 1 - raised.length * floor;
      result = [
        for (var i = 0; i < shares.length; i++)
          raised.contains(i) ? floor : shares[i] / free * remaining,
      ];
    }
  }
}
