import 'dart:io';

import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

/// The no-break space that French writes before `:`, `;`, `?`, `!`, `%`, a
/// unit, and the symbol of the euro, and the narrow one between thousands.
const String _nbsp = '\u00A0';
const String _nnbsp = '\u202F';

final DateTime _now = DateTime.utc(2026, 1, 15);

CoFaker _forLanguage(String tag, {int seed = 7}) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: _now,
  domains: CoFakerDomains.all,
);

CoFaker _faker(String locale, {int seed = 7}) =>
    CoFaker(locale: locale, seed: seed, now: _now, domains: CoFakerDomains.all);

String _value(CoFaker f, String role, int index) =>
    f.schema.record(
          {'value': 'String'},
          roles: {'value': role},
          index: index,
        )['value']
        as String;

typedef _Text = ({String where, String text, bool format});

/// Every text of French that a person reads, with its place: the domain text
/// bundle, the clinic data, and the SaaS data. A code is left out.
List<_Text> _frenchTexts(CoLanguageData data) {
  final tables = <CoTextTable>[
    CoLanguageTexts.ofBundle(data.bundle),
    CoLanguageTexts.ofClinic(data.clinic!),
    CoLanguageTexts.ofSaas(data.saas!),
  ];
  return <_Text>[
    for (final table in tables)
      for (final slot in table.slots.values)
        if (slot.kind == CoTextKind.text || slot.kind == CoTextKind.format)
          for (final row in slot.rows)
            for (final text in slot.cellsOf(row)!)
              (
                where: '${slot.name}[$row]',
                text: text,
                format: slot.kind == CoTextKind.format,
              ),
  ];
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

/// The vowels that make `le`, `la`, `de`, and `que` elide.
/// Entries of the bundle that a reader checked by hand: the English text, and
/// the French text that stands at the same position of the same key. They are
/// the evidence that the lists are translations entry by entry and not only
/// lists of the same length: a swapped or a shifted entry fails here, where
/// the check by position alone would still pass.
final List<(String, String, String)> _pairs = <(String, String, String)>[
  ('fx.currencyName.USD', 'US dollar', 'Dollar américain'),
  ('fx.currencyName.NPR', 'Nepalese rupee', 'Roupie népalaise'),
  (
    'fx.branchName',
    'Demo airport T1 exchange',
    'Bureau de change démo, aéroport T1',
  ),
  ('fx.branchName', 'Demo Mulpare exchange', 'Bureau de change démo, Frênaie'),
  ('fx.tierName', 'Silver', 'Argent'),
  ('fx.tierName', 'Gold', 'Or'),
  ('remit.countryName.VN', 'Vietnam', 'Viêt Nam'),
  ('remit.countryName.US', 'United States', 'États-Unis'),
  ('vet.petName', 'Cloud', 'Nuage'),
  ('vet.breed.dog', 'Maltese', 'Bichon maltais'),
  ('vet.breed.dog', 'Poodle', 'Caniche'),
  ('vet.breed.dog', 'Mixed dog', 'Chien croisé'),
  ('vet.breed.cat', 'Mixed cat', 'Chat croisé'),
  ('vet.coatColor', 'White', 'Blanc'),
  ('vet.coatColor', 'Gray', 'Gris'),
  ('vet.clinicRoom', 'Vaccination room', 'Salle de vaccination'),
  ('grocery.categoryName', 'Fruit', 'Fruits'),
  ('grocery.categoryName', 'Seafood', 'Produits de la mer'),
  ('grocery.categoryName', 'Dairy', 'Produits laitiers'),
  ('catalog.groceryName', 'Strawberries', 'Fraises'),
  ('catalog.groceryName', 'Milk', 'Lait'),
  ('catalog.commerceName', 'Ceramic cup', 'Tasse en céramique'),
  ('dental.dentalProcedure', 'Scaling', 'Détartrage'),
  (
    'dental.dentalProcedure',
    'Root canal example',
    'Exemple de traitement de canal',
  ),
  (
    'dental.dentalProcedure',
    'Resin restoration example',
    'Exemple de restauration en résine',
  ),
  (
    'dental.dentalProcedure',
    'Crown planning example',
    'Exemple de planification de couronne',
  ),
  ('dental.dentalMaterial', 'Zirconia (example)', 'Zircone (exemple)'),
  ('homecare.careGrade', 'Care grade 5', 'Niveau de prise en charge 5'),
  (
    'homecare.careGrade',
    'Cognitive support grade',
    'Niveau d’accompagnement cognitif',
  ),
  ('homecare.careTaskLabel', 'Meal assistance', 'Aide au repas'),
  ('travel_wallet.cityName', 'Hanoi', 'Hanoï'),
  ('travel_wallet.tripName', 'Bangkok weekend', 'Week-end à Bangkok'),
  (
    'b2b_trade.holdReason',
    'Delivery date check (example)',
    'Vérification de la date de livraison (exemple)',
  ),
  (
    'group_deal.dealTitle',
    'Cotton towel group deal',
    'Achat groupé de serviettes en coton',
  ),
  ('fitness.classLevelLabel', 'beginner', 'débutant'),
  ('fitness.classLevelLabel', 'advanced', 'avancé'),
  ('fitness.classCategoryLabel', 'Mat', 'Tapis'),
  ('fitness.classCategoryLabel', 'Reformer', 'Reformer'),
  ('fitness.classCategoryLabel', 'Chair', 'Chaise'),
  ('fitness.classCategoryLabel', 'Yoga', 'Yoga'),
  ('space_rental.amenity', 'Water dispenser', 'Fontaine à eau'),
  ('dining.menuName', 'Tomato pasta', 'Pâtes à la tomate'),
  ('dining.menuName', 'Warm tea', 'Thé chaud'),
  ('daycare.className', 'Sun class', 'Classe du Soleil'),
  ('daycare.className', 'Star class', 'Classe des Étoiles'),
  ('daycare.ageLabel', 'Age 1', '1 an'),
  ('daycare.ageLabel', 'Age 5', '5 ans'),
  ('daycare.snackMenu', 'Plain yogurt', 'Yaourt nature'),
  ('daycare.allergenLabel', 'Egg', 'Œuf'),
  ('daycare.allergenLabel', 'Wheat', 'Blé'),
  ('exam_prep.subjectName', 'Networking', 'Réseaux'),
  ('exam_prep.unitName', 'Routing', 'Routage'),
  ('exam_prep.correctChoice', 'Primary key', 'Clé primaire'),
  ('exam_prep.correctChoice', 'WHERE', 'WHERE'),
  ('exam_prep.correctChoice', 'TCP', 'TCP'),
  ('exam_prep.correctChoice', 'Router', 'Routeur'),
  ('exam_prep.correctChoice', 'HTTP', 'HTTP'),
  ('exam_prep.correctChoice', 'Variable', 'Variable'),
  ('exam_prep.correctChoice', 'Stack', 'Pile'),
  ('exam_prep.correctChoice', 'Hash function', 'Fonction de hachage'),
  ('exam_prep.correctChoice', 'Least privilege', 'Moindre privilège'),
  ('exam_prep.wrongChoice1', 'Speaker', 'Haut-parleur'),
  ('exam_prep.wrongChoice2', 'Keyboard', 'Clavier'),
  ('exam_prep.wrongChoice3', 'Monitor', 'Écran'),
  (
    'exam_prep.questionStem',
    'Which key distinguishes rows in a table?',
    'Quelle clé permet de distinguer les lignes d’une table$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'Which SQL clause selects rows by a condition?',
    'Quelle clause SQL permet de sélectionner des lignes selon une condition$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'Which transport protocol handles ordering and retransmission?',
    'Quel protocole de transport gère l’ordre et la retransmission des données$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'Which device selects the next packet route?',
    'Quel équipement choisit le prochain chemin d’un paquet$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'Which protocol expresses web requests and responses?',
    'Quel protocole sert à exprimer les requêtes et les réponses web$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'What stores a value under a program name?',
    'Qu’est-ce qui permet de stocker une valeur sous un nom dans un programme$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'Which structure removes the last inserted value first?',
    'Quelle structure retire en premier la dernière valeur insérée$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'What computes a fixed-length summary of an input?',
    'Qu’est-ce qui calcule une empreinte de longueur fixe à partir d’une entrée$_nbsp?',
  ),
  (
    'exam_prep.questionStem',
    'Which principle grants only the permissions needed for a task?',
    'Quel principe n’accorde que les droits nécessaires à une tâche$_nbsp?',
  ),
  ('hrd.departmentName', 'Sales', 'Ventes'),
  ('hrd.departmentName', 'Production', 'Fabrication'),
  ('hrd.departmentName', 'Research', 'Recherche'),
  ('hrd.departmentName', 'Support', 'Support client'),
  ('hrd.departmentName', 'Administration', 'Gestion administrative'),
  ('hrd.departmentName', 'Logistics', 'Logistique'),
  ('hrd.jobTitle', 'Team lead', 'Chef d’équipe'),
  ('hrd.courseKind', 'Mandatory', 'Obligatoire'),
  ('neighborhood.keyword', 'local news', 'actualités locales'),
  ('meetup.interestTag', 'Running', 'Course à pied'),
  ('meetup.interestTag', 'Hiking', 'Randonnée'),
  (
    'meetup.cadenceLabel',
    'Alternate Sundays 10:00',
    'Un dimanche sur deux à 10${_nbsp}h',
  ),
  ('content.genreName', 'Everyday life', 'Vie quotidienne'),
  ('content.genreName', 'Essay', 'Essai'),
  ('content.audioTaxonomy', 'Audiobook', 'Livre audio'),
  ('helpdesk.topicName', 'Billing', 'Facturation'),
  ('helpdesk.topicName', 'Integration', 'Intégration'),
  (
    'campaign.failReason',
    'No marketing consent (example)',
    'Aucun consentement marketing (exemple)',
  ),
  ('workplace.department', 'Design team', 'Équipe design'),
  ('workplace.department', 'HR team', 'Ressources humaines'),
  ('workplace.shiftName', 'Weekend duty', 'Permanence du week-end'),
  ('workplace.accountName', 'Travel (example)', 'Déplacements (exemple)'),
  ('brokerage.serviceTypeName', 'Cleaning', 'Nettoyage'),
  ('brokerage.serviceTypeName', 'Lessons', 'Cours'),
  ('brokerage.serviceCategory', 'Home service', 'Services à domicile'),
  ('brokerage.milestoneLabel', 'Handoff record', 'Compte rendu de passation'),
  ('logistics.scanEvent', 'Hub arrival', 'Arrivée à la plateforme'),
  ('logistics.scanEvent', 'Delivery not completed', 'Livraison non effectuée'),
  ('logistics.freightType', 'Packaging', 'Emballages'),
  ('logistics.freightType', 'Household goods', 'Articles ménagers'),
  ('logistics.itemName', 'Brown rice 2kg', 'Riz complet 2${_nbsp}kg'),
  ('hospitality.hkCheckItem', 'Change bedding', 'Changer la literie'),
  ('hospitality.hkCheckItem', 'Check minibar', 'Vérifier le minibar'),
  ('hospitality.lostItemName', 'Blue umbrella', 'Parapluie bleu'),
  ('hospitality.lostItemName', 'Water bottle', 'Bouteille d’eau'),
  ('hospitality.amenityName', 'Toothbrush', 'Brosse à dents'),
  (
    'hospitality.folioItem',
    'Room service (example)',
    'Service en chambre (exemple)',
  ),
];

const String _vowel = 'aeiouàâäéèêëîïôöùûüœAEIOUÀÂÄÉÈÊËÎÏÔÖÙÛÜŒ';

/// What an elision may stand before: a vowel, a mute `h` (`l’hygiène`), and
/// a `y` (`l’yaourt`), while `de yoga` and `de hachage` do not elide.
const String _elidable = '${_vowel}yhYH';
const String _weekdays =
    '(?:lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)';

void main() {
  final data = CoLanguageData.registered('fr');
  final bundle = data.bundle;
  final english = CoL10nRegistry.english;
  final clinicData = CoL10nClinic.clinicOf('fr')!;
  final saasData = CoL10nClinic.saasOf('fr')!;
  final texts = _frenchTexts(data);

  group('the entry points of French', () {
    // A language setting, a language code, and a country locale all read the
    // French domain text, clinic data, and SaaS data.
    final entries = <String, CoFaker Function()>{
      'CoFaker.forLanguage("fr")': () => _forLanguage('fr'),
      'CoFaker.forLanguage("fr-FR")': () => _forLanguage('fr-FR'),
      'CoFaker.forLanguage("fr_FR.UTF-8")': () => _forLanguage('fr_FR.UTF-8'),
      'CoFaker(locale: "fr")': () => _faker('fr'),
      'CoFaker(locale: "fr_FR")': () => _faker('fr_FR'),
      'CoFaker(locale: "fr-FR")': () => _faker('fr-FR'),
    };

    for (final entry in entries.entries) {
      test('${entry.key} reads the French bundle, clinic, and SaaS data', () {
        final f = entry.value();
        expect(f.l10n.language, 'fr');
        expect(identical(f.clinic.data, clinicData), isTrue);
        expect(identical(f.saas.data, saasData), isTrue);
        for (final key in bundle.texts.keys) {
          expect(f.l10n.list(key), bundle.texts[key], reason: key);
        }
      });
    }

    test('give the same domain text and the same record for a seed', () {
      final fakers = <CoFaker>[for (final entry in entries.values) entry()];
      for (final role in <String>[
        'dental.dentalProcedure',
        'vet.vetDrug',
        'exam_prep.questionStem',
        'neighborhood.postTitle',
        'hospitality.menuItem',
        'brokerage.qnaAnswerGeneric',
      ]) {
        for (var i = 0; i < 6; i++) {
          final values = <String>{for (final f in fakers) _value(f, role, i)};
          expect(values, hasLength(1), reason: '$role[$i]: $values');
        }
      }
      final summaries = <String>{
        for (final f in fakers)
          f.clinic.counselSession(topic: 'toning').summary,
      };
      expect(summaries, hasLength(1), reason: '$summaries');
      final notices = <String>{
        for (final f in fakers)
          f.clinic.closureNotice(date: DateTime.utc(2026, 11, 13)).body,
      };
      expect(notices, hasLength(1), reason: '$notices');
    });

    test('are the French data and not the English one', () {
      for (final tag in <String>['fr', 'fr_FR']) {
        final f = _faker(tag);
        expect(f.clinic.data, isNot(same(CoFakerClinicData.english)));
        expect(f.saas.data, isNot(same(CoFakerSaasData.english)));
        expect(_value(f, 'dental.dentalProcedure', 0), isNot('Scaling'));
        expect(f.clinic.money(1234), isNot(contains(r'$')));
      }
      // A language that is not French keeps its own data.
      expect(_faker('de').clinic.data, same(CoFakerClinicData.english));
    });
  });

  group('the same seed picks the same record as English', () {
    test('every role that reads a list gives the translation of the entry '
        'that English gives', () {
      final en = _forLanguage('en');
      final fr = _forLanguage('fr');
      final other = _forLanguage('fr', seed: 436);
      final otherEn = _forLanguage('en', seed: 436);
      var checked = 0;
      for (final pack in CoFakerDomains.all) {
        for (final role in pack.roles.keys) {
          final key = '${pack.name}.$role';
          final enList = english.texts[key];
          final frList = bundle.texts[key];
          if (enList == null || frList == null) continue;
          // A template that a value fills is not an entry of the list.
          if (enList.any((text) => text.contains('{'))) continue;
          expect(frList, hasLength(enList.length), reason: key);
          for (var i = 0; i < 8; i++) {
            for (final pair in <(CoFaker, CoFaker)>[
              (en, fr),
              (otherEn, other),
            ]) {
              final enValue = _value(pair.$1, key, i);
              final frValue = _value(pair.$2, key, i);
              final positions = <int>[
                for (var k = 0; k < enList.length; k++)
                  if (enList[k] == enValue) k,
              ];
              if (positions.isEmpty) continue;
              expect(
                positions.map((k) => frList[k]),
                contains(frValue),
                reason: '$key[$i]: "$enValue" is "${frList[positions.first]}"',
              );
              checked++;
            }
          }
        }
      }
      expect(checked, greaterThan(2000), reason: 'the roles that were read');
    });

    test('a pet, an exchange currency, and a question are the translation', () {
      final en = _forLanguage('en');
      final fr = _forLanguage('fr');
      for (final kind in <String>['dog', 'cat', 'small_mammal', 'bird']) {
        final enList = english.texts['vet.breed.$kind']!;
        final frList = bundle.texts['vet.breed.$kind']!;
        for (var i = 0; i < 6; i++) {
          final enPet = en.derive('pet/$kind/$i').vet.pet(animalKind: kind);
          final frPet = fr.derive('pet/$kind/$i').vet.pet(animalKind: kind);
          expect(frPet.breed, frList[enList.indexOf(enPet.breed)]);
          expect(frPet.weightKg, enPet.weightKg);
          expect(
            frPet.coatColor,
            bundle.texts['vet.coatColor']![english.texts['vet.coatColor']!
                .indexOf(enPet.coatColor)],
          );
        }
      }
      for (final code in <String>['USD', 'JPY', 'EUR', 'CNY', 'THB']) {
        expect(
          fr.fx.currency(code: code).name,
          bundle.texts['fx.currencyName.$code']!.single,
        );
      }
      final enExplanations = english.texts['exam_prep.explanation']!;
      for (var i = 0; i < 18; i++) {
        final enQuestion = en.derive('question/$i').examPrep.question(index: i);
        final frQuestion = fr.derive('question/$i').examPrep.question(index: i);
        final at = enExplanations.indexOf(enQuestion.explanation);
        expect(
          frQuestion.explanation,
          bundle.texts['exam_prep.explanation']![at],
        );
        expect(
          frQuestion.choices[frQuestion.answerKeys.single - 1],
          bundle.texts['exam_prep.correctChoice']![at],
        );
        expect(frQuestion.choices.toSet(), hasLength(4));
        expect(
          frQuestion.explanation,
          contains(frQuestion.choices[frQuestion.answerKeys.single - 1]),
        );
      }
    });

    test(
      'the entry of French at the place of an English entry translates it',
      () {
        for (final (key, en, fr) in _pairs) {
          final enList = english.texts[key];
          final frList = bundle.texts[key];
          expect(enList, isNotNull, reason: key);
          final at = enList!.indexOf(en);
          expect(at, isNonNegative, reason: '$key has no "$en" in English');
          expect(frList![at], fr, reason: '$key[$at] translates "$en"');
        }
        expect(
          _pairs.map((pair) => pair.$1).toSet(),
          hasLength(greaterThan(55)),
        );
      },
    );

    test('the clinic and SaaS data translate the entry of the same code', () {
      final en = CoFakerClinicData.english;
      expect(
        {for (final p in clinicData.procedures) p.code: p.name},
        {
          'CONS01': 'Première consultation',
          'BTX-F': 'Toxine botulique front',
          'FIL-L': 'Acide hyaluronique lèvres 1${_nbsp}ml',
          'LT-01': 'Laser picoseconde, uniformisation du teint',
          'HIFU-300': 'Lifting par ultrasons focalisés, 300 lignes',
          'ACN-01': 'Extraction des comédons',
          'CARE-01': 'Soin apaisant du visage par LED',
          'DOC-01': 'Certificat médical',
        },
      );
      expect(
        {for (final d in clinicData.diagnoses) d.code: d.name},
        {
          'L70.0': 'Acné vulgaire',
          'L81.1': 'Mélasma',
          'B07': 'Verrues virales',
          'L20.9': 'Dermatite atopique, sans précision',
          'L30.9': 'Dermatite, sans précision',
          'L71.9': 'Rosacée, sans précision',
        },
      );
      expect(
        [for (final s in en.specialties) s.name],
        [
          'Dermatology',
          'Plastic Surgery',
          'Family Medicine',
          'Internal Medicine',
          'Pediatrics',
        ],
      );
      expect(
        [for (final s in clinicData.specialties) s.name],
        [
          'Dermatologie',
          'Chirurgie plastique',
          'Médecine générale',
          'Médecine interne',
          'Pédiatrie',
        ],
      );
      expect(
        [for (final v in clinicData.visitPurposes) v.name],
        ['Consultation', 'Acte', 'Traitement', 'Soin'],
      );
      expect(
        [for (final v in en.visitPurposes) v.name],
        ['Consultation', 'Procedure', 'Treatment', 'Care'],
      );
      expect(
        clinicData.staffRoles,
        containsPair('nurse', 'Infirmier diplômé d’État'),
      );
      expect(clinicData.staffRoles, containsPair('doctor', 'Médecin'));
      expect(clinicData.staffRoles, containsPair('desk', 'Accueil'));
      expect(
        clinicData.labels,
        containsPair('uninsured', 'À la charge du patient'),
      );
      expect(clinicData.labels, containsPair('noShow', 'Absent'));
      expect(clinicData.labels, containsPair('transfer', 'Virement bancaire'));
      expect(
        {for (final p in saasData.plans) p.code: p.name},
        {
          'starter': 'Essentiel',
          'standard': 'Standard',
          'pro': 'Pro',
          'enterprise': 'Entreprise',
        },
      );
      expect(
        {for (final t in saasData.messageTemplates) t.code: t.name},
        {
          'RSV_CREATED': 'Rendez-vous réservé',
          'RSV_CANCELLED': 'Rendez-vous annulé',
          'RSV_REMIND_D1': 'Rappel',
          'QUESTIONNAIRE': 'Questionnaire avant la visite',
          'SURVEY': 'Enquête de satisfaction',
          'AD_EVENT': 'Promotion (publicité)',
        },
      );
      expect(
        [for (final n in saasData.notices) (n.category, n.title)],
        [
          ('maintenance', 'Maintenance programmée'),
          ('release', 'Nouvelles fonctionnalités disponibles'),
          ('notice', 'Mise à jour des tarifs'),
          ('notice', 'Notifications retardées'),
        ],
      );
    });

    test('a French text keeps the figures of its English text', () {
      // The figures of the alerts, the claim-check ROW_DELTA, the consent
      // clauses, and the prices of the plans are the English ones.
      final enOps = CoFakerSaasOps.english;
      final frOps = saasData.ops!;
      for (var i = 0; i < enOps.alerts.length; i++) {
        expect(frOps.alerts[i].code, enOps.alerts[i].code);
        expect(
          RegExp(r'\d+').allMatches(frOps.alerts[i].message).map((m) => m[0]),
          RegExp(r'\d+').allMatches(enOps.alerts[i].message).map((m) => m[0]),
          reason: frOps.alerts[i].code,
        );
      }
      expect(
        RegExp(r'\d+').firstMatch(frOps.masterChecks['ROW_DELTA']!)![0],
        '5',
      );
      for (final key in <String>['exam_prep.explanation']) {
        expect(bundle.texts[key], hasLength(english.texts[key]!.length));
      }
    });

    test('the clinic and SaaS lists have the length of the English ones', () {
      final english = CoFakerClinicData.english;
      expect(clinicData.specialties, hasLength(english.specialties.length));
      expect(clinicData.procedures, hasLength(english.procedures.length));
      expect(
        [for (final p in clinicData.procedures) p.code],
        [for (final p in english.procedures) p.code],
      );
      expect(
        [for (final d in clinicData.diagnoses) (d.code, d.nameEn)],
        [for (final d in english.diagnoses) (d.code, d.nameEn)],
      );
      expect(clinicData.staffRoles.keys, english.staffRoles.keys);
      expect(clinicData.labels.keys, english.labels.keys);
      expect(
        [for (final plan in saasData.plans) plan.code],
        [for (final plan in CoFakerSaasData.english.plans) plan.code],
      );
      expect(
        saasData.messageTemplates.map((t) => t.code),
        CoFakerSaasData.english.messageTemplates.map((t) => t.code),
      );
    });
  });

  group('the typography of French', () {
    test('has texts to check', () {
      expect(texts.length, greaterThan(1300));
    });

    test('writes a no-break space as an escape in its source files', () {
      // A literal no-break space is a character that no reviewer can see, so
      // the data files write `U+00A0` and `U+202F`, and the tests above read
      // what the escapes make.
      for (final name in <String>['bundle', 'clinic', 'saas']) {
        final source = File('lib/src/l10n/fr/fr_$name.dart').readAsStringSync();
        expect(source, isNot(contains(_nbsp)), reason: 'fr_$name.dart');
        expect(source, isNot(contains(_nnbsp)), reason: 'fr_$name.dart');
        expect(source, contains(r'\u00A0'), reason: 'fr_$name.dart');
      }
    });

    test('writes the apostrophe as ’ and never as a straight quote', () {
      expect(_matching(texts, RegExp('[\'"]')), isEmpty);
    });

    test('puts a no-break space before : ; ? and !', () {
      // `:` may follow a digit (a time such as 06:00); the others never do.
      expect(
        _matching(texts, RegExp('[^$_nbsp$_nnbsp\\d]:|[^$_nbsp$_nnbsp][;?!]')),
        isEmpty,
      );
      expect(_matching(texts, RegExp(' [:;?!]')), isEmpty);
    });

    test('puts a no-break space inside « » and before % and a unit', () {
      expect(_matching(texts, RegExp('«(?!$_nbsp)|(?<!$_nbsp)»')), isEmpty);
      expect(_matching(texts, RegExp(r'\d%|\d %')), isEmpty);
      const unit = r'(?:mg|g|kg|ml|mL|cl|L|h|mmHg|°C)\b';
      expect(_matching(texts, RegExp('\\d $unit|\\d$unit')), isEmpty);
    });

    test('writes no text with a stray space', () {
      // A drug is `Adermex comprimé 10 mg`: its form starts with a space and
      // its unit with a no-break one.
      expect(
        _matching(
          texts,
          RegExp(r'^\s|\s$|  '),
          except: const <String>{
            'clinic.drugForms.form',
            'clinic.drugForms.unit',
          },
        ),
        isEmpty,
      );
    });

    test('contracts and elides `de`, `à`, and the articles', () {
      // A letter is a letter of any writing system: `\b` knows ASCII only, and
      // would take the `ç` of `leçon` for the end of the word `le`.
      const before = r'(?<![\p{L}’-])';
      const after = r'(?![\p{L}])';
      final bad = <RegExp>[
        // `de le` is `du`, `de les` is `des`, `à le` is `au`, `à les` is `aux`.
        RegExp(
          '$before(?:de|à) (?:le|les)$after',
          caseSensitive: false,
          unicode: true,
        ),
        // `le`, `la`, `de`, `que`, `ne`, `se`, `je`, `me`, `te`, and `ce`
        // before a vowel are `l’`, `d’`, `qu’`, ... (`ce` is `cet`), except in
        // an inversion: `dois-je en faire`, `puis-je aller`.
        RegExp(
          '$before(?:le|la|de|que|ne|se|je|me|te|ce) (?=[$_vowel])',
          caseSensitive: false,
          unicode: true,
        ),
        // ... and the elision never stands before a consonant.
        RegExp(
          '(?<![\\p{L}])(?:d|l|n|s|j|m|t|c|qu)’(?![$_elidable])',
          caseSensitive: false,
          unicode: true,
        ),
      ];
      for (final pattern in bad) {
        expect(_matching(texts, pattern), isEmpty, reason: '$pattern');
      }
    });

    test(
      'puts no article or preposition that a value would change before it',
      () {
        // A value that a template fills may start with a vowel or be of either
        // gender, so `de`, `du`, `des`, `le`, `la`, `les`, `au`, and `aux` never
        // stand right before one: `à` and `pour` do not change. A number
        // (`{n}`, `{sessions}`, a price) never elides or contracts. A date
        // label of a range is the one place: its values are weekdays, all
        // masculine and all consonants (`du mercredi 25/11 au jeudi 26/11`).
        const numeric =
            '(?:n|m|sessions|price|packagePrice|sys|dia|pulse|spo2|temp|'
            'glucose|number|day|month|version)';
        final pattern = RegExp(
          '(?<![\\p{L}])(?:(?:de|du|des|le|la|les|au|aux)|[dl]’)\\s*'
          '\\{(?!$numeric\\})',
          caseSensitive: false,
          unicode: true,
        );
        expect(
          _matching(
            texts,
            pattern,
            except: const <String>{'clinic.ops.dateRangeFormat'},
          ),
          isEmpty,
        );
      },
    );

    test('writes the months and the weekdays in lower case', () {
      expect(
        _matching(
          texts,
          RegExp(
            r'\b(?:Janvier|Février|Mars|Avril|Mai|Juin|Juillet|Août|'
            r'Septembre|Octobre|Novembre|Décembre)\b',
          ),
        ),
        isEmpty,
      );
      final ops = clinicData.ops!;
      expect(ops.weekdayNames, hasLength(7));
      expect(ops.weekdayNames, everyElement(matches(RegExp('^[a-z]+\$'))));
      expect(ops.weekdayNames.first, 'lundi');
      expect(ops.weekdayNames.last, 'dimanche');
    });

    test('marks a fictional name with one tag, and a sample with another', () {
      expect(
        _matching(texts, RegExp(r'\(fictive\)|fictional|\(example\)')),
        isEmpty,
      );
      // The fictional places are French inventions, not the Korean ones of the
      // English data.
      expect(
        _matching(
          texts,
          RegExp('Solbit|Garam|Mulpare|Solnae', caseSensitive: false),
        ),
        isEmpty,
      );
    });

    test('writes the variables of a notification template in French', () {
      final names = <String>{
        for (final template in saasData.messageTemplates)
          for (final match in RegExp(r'#\{([^}]*)\}').allMatches(template.body))
            match.group(1)!,
      };
      expect(names, <String>{'nom', 'clinique', 'date_heure', 'heure', 'lien'});
      for (final code in <String>['RSV_CREATED', 'SURVEY', 'AD_EVENT']) {
        final body = _forLanguage('fr').saas.messageTemplate(code: code).body;
        expect(body, startsWith(code == 'AD_EVENT' ? '[Pub]' : 'Bonjour'));
        expect(body, contains('#{'));
      }
    });
  });

  group('the amounts of French are euros', () {
    final f = _forLanguage('fr');

    test('are written 1 234,56 € with no-break spaces', () {
      for (final writer in <String Function(num)>[
        f.clinic.money,
        f.saas.money,
      ]) {
        expect(writer(1234.56), '1${_nnbsp}234,56$_nbsp€');
        expect(writer(1234), '1${_nnbsp}234,00$_nbsp€');
        expect(writer(20), '20,00$_nbsp€');
        expect(writer(999), '999,00$_nbsp€');
        expect(writer(-80), '-80,00$_nbsp€');
        expect(writer(2400000), '2${_nnbsp}400${_nnbsp}000,00$_nbsp€');
        expect(writer(0), '0,00$_nbsp€');
      }
    });

    test('have the code, the symbol, and the minor units of France', () {
      const france = CoFakerCountries.france;
      for (final currency in <CoCurrencyFormat>[
        clinicData.currency,
        saasData.currency,
      ]) {
        expect(currency.code, france.currencyCode);
        expect(currency.symbol, france.currencySymbol);
        expect(currency.fractionDigits, france.currencyMinorUnits);
        expect(currency.decimalSeparator, ',');
        expect(currency.groupSeparator, _nnbsp);
        expect(currency.pattern, '{amount}$_nbsp{symbol}');
      }
    });

    test('are the price of a procedure inside its euro band, rounded', () {
      final bands = {for (final p in clinicData.procedures) p.code: p};
      final seen = <String>{};
      for (var i = 0; i < 160; i++) {
        final procedure = f.derive('procedure/$i').clinic.procedure();
        final band = bands[procedure.code]!;
        seen.add(procedure.code);
        expect(procedure.price, inInclusiveRange(band.minPrice, band.maxPrice));
        expect(procedure.price % clinicData.priceScale.priceRounding, 0);
        expect(procedure.price, lessThan(3000));
      }
      expect(seen, bands.keys.toSet());
    });

    test('are the price of a package, a prepaid balance, and a payment', () {
      final scale = clinicData.priceScale;
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
        {for (final plan in saasData.plans) plan.monthlyPrice},
        {69, 149, 259, 499},
      );
      expect(saasData.priceScale.vatRate, 0.2);
      for (var i = 0; i < 40; i++) {
        final invoice = f.derive('invoice/$i').saas.invoice();
        expect(invoice.vat, (invoice.supplyAmount * 0.2).round());
        expect(invoice.total, invoice.supplyAmount + invoice.vat);
      }
      final scale = saasData.priceScale;
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

  group('French generates no value of the Korean data', () {
    final f = _forLanguage('fr');

    test('masks an ID as a French social security number', () {
      final shape = RegExp(
        '^\\*$_nbsp\\*\\*$_nbsp\\*\\*$_nbsp\\*\\*$_nbsp\\*\\*\\*$_nbsp\\*\\*\\*$_nbsp\\d\\d\$',
      );
      for (var i = 0; i < 20; i++) {
        final patient = f.derive('patient/$i').clinic.patient();
        expect(patient.rrnMasked, matches(shape));
      }
    });

    test('writes the business number of a tenant as nine digits', () {
      for (var i = 0; i < 20; i++) {
        final tenant = f.derive('tenant/$i').saas.tenant();
        expect(
          tenant.businessNumber,
          matches(RegExp('^\\d{3}$_nbsp\\d{3}$_nbsp\\d{3}\$')),
        );
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

    test('gives the phone number and the address of France', () {
      for (var i = 0; i < 20; i++) {
        final patient = f.derive('patient/$i').clinic.patient();
        expect(patient.phone, matches(RegExp(r'^0[1-9]( \d\d){4}$')));
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
        expect(notice.body, contains('Motif$_nbsp:'));
        expect(notice.body, isNot(contains('Chuseok')));
      }
    });
  });

  group('the clinic and the SaaS of French read as French', () {
    final f = _forLanguage('fr');

    test('names a clinic by its kind first and its name after it', () {
      final suffixes = [for (final s in clinicData.specialties) s.clinicSuffix];
      final prefixes = clinicData.clinicNamePrefixes;
      final seen = <String>{};
      for (var i = 0; i < 80; i++) {
        final name = f.derive('clinic/$i').clinic.clinicName();
        seen.add(name);
        expect(suffixes.any(name.startsWith), isTrue, reason: name);
        expect(prefixes.any(name.endsWith), isTrue, reason: name);
      }
      expect(seen.length, greaterThan(20));
      expect(
        f.clinic.clinicName(specialty: 'Pédiatrie'),
        startsWith('Cabinet de pédiatrie '),
      );
    });

    test('writes a closure notice with a date, a reason, and a reopening', () {
      final date = RegExp('$_weekdays \\d{1,2}/\\d{1,2}');
      for (var i = 0; i < 12; i++) {
        final day = DateTime.utc(2026, 3, 1).add(Duration(days: i * 11));
        final notice = f.derive('closure/$i').clinic.closureNotice(date: day);
        expect(
          notice.title,
          matches(RegExp('^Fermeture $_weekdays \\d{1,2}/\\d{1,2}\$')),
        );
        expect(
          notice.body,
          matches(
            RegExp(
              '^.+$_nbsp: fermeture $_weekdays \\d{1,2}/\\d{1,2}\\. '
              'Motif$_nbsp: [^.]+\\. Reprise normale des consultations '
              '$_weekdays \\d{1,2}/\\d{1,2}\\.\$',
            ),
          ),
        );
        expect(date.hasMatch(notice.body), isTrue);
        expect(
          clinicData.ops!.closureReasons.any(notice.body.contains),
          isTrue,
          reason: notice.body,
        );
      }
    });

    test('writes a date range with `du` and `au`', () {
      final ops = clinicData.ops!;
      expect(ops.dateRangeFormat, 'du {from} au {to}');
      expect(ops.dateFormat, '{weekday} {day}/{month}');
    });

    test('mentions a staff member with the role in parentheses', () {
      for (var i = 0; i < 12; i++) {
        final note = f
            .derive('note/$i')
            .clinic
            .teamNote(patient: 'Inès Moreau');
        expect(note.text, contains('Inès Moreau'));
        expect(note.text, matches(RegExp(r'@[^@()]+ \([^()]+\)')));
        expect(note.text, isNot(contains('{')));
      }
      final named = f.clinic.teamNote(
        patient: 'Inès Moreau',
        authors: <String>['Léa Martin'],
        mentions: <String>['Hugo Petit'],
      );
      expect(named.text, contains('@Hugo Petit'));
      expect(named.text, isNot(contains('@Hugo Petit (')));
    });

    test('names a device with `n°` and a no-break space', () {
      for (var i = 0; i < 12; i++) {
        final device = f.derive('device/$i').clinic.device(number: 2);
        expect(device.name, '${device.kindLabel} n°${_nbsp}2');
      }
    });

    test('names a package by its sessions, and a compound one with a gift', () {
      for (var i = 0; i < 12; i++) {
        final g = f.derive('package/$i');
        final package = g.clinic.package();
        expect(package.name, endsWith(' · ${package.sessions} séances'));
        final compound = g.clinic.compoundPackageName();
        expect(compound, endsWith(' + crème réparatrice offerte'));
        expect(
          RegExp(r' \((?:3|5|10) séances\)').allMatches(compound),
          hasLength(greaterThanOrEqualTo(2)),
        );
      }
    });

    test('names an operator action and an incident with the name first', () {
      final g = _forLanguage('fr');
      final ops = saasData.ops!;
      expect(
        ops.operatorActions['tenant.approve']!.summary,
        '{target}$_nbsp: inscription approuvée.',
      );
      expect(
        ops.operatorActions['notice.publish']!.summary,
        'Avis «$_nbsp{target}$_nbsp» publié.',
      );
      for (var i = 0; i < 12; i++) {
        final incident = g.derive('incident/$i').saas.incidents().first;
        expect(incident.title, contains('$_nbsp: '));
        expect(incident.title, isNot(contains('{')));
        final activity = g.derive('activity/$i').saas.tenantActivity();
        expect(activity.text, matches(RegExp('^[^:]+$_nbsp: \\d+\$')));
      }
    });

    test('has a French weekday and a French label for every code', () {
      expect(f.clinic.label('noShow'), 'Absent');
      expect(f.clinic.label('prepaid'), 'Solde prépayé');
      expect(f.clinic.label('counseling'), 'Conseil');
      expect(f.clinic.label('desk'), 'Accueil');
      expect(f.saas.label('pastDue'), 'Paiement en retard');
      expect(f.saas.label('revealRrn'), 'Affichage du numéro d’identification');
    });
  });

  group('the safety conventions of French', () {
    final f = _forLanguage('fr');

    test('a fictional drug, product, and event name carries (fictif)', () {
      for (final role in <String>[
        'vet.vetDrug',
        'vet.preventiveProduct',
        'daycare.drugLabel',
        'remit.bankNameFictional',
        'content.seriesTitle',
        'campaign.brandName',
      ]) {
        for (var i = 0; i < 12; i++) {
          expect(_value(f, role, i), endsWith('(fictif)'), reason: role);
        }
      }
    });

    test('the two creators are French names of fiction', () {
      expect(bundle.texts['fandom.creatorName'], <String>[
        'Jardin du Sablier',
        'Ciel de Lin',
      ]);
      final seen = <String>{
        for (var i = 0; i < 6; i++) _value(f, 'fandom.creatorName', i),
      };
      expect(seen, <String>{'Jardin du Sablier', 'Ciel de Lin'});
    });

    test('a masked name, a card, and a plate stay masked', () {
      for (var i = 0; i < 20; i++) {
        expect(
          _value(f, 'homecare.recipientName', i),
          matches(RegExp(r'^[A-ZÉ]\*\*\*$')),
        );
        expect(
          _value(f, 'hospitality.guestName', i),
          matches(RegExp(r'^[A-ZÉ]\*\*\*$')),
        );
        expect(
          _value(f, 'logistics.vehiclePlate', i),
          matches(RegExp(r'^\d\d●● AB \d\d$')),
        );
        expect(
          _value(f, 'logistics.entranceHint', i),
          isNot(matches(RegExp(r'#\d{4}'))),
        );
      }
    });

    test('a general-information text starts with its prefix', () {
      for (final key in <String>[
        'brokerage.qnaAnswerGeneric',
        'brokerage.consultNoteGeneric',
      ]) {
        for (final text in bundle.texts[key]!) {
          expect(text, startsWith('Information générale'), reason: key);
        }
      }
    });

    test('an entrance hint and a guardian label take no door code', () {
      final hints = bundle.texts['logistics.entranceHint']!;
      expect(hints.where((text) => text.contains('••••')), isNotEmpty);
      for (final text in hints) {
        expect(text, isNot(matches(RegExp(r'\d{4}'))));
      }
      for (final key in <String>[
        'daycare.guardianLabel',
        'daycare.teacherName',
      ]) {
        expect(bundle.texts[key]!.single, contains('{name1}'));
      }
    });
  });
}
