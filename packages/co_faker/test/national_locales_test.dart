import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// Fictional phone rules, written from the sources independently of the
/// locale data so an edited format cannot silently become a real number.
///
/// - US, CA: NANP reserves 555-0100..555-0199 in every area code.
/// - GB: Ofcom "Telephone numbers for use in TV and radio drama".
/// - DE: Bundesnetzagentur Mitteilung 148/2021 ("Drama Numbers").
/// - FR: ARCEP décision 2018-0881, blocks for audiovisual productions.
/// - JP, CN, IN, IT, RU, BR: no reserved range; prefixes that no number
///   type uses (checked with Google libphonenumber, see docs/countries.md).
final Map<String, List<RegExp>> _fictionalPhones = <String, List<RegExp>>{
  'US': [RegExp(r'^\(\d{3}\) 555-01\d{2}$')],
  'CA': [RegExp(r'^\(\d{3}\) 555-01\d{2}$')],
  'GB': [
    RegExp(r'^07700 900\d{3}$'),
    RegExp(r'^020 7946 0\d{3}$'),
    RegExp(r'^01(13|14|15|16|17|18|21|31|41|51|61) 496 0\d{3}$'),
    RegExp(r'^0191 498 0\d{3}$'),
    RegExp(r'^029 2018 0\d{3}$'),
  ],
  'DE': [
    RegExp(r'^030 23125\d{3}$'),
    RegExp(r'^069 90009\d{3}$'),
    RegExp(r'^040 66969\d{3}$'),
    RegExp(r'^0221 4710\d{3}$'),
    RegExp(r'^089 99998\d{3}$'),
    RegExp(r'^0171 39200\d{2}$'),
    RegExp(r'^0176 040690\d{2}$'),
  ],
  'FR': [
    RegExp(r'^0(1 99 00|2 61 91|3 53 01|4 65 71|5 36 49|6 39 98) \d\d \d\d$'),
  ],
  'JP': [
    RegExp(r'^0[79]0-0\d{3}-\d{4}$'),
    RegExp(r'^03-0\d{3}-\d{4}$'),
    RegExp(r'^011-0\d{2}-\d{4}$'),
  ],
  'CN': [RegExp(r'^1[569]4 \d{4} \d{4}$'), RegExp(r'^021-0\d{3}-\d{4}$')],
  'IN': [RegExp(r'^0(11|22|44|33|40|20) 0\d{3} \d{4}$')],
  'IT': [RegExp(r'^30\d \d{3} \d{4}$')],
  'RU': [RegExp(r'^8 \(5\d{2}\) \d{3}-\d{2}-\d{2}$')],
  'BR': [RegExp(r'^\((20|30|40|50|60|70|80)\) 9\d{4}-\d{4}$')],
};

/// National trunk prefix dropped in international notation.
const Map<String, String> _trunk = <String, String>{
  'GB': '0',
  'DE': '0',
  'FR': '0',
  'JP': '0',
  'CN': '0',
  'IN': '0',
  'RU': '8',
};

final Map<String, RegExp> _postalCodes = <String, RegExp>{
  'US': RegExp(r'^\d{5}$'),
  'CA': RegExp(
    r'^[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z] \d[ABCEGHJ-NPRSTV-Z]\d$',
  ),
  'GB': RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? \d[ABD-HJLNP-UW-Z]{2}$'),
  'DE': RegExp(r'^\d{5}$'),
  'FR': RegExp(r'^\d{5}$'),
  'IT': RegExp(r'^\d{5}$'),
  'BR': RegExp(r'^\d{5}-\d{3}$'),
  'IN': RegExp(r'^[1-9]\d{5}$'),
  'JP': RegExp(r'^\d{3}-\d{4}$'),
  'CN': RegExp(r'^\d{6}$'),
  'RU': RegExp(r'^\d{6}$'),
};

final RegExp _latinName = RegExp(r"^[\p{Script=Latin} .'-]+$", unicode: true);
final Map<String, RegExp> _nameScripts = <String, RegExp>{
  'CN': RegExp(r'^\p{Script=Han}+$', unicode: true),
  'JP': RegExp(
    r'^[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}々]+'
    r' [\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}々]+$',
    unicode: true,
  ),
  'RU': RegExp(r'^\p{Script=Cyrillic}+ \p{Script=Cyrillic}+$', unicode: true),
};

/// Well-known brands of the eleven economies and global ones. A bounded
/// regression for authored company names, not a trademark search.
final RegExp _brands = RegExp(
  r'apple|google|amazon|microsoft|walmart|tesla|coca|starbucks|toyota|sony|'
  r'honda|nintendo|panasonic|uniqlo|rakuten|softbank|hitachi|mitsubishi|'
  r'任天堂|丰田|alibaba|阿里|tencent|腾讯|huawei|华为|小米|xiaomi|百度|baidu|'
  r'siemens|volkswagen|bmw|mercedes|bosch|adidas|\bsap\b|aldi|lidl|tata|'
  r'reliance|infosys|wipro|mahindra|airtel|lvmh|oréal|carrefour|renault|'
  r'peugeot|michelin|danone|gazprom|yandex|сбер|sber|лукойл|lukoil|ferrari|'
  r'fiat|gucci|prada|\beni\b|barilla|petrobras|itaú|bradesco|natura|embraer|'
  r'shopify|bombardier|hortons|barclays|hsbc|tesco|vodafone|unilever|'
  r'rolls|northwind|contoso',
  caseSensitive: false,
);

bool _reservedDomain(String host) =>
    host == 'example.com' ||
    host == 'example.net' ||
    host == 'example.org' ||
    host.endsWith('.example.com') ||
    host.endsWith('.example') ||
    host.endsWith('.test');

RegExp _templatePattern(String template, String letters) {
  final buffer = StringBuffer('^');
  for (final rune in template.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(switch (character) {
      '#' => r'\d',
      '@' => '[1-9]',
      '?' => '[$letters]',
      _ => RegExp.escape(character),
    });
  }
  return RegExp('$buffer\$');
}

CoFaker _faker(CoFakerCountry country, [int seed = 20261005]) =>
    CoFaker.forCountry(
      country.code,
      seed: seed,
      now: DateTime.utc(2026, 10, 5),
    );

void main() {
  for (final country in CoFakerCountries.all) {
    final locale = CoFakerNationalLocales.byCountry[country.code]!;
    final national = locale.national!;

    group('${country.code} ${country.locale}', () {
      test('locale data is complete and consistent', () {
        expect(national.country, country);
        expect(locale.code, country.locale);
        expect(locale.firstNames, [
          ...locale.femaleFirstNames,
          ...locale.maleFirstNames,
        ]);
        expect(locale.femaleFirstNames.length, greaterThanOrEqualTo(20));
        expect(locale.maleFirstNames.length, greaterThanOrEqualTo(20));
        expect(locale.lastNames.length, greaterThanOrEqualTo(20));
        expect(national.localities.length, greaterThanOrEqualTo(10));
        expect(locale.streetNames.length, greaterThanOrEqualTo(12));
        expect(locale.companyNames.length, greaterThanOrEqualTo(12));
        expect(locale.jobTitles.length, greaterThanOrEqualTo(15));
        expect(locale.words.length, greaterThanOrEqualTo(40));
        expect(locale.productAdjectives.length, greaterThanOrEqualTo(12));
        expect(locale.productNouns.length, greaterThanOrEqualTo(12));
        expect(locale.categories.length, greaterThanOrEqualTo(10));
        expect(locale.places.length, greaterThanOrEqualTo(10));
        expect(locale.genders, hasLength(3));
        // Legacy fields mirror the national data for direct readers.
        expect(locale.cities, national.localities.map((l) => l.city));
        expect(
          locale.phoneFormats,
          national.phoneFormats.map((f) => f.national),
        );
        expect(locale.countries, [country.nativeName]);
        expect(locale.countryCodes, [country.code]);
        expect(locale.currencyCode, country.currencyCode);
        expect(locale.currencySymbol, country.currencySymbol);
        for (final domain in [...locale.domains, ...locale.emailDomains]) {
          expect(_reservedDomain(domain), isTrue, reason: domain);
        }
        for (final format in national.phoneFormats) {
          expect(format.digitCount, greaterThan(0));
          expect(
            '#'.allMatches(format.international).length,
            format.digitCount,
            reason: format.national,
          );
          expect(format.international, startsWith('${country.callingCode} '));
        }
        for (final company in locale.companyNames) {
          expect(_brands.hasMatch(company), isFalse, reason: company);
        }
      });

      test('names use the national script and romanize for usernames', () {
        final f = _faker(country);
        final script = _nameScripts[country.code];
        for (var i = 0; i < 200; i++) {
          final name = f.person.fullName();
          expect(name, matches(script ?? _latinName), reason: name);
          final username = f.person.username();
          expect(username, matches(RegExp(r'^[a-z0-9]+\.[a-z0-9]+$')));
        }
        for (final name in [...locale.firstNames, ...locale.lastNames]) {
          expect(
            national.romanize(name).toLowerCase(),
            matches(RegExp(r'^[a-z .-]+$')),
            reason: '$name needs a romanization',
          );
        }
      });

      test('phone numbers are fictional in both notations', () {
        final rules = _fictionalPhones[country.code]!;
        final digitsOnly = RegExp(r'\D');
        for (var i = 0; i < 300; i++) {
          final seed = _faker(country, i);
          final national = seed.internet.phoneNumber();
          final again = _faker(country, i);
          final international = again.internet.phoneNumber(international: true);
          expect(
            rules.any((rule) => rule.hasMatch(national)),
            isTrue,
            reason: national,
          );
          // Chinese mobiles have no trunk prefix; landlines start with 0.
          final trunk = _trunk[country.code] ?? '';
          final nationalDigits = national.replaceAll(digitsOnly, '');
          final significant =
              trunk.isNotEmpty && nationalDigits.startsWith(trunk)
              ? nationalDigits.substring(trunk.length)
              : nationalDigits;
          expect(
            international.replaceAll(digitsOnly, ''),
            '${country.callingCode.substring(1)}$significant',
            reason: '$national / $international',
          );
        }
      });

      test('addresses agree on city, region and postal code', () {
        final f = _faker(country);
        final postal = _postalCodes[country.code]!;
        for (var i = 0; i < 200; i++) {
          final address = f.address.postalAddress();
          final locality = national.localities.firstWhere(
            (l) => l.city == address.city,
          );
          expect(address.region, locality.region);
          expect(address.regionCode, locality.regionCode);
          expect(address.postalCode, matches(postal));
          expect(
            locality.postalCodes.any(
              (t) => _templatePattern(
                t,
                national.postalLetters,
              ).hasMatch(address.postalCode),
            ),
            isTrue,
            reason: '${address.city} ${address.postalCode}',
          );
          expect(address.formatted, contains(address.city));
          expect(address.formatted, contains(address.line1));
          if (country.code != 'CN') {
            expect(address.formatted, contains(address.postalCode));
          }
          expect(address.countryCode, country.code);
          expect(address.country, country.nativeName);
          expect(f.address.postalCode(), matches(postal));
          expect(f.address.fullAddress(), isNotEmpty);
          expect(f.address.country(), country.nativeName);
        }
      });

      test('schema records keep one place per record', () {
        final f = _faker(country);
        final records = f.schema.records(
          40,
          const {
            'name': 'String',
            'email': 'String',
            'phone': 'String',
            'city': 'String',
            'state': 'String',
            'postalCode': 'String',
            'address': 'String',
            'country': 'String',
          },
          roles: const {'state': 'province'},
          entity: 'customer',
        );
        for (final record in records) {
          final locality = national.localities.firstWhere(
            (l) => l.city == record['city'],
          );
          expect(record['state'], locality.region);
          expect(record['address'], contains(record['city']! as String));
          if (country.code != 'CN') {
            expect(
              record['address'],
              contains(record['postalCode']! as String),
            );
          }
          expect(record['country'], country.nativeName);
          final host = (record['email']! as String).split('@').last;
          expect(_reservedDomain(host), isTrue, reason: host);
        }
        expect(
          records.map((r) => r['city']).toSet().length,
          greaterThan(3),
          reason: 'records should spread over several cities',
        );
      });

      test('prices, products, text and URLs follow the locale', () {
        final f = _faker(country);
        for (var i = 0; i < 100; i++) {
          final price = f.commerce.price(min: 1, max: 9999);
          final decimals = country.currencyMinorUnits;
          expect(
            (price * 100).round() % (decimals == 0 ? 100 : 1),
            0,
            reason: '$price',
          );
          final product = f.commerce.productName();
          expect(locale.productNouns.any(product.contains), isTrue);
          expect(locale.productAdjectives.any(product.contains), isTrue);
          expect(f.text.sentence(), endsWith(national.sentenceTerminator));
          expect(f.text.slug(), matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')));
          final host = Uri.parse(f.internet.url()).host;
          expect(_reservedDomain(host), isTrue, reason: host);
        }
        expect(f.commerce.currency().code, country.currencyCode);
      });

      test('the same seed and clock give the same values', () {
        Map<String, Object?> sample(CoFaker f) => {
          'name': f.person.fullName(),
          'email': f.internet.email(),
          'phone': f.internet.phoneNumber(international: true),
          'address': f.address.fullAddress(),
          'company': f.commerce.companyName(),
          'record': f.schema.record(const {'city': 'String', 'zip': 'String'}),
        };
        expect(sample(_faker(country, 7)), sample(_faker(country, 7)));
        expect(sample(_faker(country, 7)), isNot(sample(_faker(country, 8))));
      });
    });
  }

  test('Russian given and family names agree with the sex', () {
    final f = CoFaker.forCountry('RU', seed: 11);
    final national = f.localeData.national!;
    expect(national.femaleLastNames, hasLength(national.maleLastNames.length));
    for (final name in national.femaleLastNames) {
      expect(name, endsWith('а'));
    }
    for (var i = 0; i < 200; i++) {
      final female = f.person.fullName(sex: CoSex.female).split(' ');
      expect(f.localeData.femaleFirstNames, contains(female.first));
      expect(national.femaleLastNames, contains(female.last));
      final male = f.person.fullName(sex: CoSex.male).split(' ');
      expect(national.maleLastNames, contains(male.last));
      final any = f.person.fullName().split(' ');
      final isFemale = f.localeData.femaleFirstNames.contains(any.first);
      expect(
        (isFemale ? national.femaleLastNames : national.maleLastNames),
        contains(any.last),
        reason: any.join(' '),
      );
      expect(
        f.person.fullName(firstName: 'Анна'),
        matches(RegExp(r'^Анна \p{Script=Cyrillic}+а$', unicode: true)),
      );
    }
    expect(f.person.lastName(sex: CoSex.female), endsWith('а'));
  });

  test('romanization handles diacritics, umlauts and Cyrillic', () {
    final german = CoFakerNationalLocales.germany.national!;
    expect(german.romanize('Müller'), 'Mueller');
    expect(german.romanize('Schäfer'), 'Schaefer');
    expect(german.romanize('Groß'), 'Gross');
    expect(german.romanize('Léa Côté'), 'Lea Cote');
    expect(german.romanize('João'), 'Joao');
    expect(german.romanize('Артём Фёдоров'), 'Artyom Fyodorov');
    expect(german.romanize('Наталья'), 'Natalya');
    expect(CoFakerNationalLocales.japan.national!.romanize('佐藤'), 'sato');
    expect(CoFakerNationalLocales.china.national!.romanize('王'), 'wang');
    expect(german.romanize('東京'), '東京');
  });

  test('phone formats render digits in order', () {
    const format = CoFakerPhoneFormat(
      national: '090-0###-####',
      international: '+81 90-0###-####',
    );
    expect(format.digitCount, 7);
    final digits = [1, 2, 3, 4, 5, 6, 7];
    expect(format.render(digits), '090-0123-4567');
    expect(format.render(digits, international: true), '+81 90-0123-4567');
    expect(() => format.render([1]), throwsArgumentError);
  });

  test('national-only APIs explain themselves on language-only locales', () {
    final faker = CoFaker(locale: 'ko', seed: 1);
    expect(faker.address.region, throwsStateError);
    expect(faker.address.postalAddress, throwsStateError);
    expect(
      () => faker.schema.record(
        const {'state': 'String'},
        roles: const {'state': 'region'},
      ),
      throwsStateError,
    );
    expect(
      CoFaker(locale: 'ko', seed: 1).internet.phoneNumber(international: true),
      CoFaker(locale: 'ko', seed: 1).internet.phoneNumber(),
    );
    expect(CoFieldRole.parse('prefecture'), CoFieldRole.region);
    expect(CoFieldRole.parse('region'), CoFieldRole.region);
  });
}
