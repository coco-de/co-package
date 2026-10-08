import 'package:co_demo_prefs/co_demo_prefs.dart';

import 'locale_field_status.dart';

/// The support of one display field in one language, measured from real
/// co_faker output.
class LocaleFieldReport {
  /// Creates a report row.
  const LocaleFieldReport({
    required this.locale,
    required this.fieldKey,
    required this.status,
    required this.englishShare,
    required this.scriptShare,
    required this.sample,
  });

  /// The UI language.
  final DemoLocale locale;

  /// The field, `entity.field`.
  final String fieldKey;

  /// The measured support.
  final LocaleFieldStatus status;

  /// The share of sampled values identical to the English values (0–1).
  final double englishShare;

  /// The share of sampled values that contain the language's own script
  /// (0–1; 1 for Latin-script languages, which are judged by [englishShare]).
  final double scriptShare;

  /// The first sampled value, for the support table.
  final String sample;

  @override
  String toString() =>
      'LocaleFieldReport(${locale.tag} $fieldKey ${status.name} '
      'en=${englishShare.toStringAsFixed(2)} '
      'script=${scriptShare.toStringAsFixed(2)} "$sample")';
}
