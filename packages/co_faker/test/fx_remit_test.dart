import 'dart:convert';

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

CoFaker _faker({String locale = 'ko'}) => CoFaker(
  locale: locale,
  seed: 436,
  now: DateTime.utc(2026, 1, 15),
  domains: CoFakerDomains.all,
);

void main() {
  test('FX histories have coherent UTC dates, endpoints, bounds and twins', () {
    for (final code in CoFakerFx.currencyCodes) {
      final f = _faker();
      final points = f.fx.rateSeries(currencyCode: code);
      expect(
        points.map((p) => p.toJson()).toList(),
        _faker().fx
            .rateSeries(currencyCode: code)
            .map((p) => p.toJson())
            .toList(),
      );
      expect(points, hasLength(365));
      expect(points.last.recordedAt, DateTime.utc(2026, 1, 15));
      final endRate = f.fx.currency(code: code).baseRate;
      expect(points.last.rate, endRate);
      for (var i = 0; i < points.length; i++) {
        expect(points[i].currencyCode, code);
        expect(points[i].recordedAt.isUtc, isTrue);
        expect(
          points[i].rate,
          inInclusiveRange(endRate * 0.85, endRate * 1.15),
        );
        if (i > 0) {
          expect(
            points[i].recordedAt.difference(points[i - 1].recordedAt),
            const Duration(days: 1),
          );
        }
      }
      final month = f.fx.rateSeries(currencyCode: code, days: 30);
      expect(
        month.map((p) => p.toJson()).toList(),
        points.skip(335).map((p) => p.toJson()).toList(),
      );
      f.random.int();
      expect(
        f.fx.rateSeries(currencyCode: code).map((p) => p.toJson()).toList(),
        points.map((p) => p.toJson()).toList(),
      );
    }
  });

  test('FX primitive adapter is real JSON, never a scalar substitute', () {
    final row = _faker().schema.record(
      {'rates': 'String'},
      roles: {'rates': 'fx.rateSeries'},
    );
    final values = jsonDecode(row['rates'] as String) as List;
    expect(values, hasLength(365));
    expect((values.first as Map)['recordedAt'], endsWith('Z'));
    expect((values.last as Map)['rate'], 1452.30);
    expect(
      () => _faker().schema.record(
        {'rates': 'double'},
        roles: {'rates': 'fx.rateSeries'},
      ),
      throwsArgumentError,
    );
    final report = CoFakerCoverage(_faker()).check(const [
      CoCoverageEntity(
        'rates',
        fields: {'value': 'double'},
        roles: {'value': 'fx.rateSeries'},
      ),
    ]);
    expect(report.rows.single.status, CoCoverageStatus.unsupported);
  });

  test('quote units and denominations match currency in schema records', () {
    final f = _faker();
    final quotes = f.schema.entities('fx.fx_rate', 6);
    for (var i = 0; i < quotes.length; i++) {
      final row = quotes[i];
      final expected = f.fx.currency(code: row['currencyCode'] as String);
      expect(row['currencyName'], expected.name);
      expect(row['baseRate'], expected.baseRate);
      expect(row['unitAmount'], expected.unitAmount);
      expect(row['buyRate'] as double, lessThan(expected.baseRate));
      expect(row['sellRate'] as double, greaterThan(expected.baseRate));
      final line = f.schema.entity(
        'fx.order_line',
        index: i,
        referenceCounts: {'orderId': 3},
      );
      expect(line['orderId'], inInclusiveRange(1, 3));
      expect(expected.denominations, contains(line['denomination']));
    }
    final branches = f.schema.entities('fx.fx_branch', 5);
    expect(branches.map((r) => r['name']).toSet(), hasLength(5));
    expect(branches.where((r) => r['branchKind'] == 'airport'), hasLength(2));
    expect(branches.where((r) => r['branchKind'] == 'downtown'), hasLength(3));
    for (final branch in branches) {
      expect(
        (branch['name'] as String).contains('공항'),
        branch['branchKind'] == 'airport',
      );
    }
  });

  test(
    'remittance helpers link masked recipients and exact amount arithmetic',
    () {
      const corridors = {
        'VN': 'VND',
        'PH': 'PHP',
        'NP': 'NPR',
        'US': 'USD',
        'CN': 'CNY',
      };
      for (final locale in ['ko', 'en', 'pt']) {
        for (var i = 0; i < CoFakerRemit.statuses.length; i++) {
          final f = _faker(locale: locale);
          final country =
              CoFakerRemit.countryCodes[i % CoFakerRemit.countryCodes.length];
          final r = f.remit.recipient(index: i, countryCode: country);
          final t = f.remit.transfer(
            index: i,
            recipient: r,
            sendAmount: 1000000,
          );
          expect(r.currencyCode, corridors[country]);
          expect(r.name, matches(RegExp(r'^[A-Z]\*{3} [A-Z]\. [A-Z]\.$')));
          expect(r.accountMasked, matches(RegExp(r'^\*{4}-\*{2}-\d{4}$')));
          expect(t.recipient, same(r));
          expect(t.receiveAmount, closeTo(t.sendAmount * t.appliedRate, 0.005));
          if (country == 'VN') {
            expect(t.receiveAmount, 17850000.0);
            expect(t.rateNumerator, 1785);
            expect(t.rateDenominator, 100);
            expect(t.receiveMinorDigits, 0);
            expect(t.receiveMinorUnits, 17850000);
          } else {
            expect(t.receiveMinorDigits, 2);
            expect(t.receiveMinorUnits, (t.receiveAmount * 100).round());
          }
          expect(t.requestedAt.isUtc, isTrue);
          expect(t.expectedArrivalAt.isAfter(t.requestedAt), isTrue);
          final history = f.remit.milestones(t);
          expect(history.last['stage'], t.status);
          for (var j = 0; j < history.length; j++) {
            expect(history[j]['transferReference'], t.referenceNo);
            expect(
              DateTime.parse(history[j]['occurredAt'] as String).isAfter(f.now),
              isFalse,
            );
            if (j > 0) {
              expect(
                DateTime.parse(history[j]['occurredAt'] as String).isAfter(
                  DateTime.parse(history[j - 1]['occurredAt'] as String),
                ),
                isTrue,
              );
            }
          }
        }
      }
    },
  );

  test('schema records are coherent and unrelated fields preserve values', () {
    final f = _faker();
    final rows = f.schema.entities(
      'remit.remittance',
      8,
      referenceCounts: {'recipientId': 4},
    );
    expect(rows.map((r) => r['status']).toSet(), CoFakerRemit.statuses.toSet());
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      expect(row['recipientId'], inInclusiveRange(1, 4));
      expect(
        row['receiveAmount'] as double,
        closeTo(
          (row['sendAmount'] as int) * (row['appliedRate'] as double),
          0.005,
        ),
      );
      final fields = f.domains.findEntity('remit.remittance')!.fields;
      final extended = _faker().schema.record(
        {'unrelated': 'String', ...fields},
        index: i,
        streamKey: 'remit.remittance',
        entity: 'remit.remittance',
        referenceCounts: {'recipientId': 4},
      );
      for (final field in row.keys) {
        expect(extended[field], row[field], reason: field);
      }
    }
    expect(
      _faker().schema.entities(
        'remit.remittance',
        8,
        referenceCounts: {'recipientId': 4},
      ),
      rows,
    );
  });

  test('unknown currency/corridor, invalid range and unknown roles fail', () {
    final f = _faker();
    expect(() => f.fx.currency(code: 'ZZZ'), throwsArgumentError);
    expect(() => f.fx.rateSeries(days: 0), throwsArgumentError);
    expect(() => f.fx.rateSeries(endRate: double.nan), throwsArgumentError);
    expect(() => f.remit.recipient(countryCode: 'ZZ'), throwsArgumentError);
    expect(() => f.remit.transfer(sendAmount: -1), throwsArgumentError);
    expect(() => f.remit.transfer(status: 'not_a_stage'), throwsArgumentError);
    expect(() => f.schema.entity('remit.unknown'), throwsArgumentError);
    expect(
      () => f.schema.record({'name': 'String'}, roles: {'name': 'fx.unknown'}),
      throwsArgumentError,
    );
  });
}
