import 'dart:convert';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

CoFaker _faker({String locale = 'ko', int seed = 436}) => CoFaker(
  locale: locale,
  seed: seed,
  now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
);

void main() {
  test(
    'pet species, breeds and bounded weights agree in helpers and schema',
    () {
      for (final locale in ['ko', 'en']) {
        final f = _faker(locale: locale);
        for (final kind in CoFakerVet.animalKinds) {
          for (var i = 0; i < 15; i++) {
            final pet = f.vet.pet(animalKind: kind);
            expect(pet.animalKind, kind);
            expect(f.vet.breeds(kind), contains(pet.breed));
            expect(pet.weightKg, greaterThan(0));
            expect(
              pet.weightKg,
              lessThanOrEqualTo(
                kind == 'dog'
                    ? 35.0
                    : kind == 'cat'
                    ? 6.5
                    : kind == 'small_mammal'
                    ? 3.0
                    : kind == 'bird'
                    ? 0.15
                    : 4.0,
              ),
            );
          }
        }
        final rows = f.schema.entities(
          'vet.pet',
          100,
          referenceCounts: {'guardianId': 40},
        );
        final smallBatch = rows.take(42).toList();
        expect(
          smallBatch.where((r) => r['animalKind'] == 'dog').length,
          inInclusiveRange(23, 28),
        );
        expect(
          smallBatch.where((r) => r['animalKind'] == 'cat').length,
          inInclusiveRange(12, 17),
        );
        expect(
          smallBatch.where((r) => !['dog', 'cat'].contains(r['animalKind'])),
          isNotEmpty,
        );
        expect(rows.where((r) => r['animalKind'] == 'dog'), hasLength(60));
        expect(rows.where((r) => r['animalKind'] == 'cat'), hasLength(35));
        for (final row in rows) {
          expect(
            f.vet.breeds(row['animalKind'] as String),
            contains(row['breed']),
          );
          expect(row['weightKg'], greaterThan(0));
        }
        expect(() => f.vet.pet(animalKind: 'unknown'), throwsArgumentError);
        expect(() => f.vet.breeds('unknown'), throwsArgumentError);
      }
    },
  );

  test(
    'grocery/commerce catalog code, name, category, price and unit cohere',
    () {
      for (final grocery in [false, true]) {
        final f = _faker();
        final entity = grocery ? 'grocery.grocery_product' : 'commerce.product';
        final rows = f.schema.entities(entity, 21);
        expect(rows.map((row) => row['code']).toSet(), hasLength(21));
        final catalog = <String, Map<String, Object?>>{};
        for (var i = 0; i < rows.length; i++) {
          final item = f.catalog.item(grocery: grocery, index: i);
          final row = rows[i];
          expect(row['code'], item.code);
          expect(row['name'], item.name);
          expect(row['category'], item.category);
          expect(row['price'], item.price);
          expect(row['listPrice'], greaterThanOrEqualTo(row['price'] as int));
          final immutableValues = {
            'name': row['name'],
            'category': row['category'],
            'price': row['price'],
            'listPrice': row['listPrice'],
          };
          final old = catalog[row['code']];
          if (old != null) {
            expect(immutableValues, old);
          }
          catalog[row['code'] as String] = immutableValues;
          if (grocery) {
            expect(row['storageType'], item.storageType);
            expect(row['weightLabel'], item.unitLabel);
            if (row['name'] == '손만두') {
              expect(row['storageType'], 'frozen');
            }
            if (row['name'] == '현미') {
              expect(row['storageType'], 'ambient');
            }
            if (row['name'] == '우유') {
              expect(row['storageType'], 'chilled');
            }
          }
        }
      }
      expect(() => _faker().catalog.item(index: -1), throwsArgumentError);
    },
  );

  test(
    'question helper and pipe adapter preserve the correct shuffled answer',
    () {
      // `nl` stands for a language without domain text, which reads English
      // and never gets any. Every language that has domain text is read as
      // well, so that the questions of a language that is localized keep their
      // invariants: the four choices differ, and the explanation contains the
      // correct choice.
      final languages = <String>[
        'nl',
        for (final language in CoFakerLanguages.all)
          if (language.domain) language.code,
      ];
      for (final locale in languages) {
        final f = _faker(locale: locale);
        final seen = <String>{};
        for (var i = 0; i < 120; i++) {
          final q = f.derive('question/$i').examPrep.question(index: i);
          seen.add(q.section);
          expect(q.choices, hasLength(4));
          expect(
            q.choices.toSet(),
            hasLength(4),
            reason: '$locale: the four choices of a question must differ',
          );
          expect(q.answerKeys, hasLength(1));
          expect(q.answerKeys.single, inInclusiveRange(1, 4));
          final correct = q.choices[q.answerKeys.single - 1];
          expect(
            q.explanation,
            contains(correct),
            reason:
                '$locale: exam_prep.explanation must contain its correct '
                'choice',
          );
          expect(q.choiceSet.split('|'), hasLength(4));
          final row = f.schema.entity('exam_prep.question', index: i);
          final answer = int.parse(row['answerKeys'] as String);
          final options = (row['choices'] as String).split('|');
          final correctText = options[answer - 1].substring(1);
          expect(row['explanation'], contains(correctText));
          expect(row['section'], q.section);
          expect(row['difficulty'], q.difficulty);
          expect(
            _faker(
              locale: locale,
            ).derive('question/$i').examPrep.question(index: i).toJson(),
            q.toJson(),
          );
        }
        expect(seen, CoFakerExamPrep.sections.toSet());
      }
      expect(() => _faker().examPrep.question(index: -1), throwsArgumentError);
    },
  );

  test(
    'UTC booking grid closes Sundays and keeps ordered capacity-consistent blocks',
    () {
      final f = _faker();
      final slots = f.booking.slots(days: 7, sundayClosed: true);
      expect(slots, hasLength(112));
      expect(
        slots.map((s) => s.toJson()).toList(),
        _faker().booking
            .slots(days: 7, sundayClosed: true)
            .map((s) => s.toJson())
            .toList(),
      );
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        expect(s.startsAt.isUtc, isTrue);
        expect(s.endsAt.isUtc, isTrue);
        expect(s.endsAt.difference(s.startsAt), const Duration(minutes: 30));
        expect(s.remaining, inInclusiveRange(0, s.capacity));
        if (s.startsAt.weekday == DateTime.sunday) {
          expect(s.capacity, 0);
        }
        if (i > 0) {
          expect(s.startsAt.isAfter(slots[i - 1].startsAt), isTrue);
        }
      }
      expect(
        f.booking
            .slots(days: 14, sundayClosed: true)
            .take(112)
            .map((s) => s.toJson())
            .toList(),
        slots.map((s) => s.toJson()).toList(),
      );
      final rows = f.schema.entities('booking.booking_slot', 32);
      for (final row in rows) {
        expect(
          (row['endsAt'] as DateTime).difference(row['startsAt'] as DateTime),
          const Duration(minutes: 30),
        );
        expect(row['remaining'], inInclusiveRange(0, row['capacity'] as int));
      }
      expect(() => f.booking.slot(capacity: -1), throwsArgumentError);
      expect(
        () => f.booking.slot(blocksPerDay: 48, durationMinutes: 60),
        throwsArgumentError,
      );
      expect(() => f.booking.slots(days: 0), throwsArgumentError);
    },
  );

  test(
    'numeric roles use their specified units and ranges, not scalar fallback',
    () {
      const ranges = <String, (String, num, num)>{
        'daycare.bodyTemperature': ('double', 36.2, 37.4),
        'daycare.napMinutes': ('int', 0, 150),
        'brokerage.quoteAmount': ('int', 50000, 60000000),
        'brokerage.responseTime': ('int', 5, 360),
        'fx.krwAmount': ('int', 10000, 5000000),
        'meetup.duesAmount': ('int', 1000, 20000),
        'hrd.trainingHours': ('int', 1, 8),
        'logistics.palletCount': ('int', 1, 24),
      };
      final f = _faker();
      for (final role in ranges.entries) {
        for (var i = 0; i < 40; i++) {
          final value = f.schema.record(
            {'value': role.value.$1},
            roles: {'value': role.key},
            index: i,
          )['value'];
          expect(
            value,
            inInclusiveRange(role.value.$2, role.value.$3),
            reason: role.key,
          );
        }
      }
      for (var i = 0; i < 100; i++) {
        final dental = f.schema.record(
          {'tooth': 'String', 'months': 'int'},
          roles: {
            'tooth': 'dental.toothNumber',
            'months': 'dental.recallInterval',
          },
          index: i,
        );
        expect(dental['tooth'], matches(RegExp(r'^[1-4][1-8]$')));
        expect([3, 6, 12], contains(dental['months']));
        final minutes = f.schema.record(
          {'value': 'int'},
          roles: {'value': 'homecare.serviceMinutes'},
          index: i,
        )['value'];
        expect([60, 90, 120, 180], contains(minutes));
        final vitals = f.schema.entity(
          'homecare.vital_sign',
          index: i,
          referenceCounts: {'recipientId': 4},
        );
        expect(vitals['systolic'], inInclusiveRange(110, 140));
        expect(vitals['diastolic'], inInclusiveRange(70, 90));
        expect(
          vitals['systolic'] as int,
          greaterThan(vitals['diastolic'] as int),
        );
        expect(vitals['bodyTemperature'], inInclusiveRange(36.2, 37.4));
        final adapter = f.schema.record(
          {'value': 'String'},
          roles: {'value': 'homecare.vitalReading'},
          index: i,
        );
        final decoded = jsonDecode(adapter['value'] as String) as Map;
        expect(decoded['pressureUnit'], 'mmHg');
        expect(decoded['systolic'], greaterThan(decoded['diastolic'] as int));
      }
    },
  );

  test(
    'human-authored simulated drafts cover five categories with eight records',
    () {
      final drafts = CoFakerHelpdesk(_faker()).drafts();
      expect(drafts, hasLength(8));
      expect(drafts.map((r) => r['category']).toSet(), {
        'account',
        'billing',
        'data_export',
        'integration',
        'bug',
      });
      expect(drafts.map((r) => r['code']).toSet(), hasLength(8));
      for (final draft in drafts) {
        expect(draft['templateBody'], contains('모의 AI 초안'));
        expect(draft['isSimulated'], isTrue);
        expect(draft['sourceArticleCode'], matches(RegExp(r'^HA-\d{4}$')));
      }
      // A language without domain text reads English. `nl` stands for one
      // that never gets any: a language of the Epic (`pt`) writes its own
      // drafts once it is localized.
      expect(
        CoFakerHelpdesk(_faker(locale: 'en')).drafts(),
        CoFakerHelpdesk(_faker(locale: 'nl')).drafts(),
      );
    },
  );
}
