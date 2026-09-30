import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  CoFaker ko([int seed = 1]) =>
      CoFaker(locale: 'ko', seed: seed, now: DateTime.utc(2026, 9, 30));

  group('CoFakerKorea', () {
    test('is deterministic for the same seed and clock', () {
      final a = ko(9);
      final b = ko(9);
      expect(a.korea.mobilePhone(), b.korea.mobilePhone());
      expect(a.korea.rrn(masked: false), b.korea.rrn(masked: false));
      expect(a.korea.businessNumber(), b.korea.businessNumber());
      expect(a.korea.roadAddress(), b.korea.roadAddress());
    });

    test('phone numbers use unassignable blocks', () {
      final faker = ko();
      for (var i = 0; i < 200; i++) {
        expect(faker.korea.mobilePhone(), matches(r'^010-0\d{3}-\d{4}$'));
        expect(
          faker.korea.landlinePhone(),
          matches(r'^0\d{1,2}-0\d{2}-\d{4}$'),
        );
      }
      expect(faker.korea.mobilePhone(dashed: false), matches(r'^0100\d{7}$'));
      expect(CoFakerKorea.maskPhone('010-0123-4567'), '010-****-4567');
    });

    test('resident numbers never pass the checksum', () {
      final faker = ko();
      for (var i = 0; i < 500; i++) {
        final value = faker.korea.rrn(masked: false);
        expect(value, matches(r'^\d{6}-[1-4]\d{6}$'));
        expect(CoFakerKorea.isRrnChecksumValid(value), isFalse);
      }
    });

    test('resident numbers are masked by default and match birth and sex', () {
      final faker = ko();
      expect(
        faker.korea.rrn(birthDate: DateTime(1990, 3, 7), sex: CoSex.female),
        '900307-2******',
      );
      expect(
        faker.korea.rrn(birthDate: DateTime(2001, 12, 1), sex: CoSex.male),
        '011201-3******',
      );
      expect(
        () => faker.korea.rrn(birthDate: DateTime(2021), masked: false),
        throwsArgumentError,
      );
    });

    test('the checksum helper accepts a known valid sample', () {
      // Synthetic samples that satisfy the checksums.
      expect(CoFakerKorea.isRrnChecksumValid('900101-1234568'), isTrue);
      expect(
        CoFakerKorea.isBusinessNumberChecksumValid('123-45-67891'),
        isTrue,
      );
    });

    test('business numbers never pass the checksum', () {
      final faker = ko();
      for (var i = 0; i < 500; i++) {
        final value = faker.korea.businessNumber();
        expect(value, matches(r'^\d{3}-\d{2}-\d{5}$'));
        expect(CoFakerKorea.isBusinessNumberChecksumValid(value), isFalse);
      }
    });

    test('road addresses are consistent', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        final a = faker.korea.roadAddress();
        expect(a.postalCode, matches(r'^\d{5}$'));
        expect(a.line1, '${a.sido} ${a.sigungu} ${a.road} ${a.buildingNumber}');
        expect(a.line2, a.detail);
        expect(CoFakerKorea.areaCodeOf(a.sido), startsWith('0'));
      }
    });

    test('birth dates respect the age range and clock', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        final birth = faker.korea.birthDate(minAge: 30, maxAge: 30);
        expect(birth.isUtc, isTrue);
        expect(birth.year, anyOf(1995, 1996));
      }
    });
  });

  group('Korean names', () {
    test('gendered first names come from the gendered lists', () {
      final faker = ko();
      final data = faker.localeData;
      for (var i = 0; i < 50; i++) {
        expect(
          data.femaleFirstNames,
          contains(faker.person.firstName(sex: CoSex.female)),
        );
        expect(
          data.maleFirstNames,
          contains(faker.person.firstName(sex: CoSex.male)),
        );
      }
    });

    test('locales without gendered names fall back to all first names', () {
      final faker = CoFaker(locale: 'ja', seed: 1);
      expect(faker.localeData.femaleFirstNames, isEmpty);
      expect(
        faker.localeData.firstNames,
        contains(faker.person.firstName(sex: CoSex.female)),
      );
    });

    test('romanizes Hangul for usernames and emails', () {
      expect(CoFakerPerson.romanize('서연'), 'seoyeon');
      expect(CoFakerPerson.romanize('민준'), 'minjun');
      expect(CoFakerPerson.romanize('Ada'), 'Ada');
      final faker = ko();
      expect(
        faker.person.username(firstName: '하은', lastName: '김'),
        'haeun.kim',
      );
      expect(faker.internet.email(), matches(r'^[a-z]+\.[a-z]+@'));
    });

    test('sex follows the female ratio', () {
      final faker = ko();
      final females = List.generate(
        1000,
        (_) => faker.person.sex(femaleRatio: 0.8),
      ).where((s) => s == CoSex.female).length;
      expect(females, inInclusiveRange(740, 860));
    });
  });

  group('schema roles', () {
    test('infers rrn and business number fields', () {
      final faker = ko();
      expect(faker.schema.infer('rrnMasked'), CoFieldRole.rrn);
      expect(faker.schema.infer('businessNumber'), CoFieldRole.businessNumber);
      final record = faker.schema({
        'rrnMasked': 'String',
        'bizNo': 'String',
        'phone': 'String',
      });
      expect(record['rrnMasked'], matches(r'^\d{6}-[1-4]\*{6}$'));
      expect(record['bizNo'], matches(r'^\d{3}-\d{2}-\d{5}$'));
      expect(record['phone'], matches(r'^010-0\d{3}-\d{4}$'));
    });
  });
}
