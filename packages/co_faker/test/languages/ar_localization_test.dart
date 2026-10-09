import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/ar.dart';

/// What is particular to the Arabic data: that it is the translation of the
/// English records (the same seed picks the counterpart of the same record),
/// that every way in reads the same data, the writing, the fictional markers,
/// and the currency of Saudi Arabia.

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
final CoL10nBundle _xx = CoL10nRegistry.bundleFor('ar')!;
final CoFakerClinicData _xxClinic = CoL10nClinic.clinicOf('ar')!;
final CoFakerSaasData _xxSaas = CoL10nClinic.saasOf('ar')!;

/// Every text of the Arabic data, with where it is and how the gate judges it.
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

/// The same index of two lists: the Arabic counterpart of [english].
T _counterpart<T>(List<T> translated, List<T> english, T value) {
  final index = english.indexOf(value);
  expect(index, isNonNegative, reason: 'English has no $value');
  return translated[index];
}

/// A text of English, the Arabic text that translates it, and the key: the same
/// position in both languages is what makes one seed pick the same record.
const List<(String, String, String)> _anchors = <(String, String, String)>[
  ('fx.currencyName.USD', 'US dollar', 'الدولار الأمريكي'),
  ('fx.currencyName.NPR', 'Nepalese rupee', 'الروبية النيبالية'),
  ('vet.petName', 'Butterfly', 'فراشة'),
  ('vet.petName', 'Cloud', 'غيمة'),
  ('dental.dentalProcedure', 'Scaling', 'تنظيف الجير'),
];

final RegExp _hangul = RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]');

void main() {
  group('the entry points of Arabic', () {
    final ways = <String, CoFaker Function()>{
      "forLanguage('ar')": () => _faker('ar', 7),
      "forLanguage('ar-SA')": () => _faker('ar-SA', 7),
      "forLanguage('ar_SA.UTF-8')": () => _faker('ar_SA.UTF-8', 7),
      "forLanguage('ar-EG')": () => _faker('ar-EG', 7),
      "locale: 'ar'": () => _locale('ar', 7),
      "locale: 'ar_SA'": () => _locale('ar_SA', 7),
      "locale: 'ar-sa'": () => _locale('ar-sa', 7),
      "locale: 'AR'": () => _locale('AR', 7),
    };

    test('read the Arabic bundle and the registered clinic and SaaS data', () {
      for (final entry in ways.entries) {
        final f = entry.value();
        expect(f.language, 'ar', reason: entry.key);
        expect(f.l10n.language, 'ar', reason: entry.key);
        expect(f.clinic.data, same(_xxClinic), reason: entry.key);
        expect(f.saas.data, same(_xxSaas), reason: entry.key);
        for (final key in _xx.texts.keys) {
          expect(f.l10n.list(key), _xx.texts[key], reason: '${entry.key} $key');
        }
      }
    });

    test('are the Arabic data and not the English one', () {
      final f = _faker('ar', 7);
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
        final xx = _faker('ar', seed);
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
        final xx = _faker('ar', seed);
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
          expect(text, contains(arSafety.fictionalMarker), reason: key);
        }
      }
      for (final key in <String>[
        'brokerage.qnaAnswerGeneric',
        'brokerage.consultNoteGeneric',
      ]) {
        for (final text in _xx.texts[key]!) {
          expect(text, startsWith(arSafety.generalInfoPrefix), reason: key);
        }
      }
    });
  });

  group('the writing is Arabic', () {
    final arabicLetter = RegExp(r'[؀-ۿݐ-ݿ]');
    final easternDigit = RegExp(r'[٠-٩۰-۹]');

    test('has Arabic letters in its texts, and no Hangul', () {
      var prose = 0;
      var arabic = 0;
      for (final item in _texts) {
        expect(_hangul.hasMatch(item.text), isFalse, reason: item.where);
        if (item.kind != CoTextKind.text) continue;
        final words = item.text.replaceAll(RegExp(r'#?\{[^{}]*\}'), '');
        if (!RegExp(r'\p{L}', unicode: true).hasMatch(words)) continue;
        prose++;
        if (arabicLetter.hasMatch(words)) arabic++;
      }
      expect(arabic / prose, greaterThanOrEqualTo(0.95));
    });

    test('keeps the digits 0 to 9', () {
      for (final item in _texts) {
        expect(easternDigit.hasMatch(item.text), isFalse, reason: item.where);
      }
      final f = _faker('ar', 7);
      for (var i = 0; i < 20; i++) {
        expect(easternDigit.hasMatch(f.internet.phoneNumber()), isFalse);
        expect(easternDigit.hasMatch(f.address.fullAddress()), isFalse);
      }
    });

    test('writes the Arabic question mark and comma', () {
      for (final item in _texts) {
        if (!arabicLetter.hasMatch(item.text)) continue;
        expect(item.text.contains('?'), isFalse, reason: item.where);
      }
    });
  });

  group('the currency', () {
    test(
      'writes the clinic and SaaS amounts in the currency of Saudi Arabia',
      () {
        final f = _faker('ar', 7);
        expect(f.clinic.money(1234), '1,234.00\u00A0ر.س');
        expect(f.saas.money(1234), contains('ر.س'));
        expect(_xxClinic.koreanValues, CoKoreanValues.none);
        expect(_xxSaas.koreanValues, CoKoreanValues.none);
      },
    );
  });

  group('the language is finished', () {
    test('is localized and passes the completion gate', () {
      final data = CoLanguageData.registered('ar');
      expect(data.level, CoLanguageLevel.localized);
      final report = CoLanguageCoverage().check(data);
      expect(report.issues, isEmpty, reason: report.toMarkdown());
    });
  });
}
