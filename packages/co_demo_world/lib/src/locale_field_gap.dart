import 'display_key.dart';

/// Why a sampled key is not in the language of its report.
enum LocaleFieldGapReason {
  /// The value is written the same in every language, while other values of
  /// the field are in their languages: the generator returned a fallback
  /// (an SKU, a code) instead of text for this key.
  languageNeutral,
}

/// One sampled key of a display field that a language does not really have.
class LocaleFieldGap {
  /// Creates a gap.
  const LocaleFieldGap({
    required this.key,
    required this.value,
    required this.reason,
  });

  /// The key that was sampled.
  final DisplayKey key;

  /// What the language showed for it.
  final String value;

  /// Why it is not the language.
  final LocaleFieldGapReason reason;

  @override
  String toString() => 'LocaleFieldGap(${key.path} ${reason.name} "$value")';
}
