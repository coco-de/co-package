import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:test/test.dart';

import 'support/virtual_language.dart';

/// Language codes that must resolve to the same clinic and SaaS data, by the
/// language and its country, in every spelling a setting may use.
const Map<String, List<String>> _spellings = <String, List<String>>{
  'zh': <String>['zh', 'zh_CN', 'zh-CN', 'zh-Hans', 'zh_Hans_CN', 'ZH-cn'],
  'ja': <String>['ja', 'ja_JP', 'ja-JP', 'ja_JP.UTF-8'],
  'de': <String>['de', 'de_DE', 'de-AT'],
  'fr': <String>['fr', 'fr_FR', 'fr-CA'],
  'ru': <String>['ru', 'ru_RU'],
  'it': <String>['it', 'it_IT'],
  'pt': <String>['pt', 'pt_BR', 'pt-BR'],
};

void main() {
  // Data of two virtual languages, to tell which entry a locale reads.
  final chinese = const VirtualLanguage(
    locale: 'zh_cn',
    currency: CoCurrencyFormat(code: 'CNY', symbol: '¥', fractionDigits: 2),
    scale: CoClinicPriceScale(),
    saasScale: CoSaasPriceScale(),
  );
  final chineseClinic = chinese.clinic;
  final chineseSaas = chinese.saas;
  final japaneseClinic = virtualJapanese.clinic;

  final registry = <String, CoL10nClinicEntry>{
    'ko': (clinic: CoFakerClinicData.korean, saas: CoFakerSaasData.korean),
    'en': (clinic: CoFakerClinicData.english, saas: CoFakerSaasData.english),
    'zh': (clinic: chineseClinic, saas: chineseSaas),
    // A language that has clinic data but no SaaS data yet.
    'ja': (clinic: japaneseClinic, saas: null),
    // A stub that no Story has filled.
    'de': (clinic: null, saas: null),
  };

  CoFakerLocale pick(
    String code, {
    CoFakerLocale? selected,
    Map<String, CoL10nClinicEntry>? from,
  }) {
    return CoL10nClinic.select(
      selected ?? CoFakerLocales.resolve(code),
      fallback: CoFakerLocales.english,
      locale: CoFakerLocales.normalize(code),
      registry: from ?? registry,
    );
  }

  group('selecting the data of a locale', () {
    test('a supported language reads the data registered for it', () {
      for (final code in <String>[
        'zh',
        'zh_CN',
        'zh-CN',
        'zh-Hans',
        'zh_Hans_CN',
        'ZH-cn',
        'zh-Hans-TW',
      ]) {
        final locale = pick(code);
        expect(locale.clinic, same(chineseClinic), reason: code);
        expect(locale.saas, same(chineseSaas), reason: code);
      }
    });

    test('Korean locales read the Korean data', () {
      for (final code in <String>['ko', 'ko_KR', 'ko-KR', 'KO']) {
        final locale = pick(code);
        expect(locale.clinic, same(CoFakerClinicData.korean), reason: code);
        expect(locale.saas, same(CoFakerSaasData.korean), reason: code);
      }
    });

    test('English locales read the English data', () {
      for (final code in <String>['en', 'en_US', 'en-GB', 'en_IN', 'EN']) {
        final locale = pick(code);
        expect(locale.clinic, same(CoFakerClinicData.english), reason: code);
        expect(locale.saas, same(CoFakerSaasData.english), reason: code);
      }
    });

    test('a stub or a language without an entry falls back to English', () {
      for (final code in <String>[
        'de',
        'de_DE',
        'fr',
        'fr_FR',
        'es',
        'es_MX',
      ]) {
        final locale = pick(code);
        expect(locale.clinic, same(CoFakerClinicData.english), reason: code);
        expect(locale.saas, same(CoFakerSaasData.english), reason: code);
      }
    });

    test('an entry fills only the data it has', () {
      for (final code in <String>['ja', 'ja_JP', 'ja-JP']) {
        final locale = pick(code);
        expect(locale.clinic, same(japaneseClinic), reason: code);
        expect(locale.saas, same(CoFakerSaasData.english), reason: code);
      }
    });

    test('Traditional Chinese never receives the Simplified data', () {
      for (final code in <String>[
        'zh_TW',
        'zh-TW',
        'zh_HK',
        'zh-HK',
        'zh_MO',
        'zh-Hant',
        'zh_Hant_TW',
        'zh-Hant-HK',
        'zh-Hant-CN',
      ]) {
        expect(CoFakerLanguages.resolve(code).supported, isFalse, reason: code);
        final locale = pick(code);
        expect(locale.clinic, same(CoFakerClinicData.english), reason: code);
        expect(locale.saas, same(CoFakerSaasData.english), reason: code);
      }
    });

    test('an unsupported language or a custom code gets English', () {
      for (final code in <String>[
        'xx',
        'xx_YY',
        'ar',
        'und',
        'acme',
        'kok',
        '',
      ]) {
        final locale = pick(code);
        expect(locale.clinic, same(CoFakerClinicData.english), reason: code);
        expect(locale.saas, same(CoFakerSaasData.english), reason: code);
      }
    });

    test('a locale keeps the data it carries', () {
      final ownClinic = chinese.clinic;
      final ownSaas = chinese.saas;
      final clinicOnly = pick(
        'zh_CN',
        selected: CoFakerLocale(code: 'zh_cn', clinic: ownClinic),
      );
      expect(clinicOnly.clinic, same(ownClinic));
      expect(clinicOnly.saas, same(chineseSaas));
      final both = pick(
        'zh_CN',
        selected: CoFakerLocale(
          code: 'zh_cn',
          clinic: ownClinic,
          saas: ownSaas,
        ),
      );
      expect(both.clinic, same(ownClinic));
      expect(both.saas, same(ownSaas));
      final unsupported = pick(
        'acme',
        selected: CoFakerLocale(code: 'acme', clinic: ownClinic),
      );
      expect(unsupported.clinic, same(ownClinic));
      expect(unsupported.saas, same(CoFakerSaasData.english));
    });

    test('everything else of the locale is the same as before', () {
      final selected = CoFakerLocales.resolve('zh_CN');
      final merged = pick('zh_CN');
      final plain = selected.merge(CoFakerLocales.english);
      expect(merged.code, plain.code);
      expect(merged.firstNames, plain.firstNames);
      expect(merged.cities, plain.cities);
      expect(merged.currencyCode, plain.currencyCode);
      expect(merged.national, same(plain.national));
      expect(merged.phoneFormats, plain.phoneFormats);
    });
  });

  group('the registry', () {
    test('lists Korean, English, and the seven languages of the Epic', () {
      expect(
        CoL10nClinic.entries.keys,
        containsAll(<String>[
          'ko',
          'en',
          'zh',
          'ja',
          'de',
          'fr',
          'ru',
          'it',
          'pt',
        ]),
      );
      expect(CoL10nClinic.clinicOf('ko'), same(CoFakerClinicData.korean));
      expect(CoL10nClinic.saasOf('ko'), same(CoFakerSaasData.korean));
      expect(CoL10nClinic.clinicOf('en'), same(CoFakerClinicData.english));
      expect(CoL10nClinic.saasOf('en'), same(CoFakerSaasData.english));
      expect(CoL10nClinic.clinicOf('xx'), isNull);
      expect(CoL10nClinic.saasOf('xx'), isNull);
    });

    test('only registers languages that CoFakerLanguages supports', () {
      for (final code in CoL10nClinic.entries.keys) {
        final resolved = CoFakerLanguages.resolve(code);
        expect(resolved.supported, isTrue, reason: code);
        expect(resolved.language.code, code);
      }
    });

    test('data of a language other than Korean and English is neutral', () {
      for (final code in CoL10nClinic.entries.keys) {
        if (code == 'ko' || code == 'en') continue;
        final faker = CoFaker.forLanguage(code);
        final clinic = CoL10nClinic.clinicOf(code);
        final saas = CoL10nClinic.saasOf(code);
        if (clinic != null) {
          expect(clinic.koreanValues, CoKoreanValues.none, reason: code);
        }
        if (saas != null) {
          expect(saas.koreanValues, CoKoreanValues.none, reason: code);
        }
        final country = faker.country;
        if (country == null) continue;
        for (final currency in <CoCurrencyFormat?>[
          clinic?.currency,
          saas?.currency,
        ]) {
          if (currency == null) continue;
          expect(currency.code, country.currencyCode, reason: code);
          expect(currency.symbol, country.currencySymbol, reason: code);
          expect(
            currency.fractionDigits,
            country.currencyMinorUnits,
            reason: code,
          );
        }
      }
    });
  });

  group('CoFaker', () {
    test('Korean locales get the Korean data', () {
      for (final code in <String>['ko', 'ko_KR', 'ko-KR']) {
        final faker = CoFaker(locale: code, seed: 1);
        expect(faker.clinic.data, same(CoFakerClinicData.korean), reason: code);
        expect(faker.saas.data, same(CoFakerSaasData.korean), reason: code);
      }
      final forLanguage = CoFaker.forLanguage('ko-KR', seed: 1);
      expect(forLanguage.clinic.data, same(CoFakerClinicData.korean));
    });

    test('English locales get the English data', () {
      for (final code in <String>['en', 'en_US', 'en_GB', 'xx_YY', 'zh_TW']) {
        final faker = CoFaker(locale: code, seed: 1);
        expect(
          faker.clinic.data,
          same(CoFakerClinicData.english),
          reason: code,
        );
        expect(faker.saas.data, same(CoFakerSaasData.english), reason: code);
      }
    });

    test(
      'a language reads its registered data, or English until it has some',
      () {
        for (final entry in _spellings.entries) {
          final clinic = CoL10nClinic.clinicOf(entry.key);
          final saas = CoL10nClinic.saasOf(entry.key);
          for (final code in entry.value) {
            final faker = CoFaker(locale: code, seed: 1);
            expect(
              faker.clinic.data,
              same(clinic ?? CoFakerClinicData.english),
              reason: code,
            );
            expect(
              faker.saas.data,
              same(saas ?? CoFakerSaasData.english),
              reason: code,
            );
          }
          final forLanguage = CoFaker.forLanguage(entry.key, seed: 1);
          expect(
            forLanguage.clinic.data,
            same(clinic ?? CoFakerClinicData.english),
            reason: entry.key,
          );
          expect(
            forLanguage.saas.data,
            same(saas ?? CoFakerSaasData.english),
            reason: entry.key,
          );
        }
      },
    );

    test('Traditional Chinese and unsupported languages get English', () {
      for (final code in <String>[
        'zh_TW',
        'zh-Hant',
        'zh_HK',
        'zh_MO',
        'ar',
        'acme',
      ]) {
        final faker = CoFaker(locale: code, seed: 1);
        expect(
          faker.clinic.data,
          same(CoFakerClinicData.english),
          reason: code,
        );
        expect(faker.saas.data, same(CoFakerSaasData.english), reason: code);
      }
      final traditional = CoFaker.forLanguage('zh-Hant', seed: 1);
      expect(traditional.clinic.data, same(CoFakerClinicData.english));
    });

    test('a custom locale supplies its own data', () {
      final faker = virtualJapanese.faker();
      expect(faker.clinic.data.currency.code, 'JPY');
      expect(faker.saas.data.currency.code, 'JPY');
      expect(faker.clinic.data.koreanValues, CoKoreanValues.none);
      // The code of the locale decides nothing but the lookup: a custom
      // `ko` locale with English clinic data reads that data.
      final custom = CoFaker(
        locale: 'ko',
        seed: 1,
        locales: <String, CoFakerLocale>{
          'ko': const CoFakerLocale(
            code: 'ko',
            clinic: CoFakerClinicData.english,
            saas: CoFakerSaasData.english,
          ),
        },
      );
      expect(custom.clinic.money(1234), r'$1,234');
    });

    test('the generators of a stub language speak English, byte for byte', () {
      final now = DateTime.utc(2026, 10, 5);
      CoFaker english() => CoFaker.forLanguage('en', seed: 5, now: now);
      for (final code in <String>['zh', 'ja', 'de', 'fr', 'ru', 'it', 'pt']) {
        if (CoL10nClinic.clinicOf(code) != null ||
            CoL10nClinic.saasOf(code) != null) {
          continue;
        }
        CoFaker stub() => CoFaker.forLanguage(code, seed: 5, now: now);
        expect(stub().clinic.money(1234), r'$1,234', reason: code);
        expect(stub().clinic.label('nhis'), 'National insurance');
        expect(
          '${stub().clinic.counselSession()}',
          '${english().clinic.counselSession()}',
          reason: code,
        );
        expect(
          stub().clinic.payment(amount: 900, method: 'card').approvalNo,
          matches(RegExp(r'^\d{8}$')),
        );
        expect(
          '${stub().saas.invoice()}',
          '${english().saas.invoice()}',
          reason: code,
        );
        expect(
          '${stub().saas.prepaidLedger()}',
          '${english().saas.prepaidLedger()}',
          reason: code,
        );
        expect(stub().saas.label('pastDue'), 'Past due', reason: code);
      }
    });
  });
}
