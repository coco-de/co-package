/// The order of note titles in the library: case-insensitive, and digit runs
/// compare by numeric value, so `Note 2` comes before `Note 10`.
///
/// Everything else compares by lower-cased Unicode code point, so Hangul sorts
/// after Latin letters and keeps its dictionary order among itself.
abstract final class NoteNaturalOrder {
  /// Compares [a] with [b]; the result is negative, zero or positive like
  /// [Comparable.compareTo].
  ///
  /// Names that differ only in case, or only in leading zeros of a number, are
  /// still ordered (fewer zeros first, then plain code unit order) so that the
  /// order of any two different strings is fixed.
  static int compare(String a, String b) {
    final left = a.toLowerCase().runes.toList();
    final right = b.toLowerCase().runes.toList();
    var i = 0;
    var j = 0;
    var zeroBias = 0;
    while (i < left.length && j < right.length) {
      if (!_isDigit(left[i]) || !_isDigit(right[j])) {
        final byPoint = left[i++].compareTo(right[j++]);
        if (byPoint != 0) return byPoint;
        continue;
      }
      final endI = _endOfDigits(left, i);
      final endJ = _endOfDigits(right, j);
      final byValue = _compareValues(
        left.sublist(i, endI),
        right.sublist(j, endJ),
      );
      if (byValue != 0) return byValue;
      if (zeroBias == 0) zeroBias = (endI - i).compareTo(endJ - j);
      i = endI;
      j = endJ;
    }
    final byRest = (left.length - i).compareTo(right.length - j);
    if (byRest != 0) return byRest;

    return zeroBias != 0 ? zeroBias : a.compareTo(b);
  }

  static bool _isDigit(int point) => point >= 0x30 && point <= 0x39;

  static int _endOfDigits(List<int> points, int start) {
    var end = start;
    while (end < points.length && _isDigit(points[end])) {
      end++;
    }

    return end;
  }

  /// Compares two digit runs as numbers of any length.
  static int _compareValues(List<int> a, List<int> b) {
    final x = _significant(a);
    final y = _significant(b);
    if (x.length != y.length) return x.length.compareTo(y.length);
    for (var k = 0; k < x.length; k++) {
      if (x[k] != y[k]) return x[k].compareTo(y[k]);
    }

    return 0;
  }

  static List<int> _significant(List<int> digits) =>
      digits.skipWhile((digit) => digit == 0x30).toList();
}
