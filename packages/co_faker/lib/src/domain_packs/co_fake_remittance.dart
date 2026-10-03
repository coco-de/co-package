import 'co_fake_remit_recipient.dart';

/// A coherent, illustrative transfer. No real payment or banking identity.
class CoFakeRemittance {
  /// Constructs an illustrative transfer, usually through CoFakerRemit.
  const CoFakeRemittance({
    required this.referenceNo,
    required this.recipient,
    required this.sendAmount,
    required this.feeAmount,
    required this.appliedRate,
    required this.receiveAmount,
    required this.purpose,
    required this.fundSource,
    required this.status,
    required this.requestedAt,
    required this.expectedArrivalAt,
  });

  /// UTC-date-based fictional sequence reference.
  final String referenceNo;

  /// Linked recipient determining the country and payout currency.
  final CoFakeRemitRecipient recipient;

  /// KRW principal before fees.
  final int sendAmount;

  /// Example fee in KRW.
  final int feeAmount;

  /// Recipient currency units per KRW, rather than the FX pack's KRW quote.
  final double appliedRate;

  /// Rounded payout in the recipient's currency.
  final double receiveAmount;

  /// Transfer-purpose code.
  final String purpose;

  /// Funding-source code.
  final String fundSource;

  /// PRD workflow status code.
  final String status;

  /// UTC request time before the supplied clock.
  final DateTime requestedAt;

  /// Illustrative UTC arrival estimate after the request.
  final DateTime expectedArrivalAt;

  /// Integer denominator for the illustrative per-KRW quote (VN: 100).
  int get rateDenominator => recipient.currencyCode == 'VND' ? 100 : 10000;

  /// Integer numerator (VN: 1785), avoiding ambiguous quote-unit conversions.
  int get rateNumerator => (appliedRate * rateDenominator).round();

  /// Payout currency minor-unit precision (VND: 0, PHP/NPR: 2).
  int get receiveMinorDigits => recipient.currencyCode == 'VND' ? 0 : 2;

  /// Primitive integer payout adapter for workflow seed collections.
  int get receiveMinorUnits =>
      (receiveAmount * (receiveMinorDigits == 0 ? 1 : 100)).round();

  /// Primitive JSON representation with UTC dates.
  Map<String, Object?> toJson() => {
    'referenceNo': referenceNo,
    'recipientId': recipient.id,
    'recipientName': recipient.name,
    'receiveCountry': recipient.countryName,
    'receiveCurrency': recipient.currencyCode,
    'sendAmount': sendAmount,
    'feeAmount': feeAmount,
    'appliedRate': appliedRate,
    'receiveAmount': receiveAmount,
    'rateNumerator': rateNumerator,
    'rateDenominator': rateDenominator,
    'receiveMinorDigits': receiveMinorDigits,
    'receiveMinorUnits': receiveMinorUnits,
    'purpose': purpose,
    'fundSource': fundSource,
    'status': status,
    'requestedAt': requestedAt.toIso8601String(),
    'expectedArrivalAt': expectedArrivalAt.toIso8601String(),
  };
}
