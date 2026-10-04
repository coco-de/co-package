import '../co_faker_locale.dart';
import 'data/brazil.dart';
import 'data/canada.dart';
import 'data/china.dart';
import 'data/france.dart';
import 'data/germany.dart';
import 'data/india.dart';
import 'data/italy.dart';
import 'data/japan.dart';
import 'data/russia.dart';
import 'data/united_kingdom.dart';
import 'data/united_states.dart';

/// National locales: one per country in `CoFakerCountries.all`.
///
/// They are registered in `CoFakerLocales.all` under their regional code
/// (`en_us`, `ja_jp`, ...), so `CoFaker(locale: 'ja-JP')` and
/// `CoFaker.forCountry('JP')` both select [japan].
abstract final class CoFakerNationalLocales {
  /// United States (`en_US`).
  static const CoFakerLocale unitedStates = unitedStatesLocale;

  /// China (`zh_CN`).
  static const CoFakerLocale china = chinaLocale;

  /// Germany (`de_DE`).
  static const CoFakerLocale germany = germanyLocale;

  /// Japan (`ja_JP`).
  static const CoFakerLocale japan = japanLocale;

  /// United Kingdom (`en_GB`).
  static const CoFakerLocale unitedKingdom = unitedKingdomLocale;

  /// India (`en_IN`).
  static const CoFakerLocale india = indiaLocale;

  /// France (`fr_FR`).
  static const CoFakerLocale france = franceLocale;

  /// Russia (`ru_RU`).
  static const CoFakerLocale russia = russiaLocale;

  /// Italy (`it_IT`).
  static const CoFakerLocale italy = italyLocale;

  /// Canada (`en_CA`).
  static const CoFakerLocale canada = canadaLocale;

  /// Brazil (`pt_BR`).
  static const CoFakerLocale brazil = brazilLocale;

  /// National locales keyed by ISO 3166-1 alpha-2 country code.
  static const Map<String, CoFakerLocale> byCountry = <String, CoFakerLocale>{
    'US': unitedStates,
    'CN': china,
    'DE': germany,
    'JP': japan,
    'GB': unitedKingdom,
    'IN': india,
    'FR': france,
    'RU': russia,
    'IT': italy,
    'CA': canada,
    'BR': brazil,
  };
}
