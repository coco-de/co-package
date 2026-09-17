# co-package

Cocode Dart and Flutter packages in a Melos monorepo.

## Packages

| Package | Description |
| --- | --- |
| [`co_faker`](packages/co_faker/README.md) | Pure Dart, deterministic, multilingual fake data generation. |
| [`open_board`](packages/open_board/README.md) | Flutter drawing & annotation widget (pen/lasso/text/image, multi-page, recording & replay). |

## Development

```bash
flutter pub get   # open_board 가 Flutter 패키지라 워크스페이스 해석에 Flutter SDK 가 필요하다
dart pub global activate melos
melos run verify
```

The workspace uses Dart's native `workspace` declaration. Packages use
`resolution: workspace`, so dependency resolution stays consistent across the
repository.

## License

BSD-3-Clause (Cocode Inc.)
