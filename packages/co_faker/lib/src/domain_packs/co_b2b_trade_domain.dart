import '../domain.dart';
import 'authored_roles.dart';

/// Fictional wholesale companies, package specifications and credit terms.
class CoB2bTradeDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoB2bTradeDomain();
  @override
  String get name => 'b2b_trade';

  /// SKU code, pack unit, and price of each item; the item's specification text
  /// is `b2b_trade.itemSpec` in the same order.
  static const _items = <(String, int, int)>[
    ('CUP', 1000, 66000),
    ('FRZ', 1, 160500),
    ('PKG', 100, 18000),
    ('HYG', 20, 24000),
  ];
  @override
  Map<String, CoDomainRole> get roles => {
    'buyerCompany': textRole('b2b_trade.buyerCompany'),
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
    'itemSpec': indexedTextRole('b2b_trade.itemSpec', rows: _items.length),
    'packUnit': authoredRole(
      (f, c) => _items[c.index % _items.length].$2,
      type: 'int',
      coherent: true,
    ),
    'priceTier': enumRole(['gold', 'silver', 'standard']),
    'creditTerm': enumRole(['credit_month_end', 'virtual_account']),
    'quoteTitle': textRole('b2b_trade.quoteTitle'),
    'taxInvoiceNo': codeRole('DEMO-TAX', dated: true),
    'salesRepName': firstNameRole(),
    'holdReason': textRole('b2b_trade.holdReason'),
    'itemPrice': authoredRole(
      (f, c) => _items[c.index % _items.length].$3,
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
