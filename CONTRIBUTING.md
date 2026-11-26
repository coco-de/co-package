# Contributing

Use the [issue forms](https://github.com/coco-de/co-package/issues/new/choose)
for bugs and feature requests. Issues and pull requests are welcome in English
or Korean. Follow the [Code of Conduct](CODE_OF_CONDUCT.md) and use the
[security policy](SECURITY.md) for private vulnerability reports.

## Run the public checks

Use Python 3.9 or later and put Flutter 3.50.1's `bin` directory on your `PATH`
so `dart` and `flutter` come from the same SDK. FVM reads the pin from `.fvmrc`.
Run the checks from the repository root.

```sh
python3 tool/pages/public_workspace.py verify
```

This creates a Git-ignored `pubspec_overrides.yaml` and runs the public
format, analysis, license and test checks. The public workspace excludes the
CoUI-dependent theme package, gallery, and full demo apps. To run fewer checks,
pass scripts such as `analyze` or `test:dart` in place of `verify`. If you already
have a local override file, move it aside first. Remove the generated override
to return to the full workspace with CoUI access.

The terminal forks use their own dependency resolution and CI jobs. Run
`flutter pub get --no-example` and `flutter test --no-pub` from their package
directories. On Linux, the `co_xterm2` CI job excludes `platform-golden` tests.

The libraries use the SDK's Material and Cupertino types for compatibility with
existing host apps. Flutter 3.50 marks those imports and the legacy localization
delegate as deprecated. The analysis exceptions apply to those lines.

## Open a pull request

Open a pull request with the package scope and verification results. Use a
Conventional Commit title such as `fix(open_board): preserve drawing input`
so release-please can build the changelog.
