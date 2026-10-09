import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// One language setting as an app hands it out, and what
/// [CoFakerLanguages.resolve] must read from it.
typedef _Setting = ({String tag, String language, String? region});

/// Settings of supported languages: BCP-47 tags, POSIX locale names, Flutter
/// `Locale.toLanguageTag()` output, and the tags of co_demo_prefs'
/// `DemoLocale`. Case, `-` versus `_`, the script, the encoding, and the
/// modifier must not matter.
const List<_Setting> _supported = <_Setting>[
  (tag: 'ko', language: 'ko', region: null),
  (tag: 'ko_KR', language: 'ko', region: 'KR'),
  (tag: 'ko-KR', language: 'ko', region: 'KR'),
  (tag: 'KO-kr', language: 'ko', region: 'KR'),
  (tag: ' ko ', language: 'ko', region: null),
  (tag: 'zh-Hans', language: 'zh', region: null),
  (tag: 'zh-Hans-CN', language: 'zh', region: 'CN'),
  (tag: 'zh_Hans_CN.UTF-8', language: 'zh', region: 'CN'),
  (tag: 'zh_Hans-CN', language: 'zh', region: 'CN'),
  (tag: 'ZH_cn', language: 'zh', region: 'CN'),
  (tag: 'zh', language: 'zh', region: null),
  (tag: 'zh-CN', language: 'zh', region: 'CN'),
  (tag: 'zh-SG', language: 'zh', region: 'SG'),
  (tag: 'pt-BR', language: 'pt', region: 'BR'),
  (tag: 'pt-PT', language: 'pt', region: 'PT'),
  (tag: 'ja_JP.UTF-8', language: 'ja', region: 'JP'),
  (tag: 'ja-JP-u-ca-japanese', language: 'ja', region: 'JP'),
  (tag: 'en_US@posix', language: 'en', region: 'US'),
  (tag: 'en-US-POSIX', language: 'en', region: 'US'),
  (tag: 'en-GB', language: 'en', region: 'GB'),
  (tag: 'en-u-ca-gregory', language: 'en', region: null),
  (tag: 'de_DE.ISO-8859-1@euro', language: 'de', region: 'DE'),
  (tag: 'de_DE@euro.UTF-8', language: 'de', region: 'DE'),
  (tag: 'fr-CA', language: 'fr', region: 'CA'),
  (tag: 'ru_RU.KOI8-R', language: 'ru', region: 'RU'),
  (tag: 'it-IT', language: 'it', region: 'IT'),
  (tag: 'es', language: 'es', region: null),
  (tag: 'es-419', language: 'es', region: '419'),
  (tag: 'es_ES.UTF-8', language: 'es', region: 'ES'),
  (tag: 'ar', language: 'ar', region: null),
  (tag: 'ar-SA', language: 'ar', region: 'SA'),
  (tag: 'ar-EG', language: 'ar', region: 'EG'),
  (tag: 'ar_SA.UTF-8', language: 'ar', region: 'SA'),
  // The subtags of an extension or private use name no script or region.
  (tag: 'zh-CN-x-hk', language: 'zh', region: 'CN'),
  (tag: 'zh-x-tw', language: 'zh', region: null),
  (tag: 'zh-CN-u-rg-hkzzzz', language: 'zh', region: 'CN'),
  (tag: 'ja-u-ca-japanese-x-us', language: 'ja', region: null),
];

/// Settings that must resolve to English with `supported == false`.
const List<String> _unsupported = <String>[
  'hi',
  'hi_IN',
  'vi',
  'nl_NL',
  'sr-Latn-RS',
  'xx',
  'english',
  'und',
  'C',
  'POSIX',
  '',
  '   ',
  '-',
  '_',
  '.UTF-8',
  '@posix',
];

/// Traditional Chinese in every spelling an app may hand out.
const List<String> _traditional = <String>[
  'zh-Hant',
  'zh_TW',
  'zh_HK',
  'zh_MO',
  'zh-Hant-TW',
  'zh-Hant-HK',
  'zh-Hant-CN',
  'zh-tw',
  'ZH_hk',
  'zh_TW.UTF-8',
  'zh_MO@modifier',
  'zh-Hant-x-private',
  'zh-TW-u-ca-roc',
];

/// The supported language codes and the locale `forLanguage` builds each with.
const Map<String, String> _locales = <String, String>{
  'ko': 'ko',
  'en': 'en_us',
  'zh': 'zh_cn',
  'ja': 'ja_jp',
  'de': 'de_de',
  'fr': 'fr_fr',
  'ru': 'ru_ru',
  'it': 'it_it',
  'pt': 'pt_br',
  'es': 'es_es',
  'ar': 'ar_sa',
};

/// The country whose generator `forLanguage` must reproduce, per language.
const Map<String, String> _countries = <String, String>{
  'en': 'US',
  'zh': 'CN',
  'ja': 'JP',
  'de': 'DE',
  'fr': 'FR',
  'ru': 'RU',
  'it': 'IT',
  'pt': 'BR',
  'es': 'ES',
  'ar': 'SA',
};

final DateTime _now = DateTime.utc(2026, 1, 15);

/// Values of the basic modules, as strings, for comparing two generators.
List<String> _sample(CoFaker faker) => <String>[
  faker.person.fullName(),
  faker.person.firstName(),
  faker.address.city(),
  faker.address.fullAddress(),
  faker.internet.email(),
  faker.internet.phoneNumber(),
  '${faker.commerce.price()}',
  faker.text.sentence(),
  faker.date.past(utc: true).toIso8601String(),
];

void main() {
  group('CoFakerLanguages', () {
    test('lists the supported languages with locale and script', () {
      expect(CoFakerLanguages.all.map((language) => language.code), [
        'ko',
        'en',
        'zh',
        'ja',
        'de',
        'fr',
        'ru',
        'it',
        'pt',
        'es',
        'ar',
      ]);
      expect({
        for (final language in CoFakerLanguages.all)
          language.code: language.locale,
      }, _locales);
      expect(
        {
          for (final language in CoFakerLanguages.all)
            language.code: language.script,
        },
        {
          'ko': CoFakerScript.hangul,
          'en': CoFakerScript.latin,
          'zh': CoFakerScript.han,
          'ja': CoFakerScript.kana,
          'de': CoFakerScript.latin,
          'fr': CoFakerScript.latin,
          'ru': CoFakerScript.cyrillic,
          'it': CoFakerScript.latin,
          'pt': CoFakerScript.latin,
          'es': CoFakerScript.latin,
          'ar': CoFakerScript.arabic,
        },
      );
      expect(CoFakerScript.values, hasLength(6));
    });

    test('names a built-in locale of its own language for every entry', () {
      for (final language in CoFakerLanguages.all) {
        final code = language.code;
        expect(CoFakerLocales.all, contains(language.locale), reason: code);
        expect(
          language.locale,
          CoFakerLocales.normalize(language.locale),
          reason: '$code is stored normalized',
        );
        expect(CoFaker(locale: language.locale).language, code, reason: code);
      }
    });

    test('maps a language to the national locale of its country', () {
      for (final language in CoFakerLanguages.all) {
        final country = CoFakerLocales.all[language.locale]!.national?.country;
        expect(country?.code, _countries[language.code], reason: language.code);
      }
    });

    test('computes domain support instead of flagging each language', () {
      // Korean and English carry the authored domain data. The other
      // languages are not asserted: their domain data arrives language by
      // language.
      expect(CoFakerLanguages.korean.domain, isTrue);
      expect(CoFakerLanguages.english.domain, isTrue);
      expect(
        CoFakerLanguages.all.where((language) => language.domain),
        containsAll(<CoFakerLanguage>[
          CoFakerLanguages.korean,
          CoFakerLanguages.english,
        ]),
      );
    });

    test('describes itself', () {
      expect(CoFakerLanguages.japanese.toString(), 'CoFakerLanguage(ja)');
      expect(
        CoFakerLanguages.resolve('ja').toString(),
        'CoFakerLanguageResolution(ja, supported)',
      );
      expect(
        CoFakerLanguages.resolve('hi').toString(),
        'CoFakerLanguageResolution(en, unsupported)',
      );
    });
  });

  group('CoFakerLanguages.resolve', () {
    test('reads the language and region of every spelling', () {
      for (final setting in _supported) {
        final resolved = CoFakerLanguages.resolve(setting.tag);
        final language = CoFakerLanguages.all.singleWhere(
          (language) => language.code == setting.language,
        );
        expect(resolved.supported, isTrue, reason: setting.tag);
        expect(resolved.language, language, reason: setting.tag);
        expect(resolved.locale, language.locale, reason: setting.tag);
        expect(resolved.region, setting.region, reason: setting.tag);
      }
    });

    test('reads the same language from every Korean spelling', () {
      final readings = <String>{
        for (final tag in const ['ko_KR', 'ko-KR', 'KO-kr', 'ko_KR.UTF-8'])
          '${CoFakerLanguages.resolve(tag).language.code}/'
              '${CoFakerLanguages.resolve(tag).region}',
      };
      expect(readings, {'ko/KR'});
    });

    test('accepts the tag of every demo locale', () {
      // The tags of co_demo_prefs' DemoLocale.
      for (final tag in const [
        'ko',
        'en',
        'zh-Hans',
        'ja',
        'de',
        'fr',
        'es',
        'pt',
        'it',
        'ru',
        'ar',
      ]) {
        expect(CoFakerLanguages.resolve(tag).supported, isTrue, reason: tag);
      }
    });

    test('does not mistake a script or an extension for a region', () {
      expect(CoFakerLanguages.resolve('zh-Hans').region, isNull);
      expect(CoFakerLanguages.resolve('en-u-ca-gregory').region, isNull);
      expect(CoFakerLanguages.resolve('sr-Latn-RS').region, 'RS');
    });

    test('refuses Traditional Chinese rather than serve Simplified', () {
      for (final tag in _traditional) {
        final resolved = CoFakerLanguages.resolve(tag);
        expect(resolved.supported, isFalse, reason: tag);
        expect(resolved.language, CoFakerLanguages.english, reason: tag);
        expect(resolved.locale, 'en_us', reason: tag);
      }
      expect(CoFakerLanguages.resolve('zh_TW').region, 'TW');
    });

    test('keeps Simplified Chinese, whatever the region of its script', () {
      for (final tag in const [
        'zh',
        'zh-CN',
        'zh_CN',
        'zh-SG',
        'zh-Hans',
        'zh-Hans-CN',
        'zh-Hans-TW',
        'zh-Hans-HK',
        'zh_Hans_MO',
      ]) {
        final resolved = CoFakerLanguages.resolve(tag);
        expect(resolved.supported, isTrue, reason: tag);
        expect(resolved.locale, 'zh_cn', reason: tag);
      }
    });

    test('falls back to English for an unsupported language', () {
      for (final tag in _unsupported) {
        final resolved = CoFakerLanguages.resolve(tag);
        expect(resolved.supported, isFalse, reason: '"$tag"');
        expect(resolved.language, CoFakerLanguages.english, reason: '"$tag"');
        expect(resolved.locale, 'en_us', reason: '"$tag"');
      }
    });

    test('still reports the region of an unsupported setting', () {
      expect(CoFakerLanguages.resolve('nl-BE').region, 'BE');
      expect(CoFakerLanguages.resolve('hi_IN').region, 'IN');
    });

    test('does not choose the locale by region', () {
      expect(CoFakerLanguages.resolve('en-GB').locale, 'en_us');
      expect(CoFakerLanguages.resolve('en-CA').locale, 'en_us');
      expect(CoFakerLanguages.resolve('pt-PT').locale, 'pt_br');
      expect(CoFakerLanguages.resolve('fr-CA').locale, 'fr_fr');
      expect(CoFakerLanguages.resolve('es-MX').locale, 'es_es');
      expect(CoFakerLanguages.resolve('ar-EG').locale, 'ar_sa');
    });
  });

  group('CoFaker.language', () {
    test('is derived from the normalized locale', () {
      const expected = <String, String>{
        'en': 'en',
        'ko': 'ko',
        'ko-KR': 'ko',
        'ja_jp': 'ja',
        'ja_JP': 'ja',
        'zh_hans': 'zh',
        'zh-Hans': 'zh',
        'pt_BR': 'pt',
        'es_MX': 'es',
        'xx_YY': 'xx',
        'acme': 'acme',
      };
      for (final entry in expected.entries) {
        expect(
          CoFaker(locale: entry.key).language,
          entry.value,
          reason: entry.key,
        );
      }
      expect(CoFaker().language, 'en');
    });

    test('leaves locale as it was', () {
      expect(CoFaker(locale: 'ja-JP').locale, 'ja_jp');
      expect(CoFaker(locale: 'zh_Hans').locale, 'zh_hans');
      expect(CoFaker(locale: ' KO ').locale, 'ko');
    });

    test('follows the language through derived and localized views', () {
      final faker = CoFaker.forLanguage('ja', seed: 1);
      expect(faker.derive('customer/1').language, 'ja');
      expect(faker.localized('de-DE').language, 'de');
    });

    test('names a custom locale by its own code', () {
      final faker = CoFaker(
        locale: 'ko-KR',
        locales: {
          'ko-KR': const CoFakerLocale(code: 'ko_KR', firstNames: ['테스트']),
        },
      );
      expect(faker.language, 'ko');
      expect(faker.person.firstName(), '테스트');
    });
  });

  group('the CoFaker constructor', () {
    test('keeps reading locale codes literally', () {
      // Only forLanguage reads POSIX names and script subtags: the
      // constructor lower-cases, turns `-` into `_`, and falls back from the
      // exact code to the part before the first `_`.
      final posix = CoFaker(locale: 'ja_JP.UTF-8');
      expect(posix.locale, 'ja_jp.utf_8');
      expect(posix.language, 'ja');
      expect(posix.country, isNull);
      expect(posix.localeData.code, 'ja');
      expect(CoFaker.forLanguage('ja_JP.UTF-8').locale, 'ja_jp');
    });

    test('keeps serving Chinese data for Traditional codes', () {
      for (final code in const ['zh_TW', 'zh_HK', 'zh_MO', 'zh-Hant']) {
        final legacy = CoFaker(locale: code, seed: 11, now: _now);
        final chinese = CoFaker(locale: 'zh', seed: 11, now: _now);
        expect(legacy.localeData.code, 'zh', reason: code);
        expect(legacy.language, 'zh', reason: code);
        expect(_sample(legacy), _sample(chinese), reason: code);
        expect(CoFakerLanguages.resolve(code).supported, isFalse, reason: code);
      }
    });

    test('keeps a bare language code on its language-only data', () {
      final bare = CoFaker(locale: 'ja', seed: 11, now: _now);
      final national = CoFaker.forLanguage('ja', seed: 11, now: _now);
      expect(bare.locale, 'ja');
      expect(bare.country, isNull);
      expect(national.locale, 'ja_jp');
      expect(national.country, CoFakerCountries.japan);
      expect(_sample(bare), isNot(_sample(national)));
    });
  });

  group('CoFaker.forLanguage', () {
    test('builds each language with its national locale', () {
      for (final entry in _locales.entries) {
        final faker = CoFaker.forLanguage(entry.key);
        expect(faker.locale, entry.value, reason: entry.key);
        expect(faker.language, entry.key, reason: entry.key);
      }
    });

    test('builds Spanish with Spain, while CoFaker keeps the bare es', () {
      final faker = CoFaker.forLanguage('es-MX', seed: 3, now: _now);
      expect(faker.locale, 'es_es');
      expect(faker.country, CoFakerCountries.spain);
      final bare = CoFaker(locale: 'es', seed: 3, now: _now);
      expect(bare.country, isNull);
      expect(bare.localeData.code, 'es');
    });

    test('builds Arabic with Saudi Arabia instead of English', () {
      final faker = CoFaker.forLanguage('ar', seed: 3, now: _now);
      expect(faker.locale, 'ar_sa');
      expect(faker.country, CoFakerCountries.saudiArabia);
      expect(CoFaker(locale: 'ar').country, CoFakerCountries.saudiArabia);
      expect(
        faker.person.fullName(),
        matches(
          RegExp(r'^\p{Script=Arabic}+ \p{Script=Arabic}+$', unicode: true),
        ),
      );
    });

    test('uses the data of CoFaker.forCountry', () {
      for (final entry in _countries.entries) {
        final byLanguage = CoFaker.forLanguage(entry.key, seed: 5, now: _now);
        final byCountry = CoFaker.forCountry(entry.value, seed: 5, now: _now);
        expect(byLanguage.locale, byCountry.locale, reason: entry.key);
        expect(byLanguage.country, byCountry.country, reason: entry.key);
        expect(
          byLanguage.localeData.code,
          byCountry.localeData.code,
          reason: entry.key,
        );
        expect(_sample(byLanguage), _sample(byCountry), reason: entry.key);
      }
    });

    test('keeps Korean on the Korean locale', () {
      expect(
        _sample(CoFaker.forLanguage('ko_KR', seed: 5, now: _now)),
        _sample(CoFaker(locale: 'ko', seed: 5, now: _now)),
      );
    });

    test('gives the languages with a national locale postal addresses', () {
      for (final code in _countries.keys) {
        final faker = CoFaker.forLanguage(code, seed: 5);
        final address = faker.address.postalAddress();
        expect(address.formatted, isNotEmpty, reason: code);
        expect(address.countryCode, _countries[code], reason: code);
      }
    });

    test('leaves Korean without national address data', () {
      for (final code in const ['ko']) {
        final faker = CoFaker.forLanguage(code);
        expect(faker.country, isNull, reason: code);
        expect(
          () => faker.address.postalAddress(),
          throwsStateError,
          reason: code,
        );
        expect(() => faker.address.region(), throwsStateError, reason: code);
      }
    });

    test('builds the same generator from every spelling', () {
      for (final spelling in const [
        'ja',
        'JA',
        'ja_JP',
        'ja-JP',
        'ja_JP.UTF-8',
        'ja-Jpan-JP',
        'ja_JP@modifier',
      ]) {
        final faker = CoFaker.forLanguage(spelling, seed: 8, now: _now);
        expect(faker.locale, 'ja_jp', reason: spelling);
        expect(
          _sample(faker),
          _sample(CoFaker.forLanguage('ja', seed: 8, now: _now)),
          reason: spelling,
        );
      }
    });

    test('falls back to English for an unsupported language', () {
      final english = _sample(CoFaker.forLanguage('en', seed: 5, now: _now));
      for (final tag in const ['nl', 'hi', 'xx', 'und', '']) {
        final faker = CoFaker.forLanguage(tag, seed: 5, now: _now);
        expect(faker.locale, 'en_us', reason: '"$tag"');
        expect(faker.language, 'en', reason: '"$tag"');
        expect(faker.country, CoFakerCountries.unitedStates, reason: '"$tag"');
        expect(_sample(faker), english, reason: '"$tag"');
      }
    });

    test('refuses Traditional Chinese: English, never Simplified', () {
      final english = _sample(CoFaker.forLanguage('en', seed: 5, now: _now));
      final simplified = _sample(CoFaker.forLanguage('zh', seed: 5, now: _now));
      for (final tag in _traditional) {
        final faker = CoFaker.forLanguage(tag, seed: 5, now: _now);
        expect(faker.locale, 'en_us', reason: tag);
        expect(faker.language, 'en', reason: tag);
        expect(_sample(faker), english, reason: tag);
        expect(_sample(faker), isNot(simplified), reason: tag);
      }
    });

    test('is deterministic for the same seed and clock', () {
      for (final language in CoFakerLanguages.all) {
        final first = CoFaker.forLanguage(language.code, seed: 42, now: _now);
        final second = CoFaker.forLanguage(language.code, seed: 42, now: _now);
        expect(_sample(first), _sample(second), reason: language.code);
        expect(first.now, _now);
        expect(first.seed, 42);
      }
    });

    test('draws different values from different seeds', () {
      for (final language in CoFakerLanguages.all) {
        final first = CoFaker.forLanguage(language.code, seed: 1, now: _now);
        final second = CoFaker.forLanguage(language.code, seed: 2, now: _now);
        expect(_sample(first), isNot(_sample(second)), reason: language.code);
      }
    });

    test('passes the clock, the stream, and the domains through', () {
      final stream = CoRandom(3);
      final shared = CoFaker.forLanguage(
        'fr',
        now: _now,
        random: stream,
        domains: CoFakerDomains.all,
      );
      expect(shared.random, same(stream));
      expect(shared.now, _now);
      expect(shared.domains, CoFakerDomains.all);
      expect(CoFaker.forLanguage('fr').domains, isEmpty);
    });

    test('looks custom locales up by the resolved locale code', () {
      final faker = CoFaker.forLanguage(
        'ja-JP',
        locales: {
          'ja_JP': const CoFakerLocale(code: 'ja_JP', words: ['語']),
        },
      );
      expect(faker.text.word(), '語');

      // A language code is not the resolved code: the national locale wins.
      final ignored = CoFaker.forLanguage(
        'ja',
        locales: {
          'ja': const CoFakerLocale(code: 'ja', words: ['語']),
        },
      );
      expect(ignored.text.word(), isNot('語'));
    });
  });
}
