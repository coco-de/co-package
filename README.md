# co-package

Cocode Dart and Flutter packages in a Melos monorepo.

## Packages

| Package | Description |
| --- | --- |
| [`co_arc`](packages/co_arc/README.md) | Cocode Actions Runner Cluster — self-hosted 러너 관리 TUI(`coarc`), 등록 스크립트, ARC 설정, 재사용 CI 워크플로우. |
| [`co_faker`](packages/co_faker/README.md) | Pure Dart, deterministic, multilingual fake data generation. |

## Reusable workflows

Service repositories call the shared CI workflows in
[`.github/workflows/`](.github/workflows/) with `workflow_call`
(`uses: coco-de/co-package/.github/workflows/melos-ci.yml@main`).
See [`packages/co_arc/README.md`](packages/co_arc/README.md) for the runner setup.

## Development

```bash
dart pub get
dart pub global activate melos
melos run verify
```

The workspace uses Dart's native `workspace` declaration. Packages use
`resolution: workspace`, so dependency resolution stays consistent across the
repository.

## License

BSD-3-Clause (Cocode Inc.)
