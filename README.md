# co-package

Cocode Dart and Flutter packages in a Melos monorepo.

## Packages

| Package | Description |
| --- | --- |
| [`co_arc`](packages/co_arc/README.md) | Cocode Actions Runner Cluster — self-hosted 러너 관리 TUI(`coarc`), 등록 스크립트, ARC 설정, 재사용 CI 워크플로우. |
| [`co_faker`](packages/co_faker/README.md) | Pure Dart, deterministic, multilingual fake data generation. |
| [`co_golden`](packages/co_golden/README.md) | Golden matrix testing for Flutter — devices × themes × locales, strict layout diagnostics, Slang locale binding, JSON run manifests. |
| [`co_golden_gallery`](packages/co_golden_gallery/README.md) | Single-file HTML gallery for co_golden captures and golden PNG trees; images local, copied, or served from a bucket. |
| [`open_epub_engine`](packages/open_epub_engine/README.md) | Pure Dart EPUB 2/3 parser, object model, and CFI locator engine. |
| [`open_epub`](packages/open_epub/README.md) | Customizable EPUB reader widget for Flutter (reflowable + fixed layout). |
| [`open_board`](packages/open_board/README.md) | Flutter drawing & annotation widget (pen/lasso/text/image, multi-page, recording & replay). |
| [`xterm3`](packages/xterm3/FORK.md) | [klc/xterm3](https://github.com/klc/xterm3) 6.3.4 포크 — 데스크톱 입력기(한글 두벌식 등) 조합 수정. **AGPL-3.0**, 워크스페이스 비회원(자체 CI 잡). |

## Depending on these packages

Until a package is on pub.dev, depend on it by git tag
(`<package>-v<version>`, for example `co_faker-v0.8.1`):

```yaml
dependencies:
  co_faker:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_faker
      ref: co_faker-v0.8.1
```

- **One ref per workspace.** Every package of a consuming workspace must use
  the same ref for the same git dependency. Two members pinning different
  tags (say `co_faker-v0.7.0` and `co_faker-v0.8.0`) make the workspace
  `pub get` fail with a version-solving error. Upgrade all members in one
  change, and enforce it with a CI check.
- Sibling packages released together share one release commit, so their tags
  from the same release point to the same tree.

## Reusable workflows

Service repositories call the shared CI workflows in
[`.github/workflows/`](.github/workflows/) with `workflow_call`
(`uses: coco-de/co-package/.github/workflows/melos-ci.yml@main`).
See [`packages/co_arc/README.md`](packages/co_arc/README.md) for the runner setup.

## Development

```bash
flutter pub get --no-example   # open_board 가 Flutter 패키지라 워크스페이스 해석에 Flutter SDK 가 필요하다
dart pub global activate melos
melos run verify
```

The workspace uses Dart's native `workspace` declaration. Packages use
`resolution: workspace`, so dependency resolution stays consistent across the
repository.

### Graft code graph

This repository shares the Graft agent instructions in `AGENTS.md`. The
generated `graft/` graph stays local, so each contributor builds it after
cloning the repository:

```bash
npx --yes @nanonets/graft@0.18.0 build
```

The build needs no API key. Run the same command after large code changes, or
query the graph directly with `npx --yes @nanonets/graft@0.18.0 ask "<task>" --source`;
queries refresh changed files automatically. The pinned version keeps the
shared instructions and generated graph format consistent.

## License

BSD-3-Clause (Cocode Inc.)

예외: `packages/xterm3` 는 업스트림 라이선스 AGPL-3.0-or-later 를 따른다
(패키지 안의 `LICENSE` · `LICENSE.MIT` · `NOTICE`).
