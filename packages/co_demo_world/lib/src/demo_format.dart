import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formats business values (A data) in the UI language without changing
/// them: the amount and the currency code stay the same, only grouping,
/// separators, symbol position and month names follow the language.
///
/// Digits are always ASCII 0–9, in every language.
abstract final class DemoFormat {
  static const Map<DemoLocale, String> _intlLocales = <DemoLocale, String>{
    DemoLocale.ko: 'ko',
    DemoLocale.en: 'en',
    DemoLocale.zhHans: 'zh',
    DemoLocale.ja: 'ja',
    DemoLocale.de: 'de',
    DemoLocale.fr: 'fr',
    DemoLocale.es: 'es',
    DemoLocale.pt: 'pt',
    DemoLocale.it: 'it',
    DemoLocale.ru: 'ru',
    DemoLocale.ar: 'ar',
  };

  /// The `package:intl` locale for [locale].
  static String intlLocaleOf(DemoLocale locale) => _intlLocales[locale]!;

  /// Loads date symbols for every demo language. Call once before [date] —
  /// the data is bundled, so this completes without I/O.
  static Future<void> ensureInitialized() async {
    for (final locale in _intlLocales.values) {
      await initializeDateFormatting(locale);
    }
  }

  /// [amount] in [currencyCode] formatted for [locale] (`₩1,003,000` in
  /// Korean, `1.003.000 ₩` in German). The currency is never converted.
  static String money(
    num amount, {
    required String currencyCode,
    required DemoLocale locale,
  }) => latinDigits(
    NumberFormat.simpleCurrency(
      locale: intlLocaleOf(locale),
      name: currencyCode,
    ).format(amount),
  );

  /// [value] with the grouping and decimal separators of [locale].
  static String decimal(num value, {required DemoLocale locale}) => latinDigits(
    NumberFormat.decimalPattern(intlLocaleOf(locale)).format(value),
  );

  /// [value] formatted with the `intl` [skeleton] (default `yMMMd`) for
  /// [locale]. Call [ensureInitialized] first.
  static String date(
    DateTime value, {
    required DemoLocale locale,
    String skeleton = 'yMMMd',
  }) => latinDigits(DateFormat(skeleton, intlLocaleOf(locale)).format(value));

  /// Replaces Arabic-Indic and Extended Arabic-Indic digits with ASCII
  /// digits.
  static String latinDigits(String text) {
    final buffer = StringBuffer();
    for (final unit in text.runes) {
      if (unit >= 0x0660 && unit <= 0x0669) {
        buffer.writeCharCode(0x30 + unit - 0x0660);
      } else if (unit >= 0x06F0 && unit <= 0x06F9) {
        buffer.writeCharCode(0x30 + unit - 0x06F0);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}
