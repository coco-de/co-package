/// A single fictional catalog entry, with coherent code/name/price/category.
class CoFakeCatalogItem {
  /// Constructs an authored item with its unit and example prices.
  const CoFakeCatalogItem({
    required this.code,
    required this.name,
    required this.category,
    required this.price,
    required this.listPrice,
    required this.unitLabel,
    this.storageType = 'ambient',
  });

  /// Fictional SKU.
  final String code;

  /// Localized generic product name.
  final String name;

  /// Category code.
  final String category;

  /// Illustrative selling price in KRW.
  final int price;

  /// Illustrative list price, never lower than [price].
  final int listPrice;

  /// Size/unit label appropriate to the product.
  final String unitLabel;

  /// Storage code: chilled, frozen or ambient.
  final String storageType;

  /// Primitive JSON adapter.
  Map<String, Object?> toJson() => {
    'code': code,
    'name': name,
    'category': category,
    'price': price,
    'listPrice': listPrice,
    'weightLabel': unitLabel,
    'storageType': storageType,
  };
}
