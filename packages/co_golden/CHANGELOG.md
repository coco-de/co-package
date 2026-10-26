# Changelog

## [0.4.0](https://github.com/coco-de/co-package/compare/co_golden-v0.3.0...co_golden-v0.4.0) (2026-10-26)


### 기능

* **co-golden:** ✨ Figma 원본과 구현을 골든 갤러리에서 비교 ([#115](https://github.com/coco-de/co-package/issues/115)) ([1fe6506](https://github.com/coco-de/co-package/commit/1fe6506c32455834fc81e202f1afcb83e922999c)), closes [#114](https://github.com/coco-de/co-package/issues/114)
* **co-golden:** ✨ Figma와 다른 서체·위젯·컴포넌트를 소스 위치와 함께 리포트 ([#116](https://github.com/coco-de/co-package/issues/116)) ([6391480](https://github.com/coco-de/co-package/commit/6391480bad79bb84517c736b8796a669b4adcb38))


### 상세

- Add optional per-variant `GoldenDesignReference` associations to scenarios.
  Capture mode snapshots local PNGs and records informational exact RGBA
  comparisons, visible diffs and unmodified geometry in run-manifest v1.
- Preserve existing golden pass/fail behavior: design differences and size
  mismatches are metadata, while invalid references fail `designComparison`.
- Add a design analysis for variants with a design reference
  (`GoldenMatrix.designAnalysis`, `GoldenDesignAnalysis`):
  - tolerant pixel comparison (CIEDE2000, positional radius, anti-aliasing,
    relaxed text boxes) with a ratio and largest-region budget, regions
    attributed to the design node and widget under them, and a tolerant diff
    map — rules and defaults shared with the `visual-verify` skill;
  - structural comparison with the design's node data
    (`GoldenDesignReference.specPath`: `co_golden.design_spec`, Figma REST
    nodes, or compare-frames output) that reports typography (role, family,
    weight, size, line height, letter spacing, runs), colors with token names,
    layout offsets relative to the nearest matched ancestor and sibling gaps,
    radii, borders, shadows, component types and variants, and missing or
    extra elements;
  - setup checks for fonts that fell back to the test font and images captured
    before decoding;
  - findings with source locations of the widgets that created them, written
    to `analysis/<suite>/<scenario>/<variant>.json`
    (`co_golden.design_report` v1) and summarized under
    `designComparison.analysis`.
- Add `GoldenDesignSystem`: CoUI's `components.json` catalog is discovered from
  the resolved `coui_flutter`, other design systems use
  `GoldenComponentMapping`, design packages, text roles, and theme color
  tokens. Design components missing from the catalog are reported as
  design-system extension candidates.
- Add masks with reasons (`GoldenDesignMask.rect`, `.figmaNode`, `.finder`,
  device safe-area bands by default) and `GoldenKnownDifference` for tracked
  differences that stay visible without failing the verdict.
- `GoldenDesignAnalysis.failOnMismatch` turns the verdict into a CI gate;
  `GoldenDesignAnalysis.off` keeps only the exact comparison.

## [0.3.0](https://github.com/coco-de/co-package/compare/co_golden-v0.2.0...co_golden-v0.3.0) (2026-09-30)


### 기능

* **co_golden:** ✨ 골든 시계 주입·파일 폰트 로더·CI 기준 이미지 가이드, co_faker release-please 편입 ([#35](https://github.com/coco-de/co-package/issues/35)) ([65f0bd0](https://github.com/coco-de/co-package/commit/65f0bd0422a1a2e89d0d7cb5188d53b8e0fcf6ab)), closes [#34](https://github.com/coco-de/co-package/issues/34)

## [0.2.0](https://github.com/coco-de/co-package/compare/co_golden-v0.1.0...co_golden-v0.2.0) (2026-09-29)


### 기능

* **co-golden:** ✨ co_golden · co_golden_gallery — 골든 매트릭스 러너와 정적 갤러리 생성기 ([#8](https://github.com/coco-de/co-package/issues/8)) ([5e7080d](https://github.com/coco-de/co-package/commit/5e7080dd36716765d028f755fa6986616061922c))
* **co-golden:** ✨ 런 매니페스트 plan.axes 에 커버리지 축 순서를 기록한다 ([e00ca8b](https://github.com/coco-de/co-package/commit/e00ca8b7b6e77b2b14c634a5d704904ec7191a17))


### 버그 수정

* **co-golden:** 🐛 Slang 지연 로딩 로케일을 setUpAll 에서 미리 로드한다 ([#9](https://github.com/coco-de/co-package/issues/9)) ([b0a1e12](https://github.com/coco-de/co-package/commit/b0a1e124dba8b3227f021413888792c76f3ced99))

## 0.1.0

- Initial release: `GoldenMatrix` registers one widget test per variant of a
  device × theme × locale × text scale coverage (`full`, `smoke`, `pairwise`
  sampling, exclusion rules, a hard variant budget).
- Theme-agnostic `GoldenTheme<T>` and device presets with pixel ratio, safe
  area, and platform applied to the test view.
- `SlangGoldenLocalization` switches Slang `LocaleSettings` per variant and
  fails on locales the app does not ship.
- `CO_GOLDEN_MODE` selects skip (default), capture (PNG + JSON run manifest,
  no comparison), or compare (`matchesGoldenFile`).
- Flutter errors such as overflows fail the variant while the image is still
  captured; `loadGoldenFonts` registers package fonts under their plain name.
