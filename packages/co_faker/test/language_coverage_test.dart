import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/language_coverage/co_language_calls.dart';
import 'package:co_faker/src/language_coverage/co_language_generation.dart';
import 'package:co_faker/src/language_coverage/co_language_text_scan.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import 'support/class_members.dart';
import 'support/sample_language.dart';

/// Where each generator that the calls exercise is declared.
const Map<String, (String, String)>
_generatorSources = <String, (String, String)>{
  'clinic': ('lib/src/clinic.dart', 'CoFakerClinic'),
  'saas': ('lib/src/saas.dart', 'CoFakerSaas'),
  'fx': ('lib/src/domain_packs/co_faker_fx.dart', 'CoFakerFx'),
  'remit': ('lib/src/domain_packs/co_faker_remit.dart', 'CoFakerRemit'),
  'vet': ('lib/src/domain_packs/co_faker_vet.dart', 'CoFakerVet'),
  'booking': ('lib/src/domain_packs/co_faker_booking.dart', 'CoFakerBooking'),
  'catalog': ('lib/src/domain_packs/co_faker_catalog.dart', 'CoFakerCatalog'),
  'examPrep': (
    'lib/src/domain_packs/co_faker_exam_prep.dart',
    'CoFakerExamPrep',
  ),
  'helpdesk': (
    'lib/src/domain_packs/co_faker_helpdesk.dart',
    'CoFakerHelpdesk',
  ),
};

/// The public members that the class [className] declares in [path]:
/// methods, getters, and fields, static or not.
Set<String> _publicMembers(String path, String className) => <String>{
  for (final member in classMembers(File(path).readAsStringSync(), className))
    if (!member.name.startsWith('_')) member.name,
};

/// The instance fields of the class [className] in [path]: what a data class
/// holds.
Set<String> _instanceFields(String path, String className) => <String>{
  for (final member in classMembers(File(path).readAsStringSync(), className))
    if (member.isField && !member.isStatic && !member.name.startsWith('_'))
      member.name,
};

/// A bundle of [sample] with [change] applied to a copy of its texts.
CoL10nBundle _bundle(
  SampleLanguage sample,
  void Function(Map<String, List<String>> texts) change, {
  Map<String, List<String>> allow = const <String, List<String>>{},
}) {
  final texts = <String, List<String>>{
    for (final entry in sample.bundle().texts.entries)
      entry.key: <String>[...entry.value],
  };
  change(texts);
  return CoL10nBundle(
    language: sample.code,
    texts: texts,
    allowSameAsEnglish: allow,
  );
}

CoLanguageReport _data(CoLanguageData data) =>
    CoLanguageCoverage().check(data, generate: false);

/// The places of the issues of [check] in [report].
List<String> _where(CoLanguageReport report, CoLanguageCheck check) => <String>[
  for (final issue in report.issuesOf(check)) issue.where,
];

CoGenerationResult _generate(
  SampleLanguage sample,
  CoLanguageData data, {
  List<int> seeds = const <int>[7],
  int records = 4,
  bool strictProse = false,
}) => runGenerationChecks(
  language: sample.code,
  script: CoFakerLanguages.all
      .firstWhere((language) => language.code == sample.code)
      .script,
  faker: sample.faker(data),
  seeds: seeds,
  records: records,
  checkHangul: true,
  minScript: 0.9,
  strictProse: strictProse,
);

void main() {
  const ja = SampleLanguage('ja');
  const de = SampleLanguage('de');

  group('text scan', () {
    test('tells the writing systems apart', () {
      expect(CoTextScan.hasHangul('치과 clinic'), isTrue);
      expect(CoTextScan.hasHangul('ㅋㅋ'), isTrue);
      expect(CoTextScan.hasHangul('皮膚科 クリニック'), isFalse);
      expect(CoTextScan.hasScript('皮膚科', CoFakerScript.han), isTrue);
      expect(CoTextScan.hasScript('皮膚科', CoFakerScript.kana), isTrue);
      expect(CoTextScan.hasScript('クリニック', CoFakerScript.kana), isTrue);
      expect(CoTextScan.hasScript('クリニック', CoFakerScript.han), isFalse);
      expect(CoTextScan.hasScript('ひらがな', CoFakerScript.kana), isTrue);
      expect(CoTextScan.hasScript('Клиника', CoFakerScript.cyrillic), isTrue);
      expect(CoTextScan.hasScript('Clinic', CoFakerScript.cyrillic), isFalse);
      expect(CoTextScan.hasScript('치과', CoFakerScript.hangul), isTrue);
      expect(CoTextScan.hasScript('anything', CoFakerScript.latin), isTrue);
      expect(CoTextScan.requiresScript(CoFakerScript.latin), isFalse);
      expect(CoTextScan.requiresScript(CoFakerScript.han), isTrue);
    });

    test('finds the words that a translation has to write', () {
      expect(CoTextScan.hasLetters('{month}/{day}'), isFalse);
      expect(CoTextScan.hasLetters('***-**-####'), isFalse);
      expect(CoTextScan.hasLetters('12:00'), isFalse);
      expect(CoTextScan.hasLetters(r'#{name} → #{date}'), isFalse);
      expect(CoTextScan.hasLetters('{n}x'), isTrue);
      expect(CoTextScan.hasLetters('Sprint {n}'), isTrue);
      expect(CoTextScan.hasLetters('{n}가●●{m}'), isTrue);
    });

    test('reads placeholders and the variables of a template', () {
      expect(CoTextScan.placeholders('{a} and {b_1}'), {'a', 'b_1'});
      expect(CoTextScan.placeholders(r'#{환자명}님, #{date}'), isEmpty);
      expect(CoTextScan.templateVariables(r'#{환자명}님, #{date}'), 2);
      expect(CoTextScan.unfilledPlaceholder('Hello {name}'), '{name}');
      expect(CoTextScan.unfilledPlaceholder(r'Hello #{name}'), isNull);
      expect(CoTextScan.unfilledPlaceholder('{"a": 1}'), isNull);
    });
  });

  group('the texts of a data set', () {
    test('names every text of the English clinic and SaaS data', () {
      final clinic = CoLanguageTexts.ofClinic(
        CoFakerClinicData.english,
        resolveFallbacks: true,
      );
      final saas = CoLanguageTexts.ofSaas(
        CoFakerSaasData.english,
        resolveFallbacks: true,
      );
      expect(clinic['clinic.specialties.name']!.length, 5);
      expect(clinic['clinic.staffRoles']!.keyed, isTrue);
      expect(clinic['clinic.staffRoles']!.cellsOf('nurse'), [
        'Registered Nurse',
      ]);
      expect(clinic['clinic.visitPurposes.details']!.cellsOf('1'), [
        'Injectables',
        'Laser',
        'Lifting',
      ]);
      expect(clinic['clinic.procedures.code']!.kind, CoTextKind.code);
      expect(clinic['clinic.ops.dateFormat']!.kind, CoTextKind.format);
      expect(clinic['clinic.ops.holidayNames']!.kind, CoTextKind.koreanOnly);
      expect(
        clinic['clinic.texts.feedback']!.cellsOf('negative'),
        hasLength(2),
      );
      expect(saas['saas.plans.name']!.length, 4);
      expect(saas['saas.ops.masterRows.name']!.cellsOf('fee'), hasLength(3));
    });

    test(
      'leaves out the texts and operations that the data does not write',
      () {
        final data = ja.clinic(dropTexts: true, dropOps: true);
        final table = CoLanguageTexts.ofClinic(data);
        expect(
          table.slots.keys.where((name) => name.startsWith('clinic.texts.')),
          isEmpty,
        );
        expect(
          table.slots.keys.where((name) => name.startsWith('clinic.ops.')),
          isEmpty,
        );
        expect(table['clinic.cardIssuers'], isNotNull);
        final resolved = CoLanguageTexts.ofClinic(data, resolveFallbacks: true);
        expect(resolved['clinic.texts.insurers'], isNotNull);
        expect(resolved['clinic.ops.rooms.name'], isNotNull);
      },
    );

    test('rewrites every string through the visitor and nothing else', () {
      var visited = 0;
      final marked = CoLanguageTexts.mapClinic(CoFakerClinicData.english, (
        at,
        text,
      ) {
        visited++;
        return '«$text»';
      }, resolveFallbacks: true);
      final table = CoLanguageTexts.ofClinic(marked, resolveFallbacks: true);
      var cells = 0;
      for (final slot in table.slots.values) {
        for (final row in slot.rows) {
          for (final cell in slot.cellsOf(row)!) {
            cells++;
            expect(cell, startsWith('«'), reason: '${slot.name}[$row]');
          }
        }
      }
      expect(cells, visited);
      expect(marked.currency, same(CoFakerClinicData.english.currency));
      expect(marked.priceScale, same(CoFakerClinicData.english.priceScale));
      expect(
        marked.procedures.first.minPrice,
        CoFakerClinicData.english.procedures.first.minPrice,
      );
    });

    test('covers every field of the data classes', () {
      // A field that the walker does not name is a field that the gate does
      // not read: add it to CoLanguageTexts when this fails.
      expect(
        _instanceFields('lib/src/clinic_data.dart', 'CoFakerClinicData'),
        CoLanguageTexts.clinicDataFields,
      );
      expect(
        _instanceFields('lib/src/clinic_texts.dart', 'CoFakerClinicTexts'),
        CoLanguageTexts.clinicTextsFields,
      );
      expect(
        _instanceFields('lib/src/clinic_ops.dart', 'CoFakerClinicOps'),
        CoLanguageTexts.clinicOpsFields,
      );
      expect(
        _instanceFields('lib/src/saas_data.dart', 'CoFakerSaasData'),
        CoLanguageTexts.saasDataFields,
      );
      expect(
        _instanceFields('lib/src/saas_ops.dart', 'CoFakerSaasOps'),
        CoLanguageTexts.saasOpsFields,
      );
    });
  });

  group('the calls of the generation checks', () {
    test('call every public member of the generators', () {
      // A member that is added to a generator has to be called here, or named
      // as a data accessor: a call that is missing is a text that no language
      // is ever read for.
      expect(_generatorSources.keys, languageCallAccessors.keys);
      for (final entry in _generatorSources.entries) {
        final called = <String>{
          for (final call in allLanguageCalls)
            if (call.name.startsWith('${entry.key}.')) call.member,
        };
        final (path, className) = entry.value;
        final members = _publicMembers(path, className)
          ..removeAll(languageCallAccessors[entry.key]!);
        expect(called, members, reason: entry.key);
      }
    });

    test('name each call once', () {
      final names = allLanguageCalls.map((call) => call.name).toList();
      expect(names.toSet(), hasLength(names.length));
      expect(clinicCalls, hasLength(greaterThan(80)));
      expect(saasCalls, hasLength(greaterThan(34)));
    });

    test(
      'exempt from the Hangul check only what is independent of the locale',
      () {
        final exempt = allLanguageCalls
            .where((call) => call.hangulReason != null)
            .map((call) => call.name)
            .toList();
        expect(exempt, <String>['clinic.inquiry']);
      },
    );
  });

  group('the data checks', () {
    test('accept a complete sample in every writing system', () {
      for (final code in ['ja', 'zh', 'ru', 'de', 'fr', 'it', 'pt']) {
        final report = _data(SampleLanguage(code).data());
        expect(report.issues, isEmpty, reason: code);
        expect(report.level, CoLanguageLevel.localized);
        expect(report.stats['bundleKeys'], report.stats['bundleKeyTotal']);
        expect(report.stats['sameAsEnglish'], 0, reason: code);
      }
    });

    test('(a) reject Hangul in a bundle, a clinic text, and a pattern', () {
      final bundle = _bundle(ja, (texts) {
        texts['dental.dentalProcedure']![1] = '치과 クリニック';
      });
      final clinic = ja.clinic(
        rewrite: (at, text) => switch (at.slot) {
          'clinic.cardIssuers' when at.row == '2' => 'カード 카드',
          'clinic.ops.dateFormat' => '{month}월 {day}일',
          _ => text,
        },
      );
      final saas = ja.saas(
        rewrite: (at, text) =>
            at.slot == 'saas.plans.name' && at.row == '0' ? '스타터' : text,
      );
      final report = _data(ja.data(bundle: bundle, clinic: clinic, saas: saas));
      expect(report.passed, isFalse);
      expect(_where(report, CoLanguageCheck.hangul), [
        'dental.dentalProcedure[1]',
        'clinic.cardIssuers[2]',
        'clinic.ops.dateFormat[0]',
        'saas.plans.name[0]',
      ]);
    });

    test('(a) do not apply to Korean, which is the language of Hangul', () {
      final report = CoLanguageCoverage().checkRegistered('ko');
      expect(report.issuesOf(CoLanguageCheck.hangul), isEmpty);
      expect(report.passed, isTrue, reason: '$report');
    });

    test('(b) reject a text without the writing system, within a limit', () {
      // One Latin text among 1,300 is within the limit and is noted.
      final one = _bundle(ja, (texts) {
        texts['dental.dentalProcedure']![0] = 'Dental cleaning';
      });
      final report = _data(ja.data(bundle: one));
      expect(report.passed, isTrue, reason: '$report');
      expect(
        report.notes.single,
        allOf(contains('dental.dentalProcedure[0]'), contains('no kana')),
      );
      // Every tenth text in Latin letters is far past it.
      final many = _bundle(ja, (texts) {
        var n = 0;
        for (final list in texts.values) {
          for (var i = 0; i < list.length; i++) {
            if (n++ % 10 == 0) list[i] = 'Latin only $n';
          }
        }
      });
      final broken = _data(ja.data(bundle: many));
      expect(broken.passed, isFalse);
      final script = broken.issuesOf(CoLanguageCheck.script);
      expect(script.first.where, 'all texts');
      expect(script.first.message, contains('at least 95.0%'));
      expect(script.length, greaterThan(50));
      expect(broken.stats['scriptRatio'], lessThan(0.95));
    });

    test('(b) ask for the writing system of the language, not another', () {
      // Han-only text is Japanese enough, and kana-only text is Chinese
      // text that a Chinese Story would not write.
      const zh = SampleLanguage('zh');
      final kana = _bundle(zh, (texts) {
        var n = 0;
        for (final list in texts.values) {
          for (var i = 0; i < list.length; i++) {
            if (n++ % 4 == 0) list[i] = 'アイウエオ';
          }
        }
      });
      final report = _data(zh.data(bundle: kana));
      expect(report.issuesOf(CoLanguageCheck.script), isNotEmpty);
      expect(
        report.issuesOf(CoLanguageCheck.script).first.message,
        contains('han'),
      );
    });

    test('(c) count the texts that equal English and keep a limit', () {
      final english = CoL10nRegistry.english.texts;
      final few = _bundle(ja, (texts) {
        // The first text of eight lists with several texts.
        for (final key
            in english.keys.where((key) => english[key]!.length > 2).take(8)) {
          texts[key]![0] = english[key]![0];
        }
      });
      final within = _data(ja.data(bundle: few));
      expect(within.passed, isTrue, reason: '$within');
      expect(
        within.notes,
        contains(contains('translatable texts equal English')),
      );
      expect(within.stats['sameAsEnglish'], greaterThan(0));
      final many = _bundle(ja, (texts) {
        var n = 0;
        for (final key in english.keys) {
          for (var i = 0; i < english[key]!.length; i++) {
            if (n++ % 8 == 0) texts[key]![i] = english[key]![i];
          }
        }
      });
      final broken = _data(ja.data(bundle: many));
      final same = broken.issuesOf(CoLanguageCheck.sameAsEnglish);
      expect(same.first.where, 'all texts');
      expect(same.first.message, contains('the limit is 5.0%'));
      expect(same.length, greaterThan(50));
      expect(same[1].message, contains('allow it'));
    });

    test('(c) allow Latin-script languages more words that equal English', () {
      // About 7% of the texts kept: past the limit of Japanese, within the
      // limit of German, which shares many words with English.
      CoL10nBundle keep(SampleLanguage sample) => _bundle(sample, (texts) {
        var n = 0;
        for (final key in CoL10nRegistry.english.texts.keys) {
          final english = CoL10nRegistry.english.texts[key]!;
          for (var i = 0; i < english.length; i++) {
            if (n++ % 8 == 0) texts[key]![i] = english[i];
          }
        }
      });
      final japanese = _data(ja.data(bundle: keep(ja)));
      final german = _data(de.data(bundle: keep(de)));
      expect(japanese.issuesOf(CoLanguageCheck.sameAsEnglish), isNotEmpty);
      expect(
        german
            .issuesOf(CoLanguageCheck.sameAsEnglish)
            .where((issue) => issue.where == 'all texts'),
        isEmpty,
      );
      expect(
        german.stats['sameAsEnglishRatio'],
        allOf(greaterThan(0.05), lessThan(0.10)),
      );
    });

    test('(c) reject a slot that is English throughout', () {
      final english = CoL10nRegistry.english.texts;
      final bundle = _bundle(ja, (texts) {
        texts['dental.dentalProcedure'] = <String>[
          ...english['dental.dentalProcedure']!,
        ];
      });
      final report = _data(ja.data(bundle: bundle));
      expect(report.passed, isFalse);
      expect(_where(report, CoLanguageCheck.sameAsEnglish), [
        'dental.dentalProcedure',
      ]);
    });

    test('(c) accept the texts that the language allows, and no others', () {
      final english = CoL10nRegistry.english.texts;
      CoLanguageReport run(Map<String, List<String>> allow) => _data(
        ja.data(
          bundle: _bundle(ja, (texts) {
            texts['catalog.groceryUnit'] = <String>[
              ...english['catalog.groceryUnit']!,
            ];
            texts['fx.tierName']![0] = english['fx.tierName']![0];
          }, allow: allow),
        ),
      );
      // Without the allowance the unit slot is English throughout.
      expect(
        run(const {}).issuesOf(CoLanguageCheck.sameAsEnglish),
        hasLength(1),
      );
      final allowed = run(const <String, List<String>>{
        'catalog.groceryUnit': ['*'],
        'fx.tierName': ['Bronze'],
      });
      expect(allowed.passed, isTrue, reason: '$allowed');
      expect(allowed.stats['allowedSameAsEnglish'], greaterThan(5));
      expect(allowed.stats['sameAsEnglish'], 0);
      // An entry that no text needs, a text that is translated, and a name
      // that is no slot are reported, so the list never keeps a stale entry.
      final stale = run(const <String, List<String>>{
        'catalog.groceryUnit': ['*'],
        'fx.tierName': ['Bronze', 'Silver'],
        'catalog.commerceUnit': ['*'],
        'no.such.slot': ['x'],
        'vet.petName': [''],
      });
      expect(_where(stale, CoLanguageCheck.allowance), [
        'fx.tierName',
        'catalog.commerceUnit',
        'no.such.slot',
        'vet.petName',
      ]);
    });

    test('(d) reject a list of another length', () {
      final bundle = _bundle(ja, (texts) {
        texts['dental.dentalProcedure']!.removeLast();
        texts['vet.petName']!.add('余分');
      });
      final clinic = ja.clinic(
        cardIssuers: ja.clinic().cardIssuers.skip(1).toList(),
      );
      final report = _data(ja.data(bundle: bundle, clinic: clinic));
      expect(
        _where(report, CoLanguageCheck.length),
        unorderedEquals(<String>[
          'dental.dentalProcedure',
          'vet.petName',
          'clinic.cardIssuers',
        ]),
      );
      expect(
        report
            .issuesOf(CoLanguageCheck.length)
            .firstWhere((issue) => issue.where == 'dental.dentalProcedure')
            .message,
        'has 3 texts, English has 4: keep the same number, in the same order',
      );
    });

    test('(d) reject a map that lacks or adds a key', () {
      final clinic = ja.clinic(rewrite: (at, text) => text);
      final labels = <String, String>{
        for (final entry in clinic.labels.entries)
          if (entry.key != 'nhis') entry.key: entry.value,
        'extra': 'もう一つ',
      };
      final changed = CoFakerClinicData(
        specialties: clinic.specialties,
        clinicNamePrefixes: clinic.clinicNamePrefixes,
        staffRoles: clinic.staffRoles,
        visitPurposes: clinic.visitPurposes,
        procedures: clinic.procedures,
        diagnoses: clinic.diagnoses,
        drugStems: clinic.drugStems,
        drugForms: clinic.drugForms,
        drugUsages: clinic.drugUsages,
        complaints: clinic.complaints,
        findings: clinic.findings,
        plans: clinic.plans,
        memos: clinic.memos,
        questions: clinic.questions,
        cardIssuers: clinic.cardIssuers,
        labels: labels,
        packageNameFormat: clinic.packageNameFormat,
        texts: clinic.texts,
        ops: clinic.ops,
        koreanValues: CoKoreanValues.none,
      );
      final report = _data(ja.data(clinic: changed));
      final issue = report.issuesOf(CoLanguageCheck.length).single;
      expect(issue.where, 'clinic.labels');
      expect(issue.message, contains('missing: nhis'));
      expect(issue.message, contains('does not have: extra'));
    });

    test('(e) list the keys and the data sets that are not registered', () {
      final bundle = _bundle(ja, (texts) {
        texts.remove('dental.dentalProcedure');
        texts.remove('vet.petName');
      });
      final report = _data(
        ja.data(bundle: bundle, withoutClinic: true, withoutSaas: true),
      );
      expect(report.level, CoLanguageLevel.partial);
      expect(
        _where(report, CoLanguageCheck.unregistered),
        unorderedEquals(<String>[
          'dental.dentalProcedure',
          'vet.petName',
          'clinic',
          'saas',
        ]),
      );
      expect(report.stats['bundleKeys'], report.stats['bundleKeyTotal']! - 2);
    });

    test('(e) list the texts and operations that a data set leaves out', () {
      final report = _data(
        ja.data(
          clinic: ja.clinic(dropTexts: true, dropOps: true),
          saas: ja.saas(dropOps: true),
        ),
      );
      expect(_where(report, CoLanguageCheck.unregistered), [
        'clinic.texts',
        'clinic.ops',
        'saas.ops',
      ]);
    });

    test(
      'reject a key that English does not have, a code that differs, and an empty text',
      () {
        final bundle = _bundle(ja, (texts) {
          texts['dental.notAKey'] = ['x'];
          texts['vet.petName']![0] = '  ';
        });
        final clinic = ja.clinic(
          rewrite: (at, text) =>
              at.slot == 'clinic.procedures.code' && at.row == '1'
              ? 'XXX'
              : text,
        );
        final report = _data(ja.data(bundle: bundle, clinic: clinic));
        expect(_where(report, CoLanguageCheck.unknownKey), ['dental.notAKey']);
        expect(_where(report, CoLanguageCheck.empty), ['vet.petName[0]']);
        expect(_where(report, CoLanguageCheck.code), [
          'clinic.procedures.code[1]',
        ]);
      },
    );

    test('reject a translation that lost its placeholders', () {
      final bundle = _bundle(ja, (texts) {
        texts['workplace.sprintName'] = ['スプリント'];
      });
      final saas = ja.saas(
        rewrite: (at, text) =>
            at.slot == 'saas.messageTemplates.body' ? 'メッセージ' : text,
      );
      final report = _data(ja.data(bundle: bundle, saas: saas));
      final where = _where(report, CoLanguageCheck.placeholder);
      expect(where.first, 'workplace.sprintName[0]');
      expect(
        where.skip(1),
        everyElement(startsWith('saas.messageTemplates.body')),
      );
      expect(
        report.issuesOf(CoLanguageCheck.placeholder).last.message,
        contains('#{variable}'),
      );
    });

    test('reject exam questions that lost their pairs', () {
      // The explanation of a question contains its correct choice, and the
      // four choices of a question differ: the generator shuffles the choices
      // and keeps the answer key with the correct one.
      final bundle = _bundle(ja, (texts) {
        texts['exam_prep.explanation']![0] = 'ただの説明';
        texts['exam_prep.wrongChoice1']![1] =
            texts['exam_prep.correctChoice']![1];
      });
      final report = _data(ja.data(bundle: bundle));
      expect(
        _where(report, CoLanguageCheck.invariant),
        unorderedEquals(<String>[
          'exam_prep.explanation[0]',
          'exam_prep.questionStem[1]',
        ]),
      );
      expect(_data(ja.data()).issuesOf(CoLanguageCheck.invariant), isEmpty);
    });

    test(
      'compare the clinic and SaaS data with English, but not the Korean data',
      () {
        // The Korean clinic data has 29 procedures and English has 8: it is a
        // data set of its own sizes.
        expect(
          CoFakerClinicData.korean.procedures.length,
          isNot(CoFakerClinicData.english.procedures.length),
        );
        expect(
          CoLanguageCoverage()
              .checkRegistered('ko')
              .issuesOf(CoLanguageCheck.length),
          isEmpty,
        );
        // The same lengths in a language that is not Korean are an error.
        final report = _data(
          CoLanguageData(
            language: 'ja',
            bundle: ja.bundle(),
            clinic: CoFakerClinicData.korean,
            saas: ja.saas(),
          ),
        );
        expect(
          _where(report, CoLanguageCheck.length),
          contains('clinic.procedures.name'),
        );
      },
    );

    test('skip the Korean holiday names, which no other language shows', () {
      final report = _data(ja.data());
      expect(report.issues, isEmpty);
      final table = CoLanguageTexts.ofClinic(ja.clinic());
      expect(table['clinic.ops.holidayNames']!.kind, CoTextKind.koreanOnly);
    });
  });

  group('the levels', () {
    test('tell a stub from a partial and a complete language', () {
      expect(
        const CoLanguageData(
          language: 'ja',
          bundle: CoL10nBundle(language: 'ja'),
        ).level,
        CoLanguageLevel.planned,
      );
      expect(
        const CoLanguageData(
          language: 'es',
          bundle: CoL10nBundle(language: 'es'),
          registered: false,
        ).level,
        CoLanguageLevel.base,
      );
      expect(ja.data(withoutSaas: true).level, CoLanguageLevel.partial);
      expect(ja.data().level, CoLanguageLevel.localized);
    });

    test('report a stub as planned and nothing else', () {
      final report = CoLanguageCoverage().check(
        const CoLanguageData(
          language: 'ja',
          bundle: CoL10nBundle(language: 'ja'),
        ),
      );
      expect(report.passed, isFalse);
      expect(report.level, CoLanguageLevel.planned);
      expect(report.issues.single.check, CoLanguageCheck.planned);
      expect(report.issues.single.message, startsWith('planned — no data'));
    });

    test('generate only when the language is complete', () {
      final partial = CoLanguageCoverage().check(
        ja.data(withoutSaas: true),
        faker: ja.faker(ja.data()),
      );
      expect(partial.stats.containsKey('generatedTexts'), isFalse);
      final complete = CoLanguageCoverage().check(
        ja.data(),
        faker: ja.faker(ja.data()),
      );
      expect(complete.stats['generatedTexts'], greaterThan(10000));
    });

    test('compute the table of languages from the registries', () {
      final rows = CoLanguageCoverage.support();
      expect(
        rows.map((row) => row.code),
        CoFakerLanguages.all.map((language) => language.code),
      );
      for (final row in rows) {
        final data = CoLanguageData.registered(row.code);
        expect(row.level, data.level, reason: row.code);
        expect(row.clinic, data.clinic != null, reason: row.code);
        expect(row.saas, data.saas != null, reason: row.code);
        expect(row.bundleKeyTotal, CoL10nRegistry.english.texts.length);
        expect(row.bundleKeys, data.bundle.texts.length, reason: row.code);
      }
      final es = rows.singleWhere((row) => row.code == 'es');
      expect(es.level, CoLanguageLevel.base);
      final markdown = CoLanguageCoverage.supportMarkdown(rows);
      expect(markdown.split('\n'), hasLength(rows.length + 2));
      expect(markdown, contains('| `ko` Korean | hangul | ✓ | ✓ | '));
      expect(rows.first.toJson()['level'], 'localized');
    });
  });

  group('the generation checks', () {
    test('accept a sample whose every text is rewritten', () {
      for (final code in ['ja', 'zh', 'ru', 'de']) {
        final sample = SampleLanguage(code);
        final result = _generate(sample, sample.data(), strictProse: true);
        expect(
          result.issues,
          isEmpty,
          reason: '$code: ${result.issues.take(3)}',
        );
        expect(result.calls, greaterThan(600));
        expect(result.texts, greaterThan(1500));
      }
    });

    test('find Hangul that a text or a generator writes', () {
      final bundle = _bundle(ja, (texts) {
        texts['dental.dentalProcedure'] = <String>[
          for (final text in texts['dental.dentalProcedure']!) '치과 $text',
        ];
      });
      final result = _generate(ja, ja.data(bundle: bundle));
      final hangul = result.issues.where(
        (issue) => issue.check == CoLanguageCheck.hangul,
      );
      expect(
        hangul.map((issue) => issue.where),
        contains('role dental.dentalProcedure'),
      );
      expect(hangul.first.value, contains('치과'));
    });

    test('find a placeholder that no generator filled', () {
      final clinic = ja.clinic(
        packageNameFormat: '{name} ×{sessions}{unfilled}',
      );
      final result = _generate(ja, ja.data(clinic: clinic));
      final found = result.issues.where(
        (issue) => issue.check == CoLanguageCheck.placeholder,
      );
      expect(found.map((issue) => issue.where), contains('clinic.package'));
      expect(found.first.message, contains('{unfilled}'));
    });

    test('leave a template variable of a notification alone', () {
      // The message templates write `#{variable}` on purpose.
      final result = _generate(ja, ja.data());
      expect(
        result.issues.where((issue) => issue.where.contains('messageTemplate')),
        isEmpty,
      );
    });

    test('find a generator that throws', () {
      final clinic = ja.clinic(diagnoses: const <CoDiagnosisSpec>[]);
      final result = _generate(ja, ja.data(clinic: clinic));
      final errors = result.issues.where(
        (issue) => issue.check == CoLanguageCheck.error,
      );
      expect(errors, isNotEmpty);
      expect(errors.map((issue) => issue.where), contains('clinic.diagnosis'));
    });

    test(
      'find a role that writes English in a language with its own script',
      () {
        final bundle = _bundle(ja, (texts) {
          texts['dental.dentalProcedure'] = <String>[
            'Dental cleaning',
            'Dental sealing',
            'Dental filling',
            'Dental crown plan',
          ];
        });
        final result = _generate(ja, ja.data(bundle: bundle));
        final script = result.issues.where(
          (issue) => issue.check == CoLanguageCheck.script,
        );
        expect(script.map((issue) => issue.where), [
          'role dental.dentalProcedure',
        ]);
        expect(script.single.value, startsWith('Dental'));
      },
    );

    test('do not ask a Latin-script language for a writing system', () {
      final result = _generate(de, de.data());
      expect(result.issues, isEmpty);
    });

    test('leave out the roles that ask for Korean values by name', () {
      expect(koreanOnlyPacks.keys, ['korea']);
      final result = _generate(ja, ja.data());
      expect(
        result.issues.where((issue) => issue.where.contains('korea.')),
        isEmpty,
      );
    });

    test('exempt a call that is independent of the locale, and only that', () {
      // `inquiry` writes Korean in every language; a call that does not say
      // so is held to the check.
      final result = _generate(ja, ja.data());
      expect(
        result.issues.where((issue) => issue.where == 'clinic.inquiry'),
        isEmpty,
      );
      expect(
        clinicCalls
            .singleWhere((call) => call.name == 'clinic.inquiry')
            .hangulReason,
        isNotNull,
      );
    });
  });

  group('the report', () {
    test('writes Markdown and JSON that a person and a tool can read', () {
      final bundle = _bundle(ja, (texts) {
        texts['dental.dentalProcedure']![1] = '치과';
      });
      final report = _data(ja.data(bundle: bundle, withoutSaas: true));
      final markdown = report.toMarkdown();
      expect(markdown, contains('# Language coverage: ja'));
      expect(markdown, contains('Result: **FAIL**'));
      expect(markdown, contains('## (a) Hangul (1)'));
      expect(markdown, contains('`dental.dentalProcedure[1]`'));
      expect(markdown, contains('## (e) not registered (1)'));
      final json = report.toJson();
      expect(json['language'], 'ja');
      expect(json['passed'], isFalse);
      expect((json['issues']! as List).first, isA<Map<String, Object?>>());
      expect(
        (json['issues']! as List).cast<Map<String, Object?>>().map(
          (issue) => issue['check'],
        ),
        containsAll(<String>['hangul', 'unregistered']),
      );
    });

    test('cut a long list but count what it leaves out', () {
      final many = _bundle(ja, (texts) {
        for (final list in texts.values) {
          for (var i = 0; i < list.length; i++) {
            list[i] = '문장 ${list[i]}';
          }
        }
      });
      final report = _data(ja.data(bundle: many));
      final markdown = report.toMarkdown(limit: 5);
      final hangul = report.issuesOf(CoLanguageCheck.hangul).length;
      expect(markdown, contains('## (a) Hangul ($hangul)'));
      expect(markdown, contains('and ${hangul - 5} more'));
    });
  });
}
