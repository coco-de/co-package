import 'dart:convert';

import 'package:co_faker/co_faker.dart';

/// Locale codes whose domain output is pinned.
///
/// The authored text of the domain packs and the dedicated generators was moved
/// from `ko`/`en` string pairs to language bundles without changing a byte of
/// what `ko` and `en` generate; this pins that output.
const List<String> domainSnapshotLocales = <String>['ko', 'en'];

/// Seeds every role and generator is run with.
const List<int> domainSnapshotSeeds = <int>[7, 20261005, 436];

/// Records generated for each role: indexes `0..4`.
const int domainSnapshotRecords = 5;

/// Rows generated for each registered entity.
const int domainSnapshotRows = 6;

final DateTime _now = DateTime.utc(2026, 1, 15);

/// Runs every domain role, entity, and dedicated generator of a seeded
/// [CoFaker] for [locale] and returns each result, keyed by what produced it.
///
/// A key reads `<kind>/<name>/<seed>`: `role/dental.dentalProcedure/7` holds
/// the first [domainSnapshotRecords] records of that role, `entity/…` the rows
/// of a registered entity, and `generator/…` the public methods of the
/// dedicated generators (`fx`, `remit`, `vet`, `booking`, `catalog`,
/// `examPrep`, and the helpdesk drafts). Only public API is called, so the
/// snapshot can be produced by one revision and compared against another.
Map<String, Object?> domainSnapshot(String locale) {
  CoFaker faker(int seed) => CoFaker(
    locale: locale,
    seed: seed,
    now: _now,
    domains: CoFakerDomains.all,
  );

  final values = <String, Object?>{};
  for (final seed in domainSnapshotSeeds) {
    for (final pack in CoFakerDomains.all) {
      for (final entry in pack.roles.entries) {
        final qualified = '${pack.name}.${entry.key}';
        final type = entry.value.supportedTypes?.first ?? 'String';
        final f = faker(seed);
        values['role/$qualified/$seed'] = <Object?>[
          for (var i = 0; i < domainSnapshotRecords; i++)
            _jsonSafe(
              f.schema.record(
                {'value': type},
                roles: {'value': qualified},
                streamKey: qualified,
                index: i,
              )['value'],
            ),
        ];
      }
      for (final entity in pack.entities.entries) {
        final qualified = '${pack.name}.${entity.key}';
        final references = {
          for (final field in entity.value.keys)
            if (field.endsWith('Id') && field != 'parentId') field: 3,
        };
        values['entity/$qualified/$seed'] = _jsonSafe(
          faker(seed).schema.entities(
            qualified,
            domainSnapshotRows,
            referenceCounts: references,
          ),
        );
      }
    }
    _generators(faker(seed), seed, (name, value) {
      values['generator/$name/$seed'] = _jsonSafe(value);
    });
  }
  return values;
}

/// Calls the public methods of the dedicated generators.
void _generators(CoFaker f, int seed, void Function(String, Object?) put) {
  const fxCodes = <String>[...CoFakerFx.currencyCodes, 'PHP', 'NPR'];
  for (final code in fxCodes) {
    put('fx.currency.$code', f.fx.currency(code: code).toJson());
  }
  put('fx.currency.random', [
    for (var i = 0; i < 4; i++) f.fx.currency().toJson(),
  ]);
  put('fx.denomination', [for (var i = 0; i < 4; i++) f.fx.denomination()]);
  put('fx.maskedAccount', [for (var i = 0; i < 3; i++) f.fx.maskedAccount()]);
  put('fx.rateSeries', [
    for (final point in f.fx.rateSeries(currencyCode: 'EUR', days: 4))
      point.toJson(),
  ]);

  for (final code in CoFakerRemit.countryCodes) {
    put(
      'remit.recipient.$code',
      f.remit.recipient(index: 2, countryCode: code).toJson(),
    );
  }
  put('remit.recipient.random', [
    for (var i = 0; i < 4; i++) f.remit.recipient(index: i).toJson(),
  ]);
  put('remit.transfer', [
    for (var i = 0; i < 4; i++) f.remit.transfer(index: i).toJson(),
  ]);
  put('remit.milestones', f.remit.milestones(f.remit.transfer(index: 3)));

  for (final kind in CoFakerVet.animalKinds) {
    put('vet.breeds.$kind', f.vet.breeds(kind));
    put('vet.pet.$kind', [
      for (var i = 0; i < 3; i++) f.vet.pet(animalKind: kind).toJson(),
    ]);
  }
  put('vet.pet.random', [for (var i = 0; i < 8; i++) f.vet.pet().toJson()]);

  put('booking.slots', [
    for (final slot in f.booking.slots(days: 2, blocksPerDay: 4)) slot.toJson(),
  ]);

  for (final grocery in [false, true]) {
    final name = grocery ? 'grocery' : 'commerce';
    put('catalog.item.$name', [
      for (var i = 0; i < 9; i++)
        f.catalog.item(grocery: grocery, index: i).toJson(),
    ]);
    put('catalog.item.$name.random', [
      for (var i = 0; i < 4; i++) f.catalog.item(grocery: grocery).toJson(),
    ]);
  }

  put('examPrep.question', [
    for (var i = 0; i < CoFakerExamPrep.sections.length + 2; i++)
      f.examPrep.question(index: i).toJson(),
  ]);
  put('examPrep.question.random', [
    for (var i = 0; i < 4; i++) f.examPrep.question().toJson(),
  ]);

  put('helpdesk.drafts', CoFakerHelpdesk(f).drafts());
}

/// Encodes [value] as the compact JSON that [domainDigest] hashes.
String encodeSnapshotValue(Object? value) => jsonEncode(value);

/// A 64-bit FNV-1a digest of [text], as 16 hex digits.
///
/// The fixture keeps one digest for each value so that it stays small while a
/// change to any generated character still fails the comparison.
String domainDigest(String text) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(text)) {
    hash = (hash ^ byte) * 0x100000001b3;
  }
  String half(int value) =>
      (value & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return '${half(hash >> 32)}${half(hash)}';
}

Object? _jsonSafe(Object? value) {
  return switch (value) {
    final DateTime date => date.toIso8601String(),
    final Map<Object?, Object?> map => <String, Object?>{
      for (final entry in map.entries) '${entry.key}': _jsonSafe(entry.value),
    },
    final Iterable<Object?> list => list.map(_jsonSafe).toList(),
    _ => value,
  };
}
