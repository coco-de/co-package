import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// A currency format of a language, the country whose data it must agree
/// with, and how it writes 1234 and 1234.56.
typedef _Case = ({
  String name,
  CoCurrencyFormat format,
  String? country,
  String whole,
  String fraction,
});

const String _nbsp = ' ';

const List<_Case> _cases = <_Case>[
  (
    name: 'English dollars',
    format: CoCurrencyFormat.usd,
    country: null,
    whole: r'$1,234',
    fraction: r'$1,235',
  ),
  (
    name: 'Korean won',
    format: CoCurrencyFormat.korean,
    country: null,
    whole: '1,234',
    fraction: '1,235',
  ),
  (
    name: 'Japanese yen: symbol first, no minor units',
    format: CoCurrencyFormat(code: 'JPY', symbol: '¥'),
    country: 'JP',
    whole: '¥1,234',
    fraction: '¥1,235',
  ),
  (
    name: 'Chinese yuan: symbol first, two decimals',
    format: CoCurrencyFormat(code: 'CNY', symbol: '¥', fractionDigits: 2),
    country: 'CN',
    whole: '¥1,234.00',
    fraction: '¥1,234.56',
  ),
  (
    name: 'German euro: symbol last, dot and comma swapped',
    format: CoCurrencyFormat(
      code: 'EUR',
      symbol: '€',
      pattern: '{amount}$_nbsp{symbol}',
      groupSeparator: '.',
      decimalSeparator: ',',
      fractionDigits: 2,
    ),
    country: 'DE',
    whole: '1.234,00$_nbsp€',
    fraction: '1.234,56$_nbsp€',
  ),
  (
    name: 'French euro: spaces between thousands',
    format: CoCurrencyFormat(
      code: 'EUR',
      symbol: '€',
      pattern: '{amount}$_nbsp{symbol}',
      groupSeparator: _nbsp,
      decimalSeparator: ',',
      fractionDigits: 2,
    ),
    country: 'FR',
    whole: '1${_nbsp}234,00$_nbsp€',
    fraction: '1${_nbsp}234,56$_nbsp€',
  ),
  (
    name: 'Russian ruble: symbol last, spaces between thousands',
    format: CoCurrencyFormat(
      code: 'RUB',
      symbol: '₽',
      pattern: '{amount}$_nbsp{symbol}',
      groupSeparator: _nbsp,
      decimalSeparator: ',',
      fractionDigits: 2,
    ),
    country: 'RU',
    whole: '1${_nbsp}234,00$_nbsp₽',
    fraction: '1${_nbsp}234,56$_nbsp₽',
  ),
  (
    name: 'Italian euro',
    format: CoCurrencyFormat(
      code: 'EUR',
      symbol: '€',
      pattern: '{amount}$_nbsp{symbol}',
      groupSeparator: '.',
      decimalSeparator: ',',
      fractionDigits: 2,
    ),
    country: 'IT',
    whole: '1.234,00$_nbsp€',
    fraction: '1.234,56$_nbsp€',
  ),
  (
    name: 'Brazilian real: symbol and space first',
    format: CoCurrencyFormat(
      code: 'BRL',
      symbol: r'R$',
      pattern: '{symbol}$_nbsp{amount}',
      groupSeparator: '.',
      decimalSeparator: ',',
      fractionDigits: 2,
    ),
    country: 'BR',
    whole: 'R\$${_nbsp}1.234,00',
    fraction: 'R\$${_nbsp}1.234,56',
  ),
];

void main() {
  group('CoCurrencyFormat', () {
    for (final c in _cases) {
      test('${c.name} writes 1234 and 1234.56', () {
        expect(c.format.format(1234), c.whole);
        expect(c.format.format(1234.56), c.fraction);
      });
    }

    test('the formats of a language agree with its country data', () {
      for (final c in _cases.where((c) => c.country != null)) {
        final country = CoFakerCountries.byCode(c.country!)!;
        expect(c.format.code, country.currencyCode, reason: c.name);
        expect(c.format.symbol, country.currencySymbol, reason: c.name);
        expect(
          c.format.fractionDigits,
          country.currencyMinorUnits,
          reason: c.name,
        );
      }
    });

    test('groups every three digits and keeps small numbers whole', () {
      const format = CoCurrencyFormat.usd;
      expect(
        <int>[0, 7, 999, 1000, 12345, 1234567, 100000000].map(format.format),
        <String>[
          r'$0',
          r'$7',
          r'$999',
          r'$1,000',
          r'$12,345',
          r'$1,234,567',
          r'$100,000,000',
        ],
      );
      expect(CoCurrencyFormat.korean.format(480000), '480,000');
    });

    test('a negative amount gets a sign before the whole text', () {
      expect(CoCurrencyFormat.usd.format(-1234), r'-$1,234');
      expect(CoCurrencyFormat.korean.format(-5000), '-5,000');
      expect(_cases[4].format.format(-1234.5), '-1.234,50$_nbsp€');
    });

    test('the pattern places the symbol or the code, or neither', () {
      const code = CoCurrencyFormat(
        code: 'CHF',
        symbol: 'Fr.',
        pattern: '{code} {amount}',
        groupSeparator: '’',
      );
      expect(code.format(1234567), 'CHF 1’234’567');
      const bare = CoCurrencyFormat(groupSeparator: '');
      expect(bare.format(1234567), r'$1234567');
      const none = CoCurrencyFormat(pattern: '{amount}', groupSeparator: '');
      expect(none.format(1234567), '1234567');
    });

    test('the built-in formats are the ones the data sets use', () {
      expect(CoFakerClinicData.english.currency, same(CoCurrencyFormat.usd));
      expect(CoFakerSaasData.english.currency, same(CoCurrencyFormat.usd));
      expect(CoFakerClinicData.korean.currency, same(CoCurrencyFormat.korean));
      expect(CoFakerSaasData.korean.currency, same(CoCurrencyFormat.korean));
      expect(CoCurrencyFormat.usd.code, 'USD');
      expect(CoCurrencyFormat.korean.code, 'KRW');
      expect(CoCurrencyFormat.korean.symbol, '₩');
    });

    test('money() writes the amounts the way the generators do', () {
      final en = CoFaker(locale: 'en', seed: 1);
      final ko = CoFaker(locale: 'ko', seed: 1);
      expect(en.clinic.money(1234567), r'$1,234,567');
      expect(en.saas.money(79), r'$79');
      expect(ko.clinic.money(1234567), '1,234,567');
      expect(ko.saas.money(99000), '99,000');
    });
  });
}
