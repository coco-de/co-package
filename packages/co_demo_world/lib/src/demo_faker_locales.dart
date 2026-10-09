import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:co_faker/co_faker.dart';

import 'demo_locale_resolution.dart';
import 'demo_locale_resolution_reason.dart';

/// The explicit map from the eleven demo UI languages to co_faker locales.
///
/// The table is written out rather than derived from the tag, because the
/// richest co_faker data for a language lives under a national code
/// (`ja_JP` has 40 given names, the legacy `ja` has 7) and some languages have
/// no co_faker data yet.
abstract final class DemoFakerLocales {
  /// UI language → co_faker locale.
  ///
  /// * `es` maps to the legacy `es` data until co_faker ships a Spanish
  ///   national locale (co-package#71).
  /// * `ar` has no co_faker data yet (co-package#71); co_faker generates its
  ///   display data in English. [resolve] reports this as
  ///   [DemoLocaleResolution.dataFallsBackToEnglish].
  static const Map<DemoLocale, String> table = <DemoLocale, String>{
    DemoLocale.ko: 'ko',
    DemoLocale.en: 'en_US',
    DemoLocale.zhHans: 'zh_CN',
    DemoLocale.ja: 'ja_JP',
    DemoLocale.de: 'de_DE',
    DemoLocale.fr: 'fr_FR',
    DemoLocale.es: 'es',
    DemoLocale.pt: 'pt_BR',
    DemoLocale.it: 'it_IT',
    DemoLocale.ru: 'ru_RU',
    DemoLocale.ar: 'ar',
  };

  /// The co_faker locale for [locale].
  static String fakerLocaleOf(DemoLocale locale) => table[locale]!;

  /// The co_faker locale whose data co_faker actually uses for [locale] —
  /// `en` when it has no data for the language.
  static String fakerDataLocaleOf(DemoLocale locale) =>
      CoFakerLocales.resolve(fakerLocaleOf(locale)).code;

  /// Resolves a requested UI language [tag] (a `?lang=` value, a `sync`
  /// message locale, a Widgetbook locale name) to a demo locale.
  ///
  /// Uses co_demo_prefs' parsing rules: case, `_`/`-` and region subtags are
  /// ignored, and Chinese is Simplified only. A missing, unsupported or
  /// Traditional Chinese tag resolves to [fallback] with the reason recorded.
  static DemoLocaleResolution resolve(
    String? tag, {
    DemoLocale fallback = DemoLocale.ko,
  }) {
    final parsed = DemoLocale.parse(tag);
    final DemoLocaleResolutionReason reason;
    if (parsed != null) {
      reason = DemoLocaleResolutionReason.matched;
    } else if (tag == null || tag.trim().isEmpty) {
      reason = DemoLocaleResolutionReason.missing;
    } else if (_isTraditionalChinese(tag)) {
      reason = DemoLocaleResolutionReason.traditionalChinese;
    } else {
      reason = DemoLocaleResolutionReason.unsupported;
    }
    final locale = parsed ?? fallback;
    return DemoLocaleResolution(
      requestedTag: tag,
      locale: locale,
      reason: reason,
      fakerLocale: fakerLocaleOf(locale),
      fakerDataLocale: fakerDataLocaleOf(locale),
    );
  }

  static bool _isTraditionalChinese(String tag) {
    final parts = tag.trim().replaceAll('_', '-').toLowerCase().split('-');
    return parts.first == 'zh' &&
        parts.skip(1).toSet().intersection(const {
          'hant',
          'tw',
          'hk',
          'mo',
        }).isNotEmpty;
  }
}
