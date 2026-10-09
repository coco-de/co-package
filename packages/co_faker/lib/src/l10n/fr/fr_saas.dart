import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// French (`fr`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in euros that follows
/// `CoFakerSaasData.english`: every list has the length of the English one, in
/// the same order, and a map has its keys. `fr`, `fr_FR`, and
/// `CoFaker.forLanguage('fr')` read it.
///
/// What makes the data French and not a translation only:
///
/// - the amounts are euros written `1 234,56 €`, the plans cost euros, and the
///   VAT of an invoice is the 20% that France applies to a software service;
/// - a notification template writes its variables in French
///   (`#{nom}`, `#{clinique}`), and no variable follows a preposition, because
///   the value decides the elision and the contraction;
/// - a title that a name or a service fills (`{target}`, `{service}`) puts the
///   name first and a colon after it, so that it needs no `de` or `d’`;
/// - a count is written after its label (`Rendez-vous réservés : {n}`), which
///   needs no plural to agree;
/// - no Korean-only value appears (`CoKoreanValues.none`): the business number
///   of a tenant is nine digits in groups of three, as a French company
///   number is.
const CoFakerSaasData frSaas = CoFakerSaasData(
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'Essentiel',
      monthlyPrice: 69,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'Standard',
      monthlyPrice: 149,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'Pro',
      monthlyPrice: 259,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'Entreprise',
      monthlyPrice: 499,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  // The variables are French and stand alone (after a colon, a comma, or a
  // parenthesis), because the template is not filled by the generator.
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'Rendez-vous réservé',
      body:
          'Bonjour #{nom}, votre rendez-vous est réservé : #{clinique}, le '
          '#{date_heure}.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'Rendez-vous annulé',
      body:
          'Bonjour #{nom}, votre rendez-vous prévu le #{date_heure} a été '
          'annulé.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'Rappel',
      body: 'Bonjour #{nom}, à demain à #{heure} : #{clinique}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'Questionnaire avant la visite',
      body:
          'Bonjour #{nom}, merci de remplir le questionnaire avant votre '
          'visite : #{lien}',
    ),
    (
      code: 'SURVEY',
      name: 'Enquête de satisfaction',
      body:
          'Bonjour #{nom}, comment s’est passée votre visite '
          '(#{clinique}) ? #{lien}',
    ),
    (
      code: 'AD_EVENT',
      name: 'Promotion (publicité)',
      body:
          '[Pub] Offre du mois #{clinique} : 10 séances de laser en '
          'promotion. Désabonnement : #{lien}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'Maintenance programmée',
      body:
          'Le service sera indisponible de 2 h à 4 h du matin pour '
          'maintenance.',
    ),
    (
      category: 'release',
      title: 'Nouvelles fonctionnalités disponibles',
      body:
          'Vous pouvez désormais voir le numéro d’attente directement sur '
          'l’écran de réservation.',
    ),
    (
      category: 'notice',
      title: 'Mise à jour des tarifs',
      body:
          'Les nouvelles formules s’appliquent à partir de votre prochaine '
          'date de facturation.',
    ),
    (
      category: 'notice',
      title: 'Notifications retardées',
      body:
          'Certaines notifications sont retardées et seront envoyées par SMS '
          'à la place.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'Numéro du destinataire invalide',
    'NOT_FRIEND': 'Le destinataire n’utilise pas la messagerie',
    'TEMPLATE_MISMATCH': 'Modèle non conforme',
    'NO_CREDIT': 'Crédits insuffisants',
    'CARRIER_TIMEOUT': 'Délai dépassé côté opérateur',
    'OPTED_OUT': 'Le destinataire s’est désabonné',
  },
  // A status is written in the masculine, as the word `statut` it qualifies
  // is, because the same label serves a subscription and an invoice.
  labels: <String, String>{
    'trialing': 'Essai',
    'active': 'Actif',
    'pastDue': 'Paiement en retard',
    'paused': 'En pause',
    'cancelled': 'Résilié',
    'draft': 'Brouillon',
    'open': 'En attente de paiement',
    'paid': 'Payé',
    'overdue': 'En retard',
    'void': 'Annulé',
    'refunded': 'Remboursé',
    'alimtalk': 'Notification par messagerie',
    'sms': 'SMS',
    'lms': 'LMS',
    'queued': 'En file d’attente',
    'sent': 'Envoyé',
    'failed': 'Échec',
    'fallbackSent': 'Envoyé par un canal de secours',
    'approved': 'Approuvé',
    'reviewing': 'En cours d’examen',
    'rejected': 'Rejeté',
    'pending': 'En attente',
    'eligibility': 'Vérification des droits',
    'dur': 'Revue d’utilisation des médicaments',
    'ePrescription': 'Ordonnance électronique',
    'insuranceClaim': 'Demande de remboursement',
    'identityQr': 'Code QR d’identité',
    'alimtalkGateway': 'Passerelle de messagerie',
    'payment': 'Passerelle de paiement',
    'up': 'Opérationnel',
    'degraded': 'Dégradé',
    'down': 'Panne',
    'login': 'Connexion',
    'loginFailed': 'Échec de connexion',
    'view': 'Lecture',
    'revealRrn': 'Affichage du numéro d’identification',
    'create': 'Création',
    'update': 'Modification',
    'delete': 'Suppression',
    'print': 'Impression',
    'exportData': 'Exportation',
    'send': 'Envoi',
    'roleChange': 'Changement de rôle',
    'notice': 'Avis',
    'maintenance': 'Maintenance',
    'release': 'Version',
    'fee': 'Grille tarifaire',
    'drug': 'Prix des médicaments',
    'material': 'Consommables',
    'diagnosis': 'Diagnostics',
    'current': 'En vigueur',
    'scheduled': 'Programmé',
    'archived': 'Archivé',
    'purchase': 'Achat',
    'usage': 'Utilisation',
    'refund': 'Remboursement',
    'grant': 'Attribution',
  },
  ops: CoFakerSaasOps(
    // A summary starts with the name it is about, then a colon: no `de` or
    // `d’` stands before `{target}`.
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Approuver l’établissement',
        summary: '{target} : inscription approuvée.',
      ),
      'tenant.suspend': (
        label: 'Suspendre l’établissement',
        summary: '{target} : suspension pour retard de paiement.',
      ),
      'tenant.resume': (
        label: 'Réactiver l’établissement',
        summary: '{target} : levée de la suspension.',
      ),
      'plan.change': (
        label: 'Changer de formule',
        summary: '{target} : passage de la formule Standard à la formule Pro.',
      ),
      'invoice.issue': (
        label: 'Émettre une facture',
        summary: '{target} : facture mensuelle émise.',
      ),
      'invoice.refund': (
        label: 'Rembourser une facture',
        summary: '{target} : remboursement partiel d’une facture.',
      ),
      'credit.grant': (
        label: 'Accorder des crédits',
        summary: '{target} : 1 000 crédits de messages accordés.',
      ),
      'template.approve': (
        label: 'Approuver un modèle',
        summary: '{target} : modèle approuvé.',
      ),
      'template.reject': (
        label: 'Rejeter un modèle',
        summary: '{target} : modèle publicitaire rejeté.',
      ),
      'senderNumber.approve': (
        label: 'Approuver un numéro d’expéditeur',
        summary: '{target} : numéro d’expéditeur approuvé.',
      ),
      'master.publish': (
        label: 'Publier le référentiel de facturation',
        summary: 'Nouveau référentiel de facturation publié ({target}).',
      ),
      'notice.publish': (
        label: 'Publier un avis',
        summary: 'Avis « {target} » publié.',
      ),
      'operator.invite': (
        label: 'Inviter un opérateur',
        summary: 'Invitation envoyée à {target} en tant qu’opérateur.',
      ),
      'operator.roleChange': (
        label: 'Modifier le rôle d’un opérateur',
        summary: 'Rôle modifié pour {target} : administrateur.',
      ),
      'impersonate.start': (
        label: 'Se connecter en tant qu’établissement',
        summary: '{target} : connexion à sa place pour analyser un incident.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Propriétaire',
      'admin': 'Administrateur',
      'billing': 'Facturation',
      'support': 'Assistance',
      'viewer': 'Lecteur',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Plafond de la carte dépassé',
      'CARD_EXPIRED': 'Carte expirée',
      'INSUFFICIENT_FUNDS': 'Solde insuffisant',
      'CARD_LOST': 'Carte signalée perdue ou volée',
      'CARD_SUSPENDED': 'Carte suspendue',
      'ISSUER_TIMEOUT': 'Délai dépassé côté émetteur',
    },
    // Unit prices in euros.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'Première consultation', price: 60),
        (name: 'Consultation de suivi', price: 45),
        (name: 'Cryothérapie (une zone)', price: 35),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Lumisol comprimé 10 mg', price: 4),
        (name: 'Keraphen pommade 15 g', price: 9),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Compresses stériles (10)', price: 5),
        (name: 'Seringue 1 ml', price: 1),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Acné vulgaire', price: null),
        (name: 'Verrues virales', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'Aucun code en double',
      'NEGATIVE_PRICE': 'Aucun prix nul ou négatif',
      'EFFECTIVE_DATE': 'Dates d’effet dans l’ordre',
      'REQUIRED_COLUMNS': 'Aucune colonne obligatoire manquante',
      'ROW_DELTA': 'Nombre de lignes à 5 % près de la version précédente',
      'REMOVED_IN_USE':
          'Les codes supprimés ne sont pas utilisés par des demandes en cours',
    },
    // The service comes first, then a colon, so that no `de` stands before it.
    incidentTitles: <String, String>{
      'outage': '{service} : panne',
      'degraded': '{service} : réponses lentes',
      'maintenance': '{service} : maintenance programmée',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message:
            '3 établissements ont une synchronisation hors ligne en retard de plus de 15 minutes.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message: '7 factures ont échoué au prélèvement automatique ce mois-ci.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '5 établissements ont moins de 100 crédits de messages.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'La sauvegarde de nuit est terminée.',
      ),
    ],
    releaseItems: <String>[
      'Voyez le numéro d’attente directement sur l’écran de réservation.',
      'Paiements fractionnés et solde prépayé sur un seul écran.',
      'Les notifications en échec basculent automatiquement vers un SMS.',
      'Mentionnez vos collègues avec @ dans les notes du dossier.',
    ],
    regulationItems: <String>[
      'Application de la grille tarifaire révisée.',
      'Application de la liste de prix des médicaments mise à jour.',
      'Mise à jour de la correspondance des codes de diagnostic.',
    ],
    releaseTitle: 'Notes de version DPI {version}',
    regulationTitle: 'Mises à jour réglementaires {month}',
    // The count follows its label, so that one or many needs no agreement.
    tenantActivities: <String>[
      'Nouveaux patients enregistrés : {n}',
      'Demandes de remboursement envoyées : {n}',
      'Notifications envoyées : {n}',
      'Rendez-vous réservés : {n}',
      'Comptes du personnel ajoutés : {n}',
    ],
    templateRejectReason:
        'Contient de la publicité ; envoyez-le comme message marketing.',
    labels: <String, String>{
      'active': 'Actif',
      'invited': 'Invité',
      'suspended': 'Suspendu',
      'allTenants': 'Tous les établissements',
      'proAndAbove': 'Formules Pro et supérieures',
      'dermatology': 'Cabinets de dermatologie',
      'inApp': 'Dans l’application',
      'email': 'E-mail',
      'alimtalk': 'Notification par messagerie',
      'outage': 'Panne',
      'degraded': 'Dégradé',
      'maintenance': 'Maintenance',
      'info': 'Information',
      'warning': 'Avertissement',
      'critical': 'Critique',
      'topUp': 'Recharge',
      'usage': 'Utilisation',
      'refund': 'Remboursement',
      'card': 'Carte',
      'transfer': 'Virement bancaire',
      'virtualAccount': 'Compte virtuel',
      'release': 'Version',
      'regulation': 'Mise à jour réglementaire',
      'failed': 'Paiement échoué',
      'added': 'Ajouté',
      'updated': 'Mis à jour',
      'removed': 'Supprimé',
    },
    senderLabels: <String>['Ligne principale', 'Rendez-vous', 'Accueil'],
    healthMessages: <String, String>{
      'degraded': 'Réponses lentes',
      'down': 'Délai de connexion dépassé',
    },
    auditTargets: <String, String>{
      'login': 'compte',
      'loginFailed': 'compte',
      'roleChange': 'rôle du personnel',
      'send': 'message',
    },
    auditRecords: <String>['patient', 'dossier', 'facture', 'réservation'],
    masterCheckDetail: '{n} ligne(s)',
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
  // France applies a 20% VAT to a software service. The prepaid wallet of
  // message credits is topped up in euros, from fifty to two thousand, and a
  // top-up from a hundred euros earns a bonus of five to fifteen percent.
  priceScale: CoSaasPriceScale(
    vatRate: 0.2,
    prepaidTopUps: <int>[50, 100, 250, 500, 1000, 2000],
    prepaidBonusTiers: <(int, int)>[(100, 5), (250, 8), (500, 10), (1000, 15)],
    prepaidLowBalance: 100,
    prepaidUsageMin: 5,
    prepaidUsageRounding: 5,
    prepaidRefundMin: 5,
    prepaidRefundRounding: 5,
  ),
  koreanValues: CoKoreanValues.none,
  // Nine digits in groups of three, as a French company number is written.
  businessNumberFormat: '### ### ###',
);
