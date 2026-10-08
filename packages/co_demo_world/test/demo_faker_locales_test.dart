import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

void main() {
  group('DemoFakerLocales.table', () {
    test('maps every one of the eleven UI languages', () {
      expect(DemoFakerLocales.table.keys, unorderedEquals(DemoLocale.values));
    });

    test('uses the national data where co_faker has it', () {
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.en), 'en_US');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.zhHans), 'zh_CN');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.ja), 'ja_JP');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.de), 'de_DE');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.fr), 'fr_FR');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.pt), 'pt_BR');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.it), 'it_IT');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.ru), 'ru_RU');
      expect(DemoFakerLocales.fakerLocaleOf(DemoLocale.ko), 'ko');
    });

    test('reports which languages co_faker serves in English', () {
      final english = [
        for (final locale in DemoLocale.values)
          if (DemoFakerLocales.resolve(locale.tag).dataFallsBackToEnglish)
            locale,
      ];
      // co-package#71 adds Arabic; until then its display data is English.
      expect(english, [DemoLocale.ar]);
      expect(DemoFakerLocales.fakerDataLocaleOf(DemoLocale.ar), 'en');
      expect(DemoFakerLocales.fakerDataLocaleOf(DemoLocale.es), 'es');
    });
  });

  group('DemoFakerLocales.resolve', () {
    test('matches tags the way co_demo_prefs parses them', () {
      final cases = <String, DemoLocale>{
        'ko': DemoLocale.ko,
        'EN_us': DemoLocale.en,
        'zh-Hans': DemoLocale.zhHans,
        'zh': DemoLocale.zhHans,
        'zh-CN': DemoLocale.zhHans,
        'zh_SG': DemoLocale.zhHans,
        'ja-JP': DemoLocale.ja,
        'de': DemoLocale.de,
        'fr-CA': DemoLocale.fr,
        'es-MX': DemoLocale.es,
        'pt-PT': DemoLocale.pt,
        'it': DemoLocale.it,
        'ru': DemoLocale.ru,
        'AR': DemoLocale.ar,
      };
      cases.forEach((tag, expected) {
        final result = DemoFakerLocales.resolve(tag);
        expect(result.locale, expected, reason: tag);
        expect(result.reason, DemoLocaleResolutionReason.matched, reason: tag);
        expect(result.isFallback, isFalse, reason: tag);
        expect(
          result.fakerLocale,
          DemoFakerLocales.fakerLocaleOf(expected),
          reason: tag,
        );
      });
    });

    test('falls back without throwing and says why', () {
      expect(
        DemoFakerLocales.resolve(null).reason,
        DemoLocaleResolutionReason.missing,
      );
      expect(
        DemoFakerLocales.resolve('  ').reason,
        DemoLocaleResolutionReason.missing,
      );
      for (final tag in ['zh-Hant', 'zh-TW', 'zh_HK', 'zh-MO']) {
        final result = DemoFakerLocales.resolve(tag);
        expect(result.locale, DemoLocale.ko, reason: tag);
        expect(
          result.reason,
          DemoLocaleResolutionReason.traditionalChinese,
          reason: tag,
        );
      }
      final unknown = DemoFakerLocales.resolve(
        'xx-YY',
        fallback: DemoLocale.en,
      );
      expect(unknown.locale, DemoLocale.en);
      expect(unknown.reason, DemoLocaleResolutionReason.unsupported);
      expect(unknown.isFallback, isTrue);
    });
  });
}
