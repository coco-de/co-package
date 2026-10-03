import '../co_faker.dart';
import 'authored_roles.dart';
import 'co_fake_remit_recipient.dart';
import 'co_fake_remittance.dart';
import 'co_faker_fx.dart';

/// Safe offline remittance examples for PRD #657.
class CoFakerRemit {
  /// Uses only the supplied generator.
  const CoFakerRemit(this.faker);

  /// Clock, locale and random source for examples.
  final CoFaker faker;

  /// Supported corridor ISO country codes.
  static const countryCodes = ['VN', 'PH', 'NP', 'US', 'CN'];

  /// Payout-method codes used by the recipe.
  static const payoutMethods = ['bank_account', 'cash_pickup', 'mobile_wallet'];

  /// Purpose codes; labels belong to the consuming app.
  static const purposes = [
    'family_support',
    'tuition',
    'living_expense',
    'medical',
    'gift',
    'other',
  ];

  /// Funding-source codes for illustrative transfers.
  static const fundSources = ['salary', 'savings', 'business_income', 'other'];

  /// Complete PRD #657 workflow status set.
  static const statuses = [
    'submitted',
    'under_review',
    'approved',
    'sent',
    'delivered',
    'on_hold',
    'rejected',
    'canceled',
  ];
  static const _corridors = {
    'VN': ('베트남', 'Vietnam', 'VND', 17.85),
    'PH': ('필리핀', 'Philippines', 'PHP', 0.0394),
    'NP': ('네팔', 'Nepal', 'NPR', 0.0926),
    'US': ('미국', 'United States', 'USD', 0.0007),
    'CN': ('중국', 'China', 'CNY', 0.0049),
  };

  /// Produces a matching country/currency with a masked name and account.
  CoFakeRemitRecipient recipient({
    int index = 0,
    String? countryCode,
    String? payoutMethod,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index');
    }
    final country = countryCode ?? faker.random.pick<String>(countryCodes);
    final corridor = _corridors[country];
    if (corridor == null) {
      throw ArgumentError.value(country, 'countryCode', 'unknown corridor');
    }
    final payout = payoutMethod ?? faker.random.pick<String>(payoutMethods);
    if (!payoutMethods.contains(payout)) {
      throw ArgumentError.value(payout, 'payoutMethod');
    }
    return CoFakeRemitRecipient(
      id: index + 1,
      name:
          '${faker.random.string(1, alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}*** ${faker.random.string(1, alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}. ${faker.random.string(1, alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}.',
      countryCode: country,
      countryName: localized(faker, corridor.$1, corridor.$2),
      currencyCode: corridor.$3,
      payoutMethod: payout,
      bankName: localized(
        faker,
        '누리파트너은행(가상)',
        'Nuri partner bank (fictional)',
      ),
      accountMasked: CoFakerFx(faker).maskedAccount(),
    );
  }

  /// Generates matching country/currency and receiveAmount = sendAmount × rate.
  CoFakeRemittance transfer({
    int index = 0,
    CoFakeRemitRecipient? recipient,
    int? sendAmount,
    String? status,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index');
    }
    final receiver = recipient ?? this.recipient(index: index);
    final corridor = _corridors[receiver.countryCode];
    if (corridor == null || corridor.$3 != receiver.currencyCode) {
      throw ArgumentError.value(
        receiver.countryCode,
        'recipient',
        'country/currency mismatch',
      );
    }
    final amount = sendAmount ?? faker.number.int(min: 10, max: 500) * 10000;
    if (amount < 10000 || amount > 5000000) {
      throw ArgumentError.value(amount, 'sendAmount', '10000..5000000');
    }
    final stage = status ?? faker.random.pickBalanced<String>(statuses, index);
    if (!statuses.contains(stage)) {
      throw ArgumentError.value(stage, 'status');
    }
    final utc = faker.now.toUtc();
    final date = utc.toIso8601String().substring(2, 10).replaceAll('-', '');
    final requested = utc.subtract(
      Duration(minutes: faker.random.int(min: 60, max: 14400)),
    );
    return CoFakeRemittance(
      referenceNo: 'NR-$date-${(index + 1).toString().padLeft(4, '0')}',
      recipient: receiver,
      sendAmount: amount,
      feeAmount: 5000,
      appliedRate: corridor.$4,
      receiveAmount: double.parse((amount * corridor.$4).toStringAsFixed(2)),
      purpose: faker.random.pick(purposes),
      fundSource: faker.random.pick(fundSources),
      status: stage,
      requestedAt: requested,
      expectedArrivalAt: requested.add(const Duration(days: 1)),
    );
  }

  /// A chronological permitted-state path ending at the transfer's status.
  List<Map<String, Object?>> milestones(CoFakeRemittance transfer) {
    final path = switch (transfer.status) {
      'submitted' => ['submitted'],
      'under_review' => ['submitted', 'under_review'],
      'on_hold' => ['submitted', 'under_review', 'on_hold'],
      'rejected' => ['submitted', 'under_review', 'rejected'],
      'canceled' => ['submitted', 'canceled'],
      'approved' => ['submitted', 'under_review', 'approved'],
      'sent' => ['submitted', 'under_review', 'approved', 'sent'],
      'delivered' => [
        'submitted',
        'under_review',
        'approved',
        'sent',
        'delivered',
      ],
      _ => throw ArgumentError.value(transfer.status, 'status'),
    };
    return List.generate(
      path.length,
      (i) => {
        'transferReference': transfer.referenceNo,
        'stage': path[i],
        'occurredAt': transfer.requestedAt
            .add(Duration(minutes: i * 10))
            .toUtc()
            .toIso8601String(),
      },
      growable: false,
    );
  }
}
