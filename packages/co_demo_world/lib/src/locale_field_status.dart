import 'locale_field_report.dart';

/// How well co_faker generates one display field in one language.
enum LocaleFieldStatus {
  /// The values are in the language (its own words and script).
  native,

  /// Some values are in the language, some are the English values or a
  /// fallback written the same in every language (see
  /// [LocaleFieldReport.gaps]).
  partialFallback,

  /// The values are the English values — co_faker has no data for this
  /// field in this language yet.
  englishFallback,

  /// Korean text appears in a language other than Korean.
  koreanResidue,

  /// The language's script is missing from the values, and they are not the
  /// English values either.
  scriptMismatch,
}
