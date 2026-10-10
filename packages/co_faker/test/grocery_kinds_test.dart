import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

/// The eleven UI languages of the demos, by the co_faker locale each uses.
const _locales = <String>[
  'ko',
  'en_US',
  'zh_CN',
  'ja_JP',
  'de_DE',
  'fr_FR',
  'es_ES',
  'pt_BR',
  'it_IT',
  'ru_RU',
  'ar_SA',
];

/// The kind names in [CoFakerCatalog.groceryKindCodes] order, and the label
/// of a pack of 10, per locale.
const _expected = <String, (List<String>, String)>{
  'ko': (['계란', '한우 국거리', '루꼴라'], '10구'),
  'en_US': (['Eggs', 'Hanwoo beef for soup', 'Arugula'], '10-pack'),
  'zh_CN': (['鸡蛋', '韩牛汤用牛肉', '芝麻菜'], '10枚装'),
  'ja_JP': (['卵', '韓牛 スープ用', 'ルッコラ'], '10個入り'),
  'de_DE': (['Eier', 'Hanwoo-Rind für Suppe', 'Rucola'], '10er-Pack'),
  'fr_FR': (['Œufs', 'Bœuf Hanwoo pour soupe', 'Roquette'], 'x10'),
  'es_ES': (['Huevos', 'Ternera Hanwoo para sopa', 'Rúcula'], '10 uds.'),
  'pt_BR': (['Ovos', 'Carne Hanwoo para sopa', 'Rúcula'], '10 un.'),
  'it_IT': (['Uova', 'Manzo Hanwoo da brodo', 'Rucola'], '10 pz'),
  'ru_RU': (['Яйца', 'Говядина ханву для супа', 'Руккола'], 'в упаковке: 10'),
  'ar_SA': (['بيض', 'لحم هانوو للحساء', 'جرجير'], 'عبوة من 10'),
};

void main() {
  group('grocery kinds outside the rotating catalog', () {
    test('name egg, beef_stew, and rucola in all eleven languages', () {
      expect(CoFakerCatalog.groceryKindCodes, ['egg', 'beef_stew', 'rucola']);
      for (final locale in _locales) {
        final faker = CoFaker(seed: 0, locale: locale);
        final (names, packOf10) = _expected[locale]!;
        expect(
          [
            for (final code in CoFakerCatalog.groceryKindCodes)
              faker.catalog.groceryKindName(code),
          ],
          names,
          reason: locale,
        );
        expect(faker.catalog.groceryPackLabel(10), packOf10, reason: locale);
        for (final count in const [15, 20]) {
          expect(
            faker.catalog.groceryPackLabel(count),
            contains('$count'),
            reason: '$locale $count',
          );
        }
      }
    });

    test('is never the same text in every language', () {
      // A value written alike everywhere is what a demo shows when it has no
      // name — the fallback these kinds replace.
      for (final code in CoFakerCatalog.groceryKindCodes) {
        final names = {
          for (final locale in _locales)
            CoFaker(seed: 0, locale: locale).catalog.groceryKindName(code),
        };
        expect(names.length, greaterThan(1), reason: code);
      }
    });

    test('draws nothing from the random stream', () {
      for (final locale in _locales) {
        final untouched = CoFaker(seed: 11, locale: locale);
        final read = CoFaker(seed: 11, locale: locale);
        for (final code in CoFakerCatalog.groceryKindCodes) {
          read.catalog.groceryKindName(code);
        }
        read.catalog.groceryPackLabel(10);
        expect(
          read.random.int(max: 1 << 30),
          untouched.random.int(max: 1 << 30),
          reason: locale,
        );
      }
    });

    test('leave the rotating catalog where it was', () {
      for (final locale in _locales) {
        final faker = CoFaker(seed: 0, locale: locale);
        for (var index = 0; index < 48; index++) {
          expect(
            faker.catalog.item(grocery: true, index: index).name,
            faker.catalog.item(grocery: true, index: index % 7).name,
            reason: '$locale $index',
          );
        }
      }
    });

    test('reject an unknown kind and an empty pack', () {
      final faker = CoFaker(seed: 0, locale: 'ko');
      expect(
        () => faker.catalog.groceryKindName('spinach'),
        throwsArgumentError,
      );
      expect(() => faker.catalog.groceryPackLabel(0), throwsArgumentError);
    });
  });
}
