# co-package

Cocode Dart and Flutter packages in a Melos monorepo.

## Packages

| Package | Description |
| --- | --- |
| [`co_faker`](packages/co_faker/README.md) | Pure Dart, deterministic, multilingual fake data generation. |
| [`open_epub_engine`](packages/open_epub_engine/README.md) | Pure Dart EPUB 2/3 parser, object model, and CFI locator engine. |
| [`open_epub`](packages/open_epub/README.md) | Customizable EPUB reader widget for Flutter (reflowable + fixed layout). |

## Development

```bash
flutter pub get   # open_epub 이 Flutter 패키지라 워크스페이스 해석에 Flutter SDK 가 필요하다
dart pub global activate melos
melos run verify
```

The workspace uses Dart's native `workspace` declaration. Packages use
`resolution: workspace`, so dependency resolution stays consistent across the
repository.

## License

BSD-3-Clause (Cocode Inc.)
