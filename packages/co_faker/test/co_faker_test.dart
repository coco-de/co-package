import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  group('CoFaker', () {
    test('is deterministic when the seed and clock match', () {
      final first = CoFaker(seed: 42, now: DateTime(2026, 1, 1));
      final second = CoFaker(seed: 42, now: DateTime(2026, 1, 1));

      expect(first.person.fullName(), second.person.fullName());
      expect(first.internet.email(), second.internet.email());
      expect(first.id.uuid(), second.id.uuid());
      expect(first.date.past(), second.date.past());
    });

    test('supports localized module data', () {
      final faker = CoFaker(locale: 'ko', seed: 1);

      expect(faker.locale, 'ko');
      expect(CoFakerLocales.all, contains('ko'));
      expect(faker.localeData.currencyCode, 'KRW');
      expect(faker.localeData.nameFormat, '{last}{first}');
      expect(faker.person.fullName(), isNotEmpty);
      expect(faker.address.city(), isNotEmpty);
    });

    test('falls back from regional and unknown locales', () {
      final regional = CoFaker(locale: 'ja-JP', seed: 1);
      final unknown = CoFaker(locale: 'xx-YY', seed: 1);

      expect(regional.locale, 'ja_jp');
      expect(regional.localeData.currencyCode, 'JPY');
      expect(unknown.localeData.currencyCode, 'USD');
      expect(unknown.person.fullName(), isNotEmpty);
    });

    test('merges partial custom locale data over English', () {
      final faker = CoFaker(
        locale: 'acme',
        locales: {
          'acme': const CoFakerLocale(
            code: 'acme',
            firstNames: ['Ada'],
            lastNames: ['Example'],
            currencyCode: 'ACM',
          ),
        },
        seed: 1,
      );

      expect(faker.person.fullName(), 'Ada Example');
      expect(faker.localeData.cities, isNotEmpty);
      expect(faker.localeData.currencyCode, 'ACM');
    });

    test('generates batches and schema objects', () {
      final faker = CoFaker(seed: 1);

      final values = faker.generate(3, (faker, index) {
        return faker.object({
          'index': (_) => index,
          'id': (_) => faker.id.uuid(),
        });
      });

      expect(values, hasLength(3));
      expect(values.first['index'], 0);
      expect(values.map((value) => value['id']).toSet(), hasLength(3));
    });

    test('interpolates known and custom placeholders', () {
      final faker = CoFaker(seed: 1);

      final value = faker.fake(
        '{{person.fullName}} {{internet.email}} {{unknown}} {{code}}',
        custom: {'code': (faker) => 'C-${faker.number.int(min: 10, max: 10)}'},
      );

      expect(value, contains('@'));
      expect(value, contains('{{unknown}}'));
      expect(value, contains('C-10'));
    });

    test('supports the lorem alias and validation', () {
      final faker = CoFaker(seed: 1);

      expect(faker.lorem.word(), isNotEmpty);
      expect(faker.text.sentence(wordCount: 0), isEmpty);
      expect(() => faker.generate(-1, (_, _) => 1), throwsArgumentError);
      expect(() => faker.number.int(min: 2, max: 1), throwsArgumentError);
    });

    test('creates UUIDs with v4 and variant bits', () {
      final uuid = CoFaker(seed: 1).id.uuid();

      expect(
        uuid,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });
}
