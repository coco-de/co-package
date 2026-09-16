/// Localized data used by [CoFaker].
///
/// Every collection is optional. An empty collection falls back to English,
/// which makes adding a partial custom locale inexpensive.
class CoFakerLocale {
  /// Creates a locale data set.
  const CoFakerLocale({
    required this.code,
    this.firstNames = const <String>[],
    this.lastNames = const <String>[],
    this.genders = const <String>[],
    this.cities = const <String>[],
    this.countries = const <String>[],
    this.countryCodes = const <String>[],
    this.streetNames = const <String>[],
    this.companyNames = const <String>[],
    this.jobTitles = const <String>[],
    this.words = const <String>[],
    this.productAdjectives = const <String>[],
    this.productNouns = const <String>[],
    this.categories = const <String>[],
    this.places = const <String>[],
    this.domains = const <String>[],
    this.emailDomains = const <String>[],
    this.phoneFormats = const <String>[],
    this.currencyCode = 'USD',
    this.currencySymbol = r'$',
    this.nameFormat = '{first} {last}',
    this.addressFormat = '{number} {street}, {city}',
    this.postalCodeFormat = '#####',
  });

  /// Locale identifier such as `en`, `ko`, or `pt_BR`.
  final String code;

  /// Given names.
  final List<String> firstNames;

  /// Family names.
  final List<String> lastNames;

  /// Localized gender labels.
  final List<String> genders;

  /// City names.
  final List<String> cities;

  /// Country names.
  final List<String> countries;

  /// Country codes.
  final List<String> countryCodes;

  /// Street names without a house number.
  final List<String> streetNames;

  /// Company names.
  final List<String> companyNames;

  /// Job titles.
  final List<String> jobTitles;

  /// Words used by the text module.
  final List<String> words;

  /// Product name adjectives.
  final List<String> productAdjectives;

  /// Product name nouns.
  final List<String> productNouns;

  /// Product categories.
  final List<String> categories;

  /// Meeting places and venues such as stations, plazas and lobbies.
  final List<String> places;

  /// Domain names used by generated URLs.
  final List<String> domains;

  /// Domains used by generated email addresses.
  final List<String> emailDomains;

  /// Phone templates containing `#` placeholders.
  final List<String> phoneFormats;

  /// ISO 4217 currency code.
  final String currencyCode;

  /// Currency display symbol.
  final String currencySymbol;

  /// Name template with `{first}` and `{last}` placeholders.
  final String nameFormat;

  /// Address template with `{number}`, `{street}`, and `{city}` placeholders.
  final String addressFormat;

  /// Postal code template. `#` is replaced with a random digit.
  final String postalCodeFormat;

  /// Merges this locale over [fallback].
  ///
  /// A collection is considered unspecified when it is empty. Scalar values
  /// use the fallback when they still have the constructor default.
  CoFakerLocale merge(CoFakerLocale fallback) {
    return CoFakerLocale(
      code: code,
      firstNames: firstNames.isEmpty ? fallback.firstNames : firstNames,
      lastNames: lastNames.isEmpty ? fallback.lastNames : lastNames,
      genders: genders.isEmpty ? fallback.genders : genders,
      cities: cities.isEmpty ? fallback.cities : cities,
      countries: countries.isEmpty ? fallback.countries : countries,
      countryCodes: countryCodes.isEmpty ? fallback.countryCodes : countryCodes,
      streetNames: streetNames.isEmpty ? fallback.streetNames : streetNames,
      companyNames: companyNames.isEmpty ? fallback.companyNames : companyNames,
      jobTitles: jobTitles.isEmpty ? fallback.jobTitles : jobTitles,
      words: words.isEmpty ? fallback.words : words,
      productAdjectives: productAdjectives.isEmpty
          ? fallback.productAdjectives
          : productAdjectives,
      productNouns: productNouns.isEmpty ? fallback.productNouns : productNouns,
      categories: categories.isEmpty ? fallback.categories : categories,
      places: places.isEmpty ? fallback.places : places,
      domains: domains.isEmpty ? fallback.domains : domains,
      emailDomains: emailDomains.isEmpty ? fallback.emailDomains : emailDomains,
      phoneFormats: phoneFormats.isEmpty ? fallback.phoneFormats : phoneFormats,
      currencyCode: currencyCode == 'USD'
          ? fallback.currencyCode
          : currencyCode,
      currencySymbol: currencySymbol == r'$'
          ? fallback.currencySymbol
          : currencySymbol,
      nameFormat: nameFormat == '{first} {last}'
          ? fallback.nameFormat
          : nameFormat,
      addressFormat: addressFormat == '{number} {street}, {city}'
          ? fallback.addressFormat
          : addressFormat,
      postalCodeFormat: postalCodeFormat == '#####'
          ? fallback.postalCodeFormat
          : postalCodeFormat,
    );
  }
}
