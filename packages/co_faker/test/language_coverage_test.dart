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

/// Whether every surrogate of [text] has its pair: the text is valid Unicode.
bool _wellFormed(String text) {
  final units = text.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      final paired =
          i + 1 < units.length &&
          units[i + 1] >= 0xDC00 &&
          units[i + 1] <= 0xDFFF;
      if (!paired) return false;
      i++;
    } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
      return false;
    }
  }
  return true;
}

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
      expect(CoTextScan.fieldNames('{a} and {b_1}'), ['a', 'b_1']);
      expect(CoTextScan.fieldNames('{n} of {n}'), ['n', 'n']);
      expect(CoTextScan.fieldNames(r'#{환자명}님, #{date}'), isEmpty);
      expect(CoTextScan.fieldNames(r'{kind} #{number}'), ['kind']);
      expect(CoTextScan.fieldNames(r'{kind} #{number}', templates: true), [
        'kind',
        'number',
      ]);
      expect(CoTextScan.templateVariables(r'#{환자명}님, #{date}'), 2);
      expect(CoTextScan.unfilledPlaceholder('Hello {name}'), '{name}');
      // The marker of a notification template is output on purpose; anywhere
      // else a field behind a number sign (`Laser #{numer}`) is a leak.
      expect(
        CoTextScan.unfilledPlaceholder(r'Hello #{name}', templates: true),
        isNull,
      );
      expect(CoTextScan.unfilledPlaceholder(r'Laser #{numer}'), '{numer}');
      expect(CoTextScan.unfilledPlaceholder('{"a": 1}'), isNull);
    });

    test('reads a field whose name is in any writing system', () {
      // A translation that renames a field leaves it in the output: every
      // spelling of a field that a generator would not fill is found.
      expect(CoTextScan.fieldNames('{回数}回, {имя}, {mês}'), [
        '回数',
        'имя',
        'mês',
      ]);
      expect(CoTextScan.fieldNames('{0} {1}'), ['0', '1']);
      for (final leak in [
        'x {回数} y',
        'x {имя} y',
        'x { n } y',
        'x {n } y',
        'x ｛n｝ y',
        'x {0} y',
      ]) {
        expect(CoTextScan.unfilledPlaceholder(leak), isNotNull, reason: leak);
      }
      expect(
        CoTextScan.unfilledPlaceholder('x #{番号} y', templates: true),
        isNull,
      );
      for (final fine in [
        '[{"date": "2026-01-15", "rate": 1.2}]',
        '{ "a": 1 }',
        '{}',
        'plain',
      ]) {
        expect(CoTextScan.unfilledPlaceholder(fine), isNull, reason: fine);
      }
      expect(CoTextScan.hasLetters('{回数}'), isFalse);
      expect(CoTextScan.hasLetters('{回数}回'), isTrue);
    });

    test('knows the Hangul and han that the first tables left out', () {
      // Half-width and circled Hangul, and the han characters of Extension G.
      expect(CoTextScan.hasHangul('ﾡﾢ'), isTrue);
      expect(CoTextScan.hasHangul('㉠'), isTrue);
      expect(CoTextScan.hasHangul('㈀'), isTrue);
      expect(CoTextScan.hasHangul('①②'), isFalse);
      expect(CoTextScan.hasScript('\u{30000}', CoFakerScript.han), isTrue);
      expect(CoTextScan.hasKana('アイウ'), isTrue);
      expect(CoTextScan.hasKana('\u{1B001}'), isTrue);
      expect(CoTextScan.hasKana('皮膚科'), isFalse);
    });

    test('cuts a text without cutting a character in half', () {
      // The tooth emoji takes two UTF-16 code units: a cut between them would
      // leave half of it, and a report in JSON would not be valid Unicode.
      final text = '🦷' * 40;
      for (final length in [47, 48, 49]) {
        final cut = CoTextScan.cut(text, length);
        expect(cut.length, anyOf(length, length - 1));
        expect(
          cut.codeUnits.where((unit) => unit >= 0xD800 && unit <= 0xDBFF),
          hasLength(cut.length ~/ 2),
        );
        expect(
          CoTextScan.excerpt(text, length: length).runes.toList().last,
          0x2026,
        );
      }
      for (var index = 20; index < 30; index++) {
        final around = CoTextScan.around(text, index);
        expect(around, isNot(startsWith('\uDDB7')));
        expect(
          around.runes.every((rune) => rune == 0x1F9B7),
          isTrue,
          reason: 'around $index: ${around.codeUnits}',
        );
      }
      expect(CoTextScan.cut('短い', 10), '短い');
      expect(CoTextScan.around('a\nb', 1), 'a b');
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

    test('(b) tell Japanese from Chinese by the kana', () {
      // Han characters alone are Chinese, and a kana is not Chinese: a
      // language is not the other one with its name changed.
      const zh = SampleLanguage('zh');
      final chinese = zh.data();
      final asJapanese = CoLanguageData(
        language: 'ja',
        bundle: CoL10nBundle(language: 'ja', texts: chinese.bundle.texts),
        clinic: chinese.clinic,
        saas: chinese.saas,
      );
      final noKana = _data(asJapanese).issuesOf(CoLanguageCheck.script);
      expect(noKana.single.where, 'all texts');
      expect(noKana.single.message, contains('have a kana'));
      expect(noKana.single.message, contains('han characters alone'));
      final japanese = ja.data();
      final asChinese = CoLanguageData(
        language: 'zh',
        bundle: CoL10nBundle(language: 'zh', texts: japanese.bundle.texts),
        clinic: japanese.clinic,
        saas: japanese.saas,
      );
      expect(
        _data(
          asChinese,
        ).issuesOf(CoLanguageCheck.script).map((issue) => issue.message),
        contains(contains('which only Japanese writes')),
      );
      // A Japanese text with han characters and a few without a kana is fine.
      final mixed = _bundle(ja, (texts) {
        var n = 0;
        for (final list in texts.values) {
          for (var i = 0; i < list.length; i++) {
            if (n++ % 3 == 0) list[i] = '皮膚科';
          }
        }
      });
      expect(
        _data(ja.data(bundle: mixed)).issuesOf(CoLanguageCheck.script),
        isEmpty,
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

    test('(c) read a text that only its case or spaces change as English', () {
      // The English bundle, lower-cased, with a no-break space, and with
      // typographic quotes, is English still: nothing was translated.
      final english = CoL10nRegistry.english.texts;
      final bundle = _bundle(de, (texts) {
        var n = 0;
        for (final key in english.keys) {
          for (var i = 0; i < english[key]!.length; i++) {
            final text = english[key]![i];
            texts[key]![i] = switch (n++ % 4) {
              0 => text.toLowerCase(),
              1 => '$text ',
              2 => text.replaceAll(' ', ' ').replaceAll("'", '’'),
              _ => texts[key]![i],
            };
          }
        }
      });
      final report = _data(de.data(bundle: bundle));
      final same = report.issuesOf(CoLanguageCheck.sameAsEnglish);
      expect(same.first.where, 'all texts');
      expect(same.first.message, contains('the limit is 10.0%'));
      expect(report.stats['sameAsEnglishRatio'], greaterThan(0.3));
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

    test('(c) keep the allowances to a few texts', () {
      // A list that allows every slot would pass a bundle that is English
      // throughout: it is for the units, acronyms, and names.
      final english = CoL10nRegistry.english.texts;
      final bundle = _bundle(
        de,
        (texts) {
          for (final key in english.keys) {
            texts[key] = <String>[...english[key]!];
          }
        },
        allow: <String, List<String>>{
          for (final key in english.keys) key: const <String>['*'],
        },
      );
      final report = _data(de.data(bundle: bundle));
      expect(report.passed, isFalse);
      final capped = report
          .issuesOf(CoLanguageCheck.allowance)
          .where((issue) => issue.where == 'allowSameAsEnglish');
      expect(capped.single.message, contains('at most 10.0%'));
      expect(report.stats['sameAsEnglish'], 0);
      expect(report.stats['allowedSameAsEnglish'], greaterThan(700));
    });

    test('(c) report an allowance of Korean that no text needs', () {
      // The Korean clinic and SaaS data are read for their writing system, and
      // an entry that no text of them needs is as stale as any other.
      final ko = CoLanguageData.registered('ko');
      final bundle = CoL10nBundle(
        language: 'ko',
        texts: ko.bundle.texts,
        allowSameAsEnglish: <String, List<String>>{
          ...ko.bundle.allowSameAsEnglish,
          'clinic.diagnoses.name': const <String>['*'],
          'saas.plans.name': const <String>['*'],
        },
      );
      final report = _data(
        CoLanguageData(
          language: 'ko',
          bundle: bundle,
          clinic: ko.clinic,
          saas: ko.saas,
        ),
      );
      expect(
        _where(report, CoLanguageCheck.allowance),
        unorderedEquals(<String>['clinic.diagnoses.name', 'saas.plans.name']),
      );
    });

    test(
      '(c) take the detail of a failed claim master check from the data',
      () {
        // `faker.saas.masterChecks()` wrote `5 rows` in every language: the
        // English word was in the generator, so no language could write it.
        Set<String> details(CoFaker Function(int seed) faker) => <String>{
          for (var seed = 1; seed <= 40; seed++)
            for (final check in faker(seed).saas.masterChecks())
              if (check.detail != null) check.detail!,
        };
        for (final locale in ['en', 'ko']) {
          expect(
            details(
              (seed) => CoFaker(
                locale: locale,
                seed: seed,
                now: DateTime.utc(2026, 1, 15),
              ),
            ),
            everyElement(matches(RegExp(r'^\d{1,2} rows$'))),
            reason: locale,
          );
        }
        expect(CoFakerSaasOps.english.masterCheckDetail, '{n} rows');
        expect(CoFakerSaasOps.korean.masterCheckDetail, '{n} rows');
        final written = ja.saas(
          rewrite: (at, text) =>
              at.slot == 'saas.ops.masterCheckDetail' ? '{n}行' : text,
        );
        final factory = ja.faker(ja.data(saas: written));
        final japanese = details((seed) => factory(seed, CoFakerDomains.all));
        expect(japanese, isNotEmpty);
        expect(japanese, everyElement(matches(RegExp(r'^\d{1,2}行$'))));
        expect(_data(ja.data(saas: written)).issues, isEmpty);
        // Left in English, the detail is a slot that is English throughout.
        final left = ja.saas(
          rewrite: (at, text) =>
              at.slot == 'saas.ops.masterCheckDetail' ? '{n} rows' : text,
        );
        expect(
          _where(_data(ja.data(saas: left)), CoLanguageCheck.sameAsEnglish),
          ['saas.ops.masterCheckDetail'],
        );
      },
    );

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

    test('(d) reject a map whose keys are in another order', () {
      // A generator that picks one entry takes it by position, so the same
      // seed picks another entry in a language that lists the keys in
      // another order.
      final roles = ja.clinic().staffRoles;
      final reversed = <String, String>{
        for (final key in roles.keys.toList().reversed) key: roles[key]!,
      };
      final report = _data(ja.data(clinic: ja.clinic(staffRoles: reversed)));
      final issue = report.issuesOf(CoLanguageCheck.length).single;
      expect(issue.where, 'clinic.staffRoles');
      expect(issue.message, contains('another order than English'));
      expect(issue.message, contains('(director, doctor, counselor'));
      expect(_data(ja.data()).issuesOf(CoLanguageCheck.length), isEmpty);
    });

    test('reject data that keeps the Korean values outside Korean', () {
      // `legacy` is what a data set that does not choose gets, and it keeps
      // the Korean phone numbers, addresses, and registration numbers, which
      // hold no Hangul and no other check sees.
      final report = _data(
        ja.data(
          clinic: ja.clinic(koreanValues: CoKoreanValues.legacy),
          saas: ja.saas(koreanValues: CoKoreanValues.korean),
        ),
      );
      expect(_where(report, CoLanguageCheck.invariant), [
        'clinic.koreanValues',
        'saas.koreanValues',
      ]);
      expect(
        report.issuesOf(CoLanguageCheck.invariant).first.message,
        contains('CoKoreanValues.none'),
      );
      expect(_data(ja.data()).issuesOf(CoLanguageCheck.invariant), isEmpty);
      // Korean and English keep theirs by design.
      expect(CoFakerClinicData.korean.koreanValues, CoKoreanValues.korean);
      expect(
        CoLanguageCoverage()
            .checkRegistered('ko')
            .issuesOf(CoLanguageCheck.invariant),
        isEmpty,
      );
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

    test(
      'reject a translation that drops, renames, repeats, or adds a field',
      () {
        // A generator fills the English names only: a field that is renamed
        // stays in the output as written, and one that is dropped loses its
        // value. Each text below keeps one field, so the weaker rule (at least
        // one) would pass all of them.
        final bundle = _bundle(ja, (texts) {
          texts['common.taxonomyChild']![0] = '{root}の小項目'; // drops {n}
          texts['fitness.className']![0] = '{分類} {level}'; // renames {category}
          texts['workplace.sprintName']![0] = 'スプリント{n}{n}'; // repeats {n}
          texts['logistics.vehiclePlate']![0] = '{n}{m}{x}'; // adds {x}
        });
        final report = _data(ja.data(bundle: bundle));
        final issues = <String, String>{
          for (final issue in report.issuesOf(CoLanguageCheck.placeholder))
            issue.where: issue.message,
        };
        expect(
          issues.keys,
          unorderedEquals(<String>[
            'common.taxonomyChild[0]',
            'fitness.className[0]',
            'workplace.sprintName[0]',
            'logistics.vehiclePlate[0]',
          ]),
        );
        expect(
          issues['common.taxonomyChild[0]'],
          'lacks {n}, which English has',
        );
        expect(
          issues['fitness.className[0]'],
          allOf(contains('lacks {category}'), contains('has {分類}')),
        );
        expect(
          issues['workplace.sprintName[0]'],
          contains('has {n}, which English does not have'),
        );
        expect(
          issues['logistics.vehiclePlate[0]'],
          contains('has {x}, which English does not have'),
        );
        // The same fields in another order are the same fields.
        final reordered = _bundle(ja, (texts) {
          texts['fitness.className']![0] = '{level}の{category}';
          texts['logistics.vehiclePlate']![0] = '{m}・{n}';
        });
        expect(_data(ja.data(bundle: reordered)).passed, isTrue);
      },
    );

    test('read a field that a translation spaced or wrote in full-width', () {
      final bundle = _bundle(ja, (texts) {
        texts['workplace.sprintName']![0] = 'スプリント{ n }';
        texts['common.taxonomyChild']![0] = '｛root｝ · ｛n｝';
      });
      final report = _data(ja.data(bundle: bundle));
      expect(
        _where(report, CoLanguageCheck.placeholder),
        unorderedEquals(<String>[
          'common.taxonomyChild[0]',
          'workplace.sprintName[0]',
        ]),
      );
    });

    test('hold the patterns to their fields, a number sign included', () {
      final clinic = ja.clinic(
        rewrite: (at, text) => switch (at.slot) {
          'clinic.ops.dateRangeFormat' => '{from}', // drops {to}
          'clinic.packageNameFormat' => '{名前} x{sessions}', // renames {name}
          // The English pattern writes a number sign before the field.
          'clinic.texts.deviceNameFormat' => '{kind} #{numer}',
          _ => text,
        },
      );
      final report = _data(ja.data(clinic: clinic));
      expect(
        _where(report, CoLanguageCheck.placeholder),
        unorderedEquals(<String>[
          'clinic.ops.dateRangeFormat[0]',
          'clinic.packageNameFormat[0]',
          'clinic.texts.deviceNameFormat[0]',
        ]),
      );
      // The way each language writes the number of a device keeps the two
      // fields and asks for no number sign: none of them is rejected.
      const natural = <String, String>{
        'ja': '{kind} {number}号機',
        'zh': '{kind}{number}号',
        'de': '{kind} Nr. {number}',
        'fr': '{kind} n° {number}',
        'ru': '{kind} №{number}',
        'it': '{kind} n. {number}',
        'pt': '{kind} nº {number}',
      };
      for (final entry in natural.entries) {
        final sample = SampleLanguage(entry.key);
        final fine = sample.clinic(
          rewrite: (at, text) =>
              at.slot == 'clinic.texts.deviceNameFormat' ? entry.value : text,
        );
        expect(
          _data(sample.data(clinic: fine)).issues,
          isEmpty,
          reason: '${entry.key}: ${entry.value}',
        );
      }
      // The fields may come in another order.
      final reordered = ja.clinic(
        rewrite: (at, text) => at.slot == 'clinic.texts.deviceNameFormat'
            ? '{number}号機の{kind}'
            : text,
      );
      expect(_data(ja.data(clinic: reordered)).issues, isEmpty);
    });

    test('let a pattern use the fields that its generator offers besides', () {
      // The address line of a patient has the region of the place, and a date
      // has its weekday; English uses neither, and a language may.
      CoLanguageReport address(String format) =>
          _data(ja.data(clinic: ja.clinic(addressLineFormat: format)));
      CoLanguageReport date(String format) => _data(
        ja.data(
          clinic: ja.clinic(
            rewrite: (at, written) =>
                at.slot == 'clinic.ops.dateFormat' ? format : written,
          ),
        ),
      );
      for (final fine in [
        '{region}{city}{line1}',
        '{line1}, {city}, {regionCode}',
        '{line1}, {city}',
      ]) {
        expect(address(fine).issues, isEmpty, reason: fine);
      }
      expect(date('{month}月{day}日({weekday})').issues, isEmpty);
      // The English fields stay required, and no other name is offered.
      expect(_where(address('{region}{line1}'), CoLanguageCheck.placeholder), [
        'clinic.addressLineFormat[0]',
      ]);
      expect(
        address(
          '{line1}, {city}, {postal}',
        ).issuesOf(CoLanguageCheck.placeholder).single.message,
        contains('has {postal}'),
      );
      expect(
        date(
          '{year}/{month}/{day}',
        ).issuesOf(CoLanguageCheck.placeholder).single.message,
        contains('has {year}'),
      );
      // The Korean particles of a closure notice are not offered to another
      // language: they write Hangul.
      expect(
        _where(
          _data(
            ja.data(
              clinic: ja.clinic(
                rewrite: (at, written) =>
                    at.slot == 'clinic.ops.closure' && at.row == 'other'
                    ? '{clinic}{eun} {dates} {reason}{ro} {reopen}'
                    : written,
              ),
            ),
          ),
          CoLanguageCheck.placeholder,
        ),
        ['clinic.ops.closure[other]'],
      );
    });

    test(
      'count the variables of a template, and let a language rename them',
      () {
        final saas = ja.saas(
          rewrite: (at, text) => switch ((at.slot, at.row)) {
            // Renamed variables: a notification template of another language
            // names its variables in its own words.
            ('saas.messageTemplates.body', '0') =>
              'こんにちは #{お客様}、#{日時} #{医院} のご予約です',
            // One variable lost.
            ('saas.messageTemplates.body', '1') => 'こんにちは #{お客様}',
            _ => text,
          },
        );
        final report = _data(ja.data(saas: saas));
        final issue = report.issuesOf(CoLanguageCheck.placeholder).single;
        expect(issue.where, 'saas.messageTemplates.body[1]');
        expect(issue.message, contains('has 1 #{variable} markers'));
      },
    );

    test('let a template choose among the names that a generator offers', () {
      // English keeps the initial of a masked name, Korean the surname, and a
      // new language writes the first given name of a daycare template.
      final fine = _bundle(ja, (texts) {
        texts['common.maskedName']![0] = '{lastName}＊＊';
        texts['daycare.guardianLabel']![0] = '{name1}さんの保護者';
        texts['daycare.teacherName']![0] = '{name1}先生';
      });
      expect(
        _data(ja.data(bundle: fine)).issuesOf(CoLanguageCheck.placeholder),
        isEmpty,
      );
      final broken = _bundle(ja, (texts) {
        texts['common.maskedName']![0] = '{middleName}＊＊';
        texts['daycare.guardianLabel']![0] = '{name1}{name2}さんの保護者';
        texts['daycare.teacherName']![0] = '先生';
      });
      expect(
        _where(_data(ja.data(bundle: broken)), CoLanguageCheck.placeholder),
        unorderedEquals(<String>[
          'common.maskedName[0]',
          'daycare.guardianLabel[0]',
          'daycare.teacherName[0]',
        ]),
      );
    });

    test('offer the names that the Korean and English texts use', () {
      // The table of offered names is a fact about the generators: the
      // shipped English and Korean texts of those keys use names from it.
      final english = CoL10nRegistry.english.texts;
      final korean = CoL10nRegistry.bundleFor('ko')!.texts;
      const offered = <String, Set<String>>{
        'common.maskedName': {'lastName', 'firstName', 'initial'},
        'daycare.guardianLabel': {'name1', 'name2'},
        'daycare.teacherName': {'name1', 'name2'},
      };
      for (final entry in offered.entries) {
        for (final texts in [english, korean]) {
          for (final text in texts[entry.key]!) {
            expect(
              CoTextScan.fieldNames(text).toSet().difference(entry.value),
              isEmpty,
              reason: '${entry.key}: $text',
            );
          }
        }
      }
      // Every other key of the Korean bundle keeps the English fields: the
      // gate asks for the same of every language, and Korean is the one that
      // already exists.
      for (final entry in english.entries) {
        if (offered.containsKey(entry.key)) continue;
        for (var i = 0; i < entry.value.length; i++) {
          expect(
            CoTextScan.fieldNames(korean[entry.key]![i])..sort(),
            CoTextScan.fieldNames(entry.value[i])..sort(),
            reason: '${entry.key}[$i]',
          );
        }
      }
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

    test('ask the explanation for its choice whatever the case', () {
      // A choice that opens a sentence is written in the case of the
      // sentence: `Clé primaire` in `La clé primaire identifie…`.
      const fr = SampleLanguage('fr');
      final sentence = _bundle(fr, (texts) {
        texts['exam_prep.correctChoice']![0] = 'Clé primaire';
        texts['exam_prep.explanation']![0] =
            'La clé primaire identifie chaque ligne.';
      });
      expect(
        _data(fr.data(bundle: sentence)).issuesOf(CoLanguageCheck.invariant),
        isEmpty,
      );
      final other = _bundle(fr, (texts) {
        texts['exam_prep.correctChoice']![0] = 'Clé primaire';
        texts['exam_prep.explanation']![0] = 'Chaque ligne a un identifiant.';
      });
      expect(_where(_data(fr.data(bundle: other)), CoLanguageCheck.invariant), [
        'exam_prep.explanation[0]',
      ]);
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

    test('tell data that the registries do not hold from a missing text', () {
      // Without a generator of its own the gate runs the ones that an app gets,
      // which read the registries. Data that is not what the registries hold
      // is reported as such, not as a pile of untranslated texts.
      final report = CoLanguageCoverage().check(ja.data());
      final wiring = report.issues.where(
        (issue) => issue.where == 'CoFaker.forLanguage',
      );
      expect(
        wiring.map((issue) => issue.message),
        containsAll(<Matcher>[
          contains('clinic data that was checked'),
          contains('SaaS data that was checked'),
        ]),
      );
      // The registered data of Korean is what its generators read.
      expect(
        CoLanguageCoverage()
            .checkRegistered('ko')
            .issues
            .where((issue) => issue.where == 'CoFaker.forLanguage'),
        isEmpty,
      );
    });

    test('read a language setting the way CoFaker.forLanguage reads it', () {
      // `ko-KR` and `KO` are Korean for an app, so they are Korean for the
      // gate: not a language without data.
      for (final tag in ['ko', 'KO', 'ko-KR', 'ko_KR', 'ko_KR.UTF-8']) {
        final data = CoLanguageData.registered(tag);
        expect(data.language, 'ko', reason: tag);
        expect(data.level, CoLanguageLevel.localized, reason: tag);
        expect(_data(data).passed, isTrue, reason: tag);
      }
      expect(CoLanguageData.registered('en_US.UTF-8').language, 'en');
      expect(CoLanguageData.registered('JA').language, 'ja');
      // A code that no supported language owns is looked up as it is.
      for (final tag in ['xx', 'zh_TW', 'nl']) {
        final data = CoLanguageData.registered(tag);
        expect(data.language, tag);
        expect(data.level, CoLanguageLevel.base, reason: tag);
      }
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

    test('find English words in the record that a generator returns', () {
      // A record holds codes and labels, so its leaves are read one by one:
      // the detail of a master check left in English is `4 rows` in it. Only
      // the strict reading, of a sample whose every text is rewritten, holds
      // it to the writing system. The real reading leaves out what English
      // and Korean write alike, and the data check (c) finds the text.
      final left = ja.saas(
        rewrite: (at, text) =>
            at.slot == 'saas.ops.masterCheckDetail' ? '{n} rows' : text,
      );
      final data = ja.data(saas: left);
      const seeds = <int>[7, 436, 20261005];
      final strict = _generate(ja, data, seeds: seeds, strictProse: true);
      final leaks = strict.issues.where(
        (issue) => issue.check == CoLanguageCheck.script,
      );
      expect(leaks.map((issue) => issue.where), ['saas.masterChecks']);
      expect(leaks.single.value, matches(RegExp(r'^\d+ rows$')));
      final real = _generate(ja, data, seeds: seeds);
      expect(real.issues, isEmpty);
      // The calls that are made of codes and names say so, and say why.
      for (final name in [
        'clinic.device',
        'clinic.diagnosis',
        'saas.auditEvent',
      ]) {
        final call = allLanguageCalls.singleWhere((call) => call.name == name);
        expect(call.englishReason, isNotNull, reason: name);
        expect(call.hangulReason, isNull, reason: name);
      }
    });

    test('find a field whose name a translation changed', () {
      // The data layer says which text; a generator that fills the English
      // names only leaves the renamed one in what it writes.
      final clinic = ja.clinic(packageNameFormat: '{name} ×{回数}');
      final data = ja.data(clinic: clinic);
      expect(_where(_data(data), CoLanguageCheck.placeholder), [
        'clinic.packageNameFormat[0]',
      ]);
      final result = _generate(ja, data);
      final found = result.issues.where(
        (issue) => issue.check == CoLanguageCheck.placeholder,
      );
      expect(found.map((issue) => issue.where), contains('clinic.package'));
      expect(found.first.message, contains('{回数}'));
    });

    test('find a field behind a number sign that a generator left', () {
      // `{kind} #{numer}` is a typo of `{number}`: the generator fills the
      // English names, so the device is named `Laser #{numer}`. Only a
      // notification template writes `#{variable}` on purpose.
      final clinic = ja.clinic(
        rewrite: (at, text) => at.slot == 'clinic.texts.deviceNameFormat'
            ? '{kind} #{numer}'
            : text,
      );
      final result = _generate(ja, ja.data(clinic: clinic));
      final found = result.issues.where(
        (issue) => issue.check == CoLanguageCheck.placeholder,
      );
      expect(found.map((issue) => issue.where), contains('clinic.device'));
      expect(found.first.message, contains('{numer}'));
      expect(
        clinicCalls.where((call) => call.notificationTemplates),
        isEmpty,
        reason: 'only a saas call writes notification templates',
      );
      expect(
        saasCalls
            .where((call) => call.notificationTemplates)
            .map((call) => call.name),
        ['saas.messageTemplate'],
      );
    });

    test('keep a character of two code units whole in what it reports', () {
      // A cut inside the pair of a tooth emoji (or of a rare han character)
      // would leave half of it, which a report in JSON cannot hold.
      final bundle = _bundle(ja, (texts) {
        texts['dental.dentalProcedure'] = <String>[
          for (final _ in texts['dental.dentalProcedure']!) '${'🦷' * 12}x치과',
        ];
      });
      final result = _generate(ja, ja.data(bundle: bundle));
      final values = <String>[
        for (final issue in result.issues)
          if (issue.value != null) issue.value!,
      ];
      expect(values, isNotEmpty);
      for (final value in values) {
        expect(_wellFormed(value), isTrue, reason: value.codeUnits.join(','));
      }
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
