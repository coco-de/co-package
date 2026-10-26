# Changelog

## [0.3.0](https://github.com/coco-de/co-package/compare/co_golden_gallery-v0.2.2...co_golden_gallery-v0.3.0) (2026-10-26)


### 기능

* **co-golden:** ✨ Figma 원본과 구현을 골든 갤러리에서 비교 ([#115](https://github.com/coco-de/co-package/issues/115)) ([1fe6506](https://github.com/coco-de/co-package/commit/1fe6506c32455834fc81e202f1afcb83e922999c)), closes [#114](https://github.com/coco-de/co-package/issues/114)
* **co-golden:** ✨ Figma와 다른 서체·위젯·컴포넌트를 소스 위치와 함께 리포트 ([#116](https://github.com/coco-de/co-package/issues/116)) ([6391480](https://github.com/coco-de/co-package/commit/6391480bad79bb84517c736b8796a669b4adcb38))


### 버그 수정

* **co-golden-gallery:** support CoUI v2 badge APIs ([#113](https://github.com/coco-de/co-package/issues/113)) ([8c6f549](https://github.com/coco-de/co-package/commit/8c6f549a0423e9c358275a4a1139fd8df58b324b))


### 상세

- Show co_golden design analyses: a tolerance verdict line, a findings panel
  grouped by category (font loading, frame, missing/extra, component,
  typography, content, color, layout, shape, pixels) with design →
  implementation values, Figma nodes, widget source locations, components,
  fix hints, and known differences, SVG marks on the design and the
  implementation, region and mask overlays, and a tolerance difference mode.
  Thumbnails and the design filter follow the verdict when present.
- Copy and serve design reports and tolerance maps like other auxiliary
  assets; reject unsafe paths, unreadable or newer reports, and reports that
  belong to another variant.
- Extend `--summary` with `designVerdicts`, `designFindingCounts`, per-variant
  `analysis`, and a flattened `designFindings` list, and add
  `--design-report <file.md>` for AI agents and pull request comments.
- Add per-variant Figma/design comparisons: opacity overlay, side-by-side,
  reference and exact diff views, source links, design-differences filtering,
  and summary metadata. Preserve old manifests and all asset-serving modes;
  reject unsafe comparison paths and expose incompatible pixel geometry.
- Migrate scenario badges to CoUI v2 tone/variant APIs and require coui_web 0.162.0.

## [0.2.2](https://github.com/coco-de/co-package/compare/co_golden_gallery-v0.2.1...co_golden_gallery-v0.2.2) (2026-09-30)


### 문서

* **co_golden_gallery:** 📝 GitHub Pages 하위 경로 배포 안내 ([#36](https://github.com/coco-de/co-package/issues/36)) ([c20ae2c](https://github.com/coco-de/co-package/commit/c20ae2c0c6bb5b6c0be335810bdf2a7145894ec9)), closes [#34](https://github.com/coco-de/co-package/issues/34)

## [0.2.1](https://github.com/coco-de/co-package/compare/co_golden_gallery-v0.2.0...co_golden_gallery-v0.2.1) (2026-09-30)


### 버그 수정

* **co_golden_gallery:** 🐛 넓은 화면에서 갤러리 본문 폭이 줄어드는 문제 수정 ([2cf03e8](https://github.com/coco-de/co-package/commit/2cf03e8cc9a17b1c4030c74b2f54ea07bfb226d6))
* **co_golden_gallery:** 🐛 넓은 화면에서 갤러리 콘텐츠 폭 수축 수정 ([0ee4ab4](https://github.com/coco-de/co-package/commit/0ee4ab47ea687a5dd666901e0b2f99fc11f72f63))

## [0.2.0](https://github.com/coco-de/co-package/compare/co_golden_gallery-v0.1.0...co_golden_gallery-v0.2.0) (2026-09-29)


### 기능

* **co-golden-gallery:** ✨ cocode 파비콘 세트 — cocode.im 과 같은 SVG · 32px · apple-touch-icon ([adbfaee](https://github.com/coco-de/co-package/commit/adbfaeedfeb07f541d998c8ff125b8f455894da4))
* **co-golden-gallery:** CoUI Web과 cocode.im 스타일 적용 ([#12](https://github.com/coco-de/co-package/issues/12)) ([a1f1cca](https://github.com/coco-de/co-package/commit/a1f1cca063a27676ba92a1eb3150d938a5e735fb))
* **co-golden:** ✨ co_golden · co_golden_gallery — 골든 매트릭스 러너와 정적 갤러리 생성기 ([#8](https://github.com/coco-de/co-package/issues/8)) ([5e7080d](https://github.com/coco-de/co-package/commit/5e7080dd36716765d028f755fa6986616061922c))


### 버그 수정

* **co-golden-gallery:** 🐛 필터가 숨긴 요소가 보이던 문제 · 격자 축 순서 · 축 없는 이미지 구역 · favicon ([d34c91b](https://github.com/coco-de/co-package/commit/d34c91b7ff0cb679eb8de4e72f1dad0b575d14ff))


### 상세

- Render the gallery with Jaspr and `coui_web` components, using the
  `cocode-home` dark-first style and mint accent while retaining single-file
  HTML output and the existing CLI options. Document the CoUI overrides needed
  by downstream runner projects.

## 0.1.0

- Initial release: `co_golden_gallery build` turns co_golden run manifests
  and plain PNG trees into one self-contained `index.html` with a device ×
  variant grid per scenario, search and filters, and a lightbox.
- Images are referenced locally, copied with `--copy-images`, or served from
  `--asset-base-url`; `--noindex`, `--meta`, `--link`, and `--summary` for
  publishing pipelines.
- Strict input handling: foreign or newer manifests, missing images, and
  conflicting inputs fail with exit code 65.
