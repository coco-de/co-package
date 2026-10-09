import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/es.dart';

/// What is particular to the Spanish data: that it is the translation of the
/// English records (the same seed picks the counterpart of the same record),
/// that every way in reads the same data, the writing, the fictional markers,
/// and the currency of Spain.

/// The seeds the alignment checks run with.
const List<int> _seeds = <int>[7, 436, 20261005];

final DateTime _now = DateTime.utc(2026, 10, 8, 9);

CoFaker _faker(String tag, int seed) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

CoFaker _locale(String code, int seed) =>
    CoFaker(locale: code, seed: seed, now: _now, domains: CoFakerDomains.all);

String _role(CoFaker f, String key, int index) =>
    f.schema.record(
          <String, String>{'value': 'String'},
          roles: <String, String>{'value': key},
          streamKey: key,
          index: index,
        )['value']
        as String;

final CoL10nBundle _en = CoL10nRegistry.english;
final CoL10nBundle _xx = CoL10nRegistry.bundleFor('es')!;
final CoFakerClinicData _xxClinic = CoL10nClinic.clinicOf('es')!;
final CoFakerSaasData _xxSaas = CoL10nClinic.saasOf('es')!;

/// Every text of the Spanish data, with where it is and how the gate judges it.
final List<({String where, String text, CoTextKind kind})> _texts =
    <({String where, String text, CoTextKind kind})>[
      for (final table in <CoTextTable>[
        CoLanguageTexts.ofBundle(_xx),
        CoLanguageTexts.ofClinic(_xxClinic),
        CoLanguageTexts.ofSaas(_xxSaas),
      ])
        for (final slot in table.slots.values)
          for (final row in slot.rows)
            for (final text in slot.cellsOf(row)!)
              (where: '${slot.name}[$row]', text: text, kind: slot.kind),
    ];

/// The same index of two lists: the Spanish counterpart of [english].
T _counterpart<T>(List<T> translated, List<T> english, T value) {
  final index = english.indexOf(value);
  expect(index, isNonNegative, reason: 'English has no $value');
  return translated[index];
}

/// A text of English, the Spanish text that translates it, and the key: the same
/// position in both languages is what makes one seed pick the same record.
const List<(String, String, String)> _anchors = <(String, String, String)>[
  ('fx.currencyName.USD', 'US dollar', 'Dólar estadounidense'),
  ('fx.currencyName.NPR', 'Nepalese rupee', 'Rupia nepalí'),
  ('vet.petName', 'Butterfly', 'Mariposa'),
  ('vet.petName', 'Cloud', 'Nube'),
  ('dental.dentalProcedure', 'Scaling', 'Limpieza dental'),
];

final RegExp _hangul = RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]');

void main() {
  group('the entry points of Spanish', () {
    final ways = <String, CoFaker Function()>{
      "forLanguage('es')": () => _faker('es', 7),
      "forLanguage('es-ES')": () => _faker('es-ES', 7),
      "forLanguage('es_ES.UTF-8')": () => _faker('es_ES.UTF-8', 7),
      "forLanguage('es-MX')": () => _faker('es-MX', 7),
      "locale: 'es'": () => _locale('es', 7),
      "locale: 'es_ES'": () => _locale('es_ES', 7),
      "locale: 'es-es'": () => _locale('es-es', 7),
      "locale: 'ES'": () => _locale('ES', 7),
    };

    test('read the Spanish bundle and the registered clinic and SaaS data', () {
      for (final entry in ways.entries) {
        final f = entry.value();
        expect(f.language, 'es', reason: entry.key);
        expect(f.l10n.language, 'es', reason: entry.key);
        expect(f.clinic.data, same(_xxClinic), reason: entry.key);
        expect(f.saas.data, same(_xxSaas), reason: entry.key);
        for (final key in _xx.texts.keys) {
          expect(f.l10n.list(key), _xx.texts[key], reason: '${entry.key} $key');
        }
      }
    });

    test('are the Spanish data and not the English one', () {
      final f = _faker('es', 7);
      expect(f.clinic.data, isNot(same(CoFakerClinicData.english)));
      expect(f.saas.data, isNot(same(CoFakerSaasData.english)));
      expect(
        _en.texts['dental.dentalProcedure'],
        isNot(contains(_role(f, 'dental.dentalProcedure', 0))),
      );
      // A language that has no data, and never will, keeps the English one.
      final other = _locale('nl', 7);
      expect(other.clinic.data, same(CoFakerClinicData.english));
    });
  });

  group('the bundle is the translation of the English one', () {
    test('has every key, with as many texts', () {
      expect(_xx.texts.keys.toSet(), _en.texts.keys.toSet());
      for (final entry in _en.texts.entries) {
        expect(
          _xx.texts[entry.key],
          hasLength(entry.value.length),
          reason: entry.key,
        );
      }
    });

    test('writes the translation of a text at the position of that text', () {
      for (final (key, english, translated) in _anchors) {
        final position = _en.texts[key]!.indexOf(english);
        expect(position, isNonNegative, reason: '$key has no "$english"');
        expect(_xx.texts[key]![position], translated, reason: key);
      }
    });

    test('picks the translation of the English record, from the same seed', () {
      final keys = <String>{};
      for (final seed in _seeds) {
        final en = _faker('en', seed);
        final xx = _faker('es', seed);
        for (final pack in CoFakerDomains.all) {
          for (final role in pack.roles.keys) {
            final key = '${pack.name}.$role';
            final english = _en.texts[key];
            if (english == null || english.any((text) => text.contains('{'))) {
              continue;
            }
            for (var i = 0; i < 12; i++) {
              final enText = _role(en, key, i);
              final rows = <int>[
                for (var row = 0; row < english.length; row++)
                  if (english[row] == enText) row,
              ];
              if (rows.isEmpty) continue;
              expect(
                _role(xx, key, i),
                isIn(<String>[for (final row in rows) _xx.texts[key]![row]]),
                reason: '$key #$i with seed $seed',
              );
            }
            keys.add(key);
          }
        }
      }
      expect(keys.length, greaterThan(150));
    });

    test('is the same record in the dedicated generators', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed);
        final xx = _faker('es', seed);
        for (var i = 0; i < 12; i++) {
          final enPet = en.vet.pet();
          final xxPet = xx.vet.pet();
          expect(xxPet.animalKind, enPet.animalKind);
          expect(xxPet.weightKg, enPet.weightKg);
          expect(
            xxPet.name,
            _counterpart(
              _xx.texts['vet.petName']!,
              _en.texts['vet.petName']!,
              enPet.name,
            ),
          );
        }
        for (var i = 0; i < 9; i++) {
          final enQuestion = en.examPrep.question(index: i);
          final xxQuestion = xx.examPrep.question(index: i);
          final row = _en.texts['exam_prep.questionStem']!.indexOf(
            enQuestion.stem,
          );
          final correct = _xx.texts['exam_prep.correctChoice']![row];
          expect(xxQuestion.stem, _xx.texts['exam_prep.questionStem']![row]);
          expect(xxQuestion.answerKeys, enQuestion.answerKeys);
          expect(xxQuestion.choices[xxQuestion.answerKeys.single - 1], correct);
          expect(xxQuestion.explanation, contains(correct));
          expect(xxQuestion.choices.toSet(), hasLength(4));
        }
      }
    });

    test('names two creators of its own, never the Korean ones', () {
      final creators = _xx.texts['fandom.creatorName']!;
      expect(creators, hasLength(2));
      for (final text in creators) {
        expect(_hangul.hasMatch(text), isFalse);
      }
    });
  });

  group('the fictional markers', () {
    test('mark every drug and product, and open every general answer', () {
      for (final key in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
      ]) {
        for (final text in _xx.texts[key]!) {
          expect(text, contains(esSafety.fictionalMarker), reason: key);
        }
      }
      for (final key in <String>[
        'brokerage.qnaAnswerGeneric',
        'brokerage.consultNoteGeneric',
      ]) {
        for (final text in _xx.texts[key]!) {
          expect(text, startsWith(esSafety.generalInfoPrefix), reason: key);
        }
      }
    });
  });

  group('the writing is Spanish', () {
    test('opens every question and exclamation it closes', () {
      for (final item in _texts) {
        final text = item.text;
        expect(
          '¿'.allMatches(text).length,
          '?'.allMatches(text).length,
          reason: '${item.where}: $text',
        );
        expect(
          '¡'.allMatches(text).length,
          '!'.allMatches(text).length,
          reason: '${item.where}: $text',
        );
      }
    });

    test('writes a no-break space between a number and its unit', () {
      final glued = RegExp(
        r'\d (ml|mg|kg|g|cm|km|min|h|%|€)(?![\p{L}])',
        unicode: true,
      );
      for (final item in _texts) {
        expect(glued.hasMatch(item.text), isFalse, reason: item.where);
      }
    });

    test('uses the Peninsular words of the glossary', () {
      final american = RegExp(
        r'\b(computadora|celular|jugo|estacionamiento|agendar)\b',
        caseSensitive: false,
      );
      for (final item in _texts) {
        expect(american.hasMatch(item.text), isFalse, reason: item.where);
      }
    });
  });

  group('the currency', () {
    test('writes the clinic and SaaS amounts in the currency of Spain', () {
      final f = _faker('es', 7);
      expect(f.clinic.money(1234), '1.234,00\u00A0€');
      expect(f.saas.money(1234), contains('€'));
      expect(_xxClinic.koreanValues, CoKoreanValues.none);
      expect(_xxSaas.koreanValues, CoKoreanValues.none);
    });
  });

  group('the language is finished', () {
    test('is localized and passes the completion gate', () {
      final data = CoLanguageData.registered('es');
      expect(data.level, CoLanguageLevel.localized);
      final report = CoLanguageCoverage().check(data);
      expect(report.issues, isEmpty, reason: report.toMarkdown());
    });
  });
}
