/// A fictional currency quote, not a live market rate. Amounts refer to
/// [unitAmount] foreign units (JPY and VND are quoted per 100).
class CoFakeFxCurrency {
  /// Constructs an illustrative quote with its unit and banknote catalog.
  const CoFakeFxCurrency({
    required this.code,
    required this.name,
    required this.unitAmount,
    required this.baseRate,
    required this.denominations,
  });

  /// ISO currency code.
  final String code;

  /// Localized currency name.
  final String name;

  /// Foreign units to which the quote applies.
  final int unitAmount;

  /// Fictional KRW quote per [unitAmount].
  final double baseRate;

  /// Available illustrative banknotes.
  final List<int> denominations;

  /// Primitive adapter suitable for fixture JSON.
  Map<String, Object?> toJson() => {
    'currencyCode': code,
    'currencyName': name,
    'unitAmount': unitAmount,
    'baseRate': baseRate,
    'denominations': denominations,
  };
}
