/// How an amount of money is written: the currency, where its symbol goes,
/// and the separators.
///
/// `faker.clinic` and `faker.saas` generate amounts as whole numbers of the
/// currency's main unit, and a data set's [CoFakerClinicData.currency] or
/// [CoFakerSaasData.currency] decides how a text writes one (see
/// `faker.clinic.money`). The same amount `1234` reads differently by
/// language:
///
/// | Format | Written |
/// | --- | --- |
/// | [usd] | `$1,234` |
/// | [korean] | `1,234` |
/// | `CoCurrencyFormat(code: 'JPY', symbol: '¥')` | `¥1,234` |
/// | `CoCurrencyFormat(code: 'EUR', symbol: '€', pattern: '{amount} {symbol}', groupSeparator: '.', decimalSeparator: ',', fractionDigits: 2)` | `1.234,00 €` |
/// | `CoCurrencyFormat(code: 'BRL', symbol: 'R$', pattern: '{symbol} {amount}', groupSeparator: '.', decimalSeparator: ',', fractionDigits: 2)` | `R$ 1.234,00` |
/// | `CoCurrencyFormat(code: 'RUB', symbol: '₽', pattern: '{amount} {symbol}', groupSeparator: ' ', decimalSeparator: ',', fractionDigits: 2)` | `1 234,00 ₽` |
///
/// [code], [symbol], and [fractionDigits] describe the currency. They should
/// agree with the country data of the language (`CoFakerCountry.currencyCode`,
/// `currencySymbol`, and `currencyMinorUnits`); [fractionDigits] of `0` writes
/// whole units only, as English `$1,234` does although the dollar has two
/// minor units.
class CoCurrencyFormat {
  /// Creates a currency format. The defaults write US dollars as `$1,234`.
  const CoCurrencyFormat({
    this.code = 'USD',
    this.symbol = r'$',
    this.pattern = '{symbol}{amount}',
    this.groupSeparator = ',',
    this.decimalSeparator = '.',
    this.fractionDigits = 0,
  }) : assert(
         fractionDigits >= 0 && fractionDigits <= 20,
         'fractionDigits must be between 0 and 20',
       );

  /// US dollars written `$1,234`: the format of the English data.
  static const CoCurrencyFormat usd = CoCurrencyFormat();

  /// Korean won written as a bare number, `1,234`: the format of the Korean
  /// data, whose texts add the unit (`1,234원`) themselves.
  static const CoCurrencyFormat korean = CoCurrencyFormat(
    code: 'KRW',
    symbol: '₩',
    pattern: '{amount}',
  );

  /// ISO 4217 currency code such as `JPY`.
  final String code;

  /// Currency display symbol such as `¥`.
  final String symbol;

  /// How the number and the currency are combined: `{amount}` is the number,
  /// `{symbol}` the [symbol], and `{code}` the [code]. A pattern without
  /// `{symbol}` writes a bare number.
  ///
  /// Use `{symbol}{amount}` for `¥1,234`, `{symbol} {amount}` for `R$ 1.234`,
  /// and `{amount} {symbol}` for `1.234 €`. A no-break space (` `) keeps
  /// the symbol on the line of the number.
  final String pattern;

  /// Text between thousands: `,` for `1,234`, `.` for `1.234`, a space for
  /// `1 234`. Empty writes no grouping.
  final String groupSeparator;

  /// Text between the whole part and the fraction: `.` or `,`.
  final String decimalSeparator;

  /// Digits after the [decimalSeparator], from 0 to 20. Whole amounts are
  /// padded with zeros (`1.234,00`); use the currency's minor units (`2` for
  /// the euro, `0` for the yen) or `0` to write whole units.
  final int fractionDigits;

  /// Writes [amount] in this format, such as `$1,234` for `1234`.
  ///
  /// A negative amount gets a leading `-` before the whole text, unless it
  /// rounds to zero.
  String format(num amount) {
    final fixed = amount.abs().toStringAsFixed(fractionDigits);
    final dot = fixed.indexOf('.');
    final whole = _group(dot < 0 ? fixed : fixed.substring(0, dot));
    final number = dot < 0
        ? whole
        : '$whole$decimalSeparator${fixed.substring(dot + 1)}';
    final text = pattern
        .replaceAll('{symbol}', symbol)
        .replaceAll('{code}', code)
        .replaceAll('{amount}', number);
    final negative = amount < 0 && fixed.contains(_nonZeroDigit);
    return negative ? '-$text' : text;
  }

  static final RegExp _nonZeroDigit = RegExp('[1-9]');

  String _group(String digits) {
    if (groupSeparator.isEmpty) return digits;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(groupSeparator);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  String toString() => 'CoCurrencyFormat($code ${format(1234)})';
}
