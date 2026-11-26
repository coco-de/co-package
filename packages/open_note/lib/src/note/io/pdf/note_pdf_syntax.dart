// Internal to the PDF writer: how values are spelled in PDF syntax. Not
// exported from the module barrel.

/// Formats a number for PDF. PDF forbids exponent notation, so numbers have at
/// most four decimals with trailing zeros trimmed. Non-finite values become 0
/// and magnitudes are clamped to 1e9.
String notePdfNumber(double value) {
  if (!value.isFinite) return '0';
  var text = value.clamp(-1e9, 1e9).toStringAsFixed(4);
  var end = text.length;
  while (text[end - 1] == '0') {
    end--;
  }
  if (text[end - 1] == '.') end--;
  text = text.substring(0, end);

  return text == '-0' ? '0' : text;
}

/// Space-separated [values] in PDF number syntax.
String notePdfNumbers(List<double> values) =>
    values.map(notePdfNumber).join(' ');

/// A PDF text string: a literal for printable ASCII, otherwise UTF-16BE hex
/// with a byte order mark.
String notePdfTextString(String value) {
  if (value.codeUnits.every((unit) => unit >= 0x20 && unit < 0x7F)) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');

    return '($escaped)';
  }
  final hex = value.codeUnits
      .map((unit) => unit.toRadixString(16).padLeft(4, '0'))
      .join()
      .toUpperCase();

  return '<FEFF$hex>';
}

/// A PDF date string for [date], in UTC.
String notePdfDate(DateTime date) {
  final utc = date.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');

  return '(D:${utc.year.toString().padLeft(4, '0')}${two(utc.month)}'
      '${two(utc.day)}${two(utc.hour)}${two(utc.minute)}'
      '${two(utc.second)}Z)';
}
