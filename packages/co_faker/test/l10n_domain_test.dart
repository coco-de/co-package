import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

CoFaker _faker(
  String locale, {
  int seed = 436,
  Map<String, CoFakerLocale> locales = const <String, CoFakerLocale>{},
}) => CoFaker(
  locale: locale,
  seed: seed,
  now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
  locales: locales,
);

/// The primitive type a role is generated with.
String _typeOf(CoDomainRole role) => role.supportedTypes?.first ?? 'String';

/// Every role of every pack for the first [records] records, by qualified name.
Map<String, List<Object?>> _roles(CoFaker f, {int records = 3}) {
  return {
    for (final pack in CoFakerDomains.all)
      for (final entry in pack.roles.entries)
        '${pack.name}.${entry.key}': [
          for (var i = 0; i < records; i++)
            f.schema.record(
              {'value': _typeOf(entry.value)},
              roles: {'value': '${pack.name}.${entry.key}'},
              streamKey: '${pack.name}.${entry.key}',
              index: i,
            )['value'],
        ],
  };
}

/// The English bundle with every text marked, to tell whose text answers.
CoL10nBundle _marked(String mark) => CoL10nBundle(
  language: 'xx',
  texts: {
    for (final entry in CoL10nRegistry.english.texts.entries)
      entry.key: [for (final text in entry.value) '$mark$text'],
  },
);

/// A custom locale that adds [bundle] to a built-in locale.
Map<String, CoFakerLocale> _withBundle(
  String code,
  CoFakerLocale builtin,
  CoL10nBundle bundle,
) => {code: CoFakerLocale(code: code, l10n: bundle).merge(builtin)};

Iterable<File> _sources({bool includeBundles = false}) => Directory('lib/src')
    .listSync(recursive: true)
    .whereType<File>()
    .where(
      (file) =>
          file.path.endsWith('.dart') &&
          (includeBundles || !file.path.contains('/l10n/')),
    );

void main() {
  final english = CoL10nRegistry.english;

  group('the authored domain code', () {
    test('has no hard-coded Korean or English branch', () {
      final branch = RegExp(r'''startsWith\(\s*['"]ko|\blocalized\(''');
      final files = [
        ..._sources().where(
          (file) =>
              file.path.contains('/domain_packs/') ||
              file.path.endsWith('/domains.dart'),
        ),
      ];
      expect(files, isNotEmpty);
      for (final file in files) {
        expect(
          branch.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    });

    test('uses every English key, and only keys that exist', () {
      final sources = [
        for (final file in _sources()) file.readAsStringSync(),
      ].join('\n');
      final exact = {
        for (final match in RegExp(
          r"'([a-z][a-z0-9_]*(?:\.[A-Za-z0-9_]+)+)'",
        ).allMatches(sources))
          match.group(1)!,
      };
      final families = {
        for (final match in RegExp(
          r"'([a-z][a-z0-9_]*(?:\.[A-Za-z0-9_]+)*\.)\$",
        ).allMatches(sources))
          match.group(1)!,
      };
      for (final key in english.texts.keys) {
        expect(
          exact.contains(key) || families.any(key.startsWith),
          isTrue,
          reason: 'no pack or generator reads "$key"',
        );
      }

      const reader =
          r'(?:textRole|taxonomyRole|indexedTextRole|l10n\s*\.\s*'
          r'(?:list|pick|pickBalanced|text|format))\(\s*';
      for (final match in RegExp("$reader'([^'\$]+)'").allMatches(sources)) {
        expect(
          english.texts.containsKey(match.group(1)),
          isTrue,
          reason: 'unknown key "${match.group(1)}"',
        );
      }
      for (final match in RegExp("$reader'([^']*)\\\$").allMatches(sources)) {
        final prefix = match.group(1)!;
        expect(
          english.texts.keys.any((key) => key.startsWith(prefix)),
          isTrue,
          reason: 'no key starts with "$prefix"',
        );
      }
    });
  });

  group('every role', () {
    test('generates text without a leftover placeholder in every language', () {
      final placeholder = RegExp(r'\{[A-Za-z_]\w*\}');
      final codes = <String>[
        for (final language in CoFakerLanguages.all) ...[
          language.code,
          language.locale,
        ],
        'zh_TW',
        'zh-Hant',
        'xx_YY',
      ];
      for (final code in codes) {
        _roles(_faker(code), records: 2).forEach((role, values) {
          for (final value in values) {
            if (value is! String) continue;
            expect(value, isNotEmpty, reason: '$code $role');
            expect(value, isNot(matches(placeholder)), reason: '$code $role');
          }
        });
      }
    });

    test('is the same text, record by record, for a regional code', () {
      final korean = _roles(_faker('ko'));
      for (final code in ['ko_KR', 'ko-KR', 'KO_kr']) {
        expect(_roles(_faker(code)), korean, reason: code);
      }
      final englishRoles = _roles(_faker('en'));
      for (final code in ['en_AU', 'en_NZ', 'xx_YY', 'xx']) {
        expect(_roles(_faker(code)), englishRoles, reason: code);
      }
    });

    test('is the English record for Traditional Chinese', () {
      // The basic modules keep their data, but the domain text is English's:
      // Traditional readers are never handed Simplified text.
      const keys = [
        'dental.dentalProcedure',
        'workplace.position',
        'logistics.zoneName',
        'fx.couponName',
        'content.seriesTitle',
        'brokerage.providerName',
      ];
      final englishRoles = _roles(_faker('en'));
      for (final code in ['zh_TW', 'zh-TW', 'zh_HK', 'zh_MO', 'zh-Hant']) {
        final roles = _roles(_faker(code));
        for (final key in keys) {
          expect(roles[key], englishRoles[key], reason: '$code $key');
        }
      }
    });

    test('differs between Korean and English only by language', () {
      // The same seed picks the same entry of a key in both languages.
      final ko = _roles(_faker('ko'), records: 4);
      final en = _roles(_faker('en'), records: 4);
      final korean = CoL10nRegistry.bundleFor('ko')!;
      var compared = 0;
      for (final key in english.texts.keys) {
        final enValues = en[key];
        final koValues = ko[key];
        if (enValues == null || koValues == null) continue;
        final enTexts = english.texts[key]!;
        final koTexts = korean.texts[key]!;
        for (var i = 0; i < enValues.length; i++) {
          final enIndex = enTexts.indexOf(enValues[i] as String? ?? '');
          if (enIndex < 0) continue;
          final koIndex = koTexts.indexOf(koValues[i] as String? ?? '');
          expect(koIndex >= 0, isTrue, reason: '$key $i');
          if (enTexts.where((text) => text == enTexts[enIndex]).length == 1) {
            expect(koIndex, enIndex, reason: '$key $i');
            compared++;
          }
        }
      }
      expect(compared, greaterThan(500));
    });
  });

  group('a custom locale injects domain text into', () {
    final marked = _marked('ES:');
    final locales = _withBundle('en', CoFakerLocales.english, marked);

    test('every role that reads a key of its own', () {
      final plain = _roles(_faker('en'), records: 4);
      final custom = _roles(_faker('en', locales: locales), records: 4);
      var injected = 0;
      for (final key in english.texts.keys) {
        final values = plain[key];
        if (values == null) continue;
        final texts = english.texts[key]!;
        for (var i = 0; i < values.length; i++) {
          // Pick and taxonomy-root roles return a text of their list as is.
          if (values[i] is! String || !texts.contains(values[i])) continue;
          expect(custom[key]![i], 'ES:${values[i]}', reason: '$key $i');
          injected++;
        }
      }
      expect(injected, greaterThan(500));
    });

    test('the templates of the shared and the daycare roles', () {
      final f = _faker('en', locales: locales);
      final plain = _faker('en');
      final guardian = f.schema.record(
        {'value': 'String'},
        roles: {'value': 'daycare.guardianLabel'},
      )['value'];
      expect(
        guardian,
        'ES:${plain.schema.record({'value': 'String'}, roles: {'value': 'daycare.guardianLabel'})['value']}',
      );
      final taxonomy = f.schema.entities('grocery.produce_category', 9);
      expect(
        taxonomy.skip(7).map((row) => row['name']),
        everyElement(startsWith('ES:ES:')),
      );
    });

    test('the dedicated generators', () {
      final f = _faker('en', locales: locales);
      expect(f.fx.currency(code: 'JPY').name, 'ES:Japanese yen');
      final recipient = f.remit.recipient(countryCode: 'VN');
      expect(recipient.countryName, 'ES:Vietnam');
      expect(recipient.bankName, 'ES:Nuri partner bank (fictional)');
      expect(f.vet.breeds('dog'), ['ES:Maltese', 'ES:Poodle', 'ES:Mixed dog']);
      final pet = f.vet.pet(animalKind: 'cat');
      expect(f.vet.breeds('cat'), contains(pet.breed));
      expect(pet.name, startsWith('ES:'));
      expect(pet.coatColor, startsWith('ES:'));
      final item = f.catalog.item(grocery: true, index: 0);
      expect(item.name, 'ES:Strawberries');
      expect(item.unitLabel, 'ES:500g');
      final question = f.examPrep.question(index: 3);
      expect(question.subjectName, 'ES:Networking');
      expect(question.unitName, 'ES:Routing');
      expect(question.choices, everyElement(startsWith('ES:')));
      expect(question.choices[question.answerKeys.single - 1], 'ES:Router');
      expect(
        CoFakerHelpdesk(f).drafts().map((draft) => draft['templateBody']),
        everyElement(startsWith('ES:')),
      );
    });

    test('and a template chooses which names a masked name draws', () {
      const bundle = CoL10nBundle(
        language: 'xx',
        texts: {
          'common.maskedName': ['{lastName}-{firstName}'],
        },
      );
      final custom = _faker(
        'en',
        locales: _withBundle('en', CoFakerLocales.english, bundle),
      );
      final value = custom.schema.record(
        {'name': 'String'},
        roles: {'name': 'homecare.recipientName'},
      )['name'];
      // The names are drawn in the order the template names them.
      final stream = _faker('en').derive('schema/0/name');
      expect(value, '${stream.person.lastName()}-${stream.person.firstName()}');
    });

    test('and the shipped Korean text answers where it has no bundle', () {
      // A partial custom bundle for Korean translates only its keys.
      final f = _faker(
        'ko',
        locales: _withBundle(
          'ko',
          CoFakerLocales.korean,
          const CoL10nBundle(
            language: 'ko',
            texts: {
              'fx.currencyName.USD': ['달러'],
            },
          ),
        ),
      );
      expect(f.fx.currency(code: 'USD').name, '달러');
      expect(f.fx.currency(code: 'JPY').name, '일본 엔');
    });
  });
}
