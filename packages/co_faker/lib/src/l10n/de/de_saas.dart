import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// German (`de`) SaaS data for `faker.saas`.
///
/// The back office of a practice-software vendor in euros, written as a
/// translation of `CoFakerSaasData.english`: every list and map has the length
/// and the keys of the English one, in the same order, and the codes
/// (`RSV_CREATED`, `starter`, `tenant.approve`) are the English ones. The
/// plans cost euros, an invoice carries the German VAT of 19%, the wallet is
/// topped up in euros, and no Korean-only value appears
/// ([CoKoreanValues.none]).
///
/// The `#{variable}` markers of a message template keep their English names, as
/// the identifiers that a messaging service fills in. A text that holds a
/// number (`{n}`) puts it last, so that it is right for one and for many.
///
/// The texts are a draft that a native speaker has to review: see
/// `docs/languages/de.md`. A customer is addressed with `Sie`.
///
/// `de`, `de_DE`, and `CoFaker.forLanguage('de')` read it.
const CoFakerSaasData deSaas = CoFakerSaasData(
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'Einstieg',
      monthlyPrice: 69,
      seats: 3,
      messageCredits: 500,
    ),
    (
      code: 'standard',
      name: 'Standard',
      monthlyPrice: 139,
      seats: 10,
      messageCredits: 2000,
    ),
    (
      code: 'pro',
      name: 'Professional',
      monthlyPrice: 249,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'Unternehmen',
      monthlyPrice: 499,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'Termin gebucht',
      body:
          'Guten Tag #{name}, Ihr Termin bei #{clinic} am #{dateTime} ist gebucht.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'Termin abgesagt',
      body: 'Guten Tag #{name}, Ihr Termin am #{dateTime} wurde abgesagt.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'Terminerinnerung',
      body:
          'Guten Tag #{name}, wir sehen uns morgen um #{time} Uhr bei #{clinic}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'Fragebogen vor dem Termin',
      body:
          'Guten Tag #{name}, bitte füllen Sie vor Ihrem Termin den Fragebogen aus: #{link}',
    ),
    (
      code: 'SURVEY',
      name: 'Zufriedenheitsumfrage',
      body: 'Guten Tag #{name}, wie war Ihr Besuch bei #{clinic}? #{link}',
    ),
    (
      code: 'AD_EVENT',
      name: 'Werbeaktion',
      body:
          '[Werbung] Monatsangebot von #{clinic}: 10 Laser-Toning-Sitzungen im Angebot. Abmelden: #{link}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'Geplante Wartung',
      body:
          'Der Dienst ist wegen Wartungsarbeiten von 02:00 bis 04:00 Uhr nicht verfügbar.',
    ),
    (
      category: 'release',
      title: 'Neue Funktionen veröffentlicht',
      body:
          'Die Wartenummer sehen Sie jetzt direkt auf dem Buchungsbildschirm.',
    ),
    (
      category: 'notice',
      title: 'Preisanpassung',
      body: 'Die neuen Tarife gelten ab Ihrem nächsten Abrechnungstermin.',
    ),
    (
      category: 'notice',
      title: 'Verzögerte Benachrichtigungen',
      body:
          'Einige Benachrichtigungen verzögern sich und werden stattdessen per SMS gesendet.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'Ungültige Empfängernummer',
    'NOT_FRIEND': 'Empfängerkonto nutzt den Messenger nicht',
    'TEMPLATE_MISMATCH': 'Vorlage stimmt nicht überein',
    'NO_CREDIT': 'Nicht genügend Credits',
    'CARRIER_TIMEOUT': 'Zeitüberschreitung beim Netzbetreiber',
    'OPTED_OUT': 'Nachrichten abbestellt',
  },
  labels: <String, String>{
    'trialing': 'Testphase',
    'active': 'Aktiv',
    'pastDue': 'Zahlung überfällig',
    'paused': 'Pausiert',
    'cancelled': 'Gekündigt',
    'draft': 'Entwurf',
    'open': 'Offen',
    'paid': 'Bezahlt',
    'overdue': 'Überfällig',
    'void': 'Storniert',
    'refunded': 'Erstattet',
    'alimtalk': 'Messenger-Benachrichtigung',
    'sms': 'SMS',
    'lms': 'LMS',
    'queued': 'In der Warteschlange',
    'sent': 'Gesendet',
    'failed': 'Fehlgeschlagen',
    'fallbackSent': 'Ersatzweise gesendet',
    'approved': 'Genehmigt',
    'reviewing': 'In Prüfung',
    'rejected': 'Abgelehnt',
    'pending': 'Ausstehend',
    'eligibility': 'Anspruchsprüfung',
    'dur': 'Medikationsprüfung',
    'ePrescription': 'E-Rezept',
    'insuranceClaim': 'Versicherungsabrechnung',
    'identityQr': 'Ausweis-QR-Code',
    'alimtalkGateway': 'Messaging-Gateway',
    'payment': 'Zahlungs-Gateway',
    'up': 'In Betrieb',
    'degraded': 'Eingeschränkt',
    'down': 'Störung',
    'login': 'Anmeldung',
    'loginFailed': 'Fehlgeschlagene Anmeldung',
    'view': 'Ansehen',
    'revealRrn': 'Ausweisnummer anzeigen',
    'create': 'Erstellen',
    'update': 'Aktualisieren',
    'delete': 'Löschen',
    'print': 'Drucken',
    'exportData': 'Exportieren',
    'send': 'Senden',
    'roleChange': 'Rollenänderung',
    'notice': 'Hinweis',
    'maintenance': 'Wartung',
    'release': 'Veröffentlichung',
    'fee': 'Gebührenordnung',
    'drug': 'Arzneimittelpreise',
    'material': 'Materialien',
    'diagnosis': 'Diagnosen',
    'current': 'Aktuell',
    'scheduled': 'Geplant',
    'archived': 'Archiviert',
    'purchase': 'Kauf',
    'usage': 'Verbrauch',
    'refund': 'Erstattung',
    'grant': 'Zuteilung',
  },
  ops: CoFakerSaasOps(
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Praxis freigeben',
        summary: 'Anmeldung von {target} genehmigt.',
      ),
      'tenant.suspend': (
        label: 'Praxis sperren',
        summary: '{target} gesperrt (Zahlung überfällig).',
      ),
      'tenant.resume': (
        label: 'Praxis entsperren',
        summary: 'Sperre von {target} aufgehoben.',
      ),
      'plan.change': (
        label: 'Tarif ändern',
        summary: '{target} von Standard auf Professional umgestellt.',
      ),
      'invoice.issue': (
        label: 'Rechnung ausstellen',
        summary: 'Monatsrechnung für {target} ausgestellt.',
      ),
      'invoice.refund': (
        label: 'Rechnung erstatten',
        summary: 'Eine Rechnung von {target} teilweise erstattet.',
      ),
      'credit.grant': (
        label: 'Credits gutschreiben',
        summary: '{target} wurden 1.000 Nachrichten-Credits gutgeschrieben.',
      ),
      'template.approve': (
        label: 'Vorlage genehmigen',
        summary: 'Eine Vorlage von {target} genehmigt.',
      ),
      'template.reject': (
        label: 'Vorlage ablehnen',
        summary: 'Eine Werbevorlage von {target} abgelehnt.',
      ),
      'senderNumber.approve': (
        label: 'Absendernummer genehmigen',
        summary: 'Eine Absendernummer von {target} genehmigt.',
      ),
      'master.publish': (
        label: 'Abrechnungsstammdaten veröffentlichen',
        summary: 'Neue Abrechnungsstammdaten veröffentlicht ({target}).',
      ),
      'notice.publish': (
        label: 'Hinweis veröffentlichen',
        summary: 'Hinweis „{target}“ veröffentlicht.',
      ),
      'operator.invite': (
        label: 'Operator:in einladen',
        summary: '{target} als Operator:in eingeladen.',
      ),
      'operator.roleChange': (
        label: 'Rolle der Operator:in ändern',
        summary: 'Rolle von {target} auf Administration geändert.',
      ),
      'impersonate.start': (
        label: 'Als Praxis anmelden',
        summary: 'Zur Fehleranalyse als {target} angemeldet.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Eigentümer:in',
      'admin': 'Administration',
      'billing': 'Abrechnung',
      'support': 'Kundenbetreuung',
      'viewer': 'Lesezugriff',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Kartenlimit überschritten',
      'CARD_EXPIRED': 'Karte abgelaufen',
      'INSUFFICIENT_FUNDS': 'Unzureichende Deckung',
      'CARD_LOST': 'Karte als verloren oder gestohlen gemeldet',
      'CARD_SUSPENDED': 'Karte gesperrt',
      'ISSUER_TIMEOUT': 'Zeitüberschreitung beim Kartenaussteller',
    },
    // The prices are euros per pack or per service, whole numbers: a tablet
    // costs cents, so a drug and a material row name a pack.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'Erstvorstellung', price: 18),
        (name: 'Folgevorstellung', price: 13),
        (name: 'Kryotherapie (eine Stelle)', price: 10),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Lumisan Tabletten 10 mg', price: 6),
        (name: 'Zeravil Salbe 15 g', price: 7),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Sterile Mullkompressen (10 Stück)', price: 4),
        (name: 'Einmalspritzen 1 ml (10 Stück)', price: 3),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Akne vulgaris', price: null),
        (name: 'Viruswarzen', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'Keine doppelten Codes',
      'NEGATIVE_PRICE': 'Keine Preise von null oder darunter',
      'EFFECTIVE_DATE': 'Gültigkeitsdaten in der richtigen Reihenfolge',
      'REQUIRED_COLUMNS': 'Keine fehlenden Pflichtspalten',
      'ROW_DELTA': 'Zeilenzahl innerhalb von 5 % der Vorversion',
      'REMOVED_IN_USE':
          'Entfernte Codes werden von offenen Abrechnungen nicht verwendet',
    },
    incidentTitles: <String, String>{
      'outage': 'Störung bei {service}',
      'degraded': 'Verzögerte Antworten bei {service}',
      'maintenance': 'Geplante Wartung: {service}',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message:
            'Bei 3 Praxen ist die Offline-Synchronisierung um mehr als 15 '
            'Minuten verzögert.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message:
            'Bei 7 Rechnungen ist die automatische Abbuchung in diesem Monat '
            'fehlgeschlagen.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: 'Bei 5 Praxen liegen weniger als 100 Nachrichten-Credits vor.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'Die nächtliche Sicherung wurde abgeschlossen.',
      ),
    ],
    releaseItems: <String>[
      'Wartenummer direkt auf dem Buchungsbildschirm sehen.',
      'Teilzahlungen und Guthaben auf einem Bildschirm.',
      'Fehlgeschlagene Benachrichtigungen werden automatisch per SMS gesendet.',
      'Teammitglieder in Aktennotizen mit @ erwähnen.',
    ],
    regulationItems: <String>[
      'Überarbeitete Gebührenordnung übernommen.',
      'Aktualisierte Arzneimittelpreisliste übernommen.',
      'Zuordnungen der Diagnosecodes aktualisiert.',
    ],
    releaseTitle: 'Versionshinweise zu EMR {version}',
    regulationTitle: 'Regulatorische Änderungen {month}',
    tenantActivities: <String>[
      'Neu registrierte Patient:innen: {n}',
      'Eingereichte Abrechnungen: {n}',
      'Gesendete Benachrichtigungen: {n}',
      'Gebuchte Termine: {n}',
      'Hinzugefügte Teamkonten: {n}',
    ],
    templateRejectReason:
        'Enthält Werbung; bitte stattdessen als Marketingnachricht senden.',
    labels: <String, String>{
      'active': 'Aktiv',
      'invited': 'Eingeladen',
      'suspended': 'Gesperrt',
      'allTenants': 'Alle Praxen',
      'proAndAbove': 'Tarif Professional und höher',
      'dermatology': 'Dermatologische Praxen',
      'inApp': 'In der App',
      'email': 'E-Mail',
      'alimtalk': 'Messenger-Benachrichtigung',
      'outage': 'Störung',
      'degraded': 'Eingeschränkt',
      'maintenance': 'Wartung',
      'info': 'Information',
      'warning': 'Warnung',
      'critical': 'Kritisch',
      'topUp': 'Aufladung',
      'usage': 'Verbrauch',
      'refund': 'Erstattung',
      'card': 'Karte',
      'transfer': 'Überweisung',
      'virtualAccount': 'Virtuelles Konto',
      'release': 'Veröffentlichung',
      'regulation': 'Regulatorische Änderung',
      'failed': 'Zahlung fehlgeschlagen',
      'added': 'Hinzugefügt',
      'updated': 'Aktualisiert',
      'removed': 'Entfernt',
    },
    senderLabels: <String>['Zentrale', 'Terminbuchung', 'Empfang'],
    healthMessages: <String, String>{
      'degraded': 'Verzögerte Antworten',
      'down': 'Zeitüberschreitung bei der Verbindung',
    },
    auditTargets: <String, String>{
      'login': 'Konto',
      'loginFailed': 'Konto',
      'roleChange': 'Rolle im Team',
      'send': 'Benachrichtigung',
    },
    auditRecords: <String>['Patientendatensatz', 'Akte', 'Rechnung', 'Termin'],
    // The number goes last, so the text is right for one row and for twelve.
    masterCheckDetail: 'Zeilen: {n}',
  ),
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount} {symbol}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  priceScale: CoSaasPriceScale(
    vatRate: 0.19,
    prepaidTopUps: <int>[100, 250, 500, 1000, 2500],
    prepaidBonusTiers: <(int, int)>[(250, 5), (500, 8), (1000, 10), (2500, 12)],
    prepaidLowBalance: 100,
    prepaidUsageMin: 10,
    prepaidUsageRounding: 5,
    prepaidRefundMin: 5,
    prepaidRefundRounding: 5,
  ),
  koreanValues: CoKoreanValues.none,
  businessNumberFormat: 'DE#########',
);
