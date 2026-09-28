# Changelog

## [0.1.2](https://github.com/coco-de/co-test-gen/compare/v0.1.1...v0.1.2) (2026-07-21)


### 버그 수정

* **barrel:** 🐛 런타임 배럴에서 build-time generator export 제거 ([#4](https://github.com/coco-de/co-test-gen/issues/4)) ([9025090](https://github.com/coco-de/co-test-gen/commit/9025090de2d702d79fbb3f36bf563dc6186f48f3))

## 0.1.0

- Initial release
- Gherkin `.feature` parser with `@widget-only`, `@patrol-only`, `@both` tags
- `DualTestBuilder` — generates `.widget_test.dart` + `.patrol_test.dart` from `.feature`
- `TestDriver` — abstract interface for shared BDD step functions
- `WidgetTestDriver` — `WidgetTester` adapter
- `PatrolTestDriver` — `PatrolIntegrationTester` adapter (no hard dependency on patrol)
