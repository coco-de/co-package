import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 3);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

  group('CoFakerClinic', () {
    test('is deterministic for the same seed and clock', () {
      final a = ko(5);
      final b = ko(5);
      expect(a.clinic.patient(), b.clinic.patient());
      expect(a.clinic.staff(), b.clinic.staff());
      expect(a.clinic.procedure(), b.clinic.procedure());
      expect(a.clinic.packageBalance(), b.clinic.packageBalance());
      expect(a.clinic.soap(), b.clinic.soap());
      expect(a.clinic.appointmentSlot(), b.clinic.appointmentSlot());
      expect(
        a.clinic.splitPayment(amount: 480000),
        b.clinic.splitPayment(amount: 480000),
      );
    });

    test('patients are Korean-shaped and fake', () {
      final faker = ko();
      for (var i = 0; i < 100; i++) {
        final p = faker.clinic.patient();
        expect(p.name, matches(r'^[가-힣]{2,4}$'));
        expect(p.phone, matches(r'^010-0\d{3}-\d{4}$'));
        expect(p.rrnMasked, matches(r'^\d{6}-[1-4]\*{6}$'));
        final yy = (p.birthDate.year % 100).toString().padLeft(2, '0');
        expect(p.rrnMasked, startsWith(yy));
        final sexDigit = int.parse(p.rrnMasked[7]);
        expect(sexDigit.isEven, p.sex == CoSex.female);
        expect(p.age, inInclusiveRange(10, 80));
        expect(p.postalCode, matches(r'^\d{5}$'));
        expect([
          'nhis',
          'medicalAid1',
          'medicalAid2',
          'uninsured',
        ], contains(p.insurance));
        expect(p.insuranceLabel, isNot(p.insurance));
        if (p.email != null) expect(p.email, contains('@'));
      }
    });

    test('patients honor explicit sex and age bounds', () {
      final faker = ko();
      final p = faker.clinic.patient(sex: CoSex.male, minAge: 40, maxAge: 40);
      expect(p.sex, CoSex.male);
      expect(p.age, 40);
    });

    test('clinic names, staff and procedures come from the catalog', () {
      final faker = ko();
      expect(faker.clinic.clinicName(specialty: '피부과'), endsWith('피부과의원'));
      final staff = faker.clinic.staff(role: 'counselor');
      expect(staff.roleLabel, '상담실장');
      expect(staff.email, endsWith('@demo.clinic'));
      for (var i = 0; i < 100; i++) {
        final p = faker.clinic.procedure();
        final spec = faker.clinic.procedures.firstWhere(
          (s) => s.code == p.code,
        );
        expect(p.price, inInclusiveRange(spec.minPrice, spec.maxPrice + 500));
        expect(p.price % 1000, 0);
      }
      expect(faker.clinic.procedure(code: 'BTX-J').code, 'BTX-J');
      expect(() => faker.clinic.procedure(code: 'NOPE'), throwsArgumentError);
    });

    test('packages and balances are consistent', () {
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final b = faker.clinic.packageBalance();
        expect(b.usedSessions + b.remainingSessions, b.totalSessions);
        expect(b.expiresAt.isAfter(b.purchasedAt), isTrue);
        expect(b.purchasedAt.isAfter(now), isFalse);
      }
      final offer = faker.clinic.package(procedureCode: 'LT-01');
      expect(offer.name, endsWith('${offer.sessions}회'));
      expect(offer.price % 10000, 0);
    });

    test('drugs, notes and questionnaires are populated', () {
      final faker = ko();
      expect(faker.clinic.drugName(), matches(r'^[가-힣]+ \d+(mg|g)$'));
      final rx = faker.clinic.prescription();
      expect(rx.quantity, greaterThanOrEqualTo(rx.days));
      final dx = faker.clinic.diagnosis();
      final soap = faker.clinic.soap(diagnosis: dx);
      expect(soap.assessment, '${dx.name} (${dx.code})');
      expect(faker.clinic.chartMemo(), isNotEmpty);
      expect(faker.clinic.questionnaire(count: 3), hasLength(3));
      expect(
        faker.clinic.questionnaire(),
        hasLength(faker.clinic.data.questions.length),
      );
    });

    test('business slots skip lunch, shorten Saturday and close Sunday', () {
      final faker = ko();
      final thursday = faker.clinic.businessSlots(DateTime.utc(2026, 10, 1));
      expect(thursday.first, DateTime.utc(2026, 10, 1, 10));
      expect(thursday.last, DateTime.utc(2026, 10, 1, 18, 30));
      expect(thursday.where((s) => s.hour == 13), isEmpty);
      expect(thursday, hasLength(16));
      final saturday = faker.clinic.businessSlots(DateTime.utc(2026, 10, 3));
      expect(saturday.last, DateTime.utc(2026, 10, 3, 14, 30));
      expect(faker.clinic.businessSlots(DateTime.utc(2026, 10, 4)), isEmpty);
      final hourly = faker.clinic.businessSlots(
        DateTime.utc(2026, 10, 1),
        hours: const CoClinicHours(interval: 60, lunchStart: null),
      );
      expect(hourly, hasLength(9));
    });

    test('appointment slots land on business hours', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        final slot = faker.clinic.appointmentSlot();
        expect(slot.weekday, isNot(DateTime.sunday));
        expect(slot.minute % 30, 0);
        expect(slot.hour, inInclusiveRange(10, 18));
        if (slot.weekday != DateTime.saturday) expect(slot.hour, isNot(13));
        final past = faker.clinic.appointmentSlot(days: -30);
        expect(past.isBefore(now.add(const Duration(days: 1))), isTrue);
      }
    });

    test('reservation statuses depend on time', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        expect(
          ['reserved', 'confirmed', 'requested', 'cancelled', 'rejected'],
          contains(
            faker.clinic.reservationStatus(
              at: now.add(const Duration(days: 1)),
            ),
          ),
        );
        expect(
          ['completed', 'noShow', 'cancelled'],
          contains(
            faker.clinic.reservationStatus(
              at: now.subtract(const Duration(days: 1)),
            ),
          ),
        );
      }
      expect(faker.clinic.label('noShow'), '노쇼');
    });

    test('visit flows start at reception and end paid', () {
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final flow = faker.clinic.visitFlow();
        expect(flow.take(2), ['reception', 'waiting']);
        expect(flow.skip(flow.length - 2), ['payment', 'done']);
        expect(flow.every(CoFakerClinic.visitStages.contains), isTrue);
        expect(CoFakerClinic.visitStages, contains(faker.clinic.visitStage()));
      }
    });

    test('split payments add up and card payments carry approval data', () {
      final faker = ko();
      for (var i = 0; i < 100; i++) {
        final amount = faker.number.int(min: 1, max: 300) * 10000;
        final parts = faker.clinic.splitPayment(amount: amount);
        expect(parts.fold<int>(0, (sum, p) => sum + p.amount), amount);
        for (final p in parts) {
          expect(p.amount, greaterThan(0));
          if (p.method == 'card') {
            expect(p.approvalNo, matches(r'^\d{8}$'));
            expect(faker.clinic.data.cardIssuers, contains(p.cardIssuer));
          }
        }
      }
      final cash = faker.clinic.payment(amount: 10000, method: 'cash');
      expect(cash.cashReceiptNo, matches(r'^010-\*{4}-\d{4}$'));
      expect(cash.methodLabel, '현금');
    });

    test('other locales fall back to English clinic data', () {
      // `nl` stands for a language that has no clinic data and never will: a
      // language of the Epic (`fr`) gets its own data when it is localized.
      final faker = CoFaker(locale: 'nl', seed: 1, now: now);
      expect(faker.clinic.data, same(CoFakerClinicData.english));
      expect(faker.clinic.label('nhis'), 'National insurance');
      expect(faker.clinic.patient().name, isNotEmpty);
      final custom = CoFaker(
        locale: 'acme',
        locales: {
          'acme': const CoFakerLocale(
            code: 'acme',
            clinic: CoFakerClinicData.korean,
          ),
        },
      );
      expect(custom.clinic.data, same(CoFakerClinicData.korean));
    });
  });
}
