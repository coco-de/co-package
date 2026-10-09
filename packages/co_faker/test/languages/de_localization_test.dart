import 'package:co_faker/co_faker.dart';
import 'package:co_faker/src/l10n/co_l10n_clinic.dart';
import 'package:co_faker/src/language_coverage/co_language_text_scan.dart';
import 'package:co_faker/src/language_coverage/co_language_texts.dart';
import 'package:test/test.dart';

/// The no-break space between an amount and the euro sign.
const String _nbsp = ' ';

CoFaker _forLanguage(String tag, {int seed = 436}) => CoFaker.forLanguage(
  tag,
  seed: seed,
  now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
);

CoFaker _byLocale(String locale, {int seed = 436}) => CoFaker(
  locale: locale,
  seed: seed,
  now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
);

/// The primitive type a role is generated with.
String _typeOf(CoDomainRole role) => role.supportedTypes?.first ?? 'String';

/// Every role of every pack for the first [records] records, by qualified
/// name.
Map<String, List<Object?>> _roles(CoFaker f, {int records = 4}) => {
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

typedef _Text = ({String where, String text});

/// Every text and pattern of the German bundle, clinic data, and SaaS data.
List<_Text> _germanTexts() {
  final data = CoLanguageData.registered('de');
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
              (where: '${slot.name}[$row]', text: text),
  ];
}

/// Matches a text that has [word] in it, whatever the case: a German compound
/// writes `Teilnahmestempel` where English writes `stamp`.
Matcher _containsFolded(String word) => predicate<String>(
  (text) => text.toLowerCase().contains(word.toLowerCase()),
  'contains "$word", ignoring case',
);

/// The places where [pattern] matches a text, for the message of a failure.
List<String> _matches(List<_Text> texts, RegExp pattern) => <String>[
  for (final text in texts)
    if (pattern.hasMatch(text.text)) '${text.where}: ${text.text}',
];

void main() {
  final english = CoL10nRegistry.english;
  final bundle = CoL10nRegistry.bundleFor('de')!;
  final clinic = CoL10nClinic.clinicOf('de')!;
  final saas = CoL10nClinic.saasOf('de')!;
  final texts = _germanTexts();

  group('German is localized:', () {
    test('the bundle, the clinic data, and the SaaS data are all written', () {
      final data = CoLanguageData.registered('de');
      expect(data.level, CoLanguageLevel.localized);
      expect(CoFakerLanguages.resolve('de').language.domain, isTrue);
      // The keys of English, in its order: 242 keys and 762 texts.
      expect(bundle.texts.keys.toList(), english.texts.keys.toList());
      expect(
        bundle.texts.values.fold<int>(0, (sum, list) => sum + list.length),
        762,
      );
      expect(clinic.koreanValues, CoKoreanValues.none);
      expect(saas.koreanValues, CoKoreanValues.none);
    });

    test('the language gate passes', () {
      final report = CoLanguageCoverage().checkRegistered('de');
      expect(report.passed, isTrue, reason: report.toMarkdown(limit: 30));
      expect(report.stats['sameAsEnglish'], 0);
    });
  });

  group('every way to ask for German reads the same domain data:', () {
    final entryPoints = <String, CoFaker Function()>{
      'CoFaker.forLanguage("de")': () => _forLanguage('de'),
      'CoFaker.forLanguage("de-DE")': () => _forLanguage('de-DE'),
      'CoFaker(locale: "de")': () => _byLocale('de'),
      'CoFaker(locale: "de_DE")': () => _byLocale('de_DE'),
      'CoFaker(locale: "de-DE")': () => _byLocale('de-DE'),
      'CoFaker(locale: "DE")': () => _byLocale('DE'),
      'CoFaker(locale: "de_AT")': () => _byLocale('de_AT'),
    };
    for (final entry in entryPoints.entries) {
      test(entry.key, () {
        final f = entry.value();
        expect(f.language, 'de');
        expect(f.l10n.language, 'de');
        expect(f.clinic.data, same(clinic));
        expect(f.saas.data, same(saas));
        for (final item in bundle.texts.entries) {
          expect(f.l10n.list(item.key), item.value, reason: item.key);
        }
        // The roles and the generators write German, not English or Korean.
        final procedure = f.schema.record(
          {'value': 'String'},
          roles: {'value': 'dental.dentalProcedure'},
        )['value'];
        expect(bundle.texts['dental.dentalProcedure'], contains(procedure));
        expect(f.clinic.clinicName(), startsWith('Praxis '));
        expect(f.clinic.money(1234.5), '1.234,50$_nbsp€');
        expect(
          f.saas.plan().name,
          isIn(<String>['Einstieg', 'Standard', 'Professional', 'Unternehmen']),
        );
      });
    }

    test('a language that is not German keeps its own data', () {
      for (final f in <CoFaker>[_forLanguage('en'), _byLocale('en_US')]) {
        expect(f.l10n.language, 'en');
        expect(f.clinic.money(1234.5), r'$1,235');
      }
      expect(_forLanguage('ko').l10n.language, 'ko');
    });
  });

  group('the same seed picks the same record in English and in German:', () {
    test('every role that picks a text picks the entry of the same place', () {
      final en = _roles(_forLanguage('en'));
      final de = _roles(_forLanguage('de'));
      var compared = 0;
      final keys = <String>{};
      for (final key in english.texts.keys) {
        final enValues = en[key];
        final deValues = de[key];
        if (enValues == null || deValues == null) continue;
        final enTexts = english.texts[key]!;
        final deTexts = bundle.texts[key]!;
        for (var i = 0; i < enValues.length; i++) {
          final enIndex = enTexts.indexOf(enValues[i] as String? ?? '');
          if (enIndex < 0) continue;
          final deIndex = deTexts.indexOf(deValues[i] as String? ?? '');
          expect(deIndex >= 0, isTrue, reason: '$key $i');
          // Two entries that read alike (the same subject of two questions)
          // cannot tell their places apart.
          final unique =
              enTexts.where((text) => text == enTexts[enIndex]).length == 1 &&
              deTexts.where((text) => text == deTexts[deIndex]).length == 1;
          if (!unique) continue;
          expect(deIndex, enIndex, reason: '$key $i');
          compared++;
          keys.add(key);
        }
      }
      expect(compared, greaterThan(500));
      expect(keys.length, greaterThan(150));
    });

    test('the templates fill the same record: a class, a party, a child', () {
      final en = _forLanguage('en');
      final de = _forLanguage('de');
      String role(CoFaker f, String name, int index) =>
          f.schema.record(
                {'value': 'String'},
                roles: {'value': name},
                streamKey: name,
                index: index,
              )['value']
              as String;
      for (var i = 0; i < 12; i++) {
        // A class is `<category> <level>`: the same category and the same
        // level in both languages.
        final category = english.texts['fitness.classCategoryLabel']!
            .indexWhere(
              (label) => role(en, 'fitness.className', i).startsWith(label),
            );
        final level = english.texts['fitness.classLevelLabel']!.indexWhere(
          (label) => role(en, 'fitness.className', i).endsWith(label),
        );
        expect(
          role(de, 'fitness.className', i),
          '${bundle.texts['fitness.classCategoryLabel']![category]} '
          '${bundle.texts['fitness.classLevelLabel']![level]}',
          reason: 'class $i',
        );
      }
      for (var i = 0; i < 8; i++) {
        // The party label has the number last, whatever its size.
        expect(role(de, 'dining.partyLabel', i), 'Tisch für ${1 + i % 8}');
      }
      for (var i = 0; i < 6; i++) {
        expect(
          role(de, 'daycare.guardianLabel', i),
          matches(RegExp(r'^Erziehungsberechtigte von \S+$')),
        );
        expect(
          role(de, 'daycare.teacherName', i),
          matches(RegExp(r'^Erzieher:in \S+$')),
        );
      }
    });

    test('the clinic and SaaS data have the lists and maps of English', () {
      final en = CoLanguageData.registered('en');
      final tables = <(CoTextTable, CoTextTable)>[
        (
          CoLanguageTexts.ofClinic(
            en.clinic ?? CoFakerClinicData.english,
            resolveFallbacks: true,
          ),
          CoLanguageTexts.ofClinic(clinic),
        ),
        (
          CoLanguageTexts.ofSaas(
            en.saas ?? CoFakerSaasData.english,
            resolveFallbacks: true,
          ),
          CoLanguageTexts.ofSaas(saas),
        ),
      ];
      var slots = 0;
      for (final (reference, german) in tables) {
        for (final slot in reference.slots.values) {
          // The Korean holiday names are not written by a language that has
          // no Korean values.
          if (slot.kind == CoTextKind.koreanOnly) continue;
          final got = german[slot.name];
          expect(got, isNotNull, reason: slot.name);
          // The same rows in the same order: a list has the English length,
          // and a map has the English keys.
          expect(got!.rows, slot.rows, reason: slot.name);
          for (final row in slot.rows) {
            expect(
              got.cellsOf(row)!.length,
              slot.cellsOf(row)!.length,
              reason: '${slot.name}[$row]',
            );
          }
          slots++;
        }
      }
      expect(slots, greaterThan(120));
    });

    test(
      'an entry of the bundle translates the English entry of its place',
      () {
        // The same index picks the same record, but only a translation of that
        // entry makes it the same record in German. Each row names a key, the
        // place of an entry, a word of the English text, and a word of the
        // German text: the German entry is the one that English has there.
        const anchors = <(String, int, String, String)>[
          ('fx.currencyName.USD', 0, 'US dollar', 'US-Dollar'),
          ('fx.currencyName.JPY', 0, 'yen', 'Yen'),
          ('fx.branchName', 0, 'airport T1', 'Flughafen T1'),
          ('fx.branchName', 2, 'airport T2', 'Flughafen T2'),
          ('fx.tierName', 1, 'Silver', 'Silber'),
          ('remit.countryName.PH', 0, 'Philippines', 'Philippinen'),
          ('remit.countryName.US', 0, 'United States', 'Vereinigte Staaten'),
          ('remit.flagRule', 1, 'document', 'Dokumenten'),
          ('vet.breed.dog', 0, 'Maltese', 'Malteser'),
          ('vet.breed.dog', 1, 'Poodle', 'Pudel'),
          ('vet.breed.dog', 2, 'Mixed', 'Mischling'),
          ('vet.breed.cat', 0, 'shorthair', 'Kurzhaar'),
          ('vet.breed.small_mammal', 0, 'Rabbit', 'Kaninchen'),
          ('vet.breed.reptile', 0, 'Tortoise', 'schildkröte'),
          ('vet.coatColor', 1, 'Brown', 'Braun'),
          ('vet.coatColor', 3, 'Tricolor', 'Dreifarbig'),
          ('vet.vaccineName', 1, 'Rabies', 'Tollwut'),
          ('vet.preventiveProduct', 0, 'Heartworm', 'Herzwurm'),
          ('vet.vetDrug', 2, 'Eye', 'Augen'),
          ('vet.clinicRoom', 2, 'Vaccination', 'Impf'),
          ('grocery.categoryName', 0, 'Fruit', 'Obst'),
          ('grocery.categoryName', 2, 'Prepared', 'Fertig'),
          ('grocery.categoryName', 5, 'Seafood', 'Meeresfrüchte'),
          ('grocery.categoryName', 6, 'Dairy', 'Milch'),
          ('catalog.groceryName', 0, 'Strawberries', 'Erdbeeren'),
          ('catalog.groceryName', 6, 'Milk', 'Milch'),
          ('catalog.commerceName', 0, 'earphones', 'Ohrhörer'),
          ('dental.dentalProcedure', 0, 'Scaling', 'Zahnstein'),
          ('dental.dentalMaterial', 0, 'Composite', 'Komposit'),
          ('dental.dentalMaterial', 1, 'Zirconia', 'Zirkon'),
          ('dental.dentalMaterial', 2, 'Ceramic', 'Keramik'),
          ('homecare.careGrade', 2, 'grade 3', 'Pflegegrad 3'),
          ('homecare.careTaskLabel', 0, 'Meal', 'Mahlzeit'),
          ('homecare.careTaskLabel', 4, 'Toileting', 'Toilettengang'),
          ('travel_wallet.cityName', 1, 'Tokyo', 'Tokio'),
          ('group_deal.rewardLabel', 0, 'stamp', 'Stempel'),
          ('fitness.classLevelLabel', 0, 'beginner', 'Grundstufe'),
          ('fitness.classLevelLabel', 2, 'advanced', 'Oberstufe'),
          ('fitness.passName', 2, 'Monthly', 'Monats'),
          ('daycare.className', 0, 'Sun', 'Sonne'),
          ('daycare.className', 1, 'Moon', 'Mond'),
          ('daycare.className', 2, 'Star', 'Stern'),
          ('daycare.ageLabel', 0, 'Age 1', '1 Jahr'),
          ('daycare.allergenLabel', 0, 'Milk', 'Milch'),
          ('daycare.allergenLabel', 1, 'Egg', 'Ei'),
          ('daycare.allergenLabel', 2, 'Soy', 'Soja'),
          ('daycare.allergenLabel', 3, 'Wheat', 'Weizen'),
          ('daycare.drugLabel', 0, 'Fever', 'Fieber'),
          ('daycare.drugLabel', 1, 'Cough', 'Husten'),
          ('exam_prep.correctChoice', 0, 'Primary key', 'Primärschlüssel'),
          ('exam_prep.correctChoice', 6, 'Stack', 'Stapelspeicher'),
          ('exam_prep.correctChoice', 8, 'Least privilege', 'minimalen Rechte'),
          (
            'exam_prep.questionStem',
            2,
            'transport protocol',
            'Transportprotokoll',
          ),
          ('hrd.departmentName', 0, 'Sales', 'Vertrieb'),
          ('hrd.departmentName', 5, 'Logistics', 'Logistik'),
          ('meetup.interestTag', 5, 'Hiking', 'Wandern'),
          ('meetup.cadenceLabel', 0, 'Saturday', 'Samstag'),
          ('meetup.cadenceLabel', 1, 'Sunday', 'Sonntag'),
          ('workplace.shiftName', 2, 'Weekend', 'Wochenend'),
          ('brokerage.serviceTypeName', 0, 'Cleaning', 'Reinigung'),
          ('brokerage.serviceTypeName', 1, 'Moving', 'Umzug'),
          ('logistics.scanEvent', 3, 'Delivery complete', 'abgeschlossen'),
          ('logistics.scanEvent', 4, 'not completed', 'nicht erfolgt'),
          ('logistics.freightType', 2, 'Building', 'Bau'),
          ('hospitality.hkCheckItem', 0, 'bedding', 'Bettwäsche'),
          ('hospitality.lostItemName', 0, 'umbrella', 'Regenschirm'),
          ('hospitality.amenityName', 3, 'Pillow', 'Kissen'),
          ('campaign.couponTitle', 0, '20%', '20 %'),
          ('helpdesk.topicName', 1, 'Billing', 'Abrechnung'),
        ];
        for (final (key, index, enWord, deWord) in anchors) {
          expect(
            english.texts[key]![index],
            _containsFolded(enWord),
            reason: key,
          );
          expect(
            bundle.texts[key]![index],
            _containsFolded(deWord),
            reason: key,
          );
        }
      },
    );

    test('a record of the clinic and SaaS data translates its English one', () {
      // The rows that a code or a key names: the German row is the English
      // row, written in German.
      final en = CoFakerClinicData.english;
      for (final (code, enWord, deWord) in const <(String, String, String)>[
        ('CONS01', 'visit', 'Erstvorstellung'),
        ('BTX-F', 'neurotoxin', 'Botulinumtoxin'),
        ('FIL-L', 'filler', 'Filler'),
        ('LT-01', 'toning', 'Toning'),
        ('HIFU-300', 'ultrasound', 'Ultraschall'),
        ('ACN-01', 'Acne', 'Akne'),
        ('CARE-01', 'LED', 'LED'),
        ('DOC-01', 'certificate', 'Attest'),
      ]) {
        expect(
          en.procedures.firstWhere((p) => p.code == code).name,
          _containsFolded(enWord),
        );
        expect(
          clinic.procedures.firstWhere((p) => p.code == code).name,
          _containsFolded(deWord),
        );
      }
      for (final (code, deWord) in const <(String, String)>[
        ('L70.0', 'Akne'),
        ('L81.1', 'Chloasma'),
        ('B07', 'Viruswarzen'),
        ('L20.9', 'Atopische'),
        ('L30.9', 'Dermatitis'),
        ('L71.9', 'Rosazea'),
      ]) {
        final english = en.diagnoses.firstWhere((d) => d.code == code);
        final german = clinic.diagnoses.firstWhere((d) => d.code == code);
        expect(german.name, _containsFolded(deWord), reason: code);
        expect(german.nameEn, english.nameEn);
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('director', 'Director', 'Leitung'),
        ('nurse', 'Nurse', 'Pflege'),
        ('desk', 'Desk', 'Empfang'),
      ]) {
        expect(en.staffRoles[key], _containsFolded(enWord));
        expect(clinic.staffRoles[key], _containsFolded(deWord));
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('nhis', 'insurance', 'Krankenversicherung'),
        ('uninsured', 'Self-pay', 'Selbstzahlung'),
        ('reception', 'Check-in', 'Anmeldung'),
        ('waiting', 'Waiting', 'Wartend'),
        ('payment', 'Payment', 'Zahlung'),
        ('reserved', 'Booked', 'Gebucht'),
        ('cancelled', 'Cancelled', 'Abgesagt'),
        ('noShow', 'No-show', 'Nicht erschienen'),
        ('cash', 'Cash', 'Bar'),
        ('transfer', 'transfer', 'Überweisung'),
        ('female', 'Female', 'Weiblich'),
        ('male', 'Male', 'Männlich'),
      ]) {
        expect(en.labels[key], _containsFolded(enWord), reason: key);
        expect(clinic.labels[key], _containsFolded(deWord), reason: key);
      }
      final enTexts = CoFakerClinicTexts.english;
      final deTexts = clinic.texts!;
      for (final (topic, enWord, deWord) in const <(String, String, String)>[
        ('toning', 'toning', 'Toning'),
        ('lifting', 'ultrasound', 'Ultraschall'),
      ]) {
        expect(
          enTexts.counselTopics.firstWhere((t) => t.topic == topic).procedure,
          _containsFolded(enWord),
        );
        expect(
          deTexts.counselTopics.firstWhere((t) => t.topic == topic).procedure,
          _containsFolded(deWord),
        );
      }
      expect(
        enTexts.integrationResults['identityQr']!.first.message,
        'Identity verified',
      );
      expect(
        deTexts.integrationResults['identityQr']!.first.message,
        'Identität bestätigt',
      );
      expect(
        enTexts.integrationResults['ePrescription']!.first.message,
        'E-prescription sent',
      );
      expect(
        deTexts.integrationResults['ePrescription']!.first.message,
        'E-Rezept gesendet',
      );
      final enOps = CoFakerClinicOps.english;
      final deOps = clinic.ops!;
      for (final (kind, enWord, deWord) in const <(String, String, String)>[
        ('counseling', 'Counseling', 'Beratung'),
        ('payment', 'Checkout', 'Kasse'),
        ('reception', 'check-in', 'Anmeldung'),
      ]) {
        expect(
          enOps.rooms.firstWhere((r) => r.kind == kind).name,
          _containsFolded(enWord),
        );
        expect(
          deOps.rooms.firstWhere((r) => r.kind == kind).name,
          _containsFolded(deWord),
        );
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('signed', 'Signed', 'unterschrieben'),
        ('expired', 'expired', 'abgelaufen'),
        ('sent', 'sent', 'gesendet'),
      ]) {
        expect(enOps.consentDispatch[key], _containsFolded(enWord));
        expect(deOps.consentDispatch[key], _containsFolded(deWord));
      }
      final enSaas = CoFakerSaasData.english;
      for (final (code, deWord) in const <(String, String)>[
        ('starter', 'Einstieg'),
        ('standard', 'Standard'),
        ('pro', 'Professional'),
        ('enterprise', 'Unternehmen'),
      ]) {
        expect(saas.plans.firstWhere((p) => p.code == code).name, deWord);
        expect(enSaas.plans.firstWhere((p) => p.code == code).code, code);
      }
      for (final (code, enWord, deWord) in const <(String, String, String)>[
        ('RSV_CANCELLED', 'cancelled', 'abgesagt'),
        ('RSV_REMIND_D1', 'tomorrow', 'morgen'),
        ('QUESTIONNAIRE', 'questionnaire', 'Fragebogen'),
        ('SURVEY', 'how was your visit', 'wie war Ihr Besuch'),
        ('AD_EVENT', '[Ad]', '[Werbung]'),
      ]) {
        expect(
          enSaas.messageTemplates.firstWhere((t) => t.code == code).body,
          _containsFolded(enWord),
        );
        expect(
          saas.messageTemplates.firstWhere((t) => t.code == code).body,
          _containsFolded(deWord),
        );
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('NO_CREDIT', 'Insufficient', 'Nicht genügend'),
        ('CARRIER_TIMEOUT', 'timeout', 'Zeitüberschreitung'),
        ('OPTED_OUT', 'opted out', 'abbestellt'),
      ]) {
        expect(enSaas.failureReasons[key], _containsFolded(enWord));
        expect(saas.failureReasons[key], _containsFolded(deWord));
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('paid', 'Paid', 'Bezahlt'),
        ('refunded', 'Refunded', 'Erstattet'),
        ('cancelled', 'Cancelled', 'Gekündigt'),
        ('down', 'Outage', 'Störung'),
        ('ePrescription', 'E-prescription', 'E-Rezept'),
        ('print', 'Print', 'Drucken'),
        ('delete', 'Delete', 'Löschen'),
      ]) {
        expect(enSaas.labels[key], _containsFolded(enWord), reason: key);
        expect(saas.labels[key], _containsFolded(deWord), reason: key);
      }
      final enSaasOps = CoFakerSaasOps.english;
      final deSaasOps = saas.ops!;
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('tenant.suspend', 'Suspend', 'sperren'),
        ('tenant.resume', 'Resume', 'entsperren'),
        ('invoice.refund', 'Refund', 'erstatten'),
        ('credit.grant', 'Grant', 'gutschreiben'),
        ('template.reject', 'Reject', 'ablehnen'),
        ('template.approve', 'Approve', 'genehmigen'),
      ]) {
        expect(enSaasOps.operatorActions[key]!.label, _containsFolded(enWord));
        expect(deSaasOps.operatorActions[key]!.label, _containsFolded(deWord));
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('CARD_EXPIRED', 'expired', 'abgelaufen'),
        ('CARD_LOST', 'lost', 'verloren'),
        ('INSUFFICIENT_FUNDS', 'Insufficient', 'Unzureichende'),
      ]) {
        expect(enSaasOps.autopayFailures[key], _containsFolded(enWord));
        expect(deSaasOps.autopayFailures[key], _containsFolded(deWord));
      }
      for (final (key, enWord, deWord) in const <(String, String, String)>[
        ('DUPLICATE_CODE', 'duplicate', 'doppelten'),
        ('ROW_DELTA', '5%', '5 %'),
      ]) {
        expect(enSaasOps.masterChecks[key], _containsFolded(enWord));
        expect(deSaasOps.masterChecks[key], _containsFolded(deWord));
      }
      expect(enSaasOps.incidentTitles['outage'], _containsFolded('outage'));
      expect(deSaasOps.incidentTitles['outage'], _containsFolded('Störung'));
      expect(
        enSaasOps.incidentTitles['maintenance'],
        _containsFolded('maintenance'),
      );
      expect(
        deSaasOps.incidentTitles['maintenance'],
        _containsFolded('Wartung'),
      );
      expect(
        enSaasOps.alerts.firstWhere((a) => a.code == 'BACKUP_DONE').message,
        _containsFolded('backup'),
      );
      expect(
        deSaasOps.alerts.firstWhere((a) => a.code == 'BACKUP_DONE').message,
        _containsFolded('Sicherung'),
      );
    });

    test('a code, a flag, and a number are the English ones', () {
      final en = CoFakerClinicData.english;
      expect(
        [for (final p in clinic.procedures) p.code],
        [for (final p in en.procedures) p.code],
      );
      expect(
        [for (final p in clinic.procedures) p.taxable],
        [for (final p in en.procedures) p.taxable],
      );
      expect(
        [for (final d in clinic.diagnoses) (d.code, d.nameEn)],
        [for (final d in en.diagnoses) (d.code, d.nameEn)],
      );
      expect(clinic.staffRoles.keys.toList(), en.staffRoles.keys.toList());
      expect(
        [for (final p in saas.plans) (p.code, p.seats, p.messageCredits)],
        [
          for (final p in CoFakerSaasData.english.plans)
            (p.code, p.seats, p.messageCredits),
        ],
      );
    });
  });

  group('amounts follow the euro:', () {
    test('the currency is the one of Germany, written 1.234,56 €', () {
      final de = CoFakerCountries.germany;
      for (final currency in <CoCurrencyFormat>[
        clinic.currency,
        saas.currency,
      ]) {
        expect(currency.code, de.currencyCode);
        expect(currency.symbol, de.currencySymbol);
        expect(currency.fractionDigits, de.currencyMinorUnits);
        expect(currency.format(1234.56), '1.234,56$_nbsp€');
        expect(currency.format(1234), '1.234,00$_nbsp€');
        expect(currency.format(-80), '-80,00$_nbsp€');
      }
      final f = _forLanguage('de');
      expect(f.clinic.money(20), '20,00$_nbsp€');
      expect(f.clinic.money(2400000), '2.400.000,00$_nbsp€');
      expect(f.saas.money(1234.5), '1.234,50$_nbsp€');
    });

    test(
      'the prices of the clinic are in euros, rounded as a price tag is',
      () {
        final f = _forLanguage('de');
        expect(clinic.priceScale.priceRounding, 5);
        for (var i = 0; i < 60; i++) {
          final procedure = f.clinic.procedure();
          final spec = clinic.procedures.firstWhere(
            (p) => p.code == procedure.code,
          );
          expect(
            procedure.price,
            inInclusiveRange(spec.minPrice, spec.maxPrice),
          );
          expect(procedure.price % 5, 0, reason: '${procedure.price}');
          final offer = f.clinic.package();
          expect(offer.price % 10, 0, reason: '${offer.price}');
          expect(f.clinic.prepaidBalance() % 10, 0);
        }
        // A euro price band: a visit costs tens of euros, a lift thousands.
        expect(clinic.procedures.first.maxPrice, lessThan(300));
        expect(
          clinic.procedures
              .map((p) => p.maxPrice)
              .reduce((a, b) => a > b ? a : b),
          lessThan(5000),
        );
      },
    );

    test('the sessions of a counseling are quoted in euros', () {
      final f = _forLanguage('de');
      for (final topic in f.clinic.counselTopics) {
        final session = f.clinic.counselSession(topic: topic);
        expect(session.summary, contains(f.clinic.money(session.quotedPrice)));
        expect(session.summary, contains(f.clinic.money(session.packagePrice)));
        expect(session.summary, contains('${session.sessions}er-Paket'));
        expect(session.summary, contains('€'));
        expect(session.summary, isNot(contains(r'$')));
        final answer = session.turns.firstWhere(
          (turn) => turn.text.startsWith('Eine Sitzung kostet'),
        );
        expect(answer.text, contains(f.clinic.money(session.quotedPrice)));
      }
    });

    test('the invoice of a SaaS tenant carries the German VAT of 19%', () {
      final f = _forLanguage('de');
      expect(saas.priceScale.vatRate, 0.19);
      final invoice = f.saas.invoice(supplyAmount: 1000);
      expect(invoice.vat, 190);
      expect(invoice.total, 1190);
      for (final plan in saas.plans) {
        expect(plan.monthlyPrice, inInclusiveRange(50, 600), reason: plan.code);
      }
      for (final entry in f.saas.prepaidLedger(count: 40)) {
        if (entry.kind == 'topUp') {
          expect(
            saas.priceScale.prepaidTopUps,
            contains(entry.amount),
            reason: 'a top-up of the wallet is a euro amount of the data',
          );
        }
      }
    });
  });

  group('no Korean-only value appears:', () {
    test('a patient, a payment, and a tenant are German', () {
      final f = _forLanguage('de');
      for (var i = 0; i < 20; i++) {
        final patient = f.clinic.patient();
        expect(patient.rrnMasked, matches(RegExp(r'^\*{6}\d{4}$')));
        final fields =
            '${patient.name}${patient.phone}${patient.address1}'
            '${patient.postalCode}${patient.channelLabel}'
            '${patient.insuranceLabel}${patient.specialNote ?? ''}';
        expect(CoTextScan.hasHangul(fields), isFalse, reason: fields);
        expect(patient.phone, isNot(startsWith('010')));
        final payment = f.clinic.payment(amount: 400, method: 'card');
        expect(payment.approvalNo, matches(RegExp(r'^\d{6}$')));
        expect(
          f.clinic.payment(amount: 400, method: 'cash').cashReceiptNo,
          isNull,
        );
        expect(f.saas.tenant().businessNumber, matches(RegExp(r'^DE\d{9}$')));
      }
    });

    test(
      'a closure notice gives a reason, since Germany has no Korean holiday',
      () {
        final f = _forLanguage('de');
        const weekday = '(?:Mo|Di|Mi|Do|Fr|Sa|So)';
        var notices = 0;
        // Every day from Chuseok to the end of the year, with the Korean holidays
        // among them.
        for (var d = 0; d < 100; d++) {
          final date = DateTime.utc(2026, 9, 20).add(Duration(days: d));
          final notice = f.clinic.closureNotice(date: date);
          expect(notice.holiday, isNull, reason: '$date');
          expect(notice.from, notice.to);
          expect(
            notice.title,
            matches(RegExp('^Geschlossen: $weekday, \\d{1,2}\\.\\d{1,2}\\.\$')),
          );
          expect(
            notice.body,
            matches(
              RegExp(
                r'^Praxis .+: Geschlossen '
                '$weekday, \\d{1,2}\\.\\d{1,2}\\. '
                r'\(Grund: [^)]+\)\. Ab '
                '$weekday, \\d{1,2}\\.\\d{1,2}\\. '
                r'sind wir wieder regulär für Sie da\.$',
              ),
            ),
            reason: notice.body,
          );
          // A date label ends with a period, and no period follows it.
          expect(notice.body, isNot(contains('..')));
          notices++;
        }
        expect(notices, 100);
      },
    );

    test('no text has Hangul, a field left unfilled, or a Korean particle', () {
      expect(texts.length, greaterThan(1300));
      for (final text in texts) {
        expect(CoTextScan.hasHangul(text.text), isFalse, reason: text.where);
        expect(text.text, isNot(contains('{eun}')), reason: text.where);
        expect(text.text, isNot(contains('{ro}')), reason: text.where);
      }
    });
  });

  group('the writing of German:', () {
    test('the register is Sie, never du', () {
      final informal = RegExp(
        r'\b(du|dich|dir|dein\w*|euch|euer\w*|eure\w*)\b',
        caseSensitive: false,
      );
      expect(_matches(texts, informal), isEmpty);
      // The formal address is written: `Sie`, `Ihr`, `Ihnen` with a capital.
      final formal = RegExp(r'\b(Sie|Ihr\w*)\b');
      expect(
        texts.where((text) => formal.hasMatch(text.text)).length,
        greaterThan(30),
      );
      final f = _forLanguage('de');
      final session = f.clinic.counselSession();
      expect(session.turns.first.text, contains('Sie'));
    });

    test('a number and its unit or percent sign have a space between them', () {
      expect(_matches(texts, RegExp(r'\d%')), isEmpty);
      expect(_matches(texts, RegExp(r'\d(?:mg|kg|g|ml|l|cm|mm)\b')), isEmpty);
      // `500 g`, `350 ml`, `10 mg`, and `10 %` are written.
      expect(bundle.texts['catalog.groceryUnit'], contains('500 g'));
      expect(
        bundle.texts['b2b_trade.itemSpec'],
        contains('Pappbecher 350 ml, 1.000 Stück'),
      );
      expect(clinic.ops!.adjustments['discount'], contains('Folgetermin 10 %'));
    });

    test('a quotation mark is the German one, and thousands have a period', () {
      expect(_matches(texts, RegExp('"')), isEmpty);
      expect(
        bundle.texts['fandom.eventTitle'],
        contains('Veranstaltung „Geschichten aus dem Atelier“ (fiktiv)'),
      );
      // Thousands are separated by a period, never by a comma: `1.000`.
      expect(_matches(texts, RegExp(r'\d,\d{3}\b(?!,)')), isEmpty);
    });

    test('a person noun is neutral, or it has the gender colon, and only it', () {
      // Neutral wording where German has it, and `:in` or `:innen` where a
      // person noun cannot be avoided: no star, slash, bracket, or capital I.
      final other = RegExp(
        r'\w[*/]in\b|\w\(in\)|[a-zäöü]In\b|[a-zäöü]Innen\b|[Pp]atientin|Ärztin',
      );
      expect(_matches(texts, other), isEmpty);
      final colon = RegExp(r'[A-Za-zÄÖÜäöüß]:([A-Za-zÄÖÜäöüß]+)');
      final endings = <String>{
        for (final text in texts)
          for (final match in colon.allMatches(text.text)) match.group(1)!,
      };
      expect(endings, <String>{'in', 'innen'});
      expect(clinic.staffRoles['nurse'], 'Pflegefachkraft');
      expect(clinic.staffRoles['director'], 'Ärztliche Leitung');
      expect(clinic.staffRoles['doctor'], 'Ärzt:in');
    });

    test('no English word is left in a text', () {
      final english = RegExp(
        r'\b(the|and|with|please|your|you|are|this|that|from|has|have|will|for)\b',
        caseSensitive: false,
      );
      expect([
        for (final text in texts)
          if (english.hasMatch(CoTextScan.withoutPlaceholders(text.text)))
            '${text.where}: ${text.text}',
      ], isEmpty);
    });

    test(
      'a text starts with a capital letter, as a noun or a sentence does',
      () {
        final lower = RegExp('^[a-zäöüß]');
        // The one exception is a unit of measure.
        expect(
          [
            for (final text in texts)
              if (lower.hasMatch(text.text)) text.text,
          ],
          <String>['ml'],
        );
      },
    );
  });

  group('the templates stay right with every value:', () {
    test('a number goes last in a text that a count fills', () {
      final f = _forLanguage('de');
      var failed = 0;
      for (var i = 0; i < 400 && failed == 0; i++) {
        for (final check in f.saas.masterChecks()) {
          if (check.passed) continue;
          expect(check.detail, matches(RegExp(r'^Zeilen: \d+$')));
          failed++;
          break;
        }
      }
      expect(failed, 1, reason: 'a failed check was generated');
      for (var i = 0; i < 20; i++) {
        final activity = f.saas.tenantActivity();
        // `Neu registrierte Patient:innen: 134`: the count is the last word.
        expect(activity.text, matches(RegExp(r'^.+: \d+$')));
      }
      for (var i = 0; i < 12; i++) {
        final plate = f.schema.record(
          {'value': 'String'},
          roles: {'value': 'logistics.vehiclePlate'},
          streamKey: 'logistics.vehiclePlate',
          index: i,
        )['value'];
        // A German plate, masked, with no Korean `가`.
        expect(plate, matches(RegExp(r'^M-●● \d{4}$')));
      }
    });

    test('a staff mention carries the role in parentheses', () {
      final f = _forLanguage('de');
      var seen = 0;
      for (var i = 0; i < 40; i++) {
        final note = f.clinic.teamNote();
        expect(note.text, isNot(matches(RegExp(r'[{}]'))));
        if (RegExp(r'@\S+ \S+ \(').hasMatch(note.text)) seen++;
      }
      expect(seen, greaterThan(20));
      final named = f.clinic.teamNote(
        patient: 'Mia Becker',
        authors: <String>['Anna Weber', 'Tom Klein'],
        mentions: <String>['Anna Weber', 'Tom Klein'],
      );
      expect(named.text, contains('Mia Becker'));
      expect(named.text, matches(RegExp(r'@(?:Anna Weber|Tom Klein)')));
    });

    test('a device, a package, and a compound package read right', () {
      final f = _forLanguage('de');
      for (var i = 0; i < 12; i++) {
        expect(f.clinic.device().name, matches(RegExp(r'^.+ Nr\. \d$')));
      }
      final offer = f.clinic.package();
      expect(offer.name, matches(RegExp(r'^.+ – (?:3|5|10)er-Paket$')));
      final compound = f.clinic.compoundPackageName();
      expect(
        compound,
        matches(RegExp(r'^(?:\d+x [^+]+ \+ ){2,3}Regenerationscreme gratis$')),
      );
    });
  });
}
