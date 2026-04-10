## 0.1.0

- Initial release
- Gherkin `.feature` parser with `@widget-only`, `@patrol-only`, `@both` tags
- `DualTestBuilder` — generates `.widget_test.dart` + `.patrol_test.dart` from `.feature`
- `TestDriver` — abstract interface for shared BDD step functions
- `WidgetTestDriver` — `WidgetTester` adapter
- `PatrolTestDriver` — `PatrolIntegrationTester` adapter (no hard dependency on patrol)
