import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/domain_snapshot.dart';

/// Domain output of `ko` and `en` recorded before the authored text moved from
/// `ko`/`en` string pairs to language bundles. Regenerate only for an
/// intentional, documented change:
/// `CO_FAKER_WRITE_SNAPSHOT=1 dart test test/domain_output_stability_test.dart`.
const String _fixture = 'test/fixtures/domain_snapshot_ko_en.json';

/// How many records of a role, or rows of an entity, the fixture keeps in
/// readable form. The digests cover all of them.
const int _readableRecords = 2;

/// The longest string the fixture keeps whole in readable form.
const int _readableLength = 120;

void main() {
  final write = Platform.environment['CO_FAKER_WRITE_SNAPSHOT'] == '1';

  if (write) {
    test('writes the domain snapshot fixture', () {
      File(_fixture)
        ..createSync(recursive: true)
        ..writeAsStringSync(_encodeFixture());
    });
    return;
  }

  final fixture =
      jsonDecode(File(_fixture).readAsStringSync()) as Map<String, Object?>;
  final locales = fixture['locales']! as Map<String, Object?>;

  test('the fixture covers the pinned locales, seeds and records', () {
    expect(locales.keys, unorderedEquals(domainSnapshotLocales));
    expect(fixture['seeds'], domainSnapshotSeeds);
    expect(fixture['records'], domainSnapshotRecords);
    expect(fixture['rows'], domainSnapshotRows);
  });

  for (final locale in domainSnapshotLocales) {
    final recorded = locales[locale]! as Map<String, Object?>;
    final digests = (recorded['digests']! as Map<String, Object?>)
        .cast<String, String>();
    final samples = recorded['samples']! as Map<String, Object?>;
    Map<String, Object?>? snapshot;
    Map<String, Object?> actualSnapshot() =>
        snapshot ??= domainSnapshot(locale);

    test('$locale pins every role, entity and generator', () {
      expect(digests.keys.where((key) => key.startsWith('role/')), isNotEmpty);
      expect(
        digests.keys.where((key) => key.startsWith('entity/')),
        isNotEmpty,
      );
      expect(
        digests.keys.where((key) => key.startsWith('generator/')),
        isNotEmpty,
      );
    });

    test('$locale keeps its domain output byte for byte', () {
      final actual = _digestsOf(actualSnapshot());
      expect(
        actual.keys,
        containsAll(digests.keys),
        reason: 'a pinned role, entity or generator no longer produces output',
      );
      final changed = <String>[
        for (final entry in digests.entries)
          if (actual[entry.key]!.digest != entry.value)
            '${entry.key}\n'
                '  recorded: ${jsonEncode(samples[entry.key])}\n'
                '  now:      ${actual[entry.key]!.readable}',
      ];
      expect(
        changed,
        isEmpty,
        reason: '${changed.length} of ${digests.length} outputs changed',
      );
    });

    test('$locale keeps the readable samples of the fixture', () {
      final actual = actualSnapshot();
      for (final entry in samples.entries) {
        expect(
          _readable(actual['${entry.key}/${domainSnapshotSeeds.first}']),
          entry.value,
          reason: '$locale ${entry.key}',
        );
      }
    });
  }
}

/// The digest of every output across all seeds, and its readable form for the
/// first seed.
typedef _Entry = ({String digest, Object? readable});

Map<String, _Entry> _digestsOf(Map<String, Object?> snapshot) {
  final names = <String>{
    for (final key in snapshot.keys) key.substring(0, key.lastIndexOf('/')),
  };
  return {
    for (final name in names)
      name: (
        digest: [
          for (final seed in domainSnapshotSeeds)
            domainDigest(encodeSnapshotValue(snapshot['$name/$seed'])),
        ].join('-'),
        readable: _readable(snapshot['$name/${domainSnapshotSeeds.first}']),
      ),
  };
}

/// A short, human-readable excerpt of one output: the first records or rows,
/// with long strings (a JSON rate series, say) cut.
Object? _readable(Object? value) {
  if (value is List<Object?> && value.length > _readableRecords) {
    return value.take(_readableRecords).map(_shorten).toList();
  }
  return _shorten(value);
}

Object? _shorten(Object? value) {
  return switch (value) {
    final String text when text.length > _readableLength =>
      '${text.substring(0, _readableLength)}... (${text.length} characters)',
    final List<Object?> list => list.map(_shorten).toList(),
    final Map<String, Object?> map => {
      for (final entry in map.entries) entry.key: _shorten(entry.value),
    },
    _ => value,
  };
}

String _encodeFixture() {
  final buffer = StringBuffer()
    ..writeln('{')
    ..writeln('  "seeds": ${jsonEncode(domainSnapshotSeeds)},')
    ..writeln('  "records": $domainSnapshotRecords,')
    ..writeln('  "rows": $domainSnapshotRows,')
    ..writeln('  "locales": {');
  for (var l = 0; l < domainSnapshotLocales.length; l++) {
    final locale = domainSnapshotLocales[l];
    final entries = _digestsOf(domainSnapshot(locale));
    final names = entries.keys.toList()..sort();
    buffer
      ..writeln('    ${jsonEncode(locale)}: {')
      ..writeln('      "digests": {');
    for (var i = 0; i < names.length; i++) {
      final comma = i == names.length - 1 ? '' : ',';
      buffer.writeln(
        '        ${jsonEncode(names[i])}: '
        '${jsonEncode(entries[names[i]]!.digest)}$comma',
      );
    }
    buffer
      ..writeln('      },')
      ..writeln('      "samples": {');
    final lines = [
      for (final name in names)
        '        ${jsonEncode(name)}: ${jsonEncode(entries[name]!.readable)}',
    ];
    buffer
      ..writeln(lines.join(',\n'))
      ..writeln('      }')
      ..writeln('    }${l == domainSnapshotLocales.length - 1 ? '' : ','}');
  }
  buffer
    ..writeln('  }')
    ..writeln('}');
  return buffer.toString();
}
