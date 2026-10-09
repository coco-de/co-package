import '../clinic_data.dart';
import '../clinic_ops.dart';
import '../clinic_texts.dart';
import '../l10n/co_l10n_bundle.dart';
import '../saas_data.dart';
import '../saas_ops.dart';

/// How the language coverage gate judges the strings of a [CoTextSlot].
enum CoTextKind {
  /// Authored text that a language translates: it is checked for Hangul, for
  /// its writing system, and against the English text.
  text,

  /// A layout pattern (`{month}/{day}`, `***-**-####`): only checked for
  /// Hangul, because a pattern has no words to translate.
  format,

  /// A code or an identifier that is the same in every language (`CONS01`,
  /// the English name of a diagnosis): it must equal the English one.
  code,

  /// Text that only the Korean calendar reads (the Korean holiday names).
  /// Data of another language never shows it, so it is not judged.
  koreanOnly,
}

/// Where one string sits in the texts of a language.
///
/// A [slot] is one list or map of strings (`dental.dentalProcedure`,
/// `clinic.cardIssuers`). A [row] is an entry of it, named by its index in a
/// list or by its key in a map ([keyed]). A [cell] is one string of a row:
/// most rows have one, a row that holds a list (the details of a visit
/// purpose) has several.
typedef CoTextPoint = ({
  String slot,
  CoTextKind kind,
  String row,
  int cell,
  bool keyed,
});

/// Receives every string of a data set with its place, and returns the string
/// to put there: the string itself to read the data, another string to
/// rewrite it.
typedef CoTextVisitor = String Function(CoTextPoint at, String text);

/// All rows of one slot, in the order the data lists them.
class CoTextSlot {
  /// Creates an empty slot called [name].
  CoTextSlot(this.name, this.kind, {required this.keyed});

  /// The slot name: the bundle key, or the path of a clinic or SaaS field
  /// such as `clinic.ops.rooms.name`.
  final String name;

  /// How the strings of the slot are judged.
  final CoTextKind kind;

  /// Whether the rows are named by map keys (`true`) or by their index.
  final bool keyed;

  /// The row names in data order.
  final List<String> rows = <String>[];

  final Map<String, List<String>> _cells = <String, List<String>>{};

  /// The number of rows.
  int get length => rows.length;

  /// The strings of the row [row], or `null` when the slot has no such row.
  List<String>? cellsOf(String row) => _cells[row];

  /// Adds [text] as the cell [cell] of the row [row].
  void add(String row, int cell, String text) {
    final cells = _cells.putIfAbsent(row, () {
      rows.add(row);
      return <String>[];
    });
    while (cells.length <= cell) {
      cells.add('');
    }
    cells[cell] = text;
  }
}

/// Every [CoTextSlot] of a data set, by name, in data order.
class CoTextTable {
  /// Creates an empty table.
  CoTextTable();

  /// The slots by name.
  final Map<String, CoTextSlot> slots = <String, CoTextSlot>{};

  /// The slot called [name], or `null`.
  CoTextSlot? operator [](String name) => slots[name];

  /// Collects the strings of a data set into slots; use its [visit] as the
  /// visitor.
  String visit(CoTextPoint at, String text) {
    final slot = slots.putIfAbsent(
      at.slot,
      () => CoTextSlot(at.slot, at.kind, keyed: at.keyed),
    );
    slot.add(at.row, at.cell, text);
    return text;
  }
}

/// The text slots of the bundle, clinic, and SaaS data of a language.
///
/// The three data sets hold their texts in lists, maps, and nested records.
/// This class names every string of them with a [CoTextPoint] so that the
/// coverage gate can compare a language with English slot by slot, and so
/// that a test or a simulation can rewrite every string of a data set
/// ([mapClinic], [mapSaas]) without knowing its shape.
abstract final class CoLanguageTexts {
  /// The fields of [CoFakerClinicData] that [mapClinic] rewrites or copies:
  /// a field of the class that is not listed here is not covered by the
  /// gate, which a test of the package forbids.
  static const Set<String> clinicDataFields = <String>{
    'specialties',
    'clinicNamePrefixes',
    'staffRoles',
    'visitPurposes',
    'procedures',
    'diagnoses',
    'drugStems',
    'drugForms',
    'drugUsages',
    'complaints',
    'findings',
    'plans',
    'memos',
    'questions',
    'cardIssuers',
    'labels',
    'packageNameFormat',
    'texts',
    'ops',
    'clinicNameFormat',
    'currency',
    'priceScale',
    'koreanValues',
    'maskedIdFormat',
    'addressLineFormat',
  };

  /// The fields of [CoFakerClinicTexts] that [mapClinic] covers.
  static const Set<String> clinicTextsFields = <String>{
    'consentForms',
    'consentDisclaimer',
    'feedback',
    'counselTopics',
    'counselScript',
    'integrationResults',
    'insurers',
    'teamNotes',
    'deviceNameFormat',
    'labels',
    'staffMentionFormat',
    'nameMentionFormat',
  };

  /// The fields of [CoFakerClinicOps] that [mapClinic] covers.
  static const Set<String> clinicOpsFields = <String>{
    'patientTags',
    'acquisitionChannels',
    'specialNotes',
    'rooms',
    'termsChanges',
    'consentDispatch',
    'adjustments',
    'pointReasons',
    'paymentMessages',
    'tasks',
    'taskMemos',
    'kioskPurposes',
    'evidence',
    'counselFailures',
    'claimRules',
    'crmFailures',
    'packageBonus',
    'labels',
    'staffNotices',
    'vitalsNotes',
    'closure',
    'closureReasons',
    'holidayNames',
    'dateFormat',
    'weekdayNames',
    'dateRangeFormat',
    'compoundItemFormat',
  };

  /// The fields of [CoFakerSaasData] that [mapSaas] covers.
  static const Set<String> saasDataFields = <String>{
    'plans',
    'messageTemplates',
    'notices',
    'failureReasons',
    'labels',
    'ops',
    'currency',
    'priceScale',
    'koreanValues',
    'businessNumberFormat',
  };

  /// The fields of [CoFakerSaasOps] that [mapSaas] covers.
  static const Set<String> saasOpsFields = <String>{
    'operatorActions',
    'operatorRoles',
    'autopayFailures',
    'masterRows',
    'masterChecks',
    'incidentTitles',
    'alerts',
    'releaseItems',
    'regulationItems',
    'releaseTitle',
    'regulationTitle',
    'tenantActivities',
    'templateRejectReason',
    'labels',
    'senderLabels',
    'healthMessages',
    'auditTargets',
    'auditRecords',
    'masterCheckDetail',
  };

  /// The slots of [bundle]: one per key, one row per text.
  static CoTextTable ofBundle(CoL10nBundle bundle) {
    final table = CoTextTable();
    for (final entry in bundle.texts.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        table.visit((
          slot: entry.key,
          kind: CoTextKind.text,
          row: '$i',
          cell: 0,
          keyed: false,
        ), entry.value[i]);
      }
    }
    return table;
  }

  /// The slots of the clinic [data].
  ///
  /// With [resolveFallbacks] the texts and the operations texts that the data
  /// leaves out (`null`) are read from English, the way `faker.clinic` reads
  /// them; without it they leave no slot, which tells a language that has not
  /// written them yet.
  static CoTextTable ofClinic(
    CoFakerClinicData data, {
    bool resolveFallbacks = false,
  }) {
    final table = CoTextTable();
    mapClinic(data, table.visit, resolveFallbacks: resolveFallbacks);
    return table;
  }

  /// The slots of the SaaS [data]; see [ofClinic] for [resolveFallbacks].
  static CoTextTable ofSaas(
    CoFakerSaasData data, {
    bool resolveFallbacks = false,
  }) {
    final table = CoTextTable();
    mapSaas(data, table.visit, resolveFallbacks: resolveFallbacks);
    return table;
  }

  /// Returns a copy of the clinic [data] whose every string is the result of
  /// [visit]; everything else (currency, price scale, numbers) is copied as
  /// it is.
  ///
  /// A `null` texts or ops member stays `null`, or is read from English
  /// first when [resolveFallbacks] is set.
  static CoFakerClinicData mapClinic(
    CoFakerClinicData data,
    CoTextVisitor visit, {
    bool resolveFallbacks = false,
  }) {
    final w = _Walker(visit, 'clinic');
    final texts =
        data.texts ?? (resolveFallbacks ? CoFakerClinicTexts.english : null);
    final ops =
        data.ops ?? (resolveFallbacks ? CoFakerClinicOps.english : null);
    return CoFakerClinicData(
      specialties: <CoSpecialtySpec>[
        for (var i = 0; i < data.specialties.length; i++)
          (
            name: w.text('specialties.name', i, data.specialties[i].name),
            clinicSuffix: w.text(
              'specialties.clinicSuffix',
              i,
              data.specialties[i].clinicSuffix,
            ),
          ),
      ],
      clinicNamePrefixes: w.list('clinicNamePrefixes', data.clinicNamePrefixes),
      staffRoles: w.map('staffRoles', data.staffRoles),
      visitPurposes: <CoVisitPurposeSpec>[
        for (var i = 0; i < data.visitPurposes.length; i++)
          (
            name: w.text('visitPurposes.name', i, data.visitPurposes[i].name),
            details: w.cells('visitPurposes.details', i, [
              ...data.visitPurposes[i].details,
            ]),
          ),
      ],
      procedures: <CoProcedureSpec>[
        for (var i = 0; i < data.procedures.length; i++)
          (
            code: w.text(
              'procedures.code',
              i,
              data.procedures[i].code,
              kind: CoTextKind.code,
            ),
            category: w.text(
              'procedures.category',
              i,
              data.procedures[i].category,
            ),
            name: w.text('procedures.name', i, data.procedures[i].name),
            unit: w.text('procedures.unit', i, data.procedures[i].unit),
            minPrice: data.procedures[i].minPrice,
            maxPrice: data.procedures[i].maxPrice,
            taxable: data.procedures[i].taxable,
          ),
      ],
      diagnoses: <CoDiagnosisSpec>[
        for (var i = 0; i < data.diagnoses.length; i++)
          (
            code: w.text(
              'diagnoses.code',
              i,
              data.diagnoses[i].code,
              kind: CoTextKind.code,
            ),
            name: w.text('diagnoses.name', i, data.diagnoses[i].name),
            nameEn: w.text(
              'diagnoses.nameEn',
              i,
              data.diagnoses[i].nameEn,
              kind: CoTextKind.code,
            ),
          ),
      ],
      drugStems: w.list('drugStems', data.drugStems),
      drugForms: <({String form, String unit, List<int> strengths})>[
        for (var i = 0; i < data.drugForms.length; i++)
          (
            form: w.text('drugForms.form', i, data.drugForms[i].form),
            unit: w.text('drugForms.unit', i, data.drugForms[i].unit),
            strengths: data.drugForms[i].strengths,
          ),
      ],
      drugUsages: w.list('drugUsages', data.drugUsages),
      complaints: w.list('complaints', data.complaints),
      findings: w.list('findings', data.findings),
      plans: w.list('plans', data.plans),
      memos: w.list('memos', data.memos),
      questions: <CoQuestionSpec>[
        for (var i = 0; i < data.questions.length; i++)
          (
            question: w.text(
              'questions.question',
              i,
              data.questions[i].question,
            ),
            options: w.cells('questions.options', i, [
              ...data.questions[i].options,
            ]),
          ),
      ],
      cardIssuers: w.list('cardIssuers', data.cardIssuers),
      labels: w.map('labels', data.labels),
      packageNameFormat: w.one(
        'packageNameFormat',
        data.packageNameFormat,
        kind: CoTextKind.format,
      ),
      texts: texts == null ? null : _clinicTexts(w, texts),
      ops: ops == null ? null : _clinicOps(w, ops),
      clinicNameFormat: w.one(
        'clinicNameFormat',
        data.clinicNameFormat,
        kind: CoTextKind.format,
      ),
      currency: data.currency,
      priceScale: data.priceScale,
      koreanValues: data.koreanValues,
      maskedIdFormat: w.one(
        'maskedIdFormat',
        data.maskedIdFormat,
        kind: CoTextKind.format,
      ),
      addressLineFormat: w.one(
        'addressLineFormat',
        data.addressLineFormat,
        kind: CoTextKind.format,
      ),
    );
  }

  static CoFakerClinicTexts _clinicTexts(_Walker w, CoFakerClinicTexts d) {
    final t = w.under('texts');
    return CoFakerClinicTexts(
      consentForms: <CoConsentFormSpec>[
        for (var i = 0; i < d.consentForms.length; i++)
          (
            kind: t.text(
              'consentForms.kind',
              i,
              d.consentForms[i].kind,
              kind: CoTextKind.code,
            ),
            title: t.text('consentForms.title', i, d.consentForms[i].title),
            clauses: t.cells('consentForms.clauses', i, [
              ...d.consentForms[i].clauses,
            ]),
          ),
      ],
      consentDisclaimer: t.one('consentDisclaimer', d.consentDisclaimer),
      feedback: t.listMap('feedback', d.feedback),
      counselTopics: <CoCounselTopicSpec>[
        for (var i = 0; i < d.counselTopics.length; i++)
          (
            topic: t.text(
              'counselTopics.topic',
              i,
              d.counselTopics[i].topic,
              kind: CoTextKind.code,
            ),
            procedureCode: t.text(
              'counselTopics.procedureCode',
              i,
              d.counselTopics[i].procedureCode,
              kind: CoTextKind.code,
            ),
            procedure: t.text(
              'counselTopics.procedure',
              i,
              d.counselTopics[i].procedure,
            ),
            concern: t.text(
              'counselTopics.concern',
              i,
              d.counselTopics[i].concern,
            ),
            recommend: t.text(
              'counselTopics.recommend',
              i,
              d.counselTopics[i].recommend,
            ),
            pain: t.text('counselTopics.pain', i, d.counselTopics[i].pain),
            interval: t.text(
              'counselTopics.interval',
              i,
              d.counselTopics[i].interval,
            ),
            downtime: t.text(
              'counselTopics.downtime',
              i,
              d.counselTopics[i].downtime,
            ),
            sessions: d.counselTopics[i].sessions,
          ),
      ],
      counselScript: (
        greeting: t.one('counselScript.greeting', d.counselScript.greeting),
        questions: t.map('counselScript.questions', d.counselScript.questions),
        priceAnswer: t.one(
          'counselScript.priceAnswer',
          d.counselScript.priceAnswer,
        ),
        bookYes: t.one('counselScript.bookYes', d.counselScript.bookYes),
        bookYesReply: t.one(
          'counselScript.bookYesReply',
          d.counselScript.bookYesReply,
        ),
        bookNo: t.one('counselScript.bookNo', d.counselScript.bookNo),
        bookNoReply: t.one(
          'counselScript.bookNoReply',
          d.counselScript.bookNoReply,
        ),
        summary: t.one('counselScript.summary', d.counselScript.summary),
        booked: t.one('counselScript.booked', d.counselScript.booked),
        pending: t.one('counselScript.pending', d.counselScript.pending),
      ),
      integrationResults: <String, List<CoIntegrationResultSpec>>{
        for (final entry in d.integrationResults.entries)
          entry.key: <CoIntegrationResultSpec>[
            for (var j = 0; j < entry.value.length; j++)
              (
                code: t.keyed(
                  'integrationResults.code',
                  entry.key,
                  entry.value[j].code,
                  cell: j,
                  kind: CoTextKind.code,
                ),
                message: t.keyed(
                  'integrationResults.message',
                  entry.key,
                  entry.value[j].message,
                  cell: j,
                ),
                ok: entry.value[j].ok,
              ),
          ],
      },
      insurers: t.list('insurers', d.insurers),
      teamNotes: t.list('teamNotes', d.teamNotes),
      // A pattern: English writes a number sign before the field
      // (`{kind} #{number}`), which is not a notification variable.
      deviceNameFormat: t.one(
        'deviceNameFormat',
        d.deviceNameFormat,
        kind: CoTextKind.format,
      ),
      labels: t.map('labels', d.labels),
      staffMentionFormat: t.one('staffMentionFormat', d.staffMentionFormat),
      nameMentionFormat: t.one('nameMentionFormat', d.nameMentionFormat),
    );
  }

  static CoFakerClinicOps _clinicOps(_Walker w, CoFakerClinicOps d) {
    final o = w.under('ops');
    return CoFakerClinicOps(
      patientTags: o.coloredLabels('patientTags', d.patientTags),
      acquisitionChannels: o.coloredLabels(
        'acquisitionChannels',
        d.acquisitionChannels,
      ),
      specialNotes: o.list('specialNotes', d.specialNotes),
      rooms: <CoRoomSpec>[
        for (var i = 0; i < d.rooms.length; i++)
          (
            name: o.text('rooms.name', i, d.rooms[i].name),
            kind: o.text(
              'rooms.kind',
              i,
              d.rooms[i].kind,
              kind: CoTextKind.code,
            ),
            staffRole: d.rooms[i].staffRole == null
                ? null
                : o.text(
                    'rooms.staffRole',
                    i,
                    d.rooms[i].staffRole!,
                    kind: CoTextKind.code,
                  ),
          ),
      ],
      termsChanges: o.list('termsChanges', d.termsChanges),
      consentDispatch: o.map('consentDispatch', d.consentDispatch),
      adjustments: o.listMap('adjustments', d.adjustments),
      pointReasons: o.map('pointReasons', d.pointReasons),
      paymentMessages: o.map('paymentMessages', d.paymentMessages),
      tasks: o.list('tasks', d.tasks),
      taskMemos: o.list('taskMemos', d.taskMemos),
      kioskPurposes: o.map('kioskPurposes', d.kioskPurposes),
      evidence: <CoEvidenceSpec>[
        for (var i = 0; i < d.evidence.length; i++)
          (
            kind: o.text(
              'evidence.kind',
              i,
              d.evidence[i].kind,
              kind: CoTextKind.code,
            ),
            rule: o.text('evidence.rule', i, d.evidence[i].rule),
          ),
      ],
      counselFailures: o.map('counselFailures', d.counselFailures),
      claimRules: <CoClaimRuleSpec>[
        for (var i = 0; i < d.claimRules.length; i++)
          (
            ruleId: o.text(
              'claimRules.ruleId',
              i,
              d.claimRules[i].ruleId,
              kind: CoTextKind.code,
            ),
            severity: o.text(
              'claimRules.severity',
              i,
              d.claimRules[i].severity,
              kind: CoTextKind.code,
            ),
            diagnosisCode: o.text(
              'claimRules.diagnosisCode',
              i,
              d.claimRules[i].diagnosisCode,
              kind: CoTextKind.code,
            ),
            feeCode: o.text(
              'claimRules.feeCode',
              i,
              d.claimRules[i].feeCode,
              kind: CoTextKind.code,
            ),
            message: o.text('claimRules.message', i, d.claimRules[i].message),
          ),
      ],
      crmFailures: o.map('crmFailures', d.crmFailures),
      packageBonus: o.one('packageBonus', d.packageBonus),
      labels: o.map('labels', d.labels),
      staffNotices: <String, List<({String title, String body})>>{
        for (final entry in d.staffNotices.entries)
          entry.key: <({String title, String body})>[
            for (var j = 0; j < entry.value.length; j++)
              (
                title: o.keyed(
                  'staffNotices.title',
                  entry.key,
                  entry.value[j].title,
                  cell: j,
                ),
                body: o.keyed(
                  'staffNotices.body',
                  entry.key,
                  entry.value[j].body,
                  cell: j,
                ),
              ),
          ],
      },
      vitalsNotes: o.map('vitalsNotes', d.vitalsNotes),
      closure: o.map('closure', d.closure),
      closureReasons: o.list('closureReasons', d.closureReasons),
      holidayNames: o.map(
        'holidayNames',
        d.holidayNames,
        kind: CoTextKind.koreanOnly,
      ),
      dateFormat: o.one('dateFormat', d.dateFormat, kind: CoTextKind.format),
      weekdayNames: o.list('weekdayNames', d.weekdayNames),
      dateRangeFormat: o.one(
        'dateRangeFormat',
        d.dateRangeFormat,
        kind: CoTextKind.format,
      ),
      compoundItemFormat: o.one(
        'compoundItemFormat',
        d.compoundItemFormat,
        kind: CoTextKind.format,
      ),
    );
  }

  /// Returns a copy of the SaaS [data] whose every string is the result of
  /// [visit]; see [mapClinic].
  static CoFakerSaasData mapSaas(
    CoFakerSaasData data,
    CoTextVisitor visit, {
    bool resolveFallbacks = false,
  }) {
    final w = _Walker(visit, 'saas');
    final ops = data.ops ?? (resolveFallbacks ? CoFakerSaasOps.english : null);
    return CoFakerSaasData(
      plans: <CoPlanSpec>[
        for (var i = 0; i < data.plans.length; i++)
          (
            code: w.text(
              'plans.code',
              i,
              data.plans[i].code,
              kind: CoTextKind.code,
            ),
            name: w.text('plans.name', i, data.plans[i].name),
            monthlyPrice: data.plans[i].monthlyPrice,
            seats: data.plans[i].seats,
            messageCredits: data.plans[i].messageCredits,
          ),
      ],
      messageTemplates: <CoMessageTemplateSpec>[
        for (var i = 0; i < data.messageTemplates.length; i++)
          (
            code: w.text(
              'messageTemplates.code',
              i,
              data.messageTemplates[i].code,
              kind: CoTextKind.code,
            ),
            name: w.text(
              'messageTemplates.name',
              i,
              data.messageTemplates[i].name,
            ),
            body: w.text(
              'messageTemplates.body',
              i,
              data.messageTemplates[i].body,
            ),
          ),
      ],
      notices: <CoNoticeSpec>[
        for (var i = 0; i < data.notices.length; i++)
          (
            category: w.text(
              'notices.category',
              i,
              data.notices[i].category,
              kind: CoTextKind.code,
            ),
            title: w.text('notices.title', i, data.notices[i].title),
            body: w.text('notices.body', i, data.notices[i].body),
          ),
      ],
      failureReasons: w.map('failureReasons', data.failureReasons),
      labels: w.map('labels', data.labels),
      ops: ops == null ? null : _saasOps(w, ops),
      currency: data.currency,
      priceScale: data.priceScale,
      koreanValues: data.koreanValues,
      businessNumberFormat: w.one(
        'businessNumberFormat',
        data.businessNumberFormat,
        kind: CoTextKind.format,
      ),
    );
  }

  static CoFakerSaasOps _saasOps(_Walker w, CoFakerSaasOps d) {
    final o = w.under('ops');
    return CoFakerSaasOps(
      operatorActions: <String, CoOperatorActionSpec>{
        for (final entry in d.operatorActions.entries)
          entry.key: (
            label: o.keyed(
              'operatorActions.label',
              entry.key,
              entry.value.label,
            ),
            summary: o.keyed(
              'operatorActions.summary',
              entry.key,
              entry.value.summary,
            ),
          ),
      },
      operatorRoles: o.map('operatorRoles', d.operatorRoles),
      autopayFailures: o.map('autopayFailures', d.autopayFailures),
      masterRows: <String, List<CoMasterRowSpec>>{
        for (final entry in d.masterRows.entries)
          entry.key: <CoMasterRowSpec>[
            for (var j = 0; j < entry.value.length; j++)
              (
                name: o.keyed(
                  'masterRows.name',
                  entry.key,
                  entry.value[j].name,
                  cell: j,
                ),
                price: entry.value[j].price,
              ),
          ],
      },
      masterChecks: o.map('masterChecks', d.masterChecks),
      incidentTitles: o.map('incidentTitles', d.incidentTitles),
      alerts: <CoOpsAlertSpec>[
        for (var i = 0; i < d.alerts.length; i++)
          (
            level: o.text(
              'alerts.level',
              i,
              d.alerts[i].level,
              kind: CoTextKind.code,
            ),
            code: o.text(
              'alerts.code',
              i,
              d.alerts[i].code,
              kind: CoTextKind.code,
            ),
            message: o.text('alerts.message', i, d.alerts[i].message),
          ),
      ],
      releaseItems: o.list('releaseItems', d.releaseItems),
      regulationItems: o.list('regulationItems', d.regulationItems),
      releaseTitle: o.one('releaseTitle', d.releaseTitle),
      regulationTitle: o.one('regulationTitle', d.regulationTitle),
      tenantActivities: o.list('tenantActivities', d.tenantActivities),
      templateRejectReason: o.one(
        'templateRejectReason',
        d.templateRejectReason,
      ),
      labels: o.map('labels', d.labels),
      senderLabels: o.list('senderLabels', d.senderLabels),
      healthMessages: o.map('healthMessages', d.healthMessages),
      auditTargets: o.map('auditTargets', d.auditTargets),
      auditRecords: o.list('auditRecords', d.auditRecords),
      masterCheckDetail: o.one('masterCheckDetail', d.masterCheckDetail),
    );
  }
}

/// Names the strings of a data set under a path and hands them to a visitor.
class _Walker {
  _Walker(this._visit, this._path);

  final CoTextVisitor _visit;
  final String _path;

  /// A walker whose slots start with `<path>.<segment>`.
  _Walker under(String segment) => _Walker(_visit, '$_path.$segment');

  String _slot(String name) => '$_path.$name';

  /// The string [text] of the list slot [name], row [index].
  String text(
    String name,
    int index,
    String text, {
    CoTextKind kind = CoTextKind.text,
  }) => _visit((
    slot: _slot(name),
    kind: kind,
    row: '$index',
    cell: 0,
    keyed: false,
  ), text);

  /// A single string: a slot of one row.
  String one(String name, String text, {CoTextKind kind = CoTextKind.text}) =>
      this.text(name, 0, text, kind: kind);

  /// A list of strings: one row each.
  List<String> list(String name, List<String> values) => <String>[
    for (var i = 0; i < values.length; i++) text(name, i, values[i]),
  ];

  /// The strings of the row [index] of a slot whose rows hold lists.
  List<String> cells(String name, int index, List<String> values) => <String>[
    for (var j = 0; j < values.length; j++)
      _visit((
        slot: _slot(name),
        kind: CoTextKind.text,
        row: '$index',
        cell: j,
        keyed: false,
      ), values[j]),
  ];

  /// A string of the keyed slot [name], row [key], cell [cell].
  String keyed(
    String name,
    String key,
    String text, {
    int cell = 0,
    CoTextKind kind = CoTextKind.text,
  }) => _visit((
    slot: _slot(name),
    kind: kind,
    row: key,
    cell: cell,
    keyed: true,
  ), text);

  /// A map of strings: one row per key.
  Map<String, String> map(
    String name,
    Map<String, String> values, {
    CoTextKind kind = CoTextKind.text,
  }) => <String, String>{
    for (final entry in values.entries)
      entry.key: keyed(name, entry.key, entry.value, kind: kind),
  };

  /// A map of lists of strings: one row per key, one cell per string.
  Map<String, List<String>> listMap(
    String name,
    Map<String, List<String>> values,
  ) => <String, List<String>>{
    for (final entry in values.entries)
      entry.key: <String>[
        for (var j = 0; j < entry.value.length; j++)
          keyed(name, entry.key, entry.value[j], cell: j),
      ],
  };

  /// Labeled codes with a color: the code and the color stay as they are.
  List<CoColoredLabelSpec> coloredLabels(
    String name,
    List<CoColoredLabelSpec> values,
  ) => <CoColoredLabelSpec>[
    for (var i = 0; i < values.length; i++)
      (
        code: text('$name.code', i, values[i].code, kind: CoTextKind.code),
        label: text('$name.label', i, values[i].label),
        color: text('$name.color', i, values[i].color, kind: CoTextKind.code),
      ),
  ];
}
