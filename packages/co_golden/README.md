# co_golden

Golden matrix testing for Flutter. Describe a screen once and capture it on
every combination of devices, themes, locales, and text scales — with strict
layout diagnostics and a JSON run manifest per scenario.

It is built for design systems that are not Material-based (such as CoUI) and
for apps that translate with Slang:

- **Theme-agnostic axis.** `GoldenTheme<T>` carries whatever your app root
  consumes — a CoUI `ThemeData`, a Material `ThemeData`, or your own type.
- **Slang binding.** `SlangGoldenLocalization` switches `LocaleSettings` per
  variant, restores it afterwards, loads lazy (deferred) locales up front, and
  fails instead of silently falling back when a locale is not shipped.
- **Real device geometry.** Logical size, device pixel ratio, safe area,
  platform, brightness, and text scale are applied to the test view, so
  platform-adaptive scaling behaves like on the device.
- **Strict diagnostics.** Flutter errors reported while rendering (for example
  `RenderFlex` overflows) fail the variant, and the image is still captured so
  you can see what broke.
- **Opt-in execution.** Matrix tests are skipped unless `CO_GOLDEN_MODE` asks
  for `capture` or `compare`, so they can live next to ordinary tests.

Pair it with [`co_golden_gallery`](../co_golden_gallery/README.md) to publish
the captures as a searchable HTML gallery.

## Install

```yaml
dev_dependencies:
  co_golden:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_golden
      ref: co_golden-v<version>
```

Pin a release tag, and use the **same ref for every package of your
workspace** that depends on co_golden (see the repository README).

Declare the tags the matrix adds in `dart_test.yaml`:

```yaml
tags:
  golden:
  co_golden:
```

## Quick start

```dart
import 'package:co_golden/co_golden.dart';
import 'package:flutter/material.dart';

final matrix = GoldenMatrix<ThemeData>(
  suite: 'auth',
  coverage: GoldenCoverage(
    devices: const [
      GoldenDevice.phoneCompact,
      GoldenDevice.phone,
      GoldenDevice.tablet,
      GoldenDevice.desktop,
    ],
    themes: [
      GoldenTheme(name: 'light', data: ThemeData.light()),
      GoldenTheme(
        name: 'dark',
        data: ThemeData.dark(),
        brightness: Brightness.dark,
      ),
    ],
    locales: const [Locale('ko'), Locale('en')],
  ),
  // Theme objects resolve their platform when they are created. Apply the
  // variant's platform here so platform-adaptive widgets follow the device.
  app: (variant, child) => MaterialApp(
    theme: variant.theme.data.copyWith(platform: variant.platform),
    locale: variant.locale,
    home: child,
  ),
);

void main() {
  matrix.scenario(
    'login',
    description: 'Empty login form',
    build: (variant) => const LoginPage(),
  );
}
```

`scenario` registers one widget test per variant (`auth/login phone · dark ·
en`, …). Hooks run in this order: `prepare` (install fixtures), build, pump,
`interact` (tap, type), pump, capture, `dispose` (always).

### Slang

```dart
final matrix = GoldenMatrix<ThemeData>(
  suite: 'auth',
  coverage: coverage,
  localization: SlangGoldenLocalization(
    settings: LocaleSettings.instance,
    provider: (child) => TranslationProvider(child: child),
  ),
  app: (variant, child) => MyApp(locale: variant.locale, child: child),
);
```

Slang generates lazy settings by default: every locale except the base one
lives in a deferred library. Widget tests run in a fake-async zone where
loading a library never completes, so a test that awaits it hangs, and a
synchronous switch before the load throws. The matrix therefore calls
`preload` with the planned locales in `setUpAll`, and `activate` switches
synchronously. When you use the binding on its own, await `preload` first.

### CoUI and other design systems

Pass the design system's theme type as `T` and install it in `app`. When the
design system scales by platform (CoUI applies mobile scaling on iOS and
Android), hand it `variant.platform` so a `phone` variant is rendered with the
phone scaling.

## Running

| `CO_GOLDEN_MODE` | What happens |
| --- | --- |
| unset / `skip` | Tests are registered as skipped. |
| `capture` | Every variant is rendered and written to `CO_GOLDEN_OUTPUT` (default `build/co_golden`) without comparison. Errors still fail the variant. |
| `compare` | Every variant is compared with `goldens/<suite>/<scenario>/<variant>.png` next to the test file. `--update-goldens` writes those baselines. |

```sh
CO_GOLDEN_MODE=capture flutter test test/golden_matrix/
```

Capture output:

```
build/co_golden/
├── images/<suite>/<scenario>/<device>__<theme>__<locale>[__text-<scale>].png
└── runs/<suite>/<scenario>.json
```

Images are rendered at the device pixel ratio unless `captureScale` is set.

## Coverage

```dart
GoldenCoverage(
  devices: GoldenDevice.presets,
  themes: themes,
  locales: locales,
  textScales: const [1, 1.3],
  sampling: GoldenSampling.pairwise,
  rules: [
    GoldenCoverageRule.exclude(
      'the desktop app ships a light theme only',
      (variant) => variant.device == GoldenDevice.desktop &&
          variant.theme.name == 'dark',
    ),
  ],
  maxVariants: 24,
)
```

- `full` keeps every feasible combination.
- `smoke` keeps a greedy selection in which every axis value appears.
- `pairwise` keeps a greedy selection in which every pair of values from two
  axes appears.
- A plan larger than `maxVariants` throws `GoldenCoverageBudgetExceeded`;
  coverage is never reduced silently.

## Fonts

Load the app fonts once in `flutter_test_config.dart`:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadGoldenFonts();
  await testMain();
}
```

Package fonts (`packages/<package>/<Family>`) are also registered under the
plain family name, which design systems usually reference.

Fonts the app does not declare (for example Google Fonts downloaded at
runtime) render as boxes in tests — Hangul most visibly. Commit an openly
licensed Korean font (Pretendard, SIL OFL) under `test/fonts/` and load it
from disk:

```dart
await loadGoldenFonts();
await loadGoldenFontFiles({
  'Pretendard': [
    'test/fonts/Pretendard-Regular.otf',
    'test/fonts/Pretendard-Bold.otf',
  ],
});
```

## Deterministic time

Screens that show today's date, relative times ("3분 전"), ages, or "open
now" change every day and can never match a baseline. Read time through
`clock.now()` from [`package:clock`](https://pub.dev/packages/clock) (or
inject a clock) instead of `DateTime.now()`, and fix it for the matrix:

```dart
final matrix = GoldenMatrix<ThemeData>(
  suite: 'crm',
  clock: DateTime.utc(2026, 9, 30, 10, 30), // every variant
  // ...
);

matrix.scenario(
  'birthday_campaign',
  clock: DateTime.utc(2026, 12, 24, 9), // this scenario only
  build: (_) => const CampaignPage(),
);
```

Each variant runs inside `withClock(Clock.fixed(...))`. Compute ages and
"days until" values from the same injected time, and pass it to fixture
generators (for example `CoFaker(now: ...)`).

## Baselines in CI

Font rasterization differs between operating systems, so a baseline is only
valid on the platform that wrote it.

- **Linux CI owns the baselines.** Run `compare` and `--update-goldens` only
  on the CI image (for example `ubuntu-latest` with a pinned Flutter).
- **macOS and Windows are capture-only.** Use `CO_GOLDEN_MODE=capture` locally
  to look at screens and build galleries; never commit baselines written
  there.
- **Known overflows keep comparing.** Set `failOnErrors: false` on a scenario
  with a known layout defect so it still compares, and track the defect
  separately, instead of excluding the screen.

On failure, let CI write the new baselines as an artifact and apply them
after review:

```yaml
- name: Compare goldens
  run: CO_GOLDEN_MODE=compare flutter test --tags golden
- name: Write candidate baselines
  if: failure()
  run: CO_GOLDEN_MODE=compare flutter test --tags golden --update-goldens || true
- uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: golden-baselines
    path: '**/goldens/**/*.png'
```

```sh
# Apply the artifact of a failed run locally, then review the diff.
run_id=$(gh run list --workflow ci.yml --status failure --limit 1 \
  --json databaseId --jq '.[0].databaseId')
gh run download "$run_id" --name golden-baselines --dir .
git status --short -- '**/goldens/**'
```

## Run manifest

`runs/<suite>/<scenario>.json` uses schema `co_golden.run`, version 1: suite,
scenario, description, mode, plan counts, and per variant the axes, status,
duration, image path (relative to the output directory), overflow count, and
error descriptions.

## Acknowledgements

The matrix, sampling, and manifest ideas are inspired by
[ff_golden](https://pub.dev/packages/ff_golden) by ASO.dev (MIT). co_golden is
a separate implementation; no code was copied.
