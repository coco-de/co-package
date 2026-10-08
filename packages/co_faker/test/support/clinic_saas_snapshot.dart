import 'package:co_faker/co_faker.dart';

/// Seeds every recorded generator runs with.
const List<int> clinicSaasSeeds = <int>[7, 20261005, 436];

/// Locale codes recorded for every seed, with a readable sample per call.
const List<String> clinicSaasFullLocales = <String>['ko', 'en'];

/// Locale codes recorded for one seed, as digests only.
///
/// They have no clinic or SaaS data of their own (or are English or Korean
/// by another code), so their output must keep following the data of the
/// language they fall back to.
const List<String> clinicSaasFallbackLocales = <String>[
  'ko_KR',
  'en_US',
  'en_GB',
  'ja',
  'ja_JP',
  'zh',
  'zh_CN',
  'zh_TW',
  'de_DE',
  'fr_FR',
  'ru_RU',
  'it_IT',
  'pt_BR',
  'es',
  'xx_YY',
];

/// The seed of the digest-only locale codes.
const int clinicSaasFallbackSeed = 20261005;

/// How many times each call runs on one generator, so a change in how much
/// of the random stream a call consumes shows up in the later runs.
const int clinicSaasRepeats = 3;

/// The clock every recorded generator uses.
final DateTime clinicSaasNow = DateTime.utc(2026, 10, 5, 9);

/// One public-API call of `faker.clinic` or `faker.saas`.
typedef ClinicSaasCall = Object? Function(CoFaker faker);

CoFaker _faker(String locale, int seed) => CoFaker(
  locale: locale,
  seed: seed,
  now: clinicSaasNow,
  domains: CoFakerDomains.all,
);

/// Runs every call of [clinicCalls] and [saasCalls] on a fresh generator of
/// [locale] and [seed], [clinicSaasRepeats] times each, and returns the
/// output text of every call keyed by its name.
///
/// Only the public generators are called, with arguments that exist in every
/// release since 0.11.0, so the same table can be recorded by one version and
/// replayed by another. Each call gets its own generator: a change in one
/// call never shifts the values of the next.
Map<String, String> recordClinicSaas(String locale, int seed) {
  final output = <String, String>{};
  for (final entry in <String, ClinicSaasCall>{
    ...clinicCalls,
    ...saasCalls,
  }.entries) {
    final faker = _faker(locale, seed);
    final buffer = StringBuffer();
    for (var run = 0; run < clinicSaasRepeats; run++) {
      if (run > 0) buffer.write('\n');
      buffer.write(entry.value(faker));
    }
    output[entry.key] = buffer.toString();
  }
  return output;
}

/// A 64-bit fingerprint of [text] as 16 hex digits: two FNV-1a runs over the
/// UTF-16 code units, one forward and one backward, in 32-bit arithmetic.
String clinicSaasDigest(String text) {
  const prime = 0x01000193;
  var forward = 0x811c9dc5;
  var backward = 0x2545f491;
  final units = text.codeUnits;
  for (var i = 0; i < units.length; i++) {
    forward = _mul32(forward ^ units[i], prime);
    backward = _mul32(backward ^ units[units.length - 1 - i], prime);
  }
  return '${_hex(forward)}${_hex(backward)}';
}

int _mul32(int a, int b) {
  final low = (a & 0xffff) * b;
  final high = (((a >> 16) & 0xffff) * b) & 0xffff;
  return (low + (high << 16)) & 0xffffffff;
}

String _hex(int value) => value.toRadixString(16).padLeft(8, '0');

/// The first [length] characters of [text] on one line, for a readable
/// sample in the fixture.
String clinicSaasSample(String text, {int length = 160}) {
  final first = text.split('\n').first;
  return first.length <= length ? first : '${first.substring(0, length)}...';
}

const List<int> _amounts = <int>[20, 400, 800, 30000, 120000, 600000, 2400000];

final List<DateTime> _closureDates = <DateTime>[
  DateTime.utc(2026, 9, 25), // Chuseok
  DateTime.utc(2027, 2, 6), // Seollal
  DateTime.utc(2026, 5, 5), // Children's Day
  DateTime.utc(2026, 10, 9), // Hangeul Day
  DateTime.utc(2026, 10, 5), // substitute holiday
  DateTime.utc(2026, 1, 1), // New Year
  DateTime.utc(2026, 11, 11), // an ordinary Wednesday
  DateTime.utc(2026, 11, 14), // an ordinary Saturday
  DateTime.utc(2035, 3, 1), // outside the holiday table
];

const List<CoFakeVitals> _vitals = [
  (
    temperature: 36.6,
    systolic: 118,
    diastolic: 76,
    pulse: 72,
    spo2: 98,
    glucose: 96,
    heightCm: 165.0,
    weightKg: 58.0,
    bmi: 21.3,
  ),
  (
    temperature: 36.6,
    systolic: 152,
    diastolic: 96,
    pulse: 72,
    spo2: 98,
    glucose: 96,
    heightCm: 165.0,
    weightKg: 58.0,
    bmi: 21.3,
  ),
  (
    temperature: 38.1,
    systolic: 118,
    diastolic: 76,
    pulse: 72,
    spo2: 98,
    glucose: 96,
    heightCm: 165.0,
    weightKg: 58.0,
    bmi: 21.3,
  ),
  (
    temperature: 36.6,
    systolic: 118,
    diastolic: 76,
    pulse: 72,
    spo2: 92,
    glucose: 96,
    heightCm: 165.0,
    weightKg: 58.0,
    bmi: 21.3,
  ),
  (
    temperature: 36.6,
    systolic: 118,
    diastolic: 76,
    pulse: 72,
    spo2: 98,
    glucose: 180,
    heightCm: 165.0,
    weightKg: 58.0,
    bmi: 21.3,
  ),
];

/// Every public member of `CoFakerClinic`, with default and representative
/// arguments. Loops cover the weighted branches a single call may miss.
final Map<String, ClinicSaasCall> clinicCalls = <String, ClinicSaasCall>{
  'clinic.label': (f) => [
    for (final code in const <String>[
      'nhis',
      'medicalAid1',
      'uninsured',
      'noShow',
      'prepaid',
      'spouse',
      'picoLaser',
      'positive',
      'inProgress',
      'does-not-exist',
    ])
      f.clinic.label(code),
  ],
  'clinic.specialty': (f) => f.clinic.specialty(),
  'clinic.clinicName': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.clinicName(),
  ],
  'clinic.clinicName.specialty': (f) => [
    for (final spec in f.clinic.data.specialties)
      f.clinic.clinicName(specialty: spec.name),
    f.clinic.clinicName(specialty: 'no such specialty'),
  ],
  'clinic.staffRoles': (f) => f.clinic.staffRoles,
  'clinic.staffRole': (f) => [for (var i = 0; i < 4; i++) f.clinic.staffRole()],
  'clinic.staff': (f) => [for (var i = 0; i < 3; i++) f.clinic.staff()],
  'clinic.staff.role': (f) => [
    f.clinic.staff(role: 'counselor', domain: 'example.test'),
    f.clinic.staff(role: 'unknown-role'),
  ],
  'clinic.patient': (f) => [for (var i = 0; i < 6; i++) f.clinic.patient()],
  'clinic.patient.options': (f) => [
    f.clinic.patient(sex: CoSex.male, minAge: 30, maxAge: 40, emailRatio: 1),
    f.clinic.patient(sex: CoSex.female, minAge: 8, maxAge: 8, emailRatio: 0),
    f.clinic.patient(
      chartNumber: 123,
      chartNumberFormat: CoChartNumberFormat.yearly,
    ),
    f.clinic.patient(
      chartNumber: 45,
      chartNumberFormat: CoChartNumberFormat.padded,
    ),
  ],
  'clinic.chartNumber': (f) => [
    for (final format in CoChartNumberFormat.values)
      f.clinic.chartNumber(123, format: format),
  ],
  'clinic.insuranceType': (f) => [
    for (var i = 0; i < 12; i++) f.clinic.insuranceType(),
  ],
  'clinic.visitPurpose': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.visitPurpose(),
  ],
  'clinic.visitPurposeTree': (f) => f.clinic.visitPurposeTree(),
  'clinic.procedures': (f) => [
    for (final spec in f.clinic.procedures) spec.code,
  ],
  'clinic.procedure': (f) => [for (var i = 0; i < 8; i++) f.clinic.procedure()],
  'clinic.procedure.code': (f) => [
    for (final spec in f.clinic.procedures.take(6))
      f.clinic.procedure(code: spec.code),
  ],
  'clinic.procedure.category': (f) => [
    f.clinic.procedure(category: f.clinic.procedures.first.category),
    f.clinic.procedure(category: f.clinic.procedures.last.category),
  ],
  'clinic.package': (f) => [for (var i = 0; i < 6; i++) f.clinic.package()],
  'clinic.package.code': (f) => [
    for (final spec in f.clinic.procedures.take(4))
      f.clinic.package(procedureCode: spec.code),
  ],
  'clinic.packageBalance': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.packageBalance(),
  ],
  'clinic.prepaidBalance': (f) => [
    for (var i = 0; i < 6; i++) f.clinic.prepaidBalance(),
  ],
  'clinic.diagnosis': (f) => [for (var i = 0; i < 4; i++) f.clinic.diagnosis()],
  'clinic.drugName': (f) => [for (var i = 0; i < 4; i++) f.clinic.drugName()],
  'clinic.prescription': (f) => [
    for (var i = 0; i < 3; i++) f.clinic.prescription(),
  ],
  'clinic.chartMemo': (f) => [for (var i = 0; i < 3; i++) f.clinic.chartMemo()],
  'clinic.soap': (f) => [
    f.clinic.soap(),
    f.clinic.soap(diagnosis: f.clinic.data.diagnoses.first),
  ],
  'clinic.questionnaire': (f) => [
    f.clinic.questionnaire(),
    f.clinic.questionnaire(count: 3),
    f.clinic.questionnaire(count: 99),
  ],
  'clinic.businessSlots': (f) => [
    f.clinic.businessSlots(DateTime.utc(2026, 10, 1)),
    f.clinic.businessSlots(DateTime.utc(2026, 10, 3)),
    f.clinic.businessSlots(DateTime.utc(2026, 10, 4)),
    f.clinic.businessSlots(
      DateTime.utc(2026, 10, 1),
      hours: const CoClinicHours(interval: 60, lunchStart: null),
    ),
    f.clinic.businessSlots(
      DateTime.utc(2026, 10, 3),
      hours: const CoClinicHours(open: 480, close: 1080, saturdayClose: null),
    ),
  ],
  'clinic.appointmentSlot': (f) => [
    for (var i = 0; i < 6; i++) f.clinic.appointmentSlot(),
    f.clinic.appointmentSlot(days: -30),
    f.clinic.appointmentSlot(
      days: 7,
      hours: const CoClinicHours(open: 540, close: 1020, interval: 20),
    ),
  ],
  'clinic.visitStages': (f) => CoFakerClinic.visitStages,
  'clinic.visitFlow': (f) => [for (var i = 0; i < 5; i++) f.clinic.visitFlow()],
  'clinic.visitStage': (f) => [
    for (var i = 0; i < 8; i++) f.clinic.visitStage(),
  ],
  'clinic.reservationStatus': (f) => [
    for (var i = 0; i < 6; i++)
      f.clinic.reservationStatus(
        at: clinicSaasNow.add(const Duration(days: 2)),
      ),
    for (var i = 0; i < 6; i++)
      f.clinic.reservationStatus(
        at: clinicSaasNow.subtract(const Duration(days: 2)),
      ),
    f.clinic.reservationStatus(),
  ],
  'clinic.payment': (f) => [
    for (final amount in _amounts) f.clinic.payment(amount: amount),
  ],
  'clinic.payment.method': (f) => [
    for (final method in const <String>['card', 'cash', 'transfer', 'prepaid'])
      for (final amount in const <int>[400, 600000])
        f.clinic.payment(amount: amount, method: method),
  ],
  'clinic.splitPayment': (f) => [
    for (final amount in _amounts) f.clinic.splitPayment(amount: amount),
    for (var i = 0; i < 12; i++) f.clinic.splitPayment(amount: 480000),
    for (var i = 0; i < 12; i++) f.clinic.splitPayment(amount: 480),
  ],
  'clinic.consentKinds': (f) => f.clinic.consentKinds,
  'clinic.consentForm': (f) => [
    f.clinic.consentForm(),
    for (final kind in f.clinic.consentKinds) f.clinic.consentForm(kind: kind),
  ],
  'clinic.feedback': (f) => [
    f.clinic.feedback(),
    for (final sentiment in const <String>['positive', 'neutral', 'negative'])
      f.clinic.feedback(sentiment: sentiment),
  ],
  'clinic.counselTopics': (f) => f.clinic.counselTopics,
  'clinic.counselSession': (f) => [
    f.clinic.counselSession(),
    f.clinic.counselSession(),
    for (final topic in f.clinic.counselTopics)
      f.clinic.counselSession(topic: topic),
  ],
  'clinic.inquiryLanguages': (f) => CoFakerClinic.inquiryLanguages,
  'clinic.inquiry': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.inquiry(),
    for (final language in CoFakerClinic.inquiryLanguages)
      f.clinic.inquiry(language: language, exchanges: 3),
  ],
  'clinic.messengerHandle': (f) => [
    f.clinic.messengerHandle(),
    for (final channel in const <String>[
      'kakao',
      'line',
      'wechat',
      'whatsapp',
      'zalo',
      'instagram',
    ])
      for (final language in CoFakerClinic.inquiryLanguages)
        f.clinic.messengerHandle(channel: channel, language: language),
  ],
  'clinic.insurerName': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.insurerName(),
  ],
  'clinic.integrationServices': (f) => f.clinic.integrationServices,
  'clinic.integrationResult': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.integrationResult(),
    for (final service in f.clinic.integrationServices)
      for (var i = 0; i < 4; i++) f.clinic.integrationResult(service: service),
  ],
  'clinic.deviceKinds': (f) => CoFakerClinic.deviceKinds,
  'clinic.device': (f) => [
    f.clinic.device(),
    for (final kind in CoFakerClinic.deviceKinds)
      f.clinic.device(kind: kind, number: 2),
  ],
  'clinic.teamNote': (f) => [
    for (var i = 0; i < 6; i++) f.clinic.teamNote(),
    for (var i = 0; i < 4; i++)
      f.clinic.teamNote(
        patient: 'Pat Example',
        authors: const <String>['Ann Author', 'Ben Writer'],
        mentions: const <String>['Ann Author', 'Cam Mention'],
      ),
    f.clinic.teamNote(mentions: const <String>['Solo Name']),
  ],
  'clinic.staffNotice': (f) => [
    f.clinic.staffNotice(),
    for (final kind in const <String>['training', 'policy', 'schedule'])
      f.clinic.staffNotice(kind: kind),
  ],
  'clinic.vitalsNote': (f) => [
    for (final vitals in _vitals) f.clinic.vitalsNote(vitals: vitals),
    f.clinic.vitalsNote(),
  ],
  'clinic.closureNotice': (f) => [
    for (final date in _closureDates) f.clinic.closureNotice(date: date),
    for (final date in _closureDates.take(3))
      f.clinic.closureNotice(date: date, clinicName: 'Example Clinic'),
  ],
  'clinic.relations': (f) => CoFakerClinic.relations,
  'clinic.familyRelation': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.familyRelation(),
  ],
  'clinic.guardian': (f) => [
    f.clinic.guardian(),
    f.clinic.guardian(patientAge: 10),
    f.clinic.guardian(patientAge: 80),
  ],
  'clinic.patientTag': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.patientTag(),
  ],
  'clinic.patientTags': (f) => [
    f.clinic.patientTags(),
    f.clinic.patientTags(max: 5),
    f.clinic.patientTags(max: 0),
  ],
  'clinic.acquisitionChannel': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.acquisitionChannel(),
  ],
  'clinic.specialNote': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.specialNote(),
  ],
  'clinic.maskName': (f) => [
    for (final name in const <String>[
      'A',
      'Ab',
      'Abc',
      'Abcdef',
      '김하늘',
      '남궁민수',
      '佐藤花子',
    ])
      CoFakerClinic.maskName(name),
  ],
  'clinic.maskedName': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.maskedName(),
  ],
  'clinic.consentHistoryKinds': (f) => CoFakerClinic.consentHistoryKinds,
  'clinic.termsVersion': (f) => [
    f.clinic.termsVersion(),
    f.clinic.termsVersion(monthsAgo: 5),
  ],
  'clinic.consentHistory': (f) => [
    f.clinic.consentHistory(),
    f.clinic.consentHistory(count: 8),
    f.clinic.consentHistory(count: 1),
  ],
  'clinic.consentDispatch': (f) => [
    f.clinic.consentDispatch(),
    for (final status in const <String>[
      'sent',
      'opened',
      'signed',
      'expired',
      'failed',
    ])
      f.clinic.consentDispatch(status: status),
  ],
  'clinic.palette': (f) => CoFakerClinic.palette,
  'clinic.color': (f) => [
    f.clinic.color(),
    f.clinic.color(index: 3),
    f.clinic.color(index: 27),
  ],
  'clinic.rooms': (f) => [
    f.clinic.rooms(),
    f.clinic.rooms(includeReception: false),
  ],
  'clinic.queueStatuses': (f) => CoFakerClinic.queueStatuses,
  'clinic.queueBoard': (f) => [
    f.clinic.queueBoard(),
    f.clinic.queueBoard(count: 3),
    f.clinic.queueBoard(rooms: f.clinic.rooms().take(2).toList(), count: 2),
  ],
  'clinic.receptionSource': (f) => [
    for (var i = 0; i < 6; i++) f.clinic.receptionSource(),
  ],
  'clinic.kioskPurpose': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.kioskPurpose(),
  ],
  'clinic.vitals': (f) => [
    f.clinic.vitals(),
    f.clinic.vitals(age: 8),
    f.clinic.vitals(age: 70, sex: CoSex.female),
    f.clinic.vitals(age: 30, sex: CoSex.male),
  ],
  'clinic.faceRegions': (f) => CoFakerClinic.faceRegions,
  'clinic.faceFrontRegions': (f) => CoFakerClinic.faceFrontRegions,
  'clinic.canvasMarks': (f) => [
    f.clinic.canvasMarks(),
    f.clinic.canvasMarks(template: 'faceFront'),
    f.clinic.canvasMarks(regions: const <String>['forehead', 'chin']),
    f.clinic.canvasMarks(
      regionRects: const <String, CoRegionRect>{
        'zone': (left: 0.2, top: 0.2, right: 0.6, bottom: 0.5),
      },
      regions: const <String>['zone'],
    ),
  ],
  'clinic.adjustment': (f) => [
    for (final kind in const <String>[
      'discount',
      'coupon',
      'point',
      'rounding',
    ])
      for (final subtotal in const <int>[120, 2750, 123456, 480000])
        f.clinic.adjustment(subtotal: subtotal, kind: kind),
    for (var i = 0; i < 10; i++) f.clinic.adjustment(subtotal: 350000),
  ],
  'clinic.cardDecline': (f) => [
    for (var i = 0; i < 6; i++) f.clinic.cardDecline(),
  ],
  'clinic.paymentMessage': (f) => [
    for (final code in const <String>[
      'approved',
      'cashReceipt',
      'partialCancel',
      'prepaidUsed',
      'declined',
    ])
      f.clinic.paymentMessage(code: code),
  ],
  'clinic.pointTransaction': (f) => [
    for (var i = 0; i < 10; i++) f.clinic.pointTransaction(),
    for (final reason in const <String>[
      'earn',
      'use',
      'bonus',
      'expire',
      'refund',
      'adjust',
    ])
      f.clinic.pointTransaction(reason: reason),
  ],
  'clinic.compoundPackageName': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.compoundPackageName(),
  ],
  'clinic.visitHeatmap': (f) => [
    f.clinic.visitHeatmap(),
    f.clinic.visitHeatmap(base: 12),
    f.clinic.visitHeatmap(
      hours: const CoClinicHours(open: 480, close: 1080, lunchStart: null),
    ),
  ],
  'clinic.task': (f) => [for (var i = 0; i < 4; i++) f.clinic.task()],
  'clinic.counselEvidence': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.counselEvidence(),
  ],
  'clinic.counselFailure': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.counselFailure(),
  ],
  'clinic.claimIssue': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.claimIssue(),
  ],
  'clinic.crmSendFailure': (f) => [
    for (var i = 0; i < 4; i++) f.clinic.crmSendFailure(),
  ],
};

/// Every public member of `CoFakerSaas`, with default and representative
/// arguments. Loops cover the weighted branches a single call may miss.
final Map<String, ClinicSaasCall> saasCalls = <String, ClinicSaasCall>{
  'saas.label': (f) => [
    for (final code in const <String>[
      'pastDue',
      'revealRrn',
      'fallbackSent',
      'topUp',
      'virtualAccount',
      'failed',
      'regulation',
      'does-not-exist',
    ])
      f.saas.label(code),
  ],
  'saas.tenant': (f) => [for (var i = 0; i < 6; i++) f.saas.tenant()],
  'saas.plan': (f) => [for (var i = 0; i < 4; i++) f.saas.plan()],
  'saas.subscriptionStatus': (f) => [
    for (var i = 0; i < 10; i++) f.saas.subscriptionStatus(),
  ],
  'saas.subscription': (f) => [
    f.saas.subscription(),
    f.saas.subscription(planCode: 'pro', status: 'trialing'),
    f.saas.subscription(planCode: 'starter', status: 'cancelled'),
  ],
  'saas.invoice': (f) => [
    for (var months = 0; months < 8; months++)
      f.saas.invoice(monthsAgo: months),
    f.saas.invoice(supplyAmount: 99999),
    f.saas.invoice(supplyAmount: 15),
    f.saas.invoice(status: 'failed'),
    f.saas.invoice(
      numberFormat: CoInvoiceNumberFormat.monthly,
      sequence: 12,
      statusWeights: const <String, int>{
        'paid': 80,
        'failed': 15,
        'overdue': 5,
      },
    ),
  ],
  'saas.invoices': (f) => [
    f.saas.invoices(4),
    f.saas.invoices(
      6,
      supplyAmount: 120000,
      numberFormat: CoInvoiceNumberFormat.compact,
      firstSequence: 40,
      statusWeights: const <String, int>{'paid': 60, 'failed': 40},
    ),
  ],
  'saas.autopayFailureCodes': (f) => f.saas.autopayFailureCodes,
  'saas.autopayFailure': (f) => [
    for (var i = 0; i < 8; i++) f.saas.autopayFailure(),
  ],
  'saas.prepaidBonusTiers': (f) => CoFakerSaas.prepaidBonusTiers,
  'saas.prepaidBonus': (f) => [
    for (final amount in const <int>[
      99999,
      100000,
      300000,
      1000000,
      15000000,
      40000000,
    ])
      CoFakerSaas.prepaidBonus(amount),
  ],
  'saas.prepaidLedger': (f) => [
    f.saas.prepaidLedger(),
    f.saas.prepaidLedger(count: 30, openingBalance: 700000),
    f.saas.prepaidLedger(count: 12, openingBalance: 40),
  ],
  'saas.operatorRoles': (f) => f.saas.operatorRoles,
  'saas.operator': (f) => [
    for (var i = 0; i < 5; i++) f.saas.operator(),
    for (final role in f.saas.operatorRoles) f.saas.operator(role: role),
  ],
  'saas.operatorActions': (f) => f.saas.operatorActions,
  'saas.operatorEvent': (f) => [
    f.saas.operatorEvent(),
    f.saas.operatorEvent(days: 7),
    for (final action in f.saas.operatorActions)
      f.saas.operatorEvent(action: action),
  ],
  'saas.masterChanges': (f) => [
    for (final kind in const <String>['fee', 'drug', 'material', 'diagnosis'])
      f.saas.masterChanges(kind: kind, count: 7),
    f.saas.masterChanges(),
  ],
  'saas.masterChecks': (f) => [
    f.saas.masterChecks(),
    f.saas.masterChecks(allPass: true),
  ],
  'saas.integrationSnapshot': (f) => [
    f.saas.integrationSnapshot(),
    f.saas.integrationSnapshot(at: DateTime.utc(2026, 7, 1, 12)),
  ],
  'saas.incidents': (f) => [
    f.saas.incidents(),
    f.saas.incidents(count: 8, days: 10),
    f.saas.incidents(count: 0),
  ],
  'saas.opsAlert': (f) => [
    for (var i = 0; i < 4; i++) f.saas.opsAlert(),
    for (final level in const <String>['info', 'warning', 'critical'])
      f.saas.opsAlert(level: level),
  ],
  'saas.announcement': (f) => [
    f.saas.announcement(),
    f.saas.announcement(kind: 'release'),
    f.saas.announcement(kind: 'regulation'),
    for (var i = 0; i < 4; i++) f.saas.announcement(),
  ],
  'saas.tenantActivity': (f) => [
    f.saas.tenantActivity(),
    f.saas.tenantActivity(tenant: 'Example Tenant'),
    for (var i = 0; i < 4; i++) f.saas.tenantActivity(),
  ],
  'saas.creditLedger': (f) => [
    f.saas.creditLedger(),
    f.saas.creditLedger(count: 25, openingBalance: 300),
    f.saas.creditLedger(count: 12, openingBalance: 0),
  ],
  'saas.senderNumber': (f) => [
    for (var i = 0; i < 8; i++) f.saas.senderNumber(),
  ],
  'saas.messageTemplate': (f) => [
    for (var i = 0; i < 4; i++) f.saas.messageTemplate(),
    for (final spec in f.saas.data.messageTemplates)
      f.saas.messageTemplate(code: spec.code),
  ],
  'saas.messageLog': (f) => [
    for (var i = 0; i < 12; i++) f.saas.messageLog(),
    f.saas.messageLog(days: 30),
  ],
  'saas.masterVersion': (f) => [
    f.saas.masterVersion(),
    for (final kind in const <String>['fee', 'drug', 'material', 'diagnosis'])
      for (final months in const <int>[-1, 0, 3])
        f.saas.masterVersion(kind: kind, monthsAgo: months),
  ],
  'saas.services': (f) => CoFakerSaas.services,
  'saas.healthCheck': (f) => [
    for (var i = 0; i < 40; i++) f.saas.healthCheck(),
    for (final service in CoFakerSaas.services)
      f.saas.healthCheck(service: service),
  ],
  'saas.auditActions': (f) => CoFakerSaas.auditActions,
  'saas.auditEvent': (f) => [
    for (var i = 0; i < 80; i++) f.saas.auditEvent(),
    f.saas.auditEvent(days: 3),
  ],
  'saas.notice': (f) => [for (var i = 0; i < 8; i++) f.saas.notice()],
  'saas.timeSeries': (f) => [
    f.saas.timeSeries(),
    f.saas.timeSeries(days: 14, base: 50, trend: 2, weekly: 0.4, noise: 0.2),
    f.saas.timeSeries(days: 5, integer: false),
    f.saas.timeSeries(granularity: CoTimeGranularity.hour),
    f.saas.timeSeries(granularity: CoTimeGranularity.month, count: 6, base: 80),
    f.saas.timeSeries(days: 0),
  ],
};
