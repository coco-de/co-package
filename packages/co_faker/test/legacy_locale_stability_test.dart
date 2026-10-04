import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

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

  for (final code in stableLocaleCodes) {
    test('$code keeps its 0.10.0 output byte for byte', () {
      final actual = localeSnapshot(code);
      final recorded = expected[code]!;
      expect(actual.keys, unorderedEquals(recorded.keys));
      for (final key in recorded.keys) {
        expect(actual[key], recorded[key], reason: '$code $key');
      }
    });
  }
}
