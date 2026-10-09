import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/ja.dart';

/// What is particular to the Japanese data: that it is the translation of the
/// English records (the same seed picks the counterpart of the same record),
/// that the three ways in read the same data, the writing (kana, full-width
/// brackets, です・ます, counters, dates), and the yen (the format and the
/// scale of every amount).

/// The seeds the alignment checks run with.
const List<int> _seeds = <int>[7, 436, 20261005];

final DateTime _now = DateTime.utc(2026, 10, 8, 9);

CoFaker _faker(String tag, int seed) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

String _role(CoFaker f, String key, int index) =>
    f.schema.record(
          <String, String>{'value': 'String'},
          roles: <String, String>{'value': key},
          streamKey: key,
          index: index,
        )['value']
        as String;

final CoL10nBundle _en = CoL10nRegistry.english;
final CoL10nBundle _ja = CoL10nRegistry.bundleFor('ja')!;
final CoFakerClinicData _enClinic = CoFakerClinicData.english;
final CoFakerClinicData _jaClinic = CoL10nClinic.clinicOf('ja')!;
final CoFakerSaasData _enSaas = CoFakerSaasData.english;
final CoFakerSaasData _jaSaas = CoL10nClinic.saasOf('ja')!;
final CoFakerClinicTexts _enTexts = _enClinic.texts!;
final CoFakerClinicTexts _jaTexts = _jaClinic.texts!;

/// Every text of the Japanese data, with where it is and how the gate judges
/// it: the bundle, the clinic data, and the SaaS data.
final List<({String where, String text, CoTextKind kind})> _texts =
    <({String where, String text, CoTextKind kind})>[
      for (final table in <CoTextTable>[
        CoLanguageTexts.ofBundle(_ja),
        CoLanguageTexts.ofClinic(_jaClinic),
        CoLanguageTexts.ofSaas(_jaSaas),
      ])
        for (final slot in table.slots.values)
          for (final row in slot.rows)
            for (final text in slot.cellsOf(row)!)
              (where: '${slot.name}[$row]', text: text, kind: slot.kind),
    ];

/// The same index of two lists: the Japanese counterpart of [english].
T _counterpart<T>(List<T> japanese, List<T> english, T value) {
  final index = english.indexOf(value);
  expect(index, isNonNegative, reason: 'English has no $value');
  return japanese[index];
}

/// The slots of the English texts and of the Japanese texts, by name: a slot is
/// a list or a map of the bundle, the clinic data, or the SaaS data.
final Map<String, CoTextSlot> _enSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_en).slots,
  ...CoLanguageTexts.ofClinic(_enClinic, resolveFallbacks: true).slots,
  ...CoLanguageTexts.ofSaas(_enSaas, resolveFallbacks: true).slots,
};
final Map<String, CoTextSlot> _jaSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_ja).slots,
  ...CoLanguageTexts.ofClinic(_jaClinic).slots,
  ...CoLanguageTexts.ofSaas(_jaSaas).slots,
};

/// The first text of every row of [slot], in the order of the data.
List<String> _column(Map<String, CoTextSlot> slots, String slot) {
  final found = slots[slot];
  expect(found, isNotNull, reason: 'no slot $slot');
  return <String>[for (final row in found!.rows) found.cellsOf(row)!.first];
}

/// Pairs that stand for the whole: a text of English, the Japanese text that
/// translates it, and the slot they are in. The same position of the slot in
/// both languages is what makes one seed pick the same record, so a Japanese
/// text on another position than its English text is a record that the seed
/// no longer translates.
const List<(String, String, String)> _anchors = <(String, String, String)>[
  ('vet.petName', 'Barley', 'むぎ'),
  ('vet.petName', 'Cloud', 'くも'),
  ('vet.breed.dog', 'Poodle', 'プードル'),
  ('vet.coatColor', 'Black', '黒'),
  ('vet.coatColor', 'Gray', 'グレー'),
  ('fx.tierName', 'Gold', 'ゴールド'),
  ('grocery.categoryName', 'Dairy', '乳製品'),
  ('grocery.categoryName', 'Seafood', '魚介'),
  ('catalog.groceryName', 'Milk', '牛乳'),
  ('catalog.groceryName', 'Spinach', 'ほうれん草'),
  ('homecare.careGrade', 'Care grade 3', '要介護3'),
  ('homecare.careGrade', 'Cognitive support grade', '要支援'),
  ('daycare.ageLabel', 'Age 4', '4歳児'),
  ('daycare.allergenLabel', 'Wheat', '小麦'),
  ('fitness.classLevelLabel', 'advanced', '上級'),
  ('fitness.classCategoryLabel', 'Yoga', 'ヨガ'),
  ('dining.menuName', 'Warm tea', '温かいお茶'),
  ('exam_prep.subjectName', 'Information security', '情報セキュリティ'),
  ('exam_prep.correctChoice', 'Hash function', 'ハッシュ関数'),
  ('exam_prep.correctChoice', 'Stack', 'スタック'),
  ('hrd.departmentName', 'Logistics', '物流部'),
  ('hrd.jobTitle', 'Team lead', 'チームリーダー'),
  ('logistics.freightType', 'Electronic parts', '電子部品'),
  ('logistics.scanEvent', 'Delivery complete', '配達完了'),
  ('hospitality.hkCheckItem', 'Check minibar', 'ミニバーの確認'),
  ('hospitality.amenityName', 'Pillow', '枕'),
  ('workplace.accountName', 'Travel (example)', '出張費（例）'),
  ('brokerage.serviceTypeName', 'Repair', '修理'),
  ('content.audioTaxonomy', 'Podcast', 'ポッドキャスト'),
  ('helpdesk.topicName', 'Integration', '連携'),
  ('travel_wallet.cityName', 'Hanoi', 'ハノイ'),
  ('meetup.interestTag', 'Hiking', '登山'),
  ('clinic.specialties.name', 'Dermatology', '皮膚科'),
  ('clinic.specialties.name', 'Pediatrics', '小児科'),
  ('clinic.staffRoles', 'Front Desk', '受付'),
  ('clinic.staffRoles', 'Medical Director', '院長'),
  ('clinic.labels', 'No-show', '無断キャンセル'),
  ('clinic.labels', 'Male', '男性'),
  ('clinic.procedures.name', 'Acne extraction', 'ニキビ圧出'),
  ('clinic.procedures.name', 'Medical certificate', '診断書'),
  ('clinic.diagnoses.name', 'Rosacea, unspecified', '酒さ（詳細不明）'),
  ('clinic.drugStems', 'Seraton', 'セラトン'),
  ('clinic.drugForms.form', ' ointment', '軟膏'),
  ('clinic.ops.weekdayNames', 'Mon', '月'),
  ('clinic.ops.weekdayNames', 'Sun', '日'),
  ('clinic.texts.insurers', 'Clearbrook Health', 'クリアブルック医療保険'),
  ('clinic.texts.labels', 'Grandchild', '孫'),
  ('clinic.ops.labels', 'Withdrawn', '撤回'),
  ('clinic.ops.rooms.name', 'Checkout', '会計'),
  ('saas.plans.name', 'Enterprise', 'エンタープライズ'),
  ('saas.labels', 'Past due', '支払い遅延'),
  ('saas.labels', 'Sent via fallback', '代替送信済み'),
  ('saas.ops.operatorRoles', 'Viewer', '閲覧者'),
  ('saas.failureReasons', 'Insufficient credits', 'クレジットが不足しています'),
  (
    'saas.ops.alerts.message',
    'The nightly backup completed.',
    '夜間バックアップが完了しました。',
  ),
];

final RegExp _hangul = RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]');

/// Korean-only shapes that no value of Japanese may have: a masked resident
/// registration number, a Korean mobile number, and a business registration
/// number.
final RegExp _krOnlyShapes = RegExp(
  r'\d{6}-[1-4]\*{6}|010-0\d{3}-\d{4}|\b\d{3}-\d{2}-\d{5}\b',
);

void main() {
  group('the bundle is the translation of the English one', () {
    test('has every key, with as many texts, and the codes stay', () {
      expect(_ja.texts.keys.toSet(), _en.texts.keys.toSet());
      for (final entry in _en.texts.entries) {
        expect(
          _ja.texts[entry.key],
          hasLength(entry.value.length),
          reason: entry.key,
        );
      }
      expect(_ja.language, 'ja');
    });

    test('writes the translation of a text at the position of that text', () {
      for (final (slot, english, japanese) in _anchors) {
        final position = _column(_enSlots, slot).indexOf(english);
        expect(position, isNonNegative, reason: '$slot has no "$english"');
        expect(
          _column(_jaSlots, slot)[position],
          japanese,
          reason: '$slot #$position is "$english" in English',
        );
      }
    });

    test('picks the translation of the English record, from the same seed', () {
      final keys = <String>{};
      for (final seed in _seeds) {
        final en = _faker('en', seed);
        final ja = _faker('ja', seed);
        for (final pack in CoFakerDomains.all) {
          for (final role in pack.roles.keys) {
            final key = '${pack.name}.$role';
            final english = _en.texts[key];
            // A template (`{n}`) is not a text that the seed picks.
            if (english == null || english.any((text) => text.contains('{'))) {
              continue;
            }
            for (var i = 0; i < 12; i++) {
              final enText = _role(en, key, i);
              final rows = <int>[
                for (var row = 0; row < english.length; row++)
                  if (english[row] == enText) row,
              ];
              final candidates = <String>[
                for (final row in rows) _ja.texts[key]![row],
              ];
              if (rows.isEmpty) {
                // A child of a taxonomy (`Fruit · subtopic 1`) is the name of
                // its root in the template of the language.
                final child = RegExp(
                  r'^(.+) · subtopic (\d+)$',
                ).firstMatch(enText);
                expect(child, isNotNull, reason: '$key #$i read "$enText"');
                final root = _ja.texts[key]![english.indexOf(child!.group(1)!)];
                candidates.add(
                  _ja.texts['common.taxonomyChild']!.single
                      .replaceAll('{root}', root)
                      .replaceAll('{n}', child.group(2)!),
                );
              }
              expect(
                _role(ja, key, i),
                isIn(candidates),
                reason: '$key #$i with seed $seed',
              );
            }
            keys.add(key);
          }
        }
      }
      // Most of the keys are read by a role of a pack: the rest are read by a
      // dedicated generator, which the next test checks.
      expect(keys.length, greaterThan(150));
    });

    test('is the same record in the dedicated generators', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed);
        final ja = _faker('ja', seed);
        for (var i = 0; i < 12; i++) {
          final enPet = en.vet.pet();
          final jaPet = ja.vet.pet();
          expect(jaPet.animalKind, enPet.animalKind);
          expect(jaPet.weightKg, enPet.weightKg);
          expect(
            jaPet.name,
            _counterpart(
              _ja.texts['vet.petName']!,
              _en.texts['vet.petName']!,
              enPet.name,
            ),
          );
          expect(
            jaPet.breed,
            _counterpart(
              _ja.texts['vet.breed.${enPet.animalKind}']!,
              _en.texts['vet.breed.${enPet.animalKind}']!,
              enPet.breed,
            ),
          );
          expect(
            jaPet.coatColor,
            _counterpart(
              _ja.texts['vet.coatColor']!,
              _en.texts['vet.coatColor']!,
              enPet.coatColor,
            ),
          );
        }
        for (var i = 0; i < 9; i++) {
          final enQuestion = en.examPrep.question(index: i);
          final jaQuestion = ja.examPrep.question(index: i);
          final row = _en.texts['exam_prep.questionStem']!.indexOf(
            enQuestion.stem,
          );
          final correct = _ja.texts['exam_prep.correctChoice']![row];
          expect(jaQuestion.stem, _ja.texts['exam_prep.questionStem']![row]);
          // The answer key follows the shuffle: the same position in English
          // and in Japanese, and the choice there is the correct one.
          expect(jaQuestion.answerKeys, enQuestion.answerKeys);
          expect(jaQuestion.choices[jaQuestion.answerKeys.single - 1], correct);
          expect(jaQuestion.explanation, contains(correct));
          expect(jaQuestion.choices.toSet(), hasLength(4));
        }
      }
    });
  });

  group('the three ways in read the same data', () {
    final ways = <String, CoFaker Function()>{
      "forLanguage('ja')": () => CoFaker.forLanguage(
        'ja',
        seed: 7,
        now: _now,
        domains: CoFakerDomains.all,
      ),
      "locale: 'ja'": () => CoFaker(
        locale: 'ja',
        seed: 7,
        now: _now,
        domains: CoFakerDomains.all,
      ),
      "locale: 'ja_JP'": () => CoFaker(
        locale: 'ja_JP',
        seed: 7,
        now: _now,
        domains: CoFakerDomains.all,
      ),
      "locale: 'ja-jp'": () => CoFaker(
        locale: 'ja-jp',
        seed: 7,
        now: _now,
        domains: CoFakerDomains.all,
      ),
    };

    test(
      'read the Japanese bundle and the registered clinic and SaaS data',
      () {
        for (final entry in ways.entries) {
          final f = entry.value();
          expect(f.language, 'ja', reason: entry.key);
          expect(f.l10n.language, 'ja', reason: entry.key);
          expect(f.clinic.data, same(_jaClinic), reason: entry.key);
          expect(f.saas.data, same(_jaSaas), reason: entry.key);
        }
      },
    );

    test('write the same text for every role that the bundle gives', () {
      final reference = ways.values.first();
      var compared = 0;
      for (final entry in ways.entries) {
        final f = entry.value();
        for (final pack in CoFakerDomains.all) {
          for (final role in pack.roles.keys) {
            final key = '${pack.name}.$role';
            final texts = _ja.texts[key];
            if (texts == null || texts.length < 2) continue;
            for (var i = 0; i < 4; i++) {
              expect(
                _role(f, key, i),
                _role(reference, key, i),
                reason: '${entry.key} $key #$i',
              );
              compared++;
            }
          }
        }
      }
      expect(compared, greaterThan(400));
    });

    test('write the same clinic and SaaS text and amounts', () {
      String describe(CoFaker f) {
        final date = DateTime.utc(2026, 10, 8);
        return <Object?>[
          for (var i = 0; i < 6; i++) f.clinic.chartMemo(),
          for (var i = 0; i < 6; i++) f.clinic.diagnosis(),
          for (var i = 0; i < 6; i++) f.clinic.procedure(),
          for (var i = 0; i < 4; i++) f.clinic.package(),
          for (var i = 0; i < 4; i++) f.clinic.soap(),
          f.clinic.consentForm(),
          f.clinic.counselSession(),
          f.clinic.closureNotice(date: date, clinicName: 'あおぞら内科クリニック'),
          f.clinic.paymentMessage(code: 'declined'),
          f.clinic.money(1200),
          for (var i = 0; i < 4; i++) f.saas.plan(),
          for (var i = 0; i < 4; i++) f.saas.messageTemplate(),
          for (var i = 0; i < 3; i++) f.saas.notice(),
          f.saas.money(12000),
        ].join('\n');
      }

      final reference = describe(ways.values.first());
      for (final entry in ways.entries) {
        expect(describe(entry.value()), reference, reason: entry.key);
      }
    });
  });

  group('the writing is Japanese', () {
    test('has kana in most texts, and no Hangul', () {
      final prose = <String>[
        for (final item in _texts)
          if (item.kind == CoTextKind.text &&
              RegExp(r'\p{L}', unicode: true).hasMatch(item.text))
            item.text,
      ];
      final withKana = prose
          .where((text) => RegExp('[぀-ヿ]').hasMatch(text))
          .length;
      // The gate asks for a fifth: Japanese has a kana in most sentences.
      expect(withKana / prose.length, greaterThan(0.6));
      for (final item in _texts) {
        expect(_hangul.hasMatch(item.text), isFalse, reason: item.where);
      }
    });

    test('writes katakana in full width, never half width', () {
      final halfWidth = RegExp('[｡-ﾟ]');
      for (final item in _texts) {
        expect(halfWidth.hasMatch(item.text), isFalse, reason: item.where);
      }
    });

    test('writes brackets, question marks, and colons in full width', () {
      final ascii = RegExp(r'[?!]|\((例|架空)\)|(例|架空)\)');
      for (final item in _texts) {
        expect(ascii.hasMatch(item.text), isFalse, reason: item.where);
        // A fictional name or an example is marked in full-width brackets.
        if (item.text.contains('架空）') || item.text.contains('（例')) {
          expect(
            item.text,
            anyOf(contains('（架空）'), contains('（例）')),
            reason: item.where,
          );
        }
      }
      expect(jaSafety.fictionalMarker, '（架空）');
      for (final key in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
      ]) {
        for (final text in _ja.texts[key]!) {
          expect(text, endsWith(jaSafety.fictionalMarker), reason: key);
        }
      }
    });

    test('is polite, です・ます, in every sentence, a story included', () {
      // Every sentence of a text ends in a polite form, once a trailing link
      // variable, `（例）`, or question mark is set aside.
      final polite = RegExp(
        r'(です|ます|ません|ました|でした|ください|ましょう|ますか|ませんか|ですか|ましたか|でしたか'
        r'|こんにちは)$',
      );
      var sentences = 0;
      for (final item in _texts) {
        if (item.kind != CoTextKind.text) continue;
        // A text that holds a full stop is a text of sentences; the question
        // of a questionnaire is one sentence too.
        if (!item.text.contains('。') && !item.text.endsWith('？')) continue;
        for (final sentence in item.text.split('。')) {
          // A field that a generator fills with a sentence of its own.
          if (sentence.isEmpty || RegExp(r'^\{\w+\}$').hasMatch(sentence)) {
            continue;
          }
          final core = sentence
              .replaceAll(RegExp(r'[：\s]*#\{\w+\}$'), '')
              .replaceAll(RegExp(r'（[^（）]*）$'), '')
              .replaceAll(RegExp(r'？$'), '');
          expect(core, matches(polite), reason: '${item.where}: ${item.text}');
          sentences++;
        }
      }
      expect(sentences, greaterThan(200));
    });

    test('writes the honorific, the counters, and the loanwords one way', () {
      // 様 follows a patient who is named; さん follows a colleague.
      for (final note in _jaTexts.teamNotes) {
        expect(note, contains('{patient}様'));
        expect(note, isNot(contains('患者さん')));
      }
      expect(_jaTexts.nameMentionFormat, '@{name}さん');
      expect(_jaTexts.staffMentionFormat, contains('{name}さん'));
      // The counters: 名 for a person, 回 for a time, 件 for a record.
      expect(_ja.texts['dining.partyLabel'], <String>['{n}名様']);
      expect(_jaClinic.packageNameFormat, '{name} {sessions}回券');
      expect(_jaClinic.ops!.compoundItemFormat, '{name} {sessions}回');
      for (final text in _jaSaas.ops!.tenantActivities) {
        expect(text, contains(RegExp('[名件]')));
      }
      expect(_jaTexts.deviceNameFormat, '{kind} {number}号機');
      // A loanword keeps the long-vowel mark: the printer, the router, and
      // the coordinator, never `プリンタ` or `コーディネータ`.
      expect(_jaTexts.labels['labelPrinter'], 'ラベルプリンター');
      expect(_jaClinic.staffRoles['coordinator'], 'コーディネーター');
      expect(_ja.texts['exam_prep.correctChoice'], contains('ルーター'));
    });

    test('writes a closure notice with the date and the weekday of Japan', () {
      final weekday = RegExp(r'\d{1,2}月\d{1,2}日（[月火水木金土日]）');
      for (final seed in _seeds) {
        final f = _faker('ja', seed);
        for (var day = 1; day <= 28; day += 3) {
          final date = DateTime.utc(2026, 10, day);
          final notice = f.clinic.closureNotice(date: date);
          expect(notice.holiday, isNull);
          expect(notice.title, matches(RegExp('^${weekday.pattern}休診のお知らせ\$')));
          expect(
            notice.body,
            matches(
              RegExp(
                'は${weekday.pattern}、.+のため休診いたします。'
                '${weekday.pattern}から通常診療を行います。\$',
              ),
            ),
          );
          // October 8, 2026 is a Thursday.
          if (day == 8) expect(notice.title, '10月8日（木）休診のお知らせ');
        }
      }
      expect(_jaClinic.ops!.dateRangeFormat, '{from}〜{to}');
      expect(_jaClinic.ops!.weekdayNames, <String>[
        '月',
        '火',
        '水',
        '木',
        '金',
        '土',
        '日',
      ]);
    });

    test('names a clinic by its prefix and its specialty, with no space', () {
      final f = _faker('ja', 7);
      for (var i = 0; i < 40; i++) {
        expect(
          f.clinic.clinicName(),
          matches(RegExp(r'^[^\s]+(皮膚科|形成外科|内科|小児科)クリニック$|ファミリークリニック$')),
        );
      }
    });
  });

  group('the yen', () {
    test('is JPY, written ¥1,200 with no decimals, as the country says', () {
      final japan = CoFakerCountries.japan;
      for (final currency in <CoCurrencyFormat>[
        _jaClinic.currency,
        _jaSaas.currency,
      ]) {
        expect(currency.code, japan.currencyCode);
        expect(currency.symbol, japan.currencySymbol);
        expect(currency.fractionDigits, japan.currencyMinorUnits);
        expect(currency.format(1200), '¥1,200');
        expect(currency.format(-80), '-¥80');
        expect(currency.format(1234567), '¥1,234,567');
      }
      final f = _faker('ja', 7);
      expect(f.clinic.money(1200), '¥1,200');
      expect(f.saas.money(12000), '¥12,000');
      expect(f.clinic.counselSession().summary, contains('¥'));
    });

    test('scales the prices, the roundings, and the thresholds in yen', () {
      final scale = _jaClinic.priceScale;
      expect(scale.priceRounding, 500);
      expect(scale.packageRounding, 1000);
      expect(scale.prepaidStep, 1000);
      // The finest unit is 10 yen, for a discount, a split share, and a point.
      for (final unit in <int>[
        scale.adjustmentUnit,
        scale.splitRounding,
        scale.pointUnit,
      ]) {
        expect(unit, 10);
      }
      for (final spec in _jaClinic.procedures) {
        final english = _enClinic.procedures.firstWhere(
          (p) => p.code == spec.code,
        );
        expect(spec.taxable, english.taxable, reason: spec.code);
        expect(spec.minPrice % scale.priceRounding, 0, reason: spec.code);
        expect(spec.minPrice, greaterThanOrEqualTo(english.minPrice * 20));
        expect(spec.maxPrice, greaterThan(spec.minPrice), reason: spec.code);
      }
      expect(scale.quoteMin, lessThan(scale.quoteMax));
    });

    test('generates every amount of the clinic in yen units', () {
      for (final seed in _seeds) {
        final f = _faker('ja', seed);
        final clinic = f.clinic;
        for (var i = 0; i < 60; i++) {
          final procedure = clinic.procedure();
          final spec = _jaClinic.procedures.firstWhere(
            (p) => p.code == procedure.code,
          );
          expect(procedure.price % 500, 0, reason: procedure.code);
          expect(
            procedure.price,
            inInclusiveRange(spec.minPrice, spec.maxPrice),
          );
          expect(clinic.package().price % 1000, 0);
          expect(clinic.prepaidBalance() % 1000, 0);
          expect(clinic.pointTransaction().amount % 10, 0);
          for (final kind in <String>['discount', 'coupon', 'point']) {
            final line = clinic.adjustment(subtotal: 123450, kind: kind);
            expect(line.amount % 10, 0, reason: kind);
            expect(line.amount, lessThanOrEqualTo(0));
          }
          final session = clinic.counselSession();
          expect(session.quotedPrice % 500, 0);
          expect(session.packagePrice % 1000, 0);
        }
        // The rounding adjustment cuts the remainder below 10 yen.
        expect(clinic.adjustment(subtotal: 12345, kind: 'rounding').amount, -5);
        final shares = clinic.splitPayment(amount: 123450);
        expect(shares.fold<int>(0, (sum, p) => sum + p.amount), 123450);
        for (final share in shares) {
          expect(share.amount % 10, 0);
        }
      }
    });

    test('generates every amount of the SaaS in yen units, with a 10% VAT', () {
      for (final seed in _seeds) {
        final saas = _faker('ja', seed).saas;
        final prices = <int>{9800, 19800, 34800, 69800};
        for (var i = 0; i < 40; i++) {
          final plan = saas.plan();
          expect(prices, contains(plan.monthlyPrice));
          final invoice = saas.invoice();
          expect(invoice.vat, (invoice.supplyAmount * 0.1).round());
          expect(invoice.total, invoice.supplyAmount + invoice.vat);
        }
        final scale = _jaSaas.priceScale;
        expect(scale.vatRate, 0.1);
        for (final entry in saas.prepaidLedger(count: 40)) {
          expect(entry.amount % 10, 0);
          if (entry.kind == 'topUp') {
            expect(scale.prepaidTopUps, contains(entry.amount));
            expect(entry.bonus, scale.bonusFor(entry.amount));
          }
        }
        for (final rows in _jaSaas.ops!.masterRows.values) {
          for (final row in rows) {
            expect(row.price == null || row.price! < 10000, isTrue);
          }
        }
      }
    });
  });

  group('no Korean-only value appears', () {
    test('the data of the language says none, and the values are Japanese', () {
      expect(_jaClinic.koreanValues, CoKoreanValues.none);
      expect(_jaSaas.koreanValues, CoKoreanValues.none);
      for (final seed in _seeds) {
        final f = _faker('ja', seed);
        for (var i = 0; i < 20; i++) {
          final patient = f.clinic.patient();
          expect(patient.rrnMasked, matches(RegExp(r'^\*{4}-\d{4}$')));
          expect(patient.address1, matches(RegExp('^[^\\s]*[都道府県]')));
          final payment = f.clinic.payment(amount: 12000, method: 'card');
          expect(payment.approvalNo, matches(RegExp(r'^\d{6}$')));
          expect(
            f.clinic.payment(amount: 12000, method: 'cash').cashReceiptNo,
            isNull,
          );
          final tenant = f.saas.tenant();
          expect(tenant.businessNumber, matches(RegExp(r'^\d{13}$')));
          for (final value in <Object?>[
            patient,
            f.clinic.staff(),
            payment,
            tenant,
            f.clinic.closureNotice(date: DateTime.utc(2026, 5, 5)),
          ]) {
            expect(_krOnlyShapes.hasMatch('$value'), isFalse, reason: '$value');
            expect(_hangul.hasMatch('$value'), isFalse, reason: '$value');
          }
        }
      }
    });

    test('a closure on a Korean holiday gives a reason, never the holiday', () {
      final f = _faker('ja', 7);
      for (final date in <DateTime>[
        DateTime.utc(2026, 9, 25),
        DateTime.utc(2027, 2, 6),
        DateTime.utc(2026, 5, 5),
        DateTime.utc(2026, 10, 9),
      ]) {
        final notice = f.clinic.closureNotice(date: date);
        expect(notice.holiday, isNull);
        expect(notice.from, notice.to);
        expect(
          notice.body,
          anyOf(contains('学会参加'), contains('内装工事'), contains('機器の定期点検')),
        );
      }
    });
  });

  group('the clinic data is the translation of the English data', () {
    test('has the lists of the English data, in the same order', () {
      expect(_jaClinic.specialties, hasLength(_enClinic.specialties.length));
      expect(
        _jaClinic.clinicNamePrefixes,
        hasLength(_enClinic.clinicNamePrefixes.length),
      );
      expect(_jaClinic.staffRoles.keys, _enClinic.staffRoles.keys);
      expect(_jaClinic.labels.keys, _enClinic.labels.keys);
      expect(
        <String>[for (final p in _jaClinic.procedures) p.code],
        <String>[for (final p in _enClinic.procedures) p.code],
      );
      expect(
        <String>[for (final d in _jaClinic.diagnoses) d.code],
        <String>[for (final d in _enClinic.diagnoses) d.code],
      );
      expect(
        <String>[for (final d in _jaClinic.diagnoses) d.nameEn],
        <String>[for (final d in _enClinic.diagnoses) d.nameEn],
      );
      for (final list in <(List<Object?>, List<Object?>)>[
        (_jaClinic.drugStems, _enClinic.drugStems),
        (_jaClinic.drugForms, _enClinic.drugForms),
        (_jaClinic.drugUsages, _enClinic.drugUsages),
        (_jaClinic.complaints, _enClinic.complaints),
        (_jaClinic.findings, _enClinic.findings),
        (_jaClinic.plans, _enClinic.plans),
        (_jaClinic.memos, _enClinic.memos),
        (_jaClinic.questions, _enClinic.questions),
        (_jaClinic.cardIssuers, _enClinic.cardIssuers),
        (_jaTexts.consentForms, _enTexts.consentForms),
        (_jaTexts.counselTopics, _enTexts.counselTopics),
        (_jaTexts.insurers, _enTexts.insurers),
        (_jaTexts.teamNotes, _enTexts.teamNotes),
      ]) {
        expect(list.$1, hasLength(list.$2.length));
      }
    });

    test('picks the counterpart of the English record from the same seed', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed).clinic;
        final ja = _faker('ja', seed).clinic;
        for (var i = 0; i < 12; i++) {
          // A clinic name is a prefix and a specialty.
          final enName = en.clinicName();
          final jaName = ja.clinicName();
          final names = <String>[
            for (var p = 0; p < _enClinic.clinicNamePrefixes.length; p++)
              for (var s = 0; s < _enClinic.specialties.length; s++)
                if (enName ==
                    '${_enClinic.clinicNamePrefixes[p]} '
                        '${_enClinic.specialties[s].clinicSuffix}')
                  '${_jaClinic.clinicNamePrefixes[p]}'
                      '${_jaClinic.specialties[s].clinicSuffix}',
          ];
          expect(jaName, names.single);

          final enProcedure = en.procedure();
          final jaProcedure = ja.procedure();
          final spec = _jaClinic.procedures.firstWhere(
            (p) => p.code == enProcedure.code,
          );
          expect(jaProcedure.code, enProcedure.code);
          expect(jaProcedure.name, spec.name);
          expect(jaProcedure.unit, spec.unit);
          expect(jaProcedure.category, spec.category);
          expect(jaProcedure.taxable, enProcedure.taxable);

          final enDiagnosis = en.diagnosis();
          final jaDiagnosis = ja.diagnosis();
          expect(jaDiagnosis.code, enDiagnosis.code);
          expect(jaDiagnosis.nameEn, enDiagnosis.nameEn);
          expect(
            jaDiagnosis.name,
            _jaClinic.diagnoses
                .firstWhere((d) => d.code == enDiagnosis.code)
                .name,
          );

          // A drug is a stem, a form, and a strength.
          final enDrug = en.drugName();
          final jaDrug = ja.drugName();
          final drugs = <String>[
            for (var s = 0; s < _enClinic.drugStems.length; s++)
              for (var f = 0; f < _enClinic.drugForms.length; f++)
                for (final strength in _enClinic.drugForms[f].strengths)
                  if (enDrug ==
                      '${_enClinic.drugStems[s]}${_enClinic.drugForms[f].form} '
                          '$strength${_enClinic.drugForms[f].unit}')
                    '${_jaClinic.drugStems[s]}${_jaClinic.drugForms[f].form} '
                        '$strength${_jaClinic.drugForms[f].unit}',
          ];
          expect(jaDrug, drugs.first);

          expect(
            ja.chartMemo(),
            _counterpart(_jaClinic.memos, _enClinic.memos, en.chartMemo()),
          );
          final enSoap = en.soap();
          final jaSoap = ja.soap();
          expect(
            jaSoap.subjective,
            _counterpart(
              _jaClinic.complaints,
              _enClinic.complaints,
              enSoap.subjective,
            ),
          );
          expect(
            jaSoap.objective,
            _counterpart(
              _jaClinic.findings,
              _enClinic.findings,
              enSoap.objective,
            ),
          );
          expect(
            jaSoap.plan,
            _counterpart(_jaClinic.plans, _enClinic.plans, enSoap.plan),
          );
          expect(
            ja.insurerName(),
            _counterpart(
              _jaTexts.insurers,
              _enTexts.insurers,
              en.insurerName(),
            ),
          );
          expect(ja.staffRole().code, en.staffRole().code);
        }
      }
    });

    test('has a consent form, feedback, and counseling of the same kind', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed).clinic;
        final ja = _faker('ja', seed).clinic;
        for (var i = 0; i < 12; i++) {
          final enForm = en.consentForm();
          final jaForm = ja.consentForm();
          final spec = _jaTexts.consentForms.firstWhere(
            (form) => form.kind == enForm.kind,
          );
          expect(jaForm.kind, enForm.kind);
          expect(jaForm.title, spec.title);
          expect(jaForm.clauses, spec.clauses);
          expect(jaForm.clauses, hasLength(enForm.clauses.length));
          expect(jaForm.disclaimer, _jaTexts.consentDisclaimer);

          final enFeedback = en.feedback();
          final jaFeedback = ja.feedback();
          expect(jaFeedback.sentiment, enFeedback.sentiment);
          expect(jaFeedback.score, enFeedback.score);
          expect(
            jaFeedback.comment,
            _counterpart(
              _jaTexts.feedback[enFeedback.sentiment]!,
              _enTexts.feedback[enFeedback.sentiment]!,
              enFeedback.comment,
            ),
          );

          final enSession = en.counselSession();
          final jaSession = ja.counselSession();
          final topic = _jaTexts.counselTopics.firstWhere(
            (t) => t.topic == enSession.topic,
          );
          expect(jaSession.topic, enSession.topic);
          expect(jaSession.procedureCode, enSession.procedureCode);
          expect(jaSession.procedure, topic.procedure);
          expect(jaSession.sessions, enSession.sessions);
          expect(jaSession.booked, enSession.booked);
          expect(jaSession.turns, hasLength(enSession.turns.length));
          expect(
            jaSession.turns.map((turn) => turn.speaker),
            enSession.turns.map((turn) => turn.speaker),
          );

          final enResult = en.integrationResult();
          final jaResult = ja.integrationResult();
          expect(jaResult.service, enResult.service);
          expect(jaResult.code, enResult.code);
          expect(jaResult.ok, enResult.ok);
          final english = _enTexts.integrationResults[enResult.service]!;
          final japanese = _jaTexts.integrationResults[enResult.service]!;
          expect(
            jaResult.message,
            japanese[english.indexWhere((r) => r.message == enResult.message)]
                .message,
          );

          final enDevice = en.device();
          final jaDevice = ja.device();
          expect(jaDevice.kind, enDevice.kind);
          expect(jaDevice.kindLabel, _jaTexts.labels[enDevice.kind]);
          expect(jaDevice.name, startsWith(jaDevice.kindLabel));
          expect(jaDevice.name, endsWith('号機'));
        }
      }
    });
  });

  group('the SaaS data is the translation of the English data', () {
    test('has the plans, templates, and notices of the English data', () {
      expect(
        <String>[for (final p in _jaSaas.plans) p.code],
        <String>[for (final p in _enSaas.plans) p.code],
      );
      for (var i = 0; i < _enSaas.plans.length; i++) {
        expect(_jaSaas.plans[i].seats, _enSaas.plans[i].seats);
        expect(
          _jaSaas.plans[i].messageCredits,
          _enSaas.plans[i].messageCredits,
        );
      }
      expect(_jaSaas.labels.keys, _enSaas.labels.keys);
      expect(_jaSaas.ops!.labels.keys, CoFakerSaasOps.english.labels.keys);
      // A notification template keeps the variables of the English one.
      final marker = RegExp(r'#\{\w+\}');
      for (var i = 0; i < _enSaas.messageTemplates.length; i++) {
        final english = _enSaas.messageTemplates[i];
        final japanese = _jaSaas.messageTemplates[i];
        expect(japanese.code, english.code);
        expect(
          marker.allMatches(japanese.body).map((m) => m.group(0)).toList()
            ..sort(),
          marker.allMatches(english.body).map((m) => m.group(0)).toList()
            ..sort(),
          reason: english.code,
        );
        // A message that greets the patient by name honors it with 様.
        if (english.body.contains('#{name}')) {
          expect(japanese.body, contains('#{name}様'), reason: english.code);
        }
      }
      expect(_jaSaas.ops!.masterCheckDetail, '{n}行');
    });

    test('picks the counterpart of the English record from the same seed', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed).saas;
        final ja = _faker('ja', seed).saas;
        for (var i = 0; i < 12; i++) {
          final enPlan = en.plan();
          final jaPlan = ja.plan();
          final spec = _jaSaas.plans.firstWhere((p) => p.code == enPlan.code);
          expect(jaPlan.code, enPlan.code);
          expect(jaPlan.name, spec.name);
          expect(jaPlan.seats, enPlan.seats);
          expect(jaPlan.messageCredits, enPlan.messageCredits);

          final enTemplate = en.messageTemplate();
          final jaTemplate = ja.messageTemplate();
          expect(jaTemplate.code, enTemplate.code);
          expect(
            jaTemplate.name,
            _jaSaas.messageTemplates
                .firstWhere((t) => t.code == enTemplate.code)
                .name,
          );

          final enNotice = en.notice();
          final jaNotice = ja.notice();
          expect(jaNotice.category, enNotice.category);
          expect(
            jaNotice.title,
            _counterpart(
              <String>[for (final n in _jaSaas.notices) n.title],
              <String>[for (final n in _enSaas.notices) n.title],
              enNotice.title,
            ),
          );

          final enEvent = en.operatorEvent();
          final jaEvent = ja.operatorEvent();
          expect(jaEvent.action, enEvent.action);
          expect(
            jaEvent.actionLabel,
            _jaSaas.ops!.operatorActions[enEvent.action]!.label,
          );
          final role = CoFakerSaasOps.english.operatorRoles.entries
              .firstWhere((entry) => entry.value == enEvent.operatorRole)
              .key;
          expect(jaEvent.operatorRole, _jaSaas.ops!.operatorRoles[role]);
        }
      }
    });
  });

  group('the language is finished', () {
    test('is localized and passes the completion gate', () {
      final data = CoLanguageData.registered('ja');
      expect(data.level, CoLanguageLevel.localized);
      final report = CoLanguageCoverage().check(data);
      expect(report.issues, isEmpty, reason: report.toMarkdown());
    });
  });
}
