# Contributing

Use [GitHub Issues](https://github.com/coco-de/co-package/issues) for bugs and
feature requests. Include the package name, Dart or Flutter version, platform,
and a minimal reproduction for bugs. Follow [SECURITY.md](SECURITY.md) to
report a security issue privately.

Use Flutter 3.47.0 for the same SDK as CI. If you cloned without access to
Cocode's CoUI Git repository, run the public workspace setup in a disposable
checkout. It edits the root pubspec to exclude the CoUI-dependent examples
and gallery for that checkout.

```sh
python3 tool/pages/public_workspace.py
flutter pub get --no-example
dart run melos run format
dart run melos run analyze
dart run melos run test:dart
dart run melos run test:flutter
bash tool/check_licenses.sh
```

The terminal forks use their own dependency resolution and CI jobs. Run
`flutter pub get --no-example` and `flutter test --no-pub` from their package
directories. On Linux, the `co_xterm2` CI job excludes `platform-golden` tests.

Open a pull request with the package scope and verification results. Use a
Conventional Commit title such as `fix(open_board): preserve drawing input`
so release-please can build the changelog.
