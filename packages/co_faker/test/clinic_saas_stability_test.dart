import 'dart:convert';
import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:test/test.dart';

import 'support/clinic_saas_snapshot.dart';
import 'support/language_state.dart';

/// Output of every public `faker.clinic` and `faker.saas` generator, recorded
/// with co_faker 0.11.0 before the two modules stopped reading the locale
/// code. Korean and English are recorded for three seeds; the other codes
/// (which fall back to English or Korean data) for one.
///
/// The fixture holds a digest per call, plus a readable sample of the first
/// run for Korean and English. Regenerate it only for an intentional,
/// documented change:
/// `CO_FAKER_WRITE_SNAPSHOT=1 dart test test/clinic_saas_stability_test.dart`.
const String _fixture = 'test/fixtures/clinic_saas_snapshot_v0_11.json';

void main() {
  final write = Platform.environment['CO_FAKER_WRITE_SNAPSHOT'] == '1';

  if (write) {
    test('writes the clinic and saas snapshot fixture', () {
      final locales = <String, Object?>{
        for (final locale in clinicSaasFullLocales) locale: _recordFull(locale),
      };
      final fallbacks = <String, Object?>{
        for (final locale in clinicSaasFallbackLocales)
          locale: _recordDigests(locale, clinicSaasFallbackSeed),
      };
      final fixture = <String, Object?>{
        'seeds': clinicSaasSeeds,
        'repeats': clinicSaasRepeats,
        'fallbackSeed': clinicSaasFallbackSeed,
        'locales': locales,
        'fallbacks': fallbacks,
      };
      File(_fixture)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(fixture)}\n',
        );
    });
    return;
  }

  final recorded =
      jsonDecode(File(_fixture).readAsStringSync()) as Map<String, Object?>;
  final locales = recorded['locales']! as Map<String, Object?>;
  final fallbacks = recorded['fallbacks']! as Map<String, Object?>;
  final callNames = <String>{...clinicCalls.keys, ...saasCalls.keys};

  test('the fixture covers every recorded call, seed, and locale code', () {
    expect(recorded['seeds'], clinicSaasSeeds);
    expect(recorded['repeats'], clinicSaasRepeats);
    expect(recorded['fallbackSeed'], clinicSaasFallbackSeed);
    expect(locales.keys, unorderedEquals(clinicSaasFullLocales));
    expect(fallbacks.keys, unorderedEquals(clinicSaasFallbackLocales));
    for (final locale in clinicSaasFullLocales) {
      final calls = locales[locale]! as Map<String, Object?>;
      expect(calls.keys, unorderedEquals(callNames), reason: locale);
      for (final entry in calls.values) {
        final digests = (entry! as Map<String, Object?>)['digests']! as List;
        expect(digests, hasLength(clinicSaasSeeds.length));
      }
    }
    for (final locale in clinicSaasFallbackLocales) {
      final calls = fallbacks[locale]! as Map<String, Object?>;
      expect(calls.keys, unorderedEquals(callNames), reason: locale);
    }
  });

  for (final locale in clinicSaasFullLocales) {
    final calls = locales[locale]! as Map<String, Object?>;
    for (var index = 0; index < clinicSaasSeeds.length; index++) {
      final seed = clinicSaasSeeds[index];
      test('$locale seed $seed keeps its 0.11.0 clinic and saas output', () {
        final actual = recordClinicSaas(locale, seed);
        final mismatches = <String>[];
        for (final name in callNames) {
          final entry = calls[name]! as Map<String, Object?>;
          final digest = (entry['digests']! as List)[index] as String;
          if (clinicSaasDigest(actual[name]!) != digest) {
            mismatches.add(
              '$name\n  recorded: ${entry['sample']}'
              '\n  actual:   ${clinicSaasSample(actual[name]!)}',
            );
          }
        }
        expect(mismatches, isEmpty, reason: mismatches.take(3).join('\n'));
      });
    }
  }

  // A fallback code keeps its output only while its language has no clinic or
  // SaaS data of its own. Once a language is localized (the registries say
  // which: `domainLocalized`), every code of it reads the language data
  // instead of the English or Korean data that the fixture recorded, on
  // purpose (see the CHANGELOG): `ja` and `ja_JP` change together, while
  // `zh_TW` (Traditional Chinese), `es`, and `xx_YY` read English for good and
  // keep their digests. Both data sets are left out together, because the
  // calls of one read the other: a SaaS tenant is named by the clinic data,
  // and a clinic reads the SaaS labels.
  for (final locale in clinicSaasFallbackLocales) {
    if (domainLocalized(locale)) continue;
    test('$locale keeps its 0.11.0 clinic and saas output', () {
      final calls = fallbacks[locale]! as Map<String, Object?>;
      final actual = recordClinicSaas(locale, clinicSaasFallbackSeed);
      final mismatches = <String>[
        for (final name in callNames)
          if (clinicSaasDigest(actual[name]!) != calls[name]) name,
      ];
      expect(mismatches, isEmpty, reason: mismatches.join(', '));
    });
  }

  test('a code that is left out reads the data of its language', () {
    // The left-out codes are no longer fallbacks: they read the clinic and
    // SaaS data that their language registered, so the digests of the fixture
    // no longer apply to them.
    for (final locale in clinicSaasFallbackLocales.where(domainLocalized)) {
      final language = CoFakerLanguages.resolve(locale).language.code;
      final entry = CoL10nClinic.entries[language]!;
      final faker = CoFaker(locale: locale, seed: 1);
      expect(
        faker.clinic.data,
        same(entry.clinic ?? CoFakerClinicData.english),
        reason: locale,
      );
      expect(
        faker.saas.data,
        same(entry.saas ?? CoFakerSaasData.english),
        reason: locale,
      );
    }
  });
}

Map<String, Object?> _recordFull(String locale) {
  final perSeed = <int, Map<String, String>>{
    for (final seed in clinicSaasSeeds) seed: recordClinicSaas(locale, seed),
  };
  final first = perSeed[clinicSaasSeeds.first]!;
  return <String, Object?>{
    for (final name in first.keys)
      name: <String, Object?>{
        'digests': <String>[
          for (final seed in clinicSaasSeeds)
            clinicSaasDigest(perSeed[seed]![name]!),
        ],
        'sample': clinicSaasSample(first[name]!),
      },
  };
}

Map<String, String> _recordDigests(String locale, int seed) {
  return <String, String>{
    for (final entry in recordClinicSaas(locale, seed).entries)
      entry.key: clinicSaasDigest(entry.value),
  };
}
