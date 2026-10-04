/// A postal address of a national locale, split into the parts forms ask for.
///
/// [city], [region] and [postalCode] always belong together. [formatted] is
/// the one-line address in the country's usual order, such as
/// `1234 Oak Street, Austin, TX 78701` or `〒100-0011 東京都千代田区本町2丁目3-15`.
typedef CoPostalAddress = ({
  String line1,
  String city,
  String region,
  String regionCode,
  String postalCode,
  String countryCode,
  String country,
  String formatted,
});
