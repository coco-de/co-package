import '../co_faker.dart';
import 'co_fake_fx_currency.dart';
import 'co_fake_fx_rate_point.dart';

/// Offline FX dictionaries and bounded, seeded UTC random walks.
class CoFakerFx {
  /// Uses only the supplied generator's clock and derived random streams.
  const CoFakerFx(this.faker);

  /// Source of locale, random streams and clock.
  final CoFaker faker;

  /// Shared recipe currencies; PHP/NPR are additional helper corridors.
  static const currencyCodes = ['USD', 'JPY', 'EUR', 'CNY', 'THB', 'VND'];
  static const _quotes = <String, (String, String, int, double, List<int>)>{
    'USD': ('미국 달러', 'US dollar', 1, 1452.30, [1, 5, 10, 20, 50, 100]),
    'JPY': ('일본 엔', 'Japanese yen', 100, 935.20, [1000, 2000, 5000, 10000]),
    'EUR': ('유로', 'Euro', 1, 1580.40, [5, 10, 20, 50, 100, 200]),
    'CNY': ('중국 위안', 'Chinese yuan', 1, 202.40, [1, 5, 10, 20, 50, 100]),
    'THB': ('태국 바트', 'Thai baht', 1, 41.20, [20, 50, 100, 500, 1000]),
    'VND': (
      '베트남 동',
      'Vietnamese dong',
      100,
      5.62,
      [10000, 20000, 50000, 100000, 200000, 500000],
    ),
    'PHP': ('필리핀 페소', 'Philippine peso', 1, 25.40, [20, 50, 100, 500, 1000]),
    'NPR': (
      '네팔 루피',
      'Nepalese rupee',
      1,
      10.80,
      [5, 10, 20, 50, 100, 500, 1000],
    ),
  };

  /// Selects a supported currency; unknown codes fail explicitly.
  CoFakeFxCurrency currency({String? code}) {
    final selected = code ?? faker.random.pick<String>(currencyCodes);
    final quote = _quotes[selected];
    if (quote == null) {
      throw ArgumentError.value(selected, 'code', 'unknown currency');
    }
    return CoFakeFxCurrency(
      code: selected,
      name: faker.locale.startsWith('ko') ? quote.$1 : quote.$2,
      unitAmount: quote.$3,
      baseRate: quote.$4,
      denominations: quote.$5,
    );
  }

  /// Selects a valid banknote unit for the supplied currency.
  int denomination({String? currencyCode}) =>
      faker.random.pick(currency(code: currencyCode).denominations);

  /// Masked display only; cannot produce a valid bank account.
  String maskedAccount() => faker.random.digits('****-**-####');

  /// Returns [days] chronological points ending at a supplied quote.
  /// Every point is positive and within ±15% of [endRate]. Extending the
  /// history preserves the overlapping points; no real clock or network is read.
  List<CoFakeFxRatePoint> rateSeries({
    String currencyCode = 'USD',
    int days = 365,
    DateTime? endAt,
    double? endRate,
  }) {
    if (days < 1 || days > 3660) {
      throw ArgumentError.value(days, 'days', '1..3660');
    }
    final quote = currency(code: currencyCode);
    final endpoint = endRate ?? quote.baseRate;
    if (!endpoint.isFinite || endpoint < 0.01) {
      throw ArgumentError.value(endpoint, 'endRate', 'finite and >= 0.01');
    }
    final utc = (endAt ?? faker.now).toUtc();
    final end = DateTime.utc(utc.year, utc.month, utc.day);
    final key = 'fx/rates/$currencyCode/${end.toIso8601String()}/$endpoint';
    var value = endpoint;
    final reversed = <CoFakeFxRatePoint>[];
    for (var back = 0; back < days; back++) {
      if (back > 0) {
        final step = faker
            .derive('$key/$back')
            .random
            .double(min: -0.006, max: 0.006);
        value = (value * (1 + step)).clamp(endpoint * 0.85, endpoint * 1.15);
      }
      reversed.add(
        CoFakeFxRatePoint(
          currencyCode: currencyCode,
          rate: back == 0
              ? endpoint
              : double.parse(
                  value.toStringAsFixed(2),
                ).clamp(endpoint * 0.85, endpoint * 1.15),
          recordedAt: end.subtract(Duration(days: back)),
        ),
      );
    }
    return List.unmodifiable(reversed.reversed);
  }
}
