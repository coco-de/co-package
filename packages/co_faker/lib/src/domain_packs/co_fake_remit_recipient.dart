/// A fictional remittance recipient, with a masked name and account only.
class CoFakeRemitRecipient {
  /// Constructs a masked, fictional corridor recipient.
  const CoFakeRemitRecipient({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.payoutMethod,
    required this.bankName,
    required this.accountMasked,
  });

  /// Fixture-local positive identifier.
  final int id;

  /// Romanized initials only.
  final String name;

  /// ISO country code of the supported corridor.
  final String countryCode;

  /// Localized country name.
  final String countryName;

  /// Matching payout currency.
  final String currencyCode;

  /// Supported payout-method code.
  final String payoutMethod;

  /// Explicitly fictional partner-bank display label.
  final String bankName;

  /// Masked display, never a real bank identifier.
  final String accountMasked;

  /// Primitive JSON fixture representation.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'countryCode': countryCode,
    'country': countryName,
    'currencyCode': currencyCode,
    'payoutMethod': payoutMethod,
    'bankName': bankName,
    'accountMasked': accountMasked,
  };
}
