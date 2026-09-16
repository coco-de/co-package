import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  group('CoFakerSchema', () {
    const fields = <String, String>{
      'title': 'String',
      'instructor': 'String',
      'email': 'String',
      'price': 'int',
      'rating': 'double',
      'isPublished': 'bool',
      'startsAt': 'DateTime?',
      'createdAt': 'String',
      'thumbnailUrl': 'String',
      'courseId': 'int',
      'sortOrder': 'int',
      'status': 'String',
    };
    const enums = <String, List<String>>{
      'status': ['draft', 'open', 'closed'],
    };

    CoFaker faker({String locale = 'ko'}) =>
        CoFaker(locale: locale, seed: 7, now: DateTime.utc(2026, 1, 1, 9));

    test('is deterministic for the same seed, clock, schema and index', () {
      final first = faker().schema(fields, index: 3, enums: enums);
      final second = faker().schema(fields, index: 3, enums: enums);

      expect(first, second);
    });

    test('produces typed values matching the declared field types', () {
      final record = faker().schema(fields, index: 0, enums: enums);

      expect(record['title'], isA<String>());
      expect(record['price'], isA<int>());
      expect(record['rating'], isA<double>());
      expect(record['isPublished'], isA<bool>());
      expect(record['startsAt'], isA<DateTime>());
      expect((record['startsAt']! as DateTime).isUtc, isTrue);
      expect(record['createdAt'], endsWith('Z'));
      expect(record['courseId'], inInclusiveRange(1, 10));
      expect(record['sortOrder'], 1);
      expect(record['email'], contains('@'));
      expect(record['thumbnailUrl'], startsWith('data:image/svg+xml;base64,'));
      expect(record['status'], 'draft');
    });

    test('keeps other fields stable when a field is added', () {
      final before = faker().schema(fields, index: 1, enums: enums);
      final after = faker().schema(
        {...fields, 'summary': 'String'},
        index: 1,
        enums: enums,
      );

      for (final key in fields.keys) {
        expect(after[key], before[key], reason: key);
      }
      expect(after['summary'], isA<String>());
    });

    test('cycles status values so every value appears', () {
      final records = faker().schema.records(6, fields, enums: enums);

      expect(records.map((record) => record['status']).toList(), [
        'draft',
        'open',
        'closed',
        'draft',
        'open',
        'closed',
      ]);
    });

    test('separates entities with identical schemas by stream key', () {
      final course = faker().schema.records(2, fields, streamKey: 'course');
      final lesson = faker().schema.records(2, fields, streamKey: 'lesson');

      expect(course.first['title'], isNot(lesson.first['title']));
    });

    test('forces roles by name and rejects unknown roles', () {
      final record = faker().schema(
        {'headline': 'String', 'label': 'String'},
        roles: {'headline': 'description', 'label': 'badge'},
      );
      final categories = faker().localeData.categories;

      expect((record['headline']! as String).contains('.'), isTrue);
      expect(categories, contains(record['label']));
      expect(
        () => faker().schema({'x': 'String'}, roles: {'x': 'nope'}),
        throwsArgumentError,
      );
    });

    test('infers roles from common field names', () {
      final schema = faker().schema;

      expect(schema.infer('id', type: 'int'), CoFieldRole.id);
      expect(schema.infer('shop_id', type: 'int'), CoFieldRole.reference);
      expect(schema.infer('instructor'), CoFieldRole.name);
      expect(schema.infer('imageUrl'), CoFieldRole.image);
      expect(schema.infer('avatarUrl'), CoFieldRole.avatar);
      expect(schema.infer('dueAt', type: 'DateTime'), CoFieldRole.dateFuture);
      expect(schema.infer('updatedAt', type: 'DateTime'), CoFieldRole.date);
      expect(schema.infer('completed', type: 'bool'), CoFieldRole.boolean);
      expect(schema.infer('remaining', type: 'int'), CoFieldRole.quantity);
      expect(schema.infer('description'), CoFieldRole.description);
      expect(
        schema.infer('durationMinutes', type: 'int'),
        CoFieldRole.quantity,
      );
      expect(schema.infer('memo', type: 'String?'), CoFieldRole.description);
      expect(schema.infer('weight', type: 'double'), CoFieldRole.number);
      expect(schema.infer('nickname'), CoFieldRole.username);
      expect(schema.infer('stage', hasEnum: true), CoFieldRole.status);
      expect(schema.infer('stage'), CoFieldRole.status);
      expect(
        schema.infer('startsAt', type: 'DateTime'),
        CoFieldRole.dateFuture,
      );
      expect(schema.infer('location'), CoFieldRole.address);
      expect(schema.infer('format'), CoFieldRole.text);
      expect(schema.infer('name', entity: 'customer'), CoFieldRole.name);
      expect(schema.infer('name', entity: 'shop'), CoFieldRole.title);
      expect(schema.infer('name'), CoFieldRole.name);
    });

    test('coerces incompatible role values to the declared type', () {
      final record = faker().schema({'title': 'int', 'price': 'String'});

      expect(record['title'], isA<int>());
      expect(record['price'], isA<String>());
    });

    test('uses localized data for the selected locale', () {
      final korean = faker().schema({'name': 'String'});
      final english = faker(locale: 'en').schema({'name': 'String'});

      expect(korean['name'], matches(RegExp(r'^[가-힣]+$')));
      expect(english['name'], matches(RegExp('^[A-Za-z ]+\$')));
    });

    test('rejects negative indexes', () {
      expect(() => faker().schema(fields, index: -1), throwsArgumentError);
    });
  });

  group('0.3.0 roles', () {
    CoFaker faker({String locale = 'ko'}) =>
        CoFaker(locale: locale, seed: 11, now: DateTime.utc(2026, 1, 1, 9));

    test('infers currencyPair, place and rate from field names', () {
      final schema = faker().schema;
      expect(schema.infer('pair'), CoFieldRole.currencyPair);
      expect(schema.infer('fxPair'), CoFieldRole.currencyPair);
      expect(schema.infer('placeName'), CoFieldRole.place);
      expect(schema.infer('venue'), CoFieldRole.place);
      expect(schema.infer('meetingPoint'), CoFieldRole.place);
      expect(schema.infer('midRate', type: 'String'), CoFieldRole.rate);
      expect(schema.infer('exchangeRate', type: 'double'), CoFieldRole.rate);
      // rating is still a rating, name is still a name
      expect(schema.infer('rating'), CoFieldRole.rating);
      expect(schema.infer('name', entity: 'user'), CoFieldRole.name);
    });

    test(
      'generates a distinct-code pair, a localized place and a decimal rate',
      () {
        final record = faker().schema(const {
          'pair': 'String',
          'placeName': 'String',
          'midRate': 'String',
          'rate': 'double',
        }, index: 2);
        final pair = record['pair']! as String;
        expect(pair, matches(RegExp(r'^[A-Z]{3}/[A-Z]{3}$')));
        expect(pair.substring(0, 3), isNot(pair.substring(4)));
        expect(CoFakerLocales.korean.places, contains(record['placeName']));
        expect(double.parse(record['midRate']! as String), greaterThan(0));
        expect(record['rate'], isA<double>());
        expect(
          faker(
            locale: 'en',
          ).schema(const {'placeName': 'String'})['placeName'],
          isIn(CoFakerLocales.english.places),
        );
        // other locales fall back to English places
        expect(
          faker(
            locale: 'de',
          ).schema(const {'placeName': 'String'})['placeName'],
          isIn(CoFakerLocales.english.places),
        );
      },
    );

    test('CoFieldRole.parse knows the new roles', () {
      expect(CoFieldRole.parse('currency_pair'), CoFieldRole.currencyPair);
      expect(CoFieldRole.parse('place'), CoFieldRole.place);
      expect(CoFieldRole.parse('rate'), CoFieldRole.rate);
    });
  });
}
