import 'package:co_demo_prefs/co_demo_prefs.dart';

import 'demo_locale_resolution_reason.dart';

/// The result of resolving a requested UI language tag.
///
/// Resolution never throws: an unusable tag resolves to the fallback locale
/// and says why in [reason], so the demo keeps working and the diagnostic is
/// visible to tests and logs.
class DemoLocaleResolution {
  /// Creates a resolution result.
  const DemoLocaleResolution({
    required this.requestedTag,
    required this.locale,
    required this.reason,
    required this.fakerLocale,
    required this.fakerDataLocale,
  });

  /// The tag that was requested, as given.
  final String? requestedTag;

  /// The demo locale to use.
  final DemoLocale locale;

  /// Why [locale] was chosen.
  final DemoLocaleResolutionReason reason;

  /// The co_faker locale code mapped from [locale].
  final String fakerLocale;

  /// The co_faker locale whose data is actually used for [fakerLocale] —
  /// `en` when co_faker has no data for the language yet.
  final String fakerDataLocale;

  /// Whether the requested tag could not be used and [locale] is the
  /// fallback.
  bool get isFallback => reason != DemoLocaleResolutionReason.matched;

  /// Whether co_faker generates this language's display data in English
  /// because it has no data for the language yet.
  bool get dataFallsBackToEnglish =>
      locale != DemoLocale.en && fakerDataLocale.split('_').first == 'en';

  @override
  String toString() =>
      'DemoLocaleResolution(${requestedTag ?? '<none>'} → ${locale.tag}, '
      '${reason.name}, faker $fakerLocale → $fakerDataLocale)';
}
