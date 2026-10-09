import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  String ymd(DateTime d) => d.toIso8601String().substring(0, 10);

  List<String> substitutes(int year) => [
    for (final h in CoFakerKorea.holidays(year: year))
      if (h.substitute) '${ymd(h.date)} ${h.name}',
  ];

  group('Korean holidays', () {
    test('match the published calendars', () {
      expect(substitutes(2024), [
        '2024-02-12 대체공휴일(설날)',
        '2024-05-06 대체공휴일(어린이날)',
      ]);
      expect(substitutes(2025), [
        '2025-03-03 대체공휴일(삼일절)',
        '2025-05-06 대체공휴일(어린이날)',
        '2025-10-08 대체공휴일(추석)',
      ]);
      expect(substitutes(2026), [
        '2026-03-02 대체공휴일(삼일절)',
        '2026-05-25 대체공휴일(부처님오신날)',
        '2026-08-17 대체공휴일(광복절)',
        '2026-10-05 대체공휴일(개천절)',
      ]);
      final y2026 = CoFakerKorea.holidays(year: 2026);
      expect(y2026.where((h) => h.block == 'chuseok').map((h) => ymd(h.date)), [
        '2026-09-24',
        '2026-09-25',
        '2026-09-26',
      ]);
      expect(
        y2026.firstWhere((h) => h.name == '설날').date,
        DateTime.utc(2026, 2, 17),
      );
    });

    test('are sorted, cover every supported year, and reject others', () {
      final (first, last) = CoFakerKorea.holidayYears;
      for (var year = first; year <= last; year++) {
        final list = CoFakerKorea.holidays(year: year);
        expect(list.length, greaterThanOrEqualTo(15));
        for (var i = 1; i < list.length; i++) {
          expect(list[i].date.isBefore(list[i - 1].date), isFalse);
        }
        for (final h in list.where((h) => h.substitute)) {
          expect(h.date.weekday, lessThan(DateTime.saturday));
        }
      }
      expect(() => CoFakerKorea.holidays(year: 2023), throwsArgumentError);
      expect(() => CoFakerKorea.holidays(year: 2031), throwsArgumentError);
      expect(CoFakerKorea.holidaysOn(DateTime(2026, 10, 9)).single.name, '한글날');
      expect(CoFakerKorea.holidaysOn(DateTime(2026, 10, 7)), isEmpty);
    });
  });

  group('clinic notices', () {
    final now = DateTime.utc(2026, 9, 30);
    CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

    test('closure notices span holiday stretches', () {
      final faker = ko();
      final chuseok = faker.clinic.closureNotice(
        date: DateTime.utc(2026, 9, 25),
        clinicName: '데모피부과의원',
      );
      expect(chuseok.holiday, '추석 연휴');
      expect(chuseok.from, DateTime.utc(2026, 9, 24));
      expect(chuseok.to, DateTime.utc(2026, 9, 27));
      expect(
        chuseok.body,
        '데모피부과의원은 9월 24일(목)~9월 27일(일) 추석 연휴로 휴진합니다. '
        '9월 28일(월)부터 정상 진료합니다.',
      );
      final seollal = faker.clinic.closureNotice(
        date: DateTime.utc(2027, 2, 6),
      );
      expect(seollal.to, DateTime.utc(2027, 2, 8));
      final other = faker.clinic.closureNotice(
        date: DateTime.utc(2026, 11, 11),
      );
      expect(other.holiday, isNull);
      expect(other.body, contains('11월 12일(목)부터'));
      expect(other.body, isNot(contains('(으)로')));
    });

    test('team notes use the caller staff list', () {
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final note = faker.clinic.teamNote(
          authors: ['김도윤', '이서준'],
          mentions: ['김도윤', '박지현'],
        );
        expect(['김도윤', '이서준'], contains(note.author));
        expect(note.mentions.single, isNot(note.author));
        expect(note.text, contains('@${note.mentions.single}님'));
      }
      final single = faker.clinic.teamNote(mentions: ['한소희']);
      expect(single.author, '한소희');
      expect(single.mentions, ['한소희']);
      expect(() => faker.clinic.teamNote(authors: []), throwsArgumentError);
    });

    test('staff notices and vitals notes', () {
      final faker = ko();
      for (final kind in ['training', 'policy', 'schedule']) {
        final notice = faker.clinic.staffNotice(kind: kind);
        expect(notice.kind, kind);
        expect(notice.body, isNotEmpty);
      }
      expect(() => faker.clinic.staffNotice(kind: 'x'), throwsArgumentError);
      const base = (
        temperature: 36.6,
        systolic: 118,
        diastolic: 76,
        pulse: 72,
        spo2: 98,
        glucose: 96,
        heightCm: 165.0,
        weightKg: 58.0,
        bmi: 21.3,
      );
      expect(faker.clinic.vitalsNote(vitals: base), startsWith('활력징후 안정적'));
      expect(faker.clinic.vitalsNote(vitals: base), isNot(contains('@')));
      final high = (
        temperature: 36.6,
        systolic: 152,
        diastolic: 96,
        pulse: 72,
        spo2: 98,
        glucose: 96,
        heightCm: 165.0,
        weightKg: 58.0,
        bmi: 21.3,
      );
      expect(faker.clinic.vitalsNote(vitals: high), contains('152/96'));
      expect(
        // `nl`: a language with no clinic data of its own reads English. A
        // language of the Epic (`fr`) writes its own notes once localized.
        CoFaker(locale: 'nl', seed: 1).clinic.vitalsNote(vitals: base),
        startsWith('Vitals stable'),
      );
    });
  });
}
