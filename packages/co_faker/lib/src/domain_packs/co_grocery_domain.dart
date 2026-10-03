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
    'originRegion': textRole(
      ['솔빛 재배권역(가상)', '가람 생산권역(가상)', '들녘 재배권역(가상)'],
      [
        'Solbit growing zone (fictional)',
        'Garam growing zone (fictional)',
        'Field growing zone (fictional)',
      ],
    ),
    'harvestNote': textRole(
      ['수확일과 포장일은 예시입니다.', '신선도 표시는 가상 상품 설명입니다.'],
      [
        'Harvest and packing dates are illustrative.',
        'Freshness text describes a fictional product.',
      ],
    ),
    'deliveryZone': textRole(
      ['솔빛 A권역(가상)', '가람 B권역(가상)', '들녘 C권역(가상)'],
      ['Demo Solbit zone A', 'Demo Garam zone B', 'Demo Field zone C'],
    ),
    'slotLabel': textRole(
      ['새벽 06:00~07:00', '저녁 18:00~20:00'],
      ['Dawn 06:00–07:00', 'Evening 18:00–20:00'],
    ),
    'substitutionNote': textRole(
      ['비슷한 중량의 품목으로 대체한 예시입니다.', '대체 없이 해당 줄을 환불한 예시입니다.'],
      [
        'Example replacement with a similar weight.',
        'Example refund without substitution.',
      ],
    ),
    'pickerName': firstNameRole(),
    'binLocation': authoredRole(
      (f, c) =>
          '${f.random.pick(['A', 'B', 'C'])}-${(1 + c.index % 12).toString().padLeft(2, '0')}-${1 + c.index % 4}',
    ),
    'doorNote': textRole(
      ['공동현관은 호출해 주세요.', '문 앞 보관 대신 직접 수령합니다.'],
      [
        'Please ring at the shared entrance.',
        'Hand delivery instead of leaving at the door.',
      ],
    ),
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
    'categoryName': taxonomyRole(
      ['과일', '채소', '간편식', '곡물', '육류', '수산', '유제품'],
      [
        'Fruit',
        'Vegetables',
        'Prepared foods',
        'Grain',
        'Meat',
        'Seafood',
        'Dairy',
      ],
    ),
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
