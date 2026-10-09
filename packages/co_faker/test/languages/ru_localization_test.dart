import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/ru.dart';

/// What is particular to the Russian data: that it is the translation of the
/// English records (the same seed picks the counterpart of the same record),
/// that the three ways in read the same data, the writing (Cyrillic, `ё`,
/// guillemets, `вы`, the fixed markers, the forms of a number, the agreement of
/// a template), and the ruble (the format and the scale of every amount).

/// The seeds the alignment checks run with.
const List<int> _seeds = <int>[7, 436, 20261005];

/// The no-break space that Russian writes between thousands, before `₽`, and
/// between a number and its unit.
const String _nbsp = '\u00A0';

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
final CoL10nBundle _ru = CoL10nRegistry.bundleFor('ru')!;
final CoFakerClinicData _enClinic = CoFakerClinicData.english;
final CoFakerClinicData _ruClinic = CoL10nClinic.clinicOf('ru')!;
final CoFakerSaasData _enSaas = CoFakerSaasData.english;
final CoFakerSaasData _ruSaas = CoL10nClinic.saasOf('ru')!;
final CoFakerClinicTexts _enTexts = _enClinic.texts!;
final CoFakerClinicTexts _ruTexts = _ruClinic.texts!;

/// Every text of the Russian data, with where it is and how the gate judges it:
/// the bundle, the clinic data, and the SaaS data.
final List<({String where, String text, CoTextKind kind})> _texts =
    <({String where, String text, CoTextKind kind})>[
      for (final table in <CoTextTable>[
        CoLanguageTexts.ofBundle(_ru),
        CoLanguageTexts.ofClinic(_ruClinic),
        CoLanguageTexts.ofSaas(_ruSaas),
      ])
        for (final slot in table.slots.values)
          for (final row in slot.rows)
            for (final text in slot.cellsOf(row)!)
              (where: '${slot.name}[$row]', text: text, kind: slot.kind),
    ];

/// The same index of two lists: the Russian counterpart of [english].
T _counterpart<T>(List<T> russian, List<T> english, T value) {
  final index = english.indexOf(value);
  expect(index, isNonNegative, reason: 'English has no $value');
  return russian[index];
}

/// The slots of the English texts and of the Russian texts, by name: a slot is
/// a list or a map of the bundle, the clinic data, or the SaaS data.
final Map<String, CoTextSlot> _enSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_en).slots,
  ...CoLanguageTexts.ofClinic(_enClinic, resolveFallbacks: true).slots,
  ...CoLanguageTexts.ofSaas(_enSaas, resolveFallbacks: true).slots,
};
final Map<String, CoTextSlot> _ruSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_ru).slots,
  ...CoLanguageTexts.ofClinic(_ruClinic).slots,
  ...CoLanguageTexts.ofSaas(_ruSaas).slots,
};

/// The first text of every row of [slot], in the order of the data.
List<String> _column(Map<String, CoTextSlot> slots, String slot) {
  final found = slots[slot];
  expect(found, isNotNull, reason: 'no slot $slot');
  return <String>[for (final row in found!.rows) found.cellsOf(row)!.first];
}

/// Pairs that stand for the whole: a text of English, the Russian text that
/// translates it, and the slot they are in. The same position of the slot in
/// both languages is what makes one seed pick the same record, so a Russian
/// text on another position than its English text is a record that the seed
/// no longer translates.
const List<(String, String, String)> _anchors = <(String, String, String)>[
  ('fx.currencyName.USD', 'US dollar', 'Доллар США'),
  ('fx.currencyName.NPR', 'Nepalese rupee', 'Непальская рупия'),
  (
    'fx.branchName',
    'Demo airport T1 exchange',
    'Обменный пункт, аэропорт T1 (демо)',
  ),
  (
    'fx.branchName',
    'Demo Mulpare exchange',
    'Обменный пункт «Ясеневая Заводь» (демо)',
  ),
  ('fx.tierName', 'Gold', 'Золотой'),
  ('remit.countryName.US', 'United States', 'США'),
  (
    'remit.flagRule',
    'Large transfer (demo rule)',
    'Крупный перевод (демо-правило)',
  ),
  ('vet.petName', 'Cloud', 'Облачко'),
  ('vet.breed.dog', 'Poodle', 'Пудель'),
  ('vet.breed.dog', 'Mixed dog', 'Беспородная собака'),
  ('vet.coatColor', 'Gray', 'Серый'),
  ('vet.coatColor', 'Black', 'Чёрный'),
  (
    'vet.vetDrug',
    'Eye care example (fictional)',
    'Пример средства для ухода за глазами (вымышленное название)',
  ),
  ('vet.clinicRoom', 'Vaccination room', 'Прививочный кабинет'),
  ('grocery.categoryName', 'Seafood', 'Рыба и морепродукты'),
  ('grocery.categoryName', 'Dairy', 'Молочные продукты'),
  ('grocery.slotLabel', 'Evening 18:00–20:00', 'Вечером, 18:00–20:00'),
  ('catalog.groceryName', 'Milk', 'Молоко'),
  ('catalog.groceryName', 'Frozen mackerel', 'Замороженная скумбрия'),
  ('catalog.groceryUnit', '2kg', '2\u00A0кг'),
  ('catalog.commerceUnit', '3 pieces', '3\u00A0шт.'),
  ('catalog.commerceName', 'Ceramic cup', 'Керамическая чашка'),
  ('dental.dentalProcedure', 'Scaling', 'Удаление зубного камня'),
  ('dental.chairName', 'Dental chair 3', 'Стоматологическое кресло 3'),
  ('homecare.careGrade', 'Care grade 5', 'Уровень ухода 5'),
  (
    'homecare.careGrade',
    'Cognitive support grade',
    'Уровень когнитивной поддержки',
  ),
  ('travel_wallet.cityName', 'Hanoi', 'Ханой'),
  ('travel_wallet.tripName', 'Four days in Osaka', 'Четыре дня в Осаке'),
  (
    'b2b_trade.itemSpec',
    'Frozen potatoes, 10kg',
    'Замороженный картофель, 10\u00A0кг',
  ),
  (
    'group_deal.dealTitle',
    'Cotton towel group deal',
    'Совместная закупка: хлопковые полотенца',
  ),
  ('fitness.classLevelLabel', 'advanced', 'продвинутый'),
  ('fitness.classCategoryLabel', 'Reformer', 'Пилатес на реформере'),
  (
    'fitness.passName',
    '20 reformer classes (example)',
    'Абонемент на 20 занятий на реформере (пример)',
  ),
  ('space_rental.amenity', 'Water dispenser', 'Кулер с водой'),
  ('dining.menuName', 'Warm tea', 'Тёплый чай'),
  ('daycare.className', 'Star class', 'Группа «Звёздочка»'),
  ('daycare.ageLabel', 'Age 1', '1 год'),
  ('daycare.ageLabel', 'Age 2', '2 года'),
  ('daycare.ageLabel', 'Age 5', '5 лет'),
  ('daycare.allergenLabel', 'Wheat', 'Пшеница'),
  (
    'exam_prep.subjectName',
    'Information security',
    'Информационная безопасность',
  ),
  ('exam_prep.correctChoice', 'Hash function', 'Хеш-функция'),
  ('exam_prep.correctChoice', 'Stack', 'Стек'),
  (
    'exam_prep.correctChoice',
    'Least privilege',
    'Принцип наименьших привилегий',
  ),
  ('hrd.departmentName', 'Logistics', 'Логистика'),
  ('hrd.jobTitle', 'Team lead', 'Руководитель группы'),
  ('neighborhood.keyword', 'local news', 'новости района'),
  ('meetup.interestTag', 'Hiking', 'Походы'),
  (
    'meetup.cadenceLabel',
    'First Saturday each month 14:00',
    'Первая суббота месяца, 14:00',
  ),
  ('content.audioTaxonomy', 'Podcast', 'Подкаст'),
  ('helpdesk.topicName', 'Integration', 'Интеграция'),
  (
    'campaign.failReason',
    'No marketing consent (example)',
    'Нет согласия на рекламную рассылку (пример)',
  ),
  ('workplace.accountName', 'Travel (example)', 'Командировка (пример)'),
  ('workplace.shiftName', 'Weekend duty', 'Дежурство в выходные'),
  ('brokerage.serviceTypeName', 'Repair', 'Ремонт'),
  ('brokerage.skillTag', 'Dart', 'Dart'),
  ('logistics.scanEvent', 'Delivery not completed', 'Не доставлено'),
  ('logistics.freightType', 'Electronic parts', 'Электронные компоненты'),
  ('logistics.itemName', 'Brown rice 2kg', 'Бурый рис, 2\u00A0кг'),
  ('hospitality.hkCheckItem', 'Check minibar', 'Проверить минибар'),
  ('hospitality.amenityName', 'Toothbrush', 'Зубная щётка'),
  ('clinic.specialties.name', 'Dermatology', 'Дерматология'),
  ('clinic.specialties.name', 'Pediatrics', 'Педиатрия'),
  ('clinic.staffRoles', 'Front Desk', 'Администратор ресепшена'),
  ('clinic.staffRoles', 'Medical Director', 'Главный врач'),
  ('clinic.labels', 'No-show', 'Неявка'),
  ('clinic.labels', 'Male', 'Мужской'),
  ('clinic.procedures.name', 'Acne extraction', 'Экстракция комедонов'),
  ('clinic.procedures.name', 'Medical certificate', 'Медицинская справка'),
  ('clinic.diagnoses.name', 'Rosacea, unspecified', 'Розацеа неуточнённая'),
  ('clinic.drugStems', 'Seraton', 'Сератон'),
  ('clinic.drugForms.form', ' ointment', ', мазь'),
  ('clinic.ops.weekdayNames', 'Mon', 'пн'),
  ('clinic.ops.weekdayNames', 'Sun', 'вс'),
  ('clinic.texts.insurers', 'Clearbrook Health', 'СК «Прозрачный Ручей»'),
  ('clinic.texts.labels', 'Grandchild', 'Внук / внучка'),
  ('clinic.ops.labels', 'Withdrawn', 'Согласие отозвано'),
  ('clinic.ops.rooms.name', 'Checkout', 'Касса'),
  ('saas.plans.name', 'Enterprise', 'Корпоративный'),
  ('saas.labels', 'Past due', 'Оплата просрочена'),
  ('saas.labels', 'Sent via fallback', 'Отправлено запасным каналом'),
  ('saas.ops.operatorRoles', 'Viewer', 'Только просмотр'),
  ('saas.failureReasons', 'Insufficient credits', 'Недостаточно кредитов'),
  (
    'saas.ops.alerts.message',
    'The nightly backup completed.',
    'Ночное резервное копирование завершено.',
  ),
];

final RegExp _hangul = RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]');

/// Korean-only shapes that no value of Russian may have: a masked resident
/// registration number, a Korean mobile number, and a business registration
/// number.
final RegExp _krOnlyShapes = RegExp(
  r'\d{6}-[1-4]\*{6}|010-0\d{3}-\d{4}|\b\d{3}-\d{2}-\d{5}\b',
);

const String _cyr = 'а-яёА-ЯЁ';

/// Whether [pattern] has no match in the text of any item that passes [where].
List<String> _matching(
  RegExp pattern, {
  bool Function(CoTextKind kind)? where,
}) => <String>[
  for (final item in _texts)
    if ((where == null || where(item.kind)) && pattern.hasMatch(item.text))
      '${item.where}: ${item.text}',
];

/// The words that Russian writes with `ё` in the texts of this data, each as a
/// stem with `ё` and the same stem with `е` (a pattern), at the start of a
/// word: a text writes the first, never the second. A form that Russian writes
/// with `е` itself stays out of the pattern (`легко`, `черновик`, `платежи`).
const List<(String, String)> _yoWords = <(String, String)>[
  ('ещё', 'еще'),
  ('тёмн', 'темн'),
  ('тёпл', 'тепл'),
  ('отёк', 'отек'),
  ('неуточнённ', 'неуточненн'),
  // `легко` (easily) is written with `е`; `лёгкий` (light) with `ё`.
  ('лёгк', 'легк(?!о)'),
  // `черновик` (a draft) is written with `е`; `чёрный` (black) with `ё`.
  ('чёрн', 'черн(?!ов)'),
  ('трёх', 'трех'),
  // `звезда` is written with `е`; its diminutive `звёздочка` with `ё`.
  ('звёздочк', 'звездочк'),
  ('ребёнок', 'ребенок'),
  ('приём', 'прием'),
  ('учётн', 'учетн'),
  // `платежи` and `платежа` are written with `е`; `платёж` and `платёжный`
  // with `ё`.
  ('платёж', 'платеж(?![аиеоу])'),
  ('автоплатёж', 'автоплатеж(?![аиеоу])'),
  ('щётк', 'щетк'),
  ('бельё', 'белье'),
];

/// The form of a noun that [n] needs after it, in the nominative: 0 for `1`
/// (`1 год`), 1 for `2`, `3`, and `4` (`2 года`), and 2 for the rest (`5 лет`,
/// `11 лет`, `21` is `1` again).
int _form(int n) {
  final last = n % 10;
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 2;
  if (last == 1) return 0;
  if (last >= 2 && last <= 4) return 1;
  return 2;
}

/// The Russian form of a ruble amount that the data writes.
String _rub(String digits) => '$digits\u00A0₽';

void main() {
  group('the entry points of Russian', () {
    // A language setting, a language code, and a country locale all read the
    // Russian domain text, clinic data, and SaaS data.
    final ways = <String, CoFaker Function()>{
      "forLanguage('ru')": () => _faker('ru', 7),
      "forLanguage('ru-RU')": () => _faker('ru-RU', 7),
      "forLanguage('ru_RU.UTF-8')": () => _faker('ru_RU.UTF-8', 7),
      "locale: 'ru'": () => _locale('ru', 7),
      "locale: 'ru_RU'": () => _locale('ru_RU', 7),
      "locale: 'ru-ru'": () => _locale('ru-ru', 7),
      // The spellings that a setting of an operating system or a browser has.
      "locale: 'RU'": () => _locale('RU', 7),
      "locale: 'ru_RU.UTF-8'": () => _locale('ru_RU.UTF-8', 7),
    };

    test('read the Russian bundle and the registered clinic and SaaS data', () {
      for (final entry in ways.entries) {
        final f = entry.value();
        expect(f.language, 'ru', reason: entry.key);
        expect(f.l10n.language, 'ru', reason: entry.key);
        expect(f.clinic.data, same(_ruClinic), reason: entry.key);
        expect(f.saas.data, same(_ruSaas), reason: entry.key);
        for (final key in _ru.texts.keys) {
          expect(f.l10n.list(key), _ru.texts[key], reason: '${entry.key} $key');
        }
      }
    });

    test('write the same text for every role that the bundle gives', () {
      final reference = ways.values.first();
      var compared = 0;
      for (final entry in ways.entries) {
        final f = entry.value();
        for (final pack in CoFakerDomains.all) {
          for (final role in pack.roles.keys) {
            final key = '${pack.name}.$role';
            final texts = _ru.texts[key];
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
          f.clinic.closureNotice(
            date: date,
            clinicName: 'Детская клиника «Образец»',
          ),
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

    test('are the Russian data and not the English one', () {
      for (final tag in <String>['ru', 'ru_RU']) {
        final f = _locale(tag, 7);
        expect(f.clinic.data, isNot(same(CoFakerClinicData.english)));
        expect(f.saas.data, isNot(same(CoFakerSaasData.english)));
        expect(
          _ru.texts['dental.dentalProcedure'],
          contains(_role(f, 'dental.dentalProcedure', 0)),
        );
        expect(
          _en.texts['dental.dentalProcedure'],
          isNot(contains(_role(f, 'dental.dentalProcedure', 0))),
        );
        expect(f.clinic.money(1234), isNot(contains(r'$')));
      }
      // A language that has no data, and never will, keeps the English one.
      final other = _locale('nl', 7);
      expect(other.clinic.data, same(CoFakerClinicData.english));
      expect(other.saas.data, same(CoFakerSaasData.english));
      expect(
        _en.texts['dental.dentalProcedure'],
        contains(_role(other, 'dental.dentalProcedure', 0)),
      );
    });
  });

  group('the bundle is the translation of the English one', () {
    test('has every key, with as many texts, and the codes stay', () {
      expect(_ru.texts.keys.toSet(), _en.texts.keys.toSet());
      for (final entry in _en.texts.entries) {
        expect(
          _ru.texts[entry.key],
          hasLength(entry.value.length),
          reason: entry.key,
        );
      }
      expect(_ru.language, 'ru');
    });

    test('writes the translation of a text at the position of that text', () {
      for (final (slot, english, russian) in _anchors) {
        final position = _column(_enSlots, slot).indexOf(english);
        expect(position, isNonNegative, reason: '$slot has no "$english"');
        expect(
          _column(_ruSlots, slot)[position],
          russian,
          reason: '$slot #$position is "$english" in English',
        );
      }
    });

    test('picks the translation of the English record, from the same seed', () {
      final keys = <String>{};
      for (final seed in _seeds) {
        final en = _faker('en', seed);
        final ru = _faker('ru', seed);
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
                for (final row in rows) _ru.texts[key]![row],
              ];
              if (rows.isEmpty) {
                // A child of a taxonomy (`Fruit · subtopic 1`) is the name of
                // its root in the template of the language.
                final child = RegExp(
                  r'^(.+) · subtopic (\d+)$',
                ).firstMatch(enText);
                expect(child, isNotNull, reason: '$key #$i read "$enText"');
                final root = _ru.texts[key]![english.indexOf(child!.group(1)!)];
                candidates.add(
                  _ru.texts['common.taxonomyChild']!.single
                      .replaceAll('{root}', root)
                      .replaceAll('{n}', child.group(2)!),
                );
              }
              expect(
                _role(ru, key, i),
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
        final ru = _faker('ru', seed);
        for (var i = 0; i < 12; i++) {
          final enPet = en.vet.pet();
          final ruPet = ru.vet.pet();
          expect(ruPet.animalKind, enPet.animalKind);
          expect(ruPet.weightKg, enPet.weightKg);
          expect(
            ruPet.name,
            _counterpart(
              _ru.texts['vet.petName']!,
              _en.texts['vet.petName']!,
              enPet.name,
            ),
          );
          expect(
            ruPet.breed,
            _counterpart(
              _ru.texts['vet.breed.${enPet.animalKind}']!,
              _en.texts['vet.breed.${enPet.animalKind}']!,
              enPet.breed,
            ),
          );
          expect(
            ruPet.coatColor,
            _counterpart(
              _ru.texts['vet.coatColor']!,
              _en.texts['vet.coatColor']!,
              enPet.coatColor,
            ),
          );
        }
        for (final code in <String>['USD', 'JPY', 'EUR', 'CNY', 'THB']) {
          expect(
            ru.fx.currency(code: code).name,
            _ru.texts['fx.currencyName.$code']!.single,
          );
        }
        for (var i = 0; i < 9; i++) {
          final enQuestion = en.examPrep.question(index: i);
          final ruQuestion = ru.examPrep.question(index: i);
          final row = _en.texts['exam_prep.questionStem']!.indexOf(
            enQuestion.stem,
          );
          final correct = _ru.texts['exam_prep.correctChoice']![row];
          expect(ruQuestion.stem, _ru.texts['exam_prep.questionStem']![row]);
          // The answer key follows the shuffle: the same position in English
          // and in Russian, and the choice there is the correct one.
          expect(ruQuestion.answerKeys, enQuestion.answerKeys);
          expect(ruQuestion.choices[ruQuestion.answerKeys.single - 1], correct);
          expect(ruQuestion.explanation, contains(correct));
          expect(ruQuestion.choices.toSet(), hasLength(4));
        }
      }
    });

    test('names the two creators of its own, never the Korean ones', () {
      expect(_ru.texts['fandom.creatorName'], <String>[
        'Сад песочных часов',
        'Небесная нить',
      ]);
      for (final text in _ru.texts['fandom.creatorName']!) {
        expect(_hangul.hasMatch(text), isFalse);
      }
    });
  });

  group('the writing is Russian', () {
    test('is Cyrillic in the texts, and has no Hangul', () {
      // The words of a text, without its fields (`{name}`, `#{ссылка}`).
      String words(String text) => text.replaceAll(RegExp(r'#?\{[^{}]*\}'), '');
      final prose = <String>[
        for (final item in _texts)
          if (item.kind == CoTextKind.text &&
              RegExp(r'\p{L}', unicode: true).hasMatch(words(item.text)))
            words(item.text),
      ];
      final withCyrillic = prose
          .where((text) => RegExp('[а-яёА-ЯЁ]').hasMatch(text))
          .length;
      // The gate asks for 95%; what is left are the acronyms, the names of a
      // technology, and the card networks, listed in `allowSameAsEnglish`.
      expect(withCyrillic / prose.length, greaterThan(0.97));
      final latin = <String>[
        for (final text in prose)
          if (!RegExp('[а-яёА-ЯЁ]').hasMatch(text)) text,
      ];
      expect(latin.toSet().length, lessThanOrEqualTo(24), reason: '$latin');
      for (final item in _texts) {
        expect(_hangul.hasMatch(item.text), isFalse, reason: item.where);
      }
    });

    test('writes `ё` wherever the word has it, one way in every text', () {
      for (final (_, e) in _yoWords) {
        final pattern = RegExp('(?<![$_cyr])$e', caseSensitive: false);
        expect(_matching(pattern), isEmpty, reason: 'a text writes $e');
      }
      // The stems that the data does write are there, so that the check above
      // is not an empty one.
      for (final (yo, _) in _yoWords) {
        final pattern = RegExp('(?<![$_cyr])$yo', caseSensitive: false);
        // No text of the data needs `ещё`, which only the check above guards.
        if (yo == 'ещё') continue;
        expect(_matching(pattern), isNotEmpty, reason: 'no text writes $yo');
      }
      expect(
        _texts.where((item) => item.text.contains('ё')).length,
        greaterThan(60),
      );
      // The data of the basic modules of Russia writes `ё` the same way.
      expect(_ru.texts['vet.coatColor'], contains('Чёрный'));
      expect(_ruClinic.diagnoses[3].name, 'Атопический дерматит неуточнённый');
    });

    test(
      'quotes a name with guillemets, and writes no other quotation mark',
      () {
        for (final item in _texts) {
          expect(item.text, isNot(contains('"')), reason: item.where);
          expect(
            item.text,
            isNot(matches(RegExp('[“”„‟]'))),
            reason: item.where,
          );
          expect(
            '«'.allMatches(item.text).length,
            '»'.allMatches(item.text).length,
            reason: item.where,
          );
        }
        // A coined name is a Russian name in guillemets after a common noun.
        expect(
          _ru.texts['dining.restaurantName']!.first,
          startsWith('Лапшичная «'),
        );
        expect(_ruClinic.clinicNameFormat, '{suffix} «{prefix}»');
      },
    );

    test('writes a no-break space between a number and its unit', () {
      // A regular space before `%`, `°C`, a unit of measure, or a unit of time
      // would let the number end a line and the unit begin the next.
      final loose = RegExp(
        r'\d [%°]|\d (?:г|кг|мг|мл|л|мм|шт\.|мг/дл|минут|минуты|час|часа|часов|дней)'
        '(?![а-яёА-ЯЁ])',
      );
      expect(_matching(loose), isEmpty);
      // A thousand is written with a no-break space, never with a comma or a
      // dot between the groups.
      expect(_matching(RegExp(r'\d,\d{3}(?!\d)|\d\.\d{3}(?!\d)')), isEmpty);
      expect(_ru.texts['catalog.groceryUnit']!.first, '500\u00A0г');
      expect(_ruTexts.deviceNameFormat, '{kind} №\u00A0{number}');
    });

    test('marks a fictional name, a sample, and a demo one way', () {
      // One tag after a fictional name, and a question has its own noun.
      const markers = <String>[
        '(вымышленное название)',
        '(вымышленный вопрос)',
      ];
      for (final item in _texts) {
        for (final match in RegExp(r'\(вымышл[^)]*\)').allMatches(item.text)) {
          expect(markers, contains(match.group(0)), reason: item.where);
        }
        for (final match in RegExp(
          r'\((?:пример|демо)[^)]*\)',
        ).allMatches(item.text)) {
          expect(
            <String>['(пример)', '(демо)', '(демо-правило)'],
            contains(match.group(0)),
            reason: item.where,
          );
        }
        // The tags of English and Korean are not written.
        expect(item.text, isNot(contains('(fictional)')), reason: item.where);
        expect(item.text, isNot(contains('(example)')), reason: item.where);
        expect(item.text, isNot(contains('(가상)')), reason: item.where);
      }
      expect(ruSafety.fictionalMarker, '(вымышленное название)');
      expect(ruSafety.generalInfoPrefix, 'Пример общей информации');
      for (final key in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
      ]) {
        for (final text in _ru.texts[key]!) {
          expect(text, endsWith(ruSafety.fictionalMarker), reason: key);
        }
      }
      for (final key in <String>[
        'brokerage.qnaAnswerGeneric',
        'brokerage.consultNoteGeneric',
      ]) {
        for (final text in _ru.texts[key]!) {
          expect(text, startsWith(ruSafety.generalInfoPrefix), reason: key);
        }
      }
    });

    test('speaks to a patient with `вы`, in the plural imperative', () {
      // `ты` and its forms are never written.
      final ty = RegExp(
        '(?<![$_cyr])(?:ты|тебя|тебе|тобой|твой|твоя|твоё|твои|твоих)(?![$_cyr])',
        caseSensitive: false,
      );
      expect(_matching(ty), isEmpty);
      // `Пожалуйста,` opens a request in the form of `вы`: `позвоните`,
      // `соблюдайте`, `общайтесь`.
      var requests = 0;
      for (final item in _texts) {
        for (final match in RegExp(
          'Пожалуйста, (?:не )?([$_cyr]+)',
        ).allMatches(item.text)) {
          expect(
            match.group(1),
            matches(RegExp('.*(?:те|тесь)\$')),
            reason: '${item.where}: ${item.text}',
          );
          requests++;
        }
      }
      expect(requests, greaterThan(12));
      // The patient is addressed as `вы` (`вас`, `вам`, `ваш`, `ваш приём`).
      expect(
        _matching(RegExp('(?<![$_cyr])(?:вас|вам|ваш|ваша|вами)(?![$_cyr])')),
        isNotEmpty,
      );
    });

    test('writes a first-person line with no gender', () {
      // The past tense of the first person has a gender (`я сообщил`,
      // `я сообщила`), so a line of a patient is written in the present or the
      // future tense, or without a verb.
      final past = RegExp('(?<![$_cyr])[Яя]\\s+[$_cyr]+(?:л|ла)(?![$_cyr])');
      expect(_matching(past), isEmpty);
      expect(
        _ruClinic.texts!.consentForms.first.clauses.last,
        'Сведения о принимаемых лекарствах, аллергиях и беременности мной указаны.',
      );
      expect(_ru.texts['meetup.joinAnswer'], <String>[
        'Хочу присоединиться к занятиям в этом месяце.',
        'Могу участвовать по утрам в выходные.',
      ]);
    });

    test('writes the time on the 24-hour clock and the date with dots', () {
      for (final item in _texts) {
        for (final match in RegExp(
          r'(\d{1,2}):(\d{2})',
        ).allMatches(item.text)) {
          expect(int.parse(match.group(1)!), lessThan(24), reason: item.where);
          expect(int.parse(match.group(2)!), lessThan(60), reason: item.where);
        }
        expect(item.text, isNot(matches(RegExp(r'\b[AP]M\b'))));
      }
      expect(_ruClinic.ops!.dateFormat, '{day}.{month} ({weekday})');
      expect(_ruClinic.ops!.dateRangeFormat, 'с {from} по {to}');
      expect(_ruClinic.ops!.weekdayNames, <String>[
        'пн',
        'вт',
        'ср',
        'чт',
        'пт',
        'сб',
        'вс',
      ]);
    });
  });

  group('a number and a template that a value fills', () {
    test(
      'write the form that a fixed number needs: 1, 2 to 4, and 5 and more',
      () {
        // The three forms of Russian after a number: `1 год`, `2 года`, `5 лет`.
        const years = <String>['год', 'года', 'лет'];
        final ages = _ru.texts['daycare.ageLabel']!;
        for (var n = 1; n <= ages.length; n++) {
          expect(ages[n - 1], '$n ${years[_form(n)]}');
        }
        expect(
          <String>[for (var n = 1; n <= 5; n++) years[_form(n)]],
          <String>['год', 'года', 'года', 'года', 'лет'],
        );
        expect(
          <int>[
            for (final n in <int>[11, 12, 21, 22, 25]) _form(n),
          ],
          <int>[2, 2, 0, 1, 2],
        );
        // A unit is a fixed text: `1 пара`, `3 шт.`, and a pass has its number
        // in the genitive plural that `на` asks for, `10 занятий`, `20 занятий`.
        expect(_ru.texts['catalog.commerceUnit'], <String>[
          '1\u00A0пара',
          '1\u00A0коробка',
          '3\u00A0шт.',
          '1\u00A0шт.',
          '200\u00A0г',
        ]);
        final passes = _ru.texts['fitness.passName']!;
        expect(passes[0], contains('на 10 занятий'));
        expect(passes[1], contains('на 20 занятий'));
        // The alerts of the SaaS have a fixed number after a preposition.
        final alerts = <String>[
          for (final alert in _ruSaas.ops!.alerts) alert.message,
        ];
        expect(alerts[0], endsWith('у 3 клиник.'));
        expect(alerts[1], contains('по 7 счетам'));
        expect(alerts[2], startsWith('У 5 клиник'));
        expect(
          _ruSaas.ops!.operatorActions['credit.grant']!.summary,
          contains('1\u00A0000 кредитов'),
        );
      },
    );

    test('put a count after its label, and never before a noun', () {
      // `Гостей: 4`, `Заявок отправлено: 12`, `Строк: 3`, `Подтема 2`: a noun
      // that stood after the number would have to agree with it.
      final counted = RegExp('\\{(?:n|m|sessions|number)\\}[ \u00A0]+[$_cyr]');
      expect(_matching(counted), isEmpty);
      expect(_ru.texts['dining.partyLabel'], <String>['Гостей: {n}']);
      expect(_ru.texts['common.taxonomyChild'], <String>[
        '{root} · подтема {n}',
      ]);
      expect(_ru.texts['workplace.sprintName'], <String>['Спринт {n}']);
      expect(_ruSaas.ops!.masterCheckDetail, 'Строк: {n}');
      expect(_ruClinic.packageNameFormat, '{name} ×{sessions}');
      expect(_ruClinic.ops!.compoundItemFormat, '{name} ×{sessions}');
      for (final text in _ruSaas.ops!.tenantActivities) {
        expect(text, endsWith(': {n}'));
      }
      // A generated count reads right whatever the number is.
      final f = _faker('ru', 7);
      for (var n = 1; n <= 25; n++) {
        expect(
          f.l10n.format('dining.partyLabel', <String, Object>{'n': n}),
          'Гостей: $n',
        );
        expect(
          _ruClinic.packageNameFormat
              .replaceAll('{name}', 'Лазер')
              .replaceAll('{sessions}', '$n'),
          'Лазер ×$n',
        );
      }
    });

    test('put no case ending on a name, a clinic, or a service', () {
      // A preposition before a field would ask a case of the value that fills
      // it: `у {patient}`, `для {name1}`.
      final prepositions = RegExp(
        '(?<![$_cyr])(?:для|от|у|к|ко|с|со|о|об|на|в|во|по|за|из|без|про|над|под)'
        r' +\{(?:name1|name2|patient|mention|target|service|clinic|name|reason)\}',
        caseSensitive: false,
      );
      expect(_matching(prepositions), isEmpty);
      // A name stands first, after a colon, in parentheses, or after a title.
      expect(_ru.texts['daycare.guardianLabel'], <String>[
        '{name1} (законный представитель)',
      ]);
      expect(_ru.texts['daycare.teacherName'], <String>['Воспитатель {name1}']);
      for (final note in _ruTexts.teamNotes) {
        expect(note, contains(RegExp(r'(?:пациент|Пациент): \{patient\}')));
        expect(note, contains(RegExp(r'(?:^|\. )\{mention\}')));
      }
      for (final action in _ruSaas.ops!.operatorActions.values) {
        expect(
          action.summary,
          anyOf(
            startsWith('{target}: '),
            contains('({target})'),
            contains('«{target}»'),
          ),
        );
      }
      for (final title in _ruSaas.ops!.incidentTitles.values) {
        expect(title, startsWith('{service}: '));
      }
      expect(_ruTexts.staffMentionFormat, '@{name} ({role})');
      // A notification template greets the patient by name, and no variable
      // follows a preposition but the time and the date, which are numbers.
      final variable = RegExp(
        '(?<![$_cyr])(?:в|на|для|от|у|к|с|по|за) +#\\{(?!время\\}|дата_время\\})',
        caseSensitive: false,
      );
      for (final template in _ruSaas.messageTemplates) {
        expect(template.body, isNot(contains(variable)), reason: template.code);
        if (template.body.contains('#{имя}')) {
          expect(template.body, startsWith('Здравствуйте, #{имя}!'));
        }
      }
      expect(_ruSaas.ops!.masterCheckDetail, 'Строк: {n}');
    });

    test('write a level, a status, and a role without an agreement', () {
      // A level is an adjective that stands before `уровень`.
      final f = _faker('ru', 7);
      for (var i = 0; i < 12; i++) {
        expect(
          _role(f, 'fitness.className', i),
          matches(RegExp('^.+, (?:начальный|средний|продвинутый) уровень\$')),
        );
      }
      // A status is a noun or a neuter, and a role has both of its forms.
      for (final key in <String>['noShow', 'reserved', 'completed']) {
        expect(_ruClinic.labels[key], isNot(contains('/')), reason: key);
      }
      expect(_ruClinic.staffRoles['nurse'], 'Медсестра / медбрат');
      expect(_ruTexts.labels['spouse'], 'Супруг / супруга');
    });
  });

  group('the ruble', () {
    test(
      'is RUB, written 1 234,56 ₽ with a no-break space, as the country says',
      () {
        final russia = CoFakerCountries.russia;
        for (final currency in <CoCurrencyFormat>[
          _ruClinic.currency,
          _ruSaas.currency,
        ]) {
          expect(currency.code, russia.currencyCode);
          expect(currency.symbol, russia.currencySymbol);
          expect(currency.fractionDigits, russia.currencyMinorUnits);
          expect(currency.format(1234.56), _rub('1\u00A0234,56'));
          expect(currency.format(1200), _rub('1\u00A0200,00'));
          expect(currency.format(-80), '-${_rub('80,00')}');
          expect(currency.format(1234567), _rub('1\u00A0234\u00A0567,00'));
          expect(currency.groupSeparator, _nbsp);
          expect(currency.decimalSeparator, ',');
        }
        final f = _faker('ru', 7);
        expect(f.clinic.money(1200), _rub('1\u00A0200,00'));
        expect(f.saas.money(12000), _rub('12\u00A0000,00'));
        expect(f.clinic.counselSession().summary, contains('₽'));
        // The same ruble through the other two ways in.
        expect(_locale('ru_RU', 7).clinic.money(1234), _rub('1\u00A0234,00'));
        expect(_locale('ru', 7).saas.money(1234), _rub('1\u00A0234,00'));
      },
    );

    test('scales the prices, the roundings, and the thresholds in rubles', () {
      final scale = _ruClinic.priceScale;
      expect(scale.priceRounding, 100);
      expect(scale.packageRounding, 500);
      expect(scale.prepaidStep, 1000);
      expect(scale.installmentMinimum, 30000);
      // The finest unit is 100 rubles for a discount and a split share, and a
      // point is worth 10.
      expect(scale.adjustmentUnit, 100);
      expect(scale.splitRounding, 100);
      expect(scale.pointUnit, 10);
      for (final spec in _ruClinic.procedures) {
        final english = _enClinic.procedures.firstWhere(
          (p) => p.code == spec.code,
        );
        expect(spec.taxable, english.taxable, reason: spec.code);
        expect(spec.minPrice % scale.priceRounding, 0, reason: spec.code);
        expect(spec.maxPrice % scale.priceRounding, 0, reason: spec.code);
        // A ruble price is of the order of thirty to seventy times a dollar
        // price of the English data.
        expect(spec.minPrice, greaterThanOrEqualTo(english.minPrice * 25));
        expect(spec.maxPrice, lessThanOrEqualTo(english.maxPrice * 80));
        expect(spec.maxPrice, greaterThan(spec.minPrice), reason: spec.code);
      }
      expect(scale.quoteMin, lessThan(scale.quoteMax));
    });

    test('generates every amount of the clinic in ruble units', () {
      for (final seed in _seeds) {
        final f = _faker('ru', seed);
        final clinic = f.clinic;
        for (var i = 0; i < 60; i++) {
          final procedure = clinic.procedure();
          final spec = _ruClinic.procedures.firstWhere(
            (p) => p.code == procedure.code,
          );
          expect(procedure.price % 100, 0, reason: procedure.code);
          expect(
            procedure.price,
            inInclusiveRange(spec.minPrice, spec.maxPrice),
          );
          expect(clinic.package().price % 500, 0);
          expect(clinic.prepaidBalance() % 1000, 0);
          expect(clinic.pointTransaction().amount % 10, 0);
          for (final kind in <String>['discount', 'coupon', 'point']) {
            final line = clinic.adjustment(subtotal: 123450, kind: kind);
            expect(line.amount % 100, 0, reason: kind);
            expect(line.amount, lessThanOrEqualTo(0));
          }
          final session = clinic.counselSession();
          expect(session.quotedPrice % 100, 0);
          expect(session.packagePrice % 500, 0);
          expect(session.summary, contains(_rub('')), reason: session.summary);
        }
        final shares = clinic.splitPayment(amount: 123400);
        expect(shares.fold<int>(0, (sum, p) => sum + p.amount), 123400);
        for (final share in shares) {
          expect(share.amount % 100, 0);
        }
      }
    });

    test('generates every amount of the SaaS in rubles, with a 22% VAT', () {
      for (final seed in _seeds) {
        final saas = _faker('ru', seed).saas;
        final prices = <int>{4900, 9900, 17900, 34900};
        for (var i = 0; i < 40; i++) {
          final plan = saas.plan();
          expect(prices, contains(plan.monthlyPrice));
          final invoice = saas.invoice();
          expect(invoice.vat, (invoice.supplyAmount * 0.22).round());
          expect(invoice.total, invoice.supplyAmount + invoice.vat);
        }
        final scale = _ruSaas.priceScale;
        expect(scale.vatRate, 0.22);
        expect(scale.prepaidTopUps, <int>[
          1000,
          3000,
          5000,
          10000,
          25000,
          50000,
        ]);
        for (final entry in saas.prepaidLedger(count: 40)) {
          expect(entry.amount % 50, 0);
          if (entry.kind == 'topUp') {
            expect(scale.prepaidTopUps, contains(entry.amount));
            expect(entry.bonus, scale.bonusFor(entry.amount));
          }
        }
        for (final rows in _ruSaas.ops!.masterRows.values) {
          for (final row in rows) {
            expect(row.price == null || row.price! < 10000, isTrue);
          }
        }
      }
    });
  });

  group('no Korean-only value appears', () {
    test('the data of the language says none, and the values are Russian', () {
      expect(_ruClinic.koreanValues, CoKoreanValues.none);
      expect(_ruSaas.koreanValues, CoKoreanValues.none);
      final cyrillic = RegExp('[а-яёА-ЯЁ]');
      for (final seed in _seeds) {
        final f = _faker('ru', seed);
        for (var i = 0; i < 20; i++) {
          final patient = f.clinic.patient();
          // The masked ID has the shape of a Russian insurance account number.
          expect(
            patient.rrnMasked,
            matches(RegExp(r'^\*{3}-\*{3}-\d{3} \d{2}$')),
          );
          expect(patient.address1, matches(cyrillic));
          expect(
            patient.phone,
            matches(RegExp(r'^8 \(5\d\d\) \d{3}-\d{2}-\d{2}$')),
          );
          final payment = f.clinic.payment(amount: 12000, method: 'card');
          expect(payment.approvalNo, matches(RegExp(r'^\d{6}$')));
          expect(
            f.clinic.payment(amount: 12000, method: 'cash').cashReceiptNo,
            isNull,
          );
          final tenant = f.saas.tenant();
          // The business number is ten digits, as the INN of a company is.
          expect(tenant.businessNumber, matches(RegExp(r'^\d{10}$')));
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
      final f = _faker('ru', 7);
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
          anyOf(
            contains('медицинская конференция'),
            contains('ремонт помещений'),
            contains('техническое обслуживание оборудования'),
          ),
        );
      }
    });
  });

  group('the clinic data is the translation of the English data', () {
    test('has the lists of the English data, in the same order', () {
      expect(_ruClinic.specialties, hasLength(_enClinic.specialties.length));
      expect(
        _ruClinic.clinicNamePrefixes,
        hasLength(_enClinic.clinicNamePrefixes.length),
      );
      expect(_ruClinic.staffRoles.keys, _enClinic.staffRoles.keys);
      expect(_ruClinic.labels.keys, _enClinic.labels.keys);
      expect(
        <String>[for (final p in _ruClinic.procedures) p.code],
        <String>[for (final p in _enClinic.procedures) p.code],
      );
      expect(
        <String>[for (final d in _ruClinic.diagnoses) d.code],
        <String>[for (final d in _enClinic.diagnoses) d.code],
      );
      expect(
        <String>[for (final d in _ruClinic.diagnoses) d.nameEn],
        <String>[for (final d in _enClinic.diagnoses) d.nameEn],
      );
      for (final list in <(List<Object?>, List<Object?>)>[
        (_ruClinic.drugStems, _enClinic.drugStems),
        (_ruClinic.drugForms, _enClinic.drugForms),
        (_ruClinic.drugUsages, _enClinic.drugUsages),
        (_ruClinic.complaints, _enClinic.complaints),
        (_ruClinic.findings, _enClinic.findings),
        (_ruClinic.plans, _enClinic.plans),
        (_ruClinic.memos, _enClinic.memos),
        (_ruClinic.questions, _enClinic.questions),
        (_ruClinic.cardIssuers, _enClinic.cardIssuers),
        (_ruTexts.consentForms, _enTexts.consentForms),
        (_ruTexts.counselTopics, _enTexts.counselTopics),
        (_ruTexts.insurers, _enTexts.insurers),
        (_ruTexts.teamNotes, _enTexts.teamNotes),
      ]) {
        expect(list.$1, hasLength(list.$2.length));
      }
    });

    test('picks the counterpart of the English record from the same seed', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed).clinic;
        final ru = _faker('ru', seed).clinic;
        for (var i = 0; i < 12; i++) {
          // A clinic name is a specialty and a prefix: the kind of place first,
          // then the name in guillemets.
          final enName = en.clinicName();
          final ruName = ru.clinicName();
          final names = <String>[
            for (var p = 0; p < _enClinic.clinicNamePrefixes.length; p++)
              for (var s = 0; s < _enClinic.specialties.length; s++)
                if (enName ==
                    '${_enClinic.clinicNamePrefixes[p]} '
                        '${_enClinic.specialties[s].clinicSuffix}')
                  '${_ruClinic.specialties[s].clinicSuffix} '
                      '«${_ruClinic.clinicNamePrefixes[p]}»',
          ];
          expect(ruName, names.single);

          final enProcedure = en.procedure();
          final ruProcedure = ru.procedure();
          final spec = _ruClinic.procedures.firstWhere(
            (p) => p.code == enProcedure.code,
          );
          expect(ruProcedure.code, enProcedure.code);
          expect(ruProcedure.name, spec.name);
          expect(ruProcedure.unit, spec.unit);
          expect(ruProcedure.category, spec.category);
          expect(ruProcedure.taxable, enProcedure.taxable);

          final enDiagnosis = en.diagnosis();
          final ruDiagnosis = ru.diagnosis();
          expect(ruDiagnosis.code, enDiagnosis.code);
          expect(ruDiagnosis.nameEn, enDiagnosis.nameEn);
          expect(
            ruDiagnosis.name,
            _ruClinic.diagnoses
                .firstWhere((d) => d.code == enDiagnosis.code)
                .name,
          );

          // A drug is a stem, a form, and a strength.
          final enDrug = en.drugName();
          final ruDrug = ru.drugName();
          final drugs = <String>[
            for (var s = 0; s < _enClinic.drugStems.length; s++)
              for (var f = 0; f < _enClinic.drugForms.length; f++)
                for (final strength in _enClinic.drugForms[f].strengths)
                  if (enDrug ==
                      '${_enClinic.drugStems[s]}${_enClinic.drugForms[f].form} '
                          '$strength${_enClinic.drugForms[f].unit}')
                    '${_ruClinic.drugStems[s]}${_ruClinic.drugForms[f].form} '
                        '$strength${_ruClinic.drugForms[f].unit}',
          ];
          expect(ruDrug, drugs.first);
          // `Адермекс, таблетки 10 мг`: a comma after the name and a no-break
          // space before the unit.
          expect(
            ruDrug,
            matches(RegExp('^[$_cyr]+, [$_cyr]+ \\d+\u00A0(?:мг|г)\$')),
          );

          expect(
            ru.chartMemo(),
            _counterpart(_ruClinic.memos, _enClinic.memos, en.chartMemo()),
          );
          final enSoap = en.soap();
          final ruSoap = ru.soap();
          expect(
            ruSoap.subjective,
            _counterpart(
              _ruClinic.complaints,
              _enClinic.complaints,
              enSoap.subjective,
            ),
          );
          expect(
            ruSoap.objective,
            _counterpart(
              _ruClinic.findings,
              _enClinic.findings,
              enSoap.objective,
            ),
          );
          expect(
            ruSoap.plan,
            _counterpart(_ruClinic.plans, _enClinic.plans, enSoap.plan),
          );
          expect(
            ru.insurerName(),
            _counterpart(
              _ruTexts.insurers,
              _enTexts.insurers,
              en.insurerName(),
            ),
          );
          expect(ru.staffRole().code, en.staffRole().code);
        }
      }
    });

    test('has a consent form, feedback, and counseling of the same kind', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed).clinic;
        final ru = _faker('ru', seed).clinic;
        for (var i = 0; i < 12; i++) {
          final enForm = en.consentForm();
          final ruForm = ru.consentForm();
          final spec = _ruTexts.consentForms.firstWhere(
            (form) => form.kind == enForm.kind,
          );
          expect(ruForm.kind, enForm.kind);
          expect(ruForm.title, spec.title);
          expect(ruForm.clauses, spec.clauses);
          expect(ruForm.clauses, hasLength(enForm.clauses.length));
          expect(ruForm.disclaimer, _ruTexts.consentDisclaimer);

          final enFeedback = en.feedback();
          final ruFeedback = ru.feedback();
          expect(ruFeedback.sentiment, enFeedback.sentiment);
          expect(ruFeedback.score, enFeedback.score);
          expect(
            ruFeedback.comment,
            _counterpart(
              _ruTexts.feedback[enFeedback.sentiment]!,
              _enTexts.feedback[enFeedback.sentiment]!,
              enFeedback.comment,
            ),
          );

          final enSession = en.counselSession();
          final ruSession = ru.counselSession();
          final topic = _ruTexts.counselTopics.firstWhere(
            (t) => t.topic == enSession.topic,
          );
          expect(ruSession.topic, enSession.topic);
          expect(ruSession.procedureCode, enSession.procedureCode);
          expect(ruSession.procedure, topic.procedure);
          expect(ruSession.sessions, enSession.sessions);
          expect(ruSession.booked, enSession.booked);
          expect(ruSession.turns, hasLength(enSession.turns.length));
          expect(
            ruSession.turns.map((turn) => turn.speaker),
            enSession.turns.map((turn) => turn.speaker),
          );
          // The summary writes the number of sessions after its label.
          expect(
            ruSession.summary,
            contains('(сеансов: ${ruSession.sessions})'),
          );

          final enResult = en.integrationResult();
          final ruResult = ru.integrationResult();
          expect(ruResult.service, enResult.service);
          expect(ruResult.code, enResult.code);
          expect(ruResult.ok, enResult.ok);
          final english = _enTexts.integrationResults[enResult.service]!;
          final russian = _ruTexts.integrationResults[enResult.service]!;
          expect(
            ruResult.message,
            russian[english.indexWhere((r) => r.message == enResult.message)]
                .message,
          );

          final enDevice = en.device();
          final ruDevice = ru.device();
          expect(ruDevice.kind, enDevice.kind);
          expect(ruDevice.kindLabel, _ruTexts.labels[enDevice.kind]);
          expect(ruDevice.name, startsWith(ruDevice.kindLabel));
          expect(ruDevice.name, matches(RegExp('^.+ №\u00A0\\d+\$')));
        }
      }
    });

    test('writes a package and a compound package with the sign ×', () {
      for (final seed in _seeds) {
        final clinic = _faker('ru', seed).clinic;
        for (var i = 0; i < 12; i++) {
          final package = clinic.package();
          expect(package.name, endsWith(' ×${package.sessions}'));
          expect(
            clinic.compoundPackageName(),
            matches(
              RegExp(
                r'^.+ ×(?:3|5|10)(?: \+ .+ ×(?:3|5|10)){1,2}'
                ' \\+ восстанавливающий крем в подарок\$',
              ),
            ),
          );
        }
      }
    });

    test('writes a closure notice with the date and the weekday of Russia', () {
      final weekday = RegExp(r'\d{1,2}\.\d{1,2} \((?:пн|вт|ср|чт|пт|сб|вс)\)');
      for (final seed in _seeds) {
        final f = _faker('ru', seed);
        for (var day = 1; day <= 28; day += 3) {
          final date = DateTime.utc(2026, 10, day);
          final notice = f.clinic.closureNotice(
            date: date,
            clinicName: 'Детская клиника «Образец»',
          );
          expect(notice.holiday, isNull);
          expect(
            notice.title,
            matches(RegExp('^Закрыто: ${weekday.pattern}\$')),
          );
          expect(
            notice.body,
            matches(
              RegExp(
                '^Детская клиника «Образец»: закрыто ${weekday.pattern}\\. '
                'Причина: .+\\. Приём возобновится ${weekday.pattern}\\.\$',
              ),
            ),
          );
          // October 7, 2026 is a Wednesday.
          if (day == 7) {
            expect(notice.title, 'Закрыто: 7.10 (ср)');
          }
        }
      }
      // October 8, 2026 is a Thursday, and the clinic reopens on Friday.
      final notice = _faker('ru', 7).clinic.closureNotice(
        date: DateTime.utc(2026, 10, 8),
        clinicName: 'Детская клиника «Образец»',
      );
      expect(notice.title, 'Закрыто: 8.10 (чт)');
      expect(notice.body, endsWith('Приём возобновится 9.10 (пт).'));
    });

    test('names a clinic by its kind of place and its name in guillemets', () {
      final f = _faker('ru', 7);
      for (var i = 0; i < 40; i++) {
        expect(
          f.clinic.clinicName(),
          matches(
            RegExp(
              '^(?:Дерматологическая клиника|Клиника пластической хирургии|'
              'Семейная клиника|Терапевтическая клиника|Детская клиника) '
              '«[^«»]+»\$',
            ),
          ),
        );
      }
    });
  });

  group('the SaaS data is the translation of the English data', () {
    test('has the plans, templates, and notices of the English data', () {
      expect(
        <String>[for (final p in _ruSaas.plans) p.code],
        <String>[for (final p in _enSaas.plans) p.code],
      );
      for (var i = 0; i < _enSaas.plans.length; i++) {
        expect(_ruSaas.plans[i].seats, _enSaas.plans[i].seats);
        expect(
          _ruSaas.plans[i].messageCredits,
          _enSaas.plans[i].messageCredits,
        );
      }
      expect(_ruSaas.labels.keys, _enSaas.labels.keys);
      expect(_ruSaas.ops!.labels.keys, CoFakerSaasOps.english.labels.keys);
      // A notification template keeps the number of the variables of the
      // English one, and writes them in Russian.
      final marker = RegExp(r'#\{[^{}]+\}');
      for (var i = 0; i < _enSaas.messageTemplates.length; i++) {
        final english = _enSaas.messageTemplates[i];
        final russian = _ruSaas.messageTemplates[i];
        expect(russian.code, english.code);
        final markers = marker
            .allMatches(russian.body)
            .map((m) => m.group(0)!)
            .toList();
        expect(
          markers,
          hasLength(marker.allMatches(english.body).length),
          reason: english.code,
        );
        for (final variable in markers) {
          expect(variable, matches(RegExp('^#\\{[$_cyr\\_]+\\}\$')));
        }
      }
      expect(_ruSaas.ops!.masterCheckDetail, 'Строк: {n}');
      expect(
        <String>[for (final p in _ruSaas.plans) p.name],
        <String>['Старт', 'Стандарт', 'Профи', 'Корпоративный'],
      );
    });

    test('picks the counterpart of the English record from the same seed', () {
      for (final seed in _seeds) {
        final en = _faker('en', seed).saas;
        final ru = _faker('ru', seed).saas;
        for (var i = 0; i < 12; i++) {
          final enPlan = en.plan();
          final ruPlan = ru.plan();
          final spec = _ruSaas.plans.firstWhere((p) => p.code == enPlan.code);
          expect(ruPlan.code, enPlan.code);
          expect(ruPlan.name, spec.name);
          expect(ruPlan.seats, enPlan.seats);
          expect(ruPlan.messageCredits, enPlan.messageCredits);

          final enTemplate = en.messageTemplate();
          final ruTemplate = ru.messageTemplate();
          expect(ruTemplate.code, enTemplate.code);
          expect(
            ruTemplate.name,
            _ruSaas.messageTemplates
                .firstWhere((t) => t.code == enTemplate.code)
                .name,
          );

          final enNotice = en.notice();
          final ruNotice = ru.notice();
          expect(ruNotice.category, enNotice.category);
          expect(
            ruNotice.title,
            _counterpart(
              <String>[for (final n in _ruSaas.notices) n.title],
              <String>[for (final n in _enSaas.notices) n.title],
              enNotice.title,
            ),
          );
        }
      }
    });

    test('picks the counterpart of the English operator event', () {
      // An operator is named with a given name and a surname, which the
      // national locale of Russia draws in another way than the English one,
      // so each event has a generator of its own and the stream of the other
      // calls stays aligned.
      for (final seed in _seeds) {
        for (var i = 0; i < 12; i++) {
          final enEvent = _faker('en', seed * 100 + i).saas.operatorEvent();
          final ruEvent = _faker('ru', seed * 100 + i).saas.operatorEvent();
          expect(ruEvent.action, enEvent.action);
          expect(
            ruEvent.actionLabel,
            _ruSaas.ops!.operatorActions[enEvent.action]!.label,
          );
          final role = CoFakerSaasOps.english.operatorRoles.entries
              .firstWhere((entry) => entry.value == enEvent.operatorRole)
              .key;
          expect(ruEvent.operatorRole, _ruSaas.ops!.operatorRoles[role]);
          // The summary names the target first, so that it needs no case.
          expect(
            ruEvent.summary,
            _ruSaas.ops!.operatorActions[enEvent.action]!.summary.replaceAll(
              '{target}',
              ruEvent.target,
            ),
          );
        }
      }
    });
  });

  group('the language is finished', () {
    test('is localized and passes the completion gate', () {
      final data = CoLanguageData.registered('ru');
      expect(data.level, CoLanguageLevel.localized);
      final report = CoLanguageCoverage().check(data);
      expect(report.issues, isEmpty, reason: report.toMarkdown());
    });
  });
}
