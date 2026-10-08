import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 3);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

  group('CoFakerSaas', () {
    test('is deterministic for the same seed and clock', () {
      final a = ko(3);
      final b = ko(3);
      expect(a.saas.tenant(), b.saas.tenant());
      expect(a.saas.subscription(), b.saas.subscription());
      expect(a.saas.invoice(), b.saas.invoice());
      expect(a.saas.messageLog(), b.saas.messageLog());
      expect(a.saas.auditEvent(), b.saas.auditEvent());
      expect(a.saas.timeSeries(), b.saas.timeSeries());
    });

    test('tenants carry fake identifiers', () {
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final t = faker.saas.tenant();
        expect(t.code, matches(r'^CLN-[A-Z0-9]{6}$'));
        expect(
          CoFakerKorea.isBusinessNumberChecksumValid(t.businessNumber),
          isFalse,
        );
        expect(t.phone, matches(r'^0\d{1,2}-0\d{2}-\d{4}$'));
        expect(t.name, endsWith('의원'));
        expect(t.createdAt.isAfter(now), isFalse);
      }
    });

    test('subscriptions and invoices are internally consistent', () {
      final faker = ko();
      final sub = faker.saas.subscription(planCode: 'pro', status: 'trialing');
      expect(sub.planName, '프로');
      expect(sub.statusLabel, '체험 중');
      expect(sub.trialEndsAt, isNotNull);
      expect(sub.currentPeriodStart, DateTime.utc(2026, 9));
      expect(sub.currentPeriodEnd, DateTime.utc(2026, 10));
      expect(() => faker.saas.subscription(planCode: 'x'), throwsArgumentError);

      for (var m = 0; m < 12; m++) {
        final inv = faker.saas.invoice(monthsAgo: m);
        expect(inv.total, inv.supplyAmount + inv.vat);
        expect(inv.vat, (inv.supplyAmount * 0.1).round());
        expect(inv.number, matches(r'^INV-\d{6}-\d{6}$'));
        expect(inv.dueAt.isAfter(inv.issuedAt), isTrue);
        if (m == 0) expect(inv.status, 'draft');
        if (inv.status == 'paid') expect(inv.paidAt, isNotNull);
      }
    });

    test('credit ledgers never go negative and chain balances', () {
      final faker = ko();
      final ledger = faker.saas.creditLedger(count: 40);
      var balance = 0;
      for (final entry in ledger) {
        balance += entry.delta;
        expect(entry.balanceAfter, balance);
        expect(entry.balanceAfter, greaterThanOrEqualTo(0));
      }
      for (var i = 1; i < ledger.length; i++) {
        expect(ledger[i].at.isAfter(ledger[i - 1].at), isTrue);
      }
    });

    test('messaging values are well-formed', () {
      final faker = ko();
      for (var i = 0; i < 50; i++) {
        final log = faker.saas.messageLog();
        expect(log.recipient, matches(r'^010-\*{4}-\d{4}$'));
        expect(log.requestedAt.isAfter(now), isFalse);
        if (log.status == 'failed') expect(log.failureReason, isNotNull);
        if (log.channel != 'alimtalk') expect(log.templateCode, isNull);
        final template = faker.saas.messageTemplate();
        expect(template.body, contains('#{'));
        final sender = faker.saas.senderNumber();
        expect(sender.number, matches(r'^0\d{1,2}-0\d{2}-\d{4}$'));
      }
    });

    test('masters, health checks, audit events and notices', () {
      final faker = ko();
      final master = faker.saas.masterVersion(kind: 'drug', monthsAgo: 2);
      expect(master.version, startsWith('2026.07.r'));
      expect(master.status, 'archived');
      expect(faker.saas.masterVersion(monthsAgo: -1).status, 'scheduled');
      for (var i = 0; i < 50; i++) {
        final check = faker.saas.healthCheck();
        expect(CoFakerSaas.services, contains(check.service));
        if (check.status == 'down') expect(check.latencyMs, 0);
        final event = faker.saas.auditEvent();
        expect(CoFakerSaas.auditActions, contains(event.action));
        expect(
          event.ip,
          matches(r'^(192\.0\.2|198\.51\.100|203\.0\.113)\.\d{1,3}$'),
        );
        final notice = faker.saas.notice();
        expect(['notice', 'release', 'maintenance'], contains(notice.category));
      }
    });

    test('time series end today with the requested length', () {
      final faker = ko();
      final series = faker.saas.timeSeries(days: 30, base: 50, trend: 2);
      expect(series, hasLength(30));
      expect(series.last.date, DateTime.utc(2026, 9, 30));
      expect(series.first.date, DateTime.utc(2026, 9, 1));
      expect(series.every((p) => p.value is int && p.value >= 0), isTrue);
      expect(series.last.value, greaterThan(series.first.value));
      final decimals = faker.saas.timeSeries(days: 3, integer: false);
      expect(decimals.every((p) => p.value is double), isTrue);
      expect(faker.saas.timeSeries(days: 0), isEmpty);
    });

    test('other locales fall back to English SaaS data', () {
      // `nl` stands for a language that has no SaaS data and never will: a
      // language of the Epic (`de`) gets its own data when it is localized.
      final faker = CoFaker(locale: 'nl', seed: 1, now: now);
      expect(faker.saas.data, same(CoFakerSaasData.english));
      expect(faker.saas.label('pastDue'), 'Past due');
      expect(faker.saas.tenant().name, isNotEmpty);
    });
  });

  group('template placeholders', () {
    test('expose Korean and clinic providers', () {
      final faker = ko();
      final text = faker.fake('{{clinic.clinicName}} {{korea.mobilePhone}}');
      expect(text, matches(r'^[가-힣]+ 010-0\d{3}-\d{4}$'));
    });
  });
}
