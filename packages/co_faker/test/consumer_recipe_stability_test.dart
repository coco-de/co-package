import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// Inferred roles and generated values of the planned entities of the demos
/// that already use co_faker — coco-de/cocode#653 healthcare_vet, #657
/// exchange_remittance and #659 ecommerce_grocery (co-bricks `recipes/` at
/// 5c030ed9) — and the roles of the packs they register.
///
/// Recorded after co-package#99, whose intended changes to these plans are
/// `vet_slot.capacity` and `delivery_slot.capacity` (city → quantity),
/// `vaccination.petName` (name → vet.petName),
/// `grocery_product.originRegion` (address → grocery.originRegion) and
/// `grocery_order.slotLabel` (category → grocery.slotLabel); every other row
/// and value equals 0.13.0. Regenerate only for an intentional, documented
/// change:
/// `CO_FAKER_WRITE_SNAPSHOT=1 dart test test/consumer_recipe_stability_test.dart`.
const String _fixture = 'test/fixtures/consumer_recipes_v0_13.json';

/// Packs whose entity roles the demos rely on.
const List<CoFakerDomain> _packs = [
  CoFakerDomains.vet,
  CoFakerDomains.remit,
  CoFakerDomains.fx,
  CoFakerDomains.grocery,
];

/// The longest string the fixture keeps whole.
const int _readableLength = 120;

void main() {
  final fixture =
      jsonDecode(File(_fixture).readAsStringSync()) as Map<String, Object?>;
  final recipes = fixture['recipes']! as Map<String, Object?>;

  if (Platform.environment['CO_FAKER_WRITE_SNAPSHOT'] == '1') {
    test('writes the consumer recipe fixture', () {
      final encoded = <String, Object?>{
        'recipes': {
          for (final recipe in recipes.entries)
            recipe.key: _snapshot(
              (recipe.value! as Map<String, Object?>)['entities']! as List,
            ),
        },
        'packs': _packRoles(),
      };
      File(_fixture).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(encoded)}\n',
      );
    });
    return;
  }

  for (final recipe in recipes.entries) {
    final expected = recipe.value! as Map<String, Object?>;
    final actual = _snapshot(expected['entities']! as List);
    test('${recipe.key} keeps its roles', () {
      expect(actual['roles'], expected['roles']);
    });
    test('${recipe.key} keeps its values for the same seed', () {
      expect(jsonDecode(jsonEncode(actual['values'])), expected['values']);
    });
  }

  test('the demo packs keep the roles of their entities', () {
    expect(_packRoles(), fixture['packs']);
  });
}

List<CoCoverageEntity> _requests(List<Object?> entities) => [
  for (final raw in entities.cast<Map<String, Object?>>())
    CoCoverageEntity(
      raw['name']! as String,
      fields: Map<String, String>.from(raw['fields'] as Map? ?? const {}),
      roles: Map<String, String>.from(raw['roles'] as Map? ?? const {}),
      enums: {
        for (final entry in (raw['enums'] as Map? ?? const {}).entries)
          entry.key as String: List<String>.from(entry.value as List),
      },
    ),
];

Map<String, Object?> _snapshot(List<Object?> entities) {
  final requests = _requests(entities);
  final checker = CoFakerCoverage(
    CoFaker(locale: 'ko', seed: 0, domains: CoFakerDomains.all),
  );
  final values = <String, Object?>{};
  for (final locale in ['ko', 'en']) {
    final faker = CoFaker(
      locale: locale,
      seed: 7,
      now: DateTime.utc(2026),
      domains: CoFakerDomains.all,
    );
    for (final request in requests) {
      values['$locale/${request.name}'] = [
        for (final record in faker.schema.records(
          2,
          request.fields,
          roles: request.roles,
          enums: request.enums,
          entity: request.name,
          streamKey: request.name,
        ))
          {
            for (final entry in record.entries)
              entry.key: _readable(entry.value),
          },
      ];
    }
  }
  return {
    'entities': entities,
    'roles': {
      for (final row in checker.check(requests).rows)
        '${row.entity}.${row.field}': '${row.role} ${row.status.name}',
    },
    'values': values,
  };
}

Map<String, String> _packRoles() {
  final checker = CoFakerCoverage(
    CoFaker(locale: 'ko', seed: 0, domains: CoFakerDomains.all),
  );
  return {
    for (final pack in _packs)
      for (final row in checker.check([
        for (final entity in pack.entities.keys)
          CoCoverageEntity('${pack.name}.$entity'),
      ]).rows)
        '${row.entity}.${row.field}': '${row.role} ${row.status.name}',
  };
}

Object? _readable(Object? value) => switch (value) {
  final String text when text.length > _readableLength =>
    '${text.substring(0, 60)}…(${text.length})',
  final DateTime date => date.toIso8601String(),
  _ => value,
};
