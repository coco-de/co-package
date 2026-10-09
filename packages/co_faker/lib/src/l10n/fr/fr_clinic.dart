import '../../clinic_data.dart';
import '../../clinic_ops.dart';
import '../../clinic_texts.dart';
import '../../currency_format.dart';
import '../../korean_values.dart';

/// French (`fr`) clinic data for `faker.clinic`.
///
/// A general dermatology and aesthetic clinic in euros that follows
/// `CoFakerClinicData.english`: every list has the length of the English one,
/// in the same order, so that one seed picks the same record in both
/// languages. `fr`, `fr_FR`, and `CoFaker.forLanguage('fr')` read it.
///
/// What makes the data French and not a translation only:
///
/// - the amounts are euros written `1 234,56 €`: a narrow no-break space
///   between thousands, a comma before the cents, and a no-break space before
///   the symbol. The price bands and the price scale are in euros;
/// - a clinic name is the kind of place first and the name after it
///   (`Cabinet de pédiatrie des Érables`), and a date is `mercredi 25/11`;
/// - the patient is addressed with `vous`, and a text that a value fills never
///   needs the elision of `de` or the contraction of `à le`, because the value
///   comes after a colon or a parenthesis;
/// - no value of the Korean data appears (`CoKoreanValues.none`): the ID is
///   masked in the French shape of a social security number, the phones and
///   addresses are those of France, and a closure notice gives a reason.
const CoFakerClinicData frClinic = CoFakerClinicData(
  specialties: <CoSpecialtySpec>[
    (name: 'Dermatologie', clinicSuffix: 'Cabinet de dermatologie'),
    (
      name: 'Chirurgie plastique',
      clinicSuffix: 'Clinique de chirurgie plastique',
    ),
    (name: 'Médecine générale', clinicSuffix: 'Cabinet de médecine générale'),
    (name: 'Médecine interne', clinicSuffix: 'Cabinet de médecine interne'),
    (name: 'Pédiatrie', clinicSuffix: 'Cabinet de pédiatrie'),
  ],
  // They follow the kind of place: `Cabinet de pédiatrie des Érables`, or
  // `Cabinet de pédiatrie d’exemple`.
  clinicNamePrefixes: <String>[
    'de la Vue-Claire',
    'de l’Éclaircie',
    'des Érables',
    'de la Rive',
    'des Sapins',
    'd’exemple',
    'de démonstration',
    'de la Porte-Nord',
  ],
  // A role is a generic title, written in the masculine as a form does.
  staffRoles: <String, String>{
    'director': 'Médecin-directeur',
    'doctor': 'Médecin',
    'counselor': 'Conseiller patient',
    'coordinator': 'Coordinateur de soins',
    'nurse': 'Infirmier diplômé d’État',
    'nurseAide': 'Aide-soignant',
    'skincare': 'Esthéticien',
    'desk': 'Accueil',
  },
  visitPurposes: <CoVisitPurposeSpec>[
    (
      name: 'Consultation',
      details: <String>['Première consultation', 'Consultation de suivi'],
    ),
    (name: 'Acte', details: <String>['Injections', 'Laser', 'Lifting']),
    (
      name: 'Traitement',
      details: <String>['Acné', 'Affection cutanée', 'Verrues'],
    ),
    (name: 'Soin', details: <String>['Soin du visage', 'Soin apaisant']),
  ],
  // Prices are euros, the English bands at roughly nine tenths and rounded.
  procedures: <CoProcedureSpec>[
    (
      code: 'CONS01',
      category: 'Consultation/Honoraires',
      name: 'Première consultation',
      unit: 'consultation',
      minPrice: 70,
      maxPrice: 180,
      taxable: false,
    ),
    (
      code: 'BTX-F',
      category: 'Toxine botulique/Rides',
      name: 'Toxine botulique front',
      unit: 'zone',
      minPrice: 140,
      maxPrice: 400,
      taxable: true,
    ),
    (
      code: 'FIL-L',
      category: 'Comblement/Zone',
      name: 'Acide hyaluronique lèvres 1 ml',
      unit: 'ml',
      minPrice: 450,
      maxPrice: 800,
      taxable: true,
    ),
    (
      code: 'LT-01',
      category: 'Laser/Uniformisation du teint',
      name: 'Laser picoseconde, uniformisation du teint',
      unit: 'séance',
      minPrice: 180,
      maxPrice: 450,
      taxable: true,
    ),
    (
      code: 'HIFU-300',
      category: 'Lifting/Ultrasons',
      name: 'Lifting par ultrasons focalisés, 300 lignes',
      unit: 'séance',
      minPrice: 800,
      maxPrice: 2700,
      taxable: true,
    ),
    (
      code: 'ACN-01',
      category: 'Acné/Traitement',
      name: 'Extraction des comédons',
      unit: 'séance',
      minPrice: 50,
      maxPrice: 130,
      taxable: false,
    ),
    (
      code: 'CARE-01',
      category: 'Soin/Apaisant',
      name: 'Soin apaisant du visage par LED',
      unit: 'séance',
      minPrice: 50,
      maxPrice: 120,
      taxable: true,
    ),
    (
      code: 'DOC-01',
      category: 'Documents médicaux',
      name: 'Certificat médical',
      unit: 'exemplaire',
      minPrice: 10,
      maxPrice: 30,
      taxable: false,
    ),
  ],
  // The codes and the English names are the ones of the English data; the
  // French names are those of the French version of ICD-10.
  diagnoses: <CoDiagnosisSpec>[
    (code: 'L70.0', name: 'Acné vulgaire', nameEn: 'Acne vulgaris'),
    (code: 'L81.1', name: 'Mélasma', nameEn: 'Chloasma'),
    (code: 'B07', name: 'Verrues virales', nameEn: 'Viral warts'),
    (
      code: 'L20.9',
      name: 'Dermatite atopique, sans précision',
      nameEn: 'Atopic dermatitis, unspecified',
    ),
    (
      code: 'L30.9',
      name: 'Dermatite, sans précision',
      nameEn: 'Dermatitis, unspecified',
    ),
    (
      code: 'L71.9',
      name: 'Rosacée, sans précision',
      nameEn: 'Rosacea, unspecified',
    ),
  ],
  // Invented names that no marketed product has, as in the English data.
  drugStems: <String>[
    'Adermex',
    'Lumisol',
    'Keraphen',
    'Dioclin',
    'Navirox',
    'Seraton',
    'Minobel',
    'Acrozine',
  ],
  // A drug reads `Adermex comprimé 10 mg`: the form has its leading space and
  // the unit a no-break one.
  drugForms: <({String form, String unit, List<int> strengths})>[
    (form: ' comprimé', unit: ' mg', strengths: <int>[5, 10, 20, 50]),
    (form: ' gélule', unit: ' mg', strengths: <int>[25, 50, 100]),
    (form: ' pommade', unit: ' g', strengths: <int>[15, 30]),
    (form: ' crème', unit: ' g', strengths: <int>[15, 30]),
  ],
  drugUsages: <String>[
    'Une fois par jour au coucher',
    'Deux fois par jour après les repas',
    'Appliquer une fine couche deux fois par jour',
    'Appliquer une fois par jour après le nettoyage',
  ],
  complaints: <String>[
    'Signale des taches plus foncées sur les deux joues',
    'Acné récurrente le long de la mâchoire',
    'Préoccupation concernant les rides du front',
    'Souhaite améliorer le relâchement cutané',
    'Rougeurs persistantes après un acte',
  ],
  findings: <String>[
    'Macules brunes mal délimitées sur les deux régions malaires',
    'Multiples papules inflammatoires sur le menton',
    'Rides dynamiques du front, grade 2',
    'Relâchement modéré du bas du visage',
    'Érythème léger, pas d’œdème',
  ],
  plans: <String>[
    'Séance de laser toutes les deux semaines',
    'Extraction et traitement local',
    'Contrôle deux semaines après l’injection',
    'Conseils de photoprotection, revoir dans quatre semaines',
    'Surveillance, revenir en cas d’aggravation',
  ],
  memos: <String>[
    'Maquillage déconseillé pendant 24 heures.',
    'Anesthésique local appliqué 30 minutes avant l’acte.',
    'Photos avant l’acte prises.',
    'Forfait expliqué ; le patient décidera plus tard.',
    'Prochain rendez-vous fixé dans deux semaines.',
  ],
  questions: <CoQuestionSpec>[
    (
      question: 'Avez-vous des allergies médicamenteuses ?',
      options: <String>['Aucune', 'Lidocaïne', 'Pénicilline', 'Je ne sais pas'],
    ),
    (
      question: 'Prenez-vous des médicaments ?',
      options: <String>[
        'Aucun',
        'Anticoagulants',
        'Traitement contre l’acné',
        'Autre',
      ],
    ),
    (
      question: 'Êtes-vous enceinte ou allaitez-vous ?',
      options: <String>['Non', 'Enceinte', 'Allaitement', 'Sans objet'],
    ),
    (
      question: 'Qu’aimeriez-vous améliorer en priorité ?',
      options: <String>['Taches pigmentaires', 'Acné', 'Rides', 'Fermeté'],
    ),
  ],
  // Card networks, with the French domestic one in place of the fourth.
  cardIssuers: <String>['Visa', 'Mastercard', 'Amex', 'CB'],
  // A status is written in the masculine, as the word `rendez-vous` it
  // qualifies is.
  labels: <String, String>{
    'nhis': 'Assurance maladie obligatoire',
    'medicalAid1': 'Aide médicale (type 1)',
    'medicalAid2': 'Aide médicale (type 2)',
    'uninsured': 'À la charge du patient',
    'reception': 'Enregistrement',
    'waiting': 'En attente',
    'consultation': 'Consultation',
    'counseling': 'Entretien conseil',
    'procedure': 'Acte',
    'care': 'Soin',
    'payment': 'Paiement',
    'done': 'Terminé',
    'requested': 'Demandé',
    'reserved': 'Réservé',
    'confirmed': 'Confirmé',
    'checkedIn': 'Arrivé',
    'completed': 'Effectué',
    'cancelled': 'Annulé',
    'noShow': 'Absent',
    'rejected': 'Refusé',
    'card': 'Carte',
    'cash': 'Espèces',
    'transfer': 'Virement bancaire',
    'prepaid': 'Solde prépayé',
    'package': 'Forfait',
    'female': 'Féminin',
    'male': 'Masculin',
  },
  packageNameFormat: '{name} · {sessions} séances',
  texts: CoFakerClinicTexts(
    consentForms: <CoConsentFormSpec>[
      (
        kind: 'procedure',
        title: 'Consentement à l’acte',
        clauses: <String>[
          'On m’a expliqué l’objectif, la méthode et l’effet attendu de l’acte.',
          'Je comprends que des rougeurs, un gonflement ou des ecchymoses peuvent apparaître.',
          'Je comprends que les résultats varient et ne sont pas garantis.',
          'J’ai indiqué mes traitements, mes allergies et mon éventuelle grossesse.',
        ],
      ),
      (
        kind: 'privacy',
        title: 'Consentement relatif aux données personnelles',
        clauses: <String>[
          'Données collectées : nom, date de naissance, coordonnées, dossier médical.',
          'Finalités : soins, rappels de rendez-vous, facturation.',
          'Je peux refuser, mais la prise de rendez-vous en ligne peut alors être indisponible.',
        ],
      ),
      (
        kind: 'photo',
        title: 'Consentement pour la photographie',
        clauses: <String>[
          'Des photos avant et après sont prises pour suivre l’évolution.',
          'Les photos sont utilisées uniquement pour les soins et ne sont jamais publiées.',
        ],
      ),
    ],
    consentDisclaimer:
        'Texte d’exemple pour démonstration uniquement. Non relu juridiquement ; '
        'ne pas utiliser comme formulaire de consentement réel.',
    feedback: <String, List<String>>{
      'positive': <String>[
        'Le médecin a tout expliqué avec soin.',
        'Peu d’attente et une équipe sympathique.',
        'Mon teint s’est amélioré après trois séances.',
      ],
      'neutral': <String>[
        'De bons résultats, mais un peu cher.',
        'Le stationnement était peu pratique.',
      ],
      'negative': <String>[
        'J’ai attendu plus de 40 minutes après l’heure de mon rendez-vous.',
        'La facture finale différait du devis.',
      ],
    },
    counselTopics: <CoCounselTopicSpec>[
      (
        topic: 'toning',
        procedureCode: 'LT-01',
        procedure: 'laser picoseconde',
        concern: 'Les taches foncées sur mes joues s’accentuent.',
        recommend:
            'Pour la pigmentation, je vous recommande le laser picoseconde.',
        pain:
            'Cela pique un peu ; la plupart des personnes n’ont pas besoin d’anesthésie.',
        interval: 'Environ dix séances, espacées de deux semaines.',
        downtime:
            'Quelques rougeurs pendant quelques heures ; vous pouvez vous laver le visage le jour même.',
        sessions: 10,
      ),
      (
        topic: 'lifting',
        procedureCode: 'HIFU-300',
        procedure: 'lifting par ultrasons focalisés',
        concern: 'Ma ligne de mâchoire me semble relâchée.',
        recommend:
            'Le lifting par ultrasons focalisés raffermit les couches profondes.',
        pain:
            'Cela peut être douloureux près de l’os, c’est pourquoi nous appliquons une crème anesthésiante.',
        interval: 'Une fois tous les six à douze mois.',
        downtime: 'Vous pouvez reprendre le travail immédiatement.',
        sessions: 3,
      ),
    ],
    counselScript: (
      greeting: 'Bonjour, qu’est-ce qui vous amène aujourd’hui ?',
      questions: <String, String>{
        'pain': 'Est-ce que ça fait mal ?',
        'interval': 'À quelle fréquence dois-je en faire ?',
        'downtime': 'Puis-je aller travailler juste après ?',
        'price': 'Combien cela coûte-t-il ?',
      },
      priceAnswer:
          'C’est {price} la séance, ou {packagePrice} pour un forfait de '
          '{sessions} séances.',
      bookYes: 'Parfait, je voudrais prendre rendez-vous cette semaine.',
      bookYesReply:
          'Avec plaisir, je vous réserve un créneau et je vous envoie par SMS '
          'les consignes de suivi.',
      bookNo: 'Je vais y réfléchir et je reviendrai vers vous.',
      bookNoReply: 'Bien sûr, n’hésitez pas à nous contacter à tout moment.',
      summary:
          'Recommandation : {procedure}, {price} la séance, {packagePrice} '
          'pour {sessions} séances. {outcome}',
      booked: 'Rendez-vous pris.',
      pending: 'Décision en attente, à relancer plus tard.',
    ),
    integrationResults: <String, List<CoIntegrationResultSpec>>{
      'eligibility': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Droits vérifiés', ok: true),
        (code: 'LOST', message: 'Couverture résiliée', ok: false),
        (code: 'NOT_FOUND', message: 'Aucun assuré correspondant', ok: false),
      ],
      'dur': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Aucune interaction détectée', ok: true),
        (
          code: 'WARN_COMBINATION',
          message: 'Alerte d’interaction médicamenteuse',
          ok: false,
        ),
      ],
      'insuranceClaim': <CoIntegrationResultSpec>[
        (code: 'ACCEPTED', message: 'Demande reçue', ok: true),
        (code: 'ADJUSTED', message: 'Demande ajustée après examen', ok: false),
        (
          code: 'RETURNED',
          message: 'Demande retournée : champs manquants',
          ok: false,
        ),
      ],
      'ePrescription': <CoIntegrationResultSpec>[
        (code: 'SENT', message: 'Ordonnance électronique envoyée', ok: true),
        (code: 'FAILED', message: 'La pharmacie ne l’a pas reçue', ok: false),
      ],
      'identityQr': <CoIntegrationResultSpec>[
        (code: 'OK', message: 'Identité vérifiée', ok: true),
        (code: 'EXPIRED', message: 'Code QR expiré', ok: false),
      ],
    },
    // Invented names of insurers.
    insurers: <String>[
      'Mutuelle Nordvent',
      'Vie Havrevue',
      'Assurances Cimeline',
      'Santé Ruisseclair',
    ],
    // `{mention}` and `{patient}` stand at the start of a sentence, after
    // `pour` or `à`, or alone: no template needs `de` before a name.
    teamNotes: <String>[
      '{mention}, merci de baisser d’un cran le réglage du laser pour {patient}.',
      'Passation : la crème anesthésiante est posée pour {patient}. '
          '{mention}, c’est à vous dès que possible.',
      '{mention}, il reste une séance de forfait à {patient}.',
      'La signature d’un responsable légal est nécessaire pour {patient}. '
          '{mention}, merci de vérifier.',
    ],
    deviceNameFormat: '{kind} n° {number}',
    staffMentionFormat: '@{name} ({role})',
    nameMentionFormat: '@{name}',
    labels: <String, String>{
      'self': 'Soi-même',
      'spouse': 'Conjoint',
      'parent': 'Parent',
      'child': 'Enfant',
      'sibling': 'Frère ou sœur',
      'grandparent': 'Grand-parent',
      'grandchild': 'Petit-enfant',
      'legalGuardian': 'Représentant légal',
      'other': 'Autre',
      'picoLaser': 'Laser picoseconde',
      'hifu': 'HIFU',
      'rf': 'RF',
      'ipl': 'IPL',
      'ledTherapy': 'Photothérapie LED',
      'skinAnalyzer': 'Analyseur de peau',
      'photoCamera': 'Appareil photo clinique',
      'labelPrinter': 'Imprimante d’étiquettes',
      'cardTerminal': 'Terminal de paiement',
      'signaturePad': 'Tablette de signature',
      'kiosk': 'Borne d’enregistrement',
      'bridgePc': 'PC passerelle',
      'positive': 'Positif',
      'neutral': 'Neutre',
      'negative': 'Négatif',
      'counselor': 'Conseiller',
      'patientSpeaker': 'Patient',
      'life': 'Vie',
      'nonLife': 'Non-vie',
    },
  ),
  ops: CoFakerClinicOps(
    patientTags: <CoColoredLabelSpec>[
      (code: 'vip', label: 'VIP', color: '#F59E0B'),
      (code: 'lifting', label: 'Lifting', color: '#6366F1'),
      (code: 'referral', label: 'Recommandation', color: '#10B981'),
      (code: 'caution', label: 'Vigilance', color: '#EF4444'),
      (code: 'package', label: 'Titulaire d’un forfait', color: '#8B5CF6'),
    ],
    acquisitionChannels: <CoColoredLabelSpec>[
      (code: 'onlineBooking', label: 'Réservation en ligne', color: '#03C75A'),
      (code: 'referral', label: 'Recommandation', color: '#10B981'),
      (
        code: 'instagramAd',
        label: 'Publicité sur les réseaux sociaux',
        color: '#E1306C',
      ),
      (code: 'search', label: 'Recherche en ligne', color: '#7C3AED'),
      (code: 'walkIn', label: 'Sans rendez-vous', color: '#64748B'),
    ],
    specialNotes: <String>[
      'Allergie à la lidocaïne',
      'Tendance aux chéloïdes : réduire l’intensité du laser',
      'Sous anticoagulants : vérifier avant les actes',
      'Allergie à la pénicilline',
    ],
    rooms: <CoRoomSpec>[
      (name: 'Espace conseil 1', kind: 'counseling', staffRole: 'counselor'),
      (name: 'Cabinet 1', kind: 'consultation', staffRole: 'director'),
      (name: 'Cabinet 2', kind: 'consultation', staffRole: 'doctor'),
      (name: 'Salle de soins 1', kind: 'procedure', staffRole: 'nurse'),
      (name: 'Cabine de soin 1', kind: 'care', staffRole: 'skincare'),
      (name: 'Caisse', kind: 'payment', staffRole: 'coordinator'),
      (name: 'Enregistrement sur tablette', kind: 'reception', staffRole: null),
    ],
    termsChanges: <String>[
      'Précision de la durée de conservation des données.',
      'Ajout du réseau d’ordonnance électronique parmi les destinataires.',
      'Indication de la conservation de 90 jours des enregistrements de conseil par IA.',
    ],
    consentDispatch: <String, String>{
      'sent': 'Demande de signature envoyée.',
      'opened': 'Le patient a ouvert la demande.',
      'signed': 'Signé électroniquement.',
      'expired': 'La demande a expiré (24 heures).',
      'failed': 'Envoi de la demande impossible ; vérifiez le numéro.',
    },
    adjustments: <String, List<String>>{
      'discount': <String>[
        'Remise patient fidèle 10 %',
        'Remise famille du personnel 20 %',
      ],
      'coupon': <String>['Bon première visite 20 %', 'Bon d’anniversaire'],
      'point': <String>['Points utilisés'],
      'rounding': <String>['Arrondi'],
    },
    pointReasons: <String, String>{
      'earn': '3 % du paiement crédités',
      'use': 'Utilisés à l’encaissement',
      'bonus': 'Bonus pour un avis',
      'expire': 'Expirés',
      'refund': 'Annulés après un remboursement',
      'adjust': 'Ajustement manuel',
    },
    paymentMessages: <String, String>{
      'approved': 'Carte acceptée.',
      'cashReceipt': 'Reçu de paiement en espèces émis.',
      'partialCancel': 'Annulation partielle effectuée.',
      'prepaidUsed': 'Débité du solde prépayé.',
      'declined': 'Carte refusée : {reason}',
    },
    tasks: <String>[
      'Vérifier le stock d’embouts laser',
      'Commander les fournitures',
      'Clôture quotidienne',
      'Relever la température du réfrigérateur',
    ],
    taskMemos: <String>[
      'À terminer avant 15 h.',
      'Commander immédiatement s’il en reste moins de 5.',
    ],
    kioskPurposes: <String, String>{
      'checkin': 'Enregistrement',
      'reservation': 'Retrouver mon rendez-vous',
      'payment': 'Payer',
      'document': 'Mes documents',
    },
    evidence: <CoEvidenceSpec>[
      (kind: 'chartHistory', rule: 'Même acte dans les 3 derniers mois'),
      (
        kind: 'priceRule',
        rule:
            'Proposer d’abord les forfaits détenus avant les séances à l’unité',
      ),
      (
        kind: 'contraindication',
        rule: 'Exclure la crème anesthésiante en cas d’allergie à la lidocaïne',
      ),
    ],
    counselFailures: <String, String>{
      'CONSENT_MISSING':
          'Pas de consentement à l’enregistrement ; le conseil par IA ne peut pas démarrer.',
      'STT_FAILED':
          'La reconnaissance vocale a échoué. Vérifiez le microphone.',
      'TOO_SHORT': 'L’enregistrement est trop court pour être résumé.',
      'MODEL_TIMEOUT': 'Le résumé est retardé. Réessayez dans un instant.',
    },
    claimRules: <CoClaimRuleSpec>[
      (
        ruleId: 'R-DX-001',
        severity: 'error',
        diagnosisCode: 'Z41.1',
        feeCode: 'CONS01',
        message:
            'Un diagnostic esthétique ne permet pas de facturer une consultation remboursable.',
      ),
      (
        ruleId: 'R-FE-118',
        severity: 'warning',
        diagnosisCode: 'L20.9',
        feeCode: 'CONS02',
        message: 'Consultation de suivi facturée deux fois le même jour.',
      ),
    ],
    crmFailures: <String, String>{
      'NIGHT_AD_NO_CONSENT': 'Aucun consentement pour la publicité de nuit',
      'MARKETING_NO_CONSENT': 'Aucun consentement marketing',
      'OPTED_OUT': 'Désabonné',
      'INVALID_NUMBER': 'Numéro invalide',
    },
    // It ends the name of a compound package: `… + crème réparatrice offerte`.
    packageBonus: 'crème réparatrice offerte',
    staffNotices: <String, List<({String title, String body})>>{
      'training': <({String title, String body})>[
        (
          title: 'Formation au nouvel appareil laser',
          body:
              'La formation au nouveau laser a lieu mercredi prochain à 18 h en salle de soins 1.',
        ),
      ],
      'policy': <({String title, String body})>[
        (
          title: 'Contrôle des accès aux numéros d’identification',
          body:
              'Les numéros d’identification complets ne peuvent être affichés qu’avec un motif ; les accès sont contrôlés chaque mois.',
        ),
      ],
      'schedule': <({String title, String body})>[
        (
          title: 'Planning des jours fériés',
          body:
              'La veille du jour férié, fermeture à 17 h. Consultez le planning partagé.',
        ),
      ],
    },
    vitalsNotes: <String, String>{
      'normal':
          'Constantes stables (TA {sys}/{dia} mmHg, FC {pulse}, SpO2 {spo2} %, T {temp} °C).',
      'highBp':
          'TA {sys}/{dia} mmHg élevée ; à recontrôler après 10 minutes de repos.',
      'fever':
          'Fébricule à {temp} °C ; le médecin décidera s’il faut reporter.',
      'lowSpo2': 'SpO2 {spo2} % basse ; recontrôlée, pas de gêne respiratoire.',
      'highGlucose':
          'Glycémie {glucose} mg/dL élevée ; mesure postprandiale confirmée.',
    },
    // A date reads `mercredi 25/11` and a range `du mercredi 25/11 au jeudi
    // 26/11`, so a notice needs neither `le` nor a preposition before it. The
    // reason follows `Motif`, and the name of a holiday stands in parentheses,
    // so that neither needs `de` or `d’`.
    closure: <String, String>{
      'title': 'Fermeture {dates}',
      'holiday':
          '{clinic} : fermeture {dates} ({name}). Reprise normale des '
          'consultations {reopen}.',
      'other':
          '{clinic} : fermeture {dates}. Motif : {reason}. Reprise '
          'normale des consultations {reopen}.',
    },
    closureReasons: <String>[
      'congrès médical',
      'travaux de rénovation',
      'maintenance du matériel',
    ],
    dateFormat: '{weekday} {day}/{month}',
    weekdayNames: <String>[
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ],
    dateRangeFormat: 'du {from} au {to}',
    compoundItemFormat: '{name} ({sessions} séances)',
    labels: <String, String>{
      'requested': 'Demandé',
      'waiting': 'En attente',
      'priority': 'Prioritaire',
      'inProgress': 'En cours',
      'done': 'Terminé',
      'tablet': 'Tablette',
      'online': 'En ligne',
      'app': 'Application',
      'kiosk': 'Borne',
      'desk': 'Guichet',
      'paper': 'Papier',
      'privacyRequired': 'Données personnelles (obligatoire)',
      'marketingOptional': 'Marketing (facultatif)',
      'sensitiveInfo': 'Données sensibles',
      'photoUse': 'Utilisation de photos',
      'thirdParty': 'Partage avec des tiers',
      'aiRecording': 'Enregistrement par IA',
      'nightAdvertising': 'Publicité de nuit',
      'agreed': 'Accepté',
      'withdrawn': 'Retiré',
      'chartHistory': 'Historique du dossier',
      'procedureHistory': 'Historique des actes',
      'priceRule': 'Règle tarifaire',
      'contraindication': 'Contre-indication',
      'guideline': 'Lignes directrices',
      'preference': 'Préférence',
      'error': 'Erreur',
      'warning': 'Avertissement',
      'discount': 'Remise',
      'coupon': 'Bon de réduction',
      'point': 'Points',
      'rounding': 'Arrondi',
    },
  ),
  // The euro: `1 234,56 €`, with a narrow no-break space between thousands
  // and a no-break space before the symbol.
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount} {symbol}',
    groupSeparator: ' ',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // Euros are of the order of the dollars of the English data, so the units
  // stay (five euros for a price, ten for a package, a point for a euro); a
  // payment in installments starts a little lower, as a card payment in
  // several times does in France.
  priceScale: CoClinicPriceScale(
    priceRounding: 5,
    packageRounding: 10,
    prepaidStep: 10,
    installmentMinimum: 400,
    splitMinimum: 50,
    splitRounding: 1,
    adjustmentUnit: 1,
    pointUnit: 1,
    quoteMin: 50,
    quoteMax: 300,
  ),
  clinicNameFormat: '{suffix} {prefix}',
  koreanValues: CoKoreanValues.none,
  // The shape of a French social security number, masked but for the key.
  maskedIdFormat: '* ** ** ** *** *** ##',
  addressLineFormat: '{line1}, {city}',
);
