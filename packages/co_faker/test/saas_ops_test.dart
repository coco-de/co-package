import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 15, 20);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

  group('SaaS operations console', () {
    test('is deterministic for the same seed and clock', () {
      final a = ko(4);
      final b = ko(4);
      expect(a.saas.prepaidLedger(), b.saas.prepaidLedger());
      expect(a.saas.operator().toString(), b.saas.operator().toString());
      expect(a.saas.operatorEvent(), b.saas.operatorEvent());
      expect(a.saas.masterChanges(), b.saas.masterChanges());
      expect(a.saas.incidents(), b.saas.incidents());
      expect(
        a.saas.announcement().toString(),
        b.saas.announcement().toString(),
      );
    });

    test('prepaid bonus tiers and ledger balances', () {
      expect(CoFakerSaas.prepaidBonus(99999), 0);
      expect(CoFakerSaas.prepaidBonus(100000), 10000);
      expect(CoFakerSaas.prepaidBonus(1000000), 250000);
      expect(CoFakerSaas.prepaidBonus(15000000), 9000000);
      final ledger = ko().saas.prepaidLedger(count: 40);
      var balance = 0;
      for (final e in ledger) {
        balance += e.amount + e.bonus;
        expect(e.balanceAfter, balance);
        expect(e.balanceAfter, greaterThanOrEqualTo(0));
        if (e.kind == 'topUp') {
          expect(e.bonus, CoFakerSaas.prepaidBonus(e.amount));
          expect(['card', 'transfer', 'virtualAccount'], contains(e.method));
        } else {
          expect(e.amount, lessThan(0));
          expect(e.method, isNull);
        }
      }
      expect(ledger.first.kind, 'topUp');
    });

    test('advertising templates are rejected with a reason', () {
      final faker = ko();
      final ad = faker.saas.messageTemplate(code: 'AD_EVENT');
      expect(ad.advertising, isTrue);
      expect(ad.status, 'rejected');
      expect(ad.rejectReason, contains('광고성'));
      expect(
        faker.saas.messageTemplate(code: 'QUESTIONNAIRE').body,
        contains('#{문진링크}'),
      );
      expect(faker.saas.messageTemplate(code: 'SURVEY').advertising, isFalse);
      expect(() => faker.saas.messageTemplate(code: 'X'), throwsArgumentError);
    });

    test('operators and operator events', () {
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final op = faker.saas.operator();
        expect(faker.saas.operatorRoles, contains(op.role));
        if (op.role == 'owner' || op.role == 'admin') {
          expect(op.twoFactor, isTrue);
        }
        for (final ip in op.allowedIps) {
          expect(
            ip,
            matches(r'^(192\.0\.2|198\.51\.100|203\.0\.113)\.\d+/27$'),
          );
        }
        if (op.status == 'invited') expect(op.lastLoginAt, isNull);
        final event = faker.saas.operatorEvent();
        expect(event.action, contains('.'));
        expect(event.summary, contains(event.target));
      }
      final approve = faker.saas.operatorEvent(action: 'tenant.approve');
      expect(approve.actionLabel, '의원 가입 승인');
      expect(approve.target, endsWith('의원'));
    });

    test('invoice numbers, fixed statuses and autopay failures', () {
      final faker = ko();
      final monthly = faker.saas.invoice(
        numberFormat: CoInvoiceNumberFormat.monthly,
        sequence: 42,
      );
      expect(monthly.number, 'INV-2026-08-0042');
      final failed = faker.saas.invoice(status: 'failed');
      expect(failed.statusLabel, '결제 실패');
      expect(faker.saas.autopayFailureCodes, contains(failed.failureCode));
      expect(failed.failureReason, isNotEmpty);
      final weighted = List.generate(
        200,
        (_) => faker.saas.invoice(statusWeights: {'paid': 1, 'failed': 1}),
      );
      expect(weighted.map((i) => i.status).toSet(), {'paid', 'failed'});
      final list = faker.saas.invoices(3);
      expect(list.map((i) => i.number), [
        'INV-2026-08-0003',
        'INV-2026-07-0002',
        'INV-2026-06-0001',
      ]);
      expect(list.map((i) => i.supplyAmount).toSet(), hasLength(1));
    });

    test('claim master changes and checks', () {
      final faker = ko();
      final changes = faker.saas.masterChanges(kind: 'drug', count: 8);
      expect(changes, hasLength(8));
      for (final c in changes) {
        expect(c.code, matches(r'^EX-D\d{4}$'));
        switch (c.change) {
          case 'added':
            expect(c.oldPrice, isNull);
          case 'removed':
            expect(c.newPrice, isNull);
          default:
            expect(c.oldPrice, isNotNull);
        }
      }
      final dx = faker.saas.masterChanges(kind: 'diagnosis');
      expect(dx.every((c) => c.oldPrice == null && c.newPrice == null), isTrue);
      expect(
        faker.saas.masterChecks(allPass: true).every((c) => c.passed),
        isTrue,
      );
      expect(faker.saas.masterChecks(), hasLength(6));
    });

    test('integration snapshots are fixed per service', () {
      final first = ko(8).saas.integrationSnapshot();
      final shifted = ko(8)..saas.tenant();
      expect(shifted.saas.integrationSnapshot(), first);
      expect(first.map((s) => s.service), CoFakerSaas.services);
      for (final s in first) {
        expect(s.successRate, inInclusiveRange(40, 100));
        if (s.status == 'up') expect(s.successRate, greaterThanOrEqualTo(99));
      }
      final incidents = ko().saas.incidents(count: 10);
      for (var i = 1; i < incidents.length; i++) {
        expect(
          incidents[i].startedAt.isAfter(incidents[i - 1].startedAt),
          isFalse,
        );
        expect(incidents[i].resolved, isTrue);
      }
    });

    test('alerts, announcements and tenant activity', () {
      final faker = ko();
      expect(faker.saas.opsAlert(level: 'critical').level, 'critical');
      final regulation = faker.saas.announcement(kind: 'regulation');
      expect(regulation.title, contains('고시 반영'));
      expect(regulation.channels, containsAll(<String>['inApp', 'alimtalk']));
      expect(regulation.readRate, inInclusiveRange(0.2, 0.95));
      final release = faker.saas.announcement(kind: 'release');
      expect(release.title, matches(r'^EMR v\d{4}\.\d{2}\.\d 업데이트 안내$'));
      expect(release.items.length, inInclusiveRange(2, 3));
      final activity = faker.saas.tenantActivity(tenant: '데모피부과의원');
      expect(activity.tenant, '데모피부과의원');
      expect(activity.text, matches(r'\d'));
    });

    test('hourly and monthly time series', () {
      final faker = ko();
      final hourly = faker.saas.timeSeries(
        granularity: CoTimeGranularity.hour,
        base: 20,
        noise: 0,
      );
      expect(hourly, hasLength(24));
      expect(hourly.last.date, DateTime.utc(2026, 9, 30, 15));
      final byHour = {for (final p in hourly) p.date.hour: p.value};
      expect(byHour[3]!, lessThan(byHour[16]!));
      final monthly = faker.saas.timeSeries(
        granularity: CoTimeGranularity.month,
        count: 6,
      );
      expect(monthly.map((p) => p.date.month), [4, 5, 6, 7, 8, 9]);
      expect(monthly.every((p) => p.date.day == 1), isTrue);
      expect(faker.saas.timeSeries(days: 5), hasLength(5));
    });
  });
}
