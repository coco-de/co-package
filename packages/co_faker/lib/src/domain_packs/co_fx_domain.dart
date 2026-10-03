import 'dart:convert';

import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_fx_currency.dart';
import 'co_faker_fx.dart';

/// FX roles shared by pickup, remittance and travel-wallet recipes.
class CoFxDomain extends CoFakerDomain {
  /// Creates the offline FX pack.
  const CoFxDomain();
  @override
  String get name => 'fx';

  static const _branches = <(String, String, String)>[
    ('airport', '가람환전 공항 T1(가상)', 'Demo airport T1 exchange'),
    ('downtown', '가람환전 솔빛점(가상)', 'Demo Solbit exchange'),
    ('airport', '가람환전 공항 T2(가상)', 'Demo airport T2 exchange'),
    ('downtown', '가람환전 가람점(가상)', 'Demo Garam exchange'),
    ('downtown', '가람환전 물푸레점(가상)', 'Demo Mulpare exchange'),
  ];

  static CoFakeFxCurrency _currency(CoFaker f, CoDomainRoleContext c) =>
      CoFakerFx(f).currency(code: CoFakerFx.currencyCodes[c.index % 6]);

  @override
  Map<String, CoDomainRole> get roles => {
    'currencyCode': authoredRole(
      (f, c) => _currency(f, c).code,
      coherent: true,
    ),
    'currencyName': authoredRole(
      (f, c) => _currency(f, c).name,
      coherent: true,
    ),
    'rateSeries': authoredRole(
      (f, c) => jsonEncode(
        CoFakerFx(f)
            .rateSeries(currencyCode: _currency(f, c).code)
            .map((p) => p.toJson())
            .toList(),
      ),
      coherent: true,
      description:
          'JSON array of 365 bounded daily UTC quotes; CoFakerFx.rateSeries for typed/30-day use',
    ),
    'denomination': authoredRole(
      (f, c) => CoFakerFx(
        f.derive('fx/denomination'),
      ).denomination(currencyCode: _currency(f, c).code),
      type: 'int',
      coherent: true,
    ),
    'maskedAccount': authoredRole((f, _) => CoFakerFx(f).maskedAccount()),
    'referenceNo': codeRole('NR', dated: true),
    'krwAmount': intRole(10000, 5000000, step: 1000),
    'branchName': authoredRole(
      (f, c) =>
          localized(f, _branches[c.index % 5].$2, _branches[c.index % 5].$3),
      coherent: true,
    ),
    'branchKind': authoredRole(
      (f, c) => _branches[c.index % 5].$1,
      coherent: true,
    ),
    'ticketNo': codeRole('A', width: 3),
    'passportNameMasked': authoredRole(
      (f, _) =>
          '${f.random.string(1, alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}*** ${f.random.string(1, alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}.',
      description: 'Masked name only, never a passport number',
    ),
    'orderNo': codeRole('GR', dated: true),
    'couponName': textRole(
      ['USD 80% 우대(예시)', 'JPY 70% 우대(예시)', '첫 환전 우대(예시)'],
      [
        'USD 80% spread discount (example)',
        'JPY 70% spread discount (example)',
        'First exchange discount (example)',
      ],
    ),
    'tierName': textRole(['브론즈', '실버', '골드'], ['Bronze', 'Silver', 'Gold']),
    'unitAmount': authoredRole(
      (f, c) => _currency(f, c).unitAmount,
      type: 'int',
      coherent: true,
    ),
    'baseRate': authoredRole(
      (f, c) => _currency(f, c).baseRate,
      type: 'double',
      coherent: true,
    ),
    'buyRate': authoredRole(
      (f, c) =>
          double.parse((_currency(f, c).baseRate * 0.9825).toStringAsFixed(2)),
      type: 'double',
      coherent: true,
    ),
    'sellRate': authoredRole(
      (f, c) =>
          double.parse((_currency(f, c).baseRate * 1.0175).toStringAsFixed(2)),
      type: 'double',
      coherent: true,
    ),
  };

  @override
  Map<String, Map<String, String>> get entities => const {
    'fx_rate': {
      'id': 'int',
      'currencyCode': 'String',
      'currencyName': 'String',
      'unitAmount': 'int',
      'baseRate': 'double',
      'buyRate': 'double',
      'sellRate': 'double',
    },
    'fx_branch': {
      'id': 'int',
      'name': 'String',
      'branchKind': 'String',
      'cashLevel': 'String',
      'imageUrl': 'String',
    },
    'pickup_order': {
      'id': 'int',
      'orderNo': 'String',
      'currencyCode': 'String',
      'branchId': 'int',
      'passportNameMasked': 'String',
      'status': 'String',
    },
    'order_line': {
      'id': 'int',
      'orderId': 'int',
      'currencyCode': 'String',
      'denomination': 'int',
      'quantity': 'int',
    },
    'pickup_ticket': {
      'id': 'int',
      'orderId': 'int',
      'ticketNo': 'String',
      'status': 'String',
    },
  };

  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'fx_rate': {
      'currencyCode': 'currencyCode',
      'currencyName': 'currencyName',
      'unitAmount': 'unitAmount',
      'baseRate': 'baseRate',
      'buyRate': 'buyRate',
      'sellRate': 'sellRate',
    },
    'fx_branch': {'name': 'branchName', 'branchKind': 'branchKind'},
    'pickup_order': {
      'orderNo': 'orderNo',
      'currencyCode': 'currencyCode',
      'passportNameMasked': 'passportNameMasked',
    },
    'order_line': {
      'currencyCode': 'currencyCode',
      'denomination': 'denomination',
    },
    'pickup_ticket': {'ticketNo': 'ticketNo'},
  };

  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'fx_branch': {
      'branchKind': ['airport', 'downtown'],
      'cashLevel': ['ample', 'normal', 'low'],
    },
    'pickup_order': {
      'status': [
        'requested',
        'deposit_confirmed',
        'ready',
        'picked_up',
        'expired',
        'canceled',
      ],
    },
    'pickup_ticket': {
      'status': ['waiting', 'called', 'served', 'no_show', 'canceled'],
    },
  };
}
