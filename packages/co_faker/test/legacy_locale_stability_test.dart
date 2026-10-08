import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/language_state.dart';
import 'support/locale_snapshot.dart';

/// Output recorded with co_faker 0.10.0. Regenerate only for an intentional,
/// documented change: `CO_FAKER_WRITE_SNAPSHOT=1 dart test <this file>`.
const String _fixture = 'test/fixtures/locale_snapshot_v0_10.json';

void main() {
  final write = Platform.environment['CO_FAKER_WRITE_SNAPSHOT'] == '1';

  if (write) {
    test('writes the locale snapshot fixture', () {
      final snapshot = <String, Map<String, String>>{
        for (final code in stableLocaleCodes) code: localeSnapshot(code),
      };
      File(_fixture)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n',
        );
    });
    return;
  }

  final expected =
      (jsonDecode(File(_fixture).readAsStringSync()) as Map<String, Object?>)
          .map(
            (code, values) => MapEntry(
              code,
              (values! as Map<String, Object?>).cast<String, String>(),
            ),
          );

  test('the fixture covers every stable locale code', () {
    expect(expected.keys, unorderedEquals(stableLocaleCodes));
  });

  test('names the domain keys of the snapshot', () {
    // A key that is not named here is a base key, and is pinned for every
    // code: add a new domain key to isDomainSnapshotKey.
    final domainKeys = <String>{
      for (final values in expected.values)
        for (final key in values.keys)
          if (isDomainSnapshotKey(key)) key,
    };
    expect(domainKeys, <String>{
      'schema.patient',
      'schema.invoice',
      'clinic.clinicName',
      'clinic.drugName',
      'clinic.chartMemo',
    });
  });

  // The base modules keep their 0.10.0 bytes for every code, whatever
  // languages are localized. The domain keys (the clinic and SaaS output) keep
  // them only for a code whose language has no domain data yet: when a
  // language is localized, its clinic, SaaS, and domain pack output changes
  // from English to the language on purpose (see the CHANGELOG), and every
  // code of that language changes together (`ja`, `ja_JP`, and `ja-JP`). The
  // registries say which: `domainLocalized`. Korean and English keep every key.
  for (final code in stableLocaleCodes) {
    test('$code keeps its 0.10.0 output byte for byte', () {
      final actual = localeSnapshot(code);
      final recorded = expected[code]!;
      expect(actual.keys, unorderedEquals(recorded.keys));
      final localized = domainLocalized(code);
      for (final key in recorded.keys) {
        if (localized && isDomainSnapshotKey(key)) continue;
        expect(actual[key], recorded[key], reason: '$code $key');
      }
    });
  }
}
