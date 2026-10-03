import '../domain.dart';
import 'authored_roles.dart';

/// Fictional wholesale companies, package specifications and credit terms.
class CoB2bTradeDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoB2bTradeDomain();
  @override
  String get name => 'b2b_trade';
  static const _items = <(String, String, String, int, int)>[
    ('CUP', '12oz 종이컵 1,000입', '12oz paper cups, 1000 pieces', 1000, 66000),
    ('FRZ', '냉동 감자 10kg', 'Frozen potatoes, 10kg', 1, 160500),
    ('PKG', '종이 포장 봉투 100입', 'Paper bags, 100 pieces', 100, 18000),
    ('HYG', '무향 위생 수건 20입', 'Unscented hygiene towels, 20 pieces', 20, 24000),
  ];
  @override
  Map<String, CoDomainRole> get roles => {
    'buyerCompany': textRole(
      ['카페 온새(가상)', '제과점 밀담(가상)', '식자재점 솔내(가상)'],
      [
        'Onsae cafe (fictional)',
        'Mildam bakery (fictional)',
        'Solnae food shop (fictional)',
      ],
    ),
    'businessCategory': enumRole([
      'restaurant',
      'cafe',
      'bakery',
      'retail',
      'other',
    ]),
    'skuCode': authoredRole(
      (f, c) =>
          'HM-${_items[c.index % _items.length].$1}-${(c.index + 1).toString().padLeft(4, '0')}',
      coherent: true,
    ),
    'itemSpec': authoredRole(
      (f, c) => localized(
        f,
        _items[c.index % _items.length].$2,
        _items[c.index % _items.length].$3,
      ),
      coherent: true,
    ),
    'packUnit': authoredRole(
      (f, c) => _items[c.index % _items.length].$4,
      type: 'int',
      coherent: true,
    ),
    'priceTier': enumRole(['gold', 'silver', 'standard']),
    'creditTerm': enumRole(['credit_month_end', 'virtual_account']),
    'quoteTitle': textRole(
      ['월간 포장재 견적(가상)', '주간 식자재 견적(가상)', '위생용품 추가 견적(가상)'],
      [
        'Monthly packaging quote (fictional)',
        'Weekly food quote (fictional)',
        'Hygiene supplies quote (fictional)',
      ],
    ),
    'taxInvoiceNo': codeRole('DEMO-TAX', dated: true),
    'salesRepName': firstNameRole(),
    'holdReason': textRole(
      ['가용 한도 확인 대기(예시)', '납품일 확인 대기(예시)', '품목 규격 확인 대기(예시)'],
      [
        'Available credit check (example)',
        'Delivery date check (example)',
        'Item specification check (example)',
      ],
    ),
    'itemPrice': authoredRole(
      (f, c) => _items[c.index % _items.length].$5,
      type: 'int',
      coherent: true,
    ),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'buyer_account': {
      'id': 'int',
      'companyName': 'String',
      'businessType': 'String',
      'tierName': 'String',
      'status': 'String',
    },
    'wholesale_item': {
      'id': 'int',
      'skuCode': 'String',
      'name': 'String',
      'packUnit': 'int',
      'tierPrice': 'int',
    },
    'quote_request': {
      'id': 'int',
      'buyerId': 'int',
      'title': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'buyer_account': {
      'companyName': 'buyerCompany',
      'businessType': 'businessCategory',
      'tierName': 'priceTier',
    },
    'wholesale_item': {
      'skuCode': 'skuCode',
      'name': 'itemSpec',
      'packUnit': 'packUnit',
      'tierPrice': 'itemPrice',
    },
    'quote_request': {'title': 'quoteTitle'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'buyer_account': {
      'status': [
        'submitted',
        'reviewing',
        'approved',
        'rejected',
        'needs_more',
      ],
    },
    'quote_request': {
      'status': ['requested', 'quoted', 'accepted', 'declined', 'expired'],
    },
  };
}
