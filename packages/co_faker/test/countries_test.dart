import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  group('CoFakerCountries', () {
    test('ranks every supported country by GDP, Brazil last', () {
      expect(CoFakerCountries.all.map((c) => c.code), [
        'US',
        'CN',
        'DE',
        'JP',
        'GB',
        'IN',
        'FR',
        'RU',
        'IT',
        'CA',
        'BR',
      ]);
      expect(
        CoFakerCountries.all.map((c) => c.gdpRank),
        List<int>.generate(11, (i) => i + 1),
      );
      expect(CoFakerCountries.gdpTop10, hasLength(10));
      expect(CoFakerCountries.gdpTop10, CoFakerCountries.all.take(10));
      expect(
        CoFakerCountries.gdpTop10,
        isNot(contains(CoFakerCountries.brazil)),
      );
      expect(CoFakerCountries.gdpSource, contains('2025'));
    });

    test('carries consistent ISO, locale, calling and currency codes', () {
      final codes = <String>{};
      final alpha3 = <String>{};
      for (final country in CoFakerCountries.all) {
        expect(codes.add(country.code), isTrue, reason: country.code);
        expect(alpha3.add(country.alpha3), isTrue, reason: country.alpha3);
        expect(country.code, matches(RegExp(r'^[A-Z]{2}$')));
        expect(country.alpha3, matches(RegExp(r'^[A-Z]{3}$')));
        expect(country.locale, endsWith('_${country.code}'));
        expect(country.callingCode, matches(RegExp(r'^\+\d{1,3}$')));
        expect(country.currencyCode, matches(RegExp(r'^[A-Z]{3}$')));
        expect(
          country.currencyMinorUnits,
          country.currencyCode == 'JPY' ? 0 : 2,
        );
        expect(country.nativeName, isNotEmpty);
        expect(country.toString(), 'CoFakerCountry(${country.code})');
      }
    });

    test('finds countries by alpha-2 or alpha-3 code, ignoring case', () {
      expect(CoFakerCountries.byCode('JP'), CoFakerCountries.japan);
      expect(CoFakerCountries.byCode(' jpn '), CoFakerCountries.japan);
      expect(CoFakerCountries.byCode('bra'), CoFakerCountries.brazil);
      expect(CoFakerCountries.byCode('KR'), isNull);
      expect(CoFakerCountries.byCode(''), isNull);
    });
  });

  group('national locale resolution', () {
    test('every country locale resolves to its national locale', () {
      for (final country in CoFakerCountries.all) {
        final regional = CoFaker(locale: country.locale, seed: 1);
        final dashed = CoFaker(
          locale: country.locale.replaceAll('_', '-').toLowerCase(),
          seed: 1,
        );
        expect(regional.country, country, reason: country.locale);
        expect(dashed.country, country, reason: country.locale);
        expect(
          CoFakerNationalLocales.byCountry[country.code]!.national!.country,
          country,
        );
        expect(regional.localeData.code, country.locale);
      }
    });

    test('forCountry accepts alpha-2 and alpha-3 codes', () {
      final japan = CoFaker.forCountry('jpn', seed: 3, now: DateTime.utc(2026));
      expect(japan.country, CoFakerCountries.japan);
      expect(japan.locale, 'ja_jp');
      expect(
        japan.person.fullName(),
        CoFaker(locale: 'ja_JP', seed: 3).person.fullName(),
      );
      expect(
        () => CoFaker.forCountry('KR'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => '${error.message}',
            'message',
            contains('US, CN, DE, JP, GB, IN, FR, RU, IT, CA, BR'),
          ),
        ),
      );
    });

    test('languages without earlier data resolve to a national locale', () {
      expect(CoFaker(locale: 'it').country, CoFakerCountries.italy);
      expect(CoFaker(locale: 'pt').country, CoFakerCountries.brazil);
      expect(CoFaker(locale: 'pt_PT').country, CoFakerCountries.brazil);
      expect(CoFaker(locale: 'ru').country, CoFakerCountries.russia);
    });

    test('earlier language codes stay language-only', () {
      for (final code in [
        'en',
        'ko',
        'ja',
        'zh',
        'es',
        'fr',
        'de',
        'ko_KR',
        'fr_CA',
        'en_AU',
        'xx',
      ]) {
        expect(CoFaker(locale: code).country, isNull, reason: code);
      }
    });

    test('resolve mirrors the CoFaker fallback', () {
      expect(CoFakerLocales.resolve('ja-JP'), CoFakerNationalLocales.japan);
      expect(CoFakerLocales.resolve('es_MX'), CoFakerLocales.spanish);
      expect(CoFakerLocales.resolve('zz'), CoFakerLocales.english);
      expect(CoFakerLocales.normalize(' en-GB '), 'en_gb');
    });

    test('a custom locale merged over a national one keeps its country', () {
      final base = CoFakerLocales.resolve('de_DE');
      final custom = const CoFakerLocale(
        code: 'de_DE',
        words: ['Wort'],
      ).merge(base);
      final faker = CoFaker(locale: 'de_DE', locales: {'de_DE': custom});
      expect(faker.country, CoFakerCountries.germany);
      expect(faker.text.word(), 'Wort');
    });
  });
}
