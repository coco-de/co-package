import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(DemoFormat.ensureInitialized);

  group('DemoFormat.money', () {
    test('formats the same amount and currency for each language', () {
      expect(
        DemoFormat.money(1003000, currencyCode: 'KRW', locale: DemoLocale.ko),
        '₩1,003,000',
      );
      expect(
        DemoFormat.money(1003000, currencyCode: 'KRW', locale: DemoLocale.de),
        // intl 은 숫자와 기호 사이에 줄바꿈 없는 공백(U+00A0)을 둔다.
        '1.003.000\u00a0₩',
      );
      for (final locale in DemoLocale.values) {
        final text = DemoFormat.money(
          1003000,
          currencyCode: 'KRW',
          locale: locale,
        );
        expect(text, contains('₩'), reason: locale.tag);
        expect(
          text.replaceAll(RegExp(r'[^0-9]'), ''),
          '1003000',
          reason: '${locale.tag}: $text',
        );
      }
    });
  });

  group('DemoFormat.date', () {
    test('uses the language month names with ASCII digits', () {
      final value = DateTime.utc(2026, 1, 15);
      expect(DemoFormat.date(value, locale: DemoLocale.ja), '2026年1月15日');
      expect(DemoFormat.date(value, locale: DemoLocale.en), 'Jan 15, 2026');
      final arabic = DemoFormat.date(value, locale: DemoLocale.ar);
      expect(arabic, contains('2026'));
      expect(RegExp('[٠-٩]').hasMatch(arabic), isFalse);
    });
  });

  group('DemoFormat.latinDigits', () {
    test('turns Arabic-Indic digits into ASCII', () {
      expect(DemoFormat.latinDigits('١٢٣٤ ۵۶'), '1234 56');
      expect(DemoFormat.latinDigits('₩1,003,000'), '₩1,003,000');
    });
  });
}
