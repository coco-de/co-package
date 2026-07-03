# open_epub_engine

Pure-Dart **EPUB 2/3 파서·객체 모델·CFI 로케이터 엔진**. `open_epub`(Flutter 리더)의 파싱 계층으로, `epubx`/`epub_view`를 대체한다.

- **Flutter 무의존** — 순수 Dart (`archive`, `xml`, `path`).
- 커스텀 OPF/NCX/nav 파서 기반 + [vers-one/EpubReader](https://github.com/vers-one/EpubReader) 설계 참고 확장.
- [epub_pro](https://pub.dev/packages/epub_pro)의 CFI를 **보충 매퍼**로 채택 (BookPosition v1 canonical 유지, ADR-010).

## 구조 (모노레포 pub workspace)

S10.3(#80)에서 `open_epub` 1.0의 순수-Dart 레이어(api·domain·data)를 이 패키지로 추출했다.
클린 아키텍처 레이어 구조를 보존하며, `cfi/`는 E12에서 도입 예정이다.
```
open_epub_engine/
├── lib/
│   ├── open_epub_engine.dart   # 공개 배럴 (프로덕션 API)
│   ├── testing.dart            # 테스트 픽스처(EPUB ZIP 빌더) — 테스트 전용 (S10.5)
│   └── src/
│       ├── schema/opf/         # EpubVersion + version-branching 교차검증 (S10.6, gap #9)
│       ├── api/                # EpubBookSession·EpubBook·EpubSource·EpubPosition …
│       ├── domain/             # entity · repository 계약 · usecase
│       ├── data/               # parser(OPF/NCX/nav) · compat · codec · search · security · text
│       └── testing/            # epub_fixtures (testing.dart 로 노출)
│       # cfi/  — CFI 보충 매퍼 (E12 도입 예정)
└── test/                       # dart test (schema·parser·codec·compat·domain·usecase·api·… + architecture 가드)
```

## 소비 (open_epub)

`open_epub`(Flutter 리더)이 이 엔진을 소비한다. presentation/컨트롤러는 공개 배럴
`package:open_epub_engine/open_epub_engine.dart`를, 1.0 진입점 `open_epub_v1.dart`는 이동
타입을 엔진 배럴에서 재-export 한다(공개 표면 불변). Flutter 의존은 `open_epub`에만 잔류하며,
엔진의 pure-Dart 경계는 `test/architecture/no_flutter_import_test.dart` 가드로 강제된다(S10.4).

## 테스트 토폴로지 (S10.5)

- **engine** = `dart test` (pure Dart, 빠름) — 파서·코덱·도메인·유즈케이스·api 단위 테스트.
- **open_epub** = `flutter test` — 위젯·BDD·presentation 테스트.
- CI(`.github/workflows/ci.yaml`)는 두 잡을 병렬 실행한다.

> 개발 중 내부 패키지(`publish_to: none`). 발행 여부는 GA(E6)에서 확정. 자세한 로드맵은 저장소 `docs/epub3-monorepo-roadmap.md` 참조.
