import 'dart:ui' show Locale;

final RegExp _namePattern = RegExp(r'^[a-z0-9][a-z0-9._-]*$');

/// Whether [value] can be used as one golden path segment.
///
/// Suites, scenarios, devices, and themes become directory and file names, so
/// they are limited to lowercase letters, digits, `.`, `_`, and `-`, must start
/// with a letter or digit, and may not contain `..`.
bool isGoldenName(String value) =>
    _namePattern.hasMatch(value) && !value.contains('..');

/// Returns [value] when it is a valid golden path segment and throws an
/// [ArgumentError] naming [parameter] otherwise.
String checkGoldenName(String value, String parameter) {
  if (!isGoldenName(value)) {
    throw ArgumentError.value(
      value,
      parameter,
      'must use lowercase letters, digits, ".", "_" or "-" and start with a '
      'letter or digit',
    );
  }
  return value;
}

/// Lowercase file-name token for [locale], for example `zh-hans` for
/// `zh-Hans`.
String goldenLocaleToken(Locale locale) => locale.toLanguageTag().toLowerCase();

/// Shortest decimal token for a text scale: `1.0` becomes `1`, `1.3` stays
/// `1.3`.
String goldenScaleToken(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
