import 'co_faker_country.dart';

/// Countries that ship with a national locale.
///
/// [gdpTop10] lists the ten largest economies by nominal GDP in [gdpSource].
/// [brazil] is supported as well: it ranks 11th there, within two percent of
/// [canada], and inside the IMF's 2026 top ten, so sources disagree on ranks
/// nine to eleven. Use [all] to cover every source's top ten.
///
/// [spain] and [saudiArabia] are not in the top ten: they are the countries of
/// the languages Spanish and Arabic, which demo apps offer besides the
/// languages of the largest economies. They are listed in [languageCountries].
///
/// ```dart
/// final faker = CoFaker.forCountry('JP', seed: 7);
/// for (final country in CoFakerCountries.gdpTop10) {
///   final local = CoFaker(locale: country.locale, seed: 7);
///   print('${country.name}: ${local.person.fullName()}');
/// }
/// ```
abstract final class CoFakerCountries {
  /// Source and edition of the GDP ranking behind [CoFakerCountry.gdpRank].
  static const String gdpSource =
      'World Bank World Development Indicators, NY.GDP.MKTP.CD '
      '(GDP, current US\$), 2025 values, last updated 2026-07-13';

  /// United States (`en_US`).
  static const CoFakerCountry unitedStates = CoFakerCountry(
    code: 'US',
    alpha3: 'USA',
    locale: 'en_US',
    name: 'United States',
    nativeName: 'United States',
    callingCode: '+1',
    currencyCode: 'USD',
    currencySymbol: r'$',
    currencyMinorUnits: 2,
    gdpRank: 1,
  );

  /// China (`zh_CN`).
  static const CoFakerCountry china = CoFakerCountry(
    code: 'CN',
    alpha3: 'CHN',
    locale: 'zh_CN',
    name: 'China',
    nativeName: '中国',
    callingCode: '+86',
    currencyCode: 'CNY',
    currencySymbol: '¥',
    currencyMinorUnits: 2,
    gdpRank: 2,
  );

  /// Germany (`de_DE`).
  static const CoFakerCountry germany = CoFakerCountry(
    code: 'DE',
    alpha3: 'DEU',
    locale: 'de_DE',
    name: 'Germany',
    nativeName: 'Deutschland',
    callingCode: '+49',
    currencyCode: 'EUR',
    currencySymbol: '€',
    currencyMinorUnits: 2,
    gdpRank: 3,
  );

  /// Japan (`ja_JP`).
  static const CoFakerCountry japan = CoFakerCountry(
    code: 'JP',
    alpha3: 'JPN',
    locale: 'ja_JP',
    name: 'Japan',
    nativeName: '日本',
    callingCode: '+81',
    currencyCode: 'JPY',
    currencySymbol: '¥',
    currencyMinorUnits: 0,
    gdpRank: 4,
  );

  /// United Kingdom (`en_GB`).
  static const CoFakerCountry unitedKingdom = CoFakerCountry(
    code: 'GB',
    alpha3: 'GBR',
    locale: 'en_GB',
    name: 'United Kingdom',
    nativeName: 'United Kingdom',
    callingCode: '+44',
    currencyCode: 'GBP',
    currencySymbol: '£',
    currencyMinorUnits: 2,
    gdpRank: 5,
  );

  /// India (`en_IN`).
  static const CoFakerCountry india = CoFakerCountry(
    code: 'IN',
    alpha3: 'IND',
    locale: 'en_IN',
    name: 'India',
    nativeName: 'India',
    callingCode: '+91',
    currencyCode: 'INR',
    currencySymbol: '₹',
    currencyMinorUnits: 2,
    gdpRank: 6,
  );

  /// France (`fr_FR`).
  static const CoFakerCountry france = CoFakerCountry(
    code: 'FR',
    alpha3: 'FRA',
    locale: 'fr_FR',
    name: 'France',
    nativeName: 'France',
    callingCode: '+33',
    currencyCode: 'EUR',
    currencySymbol: '€',
    currencyMinorUnits: 2,
    gdpRank: 7,
  );

  /// Russia (`ru_RU`).
  static const CoFakerCountry russia = CoFakerCountry(
    code: 'RU',
    alpha3: 'RUS',
    locale: 'ru_RU',
    name: 'Russia',
    nativeName: 'Россия',
    callingCode: '+7',
    currencyCode: 'RUB',
    currencySymbol: '₽',
    currencyMinorUnits: 2,
    gdpRank: 8,
  );

  /// Italy (`it_IT`).
  static const CoFakerCountry italy = CoFakerCountry(
    code: 'IT',
    alpha3: 'ITA',
    locale: 'it_IT',
    name: 'Italy',
    nativeName: 'Italia',
    callingCode: '+39',
    currencyCode: 'EUR',
    currencySymbol: '€',
    currencyMinorUnits: 2,
    gdpRank: 9,
  );

  /// Canada (`en_CA`).
  static const CoFakerCountry canada = CoFakerCountry(
    code: 'CA',
    alpha3: 'CAN',
    locale: 'en_CA',
    name: 'Canada',
    nativeName: 'Canada',
    callingCode: '+1',
    currencyCode: 'CAD',
    currencySymbol: r'$',
    currencyMinorUnits: 2,
    gdpRank: 10,
  );

  /// Brazil (`pt_BR`). See the class documentation for why it is included.
  static const CoFakerCountry brazil = CoFakerCountry(
    code: 'BR',
    alpha3: 'BRA',
    locale: 'pt_BR',
    name: 'Brazil',
    nativeName: 'Brasil',
    callingCode: '+55',
    currencyCode: 'BRL',
    currencySymbol: r'R$',
    currencyMinorUnits: 2,
    gdpRank: 11,
  );

  /// Spain (`es_ES`), the country of Spanish. See the class documentation.
  static const CoFakerCountry spain = CoFakerCountry(
    code: 'ES',
    alpha3: 'ESP',
    locale: 'es_ES',
    name: 'Spain',
    nativeName: 'España',
    callingCode: '+34',
    currencyCode: 'EUR',
    currencySymbol: '€',
    currencyMinorUnits: 2,
    gdpRank: 12,
  );

  /// Saudi Arabia (`ar_SA`), the country of Arabic. See the class
  /// documentation.
  static const CoFakerCountry saudiArabia = CoFakerCountry(
    code: 'SA',
    alpha3: 'SAU',
    locale: 'ar_SA',
    name: 'Saudi Arabia',
    nativeName: 'المملكة العربية السعودية',
    callingCode: '+966',
    currencyCode: 'SAR',
    currencySymbol: 'ر.س',
    currencyMinorUnits: 2,
    gdpRank: 19,
  );

  /// The ten largest economies by nominal GDP in [gdpSource], largest first.
  static const List<CoFakerCountry> gdpTop10 = <CoFakerCountry>[
    unitedStates,
    china,
    germany,
    japan,
    unitedKingdom,
    india,
    france,
    russia,
    italy,
    canada,
  ];

  /// The countries outside the GDP ranking that carry the national locale of
  /// a demo language: [spain] for Spanish and [saudiArabia] for Arabic.
  static const List<CoFakerCountry> languageCountries = <CoFakerCountry>[
    spain,
    saudiArabia,
  ];

  /// Every supported country by [CoFakerCountry.gdpRank]: [gdpTop10], then
  /// [brazil], then [languageCountries].
  static const List<CoFakerCountry> all = <CoFakerCountry>[
    ...gdpTop10,
    brazil,
    ...languageCountries,
  ];

  /// Finds a country by ISO 3166-1 alpha-2 or alpha-3 code, ignoring case.
  ///
  /// Returns `null` for countries without a national locale.
  static CoFakerCountry? byCode(String code) {
    final key = code.trim().toUpperCase();
    for (final country in all) {
      if (country.code == key || country.alpha3 == key) return country;
    }
    return null;
  }
}
