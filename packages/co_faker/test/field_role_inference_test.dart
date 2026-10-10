import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// Field role inference defects of co-package#99: substring matches that
/// cross camelCase words (`capacity` → city), a money word that is not the
/// field's head noun (`totalSessions` → price), roles that do not fit the
/// declared type (`overBudget` bool → price), and pack entities whose fields
/// fell back to generic roles.

/// Planned fields of the co-bricks W1 recipes (5c030ed9) the issue reports:
/// entity → field → (type, expected role).
const Map<String, Map<String, (String, String)>> _issueFields = {
  // coco-de/cocode#662 booking_fitness
  'class_session': {'capacity': ('int', 'quantity')},
  'membership_pass': {'totalSessions': ('int', 'quantity')},
  'instructor': {'totalClassCount': ('int', 'quantity')},
  // coco-de/cocode#680 brokerage_services
  'service_offer': {
    'overBudget': ('bool', 'boolean'),
    'message': ('String', 'brokerage.proposalMessage'),
    'providerName': ('String', 'brokerage.providerName'),
  },
  'service_request': {'workMode': ('String', 'brokerage.workMode')},
  'portfolio_item': {
    'categoryName': ('String', 'brokerage.serviceCategory'),
    'title': ('String', 'brokerage.portfolioTitle'),
  },
  'provider_profile': {'skills': ('String', 'brokerage.skillTag')},
  'service_match': {'providerName': ('String', 'brokerage.providerName')},
};

CoFaker _faker({String locale = 'ko'}) => CoFaker(
  locale: locale,
  seed: 7,
  now: DateTime.utc(2026, 1, 1, 9),
  domains: CoFakerDomains.all,
);

void main() {
  group('co-package#99 recipe fields', () {
    final report = CoFakerCoverage(_faker()).check([
      for (final entity in _issueFields.entries)
        CoCoverageEntity(
          entity.key,
          fields: {
            for (final field in entity.value.entries) field.key: field.value.$1,
          },
        ),
    ]);

    for (final entity in _issueFields.entries) {
      for (final field in entity.value.entries) {
        test('${entity.key}.${field.key} resolves to ${field.value.$2}', () {
          final row = report.rows.singleWhere(
            (row) => row.entity == entity.key && row.field == field.key,
          );
          expect(row.role, field.value.$2);
          expect(
            row.status,
            anyOf(CoCoverageStatus.supported, CoCoverageStatus.generic),
          );
        });
      }
    }

    test('the whole plan is complete, so `cob plan --entities` exits 0', () {
      expect(report.complete, isTrue);
    });

    test('recipe enum values still override the pack role', () {
      final row = CoFakerCoverage(_faker())
          .check([
            const CoCoverageEntity(
              'service_request',
              fields: {'workMode': 'String'},
              enums: {
                'workMode': ['remote', 'onsite', 'hybrid'],
              },
            ),
          ])
          .rows
          .single;
      expect(row.role, 'status');
      expect(row.status, CoCoverageStatus.generic);
    });

    test('generates values of the declared type for every issue field', () {
      for (final entity in _issueFields.entries) {
        final fields = {
          for (final field in entity.value.entries) field.key: field.value.$1,
        };
        final record = _faker().schema.record(fields, entity: entity.key);
        for (final field in entity.value.entries) {
          final value = record[field.key];
          switch (field.value.$1) {
            case 'int':
              expect(value, isA<int>(), reason: field.key);
              expect(value! as int, inInclusiveRange(0, 100));
            case 'bool':
              expect(value, isA<bool>(), reason: field.key);
            default:
              expect(value, isA<String>(), reason: field.key);
              expect(value! as String, isNotEmpty, reason: field.key);
          }
        }
      }
    });
  });

  group('type guard', () {
    final schema = _faker().schema;

    test('a bool field only takes the boolean role', () {
      for (final name in [
        'overBudget',
        'priceVisible',
        'cityMatched',
        'titleHidden',
        'emailVerified',
        'hasPhoto',
      ]) {
        expect(
          schema.infer(name, type: 'bool'),
          CoFieldRole.boolean,
          reason: name,
        );
      }
    });

    test('an int field never takes a text role', () {
      const textRoles = {
        CoFieldRole.city,
        CoFieldRole.name,
        CoFieldRole.title,
        CoFieldRole.description,
        CoFieldRole.address,
        CoFieldRole.category,
        CoFieldRole.code,
        CoFieldRole.url,
        CoFieldRole.image,
        CoFieldRole.text,
      };
      for (final name in [
        'capacity',
        'cityCode',
        'memberCount',
        'titleLength',
        'addressLines',
        'categoryRank',
        'imageCount',
      ]) {
        for (final type in ['int', 'double', 'num', 'int?']) {
          expect(
            textRoles,
            isNot(contains(schema.infer(name, type: type))),
            reason: '$name: $type',
          );
        }
      }
    });

    test('a String field keeps its name role', () {
      expect(schema.infer('city'), CoFieldRole.city);
      expect(schema.infer('homeCity'), CoFieldRole.city);
      expect(schema.infer('budget'), CoFieldRole.price);
      expect(schema.infer('instructorName'), CoFieldRole.name);
    });
  });

  group('camelCase and snake_case words', () {
    final schema = _faker().schema;

    test('a needle must start a word, not sit inside one', () {
      for (final name in ['capacity', 'seatCapacity', 'seat_capacity']) {
        expect(
          schema.infer(name, type: 'int'),
          CoFieldRole.quantity,
          reason: name,
        );
        expect(schema.infer(name), isNot(CoFieldRole.city), reason: name);
      }
      expect(schema.infer('ethnicity'), isNot(CoFieldRole.city));
      expect(schema.infer('velocity', type: 'double'), CoFieldRole.number);
    });

    test('count and total<noun> are quantities', () {
      for (final name in [
        'totalSessions',
        'totalClassCount',
        'total_orders',
        'weeklyClassCount',
        'attendeeCount',
        'waitlistCount',
        'capacity',
        'headcount',
        'maxGuests',
      ]) {
        expect(
          schema.infer(name, type: 'int'),
          CoFieldRole.quantity,
          reason: name,
        );
      }
    });

    test('a total that is the head noun, or a money total, is a price', () {
      for (final name in [
        'total',
        'orderTotal',
        'grand_total',
        'subtotal',
        'totalPrice',
        'totalAmount',
        'totalCost',
        'totalMinor',
      ]) {
        expect(
          schema.infer(name, type: 'int'),
          CoFieldRole.price,
          reason: name,
        );
      }
    });

    test('stems keep matching the start of a longer word', () {
      expect(
        schema.infer('birthday', type: 'DateTime'),
        CoFieldRole.dateOfBirth,
      );
      expect(
        schema.infer('expiresAt', type: 'DateTime'),
        CoFieldRole.dateFuture,
      );
      expect(schema.infer('hashtags'), CoFieldRole.category);
      expect(schema.infer('coverImageUrl'), CoFieldRole.image);
      expect(schema.infer('instructorName'), CoFieldRole.name);
    });
  });

  group('list and tag fields', () {
    test('skills and keywords are supported outside a pack', () {
      final report = CoFakerCoverage(_faker()).check([
        const CoCoverageEntity(
          'mentor',
          fields: {'skills': 'String', 'keywords': 'String'},
        ),
      ]);
      for (final row in report.rows) {
        expect(row.role, 'category', reason: row.field);
        expect(row.status, CoCoverageStatus.generic, reason: row.field);
      }
    });
  });

  group('pack entity context', () {
    test('a pack entity field named like a pack role takes that role', () {
      final report = CoFakerCoverage(_faker()).check([
        // service_request maps only title, categoryName and workMode.
        const CoCoverageEntity(
          'service_request',
          fields: {'providerName': 'String', 'summary': 'String'},
        ),
        // Not a pack entity: the general role.
        const CoCoverageEntity('mentor', fields: {'providerName': 'String'}),
      ]);
      expect(
        report.rows.map((row) => '${row.entity}.${row.field}=${row.role}'),
        [
          'service_request.providerName=brokerage.providerName',
          'service_request.summary=description',
          'mentor.providerName=name',
        ],
      );
    });

    test('pack roles stay in the language of the generator', () {
      final ko = _faker().schema.record({
        'message': 'String',
        'providerName': 'String',
      }, entity: 'service_offer');
      final en = _faker(locale: 'en').schema.record({
        'message': 'String',
        'providerName': 'String',
      }, entity: 'service_offer');
      expect(ko['message'], isNot(en['message']));
      expect(ko['providerName'], isNot(en['providerName']));
    });
  });
}
