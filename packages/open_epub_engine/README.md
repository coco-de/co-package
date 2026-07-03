# open_epub_engine

Pure-Dart **EPUB 2/3 파서·객체 모델·CFI 로케이터 엔진**. `open_epub`(Flutter 리더)의 파싱 계층으로, `epubx`/`epub_view`를 대체한다.

- **Flutter 무의존** — 순수 Dart (`archive`, `xml`, `path`).
- 커스텀 OPF/NCX/nav 파서 기반 + [vers-one/EpubReader](https://github.com/vers-one/EpubReader) 설계 참고 확장.
- [epub_pro](https://pub.dev/packages/epub_pro)의 CFI를 **보충 매퍼**로 채택 (BookPosition v1 canonical 유지, ADR-010).

## 구조 (모노레포 pub workspace)
```
open_epub_engine/
└── lib/src/
    ├── schema/      # OPF·NCX·nav·SMIL 모델
    ├── parser/      # 파서 (S10.3 이관 예정)
    ├── codec/       # BookPosition 코덱
    ├── cfi/         # CFI 보충 매퍼 (E12)
    └── ...
```

> 개발 중 내부 패키지(`publish_to: none`). 발행 여부는 GA(E6)에서 확정. 자세한 로드맵은 저장소 `docs/epub3-monorepo-roadmap.md` 참조.
