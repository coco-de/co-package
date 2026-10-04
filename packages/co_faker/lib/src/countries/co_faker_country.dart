/// A country that ships with a national co_faker locale.
///
/// Countries are listed in `CoFakerCountries`, which also documents the GDP
/// ranking behind [gdpRank].
class CoFakerCountry {
  /// Creates a country description.
  const CoFakerCountry({
    required this.code,
    required this.alpha3,
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.callingCode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyMinorUnits,
    required this.gdpRank,
  });

  /// ISO 3166-1 alpha-2 code such as `JP`.
  final String code;

  /// ISO 3166-1 alpha-3 code such as `JPN`.
  final String alpha3;

  /// Code of the national locale such as `ja_JP`.
  final String locale;

  /// English short name such as `Japan`.
  final String name;

  /// Name in the language of the national locale such as `日本`.
  final String nativeName;

  /// International calling code with a leading `+`, such as `+81`.
  final String callingCode;

  /// ISO 4217 currency code such as `JPY`.
  final String currencyCode;

  /// Currency display symbol such as `¥`.
  final String currencySymbol;

  /// Digits after the decimal separator in prices (ISO 4217 minor units).
  final int currencyMinorUnits;

  /// Rank by nominal GDP, starting at 1, according to
  /// `CoFakerCountries.gdpSource`.
  final int gdpRank;

  @override
  String toString() => 'CoFakerCountry($code)';
}
