/// A city with the region it belongs to and its postal code templates.
///
/// A national locale picks one locality per address, so the city, region and
/// postal code of a generated address always agree. Postal code templates use
/// `#` for any digit, `@` for a digit from 1 to 9 and `?` for a letter from
/// `CoFakerNationalData.postalLetters`; every other character is literal.
class CoFakerLocality {
  /// Creates a locality.
  const CoFakerLocality({
    required this.city,
    required this.region,
    required this.regionCode,
    required this.postalCodes,
  });

  /// City, ward or district name as written in addresses.
  final String city;

  /// State, province, prefecture or region name.
  final String region;

  /// Short region code used in addresses, such as `CA`, `ON` or `MI`.
  final String regionCode;

  /// Postal code templates that start with the city's real prefix.
  final List<String> postalCodes;
}
