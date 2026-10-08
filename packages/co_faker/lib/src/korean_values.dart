/// Which Korean-only values a clinic or SaaS data set generates.
///
/// A few values that `faker.clinic` and `faker.saas` generate exist only in
/// Korea: resident registration numbers (주민등록번호) shown masked on a
/// patient, business registration numbers (사업자등록번호) of a tenant, card
/// approval and cash receipt numbers (현금영수증), road-name addresses and the
/// numbering plan of mobile and landline phones, and the public holidays
/// (`CoFakerKorea.holidays`) that decide a closure notice. The insurance codes
/// `nhis`, `medicalAid1`, and `medicalAid2` (건강보험, 의료급여) and the insurer
/// texts of the integration results are Korean concepts too, but they are
/// authored text: a language writes its own labels for the same codes.
///
/// The data set chooses, through [CoFakerClinicData.koreanValues] and
/// [CoFakerSaasData.koreanValues], so that a language other than Korean never
/// gets a Korean value: it uses [none], and the generators answer with a
/// neutral substitute (a configurable masked ID, a plain authorization code,
/// no holiday calendar, the phone numbers and national addresses of its own
/// locale).
enum CoKoreanValues {
  /// Korean contact data and every Korean-only value: Korean mobile and
  /// landline numbers, road-name addresses with Korean postal codes, masked
  /// resident registration numbers, business registration numbers, card
  /// approval numbers, masked cash receipt numbers, and the Korean holiday
  /// calendar. The Korean data sets use it.
  korean,

  /// The phone numbers and addresses of the locale, plus the Korean-only
  /// values that the English data has always generated: masked resident
  /// registration numbers, business registration numbers, 8-digit card
  /// approval numbers, masked cash receipt numbers, and the Korean holiday
  /// calendar (with Korean names for the holidays that the data does not
  /// rename).
  ///
  /// It is kept so that English output stays byte for byte stable, and it is
  /// the default of a data set that does not choose, so custom data written
  /// before this option existed keeps its output.
  legacy,

  /// No Korean-only value. Phones come from `faker.internet.phoneNumber()`,
  /// addresses from `faker.address.postalAddress()` of a national locale,
  /// the patient ID from `maskedIdFormat`, the business number from
  /// `businessNumberFormat`, a card payment carries a plain 6-digit
  /// authorization code and no cash receipt number, and closure notices have
  /// no public holidays. New language data uses it.
  none,
}
