import 'dart:ui' show Brightness, Locale, Size;

import 'package:co_golden/co_golden.dart';
import 'package:flutter_test/flutter_test.dart';

const GoldenTheme<String> _light = GoldenTheme(name: 'light', data: 'L');
const GoldenTheme<String> _dark = GoldenTheme(
  name: 'dark',
  data: 'D',
  brightness: Brightness.dark,
);
const List<GoldenDevice> _devices = [
  GoldenDevice.phoneCompact,
  GoldenDevice.phone,
  GoldenDevice.tablet,
  GoldenDevice.desktop,
];
const List<Locale> _locales = [Locale('ko'), Locale('en')];

GoldenCoverage<String> _coverage({
  List<GoldenDevice> devices = _devices,
  List<GoldenTheme<String>> themes = const [_light, _dark],
  List<Locale> locales = _locales,
  List<double> textScales = const [1],
  GoldenSampling sampling = GoldenSampling.full,
  List<GoldenCoverageRule<String>> rules = const [],
  int? maxVariants,
}) => GoldenCoverage<String>(
  devices: devices,
  themes: themes,
  locales: locales,
  textScales: textScales,
  sampling: sampling,
  rules: rules,
  maxVariants: maxVariants,
);

Set<String> _values(Iterable<GoldenVariant<String>> variants) => {
  for (final variant in variants) ...[
    'device=${variant.device.name}',
    'theme=${variant.theme.name}',
    'locale=${variant.localeTag}',
  ],
};

Set<String> _pairs(Iterable<GoldenVariant<String>> variants) => {
  for (final variant in variants) ...[
    '${variant.device.name}|${variant.theme.name}',
    '${variant.device.name}|${variant.localeTag}',
    '${variant.theme.name}|${variant.localeTag}',
  ],
};

void main() {
  group('full sampling', () {
    test('expands every combination in axis order', () {
      final plan = _coverage().plan();

      expect(plan.combinations, 16);
      expect(plan.variants, hasLength(16));
      expect(plan.excluded, isEmpty);
      expect(plan.variants.first.fileStem, 'phone-compact__light__ko');
      expect(plan.variants[1].fileStem, 'phone-compact__light__en');
      expect(plan.variants.last.fileStem, 'desktop__dark__en');
      expect(
        plan.variants.map((variant) => variant.fileStem).toSet(),
        hasLength(16),
      );
    });

    test('adds a text token only when the scale is not 1', () {
      final plan = _coverage(
        devices: const [GoldenDevice.phone],
        themes: const [_light],
        locales: const [Locale('en')],
        textScales: const [1, 1.3],
      ).plan();

      expect(plan.variants.map((variant) => variant.fileStem), [
        'phone__light__en',
        'phone__light__en__text-1.3',
      ]);
      expect(plan.variants.last.label, 'phone · light · en · text 1.3x');
    });

    test('lowercases script and region subtags in file names', () {
      final plan = _coverage(
        devices: const [GoldenDevice.phone],
        themes: const [_light],
        locales: const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ],
      ).plan();

      expect(plan.variants.single.fileStem, 'phone__light__zh-hans');
      expect(plan.variants.single.localeTag, 'zh-Hans');
    });
  });

  group('rules', () {
    test('exclude matching variants and keep the reason', () {
      final plan = _coverage(
        rules: [
          GoldenCoverageRule<String>.exclude(
            'desktop ships light only',
            (variant) =>
                variant.device.name == 'desktop' &&
                variant.theme.name == 'dark',
          ),
        ],
      ).plan();

      expect(plan.variants, hasLength(14));
      expect(plan.excluded, hasLength(2));
      expect(plan.excluded.map((entry) => entry.reason).toSet(), {
        'desktop ships light only',
      });
      expect(
        plan.variants.where(
          (variant) =>
              variant.device.name == 'desktop' && variant.theme.name == 'dark',
        ),
        isEmpty,
      );
    });

    test('fail when every combination is excluded', () {
      final coverage = _coverage(
        rules: [GoldenCoverageRule<String>.exclude('all', (_) => true)],
      );

      expect(coverage.plan, throwsStateError);
    });
  });

  group('smoke sampling', () {
    test('covers every axis value with far fewer variants', () {
      final full = _coverage().plan().variants;
      final smoke = _coverage(sampling: GoldenSampling.smoke).plan().variants;

      expect(_values(smoke), _values(full));
      expect(smoke, hasLength(4));
    });
  });

  group('pairwise sampling', () {
    test('covers every pair of values from two axes', () {
      final full = _coverage().plan().variants;
      final pairwise = _coverage(
        sampling: GoldenSampling.pairwise,
      ).plan().variants;

      expect(_pairs(pairwise), _pairs(full));
      expect(pairwise.length, lessThan(full.length));
    });

    test('keeps plan order', () {
      final full = _coverage().plan().variants;
      final pairwise = _coverage(
        sampling: GoldenSampling.pairwise,
      ).plan().variants;
      final positions = [for (final variant in pairwise) full.indexOf(variant)];

      expect(positions, orderedEquals([...positions]..sort()));
    });
  });

  group('validation', () {
    test('rejects an empty axis', () {
      expect(_coverage(locales: const []).plan, throwsArgumentError);
    });

    test('rejects names that cannot be path segments', () {
      final coverage = _coverage(
        devices: const [
          GoldenDevice(name: 'Pixel 8', logicalSize: Size(412, 915)),
        ],
      );

      expect(coverage.plan, throwsArgumentError);
    });

    test('rejects duplicate axis values', () {
      expect(
        _coverage(themes: const [_light, _light]).plan,
        throwsArgumentError,
      );
    });

    test('rejects text scales that are not positive', () {
      expect(_coverage(textScales: const [0]).plan, throwsArgumentError);
    });

    test('refuses to weaken coverage beyond the budget', () {
      expect(
        _coverage(maxVariants: 10).plan,
        throwsA(
          isA<GoldenCoverageBudgetExceeded>()
              .having((error) => error.required, 'required', 16)
              .having((error) => error.budget, 'budget', 10),
        ),
      );
    });
  });
}
