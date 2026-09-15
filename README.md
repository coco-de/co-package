# co-package

Cocode Dart and Flutter packages in a Melos monorepo.

## Packages

| Package | Description |
| --- | --- |
| [`co_faker`](packages/co_faker/README.md) | Pure Dart, deterministic, multilingual fake data generation. |

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
