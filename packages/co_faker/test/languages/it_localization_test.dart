import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

import '../language_safety/it.dart';

/// What is particular to the Italian data: that it is the translation of the
/// English records (the same seed picks the counterpart of the same record),
/// that the ways in read the same data, the writing (the apostrophe, the
/// punctuation, the articles that contract with a preposition and that elide,
/// the register `Lei`), and the euro (the format and the scale of every
/// amount). A language that has no data of its own is `nl`, which never gets
/// any: the control of the tests that ask for English.

/// The no-break space that Italian writes between an amount and the euro.
const String _nbsp = '\u00A0';

/// The seeds the alignment checks run with.
const List<int> _seeds = <int>[7, 436, 20261005];

final DateTime _now = DateTime.utc(2026, 10, 8, 9);

CoFaker _forLanguage(String tag, {int seed = 7}) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

CoFaker _faker(String locale, {int seed = 7}) =>
    CoFaker(locale: locale, seed: seed, now: _now, domains: CoFakerDomains.all);

String _role(CoFaker f, String key, int index) =>
    f.schema.record(
          <String, String>{'value': 'String'},
          roles: <String, String>{'value': key},
          streamKey: key,
          index: index,
        )['value']
        as String;

final CoL10nBundle _en = CoL10nRegistry.english;
final CoL10nBundle _it = CoL10nRegistry.bundleFor('it')!;
final CoFakerClinicData _enClinic = CoFakerClinicData.english;
final CoFakerClinicData _itClinic = CoL10nClinic.clinicOf('it')!;
final CoFakerSaasData _enSaas = CoFakerSaasData.english;
final CoFakerSaasData _itSaas = CoL10nClinic.saasOf('it')!;

typedef _Text = ({String where, String text, CoTextKind kind});

/// Every text of Italian that a person reads, with its place: the domain text
/// bundle, the clinic data, and the SaaS data. A code is left out.
final List<_Text> _texts = <_Text>[
  for (final table in <CoTextTable>[
    CoLanguageTexts.ofBundle(_it),
    CoLanguageTexts.ofClinic(_itClinic),
    CoLanguageTexts.ofSaas(_itSaas),
  ])
    for (final slot in table.slots.values)
      if (slot.kind == CoTextKind.text || slot.kind == CoTextKind.format)
        for (final row in slot.rows)
          for (final text in slot.cellsOf(row)!)
            (where: '${slot.name}[$row]', text: text, kind: slot.kind),
];

/// The slots of the English texts and of the Italian texts, by name: a slot is
/// a list or a map of the bundle, the clinic data, or the SaaS data.
final Map<String, CoTextSlot> _enSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_en).slots,
  ...CoLanguageTexts.ofClinic(_enClinic, resolveFallbacks: true).slots,
  ...CoLanguageTexts.ofSaas(_enSaas, resolveFallbacks: true).slots,
};
final Map<String, CoTextSlot> _itSlots = <String, CoTextSlot>{
  ...CoLanguageTexts.ofBundle(_it).slots,
  ...CoLanguageTexts.ofClinic(_itClinic).slots,
  ...CoLanguageTexts.ofSaas(_itSaas).slots,
};

/// The first text of every row of [slot], in the order of the data.
List<String> _column(Map<String, CoTextSlot> slots, String slot) {
  final found = slots[slot];
  expect(found, isNotNull, reason: 'no slot $slot');
  return <String>[for (final row in found!.rows) found.cellsOf(row)!.first];
}

/// The same index of two lists: the Italian counterpart of [english].
T _counterpart<T>(List<T> italian, List<T> english, T value) {
  final index = english.indexOf(value);
  expect(index, isNonNegative, reason: 'English has no $value');
  return italian[index];
}

/// The places of the texts that match [pattern], to say what is wrong.
List<String> _matching(
  Iterable<_Text> texts,
  RegExp pattern, {
  Set<String> except = const <String>{},
}) => <String>[
  for (final text in texts)
    if (!except.any(text.where.startsWith) && pattern.hasMatch(text.text))
      '${text.where}: ${text.text}',
];

/// Pairs that stand for the whole: a text of English, the Italian text that
/// translates it, and the slot they are in. The same position of the slot in
/// both languages is what makes one seed pick the same record, so an Italian
/// text on another position than its English text is a record that the seed
/// no longer translates, and a list that has the right length would not show
/// it.
const List<(String, String, String)> _anchors = <(String, String, String)>[
  (
    'fx.branchName',
    'Demo airport T1 exchange',
    'Ufficio cambio demo, aeroporto T1',
  ),
  ('fx.branchName', 'Demo Mulpare exchange', 'Ufficio cambio demo, Fraxinia'),
  ('fx.tierName', 'Gold', 'Oro'),
  (
    'fx.couponName',
    'First exchange discount (example)',
    'Sconto sul primo cambio (esempio)',
  ),
  (
    'remit.flagRule',
    'Large transfer (demo rule)',
    'Bonifico di importo elevato (regola demo)',
  ),
  ('vet.petName', 'Barley', 'Orzo'),
  ('vet.petName', 'Cloud', 'Nuvola'),
  ('vet.breed.dog', 'Poodle', 'Barboncino'),
  ('vet.coatColor', 'Gray', 'Grigio'),
  ('vet.clinicRoom', 'Vaccination room', 'Sala vaccinazioni'),
  ('grocery.categoryName', 'Seafood', 'Pesce e frutti di mare'),
  ('grocery.categoryName', 'Dairy', 'Latticini'),
  ('catalog.groceryName', 'Spinach', 'Spinaci'),
  ('catalog.groceryName', 'Milk', 'Latte'),
  ('catalog.commerceName', 'Ceramic cup', 'Tazza in ceramica'),
  ('dental.dentalProcedure', 'Scaling', 'Detartrasi'),
  ('dental.dentalMaterial', 'Zirconia (example)', 'Zirconia (esempio)'),
  ('homecare.careGrade', 'Care grade 5', 'Livello di assistenza 5'),
  (
    'homecare.careGrade',
    'Cognitive support grade',
    'Livello di supporto cognitivo',
  ),
  ('travel_wallet.tripName', 'Bangkok weekend', 'Fine settimana a Bangkok'),
  (
    'b2b_trade.holdReason',
    'Delivery date check (example)',
    'Verifica della data di consegna (esempio)',
  ),
  (
    'group_deal.dealTitle',
    'Cotton towel group deal',
    'Acquisto di gruppo di asciugamani in cotone',
  ),
  ('fitness.classLevelLabel', 'advanced', 'avanzato'),
  ('fitness.classCategoryLabel', 'Chair', 'Sedia'),
  ('space_rental.amenity', 'Water dispenser', 'Distributore d’acqua'),
  ('dining.menuName', 'Tomato pasta', 'Pasta al pomodoro'),
  ('daycare.className', 'Star class', 'Sezione Stella'),
  ('daycare.ageLabel', 'Age 5', '5 anni'),
  ('daycare.snackMenu', 'Plain yogurt', 'Yogurt naturale'),
  ('daycare.allergenLabel', 'Wheat', 'Grano'),
  ('exam_prep.subjectName', 'Information security', 'Sicurezza informatica'),
  ('exam_prep.correctChoice', 'Hash function', 'Funzione di hash'),
  ('exam_prep.correctChoice', 'Least privilege', 'Privilegio minimo'),
  ('exam_prep.wrongChoice1', 'FIFO queue', 'Coda FIFO'),
  ('hrd.departmentName', 'Logistics', 'Logistica'),
  ('hrd.jobTitle', 'Team lead', 'Coordinatore di team'),
  ('neighborhood.keyword', 'local news', 'notizie locali'),
  ('meetup.interestTag', 'Hiking', 'Escursionismo'),
  (
    'meetup.cadenceLabel',
    'Alternate Sundays 10:00',
    'Una domenica su due alle 10:00',
  ),
  ('content.genreName', 'Essay', 'Saggio'),
  ('content.audioTaxonomy', 'Audiobook', 'Audiolibro'),
  ('helpdesk.topicName', 'Billing', 'Fatturazione'),
  (
    'campaign.failReason',
    'No marketing consent (example)',
    'Nessun consenso al marketing (esempio)',
  ),
  ('workplace.department', 'HR team', 'Risorse umane'),
  ('workplace.shiftName', 'Weekend duty', 'Turno nel fine settimana'),
  ('workplace.accountName', 'Travel (example)', 'Trasferte (esempio)'),
  ('brokerage.serviceTypeName', 'Repair', 'Riparazioni'),
  ('brokerage.milestoneLabel', 'Handoff record', 'Verbale di consegna'),
  ('logistics.scanEvent', 'Delivery not completed', 'Consegna non effettuata'),
  ('logistics.freightType', 'Household goods', 'Articoli per la casa'),
  ('logistics.itemName', 'Brown rice 2kg', 'Riso integrale 2 kg'),
  ('hospitality.hkCheckItem', 'Check minibar', 'Controllare il minibar'),
  ('hospitality.amenityName', 'Toothbrush', 'Spazzolino da denti'),
  (
    'hospitality.folioItem',
    'Room service (example)',
    'Servizio in camera (esempio)',
  ),
  ('clinic.specialties.name', 'Dermatology', 'Dermatologia'),
  ('clinic.specialties.name', 'Pediatrics', 'Pediatria'),
  ('clinic.staffRoles', 'Front Desk', 'Accoglienza'),
  ('clinic.staffRoles', 'Medical Director', 'Direzione sanitaria'),
  ('clinic.labels', 'No-show', 'Assente'),
  ('clinic.labels', 'Bank transfer', 'Bonifico bancario'),
  ('clinic.procedures.name', 'Acne extraction', 'Estrazione dei comedoni'),
  ('clinic.procedures.name', 'Medical certificate', 'Certificato medico'),
  ('clinic.diagnoses.name', 'Rosacea, unspecified', 'Rosacea, non specificata'),
  ('clinic.drugStems', 'Seraton', 'Corelmin'),
  ('clinic.drugForms.form', ' ointment', ' pomata'),
  ('clinic.ops.weekdayNames', 'Mon', 'lunedì'),
  ('clinic.ops.weekdayNames', 'Sun', 'domenica'),
  ('clinic.texts.insurers', 'Clearbrook Health', 'Salute Rivalimpida'),
  ('clinic.texts.labels', 'Grandchild', 'Nipote'),
  ('clinic.ops.labels', 'Withdrawn', 'Revocato'),
  ('clinic.ops.rooms.name', 'Checkout', 'Cassa'),
  ('saas.plans.name', 'Enterprise', 'Aziendale'),
  ('saas.labels', 'Past due', 'Pagamento in ritardo'),
  ('saas.labels', 'Sent via fallback', 'Inviato con un canale alternativo'),
  ('saas.ops.operatorRoles', 'Viewer', 'Sola lettura'),
  ('saas.failureReasons', 'Insufficient credits', 'Crediti insufficienti'),
  (
    'saas.ops.alerts.message',
    'The nightly backup completed.',
    'Il backup notturno è stato completato.',
  ),
];

/// The vowels that make `lo`, `la`, and `una` elide.
const String _vowel = 'aeiouàèéìòùAEIOUÀÈÉÌÒÙ';

/// The articles, and the prepositions that contract with them, that no
/// template puts right before a value that it fills.
const String _articles =
    'del|dello|della|dei|degli|delle|dell’|al|allo|alla|ai|agli|alle|all’|'
    'nel|nello|nella|nei|negli|nelle|nell’|dal|dallo|dalla|dai|dagli|dalle|'
    'dall’|sul|sullo|sulla|sui|sugli|sulle|sull’|il|lo|la|i|gli|le|l’|un|'
    'uno|una|un’';

const String _weekdays =
    '(?:lunedì|martedì|mercoledì|giovedì|venerdì|sabato|domenica)';

void main() {
  final data = CoLanguageData.registered('it');

  group('the bundle is the translation of the English one', () {
    test('has every key, with as many texts, and the codes stay', () {
      expect(_it.language, 'it');
      expect(_it.texts.keys.toSet(), _en.texts.keys.toSet());
      for (final entry in _en.texts.entries) {
        expect(
          _it.texts[entry.key],
          hasLength(entry.value.length),
          reason: entry.key,
        );
      }
      expect(data.level, CoLanguageLevel.localized);
    });

    test('writes the translation of a text at the position of that text', () {
      for (final (slot, english, italian) in _anchors) {
        final position = _column(_enSlots, slot).indexOf(english);
        expect(position, isNonNegative, reason: '$slot has no "$english"');
        expect(
          _column(_itSlots, slot)[position],
          italian,
          reason: '$slot #$position is "$english" in English',
        );
      }
      expect(
        _anchors.map((anchor) => anchor.$1).toSet().length,
        greaterThan(55),
      );
    });

    test('picks the translation of the English record, from the same seed', () {
      final keys = <String>{};
      for (final seed in _seeds) {
        final en = _forLanguage('en', seed: seed);
        final it = _forLanguage('it', seed: seed);
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
                for (final row in rows) _it.texts[key]![row],
              ];
              if (rows.isEmpty) {
                // A child of a taxonomy (`Fruit · subtopic 1`) is the name of
                // its root in the template of the language.
                final child = RegExp(
                  r'^(.+) · subtopic (\d+)$',
                ).firstMatch(enText);
                expect(child, isNotNull, reason: '$key #$i read "$enText"');
                final root = _it.texts[key]![english.indexOf(child!.group(1)!)];
                candidates.add(
                  _it.texts['common.taxonomyChild']!.single
                      .replaceAll('{root}', root)
                      .replaceAll('{n}', child.group(2)!),
                );
              }
              expect(
                _role(it, key, i),
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
        final en = _forLanguage('en', seed: seed);
        final it = _forLanguage('it', seed: seed);
        for (var i = 0; i < 12; i++) {
          final enPet = en.vet.pet();
          final itPet = it.vet.pet();
          expect(itPet.animalKind, enPet.animalKind);
          expect(itPet.weightKg, enPet.weightKg);
          expect(
            itPet.name,
            _counterpart(
              _it.texts['vet.petName']!,
              _en.texts['vet.petName']!,
              enPet.name,
            ),
          );
          expect(
            itPet.breed,
            _counterpart(
              _it.texts['vet.breed.${enPet.animalKind}']!,
              _en.texts['vet.breed.${enPet.animalKind}']!,
              enPet.breed,
            ),
          );
          expect(
            itPet.coatColor,
            _counterpart(
              _it.texts['vet.coatColor']!,
              _en.texts['vet.coatColor']!,
              enPet.coatColor,
            ),
          );
        }
        for (final code in <String>['USD', 'JPY', 'EUR', 'CNY', 'THB']) {
          expect(
            it.fx.currency(code: code).name,
            _it.texts['fx.currencyName.$code']!.single,
          );
        }
        for (var i = 0; i < 9; i++) {
          final enQuestion = en.examPrep.question(index: i);
          final itQuestion = it.examPrep.question(index: i);
          final row = _en.texts['exam_prep.questionStem']!.indexOf(
            enQuestion.stem,
          );
          final correct = _it.texts['exam_prep.correctChoice']![row];
          expect(itQuestion.stem, _it.texts['exam_prep.questionStem']![row]);
          // The answer key follows the shuffle: the same position in English
          // and in Italian, and the choice there is the correct one.
          expect(itQuestion.answerKeys, enQuestion.answerKeys);
          expect(itQuestion.choices[itQuestion.answerKeys.single - 1], correct);
          expect(
            itQuestion.explanation,
            _it.texts['exam_prep.explanation']![row],
          );
          // The explanation names its answer in the case of the list, which
          // the shared tests compare.
          expect(itQuestion.explanation, contains(correct));
          expect(itQuestion.choices.toSet(), hasLength(4));
        }
      }
    });

    test('has the clinic and SaaS entry of the same code in its place', () {
      expect(
        <String, String>{for (final p in _itClinic.procedures) p.code: p.name},
        <String, String>{
          'CONS01': 'Prima visita',
          'BTX-F': 'Tossina botulinica fronte',
          'FIL-L': 'Filler di acido ialuronico labbra 1 ml',
          'LT-01': 'Laser a picosecondi, uniformazione del colorito',
          'HIFU-300': 'Lifting a ultrasuoni focalizzati, 300 linee',
          'ACN-01': 'Estrazione dei comedoni',
          'CARE-01': 'Cura lenitiva del viso con LED',
          'DOC-01': 'Certificato medico',
        },
      );
      expect(
        <String, String>{for (final d in _itClinic.diagnoses) d.code: d.name},
        <String, String>{
          'L70.0': 'Acne volgare',
          'L81.1': 'Cloasma',
          'B07': 'Verruche virali',
          'L20.9': 'Dermatite atopica, non specificata',
          'L30.9': 'Dermatite, non specificata',
          'L71.9': 'Rosacea, non specificata',
        },
      );
      expect(
        <String>[for (final s in _itClinic.specialties) s.name],
        <String>[
          'Dermatologia',
          'Chirurgia plastica',
          'Medicina generale',
          'Medicina interna',
          'Pediatria',
        ],
      );
      expect(
        <String>[for (final s in _enClinic.specialties) s.name],
        <String>[
          'Dermatology',
          'Plastic Surgery',
          'Family Medicine',
          'Internal Medicine',
          'Pediatrics',
        ],
      );
      expect(
        <String>[for (final v in _itClinic.visitPurposes) v.name],
        <String>['Visita', 'Procedura', 'Trattamento', 'Cura'],
      );
      expect(
        <String>[for (final v in _enClinic.visitPurposes) v.name],
        <String>['Consultation', 'Procedure', 'Treatment', 'Care'],
      );
      expect(
        _itClinic.staffRoles,
        containsPair('director', 'Direzione sanitaria'),
      );
      expect(_itClinic.staffRoles, containsPair('doctor', 'Medico'));
      expect(_itClinic.staffRoles, containsPair('desk', 'Accoglienza'));
      expect(_itClinic.labels, containsPair('uninsured', 'Privato'));
      expect(_itClinic.labels, containsPair('noShow', 'Assente'));
      expect(
        <String, String>{for (final p in _itSaas.plans) p.code: p.name},
        <String, String>{
          'starter': 'Base',
          'standard': 'Standard',
          'pro': 'Pro',
          'enterprise': 'Aziendale',
        },
      );
      expect(
        <String, String>{
          for (final t in _itSaas.messageTemplates) t.code: t.name,
        },
        <String, String>{
          'RSV_CREATED': 'Appuntamento prenotato',
          'RSV_CANCELLED': 'Appuntamento annullato',
          'RSV_REMIND_D1': 'Promemoria',
          'QUESTIONNAIRE': 'Questionario prima della visita',
          'SURVEY': 'Sondaggio di soddisfazione',
          'AD_EVENT': 'Promozione (pubblicità)',
        },
      );
      expect(
        <(String, String)>[
          for (final n in _itSaas.notices) (n.category, n.title),
        ],
        <(String, String)>[
          ('maintenance', 'Manutenzione programmata'),
          ('release', 'Nuove funzionalità disponibili'),
          ('notice', 'Aggiornamento dei prezzi'),
          ('notice', 'Notifiche in ritardo'),
        ],
      );
      expect(
        <String>[for (final p in _itClinic.procedures) p.code],
        <String>[for (final p in _enClinic.procedures) p.code],
      );
      expect(
        <(String, String)>[
          for (final d in _itClinic.diagnoses) (d.code, d.nameEn),
        ],
        <(String, String)>[
          for (final d in _enClinic.diagnoses) (d.code, d.nameEn),
        ],
      );
      expect(_itClinic.staffRoles.keys, _enClinic.staffRoles.keys);
      expect(_itClinic.labels.keys, _enClinic.labels.keys);
    });

    test('keeps the figures of its English text', () {
      // The figures of the alerts, the claim-check ROW_DELTA, and the lists
      // of the exam are the English ones.
      final enOps = CoFakerSaasOps.english;
      final itOps = _itSaas.ops!;
      for (var i = 0; i < enOps.alerts.length; i++) {
        expect(itOps.alerts[i].code, enOps.alerts[i].code);
        expect(
          RegExp(r'\d+').allMatches(itOps.alerts[i].message).map((m) => m[0]),
          RegExp(r'\d+').allMatches(enOps.alerts[i].message).map((m) => m[0]),
          reason: itOps.alerts[i].code,
        );
      }
      expect(
        RegExp(r'\d+').firstMatch(itOps.masterChecks['ROW_DELTA']!)![0],
        '5',
      );
    });
  });

  group('the ways in read the same data', () {
    final ways = <String, CoFaker Function()>{
      "forLanguage('it')": () => _forLanguage('it'),
      "forLanguage('it-IT')": () => _forLanguage('it-IT'),
      "forLanguage('it_IT.UTF-8')": () => _forLanguage('it_IT.UTF-8'),
      "locale: 'it'": () => _faker('it'),
      "locale: 'it_IT'": () => _faker('it_IT'),
      "locale: 'it-it'": () => _faker('it-it'),
      // The spellings that a setting of an operating system or a browser has.
      "locale: 'IT'": () => _faker('IT'),
      "locale: 'it_IT.UTF-8'": () => _faker('it_IT.UTF-8'),
    };

    test('read the Italian bundle and the registered clinic and SaaS data', () {
      for (final entry in ways.entries) {
        final f = entry.value();
        expect(f.language, 'it', reason: entry.key);
        expect(f.l10n.language, 'it', reason: entry.key);
        expect(f.clinic.data, same(_itClinic), reason: entry.key);
        expect(f.saas.data, same(_itSaas), reason: entry.key);
        for (final key in _it.texts.keys) {
          expect(f.l10n.list(key), _it.texts[key], reason: '${entry.key} $key');
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
            final texts = _it.texts[key];
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
      expect(compared, greaterThan(800));
    });

    test('write the same clinic and SaaS text and amounts', () {
      String describe(CoFaker f) {
        final date = DateTime.utc(2026, 11, 25);
        return <Object?>[
          for (var i = 0; i < 6; i++) f.clinic.chartMemo(),
          for (var i = 0; i < 6; i++) f.clinic.diagnosis(),
          for (var i = 0; i < 6; i++) f.clinic.procedure(),
          for (var i = 0; i < 4; i++) f.clinic.package(),
          for (var i = 0; i < 4; i++) f.clinic.soap(),
          f.clinic.consentForm(),
          f.clinic.counselSession(topic: 'toning').summary,
          f.clinic.closureNotice(date: date, clinicName: 'Studio Demo').body,
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

    test('are the Italian data and not the English one', () {
      for (final tag in <String>['it', 'it_IT']) {
        final f = _faker(tag);
        expect(f.clinic.data, isNot(same(CoFakerClinicData.english)));
        expect(f.saas.data, isNot(same(CoFakerSaasData.english)));
        final procedure = _role(f, 'dental.dentalProcedure', 0);
        expect(procedure, isIn(_it.texts['dental.dentalProcedure']!));
        expect(procedure, isNot(isIn(_en.texts['dental.dentalProcedure']!)));
        expect(f.clinic.money(1234), isNot(contains(r'$')));
      }
    });

    test('are English only for a language that has no data, such as nl', () {
      // `nl` is a language that the package never localizes: it keeps reading
      // English, whatever the other Stories do.
      final f = _faker('nl');
      expect(f.clinic.data, same(CoFakerClinicData.english));
      expect(f.saas.data, same(CoFakerSaasData.english));
      expect(f.l10n.language, 'en');
      expect(
        _role(f, 'dental.dentalProcedure', 0),
        isIn(_en.texts['dental.dentalProcedure']!),
      );
    });
  });

  group('the writing is Italian', () {
    test('has texts to check, and none in another writing system', () {
      expect(_texts.length, greaterThan(1300));
      // Hangul, kana, han, and Cyrillic: a text that stayed in another
      // language.
      final other = RegExp(
        r'[\p{Script=Hangul}\p{Script=Hiragana}\p{Script=Katakana}'
        r'\p{Script=Han}\p{Script=Cyrillic}]',
        unicode: true,
      );
      expect(_matching(_texts, other), isEmpty);
    });

    test('writes the apostrophe as ’ and never as a straight quote', () {
      expect(_matching(_texts, RegExp('[\'"]')), isEmpty);
      // A quotation is `«…»`, never the curly marks of English or German.
      expect(_matching(_texts, RegExp('[“”„‘]')), isEmpty);
      expect(
        _it.texts.values.expand((list) => list).any((t) => t.contains('’')),
        isTrue,
      );
    });

    test('writes no space before punctuation, and one after', () {
      expect(_matching(_texts, RegExp(' [:;?!,.]')), isEmpty);
      // A colon, a semicolon, and a question mark are followed by a space or
      // end the text, except the colon of a time (`06:00`).
      final bad = <String>[
        for (final text in _texts)
          if (text.kind == CoTextKind.text)
            for (final match in RegExp('[:;?!]').allMatches(text.text))
              if (!_punctuationFollowedProperly(text.text, match.start))
                '${text.where}: ${text.text}',
      ];
      expect(bad, isEmpty);
    });

    test('writes a space between a number and a unit, and `%` after it', () {
      const unit = r'(?:mg|g|kg|ml|mL|cl|L|mmHg|°C)\b';
      expect(_matching(_texts, RegExp('\\d$unit')), isEmpty);
      expect(_matching(_texts, RegExp(r'\d %')), isEmpty);
    });

    test('writes no text with a stray space', () {
      // A drug is `Pelnovax compresse 10 mg`: its form starts with a space and
      // its unit with another.
      expect(
        _matching(
          _texts,
          RegExp(r'^\s|\s$|  '),
          except: const <String>{
            'clinic.drugForms.form',
            'clinic.drugForms.unit',
          },
        ),
        isEmpty,
      );
    });

    test('writes a no-break space as an escape in its source files', () {
      // A literal no-break space is a character that no reviewer can see, so
      // the data files write `U+00A0` as an escape, and the tests below read
      // what the escape makes.
      for (final name in <String>['bundle', 'clinic', 'saas']) {
        final source = File('lib/src/l10n/it/it_$name.dart').readAsStringSync();
        expect(source, isNot(contains(_nbsp)), reason: 'it_$name.dart');
        expect(source, isNot(contains('\u202F')), reason: 'it_$name.dart');
      }
      expect(
        File('lib/src/l10n/it/it_clinic.dart').readAsStringSync(),
        contains(r'\u00A0'),
      );
      expect(
        File('lib/src/l10n/it/it_saas.dart').readAsStringSync(),
        contains(r'\u00A0'),
      );
    });

    test('contracts a preposition with the article that follows it', () {
      // `di il` is `del`, `a il` is `al`, `in il` is `nel`, `da il` is `dal`,
      // `su il` is `sul`, and so on for `lo`, `la`, `i`, `gli`, and `le`.
      final pattern = RegExp(
        r'(?<![\p{L}’-])(?:di|a|da|in|su) (?:il|lo|la|i|gli|le)(?![\p{L}’-])',
        caseSensitive: false,
        unicode: true,
      );
      expect(_matching(_texts, pattern), isEmpty);
    });

    test('elides `lo`, `la`, and `una` before a vowel', () {
      final pattern = RegExp(
        '(?<![\\p{L}’-])(?:lo|la|una) (?=[$_vowel])',
        caseSensitive: false,
        unicode: true,
      );
      expect(_matching(_texts, pattern), isEmpty);
      // ... and the elision never stands before a consonant: a silent `h`
      // (`l’ha`) and a number that starts with a vowel (`dell’80%`, `l’8`)
      // elide as a vowel does.
      final before = RegExp(
        '(?<![\\p{L}])(?:l|un|dell|all|nell|dall|sull)’(?![${_vowel}hH0-9])',
        caseSensitive: false,
        unicode: true,
      );
      expect(_matching(_texts, before), isEmpty);
    });

    test(
      'puts no article or contraction before a value that a template fills',
      () {
        // A value that a template fills may start with a vowel, be of either
        // gender, and be plural, so an article, or a preposition that contracts
        // with it, never stands right before one: `per`, `di`, `in`, `da`, `a`,
        // and `presso` do not change.
        final pattern = RegExp(
          '(?<![\\p{L}])(?:$_articles)\\s*\\{',
          caseSensitive: false,
          unicode: true,
        );
        expect(_matching(_texts, pattern), isEmpty);
      },
    );

    test('writes the weekdays and the months in lower case', () {
      expect(
        _matching(
          _texts,
          RegExp(
            r'\b(?:Gennaio|Febbraio|Marzo|Aprile|Maggio|Giugno|Luglio|Agosto|'
            r'Settembre|Ottobre|Novembre|Dicembre|Lunedì|Martedì|Mercoledì|'
            r'Giovedì|Venerdì|Sabato|Domenica)\b',
          ),
        ),
        isEmpty,
      );
      final ops = _itClinic.ops!;
      expect(ops.weekdayNames, hasLength(7));
      expect(ops.weekdayNames, everyElement(matches(RegExp('^[a-zì]+\$'))));
      expect(ops.weekdayNames.first, 'lunedì');
      expect(ops.weekdayNames.last, 'domenica');
    });

    test('marks a fictional name with one tag, and a sample with another', () {
      expect(
        _matching(
          _texts,
          RegExp(
            r'\((?:fittizi[oa]|finto|fictional|example|campione|di finzione)\)',
            caseSensitive: false,
          ),
        ),
        isEmpty,
      );
      // Every `fantasia` that closes a tag is the tag `(di fantasia)`, or the
      // tag of a question (`(domanda di fantasia)`), as English has
      // `(fictional question)`.
      expect(
        _matching(
          _texts,
          RegExp(r'\((?!(?:domanda )?di fantasia\))[^()]*fantasia\)'),
        ),
        isEmpty,
      );
      expect(itSafety.fictionalMarker, '(di fantasia)');
      // The fictional places are Italian inventions, not the Korean ones of the
      // English data.
      expect(
        _matching(
          _texts,
          RegExp('Solbit|Garam|Mulpare|Solnae', caseSensitive: false),
        ),
        isEmpty,
      );
    });

    test('speaks with `Lei` and never with `tu`', () {
      // The forms of the second person singular that no text of a patient, a
      // customer, or a colleague writes.
      final tu = RegExp(
        r'(?<![\p{L}’])(?:tu|ti|tuo|tua|tuoi|tue|puoi|vuoi|hai|devi|sai|vedi|'
        r'controlla|annota|indica|inserisci|scegli|clicca)(?![\p{L}’])',
        caseSensitive: false,
        unicode: true,
      );
      expect(_matching(_texts, tu), isEmpty);
      // `Lei` is written in capitals when it speaks to the reader.
      final script = _itClinic.texts!.counselScript;
      expect(script.greeting, contains('Sua'));
      expect(script.bookYesReply, contains('Le prenoto'));
      expect(
        _it.texts['helpdesk.draftBody']!,
        everyElement(matches(RegExp('^(?:Controlli|Annoti|Indichi) '))),
      );
    });

    test('writes the variables of a notification template in Italian', () {
      final names = <String>{
        for (final template in _itSaas.messageTemplates)
          for (final match in RegExp(r'#\{([^}]*)\}').allMatches(template.body))
            match.group(1)!,
      };
      expect(names, <String>{'nome', 'struttura', 'data_ora', 'ora', 'link'});
      for (final code in <String>['RSV_CREATED', 'SURVEY', 'AD_EVENT']) {
        final body = _forLanguage('it').saas.messageTemplate(code: code).body;
        expect(
          body,
          startsWith(code == 'AD_EVENT' ? '[Pubblicità]' : 'Gentile'),
        );
        expect(body, contains('#{'));
      }
    });
  });

  group('the amounts of Italian are euros', () {
    final f = _forLanguage('it');

    test('are written 1.234,56 € with a no-break space before the euro', () {
      for (final writer in <String Function(num)>[
        f.clinic.money,
        f.saas.money,
      ]) {
        expect(writer(1234.56), '1.234,56$_nbsp€');
        expect(writer(1234), '1.234,00$_nbsp€');
        expect(writer(20), '20,00$_nbsp€');
        expect(writer(999), '999,00$_nbsp€');
        expect(writer(-80), '-80,00$_nbsp€');
        expect(writer(2400000), '2.400.000,00$_nbsp€');
        expect(writer(0), '0,00$_nbsp€');
      }
    });

    test('have the code, the symbol, and the minor units of Italy', () {
      const italy = CoFakerCountries.italy;
      for (final currency in <CoCurrencyFormat>[
        _itClinic.currency,
        _itSaas.currency,
      ]) {
        expect(currency.code, italy.currencyCode);
        expect(currency.symbol, italy.currencySymbol);
        expect(currency.fractionDigits, italy.currencyMinorUnits);
        expect(currency.decimalSeparator, ',');
        expect(currency.groupSeparator, '.');
        expect(currency.pattern, '{amount}$_nbsp{symbol}');
      }
    });

    test('are the price of a procedure inside its euro band, rounded', () {
      final bands = <String, CoProcedureSpec>{
        for (final p in _itClinic.procedures) p.code: p,
      };
      final seen = <String>{};
      for (var i = 0; i < 160; i++) {
        final procedure = f.derive('procedure/$i').clinic.procedure();
        final band = bands[procedure.code]!;
        seen.add(procedure.code);
        expect(procedure.price, inInclusiveRange(band.minPrice, band.maxPrice));
        expect(procedure.price % _itClinic.priceScale.priceRounding, 0);
        expect(procedure.price, lessThan(3000));
      }
      expect(seen, bands.keys.toSet());
    });

    test('are the price of a package, a prepaid balance, and a payment', () {
      final scale = _itClinic.priceScale;
      for (var i = 0; i < 60; i++) {
        final g = f.derive('scale/$i');
        final package = g.clinic.package();
        expect(package.price % scale.packageRounding, 0);
        expect(package.price, lessThan(30000));
        final balance = g.clinic.prepaidBalance();
        expect(balance % scale.prepaidStep, 0);
        expect(balance, lessThanOrEqualTo(100 * scale.prepaidStep));
        final small = g.clinic.payment(amount: 120, method: 'card');
        expect(small.installmentMonths, 0);
        final split = g.clinic.splitPayment(amount: 40);
        expect(split, hasLength(1));
      }
      var installments = 0;
      for (var i = 0; i < 80; i++) {
        final months = f
            .derive('installment/$i')
            .clinic
            .payment(amount: 500, method: 'card')
            .installmentMonths;
        if (months != null && months > 0) installments++;
      }
      expect(installments, greaterThan(0));
    });

    test('write the price in a counseling quote with the euro format', () {
      for (var i = 0; i < 12; i++) {
        final session = f.derive('quote/$i').clinic.counselSession();
        expect(session.summary, contains('$_nbsp€'));
        expect(session.summary, contains(f.clinic.money(session.quotedPrice)));
        expect(session.summary, isNot(contains(r'$')));
        for (final turn in session.turns) {
          expect(turn.text, isNot(contains(r'$')));
          expect(turn.text, isNot(matches(RegExp('[₩원]'))));
        }
      }
    });

    test('follow the plans, the VAT, and the wallet of a euro back office', () {
      expect(
        <int>{for (final plan in _itSaas.plans) plan.monthlyPrice},
        <int>{69, 139, 249, 479},
      );
      expect(_itSaas.priceScale.vatRate, 0.22);
      for (var i = 0; i < 40; i++) {
        final invoice = f.derive('invoice/$i').saas.invoice();
        expect(invoice.vat, (invoice.supplyAmount * 0.22).round());
        expect(invoice.total, invoice.supplyAmount + invoice.vat);
      }
      final scale = _itSaas.priceScale;
      for (var i = 0; i < 20; i++) {
        final ledger = f.derive('wallet/$i').saas.prepaidLedger(count: 16);
        for (final entry in ledger) {
          if (entry.kind == 'topUp') {
            expect(scale.prepaidTopUps, contains(entry.amount));
            expect(entry.bonus, scale.bonusFor(entry.amount));
          } else {
            expect(entry.amount.abs(), lessThan(5000));
          }
          expect(entry.balanceAfter, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('Italian generates no value of the Korean data', () {
    final f = _forLanguage('it');

    test('masks an ID in the shape of an Italian tax code', () {
      // Sixteen characters, masked but for the three digits of the place.
      final shape = RegExp(r'^\*{12}\d{3}\*$');
      for (var i = 0; i < 20; i++) {
        final patient = f.derive('patient/$i').clinic.patient();
        expect(patient.rrnMasked, matches(shape));
      }
    });

    test('writes the business number of a tenant as eleven digits', () {
      for (var i = 0; i < 20; i++) {
        final tenant = f.derive('tenant/$i').saas.tenant();
        expect(tenant.businessNumber, matches(RegExp(r'^\d{11}$')));
      }
    });

    test('gives a plain authorization code, and no cash receipt number', () {
      for (var i = 0; i < 20; i++) {
        final card = f
            .derive('card/$i')
            .clinic
            .payment(amount: 90, method: 'card');
        expect(card.approvalNo, matches(RegExp(r'^\d{6}$')));
        expect(card.cashReceiptNo, isNull);
        final cash = f
            .derive('cash/$i')
            .clinic
            .payment(amount: 90, method: 'cash');
        expect(cash.cashReceiptNo, isNull);
      }
    });

    test('gives the phone number and the address of Italy', () {
      for (var i = 0; i < 20; i++) {
        final patient = f.derive('patient/$i').clinic.patient();
        expect(patient.phone, matches(RegExp(r'^30\d \d{3} \d{4}$')));
        expect(patient.postalCode, matches(RegExp(r'^\d{5}$')));
        expect(patient.address1, isNot(matches(RegExp('[가-힣]'))));
        expect(patient.address1, contains(','));
      }
    });

    test('names no Korean holiday in a closure notice', () {
      // Chuseok, Seollal, and Children’s Day of the Korean calendar.
      for (final date in <DateTime>[
        DateTime.utc(2026, 9, 25),
        DateTime.utc(2027, 2, 6),
        DateTime.utc(2026, 5, 5),
      ]) {
        final notice = f.clinic.closureNotice(date: date);
        expect(notice.holiday, isNull);
        expect(notice.from, notice.to);
        expect(notice.body, contains('Motivo:'));
        expect(notice.body, isNot(contains('Chuseok')));
      }
    });
  });

  group('the clinic and the SaaS of Italian read as Italian', () {
    final f = _forLanguage('it');

    test('names a clinic by its kind first and its name after it', () {
      final suffixes = <String>[
        for (final s in _itClinic.specialties) s.clinicSuffix,
      ];
      final prefixes = _itClinic.clinicNamePrefixes;
      final seen = <String>{};
      for (var i = 0; i < 80; i++) {
        final name = f.derive('clinic/$i').clinic.clinicName();
        seen.add(name);
        expect(suffixes.any(name.startsWith), isTrue, reason: name);
        expect(prefixes.any(name.endsWith), isTrue, reason: name);
      }
      expect(seen.length, greaterThan(20));
      expect(
        f.clinic.clinicName(specialty: 'Pediatria'),
        startsWith('Ambulatorio pediatrico '),
      );
    });

    test('writes a closure notice with a date, a reason, and a reopening', () {
      final date = RegExp('$_weekdays \\d{1,2}/\\d{1,2}');
      for (var i = 0; i < 12; i++) {
        final day = DateTime.utc(2026, 3, 1).add(Duration(days: i * 11));
        final notice = f.derive('closure/$i').clinic.closureNotice(date: day);
        expect(
          notice.title,
          matches(RegExp('^Chiusura $_weekdays \\d{1,2}/\\d{1,2}\$')),
        );
        expect(
          notice.body,
          matches(
            RegExp(
              '^.+: chiusura $_weekdays \\d{1,2}/\\d{1,2}\\. '
              'Motivo: [^.]+\\. Le visite riprendono regolarmente '
              '$_weekdays \\d{1,2}/\\d{1,2}\\.\$',
            ),
          ),
        );
        expect(date.hasMatch(notice.body), isTrue);
        expect(
          _itClinic.ops!.closureReasons.any(notice.body.contains),
          isTrue,
          reason: notice.body,
        );
      }
    });

    test('writes a date range with `da` and `a`, and no article', () {
      final ops = _itClinic.ops!;
      expect(ops.dateRangeFormat, 'da {from} a {to}');
      expect(ops.dateFormat, '{weekday} {day}/{month}');
      expect(
        ops.dateRangeFormat
            .replaceAll('{from}', 'lunedì 24/11')
            .replaceAll('{to}', 'giovedì 27/11'),
        'da lunedì 24/11 a giovedì 27/11',
      );
    });

    test('mentions a staff member with the role in parentheses', () {
      for (var i = 0; i < 12; i++) {
        final note = f
            .derive('note/$i')
            .clinic
            .teamNote(patient: 'Ines Moretti');
        expect(note.text, contains('Ines Moretti'));
        expect(note.text, matches(RegExp(r'@[^@()]+ \([^()]+\)')));
        expect(note.text, isNot(contains('{')));
      }
      final named = f.clinic.teamNote(
        patient: 'Ines Moretti',
        authors: <String>['Lea Martini'],
        mentions: <String>['Hugo Petri'],
      );
      expect(named.text, contains('@Hugo Petri'));
      expect(named.text, isNot(contains('@Hugo Petri (')));
    });

    test('gives a role that is a function and not a title of one sex', () {
      // A staff member is drawn a woman most of the time, so no role label is
      // a title in the masculine.
      final labels = _itClinic.staffRoles.values.toSet();
      expect(labels, isNot(contains('Direttore sanitario')));
      expect(labels, isNot(contains('Infermiere')));
      expect(labels, contains('Direzione sanitaria'));
      expect(labels, contains('Personale infermieristico'));
      expect(labels, contains('Estetista'));
    });

    test('names a device with `n.` and its number', () {
      for (var i = 0; i < 12; i++) {
        final device = f.derive('device/$i').clinic.device(number: 2);
        expect(device.name, '${device.kindLabel} n. 2');
      }
    });

    test('names a package by its sessions, and a compound one with a gift', () {
      for (var i = 0; i < 12; i++) {
        final g = f.derive('package/$i');
        final package = g.clinic.package();
        expect(package.name, endsWith(' · ${package.sessions} sedute'));
        final compound = g.clinic.compoundPackageName();
        expect(compound, endsWith(' + crema riparatrice in omaggio'));
        expect(
          RegExp(r' \((?:3|5|10) sedute\)').allMatches(compound),
          hasLength(greaterThanOrEqualTo(2)),
        );
      }
    });

    test('names a drug with its form and its strength', () {
      final stems = _itClinic.drugStems;
      for (var i = 0; i < 40; i++) {
        final name = f.derive('drug/$i').clinic.drugName();
        expect(
          name,
          matches(
            RegExp(
              '^(?:${stems.join('|')}) (?:compresse|capsule|pomata|crema) '
              '\\d+ (?:mg|g)\$',
            ),
          ),
        );
      }
    });

    test('names an operator action and an incident with the name first', () {
      final ops = _itSaas.ops!;
      expect(
        ops.operatorActions['tenant.approve']!.summary,
        '{target}: iscrizione approvata.',
      );
      expect(
        ops.operatorActions['notice.publish']!.summary,
        'Avviso «{target}» pubblicato.',
      );
      for (var i = 0; i < 12; i++) {
        final incident = f.derive('incident/$i').saas.incidents().first;
        expect(incident.title, contains(': '));
        expect(incident.title, isNot(contains('{')));
        final activity = f.derive('activity/$i').saas.tenantActivity();
        expect(activity.text, matches(RegExp(r'^[^:]+: \d+$')));
      }
    });

    test('has an Italian label for every code', () {
      expect(f.clinic.label('noShow'), 'Assente');
      expect(f.clinic.label('prepaid'), 'Saldo prepagato');
      expect(f.clinic.label('counseling'), 'Consulenza');
      expect(f.clinic.label('desk'), 'Accoglienza');
      expect(f.saas.label('pastDue'), 'Pagamento in ritardo');
      expect(
        f.saas.label('revealRrn'),
        'Visualizzazione del numero di identificazione',
      );
    });

    test('writes the detail of a failed check after its label', () {
      expect(_itSaas.ops!.masterCheckDetail, 'Righe non conformi: {n}');
    });
  });

  group('the safety conventions of Italian', () {
    final f = _forLanguage('it');

    test('a fictional drug, product, and event name carries (di fantasia)', () {
      for (final role in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
        'remit.bankNameFictional',
        'content.seriesTitle',
        'campaign.brandName',
      ]) {
        for (var i = 0; i < 12; i++) {
          expect(
            _role(f, role, i),
            endsWith(itSafety.fictionalMarker),
            reason: role,
          );
        }
      }
    });

    test('the two creators are Italian names of fiction', () {
      expect(_it.texts['fandom.creatorName'], <String>[
        'Giardino della Clessidra',
        'Venatura del Cielo',
      ]);
      final seen = <String>{
        for (var i = 0; i < 6; i++) _role(f, 'fandom.creatorName', i),
      };
      expect(seen, <String>{'Giardino della Clessidra', 'Venatura del Cielo'});
    });

    test('a masked name, a card, and a plate stay masked', () {
      for (var i = 0; i < 20; i++) {
        expect(
          _role(f, 'homecare.recipientName', i),
          matches(RegExp(r'^[A-ZÀ-Ý]\*\*\*$')),
        );
        expect(
          _role(f, 'hospitality.guestName', i),
          matches(RegExp(r'^[A-ZÀ-Ý]\*\*\*$')),
        );
        expect(
          _role(f, 'logistics.vehiclePlate', i),
          matches(RegExp(r'^AB \d\d●●\d\d CD$')),
        );
        expect(
          _role(f, 'logistics.entranceHint', i),
          isNot(matches(RegExp(r'#\d{4}'))),
        );
      }
    });

    test('a general-information text starts with its prefix', () {
      expect(itSafety.generalInfoPrefix, 'Informazione generale');
      for (final key in <String>[
        'brokerage.qnaAnswerGeneric',
        'brokerage.consultNoteGeneric',
      ]) {
        for (final text in _it.texts[key]!) {
          expect(text, startsWith(itSafety.generalInfoPrefix), reason: key);
        }
      }
    });

    test('an entrance hint and a guardian label take no door code', () {
      final hints = _it.texts['logistics.entranceHint']!;
      expect(hints.where((text) => text.contains('••••')), isNotEmpty);
      for (final text in hints) {
        expect(text, isNot(matches(RegExp(r'\d{4}'))));
      }
      for (final key in <String>[
        'daycare.guardianLabel',
        'daycare.teacherName',
      ]) {
        expect(_it.texts[key]!.single, contains('{name1}'));
      }
    });
  });
}

/// Whether the punctuation mark at [index] of [text] is followed as Italian
/// writes it: by a space or the end of the text, or, for the colon of a time,
/// by a digit that follows a digit.
bool _punctuationFollowedProperly(String text, int index) {
  if (index == text.length - 1) return true;
  final next = text[index + 1];
  if (next == ' ' || next == '\n') return true;
  if (text[index] == ':' && index > 0) {
    final previous = text[index - 1];
    return RegExp(r'\d').hasMatch(previous) && RegExp(r'\d').hasMatch(next);
  }
  return false;
}
