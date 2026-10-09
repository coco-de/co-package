import '../../currency_format.dart';
import '../../korean_values.dart';
import '../../saas_data.dart';
import '../../saas_ops.dart';

/// Italian (`it`) SaaS data for `faker.saas`.
///
/// The back office of a clinic software vendor in euros that follows
/// `CoFakerSaasData.english`: every list has the length of the English one, in
/// the same order, and a map has its keys. `it`, `it_IT`, and
/// `CoFaker.forLanguage('it')` read it.
///
/// What makes the data Italian and not a translation only:
///
/// - the amounts are euros written `1.234,56 €`, the plans cost euros, and the
///   VAT of an invoice is the 22% that Italy applies to a software service;
/// - a notification template writes its variables in Italian
///   (`#{nome}`, `#{struttura}`), speaks to the customer with `Lei`, and puts
///   no article or contraction before a variable, because the value decides
///   them: a variable follows a colon, a comma, or a parenthesis;
/// - a title that a name or a service fills (`{target}`, `{service}`) puts the
///   name first and a colon after it, so that it needs no `di` or `del`;
/// - an action of the console is a noun (`Approvazione struttura`), which is
///   neither `Lei` nor `tu`;
/// - a count is written after its label (`Notifiche inviate: {n}`), which needs
///   no plural to agree;
/// - no Korean-only value appears (`CoKoreanValues.none`): the business number
///   of a tenant is eleven digits, as the VAT number (`partita IVA`) of an
///   Italian company is.
const CoFakerSaasData itSaas = CoFakerSaasData(
  plans: <CoPlanSpec>[
    (
      code: 'starter',
      name: 'Base',
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
      name: 'Pro',
      monthlyPrice: 249,
      seats: 25,
      messageCredits: 5000,
    ),
    (
      code: 'enterprise',
      name: 'Aziendale',
      monthlyPrice: 479,
      seats: 100,
      messageCredits: 20000,
    ),
  ],
  // The variables are Italian and stand after a colon, a comma, or a
  // parenthesis, because the template is not filled by the generator: the
  // application that sends it fills them.
  messageTemplates: <CoMessageTemplateSpec>[
    (
      code: 'RSV_CREATED',
      name: 'Appuntamento prenotato',
      body:
          'Gentile #{nome}, la Sua visita è stata prenotata: #{struttura}, '
          '#{data_ora}.',
    ),
    (
      code: 'RSV_CANCELLED',
      name: 'Appuntamento annullato',
      body:
          'Gentile #{nome}, la Sua visita in programma (#{data_ora}) è stata '
          'annullata.',
    ),
    (
      code: 'RSV_REMIND_D1',
      name: 'Promemoria',
      body:
          'Gentile #{nome}, Le ricordiamo la visita di domani: #{ora}, '
          '#{struttura}.',
    ),
    (
      code: 'QUESTIONNAIRE',
      name: 'Questionario prima della visita',
      body:
          'Gentile #{nome}, La preghiamo di compilare il questionario prima '
          'della visita: #{link}',
    ),
    (
      code: 'SURVEY',
      name: 'Sondaggio di soddisfazione',
      body:
          'Gentile #{nome}, com’è andata la Sua visita (#{struttura})? '
          '#{link}',
    ),
    (
      code: 'AD_EVENT',
      name: 'Promozione (pubblicità)',
      body:
          '[Pubblicità] Offerta del mese, #{struttura}: 10 sedute di laser in '
          'promozione. Per disiscriversi: #{link}',
    ),
  ],
  notices: <CoNoticeSpec>[
    (
      category: 'maintenance',
      title: 'Manutenzione programmata',
      body:
          'Il servizio non sarà disponibile dalle 02:00 alle 04:00 per '
          'manutenzione.',
    ),
    (
      category: 'release',
      title: 'Nuove funzionalità disponibili',
      body:
          'Ora può vedere il numero di attesa direttamente nella schermata di '
          'prenotazione.',
    ),
    (
      category: 'notice',
      title: 'Aggiornamento dei prezzi',
      body:
          'I nuovi piani si applicano a partire dalla Sua prossima data di '
          'fatturazione.',
    ),
    (
      category: 'notice',
      title: 'Notifiche in ritardo',
      body: 'Alcune notifiche sono in ritardo e verranno inviate come SMS.',
    ),
  ],
  failureReasons: <String, String>{
    'INVALID_NUMBER': 'Numero del destinatario non valido',
    'NOT_FRIEND': 'Il destinatario non usa l’app di messaggistica',
    'TEMPLATE_MISMATCH': 'Modello non corrispondente',
    'NO_CREDIT': 'Crediti insufficienti',
    'CARRIER_TIMEOUT': 'Tempo scaduto presso l’operatore',
    'OPTED_OUT': 'Il destinatario si è disiscritto',
  },
  // A status is written in the masculine, as the word `stato` it qualifies is,
  // because the same label serves a subscription, an invoice, and a message.
  labels: <String, String>{
    'trialing': 'In prova',
    'active': 'Attivo',
    'pastDue': 'Pagamento in ritardo',
    'paused': 'In pausa',
    'cancelled': 'Disdetto',
    'draft': 'Bozza',
    'open': 'In attesa di pagamento',
    'paid': 'Pagato',
    'overdue': 'Insoluto',
    'void': 'Annullato',
    'refunded': 'Rimborsato',
    'alimtalk': 'Notifica tramite messaggistica',
    'sms': 'SMS',
    'lms': 'LMS',
    'queued': 'In coda',
    'sent': 'Inviato',
    'failed': 'Non riuscito',
    'fallbackSent': 'Inviato con un canale alternativo',
    'approved': 'Approvato',
    'reviewing': 'In revisione',
    'rejected': 'Rifiutato',
    'pending': 'In sospeso',
    'eligibility': 'Verifica della copertura',
    'dur': 'Revisione dell’uso dei farmaci',
    'ePrescription': 'Ricetta elettronica',
    'insuranceClaim': 'Richiesta di rimborso assicurativo',
    'identityQr': 'Codice QR di identità',
    'alimtalkGateway': 'Piattaforma di messaggistica',
    'payment': 'Piattaforma di pagamento',
    'up': 'Operativo',
    'degraded': 'Degradato',
    'down': 'Interruzione',
    'login': 'Accesso',
    'loginFailed': 'Accesso non riuscito',
    'view': 'Visualizzazione',
    'revealRrn': 'Visualizzazione del numero di identificazione',
    'create': 'Creazione',
    'update': 'Modifica',
    'delete': 'Eliminazione',
    'print': 'Stampa',
    'exportData': 'Esportazione',
    'send': 'Invio',
    'roleChange': 'Cambio di ruolo',
    'notice': 'Avviso',
    'maintenance': 'Manutenzione',
    'release': 'Rilascio',
    'fee': 'Tariffario prestazioni',
    'drug': 'Prezzi dei farmaci',
    'material': 'Materiali',
    'diagnosis': 'Diagnosi',
    'current': 'In vigore',
    'scheduled': 'Programmato',
    'archived': 'Archiviato',
    'purchase': 'Acquisto',
    'usage': 'Utilizzo',
    'refund': 'Rimborso',
    'grant': 'Assegnazione',
  },
  ops: CoFakerSaasOps(
    // A summary starts with the name it is about, then a colon: no article and
    // no contracted preposition stands before `{target}`. A label is a noun.
    operatorActions: <String, CoOperatorActionSpec>{
      'tenant.approve': (
        label: 'Approvazione struttura',
        summary: '{target}: iscrizione approvata.',
      ),
      'tenant.suspend': (
        label: 'Sospensione struttura',
        summary: '{target}: sospensione per pagamento in ritardo.',
      ),
      'tenant.resume': (
        label: 'Riattivazione struttura',
        summary: '{target}: sospensione revocata.',
      ),
      'plan.change': (
        label: 'Cambio di piano',
        summary: '{target}: passaggio dal piano Standard al piano Pro.',
      ),
      'invoice.issue': (
        label: 'Emissione fattura',
        summary: '{target}: fattura mensile emessa.',
      ),
      'invoice.refund': (
        label: 'Rimborso fattura',
        summary: '{target}: rimborso parziale di una fattura.',
      ),
      'credit.grant': (
        label: 'Assegnazione crediti',
        summary: '{target}: assegnati 1.000 crediti messaggi.',
      ),
      'template.approve': (
        label: 'Approvazione modello',
        summary: '{target}: modello approvato.',
      ),
      'template.reject': (
        label: 'Rifiuto modello',
        summary: '{target}: modello pubblicitario rifiutato.',
      ),
      'senderNumber.approve': (
        label: 'Approvazione numero mittente',
        summary: '{target}: numero mittente approvato.',
      ),
      'master.publish': (
        label: 'Pubblicazione tariffario di riferimento',
        summary: 'Nuovo tariffario di riferimento pubblicato ({target}).',
      ),
      'notice.publish': (
        label: 'Pubblicazione avviso',
        summary: 'Avviso «{target}» pubblicato.',
      ),
      'operator.invite': (
        label: 'Invito operatore',
        summary: 'Operatore invitato: {target}.',
      ),
      'operator.roleChange': (
        label: 'Cambio di ruolo operatore',
        summary: 'Ruolo modificato per {target}: amministratore.',
      ),
      'impersonate.start': (
        label: 'Accesso per conto di una struttura',
        summary:
            '{target}: accesso per conto della struttura per analizzare un '
            'problema.',
      ),
    },
    operatorRoles: <String, String>{
      'owner': 'Proprietario',
      'admin': 'Amministratore',
      'billing': 'Fatturazione',
      'support': 'Assistenza clienti',
      'viewer': 'Sola lettura',
    },
    autopayFailures: <String, String>{
      'LIMIT_EXCEEDED': 'Limite della carta superato',
      'CARD_EXPIRED': 'Carta scaduta',
      'INSUFFICIENT_FUNDS': 'Fondi insufficienti',
      'CARD_LOST': 'Carta segnalata come smarrita o rubata',
      'CARD_SUSPENDED': 'Carta sospesa',
      'ISSUER_TIMEOUT': 'Tempo scaduto presso l’emittente',
    },
    // Unit prices in euros.
    masterRows: <String, List<CoMasterRowSpec>>{
      'fee': <CoMasterRowSpec>[
        (name: 'Prima visita', price: 60),
        (name: 'Visita di controllo', price: 45),
        (name: 'Crioterapia (una zona)', price: 35),
      ],
      'drug': <CoMasterRowSpec>[
        (name: 'Cutarel compresse 10 mg', price: 4),
        (name: 'Lenidar pomata 15 g', price: 8),
      ],
      'material': <CoMasterRowSpec>[
        (name: 'Garze sterili (10)', price: 5),
        (name: 'Siringa 1 ml', price: 1),
      ],
      'diagnosis': <CoMasterRowSpec>[
        (name: 'Acne volgare', price: null),
        (name: 'Verruche virali', price: null),
      ],
    },
    masterChecks: <String, String>{
      'DUPLICATE_CODE': 'Nessun codice duplicato',
      'NEGATIVE_PRICE': 'Nessun prezzo nullo o negativo',
      'EFFECTIVE_DATE': 'Date di decorrenza in ordine',
      'REQUIRED_COLUMNS': 'Nessuna colonna obbligatoria mancante',
      'ROW_DELTA':
          'Numero di righe entro il 5% rispetto alla versione precedente',
      'REMOVED_IN_USE':
          'I codici rimossi non sono usati da richieste di rimborso aperte',
    },
    // The service comes first, then a colon, so that no `di` stands before it.
    incidentTitles: <String, String>{
      'outage': '{service}: interruzione',
      'degraded': '{service}: risposte lente',
      'maintenance': '{service}: manutenzione programmata',
    },
    alerts: <CoOpsAlertSpec>[
      (
        level: 'warning',
        code: 'SYNC_DELAY',
        message:
            '3 strutture hanno la sincronizzazione offline in ritardo di oltre 15 minuti.',
      ),
      (
        level: 'critical',
        code: 'AUTOPAY_FAILED',
        message:
            'Questo mese 7 fatture hanno avuto un addebito automatico non riuscito.',
      ),
      (
        level: 'warning',
        code: 'LOW_CREDIT',
        message: '5 strutture hanno meno di 100 crediti messaggi.',
      ),
      (
        level: 'info',
        code: 'BACKUP_DONE',
        message: 'Il backup notturno è stato completato.',
      ),
    ],
    releaseItems: <String>[
      'Il numero di attesa è visibile direttamente nella schermata di prenotazione.',
      'Pagamenti frazionati e saldo prepagato in un’unica schermata.',
      'Le notifiche non riuscite passano automaticamente a un SMS.',
      'Si possono menzionare i colleghi con @ nelle note della cartella.',
    ],
    regulationItems: <String>[
      'Applicato il tariffario aggiornato.',
      'Applicato l’elenco aggiornato dei prezzi dei farmaci.',
      'Aggiornate le corrispondenze dei codici di diagnosi.',
    ],
    releaseTitle:
        'Note di rilascio della cartella clinica elettronica {version}',
    regulationTitle: 'Aggiornamenti normativi {month}',
    // The count follows its label, so that one or many needs no agreement.
    tenantActivities: <String>[
      'Nuovi pazienti registrati: {n}',
      'Richieste di rimborso inviate: {n}',
      'Notifiche inviate: {n}',
      'Appuntamenti prenotati: {n}',
      'Account del personale aggiunti: {n}',
    ],
    templateRejectReason:
        'Contiene pubblicità; inviarlo come messaggio di marketing.',
    labels: <String, String>{
      'active': 'Attivo',
      'invited': 'Invitato',
      'suspended': 'Sospeso',
      'allTenants': 'Tutte le strutture',
      'proAndAbove': 'Piani Pro e superiori',
      'dermatology': 'Studi dermatologici',
      'inApp': 'Nell’app',
      'email': 'E-mail',
      'alimtalk': 'Notifica tramite messaggistica',
      'outage': 'Interruzione',
      'degraded': 'Degradato',
      'maintenance': 'Manutenzione',
      'info': 'Informazione',
      'warning': 'Avvertenza',
      'critical': 'Critico',
      'topUp': 'Ricarica',
      'usage': 'Utilizzo',
      'refund': 'Rimborso',
      'card': 'Carta',
      'transfer': 'Bonifico bancario',
      'virtualAccount': 'Conto virtuale',
      'release': 'Rilascio',
      'regulation': 'Aggiornamento normativo',
      'failed': 'Pagamento non riuscito',
      'added': 'Aggiunto',
      'updated': 'Aggiornato',
      'removed': 'Rimosso',
    },
    senderLabels: <String>['Linea principale', 'Prenotazioni', 'Accoglienza'],
    healthMessages: <String, String>{
      'degraded': 'Risposte lente',
      'down': 'Tempo di connessione scaduto',
    },
    auditTargets: <String, String>{
      'login': 'account',
      'loginFailed': 'account',
      'roleChange': 'ruolo del personale',
      'send': 'notifica',
    },
    auditRecords: <String>['paziente', 'cartella', 'fattura', 'prenotazione'],
    // The count follows its label, so that one row or many needs no agreement.
    masterCheckDetail: 'Righe non conformi: {n}',
  ),
  // The euro: `1.234,56 €`, with a full stop between thousands and a no-break
  // space before the symbol.
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount} {symbol}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  // Italy applies a 22% VAT to a software service. The prepaid wallet of
  // message credits is topped up in euros, from fifty to two thousand, and a
  // top-up from a hundred euros earns a bonus of five to fifteen percent.
  priceScale: CoSaasPriceScale(
    vatRate: 0.22,
    prepaidTopUps: <int>[50, 100, 250, 500, 1000, 2000],
    prepaidBonusTiers: <(int, int)>[(100, 5), (250, 8), (500, 10), (1000, 15)],
    prepaidLowBalance: 100,
    prepaidUsageMin: 5,
    prepaidUsageRounding: 5,
    prepaidRefundMin: 5,
    prepaidRefundRounding: 5,
  ),
  koreanValues: CoKoreanValues.none,
  // Eleven digits, as the VAT number of an Italian company is written.
  businessNumberFormat: '###########',
);
