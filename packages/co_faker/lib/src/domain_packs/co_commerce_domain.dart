import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_catalog_item.dart';
import 'co_faker_catalog.dart';

/// Brand-free catalog values and common order/price/coupon roles.
class CoCommerceDomain extends CoFakerDomain {
  /// Creates the common commerce pack.
  const CoCommerceDomain();
  @override
  String get name => 'commerce';
  static CoFakeCatalogItem _item(CoFaker f, CoDomainRoleContext c) =>
      CoFakerCatalog(f.derive('commerce/catalog')).item(index: c.index);
  @override
  Map<String, CoDomainRole> get roles => {
    'orderNo': codeRole('DEMO-O', dated: true),
    'productCode': authoredRole((f, c) => _item(f, c).code, coherent: true),
    'productName': authoredRole((f, c) => _item(f, c).name, coherent: true),
    'price': authoredRole(
      (f, c) => _item(f, c).price,
      type: 'int',
      coherent: true,
    ),
    'salePrice': authoredRole(
      (f, c) => _item(f, c).price,
      type: 'int',
      coherent: true,
    ),
    'listPrice': authoredRole(
      (f, c) => _item(f, c).listPrice,
      type: 'int',
      coherent: true,
    ),
    'category': authoredRole((f, c) => _item(f, c).category, coherent: true),
    'couponCode': codeRole('DEMO-COUPON'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'product': {
      'id': 'int',
      'code': 'String',
      'name': 'String',
      'price': 'int',
      'listPrice': 'int',
      'category': 'String',
      'imageUrl': 'String',
    },
    'order': {'id': 'int', 'orderNo': 'String', 'status': 'String'},
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'product': {
      'code': 'productCode',
      'name': 'productName',
      'price': 'price',
      'listPrice': 'listPrice',
      'category': 'category',
    },
    'order': {'orderNo': 'orderNo'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'order': {
      'status': [
        'pending_payment',
        'paid',
        'preparing',
        'shipped',
        'delivered',
        'cancelled',
      ],
    },
  };
}
