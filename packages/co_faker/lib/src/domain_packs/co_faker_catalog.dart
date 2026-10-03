import '../co_faker.dart';
import 'authored_roles.dart';
import 'co_fake_catalog_item.dart';

/// Authored brand-free catalogs shared by commerce and fresh grocery packs.
class CoFakerCatalog {
  /// Uses only the supplied faker.
  const CoFakerCatalog(this.faker);

  /// Locale and random source.
  final CoFaker faker;
  static const _grocery = <(String, String, String, String, String, int)>[
    ('딸기', 'Strawberries', 'fruit', '500g', 'chilled', 12900),
    ('시금치', 'Spinach', 'vegetable', '200g', 'chilled', 3480),
    ('손만두', 'Handmade dumplings', 'prepared', '1kg', 'frozen', 8900),
    ('현미', 'Brown rice', 'grain', '2kg', 'ambient', 9900),
    ('닭 안심', 'Chicken tenderloin', 'meat', '500g', 'chilled', 6900),
    ('냉동 고등어', 'Frozen mackerel', 'seafood', '600g', 'frozen', 7900),
    ('우유', 'Milk', 'dairy', '1L', 'chilled', 2800),
  ];
  static const _commerce = <(String, String, String, String, String, int)>[
    ('무선 이어폰', 'Wireless earphones', 'digital', '1 pair', 'ambient', 29900),
    ('접이식 수납함', 'Folding storage box', 'living', '1 box', 'ambient', 15900),
    ('면 수건 세트', 'Cotton towel set', 'living', '3 pieces', 'ambient', 12900),
    ('도자기 컵', 'Ceramic cup', 'living', '1 piece', 'ambient', 9900),
    ('곡물 간식', 'Grain snack', 'pantry', '200g', 'ambient', 5900),
  ];

  /// Selects one product; all fields originate from the same catalog entry.
  CoFakeCatalogItem item({bool grocery = false, int? index}) {
    if (index != null && index < 0) {
      throw ArgumentError.value(index, 'index');
    }
    final pool = grocery ? _grocery : _commerce;
    final slot = index == null
        ? faker.random.int(max: pool.length - 1)
        : index % pool.length;
    final spec = pool[slot];
    final prefix = grocery ? 'GP' : 'CP';
    return CoFakeCatalogItem(
      code: '$prefix-${((index ?? slot) + 1).toString().padLeft(4, '0')}',
      name: localized(faker, spec.$1, spec.$2),
      category: spec.$3,
      unitLabel: spec.$4,
      storageType: spec.$5,
      price: spec.$6,
      listPrice: spec.$6 + (grocery ? 3000 : 5000),
    );
  }
}
