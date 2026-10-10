import '../co_faker.dart';
import 'authored_roles.dart';
import 'co_fake_catalog_item.dart';

/// Authored brand-free catalogs shared by commerce and fresh grocery packs.
class CoFakerCatalog {
  /// Uses only the supplied faker.
  const CoFakerCatalog(this.faker);

  /// Locale and random source.
  final CoFaker faker;

  /// Category, storage type, and price of each grocery item; its name and unit
  /// label are `catalog.groceryName` and `catalog.groceryUnit` in the language
  /// bundles, in the same order.
  static const _grocery = <(String, String, int)>[
    ('fruit', 'chilled', 12900),
    ('vegetable', 'chilled', 3480),
    ('prepared', 'frozen', 8900),
    ('grain', 'ambient', 9900),
    ('meat', 'chilled', 6900),
    ('seafood', 'frozen', 7900),
    ('dairy', 'chilled', 2800),
  ];

  /// Category, storage type, and price of each commerce item; its name and
  /// unit label are `catalog.commerceName` and `catalog.commerceUnit`.
  static const _commerce = <(String, String, int)>[
    ('digital', 'ambient', 29900),
    ('living', 'ambient', 15900),
    ('living', 'ambient', 12900),
    ('living', 'ambient', 9900),
    ('pantry', 'ambient', 5900),
  ];

  /// The grocery kinds that sit outside [item]'s rotating table, by stable
  /// code. Their names are `catalog.groceryKindName`, in this order.
  ///
  /// Adding a kind here never moves an item of the rotating table: a demo
  /// that pins some of its products to these kinds keeps every other
  /// product's name.
  static const List<String> groceryKindCodes = <String>[
    'egg',
    'beef_stew',
    'rucola',
  ];

  /// The name of the grocery kind [code] (one of [groceryKindCodes]) in the
  /// faker's language. Draws nothing from the random stream.
  String groceryKindName(String code) {
    final index = groceryKindCodes.indexOf(code);
    if (index < 0) {
      throw ArgumentError.value(code, 'code', 'not in groceryKindCodes');
    }
    return indexedText(
      faker,
      'catalog.groceryKindName',
      index,
      rows: groceryKindCodes.length,
    );
  }

  /// The label of a pack of [count] pieces (`10구`, `10-pack`), written after
  /// a kind name the way [CoFakeCatalogItem.unitLabel] is. Draws nothing from
  /// the random stream.
  String groceryPackLabel(int count) {
    if (count < 1) throw ArgumentError.value(count, 'count');
    return faker.l10n.format('catalog.groceryPackLabel', {'n': count});
  }

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
    final names = grocery ? 'catalog.groceryName' : 'catalog.commerceName';
    final units = grocery ? 'catalog.groceryUnit' : 'catalog.commerceUnit';
    return CoFakeCatalogItem(
      code: '$prefix-${((index ?? slot) + 1).toString().padLeft(4, '0')}',
      name: indexedText(faker, names, slot, rows: pool.length),
      category: spec.$1,
      unitLabel: indexedText(faker, units, slot, rows: pool.length),
      storageType: spec.$2,
      price: spec.$3,
      listPrice: spec.$3 + (grocery ? 3000 : 5000),
    );
  }
}
