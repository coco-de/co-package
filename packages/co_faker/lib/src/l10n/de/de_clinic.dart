import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// German (`de`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic practice in euros, written as a
/// translation of `CoFakerClinicData.english`: every list has the length of the
/// English one, in the same order, and the codes (`CONS01`, `nhis`, `waiting`)
/// are the English ones. The amounts are euros (`1.234,00 €`), the practice
/// name reads `Praxis Ahorn – Dermatologie`, and no Korean-only value appears
/// ([CoKoreanValues.none]).
///
/// The texts are a draft that a native speaker has to review: see
/// `docs/languages/de.md`. A patient is addressed with `Sie`.
///
/// `de`, `de_DE`, and `CoFaker.forLanguage('de')` read it.
const CoFakerClinicData deClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'Dermatologie', clinicSuffix: 'Dermatologie'),
    (name: 'Plastische Chirurgie', clinicSuffix: 'Plastische Chirurgie'),
    (name: 'Allgemeinmedizin', clinicSuffix: 'Allgemeinmedizin'),
    (name: 'Innere Medizin', clinicSuffix: 'Innere Medizin'),
    (
      name: 'Kinder- und Jugendmedizin',
      clinicSuffix: 'Kinder- und Jugendmedizin',
    ),
  ],
  clinicNamePrefixes: <String>[
    'Klarblick',
    'Sonnenseite',
    'Ahorn',
    'Flussufer',
    'Immergrün',
    'Muster',
    'Beispiel',
    'Nordtor',
  ],
  staffRoles: <String, String>{
    'director': 'Ärztliche Leitung',
    'doctor': 'Ärzt:in',
    'counselor': 'Patientenberatung',
    'coordinator': 'Versorgungskoordination',
    'nurse': 'Pflegefachkraft',
    'nurseAide': 'Pflegehilfskraft',
    'skincare': 'Kosmetikfachkraft',
    'desk': 'Empfang',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (name: 'Beratung', details: <String>['Erstberatung', 'Folgeberatung']),
    (name: 'Eingriff', details: <String>['Injektionen', 'Laser', 'Straffung']),
    (name: 'Behandlung', details: <String>['Akne', 'Hauterkrankung', 'Warzen']),
    (name: 'Pflege', details: <String>['Gesichtspflege', 'Beruhigende Pflege']),
  ],
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'Besuch/Gebühr',
      name: 'Erstvorstellung',
      unit: 'Besuch',
      minPrice: 70,
      maxPrice: 180,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'Botulinumtoxin/Falten',
      name: 'Botulinumtoxin Stirn',
      unit: 'Region',
      minPrice: 140,
      maxPrice: 420,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'Filler/Region',
      name: 'Hyaluron-Filler Lippen 1 ml',
      unit: 'ml',
      minPrice: 450,
      maxPrice: 850,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'Laser/Pigment',
      name: 'Pikosekundenlaser-Toning',
      unit: 'Sitzung',
      minPrice: 180,
      maxPrice: 450,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'Straffung/HIFU',
      name: 'Fokussierter Ultraschall (HIFU), 300 Linien',
      unit: 'Sitzung',
      minPrice: 800,
      maxPrice: 2700,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'Akne/Behandlung',
      name: 'Akne-Ausreinigung',
      unit: 'Sitzung',
      minPrice: 55,
      maxPrice: 135,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'Pflege/Beruhigung',
      name: 'Beruhigende LED-Gesichtsbehandlung',
      unit: 'Sitzung',
      minPrice: 55,
      maxPrice: 130,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'Dokumente',
      name: 'Ärztliches Attest',
      unit: 'Ausfertigung',
      minPrice: 10,
      maxPrice: 30,
      taxable: false,
    ),
  ],
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'Akne vulgaris', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'Chloasma (Melasma)', nameEn: 'Chloasma'),
    (code: 'B07', name: 'Viruswarzen', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'Atopische Dermatitis, nicht näher bezeichnet',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'Dermatitis, nicht näher bezeichnet',
      nameEn: 'Dermatitis, unspecified',
    ),
    (
      code: 'L71.9',
      name: 'Rosazea, nicht näher bezeichnet',
      nameEn: 'Rosacea, unspecified',
    ),
  ],
  // Invented stems: none is a marketed product.
  drugStems: <String>[
    'Adermix',
    'Lumisan',
    'Kerafon',
    'Diaklon',
    'Naviron',
    'Seratan',
    'Minobar',
    'Akrozan',
  ],
  // The form carries its space and the unit its space: `Lumisan Tabletten
  // 10 mg`.
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ' Tabletten', unit: ' mg', strengths: <int>[5, 10, 20, 50]),
    (form: ' Kapseln', unit: ' mg', strengths: <int>[25, 50, 100]),
    (form: ' Salbe', unit: ' g', strengths: <int>[15, 30]),
    (form: ' Creme', unit: ' g', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    '1-mal täglich vor dem Schlafengehen',
    '2-mal täglich nach den Mahlzeiten',
    '2-mal täglich dünn auftragen',
    '1-mal täglich nach der Reinigung auftragen',
  ],
  complaints: <String>[
    'Berichtet über dunklere Flecken auf beiden Wangen',
    'Wiederkehrende Akne entlang der Kieferlinie',
    'Sorge wegen Stirnfalten',
    'Wunsch nach Straffung erschlaffter Haut',
    'Anhaltende Rötung nach einem Eingriff',
  ],
  findings: <String>[
    'Unscharf begrenzte braune Makulae im Bereich beider Wangenknochen',
    'Mehrere entzündliche Papeln am Kinn',
    'Dynamische Stirnfalten, Grad 2',
    'Mäßige Erschlaffung im Untergesicht',
    'Leichtes Erythem, kein Ödem',
  ],
  plans: <String>[
    'Laser-Toning alle zwei Wochen',
    'Ausreinigung und lokale Therapie',
    'Kontrolle zwei Wochen nach der Injektion',
    'Aufklärung zum Sonnenschutz, Wiedervorstellung in vier Wochen',
    'Beobachten, bei Verschlechterung erneut vorstellen',
  ],
  memos: <String>[
    'Empfohlen, 24 Stunden kein Make-up zu tragen.',
    'Lokalanästhetikum 30 Minuten vor dem Eingriff aufgetragen.',
    'Vorher-Fotos aufgenommen.',
    'Paketpreise erklärt; die Entscheidung fällt später.',
    'Nächster Termin in zwei Wochen vereinbart.',
  ],
  questions: <CoQuestionSpec>[
    (
      question: 'Haben Sie Medikamentenallergien?',
      options: <String>['Keine', 'Lidocain', 'Penicillin', 'Weiß ich nicht'],
    ),
    (
      question: 'Nehmen Sie Medikamente ein?',
      options: <String>[
        'Keine',
        'Blutverdünner',
        'Aknemedikamente',
        'Sonstige',
      ],
    ),
    (
      question: 'Sind Sie schwanger oder stillen Sie?',
      options: <String>['Nein', 'Schwanger', 'Stillend', 'Nicht zutreffend'],
    ),
    (
      question: 'Was möchten Sie am liebsten verbessern?',
      options: <String>['Pigmentierung', 'Akne', 'Falten', 'Festigkeit'],
    ),
  ],
  // Fictional issuers: German writes no card network or bank by its name.
  cardIssuers: <String>[
    'Beispielbank Nord',
    'Beispielbank Süd',
    'Beispielbank Ost',
    'Beispielbank West',
  ],
  labels: <String, String>{
    'nhis': 'Gesetzliche Krankenversicherung',
    'medicalAid1': 'Krankenhilfe (Typ 1)',
    'medicalAid2': 'Krankenhilfe (Typ 2)',
    'uninsured': 'Selbstzahlung',
    'reception': 'Anmeldung',
    'waiting': 'Wartend',
    'consultation': 'Untersuchung',
    'counseling': 'Beratung',
    'procedure': 'Eingriff',
    'care': 'Pflege',
    'payment': 'Zahlung',
    'done': 'Erledigt',
    'requested': 'Angefragt',
    'reserved': 'Gebucht',
    'confirmed': 'Bestätigt',
    'checkedIn': 'Angemeldet',
    'completed': 'Abgeschlossen',
    'cancelled': 'Abgesagt',
    'noShow': 'Nicht erschienen',
    'rejected': 'Abgelehnt',
    'card': 'Karte',
    'cash': 'Bar',
    'transfer': 'Überweisung',
    'prepaid': 'Guthaben',
    'package': 'Paket',
    'female': 'Weiblich',
    'male': 'Männlich',
  },
  packageNameFormat: '{name} – {sessions}er-Karte',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Einwilligung in den Eingriff',
        clauses: <String>[
          'Mir wurden Zweck, Ablauf und die zu erwartende Wirkung des Eingriffs erläutert.',
          'Mir ist bekannt, dass danach Rötungen, Schwellungen oder Blutergüsse auftreten können.',
          'Mir ist bewusst, dass Ergebnisse unterschiedlich ausfallen und nicht garantiert werden können.',
          'Ich habe meine Medikamente, Allergien und eine mögliche Schwangerschaft angegeben.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Einwilligung in die Datenverarbeitung',
        clauses: <String>[
          'Erhoben werden: Name, Geburtsdatum, Kontaktdaten, Behandlungsunterlagen.',
          'Zweck: Behandlung, Terminerinnerungen, Abrechnung.',
          'Ich kann die Einwilligung verweigern; die Online-Terminbuchung steht dann möglicherweise nicht zur Verfügung.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Einwilligung zur Fotodokumentation',
        clauses: <String>[
          'Vorher- und Nachher-Fotos werden aufgenommen, um den Verlauf zu dokumentieren.',
          'Die Fotos werden nur für die Behandlung verwendet und nie veröffentlicht.',
        ],
      ),
    ],
    consentDisclaimer:
        'Beispieltext nur für Demos. Rechtlich nicht geprüft; nicht als echte '
        'Einwilligungserklärung verwenden.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'Alles wurde ausführlich und sorgfältig erklärt.',
        'Kurze Wartezeit und ein freundliches Team.',
        'Mein Hautton hat sich nach drei Sitzungen verbessert.',
      ],
      'neutral': <String>[
        'Gute Ergebnisse, aber etwas teuer.',
        'Die Parkplatzsituation war umständlich.',
      ],
      'negative': <String>[
        'Ich musste über 40 Minuten über die vereinbarte Zeit hinaus warten.',
        'Die Rechnung wich vom Kostenvoranschlag ab.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'Pikosekundenlaser-Toning',
        concern: 'Die dunklen Flecken auf meinen Wangen werden immer stärker.',
        recommend:
            'Bei Pigmentflecken empfehle ich ein Pikosekundenlaser-Toning.',
        pain: 'Es zwickt ein wenig; die meisten kommen ohne Betäubung aus.',
        interval: 'Etwa zehn Sitzungen im Abstand von zwei Wochen.',
        downtime:
            'Einige Stunden leichte Rötung; Sie können sich noch am selben Tag waschen.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'Straffung mit fokussiertem Ultraschall',
        concern: 'Meine Kieferlinie wirkt erschlafft.',
        recommend:
            'Fokussierter Ultraschall strafft die tieferen Hautschichten.',
        pain:
            'In Knochennähe kann es ziehen, deshalb tragen wir eine Betäubungscreme auf.',
        interval: 'Einmal alle sechs bis zwölf Monate.',
        downtime: 'Sie können sofort wieder arbeiten.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Guten Tag, was führt Sie heute zu uns?',
      questions: <String, String>{
        'pain': 'Tut das weh?',
        'interval': 'Wie oft muss ich das machen lassen?',
        'downtime': 'Kann ich danach direkt wieder arbeiten?',
        'price': 'Was kostet das?',
      },
      priceAnswer:
          'Eine Sitzung kostet {price}, das {sessions}er-Paket {packagePrice}.',
      bookYes: 'Sehr gut, ich möchte diese Woche einen Termin buchen.',
      bookYesReply:
          'Gern, ich buche den Termin und schicke Ihnen die Hinweise zur '
          'Nachsorge per SMS.',
      bookNo: 'Ich überlege es mir und melde mich bei Ihnen.',
      bookNoReply: 'Natürlich, melden Sie sich jederzeit.',
      summary:
          'Empfehlung: {procedure}, {price} pro Sitzung, {sessions}er-Paket '
          '{packagePrice}. {outcome}',
      booked: 'Termin gebucht.',
      pending: 'Noch offen, später nachfassen.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Versicherungsschutz bestätigt', ok: true),
        (code: 'LOST', message: 'Versicherungsschutz beendet', ok: false),
        (
          code: 'NOT_FOUND',
          message: 'Versicherte Person nicht gefunden',
          ok: false,
        ),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Keine Wechselwirkungen gefunden', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Warnung: Arzneimittelwechselwirkung',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Abrechnung eingegangen', ok: true),
        (
          code: 'ADJUSTED',
          message: 'Abrechnung bei der Prüfung angepasst',
          ok: false,
        ),
        (
          code: 'RETURNED',
          message: 'Abrechnung zurückgewiesen: Pflichtangaben fehlen',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'E-Rezept gesendet', ok: true),
        (
          code: 'FAILED',
          message: 'Von der Apotheke nicht empfangen',
          ok: false,
        ),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Identität bestätigt', ok: true),
        (code: 'EXPIRED', message: 'QR-Code abgelaufen', ok: false),
      ],
    },
    // Fictional insurers.
    insurers: <String>[
      'Nordhafen Versicherung',
      'Hafenblick Leben',
      'Gipfellinie Assekuranz',
      'Klarbach Gesundheit',
    ],
    teamNotes: <String>[
      '{mention}, bitte die Laser-Einstellung für {patient} um eine Stufe senken.',
      'Übergabe: Bei {patient} ist die Betäubungscreme aufgetragen. {mention}, es kann losgehen.',
      '{mention}, {patient} hat noch eine Sitzung im Paket.',
      'Bei {patient} fehlt die Unterschrift der Erziehungsberechtigten. {mention}, bitte prüfen.',
    ],
    deviceNameFormat: '{kind} Nr. {number}',
    staffMentionFormat: '@{name} ({role})',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Selbst',
      'spouse': 'Ehepartner:in',
      'parent': 'Elternteil',
      'child': 'Kind',
      'sibling': 'Geschwister',
      'grandparent': 'Großelternteil',
      'grandchild': 'Enkelkind',
      'legalGuardian': 'Gesetzliche Vertretung',
      'other': 'Sonstige',
      'picoLaser': 'Pikosekundenlaser',
      'hifu': 'HIFU',
      'rf': 'Radiofrequenz',
      'ipl': 'IPL',
      'ledTherapy': 'LED-Therapie',
      'skinAnalyzer': 'Hautanalysegerät',
      'photoCamera': 'Klinische Fotokamera',
      'labelPrinter': 'Etikettendrucker',
      'cardTerminal': 'Kartenterminal',
      'signaturePad': 'Unterschriftenpad',
      'kiosk': 'Anmeldeterminal',
      'bridgePc': 'Bridge-PC',
      'positive': 'Positiv',
      'neutral': 'Neutral',
      'negative': 'Negativ',
      'counselor': 'Berater:in',
      'patientSpeaker': 'Patient:in',
      'life': 'Lebensversicherung',
      'nonLife': 'Schadenversicherung',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Straffung', color: '#6366F1'),
      (code: 'referral', label: 'Empfehlung', color: '#10B981'),
      (code: 'caution', label: 'Vorsicht', color: '#EF4444'),
      (code: 'package', label: 'Paket vorhanden', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Online-Buchung', color: '#03C75A'),
      (code: 'referral', label: 'Empfehlung', color: '#10B981'),
      (
        code: 'instagramAd',
        label: 'Anzeige in sozialen Medien',
        color: '#E1306C',
      ),
      (code: 'search', label: 'Suche', color: '#7C3AED'),
      (code: 'walkIn', label: 'Laufkundschaft', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Lidocain-Allergie',
      'Neigung zu Keloiden: Laser niedriger einstellen',
      'Nimmt Blutverdünner: vor Eingriffen prüfen',
      'Penicillin-Allergie',
    ],
    rooms: <CoRoomSpec>[
      (name: 'Beratungsraum 1', kind: 'counseling', staffRole: 'counselor'),
      (
        name: 'Untersuchungsraum 1',
        kind: 'consultation',
        staffRole: 'director',
      ),
      (name: 'Untersuchungsraum 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Behandlungsraum 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Pflegeraum 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Kasse', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Tablet-Anmeldung', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Aufbewahrungsfrist der Daten präzisiert.',
      'E-Rezept-Netzwerk als Empfänger ergänzt.',
      'Aufbewahrung von KI-Beratungsaufzeichnungen für 90 Tage festgehalten.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Unterschriftsanfrage gesendet.',
      'opened': 'Die Anfrage wurde geöffnet.',
      'signed': 'Elektronisch unterschrieben.',
      'expired': 'Die Anfrage ist abgelaufen (24 Stunden).',
      'failed':
          'Die Anfrage konnte nicht gesendet werden; bitte die Nummer prüfen.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        'Folgetermin 10 %',
        'Familie von Mitarbeitenden 20 %',
      ],
      'coupon': <String>['Gutschein Erstbesuch 20 %', 'Geburtstagsgutschein'],
      'point': <String>['Punkte eingelöst'],
      'rounding': <String>['Rundung'],
    },
    pointReasons: <String, String>{
      'earn': '3 % des Zahlbetrags gutgeschrieben',
      'use': 'An der Kasse eingelöst',
      'bonus': 'Bewertungsbonus',
      'expire': 'Verfallen',
      'refund': 'Nach einer Erstattung zurückgebucht',
      'adjust': 'Manuelle Anpassung',
    },
    paymentMessages: <String, String>{
      'approved': 'Kartenzahlung genehmigt.',
      'cashReceipt': 'Barbeleg ausgestellt.',
      'partialCancel': 'Teilweise storniert.',
      'prepaidUsed': 'Vom Guthaben abgebucht.',
      'declined': 'Karte abgelehnt: {reason}',
    },
    tasks: <String>[
      'Bestand der Laser-Aufsätze prüfen',
      'Verbrauchsmaterial bestellen',
      'Tagesabschluss',
      'Kühlschranktemperatur dokumentieren',
    ],
    taskMemos: <String>[
      'Bitte bis 15:00 Uhr erledigen.',
      'Sofort bestellen, wenn weniger als 5 übrig sind.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Anmelden',
      'reservation': 'Meinen Termin finden',
      'payment': 'Bezahlen',
      'document': 'Dokumente',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'Gleicher Eingriff innerhalb von 3 Monaten'),
      (
        kind: 'priceRule',
        rule: 'Vorhandene Pakete vor Einzelsitzungen vorschlagen',
      ),
      (
        kind: 'contraindication',
        rule: 'Bei Lidocain-Allergie keine Betäubungscreme verwenden',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'Keine Einwilligung zur Aufzeichnung; die KI-Beratung kann nicht '
          'starten.',
      'STT_FAILED':
          'Spracherkennung fehlgeschlagen. Bitte das Mikrofon prüfen.',
      'TOO_SHORT': 'Die Aufzeichnung ist zu kurz für eine Zusammenfassung.',
      'MODEL_TIMEOUT':
          'Die Zusammenfassung verzögert sich. Bitte in Kürze erneut versuchen.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message:
            'Kosmetische Diagnosen dürfen keine Kassenleistung für den Besuch '
            'abrechnen.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'Folgegebühr am selben Tag doppelt abgerechnet.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'Keine Einwilligung für nächtliche Werbung',
      'MARKETING_NO_CONSENT': 'Keine Werbeeinwilligung',
      'OPTED_OUT': 'Werbung abbestellt',
      'INVALID_NUMBER': 'Ungültige Nummer',
    },
    packageBonus: 'Regenerationscreme gratis',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'Schulung zum neuen Lasergerät',
          body:
              'Die Schulung zum neuen Laser findet nächsten Mittwoch um 18:00 '
              'Uhr in Behandlungsraum 1 statt.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'Prüfung der Einsicht in Ausweisnummern',
          body:
              'Vollständige Ausweisnummern können nur mit Angabe eines Grundes '
              'eingesehen werden; die Zugriffe werden monatlich geprüft.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'Feiertagsdienstplan',
          body:
              'Am Tag vor dem Feiertag schließen wir um 17:00 Uhr. Bitte den '
              'gemeinsamen Dienstplan beachten.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'Vitalwerte stabil (RR {sys}/{dia} mmHg, Puls {pulse}, SpO2 {spo2} %, '
          'T {temp} °C).',
      'highBp':
          'Blutdruck {sys}/{dia} mmHg erhöht; Kontrolle nach 10 Minuten Ruhe.',
      'fever':
          'Leichtes Fieber {temp} °C; ärztlich klären, ob der Eingriff '
          'verschoben wird.',
      'lowSpo2': 'SpO2 {spo2} % ist niedrig; erneut gemessen, keine Atemnot.',
      'highGlucose':
          'Blutzucker {glucose} mg/dl erhöht; nach der Mahlzeit gemessen und '
          'bestätigt.',
    },
    // A date label never follows a preposition, so a notice reads the same for
    // one day (`Mi, 30.9.`) and for a range (`Mi, 30.9. – Fr, 2.10.`).
    closure: <String, String>{
      'title': 'Geschlossen: {dates}',
      'holiday':
          '{clinic}: Geschlossen {dates} wegen {name}. Ab {reopen} sind wir '
          'wieder regulär für Sie da.',
      'other':
          '{clinic}: Geschlossen {dates}. Grund: {reason}. Ab {reopen} sind '
          'wir wieder regulär für Sie da.',
    },
    closureReasons: <String>[
      'Fachkongress',
      'Umbauarbeiten',
      'Wartung der Geräte',
    ],
    dateFormat: '{weekday}, {day}.{month}.',
    weekdayNames: <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
    dateRangeFormat: '{from} – {to}',
    compoundItemFormat: '{sessions}x {name}',
    labels: <String, String>{
      'requested': 'Angefragt',
      'waiting': 'Wartend',
      'priority': 'Vorrang',
      'inProgress': 'In Bearbeitung',
      'done': 'Erledigt',
      'tablet': 'Tablet',
      'online': 'Online',
      'app': 'App',
      'kiosk': 'Terminal',
      'desk': 'Empfang',
      'paper': 'Papier',
      'privacyRequired': 'Datenschutz (Pflicht)',
      'marketingOptional': 'Werbung (optional)',
      'sensitiveInfo': 'Sensible Daten',
      'photoUse': 'Fotonutzung',
      'thirdParty': 'Weitergabe an Dritte',
      'aiRecording': 'KI-Aufzeichnung',
      'nightAdvertising': 'Nächtliche Werbung',
      'agreed': 'Zugestimmt',
      'withdrawn': 'Widerrufen',
      'chartHistory': 'Aktenverlauf',
      'procedureHistory': 'Eingriffsverlauf',
      'priceRule': 'Preisregel',
      'contraindication': 'Kontraindikation',
      'guideline': 'Leitlinie',
      'preference': 'Wunsch',
      'error': 'Fehler',
      'warning': 'Warnung',
      'discount': 'Rabatt',
      'coupon': 'Gutschein',
      'point': 'Punkte',
      'rounding': 'Rundung',
    },
  ),
  clinicNameFormat: 'Praxis {prefix} – {suffix}',
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount} {symbol}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  priceScale: CoClinicPriceScale(
    priceRounding: 5,
    packageRounding: 10,
    prepaidStep: 10,
    installmentMinimum: 450,
    splitMinimum: 45,
    splitRounding: 1,
    adjustmentUnit: 5,
    pointUnit: 1,
    quoteMin: 50,
    quoteMax: 300,
  ),
  koreanValues: CoKoreanValues.none,
  maskedIdFormat: '******####',
  addressLineFormat: '{line1}, {city}',
);
