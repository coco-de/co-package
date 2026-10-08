import 'package:co_faker/co_faker.dart';

/// A virtual language that shows how a language Story fills the clinic and
/// SaaS data slots with data alone.
///
/// The lists and most texts are English, so a test can tell the data apart
/// from the Korean and English built-ins by the fields that make a language:
/// the currency format, the price scale, the Korean-only values, the clinic
/// name order, and the texts that the generators assemble.
class VirtualLanguage {
  /// Creates a virtual language.
  const VirtualLanguage({
    required this.locale,
    required this.currency,
    required this.scale,
    required this.saasScale,
    this.priceFactor = 1,
    this.clinicNameFormat = '{prefix}{suffix}',
    this.maskedIdFormat = '########',
    this.businessNumberFormat = '#############',
    this.dateFormat = '{month}月{day}日({weekday})',
    this.weekdayNames = const <String>['月', '火', '水', '木', '金', '土', '日'],
    this.compoundItemFormat = '{name} {sessions}回',
    this.staffMentionFormat = '@{name} {role}さん',
    this.nameMentionFormat = '@{name}さん',
    this.senderLabels = const <String>['代表番号', '予約専用'],
    this.healthMessages = const <String, String>{
      'degraded': '応答遅延',
      'down': '接続タイムアウト',
    },
    this.auditTargets = const <String, String>{
      'login': 'アカウント',
      'loginFailed': 'アカウント',
      'roleChange': 'スタッフ権限',
      'send': '通知',
    },
    this.auditRecords = const <String>['患者', 'カルテ'],
    this.values = CoKoreanValues.none,
  });

  /// The national locale the language is built on, such as `ja_jp`.
  final String locale;

  /// The currency format of the data.
  final CoCurrencyFormat currency;

  /// The clinic price scale of the data.
  final CoClinicPriceScale scale;

  /// The SaaS price scale of the data.
  final CoSaasPriceScale saasScale;

  /// How many times larger than the English dollar prices the procedure
  /// prices of the data are.
  final int priceFactor;

  /// See [CoFakerClinicData.clinicNameFormat].
  final String clinicNameFormat;

  /// See [CoFakerClinicData.maskedIdFormat].
  final String maskedIdFormat;

  /// See [CoFakerSaasData.businessNumberFormat].
  final String businessNumberFormat;

  /// See [CoFakerClinicOps.dateFormat].
  final String dateFormat;

  /// See [CoFakerClinicOps.weekdayNames].
  final List<String> weekdayNames;

  /// See [CoFakerClinicOps.compoundItemFormat].
  final String compoundItemFormat;

  /// See [CoFakerClinicTexts.staffMentionFormat].
  final String staffMentionFormat;

  /// See [CoFakerClinicTexts.nameMentionFormat].
  final String nameMentionFormat;

  /// See [CoFakerSaasOps.senderLabels].
  final List<String> senderLabels;

  /// See [CoFakerSaasOps.healthMessages].
  final Map<String, String> healthMessages;

  /// See [CoFakerSaasOps.auditTargets].
  final Map<String, String> auditTargets;

  /// See [CoFakerSaasOps.auditRecords].
  final List<String> auditRecords;

  /// Which Korean-only values the data generates.
  final CoKoreanValues values;

  /// Clinic data of the language: English lists and texts, the fields of the
  /// language.
  CoFakerClinicData get clinic {
    const base = CoFakerClinicData.english;
    const ops = CoFakerClinicOps.english;
    const texts = CoFakerClinicTexts.english;
    return CoFakerClinicData(
      specialties: base.specialties,
      clinicNamePrefixes: base.clinicNamePrefixes,
      staffRoles: base.staffRoles,
      visitPurposes: base.visitPurposes,
      procedures: <CoProcedureSpec>[
        for (final spec in base.procedures)
          (
            code: spec.code,
            category: spec.category,
            name: spec.name,
            unit: spec.unit,
            minPrice: spec.minPrice * priceFactor,
            maxPrice: spec.maxPrice * priceFactor,
            taxable: spec.taxable,
          ),
      ],
      diagnoses: base.diagnoses,
      drugStems: base.drugStems,
      drugForms: base.drugForms,
      drugUsages: base.drugUsages,
      complaints: base.complaints,
      findings: base.findings,
      plans: base.plans,
      memos: base.memos,
      questions: base.questions,
      cardIssuers: base.cardIssuers,
      labels: base.labels,
      packageNameFormat: base.packageNameFormat,
      texts: CoFakerClinicTexts(
        consentForms: texts.consentForms,
        consentDisclaimer: texts.consentDisclaimer,
        feedback: texts.feedback,
        counselTopics: texts.counselTopics,
        counselScript: texts.counselScript,
        integrationResults: texts.integrationResults,
        insurers: texts.insurers,
        teamNotes: texts.teamNotes,
        deviceNameFormat: texts.deviceNameFormat,
        labels: texts.labels,
        staffMentionFormat: staffMentionFormat,
        nameMentionFormat: nameMentionFormat,
      ),
      ops: CoFakerClinicOps(
        patientTags: ops.patientTags,
        acquisitionChannels: ops.acquisitionChannels,
        specialNotes: ops.specialNotes,
        rooms: ops.rooms,
        termsChanges: ops.termsChanges,
        consentDispatch: ops.consentDispatch,
        adjustments: ops.adjustments,
        pointReasons: ops.pointReasons,
        paymentMessages: ops.paymentMessages,
        tasks: ops.tasks,
        taskMemos: ops.taskMemos,
        kioskPurposes: ops.kioskPurposes,
        evidence: ops.evidence,
        counselFailures: ops.counselFailures,
        claimRules: ops.claimRules,
        crmFailures: ops.crmFailures,
        packageBonus: ops.packageBonus,
        labels: ops.labels,
        staffNotices: ops.staffNotices,
        vitalsNotes: ops.vitalsNotes,
        closure: ops.closure,
        closureReasons: ops.closureReasons,
        holidayNames: ops.holidayNames,
        dateFormat: dateFormat,
        weekdayNames: weekdayNames,
        compoundItemFormat: compoundItemFormat,
      ),
      clinicNameFormat: clinicNameFormat,
      currency: currency,
      priceScale: scale,
      koreanValues: values,
      maskedIdFormat: maskedIdFormat,
    );
  }

  /// SaaS data of the language: English lists and texts, the fields of the
  /// language.
  CoFakerSaasData get saas {
    const base = CoFakerSaasData.english;
    const ops = CoFakerSaasOps.english;
    return CoFakerSaasData(
      plans: base.plans,
      messageTemplates: base.messageTemplates,
      notices: base.notices,
      failureReasons: base.failureReasons,
      labels: base.labels,
      ops: CoFakerSaasOps(
        operatorActions: ops.operatorActions,
        operatorRoles: ops.operatorRoles,
        autopayFailures: ops.autopayFailures,
        masterRows: ops.masterRows,
        masterChecks: ops.masterChecks,
        incidentTitles: ops.incidentTitles,
        alerts: ops.alerts,
        releaseItems: ops.releaseItems,
        regulationItems: ops.regulationItems,
        releaseTitle: ops.releaseTitle,
        regulationTitle: ops.regulationTitle,
        tenantActivities: ops.tenantActivities,
        templateRejectReason: ops.templateRejectReason,
        labels: ops.labels,
        senderLabels: senderLabels,
        healthMessages: healthMessages,
        auditTargets: auditTargets,
        auditRecords: auditRecords,
      ),
      currency: currency,
      priceScale: saasScale,
      koreanValues: values,
      businessNumberFormat: businessNumberFormat,
    );
  }

  /// A custom locale that carries this data on top of the built-in national
  /// locale [locale], so that addresses and phone numbers are national.
  CoFakerLocale get customLocale => CoFakerLocale(
    code: locale,
    clinic: clinic,
    saas: saas,
  ).merge(CoFakerLocales.resolve(locale));

  /// A generator whose clinic and SaaS data is this language's.
  CoFaker faker({int seed = 7, DateTime? now}) => CoFaker(
    locale: locale,
    seed: seed,
    now: now ?? DateTime.utc(2026, 10, 5, 9),
    locales: <String, CoFakerLocale>{locale: customLocale},
  );
}

/// Japanese yen, no minor units, a 10% consumption tax.
const VirtualLanguage virtualJapanese = VirtualLanguage(
  locale: 'ja_jp',
  priceFactor: 100,
  currency: CoCurrencyFormat(code: 'JPY', symbol: '¥'),
  scale: CoClinicPriceScale(
    priceRounding: 500,
    packageRounding: 1000,
    prepaidStep: 1000,
    installmentMinimum: 50000,
    splitMinimum: 5000,
    splitRounding: 100,
    adjustmentUnit: 100,
    pointUnit: 10,
    quoteMin: 5000,
    quoteMax: 30000,
  ),
  saasScale: CoSaasPriceScale(
    prepaidTopUps: <int>[10000, 30000, 50000, 100000],
    prepaidBonusTiers: <(int, int)>[(10000, 10), (50000, 20)],
    prepaidLowBalance: 5000,
    prepaidUsageMin: 1000,
    prepaidUsageRounding: 100,
    prepaidRefundMin: 100,
    prepaidRefundRounding: 100,
  ),
);

/// Euro with two decimals, a 19% VAT, written `1.234,00 €`.
const VirtualLanguage virtualGerman = VirtualLanguage(
  locale: 'de_de',
  currency: CoCurrencyFormat(
    code: 'EUR',
    symbol: '€',
    pattern: '{amount} {symbol}',
    groupSeparator: '.',
    decimalSeparator: ',',
    fractionDigits: 2,
  ),
  scale: CoClinicPriceScale(
    priceRounding: 5,
    packageRounding: 10,
    prepaidStep: 10,
    installmentMinimum: 400,
    splitMinimum: 40,
  ),
  saasScale: CoSaasPriceScale(
    vatRate: 0.19,
    prepaidTopUps: <int>[100, 250, 500, 1000],
    prepaidBonusTiers: <(int, int)>[(250, 5), (1000, 10)],
    prepaidLowBalance: 100,
    prepaidUsageMin: 10,
    prepaidUsageRounding: 5,
    prepaidRefundMin: 5,
    prepaidRefundRounding: 5,
  ),
  clinicNameFormat: '{suffix} {prefix}',
  maskedIdFormat: '##.##.##',
  businessNumberFormat: 'DE#########',
  dateFormat: '{day}.{month}.',
  weekdayNames: <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  compoundItemFormat: '{sessions}x {name}',
  staffMentionFormat: '@{name} ({role})',
  nameMentionFormat: '@{name}',
  senderLabels: <String>['Zentrale', 'Terminvergabe'],
  healthMessages: <String, String>{
    'degraded': 'Verzögerte Antworten',
    'down': 'Zeitüberschreitung',
  },
  auditTargets: <String, String>{
    'login': 'Konto',
    'loginFailed': 'Konto',
    'roleChange': 'Mitarbeiterrolle',
    'send': 'Benachrichtigung',
  },
  auditRecords: <String>['Patient', 'Akte'],
);
