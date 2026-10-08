import '../co_faker.dart';
import '../domain.dart';
import 'authored_roles.dart';
import 'co_fake_catalog_item.dart';
import 'co_faker_catalog.dart';

/// Fresh grocery and picker labels from an authored, coherent catalog.
class CoGroceryDomain extends CoFakerDomain {
  /// Creates this pack.
  const CoGroceryDomain();
  @override
  String get name => 'grocery';
  static CoFakeCatalogItem _item(CoFaker f, CoDomainRoleContext c) =>
      CoFakerCatalog(
        f.derive('grocery/catalog'),
      ).item(grocery: true, index: c.index);
  @override
  Map<String, CoDomainRole> get roles => {
    'produceName': authoredRole((f, c) => _item(f, c).name, coherent: true),
    'produceCategory': authoredRole(
      (f, c) => _item(f, c).category,
      coherent: true,
    ),
    'storageType': authoredRole(
      (f, c) => _item(f, c).storageType,
      coherent: true,
    ),
    'weightLabel': authoredRole(
      (f, c) => _item(f, c).unitLabel,
      coherent: true,
    ),
    'originRegion': textRole('grocery.originRegion'),
    'harvestNote': textRole('grocery.harvestNote'),
    'deliveryZone': textRole('grocery.deliveryZone'),
    'slotLabel': textRole('grocery.slotLabel'),
    'substitutionNote': textRole('grocery.substitutionNote'),
    'pickerName': firstNameRole(),
    'binLocation': authoredRole(
      (f, c) =>
          '${f.random.pick(['A', 'B', 'C'])}-${(1 + c.index % 12).toString().padLeft(2, '0')}-${1 + c.index % 4}',
    ),
    'doorNote': textRole('grocery.doorNote'),
    'productCode': authoredRole((f, c) => _item(f, c).code, coherent: true),
    'price': authoredRole(
      (f, c) => _item(f, c).price,
      type: 'int',
      coherent: true,
    ),
    'listPrice': authoredRole(
      (f, c) => _item(f, c).listPrice,
      type: 'int',
      coherent: true,
    ),
    'categoryParent': parentRole(7),
    'categoryName': taxonomyRole('grocery.categoryName'),
  };
  @override
  Map<String, Map<String, String>> get entities => const {
    'grocery_product': {
      'id': 'int',
      'code': 'String',
      'name': 'String',
      'category': 'String',
      'storageType': 'String',
      'weightLabel': 'String',
      'price': 'int',
      'listPrice': 'int',
      'imageUrl': 'String',
    },
    'produce_category': {
      'id': 'int',
      'name': 'String',
      'parentId': 'int',
      'sortOrder': 'int',
    },
    'grocery_order': {
      'id': 'int',
      'orderNo': 'String',
      'substitutionPolicy': 'String',
      'doorNote': 'String',
      'status': 'String',
    },
    'pick_line': {
      'id': 'int',
      'orderId': 'int',
      'productName': 'String',
      'binLocation': 'String',
      'status': 'String',
    },
  };
  @override
  Map<String, Map<String, String>> get entityRoles => const {
    'grocery_product': {
      'code': 'productCode',
      'name': 'produceName',
      'category': 'produceCategory',
      'storageType': 'storageType',
      'weightLabel': 'weightLabel',
      'price': 'price',
      'listPrice': 'listPrice',
    },
    'produce_category': {'name': 'categoryName', 'parentId': 'categoryParent'},
    'grocery_order': {'orderNo': 'commerce.orderNo', 'doorNote': 'doorNote'},
    'pick_line': {'productName': 'produceName', 'binLocation': 'binLocation'},
  };
  @override
  Map<String, Map<String, List<String>>> get enums => const {
    'grocery_order': {
      'substitutionPolicy': ['allow_similar', 'contact_first', 'refund'],
      'status': [
        'pending_payment',
        'paid',
        'picking',
        'packed',
        'out_for_delivery',
        'delivered',
        'cancelled',
      ],
    },
    'pick_line': {
      'status': ['pending', 'picked', 'substituted', 'refunded'],
    },
  };
}
