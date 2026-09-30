import 'clinic_data.dart';
import 'clinic_texts.dart';
import 'co_faker.dart';
import 'korea.dart';
import 'modules.dart';

/// A patient profile for EMR fixtures.
///
/// [rrnMasked] is always a masked, Korean-format fake number
/// (`YYMMDD-G******`); see [CoFakerKorea.rrn].
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
typedef CoFakeTurn = ({String speaker, String text, Duration at});

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
/// English are built in; other locales fall back to English). Codes such as
/// `nhis`, `waiting`, `noShow`, and `prepaid` are locale independent and
/// match the enum names an EMR typically uses; `label(code)` localizes them.
class CoFakerClinic {
  /// Creates a clinic generator backed by [faker].
  CoFakerClinic(this.faker);

  /// The faker instance used by this module.
  final CoFaker faker;

  /// The clinic data of the current locale.
  CoFakerClinicData get data => faker.localeData.clinic!;

  bool get _korean => faker.locale.startsWith('ko');

  /// The longer clinic texts of the current locale.
  CoFakerClinicTexts get texts => data.texts ?? CoFakerClinicTexts.english;

  /// Returns the localized label of a code such as `nhis`, `noShow`, or
  /// `spouse`, falling back to English and then to the code itself.
  String label(String code) =>
      data.labels[code] ??
      texts.labels[code] ??
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
    return _korean
        ? '$prefix${spec.clinicSuffix}'
        : '$prefix ${spec.clinicSuffix}';
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
  CoFakePatient patient({
    CoSex? sex,
    int? minAge,
    int? maxAge,
    double femaleRatio = 0.75,
    double emailRatio = 0.4,
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
    final birth = faker.korea.birthDate(minAge: age, maxAge: age);
    final first = faker.person.firstName(sex: resolvedSex);
    final last = faker.person.lastName();
    final hasEmail = faker.random.double() < emailRatio;
    final String postal;
    final String line1;
    final String line2;
    if (_korean) {
      final address = faker.korea.roadAddress();
      postal = address.postalCode;
      line1 = address.line1;
      line2 = address.line2;
    } else {
      postal = faker.address.postalCode();
      line1 = faker.address.streetAddress();
      line2 = '';
    }
    final insurance = insuranceType();
    return (
      name: faker.person.fullName(firstName: first, lastName: last),
      sex: resolvedSex,
      birthDate: birth,
      age: _ageOn(birth, faker.now),
      rrnMasked: faker.korea.rrn(birthDate: birth, sex: resolvedSex),
      phone: _phone(),
      email: hasEmail
          ? faker.internet.email(firstName: first, lastName: last)
          : null,
      postalCode: postal,
      address1: line1,
      address2: line2,
      insurance: insurance.code,
      insuranceLabel: insurance.label,
    );
  }

  /// Generates an insurance type: `nhis` (national health insurance, 80%),
  /// `medicalAid1` (3%), `medicalAid2` (2%), or `uninsured` (15%).
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
  ({String purpose, String detail}) visitPurpose() {
    final spec = faker.random.pick(data.visitPurposes);
    return (purpose: spec.name, detail: faker.random.pick(spec.details));
  }

  /// The procedure catalog of the current locale.
  List<CoProcedureSpec> get procedures => data.procedures;

  /// Generates a procedure priced within its band, rounded to 1,000 won
  /// (or 5 dollars). [code] selects a specific catalog entry.
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
      _korean ? 10000 : 10,
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

  /// Generates a prepaid balance (선수금) rounded to 10,000 won.
  int prepaidBalance() {
    return _korean
        ? faker.random.int(max: 100) * 10000
        : faker.random.int(max: 100) * 10;
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
          ? (amount >= (_korean ? 500000 : 500)
                ? faker.random.pick(const <int>[0, 0, 2, 3, 6])
                : 0)
          : null,
      approvalNo: card ? faker.korea.cardApprovalNumber() : null,
      cashReceiptNo: resolved == 'cash' || resolved == 'transfer'
          ? CoFakerKorea.maskPhone(_phone())
          : null,
    );
  }

  /// Splits [amount] into one to three payments, for example part prepaid
  /// balance and the rest by card. The amounts always add up to [amount].
  List<CoFakePayment> splitPayment({required int amount}) {
    final parts = amount < (_korean ? 50000 : 50)
        ? 1
        : _weighted(const <(int, int)>[(1, 75), (2, 20), (3, 5)]);
    if (parts == 1) return <CoFakePayment>[payment(amount: amount)];
    final unit = _korean ? 1000 : 1;
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
        ? _price(50000, 300000)
        : procedure(code: spec.procedureCode).price;
    final packagePrice = _roundTo(
      (price * spec.sessions * faker.random.int(min: 65, max: 85) / 100)
          .round(),
      _korean ? 10000 : 10,
    );
    final answers = <String, String>{
      'pain': spec.pain,
      'interval': spec.interval,
      'downtime': spec.downtime,
      'price': script.priceAnswer
          .replaceAll('{price}', _money(price))
          .replaceAll('{sessions}', '${spec.sessions}')
          .replaceAll('{packagePrice}', _money(packagePrice)),
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
          .replaceAll('{price}', _money(price))
          .replaceAll('{sessions}', '${spec.sessions}')
          .replaceAll('{packagePrice}', _money(packagePrice))
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
  /// inbox receives messages in many languages.
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
    final remaining = [...pool];
    final count = exchanges.clamp(1, pool.length);
    final turns = <CoFakeTurn>[];
    var minutes = 0;
    for (var i = 0; i < count; i++) {
      final item = remaining.removeAt(
        faker.random.int(max: remaining.length - 1),
      );
      turns
        ..add((
          speaker: 'patient',
          text: item.question,
          at: Duration(minutes: minutes),
        ))
        ..add((
          speaker: 'staff',
          text: item.answer,
          at: Duration(minutes: minutes + faker.random.int(min: 1, max: 30)),
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
  CoFakeTeamNote teamNote({String? patient}) {
    final mentioned = staff();
    final author = faker.person.fullName();
    final title = _korean ? '${mentioned.roleLabel}님' : mentioned.roleLabel;
    final template = faker.random.pick(texts.teamNotes);
    return (
      text: template
          .replaceAll('{mention}', '@${mentioned.name} $title')
          .replaceAll('{patient}', patient ?? faker.person.fullName()),
      author: author,
      mentions: <String>[mentioned.name],
    );
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

  String _money(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return _korean ? buffer.toString() : '\$$buffer';
  }

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

  String _phone() =>
      _korean ? faker.korea.mobilePhone() : faker.internet.phoneNumber();

  int _price(int min, int max) {
    final unit = _korean ? 1000 : 5;
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
