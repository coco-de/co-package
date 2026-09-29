# Changelog

## [0.2.0](https://github.com/coco-de/co-package/compare/co_bdd-v0.1.2...co_bdd-v0.2.0) (2026-09-29)


### ⚠ BREAKING CHANGES

* **co_bdd:** `sharedSteps: true` 에 `sharedStepNames` 를 주지 않으면 이제 co_bdd 공유 step 27종 전부가 공유 import 로 해석된다(종전: 0종). 일부만 쓰려면 목록을 명시한다.
* **co_bdd:** 의존 이름 co_test_gen → co_bdd, import package:co_test_gen/co_test_gen.dart → package:co_bdd/co_bdd.dart, build.yaml 빌더 키 co_test_gen|dual_test_gen → co_bdd|dual_test_gen.

### 기능

* ✨ defaultTarget 옵션 — 실행할 수 없는 산출물 생성 차단 ([#10](https://github.com/coco-de/co-package/issues/10)) ([9692596](https://github.com/coco-de/co-package/commit/9692596e549eeeb38beb128baa44fd690ab6c57b))
* **co_bdd:** ✨ unibook test_driver 흡수 — Semantics 상태 스텝 4종 · 테스트 헬퍼 · 공유 스텝 기본 목록 ([#17](https://github.com/coco-de/co-package/issues/17)) ([653ef65](https://github.com/coco-de/co-package/commit/653ef65b08064e3f636794f70621df3fa026adff))
* **co_bdd:** ✨ 범용 BDD 공유 스텝 23종 — shared_steps.dart 를 실제 라이브러리로 ([#16](https://github.com/coco-de/co-package/issues/16)) ([3448790](https://github.com/coco-de/co-package/commit/34487908fce72c5ac09c707a5d4bbb4ef7674df1))
* **co_bdd:** ✨ 패키지 이름을 co_test_gen → co_bdd 로 변경 ([3b78ff1](https://github.com/coco-de/co-package/commit/3b78ff1ae1465e1b7ae0da134047b135649d1cdd))


### 버그 수정

* **co_bdd:** 🐛 공유 step 목록이 workspace 빌드에서 다른 패키지로 새던 문제 ([e4a7bec](https://github.com/coco-de/co-package/commit/e4a7bec2499e4c8f5049a3a5f90cbbac1970c2da))

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
