import '../clinic_data.dart';
import '../co_faker_languages.dart';
import '../co_faker_locale.dart';
import '../saas_data.dart';
import 'ar/ar_clinic.dart';
import 'ar/ar_saas.dart';
import 'de/de_clinic.dart';
import 'de/de_saas.dart';
import 'es/es_clinic.dart';
import 'es/es_saas.dart';
import 'fr/fr_clinic.dart';
import 'fr/fr_saas.dart';
import 'it/it_clinic.dart';
import 'it/it_saas.dart';
import 'ja/ja_clinic.dart';
import 'ja/ja_saas.dart';
import 'pt/pt_clinic.dart';
import 'pt/pt_saas.dart';
import 'ru/ru_clinic.dart';
import 'ru/ru_saas.dart';
import 'zh/zh_clinic.dart';
import 'zh/zh_saas.dart';

/// The clinic and SaaS data of one language: `faker.clinic` reads `clinic`
/// and `faker.saas` reads `saas`. A `null` member means that the language has
/// no such data yet and English is used.
typedef CoL10nClinicEntry = ({
  CoFakerClinicData? clinic,
  CoFakerSaasData? saas,
});

/// The language registry of clinic and SaaS data.
///
/// `CoFaker` picks the data of `faker.clinic` and `faker.saas` in this order:
/// the data of the locale itself (a custom locale, or the built-in `ko` and
/// `en`), then the data registered here for the language of the locale, then
/// English. A language is added by filling its two files under
/// `lib/src/l10n/<language>/` (`<language>_clinic.dart` and
/// `<language>_saas.dart`); this registry already reads their constants and
/// never needs an edit. Every language keeps its own lines, separated by
/// blank lines, so that the languages never touch each other's lines.
abstract final class CoL10nClinic {
  /// The registered data by language code.
  ///
  /// A `null` member is a stub that a language Story has not filled yet.
  static const Map<String, CoL10nClinicEntry> entries =
      <String, CoL10nClinicEntry>{
        'ko': (clinic: CoFakerClinicData.korean, saas: CoFakerSaasData.korean),

        'en': (
          clinic: CoFakerClinicData.english,
          saas: CoFakerSaasData.english,
        ),

        'zh': (clinic: zhClinic, saas: zhSaas),

        'ja': (clinic: jaClinic, saas: jaSaas),

        'de': (clinic: deClinic, saas: deSaas),

        'fr': (clinic: frClinic, saas: frSaas),

        'ru': (clinic: ruClinic, saas: ruSaas),

        'it': (clinic: itClinic, saas: itSaas),

        'pt': (clinic: ptClinic, saas: ptSaas),

        'es': (clinic: esClinic, saas: esSaas),

        'ar': (clinic: arClinic, saas: arSaas),
      };

  /// The clinic data registered for [language] (`ja`), or `null`.
  static CoFakerClinicData? clinicOf(String language) =>
      entries[language]?.clinic;

  /// The SaaS data registered for [language] (`ja`), or `null`.
  static CoFakerSaasData? saasOf(String language) => entries[language]?.saas;

  /// Merges [selected], the locale that `CoFaker` selected for [locale], over
  /// [fallback] (English), taking the clinic and SaaS data it lacks from
  /// [registry].
  ///
  /// A locale keeps the data it carries, so a custom locale can supply its
  /// own. Data it lacks comes from the entry of its language, found with
  /// `CoFakerLanguages.resolve`, and then from [fallback]. A locale that is
  /// not a supported language, such as a custom code or Traditional Chinese
  /// (`zh_TW`, `zh_HK`, `zh_MO`, `zh-Hant`), never reads the registry: it must
  /// not be handed the data of another language, or of Simplified Chinese.
  static CoFakerLocale select(
    CoFakerLocale selected, {
    required CoFakerLocale fallback,
    required String locale,
    Map<String, CoL10nClinicEntry> registry = entries,
  }) {
    if (selected.clinic != null && selected.saas != null) {
      return selected.merge(fallback);
    }
    final resolution = CoFakerLanguages.resolve(locale);
    final entry = resolution.supported
        ? registry[resolution.language.code]
        : null;
    if (entry == null || (entry.clinic == null && entry.saas == null)) {
      return selected.merge(fallback);
    }
    final registered = CoFakerLocale(
      code: selected.code,
      clinic: entry.clinic,
      saas: entry.saas,
    );
    return selected.merge(registered).merge(fallback);
  }
}
