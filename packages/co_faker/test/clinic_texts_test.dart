import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 3);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

  group('clinic texts', () {
    // Records holding lists compare lists by identity, so list-bearing
    // records are compared through their string form.
    test('are deterministic for the same seed and clock', () {
      final a = ko(11);
      final b = ko(11);
      expect(a.clinic.consentForm(), b.clinic.consentForm());
      expect(a.clinic.feedback(), b.clinic.feedback());
      expect(
        a.clinic.counselSession().toString(),
        b.clinic.counselSession().toString(),
      );
      expect(a.clinic.inquiry().toString(), b.clinic.inquiry().toString());
      expect(a.clinic.integrationResult(), b.clinic.integrationResult());
      expect(a.clinic.device(), b.clinic.device());
      expect(a.clinic.teamNote().toString(), b.clinic.teamNote().toString());
      expect(a.clinic.guardian(), b.clinic.guardian());
    });

    test('consent forms always carry the not-a-legal-document notice', () {
      final faker = ko();
      for (final kind in faker.clinic.consentKinds) {
        final form = faker.clinic.consentForm(kind: kind);
        expect(form.kind, kind);
        expect(form.clauses, isNotEmpty);
        expect(form.disclaimer, contains('법률 검토를 거친 서식이 아니며'));
      }
      expect(
        CoFaker(locale: 'en', seed: 1).clinic.consentForm().disclaimer,
        contains('Not legally reviewed'),
      );
      expect(() => faker.clinic.consentForm(kind: 'x'), throwsArgumentError);
    });

    test('feedback follows the sentiment distribution and score bands', () {
      final faker = ko();
      final answers = List.generate(1000, (_) => faker.clinic.feedback());
      final positive = answers.where((a) => a.sentiment == 'positive').length;
      final negative = answers.where((a) => a.sentiment == 'negative').length;
      expect(positive, inInclusiveRange(640, 760));
      expect(negative, inInclusiveRange(60, 140));
      for (final a in answers) {
        final band = switch (a.sentiment) {
          'positive' => [4, 5],
          'neutral' => [3, 4],
          _ => [1, 2],
        };
        expect(band, contains(a.score));
        expect(faker.clinic.texts.feedback[a.sentiment], contains(a.comment));
      }
      expect(faker.clinic.feedback(sentiment: 'negative').score, lessThan(3));
    });

    test('counsel sessions alternate speakers and quote consistent prices', () {
      final faker = ko();
      for (final topic in faker.clinic.counselTopics) {
        final s = faker.clinic.counselSession(topic: topic);
        expect(s.turns.first.speaker, 'counselor');
        for (var i = 0; i < s.turns.length; i++) {
          expect(s.turns[i].speaker, i.isEven ? 'counselor' : 'patient');
          if (i > 0) {
            expect(s.turns[i].at > s.turns[i - 1].at, isTrue);
          }
        }
        expect(s.turns.length, inInclusiveRange(9, 11));
        expect(s.packagePrice % 10000, 0);
        expect(s.packagePrice, lessThan(s.quotedPrice * s.sessions));
        expect(s.summary, contains(s.procedure));
        expect(
          s.turns.map((t) => t.text).join(),
          contains(s.booked ? '예약할게요' : '생각해 보고'),
        );
      }
    });

    test('inquiries stay in one language on its usual channel', () {
      final faker = ko();
      final channels = {
        'ko': 'kakao',
        'en': 'whatsapp',
        'ja': 'line',
        'zh': 'wechat',
        'vi': 'zalo',
      };
      for (final lang in CoFakerClinic.inquiryLanguages) {
        final thread = faker.clinic.inquiry(language: lang, exchanges: 3);
        expect(thread.channel, channels[lang]);
        expect(thread.turns, hasLength(6));
        final pool = CoFakerClinicTexts.inquiries[lang]!;
        for (var i = 0; i < thread.turns.length; i += 2) {
          final q = thread.turns[i];
          final a = thread.turns[i + 1];
          expect(q.speaker, 'patient');
          expect(a.speaker, 'staff');
          expect(
            pool.any((p) => p.question == q.text && p.answer == a.text),
            isTrue,
          );
        }
        if (lang == 'en') {
          expect(thread.handle, matches(r'^\+1 555-01\d{2}$'));
        } else {
          expect(thread.handle, matches(r'^(@|wxid_)[a-z]'));
        }
      }
      expect(() => faker.clinic.inquiry(language: 'xx'), throwsArgumentError);
    });

    test('integration results use example messages with ok flags', () {
      final faker = ko();
      for (final service in faker.clinic.integrationServices) {
        final results = List.generate(
          100,
          (_) => faker.clinic.integrationResult(service: service),
        );
        expect(results.every((r) => r.service == service), isTrue);
        expect(results.where((r) => r.ok).length, inInclusiveRange(65, 95));
      }
      expect(faker.clinic.texts.insurers, contains(faker.clinic.insurerName()));
    });

    test('devices use invented vendors and models', () {
      final faker = ko();
      for (final kind in CoFakerClinic.deviceKinds) {
        final d = faker.clinic.device(kind: kind, number: 2);
        expect(d.name, '${d.kindLabel} 2호기');
        expect(d.serial, matches(r'^SN-[A-Z0-9]{4}-[A-Z0-9]{4}$'));
        if (kind == 'bridgePc') {
          expect(d.model, matches(r'^EMR-BRIDGE-\d{2}$'));
        } else {
          expect(d.model, matches(r'^[A-Z]{3}-[A-Z]\d{3}'));
        }
      }
    });

    test('team notes mention a staff member', () {
      final faker = ko();
      for (var i = 0; i < 20; i++) {
        final note = faker.clinic.teamNote(patient: '홍길동');
        expect(note.mentions, hasLength(1));
        expect(note.text, contains('@${note.mentions.single} '));
        expect(note.text, contains('홍길동님'));
      }
    });

    test('guardians fit the patient age', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        expect([
          'parent',
          'grandparent',
          'legalGuardian',
        ], contains(faker.clinic.guardian(patientAge: 10).relation));
        expect([
          'child',
          'spouse',
          'grandchild',
        ], contains(faker.clinic.guardian(patientAge: 80).relation));
      }
      final g = faker.clinic.guardian();
      expect(g.relationLabel, isNot(g.relation));
      expect(g.phone, matches(r'^010-0\d{3}-\d{4}$'));
      expect(
        CoFakerClinic.relations,
        contains(faker.clinic.familyRelation().code),
      );
      expect(faker.clinic.label('spouse'), '배우자');
    });
  });

  group('CoFakerSignature', () {
    test('is deterministic and stable per name', () {
      final a = ko(2);
      final b = ko(2);
      expect(a.signature.strokes(), b.signature.strokes());
      final before = ko(3).signature.strokes(name: '김서연');
      final shifted = ko(3);
      shifted.person.fullName();
      shifted.clinic.patient();
      expect(shifted.signature.strokes(name: '김서연'), before);
      expect(ko(3).signature.strokes(name: '이민준'), isNot(equals(before)));
    });

    test('stays inside the canvas with increasing timestamps', () {
      final faker = ko();
      final strokes = faker.signature.strokes(width: 240, height: 80);
      expect(strokes.length, inInclusiveRange(2, 4));
      var last = 0;
      for (final stroke in strokes) {
        expect(stroke.length, greaterThanOrEqualTo(12));
        for (final p in stroke) {
          expect(p.x, inInclusiveRange(0, 240));
          expect(p.y, inInclusiveRange(0, 80));
          expect(p.p, inInclusiveRange(0.1, 1));
          expect(p.t, greaterThan(last));
          last = p.t;
        }
      }
      expect(strokes.first.first.t, now.millisecondsSinceEpoch);
      expect(faker.signature.strokes(strokeCount: 1), hasLength(1));
    });

    test('exports SVG and open_board points', () {
      final faker = ko();
      final strokes = faker.signature.strokes();
      final path = CoFakerSignature.svgPath(strokes);
      expect(RegExp('M').allMatches(path), hasLength(strokes.length));
      expect(
        CoFakerSignature.svgDataUri(strokes),
        startsWith('data:image/svg+xml;base64,'),
      );
      expect(faker.signature.dataUri(name: 'x'), startsWith('data:image/svg'));
      final points = CoFakerSignature.toOpenBoardPoints(strokes);
      expect(points, hasLength(strokes.length));
      expect(points.first.first.keys, ['x', 'y', 'p', 'timestamp']);
      expect(points.first.first['timestamp'], strokes.first.first.t);
    });
  });
}
