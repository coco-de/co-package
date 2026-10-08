import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import 'support/language_doc.dart';

/// Every text of a language that the glossary governs: the domain text
/// bundle, the clinic data, and the SaaS data.
List<({String where, String text})> _textsOf(CoLanguageData data) {
  final tables = <CoTextTable>[
    CoLanguageTexts.ofBundle(data.bundle),
    if (data.clinic != null) CoLanguageTexts.ofClinic(data.clinic!),
    if (data.saas != null) CoLanguageTexts.ofSaas(data.saas!),
  ];
  return <({String where, String text})>[
    for (final table in tables)
      for (final slot in table.slots.values)
        if (slot.kind == CoTextKind.text || slot.kind == CoTextKind.format)
          for (final row in slot.rows)
            for (final text in slot.cellsOf(row)!)
              (where: '${slot.name}[$row]', text: text),
  ];
}

const String _valid = '''
# Example (`xx`)

status: localized

## Glossary

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Patient | 患者 | 患者さん; 病人 | The notice register. |
| Appointment | 予約 | - | The usual word. |

## Format conventions

| Topic | Convention |
| --- | --- |
| Amounts | ¥1,234 |
''';

void main() {
  final directory = Directory('docs/languages');

  // The languages that the registries list, except Korean and English, which
  // are not localized by a Story: each has a file, and the file tells the
  // truth about the registries.
  final languages = <String>[
    for (final code in CoL10nRegistry.bundles.keys)
      if (code != 'ko' && code != 'en') code,
  ];

  group('the language files', () {
    test('are a README and one file for each language that is localized', () {
      expect(File('docs/languages/README.md').existsSync(), isTrue);
      final known = <String>{
        'README.md',
        for (final language in CoFakerLanguages.all)
          if (language.code != 'ko' && language.code != 'en')
            '${language.code}.md',
      };
      final files = <String>{
        for (final entity in directory.listSync())
          if (entity is File) entity.uri.pathSegments.last,
      };
      expect(files.difference(known), isEmpty, reason: 'unknown language file');
      for (final code in languages) {
        expect(files, contains('$code.md'), reason: 'a file for $code');
      }
    });

    for (final code in languages) {
      group(code, () {
        final path = 'docs/languages/$code.md';
        final doc = parseLanguageDoc(File(path).readAsStringSync());
        final data = CoLanguageData.registered(code);

        test('has a valid format', () {
          expect(doc.errors, isEmpty, reason: '$path: ${doc.errors}');
          expect(
            doc.status,
            anyOf('planned', 'localized'),
            reason: '$path: status is `planned` or `localized`',
          );
        });

        test('tells the truth about the registries', () {
          // `localized` only when the bundle, the clinic data, and the SaaS
          // data are all written, and `planned` only when none is.
          final level = data.level;
          expect(
            doc.status == 'localized'
                ? level == CoLanguageLevel.localized
                : level == CoLanguageLevel.planned,
            isTrue,
            reason:
                '$path says `${doc.status}`, but the registries say the '
                'language is `${level.name}`: set the status line to '
                '`localized` in the pull request that writes the bundle, the '
                'clinic data, and the SaaS data, all three',
          );
        });

        test('has a glossary that is consistent', () {
          expect(glossaryProblems(doc), isEmpty, reason: path);
          if (doc.status == 'localized') {
            expect(
              doc.glossary,
              isNotEmpty,
              reason: '$path: a localized language has a glossary',
            );
          }
        });

        test('has no forbidden form in its texts', () {
          final found = forbiddenInTexts(doc, _textsOf(data));
          expect(
            found,
            isEmpty,
            reason: '$path:\n${found.take(10).join('\n')}',
          );
        });
      });
    }
  });

  group('the format', () {
    test('reads the status line and the glossary', () {
      final doc = parseLanguageDoc(_valid);
      expect(doc.errors, isEmpty);
      expect(doc.status, 'localized');
      expect(doc.glossary, hasLength(2));
      final patient = doc.glossary.first;
      expect(patient.source, 'Patient');
      expect(patient.translation, '患者');
      expect(patient.forbidden, ['患者さん', '病人']);
      expect(patient.rationale, 'The notice register.');
      expect(doc.glossary.last.forbidden, isEmpty);
      expect(glossaryProblems(doc), isEmpty);
    });

    test('rejects a file without a status line, or with two', () {
      expect(
        parseLanguageDoc(_valid.replaceFirst('status: localized\n', '')).errors,
        contains(contains('exactly one "status:" line, found 0')),
      );
      expect(
        parseLanguageDoc('$_valid\nstatus: planned\n').errors,
        contains(contains('found 2')),
      );
    });

    test('rejects a file without the glossary table or its delimiter', () {
      final none = parseLanguageDoc('status: planned\n\n## Glossary\n');
      expect(none.errors.single, contains('exactly one glossary table'));
      final other = parseLanguageDoc(
        _valid.replaceFirst('Rationale |', 'Reason |'),
      );
      expect(other.errors, contains(contains('exactly one glossary table')));
      final delimiter = parseLanguageDoc(
        _valid.replaceFirst('| --- | --- | --- | --- |', '| - | - |'),
      );
      expect(delimiter.errors.single, contains('delimiter row'));
    });

    test('rejects a row that is not four cells or has an empty cell', () {
      final cells = parseLanguageDoc(
        _valid.replaceFirst(
          '| Appointment | 予約 | - | The usual word. |',
          '| Appointment | 予約 | The usual word. |',
        ),
      );
      expect(cells.errors.single, contains('exactly four cells'));
      final empty = parseLanguageDoc(
        _valid.replaceFirst('| Patient | 患者 |', '| Patient |  |'),
      );
      expect(empty.errors.single, contains('the translation is empty'));
      final noReason = parseLanguageDoc(
        _valid.replaceFirst('| The usual word. |', '|  |'),
      );
      expect(noReason.errors.single, contains('the rationale is empty'));
    });

    test('allows a pipe inside a cell when it is escaped', () {
      final doc = parseLanguageDoc(
        _valid.replaceFirst('| The usual word. |', r'| a \| b |'),
      );
      expect(doc.errors, isEmpty);
      expect(doc.glossary.last.rationale, 'a | b');
    });
  });

  group('the glossary checks', () {
    test('reject a term that has two rows', () {
      final doc = parseLanguageDoc(
        _valid.replaceFirst(
          '| Appointment | 予約 | - | The usual word. |',
          '| Patient | 患者様 | - | Another way. |',
        ),
      );
      final problems = glossaryProblems(doc);
      expect(problems, hasLength(1));
      expect(problems.single, contains('"Patient" is already the term'));
      expect(problems.single, contains('"患者" and "患者様"'));
    });

    test('reject a forbidden form that the texts could not avoid', () {
      final own = parseLanguageDoc(_valid.replaceFirst('患者さん; 病人', '患者'));
      expect(
        glossaryProblems(own).single,
        contains('inside the translation "患者" of its own row'),
      );
      final other = parseLanguageDoc(_valid.replaceFirst('患者さん; 病人', '予約'));
      expect(
        glossaryProblems(other).single,
        contains('translation "予約" of the term "Appointment"'),
      );
    });

    test('find a forbidden form in the texts, whatever its case', () {
      final doc = parseLanguageDoc(_valid.replaceFirst('病人', 'Klient'));
      final found = forbiddenInTexts(doc, <({String where, String text})>[
        (where: 'fx.tierName[0]', text: '患者さん が来ました'),
        (where: 'fx.tierName[1]', text: 'Ein  klient wartet'),
        (where: 'fx.tierName[2]', text: '患者が来ました'),
      ]);
      expect(found, hasLength(2));
      expect(found.first, contains('"患者さん" of the term "Patient"'));
      expect(found.first, contains('fx.tierName[0]'));
      expect(found.last, contains('fx.tierName[1]'));
    });

    test('read the clinic, the SaaS data, and the bundle of a language', () {
      final data = CoLanguageData.registered('ko');
      final texts = _textsOf(data);
      expect(
        texts.map((text) => text.where.split('.').first).toSet(),
        containsAll(<String>['dental', 'clinic', 'saas']),
      );
      expect(texts.length, greaterThan(1500));
    });
  });
}
