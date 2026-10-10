import '../clinic.dart';
import '../clinic_data.dart';
import '../clinic_ops.dart';
import '../clinic_texts.dart';
import '../co_faker.dart';
import '../domain_packs/co_faker_catalog.dart';
import '../domain_packs/co_faker_exam_prep.dart';
import '../domain_packs/co_faker_fx.dart';
import '../domain_packs/co_faker_helpdesk.dart';
import '../domain_packs/co_faker_remit.dart';
import '../domain_packs/co_faker_vet.dart';
import '../modules.dart';
import '../saas.dart';
import '../saas_data.dart';

/// Runs one public call of a generator and returns what it generated.
typedef CoLanguageRun = Object? Function(CoFaker faker);

/// A call of a public generator, with arguments that make sense in every
/// language, for the generation checks of the language coverage gate.
class CoLanguageCall {
  /// Creates a call named [name], which is `<generator>.<member>`.
  const CoLanguageCall(
    this.name,
    this.run, {
    this.hangulReason,
    this.englishReason,
    this.notificationTemplates = false,
  });

  /// The name: the generator and the member it calls (`clinic.payment`).
  /// A call that exercises one member in several ways adds a variant after a
  /// second dot (`clinic.payment.method`).
  final String name;

  /// Runs the call on a generator.
  final CoLanguageRun run;

  /// Why the output may hold Hangul in any language, or `null` when it may
  /// not.
  ///
  /// A call that says so is not checked for Hangul. Only calls whose output
  /// is independent of the locale by design may: see `clinic.inquiry`.
  final String? hangulReason;

  /// Why the output holds English words in any language, or `null` when it
  /// does not: it is made of codes and names that no language translates (the
  /// fictional brands and model codes of a device, the English name of a
  /// diagnosis, a user agent).
  ///
  /// A call that says so is not read for the writing system of the language.
  /// Any other call whose output holds English words that equal neither the
  /// English nor the Korean output is held to it.
  final String? englishReason;

  /// Whether the output is a notification template, which keeps its
  /// `#{variable}` markers on purpose (`saas.messageTemplate`). In any other
  /// output a `#{name}` that is left over is a field that no generator filled.
  final bool notificationTemplates;

  /// The member of the generator the call exercises: `payment` for
  /// `clinic.payment.method`.
  String get member => name.split('.')[1];
}

const List<int> _amounts = <int>[20, 400, 800, 30000, 120000, 600000, 2400000];

/// Days that a closure notice is written for: the Korean holidays that an
/// English or Korean notice names, an ordinary weekday, a Saturday and a
/// Sunday, and a day outside the holiday table.
final List<DateTime> _closureDates = <DateTime>[
  DateTime.utc(2026, 9, 25),
  DateTime.utc(2027, 2, 6),
  DateTime.utc(2026, 5, 5),
  DateTime.utc(2026, 10, 9),
  DateTime.utc(2026, 1, 1),
  DateTime.utc(2026, 11, 11),
  DateTime.utc(2026, 11, 14),
  DateTime.utc(2026, 11, 15),
  DateTime.utc(2035, 3, 1),
];

const List<CoFakeVitals> _vitals = <CoFakeVitals>[
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
    temperature: 38.1,
    systolic: 152,
    diastolic: 96,
    pulse: 72,
    spo2: 92,
    glucose: 180,
    heightCm: 165.0,
    weightKg: 58.0,
    bmi: 21.3,
  ),
];

/// Every code that the clinic data labels, in English's order.
final List<String> _clinicLabelCodes = <String>{
  ...CoFakerClinicData.english.labels.keys,
  ...CoFakerClinicTexts.english.labels.keys,
  ...CoFakerClinicOps.english.labels.keys,
}.toList();

/// Every code that the SaaS data labels.
final List<String> _saasLabelCodes = <String>{
  ...CoFakerSaasData.english.labels.keys,
  ...?CoFakerSaasData.english.ops?.labels.keys,
}.toList();

/// The public members of `faker.clinic` that need no calling: they expose the
/// data the generators read.
const Set<String> clinicDataAccessors = <String>{
  'faker',
  'data',
  'texts',
  'ops',
};

/// The public members of `faker.saas` that need no calling.
const Set<String> saasDataAccessors = <String>{'faker', 'data', 'ops'};

/// A call to every public member of `faker.clinic`.
///
/// Loops cover the branches that a single call may miss. A test of the package
/// counts the public members of the class and fails when one is missing here,
/// so a new member cannot escape the gate.
final List<CoLanguageCall> clinicCalls = <CoLanguageCall>[
  CoLanguageCall(
    'clinic.label',
    (f) => [for (final code in _clinicLabelCodes) f.clinic.label(code)],
  ),
  CoLanguageCall(
    'clinic.specialty',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.specialty()],
  ),
  CoLanguageCall(
    'clinic.clinicName',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.clinicName()],
  ),
  CoLanguageCall(
    'clinic.clinicName.specialty',
    (f) => [
      for (final spec in f.clinic.data.specialties)
        f.clinic.clinicName(specialty: spec.name),
    ],
  ),
  CoLanguageCall('clinic.staffRoles', (f) => f.clinic.staffRoles),
  CoLanguageCall(
    'clinic.staffRole',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.staffRole()],
  ),
  CoLanguageCall(
    'clinic.staff',
    (f) => [
      for (var i = 0; i < 3; i++) f.clinic.staff(),
      for (final role in f.clinic.staffRoles) f.clinic.staff(role: role),
    ],
  ),
  CoLanguageCall(
    'clinic.patient',
    (f) => [for (var i = 0; i < 6; i++) f.clinic.patient()],
  ),
  CoLanguageCall(
    'clinic.patient.options',
    (f) => [
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
  ),
  CoLanguageCall(
    'clinic.chartNumber',
    (f) => [
      for (final format in CoChartNumberFormat.values)
        f.clinic.chartNumber(123, format: format),
    ],
  ),
  CoLanguageCall(
    'clinic.insuranceType',
    (f) => [for (var i = 0; i < 12; i++) f.clinic.insuranceType()],
  ),
  CoLanguageCall(
    'clinic.visitPurpose',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.visitPurpose()],
  ),
  CoLanguageCall('clinic.visitPurposeTree', (f) => f.clinic.visitPurposeTree()),
  CoLanguageCall(
    'clinic.procedures',
    (f) => [for (final spec in f.clinic.procedures) spec.name],
  ),
  CoLanguageCall(
    'clinic.procedure',
    (f) => [for (var i = 0; i < 8; i++) f.clinic.procedure()],
  ),
  CoLanguageCall(
    'clinic.procedure.code',
    (f) => [
      for (final spec in f.clinic.procedures)
        f.clinic.procedure(code: spec.code),
    ],
  ),
  CoLanguageCall(
    'clinic.procedure.category',
    (f) => [
      f.clinic.procedure(category: f.clinic.procedures.first.category),
      f.clinic.procedure(category: f.clinic.procedures.last.category),
    ],
  ),
  CoLanguageCall(
    'clinic.package',
    (f) => [for (var i = 0; i < 6; i++) f.clinic.package()],
  ),
  CoLanguageCall(
    'clinic.package.code',
    (f) => [
      for (final spec in f.clinic.procedures)
        f.clinic.package(procedureCode: spec.code),
    ],
  ),
  CoLanguageCall(
    'clinic.packageBalance',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.packageBalance()],
  ),
  CoLanguageCall(
    'clinic.prepaidBalance',
    (f) => [for (var i = 0; i < 6; i++) f.clinic.prepaidBalance()],
  ),
  CoLanguageCall(
    'clinic.diagnosis',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.diagnosis()],
    englishReason:
        'A diagnosis carries its English name (`nameEn`) next to the name of '
        'the language: the English name is a code.',
  ),
  CoLanguageCall(
    'clinic.drugName',
    (f) => [for (var i = 0; i < 8; i++) f.clinic.drugName()],
  ),
  CoLanguageCall(
    'clinic.prescription',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.prescription()],
  ),
  CoLanguageCall(
    'clinic.chartMemo',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.chartMemo()],
  ),
  CoLanguageCall(
    'clinic.soap',
    (f) => [
      f.clinic.soap(),
      f.clinic.soap(diagnosis: f.clinic.data.diagnoses.first),
    ],
  ),
  CoLanguageCall(
    'clinic.questionnaire',
    (f) => [
      f.clinic.questionnaire(),
      f.clinic.questionnaire(count: 3),
      f.clinic.questionnaire(count: 99),
    ],
  ),
  CoLanguageCall(
    'clinic.businessSlots',
    (f) => [
      f.clinic.businessSlots(DateTime.utc(2026, 10, 1)),
      f.clinic.businessSlots(DateTime.utc(2026, 10, 3)),
      f.clinic.businessSlots(DateTime.utc(2026, 10, 4)),
      f.clinic.businessSlots(
        DateTime.utc(2026, 10, 1),
        hours: const CoClinicHours(interval: 60, lunchStart: null),
      ),
    ],
  ),
  CoLanguageCall(
    'clinic.appointmentSlot',
    (f) => [
      for (var i = 0; i < 6; i++) f.clinic.appointmentSlot(),
      f.clinic.appointmentSlot(days: -30),
    ],
  ),
  CoLanguageCall('clinic.visitStages', (f) => CoFakerClinic.visitStages),
  CoLanguageCall(
    'clinic.visitFlow',
    (f) => [for (var i = 0; i < 5; i++) f.clinic.visitFlow()],
  ),
  CoLanguageCall(
    'clinic.visitStage',
    (f) => [for (var i = 0; i < 8; i++) f.clinic.visitStage()],
  ),
  CoLanguageCall(
    'clinic.reservationStatus',
    (f) => [
      for (var i = 0; i < 6; i++)
        f.clinic.reservationStatus(at: f.now.add(const Duration(days: 2))),
      for (var i = 0; i < 6; i++)
        f.clinic.reservationStatus(at: f.now.subtract(const Duration(days: 2))),
      f.clinic.reservationStatus(),
    ],
  ),
  CoLanguageCall(
    'clinic.money',
    (f) => [
      for (final amount in _amounts) f.clinic.money(amount),
      f.clinic.money(1234.5),
      f.clinic.money(-80),
    ],
  ),
  CoLanguageCall(
    'clinic.payment',
    (f) => [for (final amount in _amounts) f.clinic.payment(amount: amount)],
  ),
  CoLanguageCall(
    'clinic.payment.method',
    (f) => [
      for (final method in const <String>[
        'card',
        'cash',
        'transfer',
        'prepaid',
      ])
        for (final amount in const <int>[400, 600000])
          f.clinic.payment(amount: amount, method: method),
    ],
  ),
  CoLanguageCall(
    'clinic.splitPayment',
    (f) => [
      for (final amount in _amounts) f.clinic.splitPayment(amount: amount),
      for (var i = 0; i < 12; i++) f.clinic.splitPayment(amount: 480000),
    ],
  ),
  CoLanguageCall('clinic.consentKinds', (f) => f.clinic.consentKinds),
  CoLanguageCall(
    'clinic.consentForm',
    (f) => [
      f.clinic.consentForm(),
      for (final kind in f.clinic.consentKinds)
        f.clinic.consentForm(kind: kind),
    ],
  ),
  CoLanguageCall(
    'clinic.feedback',
    (f) => [
      f.clinic.feedback(),
      for (final sentiment in const <String>['positive', 'neutral', 'negative'])
        f.clinic.feedback(sentiment: sentiment),
    ],
  ),
  CoLanguageCall('clinic.counselTopics', (f) => f.clinic.counselTopics),
  CoLanguageCall(
    'clinic.counselSession',
    (f) => [
      f.clinic.counselSession(),
      f.clinic.counselSession(),
      for (final topic in f.clinic.counselTopics)
        f.clinic.counselSession(topic: topic),
    ],
  ),
  CoLanguageCall(
    'clinic.inquiryLanguages',
    (f) => CoFakerClinic.inquiryLanguages,
  ),
  CoLanguageCall(
    'clinic.inquiry',
    (f) => [
      for (final language in CoFakerClinic.inquiryLanguages)
        f.clinic.inquiry(language: language, exchanges: 3),
    ],
    hangulReason:
        'A messenger thread is written in the language of the patient, '
        'whatever the locale of the faker is, and every thread of another '
        'language carries its Korean translation: the call is independent of '
        'the locale by design.',
  ),
  CoLanguageCall(
    'clinic.messengerHandle',
    (f) => [
      f.clinic.messengerHandle(language: f.language),
      for (final channel in const <String>[
        'kakao',
        'line',
        'wechat',
        'whatsapp',
        'zalo',
        'instagram',
      ])
        f.clinic.messengerHandle(channel: channel, language: f.language),
    ],
  ),
  CoLanguageCall(
    'clinic.insurerName',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.insurerName()],
  ),
  CoLanguageCall(
    'clinic.integrationServices',
    (f) => f.clinic.integrationServices,
  ),
  CoLanguageCall(
    'clinic.integrationResult',
    (f) => [
      for (var i = 0; i < 4; i++) f.clinic.integrationResult(),
      for (final service in f.clinic.integrationServices)
        for (var i = 0; i < 4; i++)
          f.clinic.integrationResult(service: service),
    ],
  ),
  CoLanguageCall('clinic.deviceKinds', (f) => CoFakerClinic.deviceKinds),
  CoLanguageCall(
    'clinic.device',
    (f) => [
      f.clinic.device(),
      for (final kind in CoFakerClinic.deviceKinds)
        f.clinic.device(kind: kind, number: 2),
    ],
    englishReason:
        'The brand (`Lumenixa`) and the model code (`LUM-R910 Pro`) of a '
        'device are fictional names that no language translates.',
  ),
  CoLanguageCall('clinic.teamNote', (f) {
    final names = <String>[for (var i = 0; i < 3; i++) f.person.fullName()];
    return [
      for (var i = 0; i < 8; i++) f.clinic.teamNote(),
      for (var i = 0; i < 4; i++)
        f.clinic.teamNote(
          patient: names[0],
          authors: <String>[names[1], names[2]],
          mentions: <String>[names[1], names[2]],
        ),
      f.clinic.teamNote(mentions: <String>[names[0]]),
    ];
  }),
  CoLanguageCall(
    'clinic.staffNotice',
    (f) => [
      f.clinic.staffNotice(),
      for (final kind in const <String>['training', 'policy', 'schedule'])
        f.clinic.staffNotice(kind: kind),
    ],
  ),
  CoLanguageCall(
    'clinic.vitalsNote',
    (f) => [
      for (final vitals in _vitals) f.clinic.vitalsNote(vitals: vitals),
      f.clinic.vitalsNote(),
    ],
  ),
  CoLanguageCall('clinic.closureNotice', (f) {
    final name = f.clinic.clinicName();
    return [
      for (final date in _closureDates) f.clinic.closureNotice(date: date),
      for (final date in _closureDates.take(3))
        f.clinic.closureNotice(date: date, clinicName: name),
    ];
  }),
  CoLanguageCall('clinic.relations', (f) => CoFakerClinic.relations),
  CoLanguageCall(
    'clinic.familyRelation',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.familyRelation()],
  ),
  CoLanguageCall(
    'clinic.guardian',
    (f) => [
      f.clinic.guardian(),
      f.clinic.guardian(patientAge: 10),
      f.clinic.guardian(patientAge: 80),
    ],
  ),
  CoLanguageCall(
    'clinic.patientTag',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.patientTag()],
  ),
  CoLanguageCall(
    'clinic.patientTags',
    (f) => [f.clinic.patientTags(), f.clinic.patientTags(max: 5)],
  ),
  CoLanguageCall(
    'clinic.acquisitionChannel',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.acquisitionChannel()],
  ),
  CoLanguageCall(
    'clinic.specialNote',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.specialNote()],
  ),
  CoLanguageCall(
    'clinic.maskName',
    (f) => [
      for (var i = 0; i < 4; i++) CoFakerClinic.maskName(f.person.fullName()),
    ],
  ),
  CoLanguageCall(
    'clinic.maskedName',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.maskedName()],
  ),
  CoLanguageCall(
    'clinic.consentHistoryKinds',
    (f) => CoFakerClinic.consentHistoryKinds,
  ),
  CoLanguageCall(
    'clinic.termsVersion',
    (f) => [f.clinic.termsVersion(), f.clinic.termsVersion(monthsAgo: 5)],
  ),
  CoLanguageCall(
    'clinic.consentHistory',
    (f) => [f.clinic.consentHistory(), f.clinic.consentHistory(count: 8)],
  ),
  CoLanguageCall(
    'clinic.consentDispatch',
    (f) => [
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
  ),
  CoLanguageCall('clinic.palette', (f) => CoFakerClinic.palette),
  CoLanguageCall(
    'clinic.color',
    (f) => [f.clinic.color(), f.clinic.color(index: 3)],
  ),
  CoLanguageCall(
    'clinic.rooms',
    (f) => [f.clinic.rooms(), f.clinic.rooms(includeReception: false)],
  ),
  CoLanguageCall('clinic.queueStatuses', (f) => CoFakerClinic.queueStatuses),
  CoLanguageCall(
    'clinic.queueBoard',
    (f) => [
      f.clinic.queueBoard(),
      f.clinic.queueBoard(count: 3),
      f.clinic.queueBoard(rooms: f.clinic.rooms().take(2).toList(), count: 2),
    ],
  ),
  CoLanguageCall(
    'clinic.receptionSource',
    (f) => [for (var i = 0; i < 6; i++) f.clinic.receptionSource()],
  ),
  CoLanguageCall(
    'clinic.kioskPurpose',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.kioskPurpose()],
  ),
  CoLanguageCall(
    'clinic.vitals',
    (f) => [
      f.clinic.vitals(),
      f.clinic.vitals(age: 8),
      f.clinic.vitals(age: 70, sex: CoSex.female),
    ],
  ),
  CoLanguageCall('clinic.faceRegions', (f) => CoFakerClinic.faceRegions),
  CoLanguageCall(
    'clinic.faceFrontRegions',
    (f) => CoFakerClinic.faceFrontRegions,
  ),
  CoLanguageCall(
    'clinic.canvasMarks',
    (f) => [
      f.clinic.canvasMarks(),
      f.clinic.canvasMarks(template: 'faceFront'),
      f.clinic.canvasMarks(regions: const <String>['forehead', 'chin']),
    ],
  ),
  CoLanguageCall(
    'clinic.adjustment',
    (f) => [
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
  ),
  CoLanguageCall(
    'clinic.cardDecline',
    (f) => [for (var i = 0; i < 6; i++) f.clinic.cardDecline()],
  ),
  CoLanguageCall(
    'clinic.paymentMessage',
    (f) => [
      for (final code in const <String>[
        'approved',
        'cashReceipt',
        'partialCancel',
        'prepaidUsed',
        'declined',
      ])
        f.clinic.paymentMessage(code: code),
    ],
  ),
  CoLanguageCall(
    'clinic.pointTransaction',
    (f) => [
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
  ),
  CoLanguageCall(
    'clinic.compoundPackageName',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.compoundPackageName()],
  ),
  CoLanguageCall(
    'clinic.visitHeatmap',
    (f) => [f.clinic.visitHeatmap(), f.clinic.visitHeatmap(base: 12)],
  ),
  CoLanguageCall(
    'clinic.task',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.task()],
  ),
  CoLanguageCall(
    'clinic.counselEvidence',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.counselEvidence()],
  ),
  CoLanguageCall(
    'clinic.counselFailure',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.counselFailure()],
  ),
  CoLanguageCall(
    'clinic.claimIssue',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.claimIssue()],
  ),
  CoLanguageCall(
    'clinic.crmSendFailure',
    (f) => [for (var i = 0; i < 4; i++) f.clinic.crmSendFailure()],
  ),
];

/// A call to every public member of `faker.saas`; see [clinicCalls].
final List<CoLanguageCall> saasCalls = <CoLanguageCall>[
  CoLanguageCall(
    'saas.label',
    (f) => [for (final code in _saasLabelCodes) f.saas.label(code)],
  ),
  CoLanguageCall(
    'saas.money',
    (f) => [
      for (final amount in _amounts) f.saas.money(amount),
      f.saas.money(1234.5),
    ],
  ),
  CoLanguageCall(
    'saas.tenant',
    (f) => [for (var i = 0; i < 6; i++) f.saas.tenant()],
  ),
  CoLanguageCall(
    'saas.plan',
    (f) => [for (var i = 0; i < 4; i++) f.saas.plan()],
  ),
  CoLanguageCall(
    'saas.subscriptionStatus',
    (f) => [for (var i = 0; i < 10; i++) f.saas.subscriptionStatus()],
  ),
  CoLanguageCall(
    'saas.subscription',
    (f) => [
      f.saas.subscription(),
      f.saas.subscription(planCode: 'pro', status: 'trialing'),
      f.saas.subscription(planCode: 'starter', status: 'cancelled'),
    ],
  ),
  CoLanguageCall(
    'saas.invoice',
    (f) => [
      for (var months = 0; months < 8; months++)
        f.saas.invoice(monthsAgo: months),
      f.saas.invoice(supplyAmount: 99999),
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
  ),
  CoLanguageCall(
    'saas.invoices',
    (f) => [
      f.saas.invoices(4),
      f.saas.invoices(
        6,
        supplyAmount: 120000,
        numberFormat: CoInvoiceNumberFormat.compact,
        firstSequence: 40,
        statusWeights: const <String, int>{'paid': 60, 'failed': 40},
      ),
    ],
  ),
  CoLanguageCall('saas.autopayFailureCodes', (f) => f.saas.autopayFailureCodes),
  CoLanguageCall(
    'saas.autopayFailure',
    (f) => [for (var i = 0; i < 8; i++) f.saas.autopayFailure()],
  ),
  CoLanguageCall(
    'saas.prepaidBonusTiers',
    (f) => CoFakerSaas.prepaidBonusTiers,
  ),
  CoLanguageCall(
    'saas.prepaidBonus',
    (f) => [
      for (final amount in const <int>[
        99999,
        100000,
        300000,
        1000000,
        15000000,
      ])
        CoFakerSaas.prepaidBonus(amount),
    ],
  ),
  CoLanguageCall(
    'saas.prepaidLedger',
    (f) => [
      f.saas.prepaidLedger(),
      f.saas.prepaidLedger(count: 30, openingBalance: 700000),
      f.saas.prepaidLedger(count: 12, openingBalance: 40),
    ],
  ),
  CoLanguageCall('saas.operatorRoles', (f) => f.saas.operatorRoles),
  CoLanguageCall(
    'saas.operator',
    (f) => [
      for (var i = 0; i < 5; i++) f.saas.operator(),
      for (final role in f.saas.operatorRoles) f.saas.operator(role: role),
    ],
  ),
  CoLanguageCall('saas.operatorActions', (f) => f.saas.operatorActions),
  CoLanguageCall(
    'saas.operatorEvent',
    (f) => [
      f.saas.operatorEvent(),
      f.saas.operatorEvent(days: 7),
      for (final action in f.saas.operatorActions)
        f.saas.operatorEvent(action: action),
    ],
  ),
  CoLanguageCall(
    'saas.masterChanges',
    (f) => [
      for (final kind in const <String>['fee', 'drug', 'material', 'diagnosis'])
        f.saas.masterChanges(kind: kind, count: 7),
      f.saas.masterChanges(),
    ],
  ),
  CoLanguageCall(
    'saas.masterChecks',
    (f) => [f.saas.masterChecks(), f.saas.masterChecks(allPass: true)],
  ),
  CoLanguageCall(
    'saas.integrationSnapshot',
    (f) => [
      f.saas.integrationSnapshot(),
      f.saas.integrationSnapshot(at: DateTime.utc(2026, 7, 1, 12)),
    ],
  ),
  CoLanguageCall(
    'saas.incidents',
    (f) => [
      f.saas.incidents(),
      f.saas.incidents(count: 8, days: 10),
      f.saas.incidents(count: 0),
    ],
  ),
  CoLanguageCall(
    'saas.opsAlert',
    (f) => [
      for (var i = 0; i < 4; i++) f.saas.opsAlert(),
      for (final level in const <String>['info', 'warning', 'critical'])
        f.saas.opsAlert(level: level),
    ],
  ),
  CoLanguageCall(
    'saas.announcement',
    (f) => [
      f.saas.announcement(),
      f.saas.announcement(kind: 'release'),
      f.saas.announcement(kind: 'regulation'),
      for (var i = 0; i < 4; i++) f.saas.announcement(),
    ],
  ),
  CoLanguageCall('saas.tenantActivity', (f) {
    final name = f.clinic.clinicName();
    return [
      f.saas.tenantActivity(),
      f.saas.tenantActivity(tenant: name),
      for (var i = 0; i < 4; i++) f.saas.tenantActivity(),
    ];
  }),
  CoLanguageCall(
    'saas.creditLedger',
    (f) => [
      f.saas.creditLedger(),
      f.saas.creditLedger(count: 25, openingBalance: 300),
      f.saas.creditLedger(count: 12),
    ],
  ),
  CoLanguageCall(
    'saas.senderNumber',
    (f) => [for (var i = 0; i < 8; i++) f.saas.senderNumber()],
  ),
  CoLanguageCall(
    'saas.messageTemplate',
    (f) => [
      for (var i = 0; i < 4; i++) f.saas.messageTemplate(),
      for (final spec in f.saas.data.messageTemplates)
        f.saas.messageTemplate(code: spec.code),
    ],
    notificationTemplates: true,
  ),
  CoLanguageCall(
    'saas.messageLog',
    (f) => [
      for (var i = 0; i < 12; i++) f.saas.messageLog(),
      f.saas.messageLog(days: 30),
    ],
  ),
  CoLanguageCall(
    'saas.masterVersion',
    (f) => [
      f.saas.masterVersion(),
      for (final kind in const <String>['fee', 'drug', 'material', 'diagnosis'])
        for (final months in const <int>[0, 3])
          f.saas.masterVersion(kind: kind, monthsAgo: months),
    ],
  ),
  CoLanguageCall('saas.services', (f) => CoFakerSaas.services),
  CoLanguageCall(
    'saas.healthCheck',
    (f) => [
      for (var i = 0; i < 40; i++) f.saas.healthCheck(),
      for (final service in CoFakerSaas.services)
        f.saas.healthCheck(service: service),
    ],
  ),
  CoLanguageCall('saas.auditActions', (f) => CoFakerSaas.auditActions),
  CoLanguageCall(
    'saas.auditEvent',
    (f) => [
      for (var i = 0; i < 80; i++) f.saas.auditEvent(),
      f.saas.auditEvent(days: 3),
    ],
    englishReason:
        'An audit event carries the user agent of the browser '
        '(`Chrome/140.0 Safari/537.36`), a technical string.',
  ),
  CoLanguageCall(
    'saas.notice',
    (f) => [for (var i = 0; i < 8; i++) f.saas.notice()],
  ),
  CoLanguageCall(
    'saas.timeSeries',
    (f) => [
      f.saas.timeSeries(),
      f.saas.timeSeries(days: 14, base: 50, trend: 2, weekly: 0.4, noise: 0.2),
      f.saas.timeSeries(granularity: CoTimeGranularity.hour),
      f.saas.timeSeries(
        granularity: CoTimeGranularity.month,
        count: 6,
        base: 80,
      ),
    ],
  ),
];

/// The currencies `faker.fx` knows.
const List<String> _fxCurrencies = <String>[
  ...CoFakerFx.currencyCodes,
  'PHP',
  'NPR',
];

/// A call to every public member of the dedicated generators `fx`, `remit`,
/// `vet`, `booking`, `catalog`, `examPrep`, and the helpdesk drafts.
final List<CoLanguageCall> generatorCalls = <CoLanguageCall>[
  CoLanguageCall('fx.currencyCodes', (f) => CoFakerFx.currencyCodes),
  CoLanguageCall(
    'fx.currency',
    (f) => [
      for (final code in _fxCurrencies) f.fx.currency(code: code).toJson(),
      for (var i = 0; i < 4; i++) f.fx.currency().toJson(),
    ],
  ),
  CoLanguageCall(
    'fx.denomination',
    (f) => [for (var i = 0; i < 4; i++) f.fx.denomination()],
  ),
  CoLanguageCall(
    'fx.maskedAccount',
    (f) => [for (var i = 0; i < 3; i++) f.fx.maskedAccount()],
  ),
  CoLanguageCall(
    'fx.rateSeries',
    (f) => [
      for (final point in f.fx.rateSeries(currencyCode: 'EUR', days: 4))
        point.toJson(),
    ],
  ),
  CoLanguageCall('remit.countryCodes', (f) => CoFakerRemit.countryCodes),
  CoLanguageCall('remit.payoutMethods', (f) => CoFakerRemit.payoutMethods),
  CoLanguageCall('remit.purposes', (f) => CoFakerRemit.purposes),
  CoLanguageCall('remit.fundSources', (f) => CoFakerRemit.fundSources),
  CoLanguageCall('remit.statuses', (f) => CoFakerRemit.statuses),
  CoLanguageCall(
    'remit.recipient',
    (f) => [
      for (final code in CoFakerRemit.countryCodes)
        f.remit.recipient(index: 2, countryCode: code).toJson(),
      for (var i = 0; i < 4; i++) f.remit.recipient(index: i).toJson(),
    ],
  ),
  CoLanguageCall(
    'remit.transfer',
    (f) => [for (var i = 0; i < 8; i++) f.remit.transfer(index: i).toJson()],
  ),
  CoLanguageCall(
    'remit.milestones',
    (f) => [
      for (var i = 0; i < 8; i++)
        f.remit.milestones(f.remit.transfer(index: i)),
    ],
  ),
  CoLanguageCall('vet.animalKinds', (f) => CoFakerVet.animalKinds),
  CoLanguageCall(
    'vet.breeds',
    (f) => [for (final kind in CoFakerVet.animalKinds) f.vet.breeds(kind)],
  ),
  CoLanguageCall(
    'vet.pet',
    (f) => [
      for (final kind in CoFakerVet.animalKinds)
        for (var i = 0; i < 3; i++) f.vet.pet(animalKind: kind).toJson(),
      for (var i = 0; i < 8; i++) f.vet.pet().toJson(),
    ],
  ),
  CoLanguageCall(
    'booking.slot',
    (f) => [for (var i = 0; i < 6; i++) f.booking.slot(index: i).toJson()],
  ),
  CoLanguageCall(
    'booking.slots',
    (f) => [
      for (final slot in f.booking.slots(days: 2, blocksPerDay: 4))
        slot.toJson(),
    ],
  ),
  CoLanguageCall(
    'catalog.item',
    (f) => [
      for (final grocery in const <bool>[false, true])
        for (var i = 0; i < 9; i++)
          f.catalog.item(grocery: grocery, index: i).toJson(),
      for (var i = 0; i < 4; i++) f.catalog.item().toJson(),
    ],
  ),
  CoLanguageCall(
    'catalog.groceryKindCodes',
    (f) => CoFakerCatalog.groceryKindCodes,
  ),
  CoLanguageCall(
    'catalog.groceryKindName',
    (f) => [
      for (final code in CoFakerCatalog.groceryKindCodes)
        f.catalog.groceryKindName(code),
    ],
  ),
  CoLanguageCall(
    'catalog.groceryPackLabel',
    (f) => [
      for (final count in const <int>[1, 10, 15, 20])
        f.catalog.groceryPackLabel(count),
    ],
  ),
  CoLanguageCall('examPrep.sections', (f) => CoFakerExamPrep.sections),
  CoLanguageCall(
    'examPrep.question',
    (f) => [
      for (var i = 0; i < CoFakerExamPrep.sections.length + 2; i++)
        f.examPrep.question(index: i).toJson(),
      for (var i = 0; i < 4; i++) f.examPrep.question().toJson(),
    ],
  ),
  CoLanguageCall('helpdesk.drafts', (f) => CoFakerHelpdesk(f).drafts()),
];

/// The generators that the calls above exercise, by the name that starts a
/// call (`clinic` for `clinic.payment`), with the public members of each that
/// need no call because they only expose data.
///
/// A test of the package reads the public members that each generator
/// declares and compares them with the calls, so that a member that is added
/// to a generator is either called by the gate or named here.
const Map<String, Set<String>> languageCallAccessors = <String, Set<String>>{
  'clinic': clinicDataAccessors,
  'saas': saasDataAccessors,
  'fx': <String>{'faker'},
  'remit': <String>{'faker'},
  'vet': <String>{'faker'},
  'booking': <String>{'faker'},
  'catalog': <String>{'faker'},
  'examPrep': <String>{'faker'},
  'helpdesk': <String>{'faker'},
};

/// Every call of the gate: the dedicated generators, `faker.clinic`, and
/// `faker.saas`.
List<CoLanguageCall> get allLanguageCalls => <CoLanguageCall>[
  ...clinicCalls,
  ...saasCalls,
  ...generatorCalls,
];
