import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// Italian (`it`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic clinic in euros that follows
/// `CoFakerClinicData.english`: every list has the length of the English one,
/// in the same order, so that one seed picks the same record in both
/// languages. `it`, `it_IT`, and `CoFaker.forLanguage('it')` read it.
///
/// What makes the data Italian and not a translation only:
///
/// - the amounts are euros written `1.234,56 €`: a full stop between thousands,
///   a comma before the cents, and a no-break space before the symbol. The
///   price bands and the price scale are in euros;
/// - a clinic name is the kind of place first and the name after it
///   (`Ambulatorio pediatrico dell’Acero`), and a date is `mercoledì 25/11`;
/// - the patient is addressed with `Lei`, and a text that a value fills never
///   needs an article or a contraction of a preposition (`del`, `al`, `nel`)
///   before the value, because the value comes after a colon, a comma, or a
///   parenthesis, or after `per`, which never changes;
/// - no value of the Korean data appears (`CoKoreanValues.none`): the ID is
///   masked in the shape of an Italian tax code, the phones and addresses are
///   those of Italy, and a closure notice gives a reason.
const CoFakerClinicData itClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'Dermatologia', clinicSuffix: 'Studio dermatologico'),
    (name: 'Chirurgia plastica', clinicSuffix: 'Clinica di chirurgia plastica'),
    (
      name: 'Medicina generale',
      clinicSuffix: 'Ambulatorio di medicina generale',
    ),
    (name: 'Medicina interna', clinicSuffix: 'Ambulatorio di medicina interna'),
    (name: 'Pediatria', clinicSuffix: 'Ambulatorio pediatrico'),
  ],
  // They follow the kind of place: `Studio dermatologico dell’Acero`, or
  // `Ambulatorio pediatrico Demo`.
  clinicNamePrefixes: <String>[
    'della Vista Limpida',
    'della Luce',
    'dell’Acero',
    'del Lungofiume',
    'dei Sempreverdi',
    'di Esempio',
    'Demo',
    'di Porta Nord',
  ],
  // A role is a function or a noun that is the same for a woman and a man
  // (`Estetista`, `Consulente`, `Medico`), and not a title in the masculine:
  // the generator draws the sex of a staff member at random, and the label
  // cannot agree with a name that it does not know.
  staffRoles: <String, String>{
    'director': 'Direzione sanitaria',
    'doctor': 'Medico',
    'counselor': 'Consulente per i pazienti',
    'coordinator': 'Coordinamento assistenza',
    'nurse': 'Personale infermieristico',
    'nurseAide': 'Personale socio-sanitario',
    'skincare': 'Estetista',
    'desk': 'Accoglienza',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (name: 'Visita', details: <String>['Prima visita', 'Visita di controllo']),
    (name: 'Procedura', details: <String>['Iniettabili', 'Laser', 'Lifting']),
    (
      name: 'Trattamento',
      details: <String>['Acne', 'Patologia cutanea', 'Verruche'],
    ),
    (name: 'Cura', details: <String>['Cura del viso', 'Cura lenitiva']),
  ],
  // Prices are euros, the English bands at roughly nine tenths and rounded to
  // five. A band includes the VAT (22%) where `taxable` is `true`.
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'Visita/Onorario',
      name: 'Prima visita',
      unit: 'visita',
      minPrice: 80,
      maxPrice: 180,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'Tossina botulinica/Rughe',
      name: 'Tossina botulinica fronte',
      unit: 'zona',
      minPrice: 150,
      maxPrice: 400,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'Filler/Zona',
      name: 'Filler di acido ialuronico labbra 1 ml',
      unit: 'ml',
      minPrice: 400,
      maxPrice: 750,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'Laser/Uniformazione del colorito',
      name: 'Laser a picosecondi, uniformazione del colorito',
      unit: 'seduta',
      minPrice: 150,
      maxPrice: 400,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'Lifting/Ultrasuoni',
      name: 'Lifting a ultrasuoni focalizzati, 300 linee',
      unit: 'seduta',
      minPrice: 800,
      maxPrice: 2500,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'Acne/Trattamento',
      name: 'Estrazione dei comedoni',
      unit: 'seduta',
      minPrice: 50,
      maxPrice: 120,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'Cura/Lenitiva',
      name: 'Cura lenitiva del viso con LED',
      unit: 'seduta',
      minPrice: 50,
      maxPrice: 110,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'Documenti medici',
      name: 'Certificato medico',
      unit: 'copia',
      minPrice: 15,
      maxPrice: 40,
      taxable: false,
    ),
  ],
  // The codes and the English names are the ones of the English data; the
  // Italian names are those of the Italian version of ICD-10.
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'Acne volgare', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'Cloasma', nameEn: 'Chloasma'),
    (code: 'B07', name: 'Verruche virali', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'Dermatite atopica, non specificata',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'Dermatite, non specificata',
      nameEn: 'Dermatitis, unspecified',
    ),
    (
      code: 'L71.9',
      name: 'Rosacea, non specificata',
      nameEn: 'Rosacea, unspecified',
    ),
  ],
  // Invented names that no marketed product has, as in the English data: a web
  // search for each of them found no medicine of that name.
  drugStems: <String>[
    'Pelnovax',
    'Cutarel',
    'Lenidar',
    'Ravexil',
    'Belvanex',
    'Corelmin',
    'Velanor',
    'Cheravil',
  ],
  // A drug reads `Pelnovax compresse 10 mg`: the form has its leading space and
  // the unit has its own.
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ' compresse', unit: ' mg', strengths: <int>[5, 10, 20, 50]),
    (form: ' capsule', unit: ' mg', strengths: <int>[25, 50, 100]),
    (form: ' pomata', unit: ' g', strengths: <int>[15, 30]),
    (form: ' crema', unit: ' g', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    'Una volta al giorno prima di coricarsi',
    'Due volte al giorno dopo i pasti',
    'Applicare uno strato sottile due volte al giorno',
    'Applicare una volta al giorno dopo la detersione',
  ],
  complaints: <String>[
    'Riferisce macchie più scure su entrambe le guance',
    'Acne ricorrente lungo la linea della mandibola',
    'Preoccupazione per le rughe della fronte',
    'Desidera migliorare il rilassamento cutaneo',
    'Arrossamento persistente dopo una procedura',
  ],
  findings: <String>[
    'Macchie brune dai contorni sfumati su entrambe le regioni zigomatiche',
    'Numerose papule infiammatorie sul mento',
    'Rughe frontali dinamiche, grado 2',
    'Rilassamento moderato del terzo inferiore del viso',
    'Eritema lieve, assenza di edema',
  ],
  plans: <String>[
    'Seduta di laser ogni due settimane',
    'Estrazione e terapia topica',
    'Controllo due settimane dopo l’iniezione',
    'Educazione alla fotoprotezione, controllo tra quattro settimane',
    'Osservazione, tornare in caso di peggioramento',
  ],
  memos: <String>[
    'Consigliato di non truccarsi per 24 ore.',
    'Anestetico topico applicato 30 minuti prima della procedura.',
    'Fotografie prima della procedura scattate.',
    'Pacchetto illustrato; decisione rimandata a più tardi.',
    'Prossimo appuntamento fissato tra due settimane.',
  ],
  // The questions speak to the patient with `Lei`.
  questions: <CoQuestionSpec>[
    (
      question: 'Ha allergie ai farmaci?',
      options: <String>['Nessuna', 'Lidocaina', 'Penicillina', 'Non so'],
    ),
    (
      question: 'Sta assumendo farmaci?',
      options: <String>[
        'Nessuno',
        'Anticoagulanti',
        'Farmaci contro l’acne',
        'Altro',
      ],
    ),
    (
      question: 'È in gravidanza o sta allattando?',
      options: <String>[
        'No',
        'In gravidanza',
        'Allattamento',
        'Non pertinente',
      ],
    ),
    (
      question: 'Che cosa desidera migliorare di più?',
      options: <String>['Macchie pigmentarie', 'Acne', 'Rughe', 'Tonicità'],
    ),
  ],
  // Card networks, with the Italian domestic one in place of the fourth.
  cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'Bancomat'],
  // A status is written in the masculine, as the word `appuntamento` it
  // qualifies is.
  labels: <String, String>{
    'nhis': 'Copertura sanitaria pubblica',
    'medicalAid1': 'Esenzione ticket (tipo 1)',
    'medicalAid2': 'Esenzione ticket (tipo 2)',
    'uninsured': 'Privato',
    'reception': 'Accettazione',
    'waiting': 'In attesa',
    'consultation': 'Visita',
    'counseling': 'Consulenza',
    'procedure': 'Procedura',
    'care': 'Cura',
    'payment': 'Pagamento',
    'done': 'Concluso',
    'requested': 'Richiesto',
    'reserved': 'Prenotato',
    'confirmed': 'Confermato',
    'checkedIn': 'Arrivato',
    'completed': 'Completato',
    'cancelled': 'Annullato',
    'noShow': 'Assente',
    'rejected': 'Rifiutato',
    'card': 'Carta',
    'cash': 'Contanti',
    'transfer': 'Bonifico bancario',
    'prepaid': 'Saldo prepagato',
    'package': 'Pacchetto',
    'female': 'Femminile',
    'male': 'Maschile',
  },
  packageNameFormat: '{name} · {sessions} sedute',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Consenso alla procedura',
        clauses: <String>[
          'Mi sono stati illustrati lo scopo, il metodo e l’effetto atteso della procedura.',
          'Comprendo che possono comparire arrossamento, gonfiore o lividi.',
          'Comprendo che i risultati variano e non sono garantiti.',
          'Ho dichiarato i farmaci che assumo, le mie allergie e un’eventuale gravidanza.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Consenso al trattamento dei dati personali',
        clauses: <String>[
          'Dati raccolti: nome, data di nascita, recapiti, documentazione clinica.',
          'Finalità: cura, promemoria degli appuntamenti, fatturazione.',
          'Posso rifiutare, ma la prenotazione online potrebbe non essere disponibile.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Consenso alle riprese fotografiche',
        clauses: <String>[
          'Vengono scattate fotografie prima e dopo per seguire i progressi.',
          'Le fotografie sono usate solo per le cure e non vengono mai pubblicate.',
        ],
      ),
    ],
    consentDisclaimer:
        'Testo di esempio solo a scopo dimostrativo. Non sottoposto a revisione '
        'legale; da non usare come modulo di consenso reale.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'Il medico ha spiegato tutto con cura.',
        'Attesa breve e personale gentile.',
        'Dopo tre sedute il mio colorito è migliorato.',
      ],
      'neutral': <String>[
        'Buoni risultati, ma un po’ costoso.',
        'Il parcheggio era scomodo.',
      ],
      'negative': <String>[
        'Ho aspettato più di 40 minuti oltre l’ora dell’appuntamento.',
        'Il conto finale era diverso dal preventivo.',
      ],
    },
    // The counselor speaks to the patient with `Lei`.
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'laser a picosecondi',
        concern: 'Le macchie scure sulle guance stanno peggiorando.',
        recommend: 'Per la pigmentazione Le consiglio il laser a picosecondi.',
        pain:
            'Dà un leggero fastidio; la maggior parte delle persone non ha '
            'bisogno di anestesia.',
        interval:
            'Circa dieci sedute, a distanza di due settimane l’una dall’altra.',
        downtime:
            'Un po’ di arrossamento per qualche ora; può lavarsi il viso lo '
            'stesso giorno.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'lifting a ultrasuoni focalizzati',
        concern: 'Ho l’impressione che la linea della mandibola sia rilassata.',
        recommend:
            'Il lifting a ultrasuoni focalizzati rassoda gli strati più '
            'profondi.',
        pain:
            'Può dare dolore vicino all’osso, perciò applichiamo una crema '
            'anestetica.',
        interval: 'Una volta ogni sei o dodici mesi.',
        downtime: 'Può tornare subito al lavoro.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Buongiorno, qual è il motivo della Sua visita oggi?',
      questions: <String, String>{
        'pain': 'Fa male?',
        'interval': 'Ogni quanto devo farlo?',
        'downtime': 'Posso andare al lavoro subito dopo?',
        'price': 'Quanto costa?',
      },
      priceAnswer:
          'Costa {price} a seduta, oppure {packagePrice} per un pacchetto di '
          '{sessions} sedute.',
      bookYes: 'Perfetto, vorrei prenotare questa settimana.',
      bookYesReply:
          'Certo, Le prenoto l’appuntamento e Le invio per SMS le indicazioni '
          'per i giorni successivi.',
      bookNo: 'Ci penso e La ricontatto io.',
      bookNoReply: 'Certamente, ci contatti quando vuole.',
      summary:
          'Consigliato: {procedure}. {price} a seduta, {packagePrice} per '
          '{sessions} sedute. {outcome}',
      booked: 'Appuntamento prenotato.',
      pending: 'Decisione in sospeso, da ricontattare più tardi.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Copertura verificata', ok: true),
        (code: 'LOST', message: 'Copertura cessata', ok: false),
        (
          code: 'NOT_FOUND',
          message: 'Nessun iscritto corrispondente',
          ok: false,
        ),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Nessuna interazione rilevata', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Avviso di interazione tra farmaci',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Richiesta ricevuta', ok: true),
        (
          code: 'ADJUSTED',
          message: 'Richiesta rettificata dopo la revisione',
          ok: false,
        ),
        (
          code: 'RETURNED',
          message: 'Richiesta restituita: campi mancanti',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'Ricetta elettronica inviata', ok: true),
        (code: 'FAILED', message: 'La farmacia non l’ha ricevuta', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Identità verificata', ok: true),
        (code: 'EXPIRED', message: 'Codice QR scaduto', ok: false),
      ],
    },
    // Invented names of insurers.
    insurers: <String>[
      'Mutua Nordvento',
      'Vita Portovista',
      'Assicurazioni Cimalinea',
      'Salute Rivalimpida',
    ],
    // `{mention}` and `{patient}` stand at the start of a sentence, after
    // `per`, or alone: no template needs an article or `di` before a name. A
    // note to a colleague speaks with `Lei`, as every other text does.
    teamNotes: <String>[
      '{mention}, per favore riduca di un livello l’intensità del laser per '
          '{patient}.',
      'Passaggio di consegne: crema anestetica applicata per {patient}. '
          '{mention}, può procedere quando vuole.',
      '{mention}, per {patient} resta una sola seduta del pacchetto.',
      'Serve la firma di un genitore o tutore per {patient}. {mention}, per '
          'favore verifichi.',
    ],
    deviceNameFormat: '{kind} n. {number}',
    staffMentionFormat: '@{name} ({role})',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Sé stesso',
      'spouse': 'Coniuge',
      'parent': 'Genitore',
      'child': 'Figlio o figlia',
      'sibling': 'Fratello o sorella',
      'grandparent': 'Nonno o nonna',
      'grandchild': 'Nipote',
      'legalGuardian': 'Tutore legale',
      'other': 'Altro',
      'picoLaser': 'Laser a picosecondi',
      'hifu': 'HIFU',
      'rf': 'RF',
      'ipl': 'IPL',
      'ledTherapy': 'Terapia LED',
      'skinAnalyzer': 'Analizzatore cutaneo',
      'photoCamera': 'Fotocamera clinica',
      'labelPrinter': 'Stampante di etichette',
      'cardTerminal': 'Terminale di pagamento',
      'signaturePad': 'Tavoletta per firme',
      'kiosk': 'Totem per l’accettazione',
      'bridgePc': 'PC ponte',
      'positive': 'Positivo',
      'neutral': 'Neutro',
      'negative': 'Negativo',
      'counselor': 'Consulente',
      'patientSpeaker': 'Paziente',
      'life': 'Vita',
      'nonLife': 'Danni',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Lifting', color: '#6366F1'),
      (code: 'referral', label: 'Segnalazione', color: '#10B981'),
      (code: 'caution', label: 'Attenzione', color: '#EF4444'),
      (code: 'package', label: 'Titolare di pacchetto', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Prenotazione online', color: '#03C75A'),
      (code: 'referral', label: 'Segnalazione', color: '#10B981'),
      (
        code: 'instagramAd',
        label: 'Pubblicità sui social media',
        color: '#E1306C',
      ),
      (code: 'search', label: 'Ricerca online', color: '#7C3AED'),
      (code: 'walkIn', label: 'Senza appuntamento', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Allergia alla lidocaina',
      'Tendenza ai cheloidi: ridurre l’intensità del laser',
      'In terapia con anticoagulanti: verificare prima delle procedure',
      'Allergia alla penicillina',
    ],
    rooms: <CoRoomSpec>[
      (name: 'Sala consulenza 1', kind: 'counseling', staffRole: 'counselor'),
      (name: 'Ambulatorio 1', kind: 'consultation', staffRole: 'director'),
      (name: 'Ambulatorio 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Sala procedure 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Cabina di cura 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Cassa', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Accettazione da tablet', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Chiarita la durata di conservazione dei dati.',
      'Aggiunta la rete della ricetta elettronica tra i destinatari.',
      'Indicata la conservazione di 90 giorni delle registrazioni della consulenza con IA.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Richiesta di firma inviata.',
      'opened': 'Il paziente ha aperto la richiesta.',
      'signed': 'Firmato elettronicamente.',
      'expired': 'La richiesta è scaduta (24 ore).',
      'failed': 'Impossibile inviare la richiesta; verificare il numero.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        'Sconto paziente abituale 10%',
        'Sconto familiari del personale 20%',
      ],
      'coupon': <String>['Buono prima visita 20%', 'Buono di compleanno'],
      'point': <String>['Punti utilizzati'],
      'rounding': <String>['Arrotondamento'],
    },
    pointReasons: <String, String>{
      'earn': '3% del pagamento accreditato',
      'use': 'Utilizzati alla cassa',
      'bonus': 'Bonus per una recensione',
      'expire': 'Scaduti',
      'refund': 'Stornati dopo un rimborso',
      'adjust': 'Rettifica manuale',
    },
    paymentMessages: <String, String>{
      'approved': 'Carta approvata.',
      'cashReceipt': 'Ricevuta di pagamento in contanti emessa.',
      'partialCancel': 'Annullamento parziale eseguito.',
      'prepaidUsed': 'Addebitato sul saldo prepagato.',
      'declined': 'Carta rifiutata: {reason}',
    },
    tasks: <String>[
      'Controllare la scorta di puntali laser',
      'Ordinare i materiali di consumo',
      'Chiusura giornaliera',
      'Registrare la temperatura del frigorifero',
    ],
    taskMemos: <String>[
      'Da completare prima delle 15:00.',
      'Ordinare subito se ne restano meno di 5.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Accettazione',
      'reservation': 'Ricerca della mia prenotazione',
      'payment': 'Pagamento',
      'document': 'Documenti',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'Stessa procedura negli ultimi 3 mesi'),
      (
        kind: 'priceRule',
        rule:
            'Proporre prima i pacchetti già posseduti rispetto alle singole sedute',
      ),
      (
        kind: 'contraindication',
        rule:
            'Escludere la crema anestetica in caso di allergia alla lidocaina',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'Manca il consenso alla registrazione: la consulenza con IA non può iniziare.',
      'STT_FAILED':
          'Riconoscimento vocale non riuscito. Controllare il microfono.',
      'TOO_SHORT': 'La registrazione è troppo breve per essere riassunta.',
      'MODEL_TIMEOUT': 'Il riepilogo è in ritardo. Riprovare tra poco.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message:
            'Una diagnosi estetica non permette di addebitare l’onorario di una visita rimborsabile.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message:
            'Onorario della visita di controllo fatturato due volte nello stesso giorno.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'Nessun consenso alla pubblicità notturna',
      'MARKETING_NO_CONSENT': 'Nessun consenso al marketing',
      'OPTED_OUT': 'Disiscritto',
      'INVALID_NUMBER': 'Numero non valido',
    },
    // It ends the name of a compound package: `… + crema riparatrice in
    // omaggio`.
    packageBonus: 'crema riparatrice in omaggio',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'Formazione sul nuovo laser',
          body:
              'La formazione sul nuovo laser si terrà mercoledì prossimo alle 18:00 nella sala procedure 1.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'Verifica degli accessi ai numeri di identificazione',
          body:
              'I numeri di identificazione completi possono essere mostrati solo indicando un motivo; gli accessi vengono verificati ogni mese.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'Turni dei giorni festivi',
          body:
              'Il giorno prima della festività la chiusura è alle 17:00. Consultare il piano turni condiviso.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'Parametri vitali stabili (PA {sys}/{dia} mmHg, FC {pulse}, SpO2 {spo2}%, T {temp} °C).',
      'highBp':
          'PA {sys}/{dia} mmHg elevata; ricontrollare dopo 10 minuti di riposo.',
      'fever': 'Febbricola {temp} °C; il medico deciderà se rinviare.',
      'lowSpo2':
          'SpO2 {spo2}% bassa; ricontrollata, nessuna difficoltà respiratoria.',
      'highGlucose':
          'Glicemia {glucose} mg/dL elevata; confermata la misurazione dopo i pasti.',
    },
    // A date reads `mercoledì 25/11` and a range `da lunedì 24/11 a giovedì
    // 26/11`, so a notice needs neither an article nor a contraction before it.
    // The reason follows `Motivo`, and the name of a holiday stands in
    // parentheses.
    closure: <String, String>{
      'title': 'Chiusura {dates}',
      'holiday':
          '{clinic}: chiusura {dates} ({name}). Le visite riprendono '
          'regolarmente {reopen}.',
      'other':
          '{clinic}: chiusura {dates}. Motivo: {reason}. Le visite riprendono '
          'regolarmente {reopen}.',
    },
    closureReasons: <String>[
      'congresso medico',
      'lavori di ristrutturazione',
      'manutenzione delle apparecchiature',
    ],
    dateFormat: '{weekday} {day}/{month}',
    weekdayNames: <String>[
      'lunedì',
      'martedì',
      'mercoledì',
      'giovedì',
      'venerdì',
      'sabato',
      'domenica',
    ],
    dateRangeFormat: 'da {from} a {to}',
    compoundItemFormat: '{name} ({sessions} sedute)',
    labels: <String, String>{
      'requested': 'Richiesto',
      'waiting': 'In attesa',
      'priority': 'Prioritario',
      'inProgress': 'In corso',
      'done': 'Concluso',
      'tablet': 'Tablet',
      'online': 'Online',
      'app': 'App',
      'kiosk': 'Totem',
      'desk': 'Accoglienza',
      'paper': 'Cartaceo',
      'privacyRequired': 'Dati personali (obbligatorio)',
      'marketingOptional': 'Marketing (facoltativo)',
      'sensitiveInfo': 'Dati sensibili',
      'photoUse': 'Uso delle fotografie',
      'thirdParty': 'Condivisione con terzi',
      'aiRecording': 'Registrazione con IA',
      'nightAdvertising': 'Pubblicità notturna',
      'agreed': 'Accettato',
      'withdrawn': 'Revocato',
      'chartHistory': 'Storico della cartella',
      'procedureHistory': 'Storico delle procedure',
      'priceRule': 'Regola di prezzo',
      'contraindication': 'Controindicazione',
      'guideline': 'Linea guida',
      'preference': 'Preferenza',
      'error': 'Errore',
      'warning': 'Avvertenza',
      'discount': 'Sconto',
      'coupon': 'Buono',
      'point': 'Punti',
      'rounding': 'Arrotondamento',
    },
  ),
  // The euro: `1.234,56 €`, with a full stop between thousands and a no-break
  // space before the symbol.
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount}\u00A0{symbol}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // Euros are of the order of the dollars of the English data, so the units
  // stay (five euros for a price, ten for a package, a point for a euro); a
  // payment in installments starts a little lower, as a financed payment does
  // in Italy.
  priceScale: CoClinicPriceScale(
    priceRounding: 5,
    packageRounding: 10,
    prepaidStep: 10,
    installmentMinimum: 300,
    splitMinimum: 50,
    splitRounding: 1,
    adjustmentUnit: 1,
    pointUnit: 1,
    quoteMin: 50,
    quoteMax: 300,
  ),
  clinicNameFormat: '{suffix} {prefix}',
  koreanValues: CoKoreanValues.none,
  // The shape of an Italian tax code (sixteen characters), masked but for the
  // three digits of the code of the place.
  maskedIdFormat: '************###*',
  addressLineFormat: '{line1}, {city}',
);
