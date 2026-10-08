import 'dart:math' as math;

import 'clinic_data.dart';
import 'clinic_ops.dart';
import 'clinic_texts.dart';
import 'co_faker.dart';
import 'korea.dart';
import 'korean_values.dart';
import 'modules.dart';
import 'signature.dart';

/// A patient profile for EMR fixtures.
///
/// [rrnMasked] is a masked national ID number. Korean data and English data
/// (which has always carried one) generate a masked, Korean-format fake
/// resident registration number (`YYMMDD-G******`, see [CoFakerKorea.rrn]);
/// data whose [CoFakerClinicData.koreanValues] is [CoKoreanValues.none]
/// follows its [CoFakerClinicData.maskedIdFormat] instead.
typedef CoFakePatient = ({
  String name,
  CoSex sex,
  DateTime birthDate,
  int age,
  String rrnMasked,
  String phone,
  String? email,
  String postalCode,
  String address1,
  String address2,
  String insurance,
  String insuranceLabel,
  String chartNo,
  int visitCount,
  DateTime? lastVisitAt,
  String channel,
  String channelLabel,
  String? specialNote,
});

/// A staff member of a clinic.
typedef CoFakeStaff = ({
  String name,
  String role,
  String roleLabel,
  String email,
  String phone,
});

/// A procedure line priced within its band.
typedef CoFakeProcedure = ({
  String code,
  String category,
  String name,
  String unit,
  int price,
  bool taxable,
});

/// A session package (회차권) offer.
typedef CoFakePackage = ({
  String name,
  String procedureCode,
  int sessions,
  int price,
  int validDays,
});

/// A package a patient owns, with its remaining sessions.
typedef CoFakePackageBalance = ({
  String name,
  String procedureCode,
  int totalSessions,
  int usedSessions,
  int remainingSessions,
  DateTime purchasedAt,
  DateTime expiresAt,
});

/// A fictional prescription line.
typedef CoFakePrescription = ({
  String name,
  String usage,
  int days,
  int quantity,
});

/// A SOAP chart note.
typedef CoFakeSoap = ({
  String subjective,
  String objective,
  String assessment,
  String plan,
});

/// One payment of an invoice.
///
/// [method] is one of `card`, `cash`, `transfer`, or `prepaid`. Card
/// payments carry [cardIssuer], [installmentMonths], and [approvalNo]; cash
/// payments may carry a masked [cashReceiptNo].
///
/// Korean data and English data (which has always carried them) generate a
/// Korean 8-digit card approval number and a masked cash receipt number
/// (현금영수증). Data whose [CoFakerClinicData.koreanValues] is
/// [CoKoreanValues.none] generates a plain 6-digit authorization code and no
/// cash receipt number.
typedef CoFakePayment = ({
  String method,
  String methodLabel,
  int amount,
  String? cardIssuer,
  int? installmentMonths,
  String? approvalNo,
  String? cashReceiptNo,
});

/// A generated consent form. [disclaimer] states that the text is an
/// example and not a legal document.
typedef CoFakeConsentForm = ({
  String kind,
  String title,
  List<String> clauses,
  String disclaimer,
});

/// A satisfaction survey answer. [score] is 1-5.
typedef CoFakeFeedback = ({String sentiment, int score, String comment});

/// One turn of a conversation. [speaker] is `counselor`, `patient`, or
/// `staff`; [at] is the offset from the start of the conversation.
typedef CoFakeTurn = ({
  String speaker,
  String text,
  Duration at,
  String? language,
  String? translation,
});

/// A recorded counseling session with its summary and quote.
typedef CoFakeCounselSession = ({
  String topic,
  String procedureCode,
  String procedure,
  List<CoFakeTurn> turns,
  String summary,
  int quotedPrice,
  int packagePrice,
  int sessions,
  bool booked,
});

/// A messenger inquiry thread from a (possibly foreign) patient.
typedef CoFakeInquiry = ({
  String language,
  String channel,
  String handle,
  List<CoFakeTurn> turns,
});

/// A public integration call result. The messages are examples, not
/// official response texts.
typedef CoFakeIntegrationResult = ({
  String service,
  String code,
  String message,
  bool ok,
});

/// A clinic device with a fictional vendor and model.
typedef CoFakeDevice = ({
  String kind,
  String kindLabel,
  String name,
  String vendor,
  String model,
  String serial,
});

/// A collaboration note between staff with an `@` mention.
typedef CoFakeTeamNote = ({String text, String author, List<String> mentions});

/// A guardian or family contact of a patient.
typedef CoFakeGuardian = ({
  String name,
  CoSex sex,
  String relation,
  String relationLabel,
  String phone,
});

/// How chart numbers are formatted by [CoFakerClinic.chartNumber].
enum CoChartNumberFormat {
  /// The bare number: `123`.
  plain,

  /// Zero-padded to six digits: `000123`.
  padded,

  /// Registration year and a five-digit number: `2026-00123`.
  yearly,
}

/// A node of the visit purpose tree. Top-level purposes have no
/// [parentId].
typedef CoFakeVisitPurposeNode = ({
  int id,
  int? parentId,
  String name,
  String? color,
});

/// A clinic room.
typedef CoFakeRoom = ({
  int id,
  String name,
  String kind,
  String kindLabel,
  String? staffName,
  String? staffRole,
  String color,
});

/// One entry of a room queue. [status] is `inProgress`, `priority`,
/// `waiting`, or `requested`; [order] is the 1-based position.
typedef CoFakeQueueEntry = ({
  int order,
  String patientName,
  String status,
  String statusLabel,
  String purpose,
  DateTime checkedInAt,
});

/// The queue snapshot of one room.
typedef CoFakeRoomQueue = ({
  int roomId,
  String roomName,
  String roomKind,
  List<CoFakeQueueEntry> entries,
});

/// A consent history event. [action] is `agreed` or `withdrawn`.
typedef CoFakeConsentEvent = ({
  String kind,
  String kindLabel,
  String channel,
  String channelLabel,
  String action,
  String actionLabel,
  String termsVersion,
  DateTime at,
});

/// Vital signs. [glucose] is mg/dL, [temperature] °C.
typedef CoFakeVitals = ({
  double temperature,
  int systolic,
  int diastolic,
  int pulse,
  int spo2,
  int glucose,
  double heightCm,
  double weightKg,
  double bmi,
});

/// A pen chart mark in normalized `0..1` canvas coordinates. [tool] is
/// `pen` or `highlighter`.
typedef CoFakeCanvasMark = ({
  String tool,
  String color,
  double width,
  String region,
  CoInkStroke points,
});

/// A rectangle in normalized `0..1` canvas coordinates.
typedef CoRegionRect = ({double left, double top, double right, double bottom});

/// Clinic opening hours used by [CoFakerClinic.businessSlots].
///
/// Times are minutes from midnight. [saturdayClose] of `null` closes the
/// clinic on Saturdays; Sundays are always closed.
class CoClinicHours {
  /// Creates opening hours. The defaults are a typical Korean dermatology
  /// clinic: 10:00-19:00 on weekdays, lunch 13:00-14:00, Saturdays until
  /// 15:00 without lunch, and 30-minute slots.
  const CoClinicHours({
    this.open = 600,
    this.close = 1140,
    this.lunchStart = 780,
    this.lunchEnd = 840,
    this.saturdayClose = 900,
    this.interval = 30,
  });

  /// Opening time.
  final int open;

  /// Closing time; the last slot starts `interval` minutes before.
  final int close;

  /// Start of the lunch break, or `null` for none.
  final int? lunchStart;

  /// End of the lunch break.
  final int? lunchEnd;

  /// Saturday closing time, or `null` when closed on Saturdays.
  final int? saturdayClose;

  /// Slot length in minutes.
  final int interval;
}

/// Generates clinic and EMR domain values: clinics, staff, patients,
/// procedures, diagnoses, prescriptions, chart notes, questionnaires,
/// appointment slots, visit flow, and payments.
///
/// Texts come from [CoFakerClinicData] of the current locale (Korean and
/// English are built in; a language without data of its own falls back to
/// English). The same data decides the currency format and price scale of
/// amounts, the clinic name order, and whether Korean-only values are
/// generated, so a language is added by data alone. Codes such as `nhis`,
/// `waiting`, `noShow`, and `prepaid` are locale independent and match the
/// enum names an EMR typically uses; `label(code)` localizes them.
///
/// Some concepts exist only in Korea: the resident registration number, card
/// approval and cash receipt numbers, the public holiday calendar
/// ([CoFakerKorea.holidays]) behind [closureNotice], and the national health
/// insurance (`nhis`, `medicalAid1`, `medicalAid2`) and its insurers. Korean
/// data generates them all and English data keeps the ones it has always
/// generated; data of any other language ([CoKoreanValues.none]) never
/// generates a Korean-only value, and its labels for the insurance codes come
/// from its own data or fall back to the English ones.
class CoFakerClinic {
  /// Creates a clinic generator backed by [faker].
  CoFakerClinic(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// The clinic data of the current locale.
  CoFakerClinicData get data => faker.localeData.clinic!;

  CoClinicPriceScale get _scale => data.priceScale;

  CoKoreanValues get _values => data.koreanValues;

  /// The longer clinic texts of the current locale.
  CoFakerClinicTexts get texts => data.texts ?? CoFakerClinicTexts.english;

  /// Front-desk, billing, operations, and CRM texts of the current locale.
  CoFakerClinicOps get ops => data.ops ?? CoFakerClinicOps.english;

  /// Returns the localized label of a code such as `nhis`, `noShow`, or
  /// `spouse`, falling back to English and then to the code itself.
  String label(String code) =>
      data.labels[code] ??
      texts.labels[code] ??
      ops.labels[code] ??
      CoFakerClinicOps.english.labels[code] ??
      CoFakerClinicData.english.labels[code] ??
      CoFakerClinicTexts.english.labels[code] ??
      code;

  /// Generates a specialty name such as `피부과`.
  String specialty() => faker.random.pick(data.specialties).name;

  /// Generates a clinic name such as `맑은피부과의원`.
  ///
  /// [specialty] picks the suffix of a matching specialty.
  String clinicName({String? specialty}) {
    final matching = specialty == null
        ? data.specialties
        : data.specialties.where((s) => s.name == specialty).toList();
    final spec = faker.random.pick(
      matching.isEmpty ? data.specialties : matching,
    );
    final prefix = faker.random.pick(data.clinicNamePrefixes);
    return data.clinicNameFormat
        .replaceAll('{prefix}', prefix)
        .replaceAll('{suffix}', spec.clinicSuffix);
  }

  /// Staff role codes: `director`, `doctor`, `counselor`, `coordinator`,
  /// `nurse`, `nurseAide`, `skincare`, and `desk`.
  List<String> get staffRoles => data.staffRoles.keys.toList();

  /// Generates a staff role code with its label.
  ({String code, String label}) staffRole() {
    final code = faker.random.pick(staffRoles);
    return (code: code, label: data.staffRoles[code]!);
  }

  /// Generates a staff member. [role] is a staff role code.
  CoFakeStaff staff({String? role, String domain = 'demo.clinic'}) {
    final code = role ?? faker.random.pick<String>(staffRoles);
    final sex = faker.person.sex(femaleRatio: 0.7);
    final first = faker.person.firstName(sex: sex);
    final last = faker.person.lastName();
    return (
      name: faker.person.fullName(firstName: first, lastName: last),
      role: code,
      roleLabel: data.staffRoles[code] ?? code,
      email: faker.internet.email(
        firstName: first,
        lastName: last,
        domain: domain,
      ),
      phone: _phone(),
    );
  }

  /// Generates a patient profile.
  ///
  /// Ages follow a dermatology-clinic distribution (mostly 20-50) unless
  /// [minAge]/[maxAge] are given, and [femaleRatio] defaults to 0.75.
  /// [emailRatio] is the share of patients with an email address.
  ///
  /// [chartNumber] and [chartNumberFormat] set the chart number; without
  /// them a number is derived. Chart number, visit history, acquisition
  /// channel, and special note come from a stream derived from the name and
  /// birth date, so they never shift the other fields.
  CoFakePatient patient({
    CoSex? sex,
    int? minAge,
    int? maxAge,
    double femaleRatio = 0.75,
    double emailRatio = 0.4,
    int? chartNumber,
    CoChartNumberFormat chartNumberFormat = CoChartNumberFormat.plain,
  }) {
    final resolvedSex = sex ?? faker.person.sex(femaleRatio: femaleRatio);
    final age = minAge != null || maxAge != null
        ? faker.random.int(min: minAge ?? 0, max: maxAge ?? 90)
        : _weighted(const <(int, int)>[
                (15, 4),
                (25, 30),
                (35, 30),
                (45, 18),
                (55, 12),
                (65, 6),
              ]) +
              faker.random.int(max: 9);
    final birth = _birthDate(age);
    final first = faker.person.firstName(sex: resolvedSex);
    final last = faker.person.lastName();
    final hasEmail = faker.random.double() < emailRatio;
    final String postal;
    final String line1;
    final String line2;
    if (_values == CoKoreanValues.korean) {
      final address = faker.korea.roadAddress();
      postal = address.postalCode;
      line1 = address.line1;
      line2 = address.line2;
    } else if (_values == CoKoreanValues.none && faker.country != null) {
      // A national locale: the city, region and postal code agree, in the
      // order of the country.
      final address = faker.address.postalAddress();
      postal = address.postalCode;
      line1 = address.formatted;
      line2 = '';
    } else {
      postal = faker.address.postalCode();
      line1 = faker.address.streetAddress();
      line2 = '';
    }
    final insurance = insuranceType();
    final name = faker.person.fullName(firstName: first, lastName: last);
    final extra = faker.derive('clinic/patient/$name/$birth').clinic;
    final visits = extra.faker.random.int(max: 24);
    final channel = extra.acquisitionChannel();
    return (
      name: name,
      sex: resolvedSex,
      birthDate: birth,
      age: _ageOn(birth, faker.now),
      rrnMasked: _maskedId(birth, resolvedSex),
      phone: _phone(),
      email: hasEmail
          ? faker.internet.email(firstName: first, lastName: last)
          : null,
      postalCode: postal,
      address1: line1,
      address2: line2,
      insurance: insurance.code,
      insuranceLabel: insurance.label,
      chartNo: this.chartNumber(
        chartNumber ?? extra.faker.random.int(min: 1, max: 20000),
        format: chartNumberFormat,
      ),
      visitCount: visits,
      lastVisitAt: visits == 0
          ? null
          : _dayStart(extra.faker.date.past(days: 180, utc: faker.now.isUtc)),
      channel: channel.code,
      channelLabel: channel.label,
      specialNote: extra.faker.random.double() < 0.2
          ? extra.faker.random.pick(ops.specialNotes)
          : null,
    );
  }

  /// Formats chart [number] as [format].
  String chartNumber(
    int number, {
    CoChartNumberFormat format = CoChartNumberFormat.plain,
  }) {
    return switch (format) {
      CoChartNumberFormat.plain => '$number',
      CoChartNumberFormat.padded => '$number'.padLeft(6, '0'),
      CoChartNumberFormat.yearly =>
        '${faker.now.year}-${'$number'.padLeft(5, '0')}',
    };
  }

  /// Generates an insurance type: `nhis` (national health insurance, 80%),
  /// `medicalAid1` (3%), `medicalAid2` (2%), or `uninsured` (15%).
  ///
  /// The codes are the categories of Korean health insurance (건강보험,
  /// 의료급여) and stay the same in every language; the labels come from the
  /// data of the language, so other languages read a neutral name such as
  /// `National insurance` through the English fallback.
  ({String code, String label}) insuranceType() {
    final code = _weighted(const <(String, int)>[
      ('nhis', 80),
      ('medicalAid1', 3),
      ('medicalAid2', 2),
      ('uninsured', 15),
    ]);
    return (code: code, label: label(code));
  }

  /// Generates a visit purpose with a sub-purpose.
  ///
  /// [purposeId] and [detailId] match the ids of [visitPurposeTree].
  ({String purpose, String detail, int purposeId, int detailId})
  visitPurpose() {
    final spec = faker.random.pick(data.visitPurposes);
    final detail = faker.random.pick(spec.details);
    final tree = visitPurposeTree();
    final parent = tree.firstWhere(
      (n) => n.parentId == null && n.name == spec.name,
    );
    final child = tree.firstWhere(
      (n) => n.parentId == parent.id && n.name == detail,
    );
    return (
      purpose: spec.name,
      detail: detail,
      purposeId: parent.id,
      detailId: child.id,
    );
  }

  /// The visit purpose tree: top-level purposes (ids 1..n, with a color)
  /// followed by their sub-purposes (`시술 › 레이저`). Does not consume the
  /// random stream, so ids are stable.
  List<CoFakeVisitPurposeNode> visitPurposeTree() {
    final nodes = <CoFakeVisitPurposeNode>[];
    final purposes = data.visitPurposes;
    for (var i = 0; i < purposes.length; i++) {
      nodes.add((
        id: i + 1,
        parentId: null,
        name: purposes[i].name,
        color:
            CoFakerClinicOps.palette[(i + 2) % CoFakerClinicOps.palette.length],
      ));
    }
    var next = purposes.length + 1;
    for (var i = 0; i < purposes.length; i++) {
      for (final detail in purposes[i].details) {
        nodes.add((id: next++, parentId: i + 1, name: detail, color: null));
      }
    }
    return nodes;
  }

  /// The procedure catalog of the current locale.
  List<CoProcedureSpec> get procedures => data.procedures;

  /// Generates a procedure priced within its band, rounded to
  /// [CoClinicPriceScale.priceRounding] (1,000 won, or 5 dollars). [code]
  /// selects a specific catalog entry.
  CoFakeProcedure procedure({String? code, String? category}) {
    var candidates = data.procedures;
    if (code != null) {
      candidates = candidates.where((p) => p.code == code).toList();
    } else if (category != null) {
      candidates = candidates
          .where((p) => p.category.startsWith(category))
          .toList();
    }
    if (candidates.isEmpty) {
      throw ArgumentError('no procedure matches code=$code category=$category');
    }
    final spec = faker.random.pick(candidates);
    return (
      code: spec.code,
      category: spec.category,
      name: spec.name,
      unit: spec.unit,
      price: _price(spec.minPrice, spec.maxPrice),
      taxable: spec.taxable,
    );
  }

  /// Generates a session package offer discounted 15-40% from the single
  /// session price.
  CoFakePackage package({String? procedureCode}) {
    final line = procedure(code: procedureCode);
    final sessions = faker.random.pick(const <int>[3, 5, 5, 10]);
    final discount = faker.random.int(min: 60, max: 85) / 100;
    final price = _roundTo(
      (line.price * sessions * discount).round(),
      _scale.packageRounding,
    );
    return (
      name: data.packageNameFormat
          .replaceAll('{name}', line.name)
          .replaceAll('{sessions}', '$sessions'),
      procedureCode: line.code,
      sessions: sessions,
      price: price,
      validDays: sessions >= 10 ? 365 : 180,
    );
  }

  /// Generates a package a patient bought within the last year, with the
  /// sessions used so far and its expiry.
  CoFakePackageBalance packageBalance({String? procedureCode}) {
    final offer = package(procedureCode: procedureCode);
    final purchasedAt = _dayStart(
      faker.date.past(days: offer.validDays ~/ 2, utc: faker.now.isUtc),
    );
    final used = faker.random.int(max: offer.sessions);
    return (
      name: offer.name,
      procedureCode: offer.procedureCode,
      totalSessions: offer.sessions,
      usedSessions: used,
      remainingSessions: offer.sessions - used,
      purchasedAt: purchasedAt,
      expiresAt: purchasedAt.add(Duration(days: offer.validDays)),
    );
  }

  /// Generates a prepaid balance (선수금): up to a hundred times
  /// [CoClinicPriceScale.prepaidStep] (10,000 won, or 10 dollars).
  int prepaidBalance() {
    return faker.random.int(max: 100) * _scale.prepaidStep;
  }

  /// Generates a diagnosis from an illustrative subset of public ICD-10 /
  /// KCD codes.
  ///
  /// The subset is for fixtures and screens only. It is not a claim-grade
  /// master: validate real claims against the official KCD release.
  CoDiagnosisSpec diagnosis() => faker.random.pick(data.diagnoses);

  /// Generates a fictional drug name such as `루미솔정 10mg`.
  ///
  /// The stems are invented; they are not marketed products.
  String drugName() {
    final stem = faker.random.pick(data.drugStems);
    final form = faker.random.pick(data.drugForms);
    final strength = faker.random.pick(form.strengths);
    return '$stem${form.form} $strength${form.unit}';
  }

  /// Generates a fictional prescription line.
  CoFakePrescription prescription() {
    final days = faker.random.pick(const <int>[3, 5, 7, 14, 28]);
    return (
      name: drugName(),
      usage: faker.random.pick(data.drugUsages),
      days: days,
      quantity: days * faker.random.int(min: 1, max: 3),
    );
  }

  /// Generates a short chart memo.
  String chartMemo() => faker.random.pick(data.memos);

  /// Generates a SOAP note. [diagnosis] fixes the assessment line.
  CoFakeSoap soap({CoDiagnosisSpec? diagnosis}) {
    final dx = diagnosis ?? this.diagnosis();
    return (
      subjective: faker.random.pick(data.complaints),
      objective: faker.random.pick(data.findings),
      assessment: '${dx.name} (${dx.code})',
      plan: faker.random.pick(data.plans),
    );
  }

  /// Generates [count] intake questionnaire answers (all questions when
  /// [count] is `null`). The first option of each question is the most
  /// common answer.
  List<({String question, String answer})> questionnaire({int? count}) {
    final questions = data.questions;
    final total = count == null || count > questions.length
        ? questions.length
        : count;
    return <({String question, String answer})>[
      for (final q in questions.take(total))
        (
          question: q.question,
          answer: faker.random.double() < 0.6
              ? q.options.first
              : faker.random.pick(q.options),
        ),
    ];
  }

  /// Returns the appointment slots of [day] under [hours].
  ///
  /// This does not consume the random stream. The slots share the time zone
  /// kind (UTC or local) of [day], so pass a UTC day to get UTC slots.
  List<DateTime> businessSlots(
    DateTime day, {
    CoClinicHours hours = const CoClinicHours(),
  }) {
    if (hours.interval <= 0) {
      throw ArgumentError.value(hours.interval, 'interval', 'must be > 0');
    }
    if (day.weekday == DateTime.sunday) return const <DateTime>[];
    final saturday = day.weekday == DateTime.saturday;
    final close = saturday ? hours.saturdayClose : hours.close;
    if (close == null) return const <DateTime>[];
    final slots = <DateTime>[];
    for (var m = hours.open; m + hours.interval <= close; m += hours.interval) {
      final lunchStart = hours.lunchStart;
      final lunchEnd = hours.lunchEnd;
      final inLunch =
          !saturday &&
          lunchStart != null &&
          lunchEnd != null &&
          m + hours.interval > lunchStart &&
          m < lunchEnd;
      if (!inLunch) slots.add(_at(day, m));
    }
    return slots;
  }

  /// Generates an appointment start on a business day within [days] days of
  /// `faker.now` (the past when [days] is negative).
  DateTime appointmentSlot({
    int days = 14,
    CoClinicHours hours = const CoClinicHours(),
  }) {
    for (var attempt = 0; attempt < 32; attempt++) {
      final offset = days >= 0
          ? faker.random.int(max: days)
          : -faker.random.int(max: -days);
      final day = _dayStart(faker.now).add(Duration(days: offset));
      final slots = businessSlots(day, hours: hours);
      if (slots.isNotEmpty) return faker.random.pick(slots);
    }
    throw StateError('no business day found; check CoClinicHours');
  }

  /// Visit stage codes in flow order: `reception`, `waiting`,
  /// `consultation`, `counseling`, `procedure`, `care`, `payment`, `done`.
  static const List<String> visitStages = <String>[
    'reception',
    'waiting',
    'consultation',
    'counseling',
    'procedure',
    'care',
    'payment',
    'done',
  ];

  /// Generates a plausible visit flow: check-in, waiting, one to three
  /// care stages, payment, and done.
  List<String> visitFlow() {
    final middle = <String>[
      if (faker.random.double() < 0.4) 'counseling',
      'consultation',
      if (faker.random.double() < 0.6) 'procedure',
      if (faker.random.double() < 0.3) 'care',
    ];
    return <String>['reception', 'waiting', ...middle, 'payment', 'done'];
  }

  /// Generates a current visit stage for a waiting-room board.
  String visitStage() {
    return _weighted(const <(String, int)>[
      ('waiting', 30),
      ('consultation', 15),
      ('counseling', 10),
      ('procedure', 15),
      ('care', 8),
      ('payment', 10),
      ('done', 12),
    ]);
  }

  /// Generates a reservation status that is plausible for [at]: future
  /// appointments are booked, confirmed, requested, or cancelled; past ones
  /// are completed, no-show, or cancelled.
  String reservationStatus({DateTime? at}) {
    final time = at ?? faker.now;
    if (time.isAfter(faker.now)) {
      return _weighted(const <(String, int)>[
        ('reserved', 45),
        ('confirmed', 35),
        ('requested', 10),
        ('cancelled', 8),
        ('rejected', 2),
      ]);
    }
    return _weighted(const <(String, int)>[
      ('completed', 82),
      ('noShow', 8),
      ('cancelled', 10),
    ]);
  }

  /// Writes [amount] in the currency of the current data, the way the texts
  /// of the generators do: `$1,234` for English, `1,234` for Korean
  /// ([CoFakerClinicData.currency]).
  String money(int amount) => data.currency.format(amount);

  /// Generates one payment of [amount]. [method] forces `card`, `cash`,
  /// `transfer`, or `prepaid`; otherwise card is the most common.
  CoFakePayment payment({required int amount, String? method}) {
    final resolved =
        method ??
        _weighted<String>(const <(String, int)>[
          ('card', 72),
          ('cash', 8),
          ('transfer', 8),
          ('prepaid', 12),
        ]);
    final card = resolved == 'card';
    return (
      method: resolved,
      methodLabel: label(resolved),
      amount: amount,
      cardIssuer: card ? faker.random.pick(data.cardIssuers) : null,
      installmentMonths: card
          ? (amount >= _scale.installmentMinimum
                ? faker.random.pick(const <int>[0, 0, 2, 3, 6])
                : 0)
          : null,
      approvalNo: card ? _approvalNo() : null,
      cashReceiptNo: resolved == 'cash' || resolved == 'transfer'
          ? _cashReceiptNo()
          : null,
    );
  }

  /// Splits [amount] into one to three payments, for example part prepaid
  /// balance and the rest by card. The amounts always add up to [amount].
  List<CoFakePayment> splitPayment({required int amount}) {
    final parts = amount < _scale.splitMinimum
        ? 1
        : _weighted(const <(int, int)>[(1, 75), (2, 20), (3, 5)]);
    if (parts == 1) return <CoFakePayment>[payment(amount: amount)];
    final unit = _scale.splitRounding;
    final result = <CoFakePayment>[];
    var remaining = amount;
    for (var i = 0; i < parts - 1; i++) {
      final share = _roundTo(
        (remaining * faker.random.int(min: 20, max: 60) / 100).round(),
        unit,
      );
      if (share <= 0 || share >= remaining) break;
      result.add(payment(amount: share, method: i == 0 ? 'prepaid' : 'cash'));
      remaining -= share;
    }
    result.add(payment(amount: remaining, method: 'card'));
    return result;
  }

  /// Consent form kinds of the current locale (`procedure`, `privacy`,
  /// `photo`, `marketing`, `anesthesia` in Korean).
  List<String> get consentKinds =>
      texts.consentForms.map((f) => f.kind).toList();

  /// Generates a consent form. The clauses are **example text, not a
  /// legally reviewed document**; [CoFakeConsentForm.disclaimer] says so
  /// and should be shown wherever the form is rendered.
  CoFakeConsentForm consentForm({String? kind}) {
    final forms = kind == null
        ? texts.consentForms
        : texts.consentForms.where((f) => f.kind == kind).toList();
    if (forms.isEmpty) throw ArgumentError.value(kind, 'kind');
    final form = faker.random.pick(forms);
    return (
      kind: form.kind,
      title: form.title,
      clauses: form.clauses,
      disclaimer: texts.consentDisclaimer,
    );
  }

  /// Generates a satisfaction answer: positive 70%, neutral 20%, negative
  /// 10% unless [sentiment] is given. Scores are 4-5, 3-4, and 1-2.
  CoFakeFeedback feedback({String? sentiment}) {
    final resolved =
        sentiment ??
        _weighted<String>(const <(String, int)>[
          ('positive', 70),
          ('neutral', 20),
          ('negative', 10),
        ]);
    final comments = texts.feedback[resolved];
    if (comments == null || comments.isEmpty) {
      throw ArgumentError.value(sentiment, 'sentiment');
    }
    final score = switch (resolved) {
      'positive' => faker.random.int(min: 4, max: 5),
      'neutral' => faker.random.int(min: 3, max: 4),
      _ => faker.random.int(min: 1, max: 2),
    };
    return (
      sentiment: resolved,
      score: score,
      comment: faker.random.pick(comments),
    );
  }

  /// Counseling topic codes (`toning`, `lifting`, `botox`, ...).
  List<String> get counselTopics =>
      texts.counselTopics.map((t) => t.topic).toList();

  /// Generates a recorded counseling session (AI counseling transcript):
  /// greeting, concern, recommendation, two or three patient questions,
  /// a price quote, and a booking decision, with timestamps.
  CoFakeCounselSession counselSession({String? topic}) {
    final topics = topic == null
        ? texts.counselTopics
        : texts.counselTopics.where((t) => t.topic == topic).toList();
    if (topics.isEmpty) throw ArgumentError.value(topic, 'topic');
    final spec = faker.random.pick(topics);
    final script = texts.counselScript;
    final matching = data.procedures.where((p) => p.code == spec.procedureCode);
    final price = matching.isEmpty
        ? _price(_scale.quoteMin, _scale.quoteMax)
        : procedure(code: spec.procedureCode).price;
    final packagePrice = _roundTo(
      (price * spec.sessions * faker.random.int(min: 65, max: 85) / 100)
          .round(),
      _scale.packageRounding,
    );
    final answers = <String, String>{
      'pain': spec.pain,
      'interval': spec.interval,
      'downtime': spec.downtime,
      'price': script.priceAnswer
          .replaceAll('{price}', money(price))
          .replaceAll('{sessions}', '${spec.sessions}')
          .replaceAll('{packagePrice}', money(packagePrice)),
    };
    final asked = <String>[...answers.keys.where((k) => k != 'price')];
    final questions = <String>[
      for (var i = 0; i < 1 + faker.random.int(max: 1); i++)
        asked.removeAt(faker.random.int(max: asked.length - 1)),
      'price',
    ];
    final booked = faker.random.double() < 0.6;
    final lines = <(String, String)>[
      ('counselor', script.greeting),
      ('patient', spec.concern),
      ('counselor', spec.recommend),
      for (final q in questions) ...[
        ('patient', script.questions[q] ?? q),
        ('counselor', answers[q]!),
      ],
      ('patient', booked ? script.bookYes : script.bookNo),
      ('counselor', booked ? script.bookYesReply : script.bookNoReply),
    ];
    var elapsed = 0;
    final turns = <CoFakeTurn>[];
    for (final line in lines) {
      turns.add((
        speaker: line.$1,
        text: line.$2,
        at: Duration(seconds: elapsed),
        language: null,
        translation: null,
      ));
      elapsed += 4 + line.$2.length ~/ 3 + faker.random.int(max: 20);
    }
    return (
      topic: spec.topic,
      procedureCode: spec.procedureCode,
      procedure: spec.procedure,
      turns: turns,
      summary: script.summary
          .replaceAll('{procedure}', spec.procedure)
          .replaceAll('{price}', money(price))
          .replaceAll('{sessions}', '${spec.sessions}')
          .replaceAll('{packagePrice}', money(packagePrice))
          .replaceAll('{outcome}', booked ? script.booked : script.pending),
      quotedPrice: price,
      packagePrice: packagePrice,
      sessions: spec.sessions,
      booked: booked,
    );
  }

  /// Languages supported by [inquiry]: `ko`, `en`, `ja`, `zh`, `vi`.
  static List<String> get inquiryLanguages =>
      CoFakerClinicTexts.inquiries.keys.toList();

  /// Generates a messenger inquiry thread in [language] (random when
  /// omitted): alternating patient questions and staff replies, both in the
  /// patient's language, on the channel that language usually uses.
  ///
  /// This is independent of the faker locale, because one Korean clinic
  /// inbox receives messages in many languages. Every turn carries its
  /// [CoFakeTurn.language] and, for non-Korean threads, the Korean
  /// [CoFakeTurn.translation].
  CoFakeInquiry inquiry({String? language, int exchanges = 2}) {
    final lang =
        language ??
        _weighted<String>(const <(String, int)>[
          ('ko', 40),
          ('ja', 20),
          ('zh', 20),
          ('en', 12),
          ('vi', 8),
        ]);
    final pool = CoFakerClinicTexts.inquiries[lang];
    if (pool == null) throw ArgumentError.value(language, 'language');
    final korean = CoFakerClinicTexts.inquiries['ko']!;
    final remaining = <int>[for (var i = 0; i < pool.length; i++) i];
    final count = exchanges.clamp(1, pool.length);
    final turns = <CoFakeTurn>[];
    var minutes = 0;
    for (var i = 0; i < count; i++) {
      final index = remaining.removeAt(
        faker.random.int(max: remaining.length - 1),
      );
      final item = pool[index];
      final ko = lang == 'ko' || index >= korean.length ? null : korean[index];
      turns
        ..add((
          speaker: 'patient',
          text: item.question,
          at: Duration(minutes: minutes),
          language: lang,
          translation: ko?.question,
        ))
        ..add((
          speaker: 'staff',
          text: item.answer,
          at: Duration(minutes: minutes + faker.random.int(min: 1, max: 30)),
          language: lang,
          translation: ko?.answer,
        ));
      minutes += 31 + faker.random.int(max: 60);
    }
    final channel = CoFakerClinicTexts.preferredChannels[lang] ?? 'kakao';
    return (
      language: lang,
      channel: channel,
      handle: messengerHandle(channel: channel, language: lang),
      turns: turns,
    );
  }

  /// Generates a messenger handle such as `@minji_0312` for [channel]
  /// (`kakao`, `line`, `wechat`, `whatsapp`, `zalo`, `instagram`), using a
  /// given name typical of [language] (`ko`, `en`, `ja`, `zh`, `vi`).
  /// WhatsApp handles are fictional `+1 555-01##` numbers.
  String messengerHandle({String channel = 'kakao', String language = 'ko'}) {
    if (channel == 'whatsapp') {
      return faker.random.digits('+1 555-01##');
    }
    final stems = _handleStems[language];
    final name = stems != null
        ? faker.random.pick(stems)
        : CoFakerPerson.romanize(
            faker.person.firstName(),
          ).toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final base = name.isEmpty ? 'user' : name;
    final suffix = faker.random.digits('####');
    return switch (channel) {
      'wechat' => 'wxid_$base$suffix',
      'instagram' => '@$base.$suffix',
      _ => '@${base}_$suffix',
    };
  }

  /// Latin handle stems for languages whose names are not Hangul or Latin.
  static const Map<String, List<String>> _handleStems = <String, List<String>>{
    'ja': <String>['yui', 'haruto', 'sakura', 'ren', 'aoi', 'mei', 'sora'],
    'zh': <String>['xiaomei', 'weiwei', 'lina', 'haoran', 'yuxin', 'jiahui'],
    'vi': <String>['linh', 'trang', 'minhanh', 'huong', 'tuan', 'ngoc'],
    'en': <String>['emma', 'olivia', 'liam', 'noah', 'mia', 'lucas'],
  };

  /// Generates a fictional private insurer name.
  String insurerName() => faker.random.pick(texts.insurers);

  /// Services supported by [integrationResult].
  List<String> get integrationServices =>
      texts.integrationResults.keys.toList();

  /// Generates a public integration result for [service] (`eligibility`,
  /// `dur`, `insuranceClaim`, `ePrescription`, `identityQr`); successes are
  /// about 80% of results. The messages are illustrative examples, not the
  /// official texts of any agency.
  CoFakeIntegrationResult integrationResult({String? service}) {
    final resolved = service ?? faker.random.pick<String>(integrationServices);
    final results = texts.integrationResults[resolved];
    if (results == null || results.isEmpty) {
      throw ArgumentError.value(service, 'service');
    }
    final ok = results.where((r) => r.ok).toList();
    final failed = results.where((r) => !r.ok).toList();
    final pickOk =
        failed.isEmpty || (ok.isNotEmpty && faker.random.double() < 0.8);
    final result = faker.random.pick(pickOk ? ok : failed);
    return (
      service: resolved,
      code: result.code,
      message: result.message,
      ok: result.ok,
    );
  }

  /// Device kind codes generated by [device].
  static const List<String> deviceKinds = <String>[
    'picoLaser',
    'hifu',
    'rf',
    'ipl',
    'ledTherapy',
    'skinAnalyzer',
    'photoCamera',
    'labelPrinter',
    'cardTerminal',
    'signaturePad',
    'kiosk',
    'bridgePc',
  ];

  /// Generates a clinic device with a fictional vendor and model name.
  ///
  /// Vendors and models are invented to avoid trademarks; [number] numbers
  /// the unit within the clinic (`피코 레이저 2호기`).
  CoFakeDevice device({String? kind, int? number}) {
    final resolved = kind ?? faker.random.pick<String>(deviceKinds);
    final vendor = faker.random.pick(_vendors);
    final kindLabel = label(resolved);
    final model = resolved == 'bridgePc'
        ? 'EMR-BRIDGE-${faker.random.digits('##')}'
        : '${vendor.substring(0, 3).toUpperCase()}-'
              '${resolved.substring(0, 1).toUpperCase()}'
              '${faker.random.int(min: 10, max: 99) * 10}'
              '${faker.random.pick(const <String>['', '', ' Pro', ' S', ' II'])}';
    return (
      kind: resolved,
      kindLabel: kindLabel,
      name: texts.deviceNameFormat
          .replaceAll('{kind}', kindLabel)
          .replaceAll(
            '{number}',
            '${number ?? faker.random.int(min: 1, max: 3)}',
          ),
      vendor: vendor,
      model: model,
      serial:
          'SN-${faker.random.string(4, alphabet: _serialAlphabet)}-'
          '${faker.random.string(4, alphabet: _serialAlphabet)}',
    );
  }

  /// Generates a chart collaboration note with an `@` mention of a staff
  /// member, such as a handoff between the counselor and the nurse.
  /// [patient] defaults to a generated name.
  ///
  /// Pass [authors] and [mentions] (staff display names from your own
  /// fixture) to pick the author and the mentioned person from them; the
  /// author is never mentioned when another name is available. Without
  /// them, invented staff are used and the mention carries a role title.
  CoFakeTeamNote teamNote({
    String? patient,
    List<String>? authors,
    List<String>? mentions,
  }) {
    final template = faker.random.pick(texts.teamNotes);
    final patientName = patient ?? faker.person.fullName();
    final String author;
    final String mentioned;
    final String mention;
    if (authors == null && mentions == null) {
      final staffMember = staff();
      author = faker.person.fullName();
      mentioned = staffMember.name;
      mention = texts.staffMentionFormat
          .replaceAll('{name}', mentioned)
          .replaceAll('{role}', staffMember.roleLabel);
    } else {
      final authorPool = authors ?? mentions!;
      final mentionPool = mentions ?? authors!;
      if (authorPool.isEmpty || mentionPool.isEmpty) {
        throw ArgumentError('authors and mentions must not be empty');
      }
      author = faker.random.pick(authorPool);
      final others = mentionPool.where((n) => n != author).toList();
      mentioned = faker.random.pick(others.isEmpty ? mentionPool : others);
      mention = texts.nameMentionFormat.replaceAll('{name}', mentioned);
    }
    return (
      text: template
          .replaceAll('{mention}', mention)
          .replaceAll('{patient}', patientName),
      author: author,
      mentions: <String>[mentioned],
    );
  }

  /// Generates an internal staff notice of [kind] (`training`, `policy`,
  /// or `schedule`; random when omitted).
  ({String kind, String title, String body}) staffNotice({String? kind}) {
    final notices = ops.staffNotices.isEmpty
        ? CoFakerClinicOps.english.staffNotices
        : ops.staffNotices;
    final resolved = kind ?? faker.random.pick<String>(notices.keys.toList());
    final pool = notices[resolved];
    if (pool == null || pool.isEmpty) throw ArgumentError.value(kind, 'kind');
    final notice = faker.random.pick(pool);
    return (kind: resolved, title: notice.title, body: notice.body);
  }

  /// Returns a vital sign observation note (no mentions) for [vitals]
  /// (generated when omitted). The first abnormal finding wins: high blood
  /// pressure (≥140/90), fever (≥37.5 °C), low SpO2 (<95%), or high
  /// glucose (≥140 mg/dL); otherwise a stable summary.
  String vitalsNote({CoFakeVitals? vitals}) {
    final v = vitals ?? this.vitals();
    final notes = ops.vitalsNotes.isEmpty
        ? CoFakerClinicOps.english.vitalsNotes
        : ops.vitalsNotes;
    final key = v.systolic >= 140 || v.diastolic >= 90
        ? 'highBp'
        : v.temperature >= 37.5
        ? 'fever'
        : v.spo2 < 95
        ? 'lowSpo2'
        : v.glucose >= 140
        ? 'highGlucose'
        : 'normal';
    return (notes[key] ?? notes['normal']!)
        .replaceAll('{sys}', '${v.systolic}')
        .replaceAll('{dia}', '${v.diastolic}')
        .replaceAll('{pulse}', '${v.pulse}')
        .replaceAll('{spo2}', '${v.spo2}')
        .replaceAll('{temp}', v.temperature.toStringAsFixed(1))
        .replaceAll('{glucose}', '${v.glucose}');
  }

  /// Generates a closure notice for [date].
  ///
  /// When [date] is a Korean public holiday (2024-2030, see
  /// [CoFakerKorea.holidays]) the notice covers the whole holiday stretch
  /// (for example all three days of Chuseok plus a substitute holiday) and
  /// names it; otherwise it gives a reason such as a conference. Sundays
  /// are skipped when computing the reopening day.
  ///
  /// The holiday calendar is Korean. Korean data and English data (which has
  /// always used it) read it, with [CoFakerClinicOps.holidayNames] naming the
  /// two big stretches; data whose [CoFakerClinicData.koreanValues] is
  /// [CoKoreanValues.none] has no public holidays, so its notices always give
  /// a reason. Dates are written with [CoFakerClinicOps.dateFormat].
  ({DateTime from, DateTime to, String? holiday, String title, String body})
  closureNotice({required DateTime date, String? clinicName}) {
    final texts = ops.closure.isEmpty
        ? CoFakerClinicOps.english.closure
        : ops.closure;
    final reasons = ops.closureReasons.isEmpty
        ? CoFakerClinicOps.english.closureReasons
        : ops.closureReasons;
    final day = DateTime.utc(date.year, date.month, date.day);
    final (first, last) = CoFakerKorea.holidayYears;
    final inRange =
        _values != CoKoreanValues.none && day.year >= first && day.year <= last;
    final all = inRange
        ? <CoKoreanHoliday>[
            ...CoFakerKorea.holidays(year: day.year),
            if (day.year < last) ...CoFakerKorea.holidays(year: day.year + 1),
          ]
        : const <CoKoreanHoliday>[];
    final closed = {for (final h in all) h.date};
    final hits = all.where((h) => h.date == day).toList();
    var from = day;
    var to = day;
    String? holiday;
    if (hits.isNotEmpty) {
      bool off(DateTime d) =>
          closed.contains(d) || d.weekday == DateTime.sunday;
      while (off(from.subtract(const Duration(days: 1))) &&
          closed.contains(from.subtract(const Duration(days: 1)))) {
        from = from.subtract(const Duration(days: 1));
      }
      while (off(to.add(const Duration(days: 1)))) {
        to = to.add(const Duration(days: 1));
      }
      final main = all.firstWhere(
        (h) => !h.date.isBefore(from) && !h.date.isAfter(to) && !h.substitute,
        orElse: () => hits.first,
      );
      final names = ops.holidayNames.isEmpty
          ? CoFakerClinicOps.english.holidayNames
          : ops.holidayNames;
      holiday = names[main.block] ?? main.name;
    }
    var reopen = to.add(const Duration(days: 1));
    while (reopen.weekday == DateTime.sunday || closed.contains(reopen)) {
      reopen = reopen.add(const Duration(days: 1));
    }
    final clinic = clinicName ?? this.clinicName();
    final dates = from == to
        ? _dateLabel(from)
        : ops.dateRangeFormat
              .replaceAll('{from}', _dateLabel(from))
              .replaceAll('{to}', _dateLabel(to));
    final reason = holiday == null ? faker.random.pick(reasons) : '';
    final body = (holiday == null ? texts['other']! : texts['holiday']!)
        .replaceAll('{eun}', _particle(clinic, '은', '는'))
        .replaceAll('{ro}', _particle(holiday ?? reason, '으로', '로'))
        .replaceAll('{clinic}', clinic)
        .replaceAll('{dates}', dates)
        .replaceAll('{name}', holiday ?? '')
        .replaceAll('{reason}', reason)
        .replaceAll('{reopen}', _dateLabel(reopen));
    return (
      from: from,
      to: to,
      holiday: holiday,
      title: texts['title']!.replaceAll('{dates}', dates),
      body: body,
    );
  }

  /// Picks the Korean particle for [word]: [withFinal] after a final
  /// consonant (except ㄹ for 으로/로), [withoutFinal] otherwise. Uses the
  /// last Hangul syllable, ignoring trailing brackets.
  static String _particle(String word, String withFinal, String withoutFinal) {
    for (final rune in word.runes.toList().reversed) {
      final index = rune - 0xAC00;
      if (index < 0 || index > 11171) continue;
      final jong = index % 28;
      if (jong == 0) return withoutFinal;
      if (jong == 8 && withFinal == '으로') return withoutFinal;
      return withFinal;
    }
    return withoutFinal;
  }

  String _dateLabel(DateTime d) {
    final weekdays = ops.weekdayNames.length == 7
        ? ops.weekdayNames
        : CoFakerClinicOps.english.weekdayNames;
    return ops.dateFormat
        .replaceAll('{month}', '${d.month}')
        .replaceAll('{day}', '${d.day}')
        .replaceAll('{weekday}', weekdays[d.weekday - 1]);
  }

  /// Family relation codes: `self`, `spouse`, `parent`, `child`,
  /// `sibling`, `grandparent`, `grandchild`, `legalGuardian`, `other`.
  static const List<String> relations = <String>[
    'self',
    'spouse',
    'parent',
    'child',
    'sibling',
    'grandparent',
    'grandchild',
    'legalGuardian',
    'other',
  ];

  /// Generates a family relation code with its label.
  ({String code, String label}) familyRelation() {
    final code = faker.random.pick(relations);
    return (code: code, label: label(code));
  }

  /// Generates a guardian or family contact plausible for a patient of
  /// [patientAge]: parents for minors, children or spouses for the elderly,
  /// mostly spouses otherwise.
  CoFakeGuardian guardian({int? patientAge}) {
    final age = patientAge ?? 35;
    final relation = age < 19
        ? _weighted<String>(const <(String, int)>[
            ('parent', 88),
            ('grandparent', 7),
            ('legalGuardian', 5),
          ])
        : age >= 70
        ? _weighted<String>(const <(String, int)>[
            ('child', 60),
            ('spouse', 30),
            ('grandchild', 10),
          ])
        : _weighted<String>(const <(String, int)>[
            ('spouse', 50),
            ('parent', 20),
            ('sibling', 15),
            ('child', 10),
            ('other', 5),
          ]);
    final sex = faker.person.sex();
    return (
      name: faker.person.fullName(sex: sex),
      sex: sex,
      relation: relation,
      relationLabel: label(relation),
      phone: _phone(),
    );
  }

  // ── Patients ────────────────────────────────────────────────────────

  /// Generates a patient tag with its color.
  CoColoredLabelSpec patientTag() => faker.random.pick(ops.patientTags);

  /// Generates up to [max] distinct patient tags (possibly none).
  List<CoColoredLabelSpec> patientTags({int max = 2}) {
    final pool = [...ops.patientTags];
    final count = faker.random.int(max: max.clamp(0, pool.length));
    return <CoColoredLabelSpec>[
      for (var i = 0; i < count; i++)
        pool.removeAt(faker.random.int(max: pool.length - 1)),
    ];
  }

  /// Generates an acquisition channel (online booking, referral, ad, ...).
  CoColoredLabelSpec acquisitionChannel() =>
      faker.random.pick(ops.acquisitionChannels);

  /// Generates a chart special note such as an allergy or a caution.
  String specialNote() => faker.random.pick(ops.specialNotes);

  /// Masks a name for public screens: `김하늘` → `김*늘`, `김하` → `김*`,
  /// `남궁민수` → `남**수`. Latin names keep their first and last letter.
  static String maskName(String name) {
    final chars = name.runes.map(String.fromCharCode).toList();
    if (chars.length <= 1) return name;
    if (chars.length == 2) return '${chars.first}*';
    return '${chars.first}${'*' * (chars.length - 2)}${chars.last}';
  }

  /// Generates a masked patient name for waiting-room boards.
  String maskedName() => maskName(faker.person.fullName());

  // ── Consent ─────────────────────────────────────────────────────────

  /// Consent kind codes of consent history: `privacyRequired`,
  /// `marketingOptional`, `sensitiveInfo`, `photoUse`, `thirdParty`,
  /// `aiRecording`, `nightAdvertising`.
  static const List<String> consentHistoryKinds = <String>[
    'privacyRequired',
    'marketingOptional',
    'sensitiveInfo',
    'photoUse',
    'thirdParty',
    'aiRecording',
    'nightAdvertising',
  ];

  /// Generates a terms version (`v3.2`) with its effective date and
  /// revision note, [monthsAgo] months before `faker.now`.
  ({String version, DateTime effectiveFrom, String change}) termsVersion({
    int monthsAgo = 2,
  }) {
    final base = faker.now;
    final month = base.month - monthsAgo;
    final from = base.isUtc
        ? DateTime.utc(base.year, month)
        : DateTime(base.year, month);
    return (
      version:
          'v${faker.random.int(min: 1, max: 4)}.'
          '${faker.random.int(max: 9)}',
      effectiveFrom: from,
      change: faker.random.pick(ops.termsChanges),
    );
  }

  /// Generates a consent history of [count] events, oldest first: agreements
  /// on various channels, and occasional withdrawals of optional consents.
  List<CoFakeConsentEvent> consentHistory({int count = 5}) {
    final from = faker.now.subtract(Duration(days: 30 * count));
    final times = <DateTime>[
      for (var i = 0; i < count; i++)
        faker.date.between(from, faker.now, utc: faker.now.isUtc),
    ]..sort();
    final agreed = <String>{};
    final result = <CoFakeConsentEvent>[];
    for (var i = 0; i < count; i++) {
      final optional = agreed.where((k) => k != 'privacyRequired').toList();
      final open = consentHistoryKinds
          .where((k) => !agreed.contains(k))
          .toList();
      final withdraw =
          optional.isNotEmpty && (open.isEmpty || faker.random.double() < 0.25);
      final String kind;
      if (i == 0) {
        kind = 'privacyRequired';
      } else if (withdraw) {
        kind = faker.random.pick(optional);
      } else {
        kind = faker.random.pick(open);
      }
      if (withdraw && i > 0) {
        agreed.remove(kind);
      } else {
        agreed.add(kind);
      }
      final channel = faker.random.pick(const <String>[
        'tablet',
        'tablet',
        'online',
        'desk',
        'paper',
      ]);
      final action = withdraw && i > 0 ? 'withdrawn' : 'agreed';
      result.add((
        kind: kind,
        kindLabel: label(kind),
        channel: channel,
        channelLabel: label(channel),
        action: action,
        actionLabel: label(action),
        termsVersion: 'v3.${faker.random.int(max: 4)}',
        at: times[i],
      ));
    }
    return result;
  }

  /// Generates a consent request dispatch status (`sent`, `opened`,
  /// `signed`, `expired`, `failed`) with its message.
  ({String status, String message}) consentDispatch({String? status}) {
    final resolved =
        status ??
        _weighted<String>(const <(String, int)>[
          ('signed', 55),
          ('opened', 15),
          ('sent', 15),
          ('expired', 10),
          ('failed', 5),
        ]);
    final message = ops.consentDispatch[resolved];
    if (message == null) throw ArgumentError.value(status, 'status');
    return (status: resolved, message: message);
  }

  // ── Reception ───────────────────────────────────────────────────────

  /// Schedule and staff colors (`#RRGGBB`).
  static List<String> get palette => CoFakerClinicOps.palette;

  /// Returns the palette color of [index] (cycling), or a random one.
  String color({int? index}) => index == null
      ? faker.random.pick(CoFakerClinicOps.palette)
      : CoFakerClinicOps.palette[index % CoFakerClinicOps.palette.length];

  /// Returns the clinic room layout (ids from 1) with generated staff for
  /// attended rooms and a palette color per room.
  List<CoFakeRoom> rooms({bool includeReception = true}) {
    final specs = ops.rooms
        .where((r) => includeReception || r.kind != 'reception')
        .toList();
    return <CoFakeRoom>[
      for (var i = 0; i < specs.length; i++)
        (
          id: i + 1,
          name: specs[i].name,
          kind: specs[i].kind,
          kindLabel: label(specs[i].kind),
          staffName: specs[i].staffRole == null
              ? null
              : faker.person.fullName(),
          staffRole: specs[i].staffRole,
          color: color(index: i),
        ),
    ];
  }

  /// Queue status codes: `requested`, `waiting`, `priority`, `inProgress`.
  static const List<String> queueStatuses = <String>[
    'requested',
    'waiting',
    'priority',
    'inProgress',
  ];

  /// Generates a queue snapshot per room: at most one `inProgress` entry
  /// first, then `priority`, `waiting`, and `requested` entries, with
  /// check-in times 3-15 minutes apart ending before `faker.now`.
  ///
  /// [rooms] defaults to [CoFakerClinic.rooms] without the reception room;
  /// [count] is the number of entries per room (random 0-5 when omitted).
  List<CoFakeRoomQueue> queueBoard({List<CoFakeRoom>? rooms, int? count}) {
    final targets = rooms ?? this.rooms(includeReception: false);
    return <CoFakeRoomQueue>[
      for (final room in targets) _roomQueue(room, count),
    ];
  }

  CoFakeRoomQueue _roomQueue(CoFakeRoom room, int? count) {
    final size = count ?? faker.random.int(max: 5);
    final statuses = <String>[
      for (var i = 0; i < size; i++)
        i == 0 && faker.random.double() < 0.8
            ? 'inProgress'
            : _weighted<String>(const <(String, int)>[
                ('waiting', 70),
                ('priority', 10),
                ('requested', 20),
              ]),
    ];
    const rank = <String, int>{
      'inProgress': 0,
      'priority': 1,
      'waiting': 2,
      'requested': 3,
    };
    statuses.sort((a, b) => rank[a]!.compareTo(rank[b]!));
    var at = faker.now.subtract(
      Duration(minutes: 5 + faker.random.int(max: 10)),
    );
    final times = <DateTime>[];
    for (var i = 0; i < size; i++) {
      times.add(at);
      at = at.subtract(Duration(minutes: faker.random.int(min: 3, max: 15)));
    }
    return (
      roomId: room.id,
      roomName: room.name,
      roomKind: room.kind,
      entries: <CoFakeQueueEntry>[
        for (var i = 0; i < size; i++)
          (
            order: i + 1,
            patientName: faker.person.fullName(),
            status: statuses[i],
            statusLabel: label(statuses[i]),
            purpose: visitPurpose().detail,
            checkedInAt: times[size - 1 - i],
          ),
      ],
    );
  }

  /// Generates a reception request source: `tablet`, `kiosk`, `online`,
  /// `app`, or `desk`.
  ({String code, String label}) receptionSource() {
    final code = _weighted<String>(const <(String, int)>[
      ('tablet', 35),
      ('desk', 30),
      ('kiosk', 15),
      ('online', 12),
      ('app', 8),
    ]);
    return (code: code, label: label(code));
  }

  /// Generates a kiosk visit purpose (`checkin`, `reservation`, `payment`,
  /// `document`).
  ({String code, String label}) kioskPurpose() {
    final code = faker.random.pick(ops.kioskPurposes.keys.toList());
    return (code: code, label: ops.kioskPurposes[code]!);
  }

  // ── Chart ───────────────────────────────────────────────────────────

  /// Generates vital signs realistic for [age] (default adult) and [sex]:
  /// children are shorter and lighter, blood pressure rises with age, and
  /// a few readings are mildly abnormal.
  CoFakeVitals vitals({int? age, CoSex? sex}) {
    final years = age ?? faker.random.int(min: 20, max: 60);
    final male = (sex ?? faker.person.sex()) == CoSex.male;
    final double height;
    if (years < 18) {
      height = (75 + years * 6.2 + faker.random.double(min: -6, max: 6))
          .clamp(50, 185)
          .toDouble();
    } else {
      height = (male ? 173.0 : 160.5) + faker.random.double(min: -8, max: 8);
    }
    final bmi = years < 18
        ? faker.random.double(min: 14.5, max: 21)
        : faker.random.double(min: 18, max: 29);
    final weight = bmi * (height / 100) * (height / 100);
    final systolic =
        (years < 18 ? 100 : 108 + (years - 18) * 0.45) +
        faker.random.int(min: -10, max: 18);
    return (
      temperature: _round1(faker.random.double(min: 36.1, max: 37.4)),
      systolic: systolic.round(),
      diastolic: (systolic * 0.65 + faker.random.int(min: -6, max: 6)).round(),
      pulse: faker.random.int(
        min: years < 12 ? 75 : 58,
        max: years < 12 ? 115 : 96,
      ),
      spo2: faker.random.int(min: 95, max: 100),
      glucose: faker.random.int(min: 78, max: years >= 50 ? 135 : 115),
      heightCm: _round1(height),
      weightKg: _round1(weight),
      bmi: _round1(bmi),
    );
  }

  /// Region centers of the default `face` template of [canvasMarks], in
  /// normalized coordinates of a **square** canvas with a frontal face in
  /// standard proportions: hairline at y≈0.15, brows ≈0.33, eyes ≈0.42,
  /// nose tip ≈0.58, lips ≈0.74, chin ≈0.9, face width ≈0.24-0.76.
  /// "left" and "right" are as seen by the viewer.
  static const Map<String, (double, double)> faceRegions =
      <String, (double, double)>{
        'forehead': (0.5, 0.22),
        'glabella': (0.5, 0.36),
        'leftEye': (0.36, 0.42),
        'rightEye': (0.64, 0.42),
        'leftCheek': (0.32, 0.58),
        'rightCheek': (0.68, 0.58),
        'nose': (0.5, 0.55),
        'lips': (0.5, 0.74),
        'leftJaw': (0.3, 0.8),
        'rightJaw': (0.7, 0.8),
        'chin': (0.5, 0.88),
      };

  /// Region rectangles of the `faceFront` template: a frontal face on a
  /// 3:4 (width:height) portrait canvas, head from y 0.12 to chin 0.72 and
  /// face width 0.21-0.79, matching the clinic-emr chart `faceFront`
  /// outline (brows ≈0.33, eyes ≈0.40, nose 0.42-0.56, lips ≈0.61).
  static const Map<String, CoRegionRect> faceFrontRegions =
      <String, CoRegionRect>{
        'forehead': (left: 0.30, top: 0.15, right: 0.70, bottom: 0.30),
        'glabella': (left: 0.45, top: 0.31, right: 0.55, bottom: 0.38),
        'leftEye': (left: 0.30, top: 0.37, right: 0.45, bottom: 0.44),
        'rightEye': (left: 0.55, top: 0.37, right: 0.70, bottom: 0.44),
        'nose': (left: 0.45, top: 0.42, right: 0.55, bottom: 0.56),
        'leftCheek': (left: 0.24, top: 0.45, right: 0.40, bottom: 0.58),
        'rightCheek': (left: 0.60, top: 0.45, right: 0.76, bottom: 0.58),
        'lips': (left: 0.40, top: 0.58, right: 0.60, bottom: 0.65),
        'leftJaw': (left: 0.26, top: 0.58, right: 0.38, bottom: 0.68),
        'rightJaw': (left: 0.62, top: 0.58, right: 0.74, bottom: 0.68),
        'chin': (left: 0.43, top: 0.66, right: 0.57, bottom: 0.72),
      };

  /// Generates pen chart marks in normalized `0..1` coordinates: pen
  /// circles around procedure regions plus a highlighter swipe. Scale with
  /// [CoFakerSignature.toOpenBoardPoints] (`width`/`height`) to feed
  /// `open_board`.
  ///
  /// Regions come from, in priority order:
  /// - [regionRects]: your own rectangles (for example your chart
  ///   template's layout); each mark is an ellipse inside its rectangle.
  /// - [template] `faceFront`: [faceFrontRegions] (3:4 canvas), also
  ///   ellipses inside the rectangles.
  /// - [template] `face` (default): circles around [faceRegions] centers.
  ///
  /// [regions] picks the marked region names (two or three random ones
  /// when omitted).
  List<CoFakeCanvasMark> canvasMarks({
    String template = 'face',
    List<String>? regions,
    Map<String, CoRegionRect>? regionRects,
  }) {
    final rects =
        regionRects ?? (template == 'faceFront' ? faceFrontRegions : null);
    if (rects == null && template != 'face') {
      throw ArgumentError.value(template, 'template');
    }
    if (rects != null && rects.isEmpty) {
      throw ArgumentError.value(
        regionRects,
        'regionRects',
        'must not be empty',
      );
    }
    final names = rects?.keys.toList() ?? faceRegions.keys.toList();
    final picked =
        regions ??
        <String>[
          for (
            var i = 0;
            i < 2 + faker.random.int(max: 1) && names.isNotEmpty;
            i++
          )
            names.removeAt(faker.random.int(max: names.length - 1)),
        ];
    var time = faker.now.millisecondsSinceEpoch;
    final marks = <CoFakeCanvasMark>[];
    for (final region in picked) {
      final double cx;
      final double cy;
      final double rx;
      final double ry;
      if (rects != null) {
        final rect = rects[region];
        if (rect == null) throw ArgumentError.value(region, 'regions');
        final halfW = (rect.right - rect.left) / 2;
        final halfH = (rect.bottom - rect.top) / 2;
        final scale = faker.random.double(min: 0.6, max: 0.8);
        rx = halfW * scale;
        ry = halfH * scale;
        // Shift the center a little but keep the wobbling ellipse inside.
        cx =
            rect.left +
            halfW +
            faker.random.double(min: -0.08, max: 0.08) * halfW;
        cy =
            rect.top +
            halfH +
            faker.random.double(min: -0.08, max: 0.08) * halfH;
      } else {
        final center = faceRegions[region];
        if (center == null) throw ArgumentError.value(region, 'regions');
        cx = center.$1;
        cy = center.$2;
        rx = ry = faker.random.double(min: 0.04, max: 0.08);
      }
      final points = <CoInkPoint>[];
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final angle = i / steps * 6.283185307179586;
        final wobble = 1 + faker.random.double(min: -0.08, max: 0.08);
        points.add((
          x: _norm(cx + rx * wobble * _cos(angle)),
          y: _norm(cy + ry * wobble * _sin(angle)),
          p: 0.6,
          t: time,
        ));
        time += faker.random.int(min: 8, max: 14);
      }
      marks.add((
        tool: 'pen',
        color: '#E11D48',
        width: 2,
        region: region,
        points: points,
      ));
      time += 200;
    }
    final y = faker.random.double(min: 0.3, max: 0.7);
    final highlight = <CoInkPoint>[];
    for (var i = 0; i <= 10; i++) {
      highlight.add((
        x: _norm(0.2 + i * 0.06),
        y: _norm(y + faker.random.double(min: -0.005, max: 0.005)),
        p: 1,
        t: time,
      ));
      time += 12;
    }
    marks.add((
      tool: 'highlighter',
      color: '#FACC15',
      width: 14,
      region: 'note',
      points: highlight,
    ));
    return marks;
  }

  // ── Billing ─────────────────────────────────────────────────────────

  /// Generates an invoice adjustment line (`discount`, `coupon`, `point`,
  /// `rounding`) for an invoice of [subtotal]; [amount] is negative.
  ({String kind, String kindLabel, String label, int amount}) adjustment({
    required int subtotal,
    String? kind,
  }) {
    final resolved =
        kind ??
        _weighted<String>(const <(String, int)>[
          ('discount', 45),
          ('coupon', 25),
          ('point', 20),
          ('rounding', 10),
        ]);
    final labels = ops.adjustments[resolved];
    if (labels == null || labels.isEmpty) {
      throw ArgumentError.value(kind, 'kind');
    }
    final unit = _scale.adjustmentUnit;
    final amount = switch (resolved) {
      'rounding' => subtotal % unit,
      'point' => _roundTo(faker.random.int(min: 1, max: 30) * unit, unit),
      _ => _roundTo(subtotal * faker.random.int(min: 5, max: 20) ~/ 100, unit),
    };
    return (
      kind: resolved,
      kindLabel: label(resolved),
      label: faker.random.pick(labels),
      amount: -amount.clamp(0, subtotal),
    );
  }

  /// Generates a card decline with its ISO 8583-style response code:
  /// the same reasons as `saas.autopayFailure`.
  ({String code, String responseCode, String reason}) cardDecline() {
    final failure = faker.saas.autopayFailure();
    return (
      code: failure.code,
      responseCode: _responseCodes[failure.code] ?? '05',
      reason: failure.reason,
    );
  }

  /// Returns a payment result message: `approved`, `cashReceipt`,
  /// `partialCancel`, `prepaidUsed`, or `declined` (with a generated
  /// decline reason).
  String paymentMessage({String code = 'approved'}) {
    final template = ops.paymentMessages[code];
    if (template == null) throw ArgumentError.value(code, 'code');
    return code == 'declined'
        ? template.replaceAll('{reason}', cardDecline().reason)
        : template;
  }

  /// Generates a point transaction (`earn`, `use`, `bonus`, `expire`,
  /// `refund`, `adjust`); spending reasons have a negative [amount].
  ({String reason, String label, int amount}) pointTransaction({
    String? reason,
  }) {
    final resolved =
        reason ??
        _weighted<String>(const <(String, int)>[
          ('earn', 50),
          ('use', 25),
          ('bonus', 8),
          ('expire', 8),
          ('refund', 5),
          ('adjust', 4),
        ]);
    final text = ops.pointReasons[resolved];
    if (text == null) throw ArgumentError.value(reason, 'reason');
    final value = faker.random.int(min: 1, max: 50) * _scale.pointUnit;
    final negative = const <String>{
      'use',
      'expire',
      'refund',
    }.contains(resolved);
    return (reason: resolved, label: text, amount: negative ? -value : value);
  }

  /// Generates a long compound package name combining two or three catalog
  /// procedures and a gift, for truncation and wrapping tests.
  String compoundPackageName() {
    final pool = [...data.procedures.where((p) => p.taxable)];
    final parts = <String>[
      for (var i = 0; i < 2 + faker.random.int(max: 1); i++)
        ops.compoundItemFormat
            .replaceAll(
              '{name}',
              pool.removeAt(faker.random.int(max: pool.length - 1)).name,
            )
            .replaceAll(
              '{sessions}',
              '${faker.random.pick(const <int>[3, 5, 10])}',
            ),
    ];
    return '${parts.join(' + ')} + ${ops.packageBonus}';
  }

  // ── Statistics ──────────────────────────────────────────────────────

  /// Generates a weekday × hour visit heatmap for Monday-Saturday and the
  /// opening hours of [hours]: busier late mornings, after lunch, and on
  /// Saturdays, scaled by [base] visits per busy hour.
  List<({int weekday, int hour, int count})> visitHeatmap({
    int base = 8,
    CoClinicHours hours = const CoClinicHours(),
  }) {
    final result = <({int weekday, int hour, int count})>[];
    for (
      var weekday = DateTime.monday;
      weekday <= DateTime.saturday;
      weekday++
    ) {
      final close = weekday == DateTime.saturday
          ? (hours.saturdayClose ?? hours.open)
          : hours.close;
      for (var hour = hours.open ~/ 60; hour * 60 < close; hour++) {
        final lunch =
            weekday != DateTime.saturday &&
            hours.lunchStart != null &&
            hour * 60 >= hours.lunchStart! &&
            hour * 60 < (hours.lunchEnd ?? 0);
        final shape = lunch
            ? 0.1
            : (hour == 11 || hour == 15 || hour == 16 ? 1.0 : 0.7) *
                  (weekday == DateTime.saturday ? 1.3 : 1.0);
        result.add((
          weekday: weekday,
          hour: hour,
          count: (base * shape * faker.random.double(min: 0.6, max: 1.3))
              .round(),
        ));
      }
    }
    return result;
  }

  // ── Operations and CRM ──────────────────────────────────────────────

  /// Generates an in-clinic task with a memo, an assignee role, and a due
  /// time today.
  ({String title, String memo, String assigneeRole, DateTime dueAt, bool done})
  task() {
    final role = staffRole();
    return (
      title: faker.random.pick(ops.tasks),
      memo: faker.random.pick(ops.taskMemos),
      assigneeRole: role.label,
      dueAt: _at(_dayStart(faker.now), faker.random.int(min: 20, max: 37) * 30),
      done: faker.random.double() < 0.4,
    );
  }

  /// Generates an AI counseling evidence item: its kind, label, and rule.
  ({String kind, String kindLabel, String rule}) counselEvidence() {
    final spec = faker.random.pick(ops.evidence);
    return (kind: spec.kind, kindLabel: label(spec.kind), rule: spec.rule);
  }

  /// Generates an AI counseling failure message.
  ({String code, String message}) counselFailure() {
    final code = faker.random.pick(ops.counselFailures.keys.toList());
    return (code: code, message: ops.counselFailures[code]!);
  }

  /// Generates a claim review issue: rule id, severity, diagnosis and fee
  /// codes, and a message. The rules are illustrative, not official review
  /// criteria.
  CoClaimRuleSpec claimIssue() => faker.random.pick(ops.claimRules);

  /// Generates a CRM delivery failure reason, such as sending advertising
  /// at night without night-time advertising consent.
  ({String code, String reason}) crmSendFailure() {
    final code = faker.random.pick(ops.crmFailures.keys.toList());
    return (code: code, reason: ops.crmFailures[code]!);
  }

  static const Map<String, String> _responseCodes = <String, String>{
    'LIMIT_EXCEEDED': '61',
    'INSUFFICIENT_FUNDS': '51',
    'CARD_EXPIRED': '54',
    'CARD_LOST': '41',
    'CARD_SUSPENDED': '62',
    'ISSUER_TIMEOUT': '91',
  };

  static double _round1(double value) => double.parse(value.toStringAsFixed(1));

  static double _norm(double value) =>
      double.parse(value.clamp(0.0, 1.0).toStringAsFixed(4));

  static double _cos(double x) => math.cos(x);

  static double _sin(double x) => math.sin(x);

  static const String _serialAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Invented device vendors; not real manufacturers.
  static const List<String> _vendors = <String>[
    'Lumenixa',
    'Dermavio',
    'Sonarique',
    'Radiqen',
    'Vistorra',
    'Kellbrio',
    'Opalwave',
    'Tessarin',
  ];

  String _phone() => _values == CoKoreanValues.korean
      ? faker.korea.mobilePhone()
      : faker.internet.phoneNumber();

  /// A date of birth for [age] at midnight in the time zone of `faker.now`:
  /// what `faker.korea.birthDate` returns, which is only a date, written here
  /// so that data without Korean values never calls the Korean module.
  DateTime _birthDate(int age) {
    final value = faker.date.dateOfBirth(
      minAge: age,
      maxAge: age,
      utc: faker.now.isUtc,
    );
    return faker.now.isUtc
        ? DateTime.utc(value.year, value.month, value.day)
        : DateTime(value.year, value.month, value.day);
  }

  /// The masked ID number of a patient: a resident registration number for
  /// Korean and legacy data, the `maskedIdFormat` of the data otherwise.
  String _maskedId(DateTime birth, CoSex sex) => _values == CoKoreanValues.none
      ? faker.random.digits(data.maskedIdFormat)
      : faker.korea.rrn(birthDate: birth, sex: sex);

  /// A card approval number: 8 digits for Korean and legacy data, a plain
  /// 6-digit authorization code otherwise.
  String _approvalNo() => _values == CoKoreanValues.none
      ? faker.random.digits('######')
      : faker.korea.cardApprovalNumber();

  /// A masked cash receipt number for Korean and legacy data, none otherwise.
  String? _cashReceiptNo() =>
      _values == CoKoreanValues.none ? null : CoFakerKorea.maskPhone(_phone());

  int _price(int min, int max) {
    final unit = _scale.priceRounding;
    final value = faker.random.int(min: min, max: max);
    final rounded = _roundTo(value, unit);
    return rounded < min ? min : rounded;
  }

  T _weighted<T>(List<(T, int)> items) {
    var total = 0;
    for (final item in items) {
      total += item.$2;
    }
    var roll = faker.random.int(max: total - 1);
    for (final item in items) {
      if (roll < item.$2) return item.$1;
      roll -= item.$2;
    }
    return items.last.$1;
  }

  static int _roundTo(int value, int unit) => (value / unit).round() * unit;

  static int _ageOn(DateTime birth, DateTime on) {
    var age = on.year - birth.year;
    if (on.month < birth.month ||
        (on.month == birth.month && on.day < birth.day)) {
      age--;
    }
    return age;
  }

  static DateTime _dayStart(DateTime value) {
    return value.isUtc
        ? DateTime.utc(value.year, value.month, value.day)
        : DateTime(value.year, value.month, value.day);
  }

  static DateTime _at(DateTime day, int minuteOfDay) {
    final h = minuteOfDay ~/ 60;
    final m = minuteOfDay % 60;
    return day.isUtc
        ? DateTime.utc(day.year, day.month, day.day, h, m)
        : DateTime(day.year, day.month, day.day, h, m);
  }
}
