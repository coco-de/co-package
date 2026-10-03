/// One daily fictional quote. [recordedAt] is midnight UTC.
class CoFakeFxRatePoint {
  /// Constructs a daily fictional observation.
  const CoFakeFxRatePoint({
    required this.currencyCode,
    required this.rate,
    required this.recordedAt,
  });

  /// ISO code of the quote.
  final String currencyCode;

  /// Fictional KRW rate per quote unit.
  final double rate;

  /// UTC observation date.
  final DateTime recordedAt;

  /// Serializes dates as UTC ISO-8601.
  Map<String, Object?> toJson() => {
    'currencyCode': currencyCode,
    'rate': rate,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };
}
