## Unreleased

- Render the gallery with Jaspr and `coui_web` components, using the
  `cocode-home` dark-first style and mint accent while retaining single-file
  HTML output and the existing CLI options. Document the CoUI overrides needed
  by downstream runner projects.

## [0.2.0](https://github.com/coco-de/co-package/compare/co_golden_gallery-v0.1.0...co_golden_gallery-v0.2.0) (2026-09-29)


### 기능

* **co-golden-gallery:** ✨ cocode 파비콘 세트 — cocode.im 과 같은 SVG · 32px · apple-touch-icon ([adbfaee](https://github.com/coco-de/co-package/commit/adbfaeedfeb07f541d998c8ff125b8f455894da4))
* **co-golden-gallery:** CoUI Web과 cocode.im 스타일 적용 ([#12](https://github.com/coco-de/co-package/issues/12)) ([a1f1cca](https://github.com/coco-de/co-package/commit/a1f1cca063a27676ba92a1eb3150d938a5e735fb))
* **co-golden:** ✨ co_golden · co_golden_gallery — 골든 매트릭스 러너와 정적 갤러리 생성기 ([#8](https://github.com/coco-de/co-package/issues/8)) ([5e7080d](https://github.com/coco-de/co-package/commit/5e7080dd36716765d028f755fa6986616061922c))


### 버그 수정

* **co-golden-gallery:** 🐛 필터가 숨긴 요소가 보이던 문제 · 격자 축 순서 · 축 없는 이미지 구역 · favicon ([d34c91b](https://github.com/coco-de/co-package/commit/d34c91b7ff0cb679eb8de4e72f1dad0b575d14ff))

## 0.1.0

- Initial release: `co_golden_gallery build` turns co_golden run manifests
  and plain PNG trees into one self-contained `index.html` with a device ×
  variant grid per scenario, search and filters, and a lightbox.
- Images are referenced locally, copied with `--copy-images`, or served from
  `--asset-base-url`; `--noindex`, `--meta`, `--link`, and `--summary` for
  publishing pipelines.
- Strict input handling: foreign or newer manifests, missing images, and
  conflicting inputs fail with exit code 65.
