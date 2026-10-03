import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

CoFaker _faker({
  int seed = 436,
  String locale = 'ko',
  List<CoFakerDomain> domains = CoFakerDomains.all,
}) => CoFaker(
  locale: locale,
  seed: seed,
  now: DateTime.utc(2026, 1, 15),
  domains: domains,
);

void _expectType(Object? value, String type, String qualified) {
  switch (type) {
    case 'String':
      expect(value, isA<String>(), reason: qualified);
      expect(value, isNotEmpty, reason: qualified);
    case 'int':
      expect(value, isA<int>(), reason: qualified);
    case 'double':
      expect(value, isA<double>(), reason: qualified);
      expect((value as double).isFinite, isTrue, reason: qualified);
    case 'DateTime':
      expect(value, isA<DateTime>(), reason: qualified);
      expect((value as DateTime).isUtc, isTrue, reason: qualified);
    default:
      fail('No independent type assertion for $type');
  }
}

void main() {
  final inventory =
      jsonDecode(File('docs/prd_domain_inventory.json').readAsStringSync())
          as Map<String, dynamic>;
  final sources = (inventory['sources'] as List).cast<Map<String, dynamic>>();
  final types = (inventory['types'] as Map).cast<String, String>();
  final newPacks = (inventory['newPacks'] as List).cast<String>();

  test(
    'independent inventory includes each of the 36 PRDs and all 27 packs',
    () {
      expect(
        sources.map((s) => s['issue']).toList(),
        List.generate(36, (i) => 653 + i),
      );
      expect(sources.map((s) => s['recipe']).toSet(), hasLength(36));
      expect(CoFakerDomains.all.map((d) => d.name).toList().take(3), [
        'clinic',
        'saas',
        'korea',
      ]);
      expect(
        CoFakerDomains.all.skip(3).map((d) => d.name).toSet(),
        newPacks.toSet(),
      );
      expect(CoFakerDomains.all.map((d) => d.name).toSet(), hasLength(30));
      expect(sources.singleWhere((s) => s['issue'] == 677)['seed'], 1015);
      expect(sources.singleWhere((s) => s['issue'] == 678)['seed'], 2026);
      expect(sources.singleWhere((s) => s['issue'] == 679)['seed'], 314);
      expect(sources.singleWhere((s) => s['issue'] == 680)['seed'], 406);
      expect(sources.singleWhere((s) => s['issue'] == 681)['seed'], 777);
      expect(sources.singleWhere((s) => s['issue'] == 682)['seed'], 1119);
    },
  );

  for (final source in sources) {
    test(
      'PRD ${source['issue']} roles resolve, keep their types and seeded values',
      () {
        final fields = <String, String>{};
        final roles = <String, String>{};
        for (final entry in (source['roles'] as Map).entries) {
          expect(CoFakerDomains.byName(entry.key as String).name, entry.key);
          for (final role in entry.value as List) {
            final qualified = '${entry.key}.$role';
            expect(
              _faker().domains.findRole(qualified),
              isNotNull,
              reason: qualified,
            );
            fields[qualified] = types[qualified] ?? 'String';
            roles[qualified] = qualified;
          }
        }
        final key = 'PRD-${source['issue']}';
        final f = _faker(seed: source['seed'] as int);
        final row = f.schema.record(
          fields,
          roles: roles,
          streamKey: key,
          index: 7,
        );
        f.random.int();
        expect(
          f.schema.record(fields, roles: roles, streamKey: key, index: 7),
          row,
        );
        expect(
          _faker(
            seed: source['seed'] as int,
          ).schema.record(fields, roles: roles, streamKey: key, index: 7),
          row,
        );
        final extended = _faker(seed: source['seed'] as int).schema.record(
          {'unrelated': 'String', ...fields},
          roles: roles,
          streamKey: key,
          index: 7,
        );
        for (final field in fields.keys) {
          _expectType(row[field], fields[field]!, field);
          expect(extended[field], row[field], reason: field);
        }
        final report = CoFakerCoverage(
          f,
        ).check([CoCoverageEntity(key, fields: fields, roles: roles)]);
        expect(report.complete, isTrue, reason: report.toMarkdown());
        expect(
          report.rows.every((r) => r.status == CoCoverageStatus.supported),
          isTrue,
        );
      },
    );
  }

  test(
    'every new registered entity generates twins, valid enums and bounded references',
    () {
      for (final pack in CoFakerDomains.all.skip(3)) {
        expect(pack.entities, isNotEmpty, reason: pack.name);
        for (final entry in pack.entities.entries) {
          final name = '${pack.name}.${entry.key}';
          final refs = {
            for (final field in entry.value.keys.where(
              (key) => key.endsWith('Id') && key != 'parentId',
            ))
              field: 3,
          };
          final enums = pack.enums[entry.key] ?? {};
          final count = enums.values.fold<int>(
            6,
            (n, values) => n > values.length ? n : values.length,
          );
          final rows = _faker().schema.entities(
            name,
            count,
            referenceCounts: refs,
          );
          expect(
            rows,
            _faker().schema.entities(name, count, referenceCounts: refs),
            reason: name,
          );
          for (final row in rows) {
            for (final field in refs.keys) {
              expect(
                row[field],
                inInclusiveRange(1, 3),
                reason: '$name.$field',
              );
            }
          }
          for (final field in enums.entries) {
            if (name == 'vet.pet' && field.key == 'animalKind') {
              final pets = _faker().schema.entities(
                name,
                100,
                referenceCounts: refs,
              );
              expect(
                pets.map((r) => r[field.key]).toSet(),
                field.value.toSet(),
              );
            } else {
              expect(
                rows.map((r) => r[field.key]).toSet(),
                field.value.toSet(),
                reason: '$name.${field.key}',
              );
            }
          }
        }
      }
    },
  );

  test(
    'all mapped source enum values are represented without invented code drift',
    () {
      for (final entry in (inventory['roleEnums'] as Map).entries) {
        final allowed = (entry.value as List).cast<String>();
        final values = <Object?>{};
        for (var i = 0; i < allowed.length; i++) {
          values.add(
            _faker().schema.record(
              {'value': 'String'},
              roles: {'value': entry.key as String},
              index: i,
            )['value'],
          );
        }
        expect(values, allowed.toSet(), reason: entry.key as String);
      }
    },
  );

  test('taxonomy parents are roots or existing earlier rows, never cycles', () {
    const trees = {
      'grocery.produce_category': (7, 21),
      'exam_prep.exam_unit': (4, 22),
      'content.series_genre': (5, 14),
      'content.audio_genre': (2, 8),
      'content.letter_topic': (5, 15),
      'helpdesk.help_topic': (4, 12),
      'brokerage.home_service_type': (4, 21),
    };
    for (final tree in trees.entries) {
      final rows = _faker().schema.entities(tree.key, tree.value.$2);
      for (var i = 0; i < rows.length; i++) {
        final parent = rows[i]['parentId'] as int;
        if (i < tree.value.$1) {
          expect(parent, 0, reason: tree.key);
        } else {
          expect(parent, inInclusiveRange(1, tree.value.$1), reason: tree.key);
          expect(parent, lessThan(rows[i]['id'] as int));
          expect(rows[parent - 1]['parentId'], 0);
          expect(rows[i]['name'], contains(rows[parent - 1]['name'] as String));
        }
      }
    }
  });

  test('new packs cannot steal legacy inference or default entity values', () {
    final old = [
      CoFakerDomains.clinic,
      CoFakerDomains.saas,
      CoFakerDomains.korea,
    ];
    for (final pack in old) {
      for (final name in pack.entities.keys) {
        final entity = '${pack.name}.$name';
        expect(
          _faker().schema.entities(entity, 4),
          _faker(domains: old).schema.entities(entity, 4),
          reason: entity,
        );
      }
    }
    const fields = {
      'name': 'String',
      'status': 'String',
      'comment': 'String',
      'roomName': 'String',
      'unitPrice': 'int',
      'phone': 'String',
      'title': 'String',
      'recipient': 'String',
    };
    expect(
      _faker().schema.record(fields),
      _faker(domains: old).schema.record(fields),
    );
    for (final pack in CoFakerDomains.all.skip(3)) {
      expect(
        pack.roles.values.every((r) => r.fieldPatterns.isEmpty),
        isTrue,
        reason: pack.name,
      );
    }
  });

  test(
    'recipe enum overrides legacy SaaS codes without altering their defaults',
    () {
      final f = _faker();
      final rows = f.schema.records(
        4,
        {'channel': 'String', 'status': 'String'},
        roles: {
          'channel': 'saas.messageChannel',
          'status': 'saas.messageStatus',
        },
        enums: {
          'channel': ['email', 'app', 'web'],
          'status': ['queued', 'delivered', 'failed', 'excluded'],
        },
      );
      expect(rows.map((r) => r['channel']).toSet(), {'email', 'app', 'web'});
      expect(rows.map((r) => r['status']).toSet(), {
        'queued',
        'delivered',
        'failed',
        'excluded',
      });
      final report = CoFakerCoverage(f).check(const [
        CoCoverageEntity(
          'send_log',
          fields: {'channel': 'String'},
          roles: {'channel': 'saas.messageChannel'},
          enums: {
            'channel': ['email', 'app', 'web'],
          },
        ),
      ]);
      expect(report.rows.single.status, CoCoverageStatus.generic);
      final unchanged = f.schema.record(
        {'channel': 'String'},
        roles: {'channel': 'saas.messageChannel'},
      );
      expect(['alimtalk', 'sms', 'lms'], contains(unchanged['channel']));
    },
  );

  test(
    'unknown pack/role/entity and wrong role types are rejected honestly',
    () {
      expect(() => CoFakerDomains.byName('missing'), throwsArgumentError);
      for (final pack in CoFakerDomains.all.skip(3)) {
        final f = _faker();
        expect(f.domains.findRole('${pack.name}.unknown'), isNull);
        expect(
          () => f.schema.entity('${pack.name}.unknown'),
          throwsArgumentError,
        );
        expect(
          () => f.schema.record(
            {'field': 'String'},
            roles: {'field': '${pack.name}.unknown'},
          ),
          throwsArgumentError,
        );
        final stringRole = pack.roles.entries
            .firstWhere(
              (r) =>
                  r.value.supportedTypes!.length == 1 &&
                  r.value.supportedTypes!.single == 'String',
            )
            .key;
        final qualified = '${pack.name}.$stringRole';
        expect(
          () => f.schema.record({'field': 'bool'}, roles: {'field': qualified}),
          throwsArgumentError,
        );
        final report = CoFakerCoverage(f).check([
          CoCoverageEntity(
            pack.name,
            fields: {'field': 'bool'},
            roles: {'field': qualified},
          ),
        ]);
        expect(report.rows.single.status, CoCoverageStatus.unsupported);
      }
    },
  );

  test('Korean dictionaries and English fallback produce meaningful text', () {
    for (final pack in CoFakerDomains.all.skip(3)) {
      final roles = pack.roles;
      for (final entry in roles.entries) {
        if (entry.value.supportedTypes!.singleOrNull != 'String') continue;
        if (['rateSeries', 'vitalReading'].contains(entry.key)) continue;
        final qualified = '${pack.name}.${entry.key}';
        final en = _faker(
          locale: 'en',
        ).schema.record({'value': 'String'}, roles: {'value': qualified});
        final fallback = _faker(
          locale: 'pt',
        ).schema.record({'value': 'String'}, roles: {'value': qualified});
        expect(fallback, en, reason: qualified);
        expect(en['value'], isNotEmpty, reason: qualified);
      }
    }
  });
}
