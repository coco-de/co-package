/// A fictional phone number shape in national and international notation.
///
/// Both templates contain the same number of `#` placeholders, filled with
/// the same digits in order, so one generated number can be shown either way.
/// Every built-in format is fictional by construction: it is a range a
/// regulator reserves for fiction, or a prefix that no number type uses (see
/// `docs/countries.md`).
class CoFakerPhoneFormat {
  /// Creates a phone format.
  const CoFakerPhoneFormat({
    required this.national,
    required this.international,
    this.mobile = true,
  });

  /// Template as dialed inside the country, such as `090-0###-####`.
  final String national;

  /// Template with the calling code, such as `+81 90-0###-####`.
  final String international;

  /// Whether the number is a mobile number rather than a landline.
  final bool mobile;

  /// Number of `#` placeholders in each template.
  int get digitCount => '#'.allMatches(national).length;

  /// Fills the placeholders of the national or [international] template with
  /// [digits], in order.
  String render(List<int> digits, {bool international = false}) {
    if (digits.length != digitCount) {
      throw ArgumentError.value(digits, 'digits', 'needs $digitCount digits');
    }
    var next = 0;
    return (international ? this.international : national).replaceAllMapped(
      '#',
      (_) => '${digits[next++]}',
    );
  }
}
