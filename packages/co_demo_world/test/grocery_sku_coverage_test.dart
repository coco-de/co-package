import 'package:co_demo_world/co_demo_world.dart';
import 'package:test/test.dart';

import 'support/sample_world.dart';

/// The grocery demo's products that its supply catalog did not name: product
/// number → (kind code, pack count or size).
const _pinnedKinds = <int, (String, int?, String)>{
  4: ('egg', 10, ''),
  11: ('egg', 15, ''),
  18: ('egg', 20, ''),
  8: ('beef_stew', null, '300g'),
  31: ('rucola', null, '100g'),
};

const _productCount = 48;

String _productId(int number) => 'GP-${number.toString().padLeft(4, '0')}';

/// `product.name` the way the grocery demo projects it: the rotating catalog
/// for most products, and for the pinned ones either the SKU fallback it
/// shows today or the kind name co_faker now supplies.
DisplayFieldSet _productNames({required bool supplied}) => DisplayFieldSet({
  'product.name': (faker, key) {
    final number = int.parse(key.id.substring(3));
    final pinned = _pinnedKinds[number];
    if (pinned == null) {
      final item = faker.catalog.item(grocery: true, index: (number - 1) % 7);
      return '${item.name} ${item.unitLabel}';
    }
    final (code, count, size) = pinned;
    if (!supplied) return '${key.id} · ${count ?? size}';
    final label = count == null ? size : faker.catalog.groceryPackLabel(count);
    return '${faker.catalog.groceryKindName(code)} $label';
  },
});

List<LocaleFieldReport> _evaluate({required bool supplied}) =>
    DemoLocaleSupport.evaluate(
      config: sampleConfig,
      fields: _productNames(supplied: supplied),
      samples: {
        'product.name': [
          for (var number = 1; number <= _productCount; number++)
            DisplayKey('product', _productId(number), 'name'),
        ],
      },
    );

void main() {
  group('product.name of the grocery demo', () {
    test('five SKU fallbacks keep it from native in every language', () {
      final reports = _evaluate(supplied: false);
      expect(reports, hasLength(DemoLocale.values.length));
      for (final report in reports) {
        // 5 of 48 is under every ratio the classifier uses, so the
        // fallback has to be found key by key — English included.
        expect(
          report.status,
          LocaleFieldStatus.partialFallback,
          reason: '$report',
        );
        expect(
          [for (final gap in report.gaps) gap.key.id],
          ['GP-0004', 'GP-0008', 'GP-0011', 'GP-0018', 'GP-0031'],
          reason: '$report',
        );
        expect(report.gaps.map((gap) => gap.reason).toSet(), {
          LocaleFieldGapReason.languageNeutral,
        });
        expect(report.gaps.first.value, 'GP-0004 · 10');
      }
    });

    test('is native in all eleven languages once the kinds are named', () {
      final reports = _evaluate(supplied: true);
      for (final report in reports) {
        expect(report.status, LocaleFieldStatus.native, reason: '$report');
        expect(report.gaps, isEmpty, reason: '$report');
      }
    });

    test('names each of the five products in all eleven languages', () {
      final projector = DisplayProjector(
        config: sampleConfig,
        fields: _productNames(supplied: true),
      );
      for (final number in _pinnedKinds.keys) {
        final key = DisplayKey('product', _productId(number), 'name');
        final names = {
          for (final locale in DemoLocale.values)
            locale: projector.generated(key, locale: locale),
        };
        for (final MapEntry(key: locale, value: name) in names.entries) {
          expect(name, isNot(contains(key.id)), reason: '${locale.tag} $name');
        }
        // Some languages share a spelling (Rucola, Rúcula); the eleven are
        // never one text.
        expect(names.values.toSet().length, greaterThan(5), reason: '$names');
        // Switching back returns the same text.
        expect(
          projector.generated(key, locale: DemoLocale.ar),
          names[DemoLocale.ar],
        );
      }
    });
  });

  test('a field of codes alone is judged by the ratios, not as gaps', () {
    final reports = DemoLocaleSupport.evaluate(
      config: sampleConfig,
      fields: DisplayFieldSet({'product.code': (faker, key) => key.id}),
    );
    for (final report in reports) {
      expect(report.gaps, isEmpty, reason: '$report');
    }
    expect(
      reports.firstWhere((report) => report.locale == DemoLocale.en).status,
      LocaleFieldStatus.native,
    );
  });
}
