import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 15, 20);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

  group('widgetbook and golden generators', () {
    test('are deterministic for the same seed and clock', () {
      final a = ko(6);
      final b = ko(6);
      expect(a.clinic.patient(), b.clinic.patient());
      expect(a.clinic.rooms(), b.clinic.rooms());
      expect(
        a.clinic.queueBoard().toString(),
        b.clinic.queueBoard().toString(),
      );
      expect(a.clinic.consentHistory(), b.clinic.consentHistory());
      expect(a.clinic.vitals(), b.clinic.vitals());
      expect(
        a.clinic.canvasMarks().toString(),
        b.clinic.canvasMarks().toString(),
      );
      expect(a.clinic.visitHeatmap(), b.clinic.visitHeatmap());
      expect(a.id.uuidV7(), b.id.uuidV7());
    });

    test('patients carry chart number, visits, channel and notes', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        final p = faker.clinic.patient();
        expect(p.chartNo, matches(r'^\d+$'));
        expect(p.visitCount, inInclusiveRange(0, 24));
        expect(p.lastVisitAt == null, p.visitCount == 0);
        if (p.lastVisitAt != null) {
          expect(p.lastVisitAt!.isAfter(now), isFalse);
        }
        expect(p.channelLabel, isNot(p.channel));
      }
      expect(
        faker.clinic
            .patient(
              chartNumber: 42,
              chartNumberFormat: CoChartNumberFormat.yearly,
            )
            .chartNo,
        '2026-00042',
      );
      expect(
        faker.clinic.chartNumber(7, format: CoChartNumberFormat.padded),
        '000007',
      );
    });

    test('base patient fields match 0.6.0 output for the same seed', () {
      // The new fields draw from a derived stream, so the main stream and
      // every earlier field keep their 0.6.0 values.
      final faker = ko(5);
      final a = faker.clinic.patient();
      final b = faker.clinic.patient();
      expect(a.name, '한채은');
      expect(a.rrnMasked, '900526-2******');
      expect(a.phone, '010-0075-4034');
      expect(b.name, '이채원');
      expect(b.phone, '010-0056-3558');
    });

    test('tags, channels, notes and masked names', () {
      final faker = ko();
      final tags = faker.clinic.patientTags(max: 3);
      expect(tags.map((t) => t.code).toSet(), hasLength(tags.length));
      expect(faker.clinic.patientTag().color, matches(r'^#[0-9A-F]{6}$'));
      expect(faker.clinic.acquisitionChannel().label, isNotEmpty);
      expect(faker.clinic.specialNote(), isNotEmpty);
      expect(CoFakerClinic.maskName('김하늘'), '김*늘');
      expect(CoFakerClinic.maskName('김하'), '김*');
      expect(CoFakerClinic.maskName('남궁민수'), '남**수');
      expect(faker.clinic.maskedName(), contains('*'));
    });

    test('consent history never withdraws the required consent', () {
      final faker = ko();
      final history = faker.clinic.consentHistory(count: 20);
      expect(history.first.kind, 'privacyRequired');
      expect(history.first.action, 'agreed');
      for (var i = 1; i < history.length; i++) {
        expect(history[i].at.isBefore(history[i - 1].at), isFalse);
        expect(history[i].at.isAfter(now), isFalse);
        if (history[i].action == 'withdrawn') {
          expect(history[i].kind, isNot('privacyRequired'));
        }
      }
      expect(faker.clinic.termsVersion().version, matches(r'^v\d\.\d$'));
      expect(
        faker.clinic.consentDispatch(status: 'expired').message,
        contains('만료'),
      );
    });

    test('rooms, purpose tree and queue board', () {
      final faker = ko();
      final rooms = faker.clinic.rooms();
      expect(rooms.map((r) => r.id), List.generate(rooms.length, (i) => i + 1));
      expect(rooms.last.kind, 'reception');
      expect(rooms.last.staffName, isNull);
      expect(rooms.first.staffName, isNotNull);

      final tree = faker.clinic.visitPurposeTree();
      final parents = tree.where((n) => n.parentId == null).toList();
      expect(parents.map((n) => n.name), ['상담', '시술', '진료', '관리']);
      expect(parents.every((n) => n.color != null), isTrue);
      final laser = tree.firstWhere((n) => n.name == '레이저');
      expect(tree.firstWhere((n) => n.id == laser.parentId).name, '시술');
      final vp = faker.clinic.visitPurpose();
      expect(
        tree.firstWhere((n) => n.id == vp.detailId).parentId,
        vp.purposeId,
      );

      final board = faker.clinic.queueBoard(count: 4);
      expect(board.every((q) => q.roomKind != 'reception'), isTrue);
      for (final q in board) {
        expect(q.entries, hasLength(4));
        expect(q.entries.map((e) => e.order), [1, 2, 3, 4]);
        expect(
          q.entries.where((e) => e.status == 'inProgress').length,
          lessThanOrEqualTo(1),
        );
        for (var i = 1; i < q.entries.length; i++) {
          expect(
            q.entries[i].checkedInAt.isAfter(q.entries[i - 1].checkedInAt),
            isTrue,
          );
          expect(q.entries[i].status, isNot('inProgress'));
        }
      }
      final custom = faker.clinic.queueBoard(rooms: rooms.take(2).toList());
      expect(custom, hasLength(2));
      expect(faker.clinic.receptionSource().label, isNotEmpty);
      expect(faker.clinic.kioskPurpose().label, isNotEmpty);
      expect(faker.clinic.color(index: 13), CoFakerClinic.palette[1]);
    });

    test('vitals are realistic by age', () {
      final faker = ko();
      for (var i = 0; i < 100; i++) {
        final adult = faker.clinic.vitals(age: 40);
        expect(adult.temperature, inInclusiveRange(36, 37.5));
        expect(adult.systolic, inInclusiveRange(95, 145));
        expect(adult.diastolic, lessThan(adult.systolic));
        expect(adult.spo2, inInclusiveRange(95, 100));
        expect(adult.heightCm, inInclusiveRange(150, 182));
        expect(adult.bmi, inInclusiveRange(18, 29));
        final child = faker.clinic.vitals(age: 6);
        expect(child.heightCm, lessThan(130));
        expect(child.weightKg, lessThan(40));
      }
    });

    test('billing lines, declines, points and package names', () {
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final adj = faker.clinic.adjustment(subtotal: 250500);
        expect(adj.amount, lessThanOrEqualTo(0));
        expect(adj.amount, greaterThanOrEqualTo(-250500));
        final decline = faker.clinic.cardDecline();
        expect(decline.responseCode, matches(r'^\d{2}$'));
        final point = faker.clinic.pointTransaction();
        if (point.reason == 'use') expect(point.amount, lessThan(0));
      }
      expect(
        faker.clinic.adjustment(subtotal: 250500, kind: 'rounding').amount,
        -500,
      );
      expect(faker.clinic.paymentMessage(code: 'declined'), contains('거절'));
      final name = faker.clinic.compoundPackageName();
      expect(name.split(' + ').length, greaterThanOrEqualTo(3));
      expect(name, endsWith('증정'));
    });

    test('heatmap covers business hours only', () {
      final cells = ko().clinic.visitHeatmap();
      expect(cells.map((c) => c.weekday).toSet(), {1, 2, 3, 4, 5, 6});
      expect(cells.every((c) => c.hour >= 10 && c.hour < 19), isTrue);
      expect(
        cells.where((c) => c.weekday == 6).every((c) => c.hour < 15),
        isTrue,
      );
      final lunch = cells.firstWhere((c) => c.weekday == 1 && c.hour == 13);
      final peak = cells.firstWhere((c) => c.weekday == 1 && c.hour == 15);
      expect(lunch.count, lessThan(peak.count));
    });

    test('operations, counseling, claims and CRM texts', () {
      final faker = ko();
      final task = faker.clinic.task();
      expect(task.dueAt.day, 30);
      expect(faker.clinic.counselEvidence().kindLabel, isNotEmpty);
      expect(faker.clinic.counselFailure().message, isNotEmpty);
      expect(faker.clinic.claimIssue().ruleId, matches(r'^R-[A-Z]{2}-\d{3}$'));
      expect(
        faker.clinic.data.ops!.crmFailures,
        contains(faker.clinic.crmSendFailure().code),
      );
    });

    test('inquiry turns carry language and Korean translation', () {
      final faker = ko();
      final thread = faker.clinic.inquiry(language: 'ja', exchanges: 5);
      final ko5 = CoFakerClinicTexts.inquiries['ko']!;
      for (final turn in thread.turns) {
        expect(turn.language, 'ja');
        expect(turn.translation, isNotNull);
        expect(
          ko5.any(
            (k) =>
                k.question == turn.translation || k.answer == turn.translation,
          ),
          isTrue,
        );
      }
      final korean = faker.clinic.inquiry(language: 'ko');
      expect(korean.turns.every((t) => t.translation == null), isTrue);
      for (final lang in CoFakerClinic.inquiryLanguages) {
        expect(CoFakerClinicTexts.inquiries[lang], hasLength(ko5.length));
      }
    });

    test('canvas marks are normalized and convert to open_board', () {
      final faker = ko();
      final marks = faker.clinic.canvasMarks(regions: ['forehead', 'chin']);
      expect(marks.map((m) => m.region), ['forehead', 'chin', 'note']);
      expect(marks.last.tool, 'highlighter');
      for (final m in marks) {
        for (final p in m.points) {
          expect(p.x, inInclusiveRange(0, 1));
          expect(p.y, inInclusiveRange(0, 1));
        }
      }
      final forehead = marks.first.points;
      final cy =
          forehead.map((p) => p.y).reduce((a, b) => a + b) / forehead.length;
      expect(cy, closeTo(0.22, 0.02));
      final points = CoFakerSignature.toOpenBoardPoints(
        [marks.first.points],
        width: 800,
        height: 1000,
      );
      expect(points.first.first['x'] as double, greaterThan(1));
      expect(
        () => faker.clinic.canvasMarks(template: 'x'),
        throwsArgumentError,
      );
    });

    test('uuidV7 encodes the time and sorts by it', () {
      final faker = ko();
      final a = faker.id.uuidV7(at: DateTime.utc(2026, 1, 1));
      final b = faker.id.uuidV7(at: DateTime.utc(2026, 1, 2));
      expect(
        a,
        matches(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      );
      expect(a.compareTo(b), lessThan(0));
      final millis = int.parse(
        a.replaceAll('-', '').substring(0, 12),
        radix: 16,
      );
      expect(millis, DateTime.utc(2026, 1, 1).millisecondsSinceEpoch);
    });
  });
}
