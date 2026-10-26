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
`interact` (tap, type), pump, capture, optional design comparison, `dispose` (always).

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
| `capture` | Every variant is rendered and written to `CO_GOLDEN_OUTPUT` (default `build/co_golden`) without baseline comparison. Optional design references add a design analysis (tolerant pixels, structure, findings with source locations). Errors still fail the variant. |
| `compare` | Every variant is compared with `goldens/<suite>/<scenario>/<variant>.png` next to the test file. `--update-goldens` writes those baselines. |

```sh
CO_GOLDEN_MODE=capture flutter test test/golden_matrix/
```

Capture output:

```
build/co_golden/
├── images/<suite>/<scenario>/<device>__<theme>__<locale>[__text-<scale>].png
├── references/<suite>/<scenario>/<variant>.png          # optional design snapshot
├── references/<suite>/<scenario>/<variant>.design.json  # optional design spec snapshot
├── differences/<suite>/<scenario>/<variant>.png         # optional exact pixel diff
├── analysis/<suite>/<scenario>/<variant>.json           # optional design report
├── analysis/<suite>/<scenario>/<variant>.png            # optional tolerant diff map
└── runs/<suite>/<scenario>.json
```

Images are rendered at the device pixel ratio unless `captureScale` is set.

## Design references

Associate a local PNG exported from Figma (or another design tool) with the
variants it actually describes, and optionally the design's node data
(`specPath`). The resolver runs after capture; return `null` when the design
does not cover a variant's device, theme, locale or text scale:

```dart
matrix.scenario(
  'login',
  build: (_) => const LoginPage(),
  designReference: (variant) =>
      variant.device.name == 'phone' &&
          variant.theme.name == 'light' &&
          variant.localeTag == 'ko' &&
          variant.textScale == 1
      ? GoldenDesignReference(
          imagePath: 'test/design/login-phone-light-ko.png',
          specPath: 'test/design/login.design.json', // enables findings
          nodeId: '12:345', // frame inside the spec, when it holds several
          label: 'Figma', // default
          sourceUrl: 'https://www.figma.com/design/example?node-id=12-345',
          masks: [
            GoldenDesignMask.finder(
              find.byKey(const ValueKey('clock')),
              reason: 'live clock',
            ),
          ],
        )
      : null,
);
```

Paths are local filesystem paths, relative to the test package unless absolute.
The runner never downloads the optional HTTP(S) `sourceUrl`. Export a
single-frame PNG at the captured image's physical pixel dimensions (logical
size × `captureScale`, or device pixel ratio when unset). A render that is an
exact integer multiple of the export (a 3× render of a 1× export) is
box-averaged for the tolerant comparison; other sizes are never resampled.

In **capture mode only**, the runner copies the reference PNG (and the spec)
byte for byte into `references/` and writes `GoldenResult.designComparison`
in the existing version 1 manifest. No reference resolver means no additional
field or files; a `null` result does the same for that variant. Skip and
baseline compare modes do not call the resolver or read design files.

`designComparison` keeps the exact RGBA result of earlier versions:

- Equal dimensions produce `matched` or `different`, `differentPixels`,
  `totalPixels`, and `differenceRatio` (0 to 1). A pixel differs when any decoded
  normalized R, G, B or alpha channel differs exactly, including RGB under full
  transparency. 16-bit channel differences are preserved.
- A visible diff PNG is written under `differences/` even for a perfect match.
  Changed pixels are opaque magenta and unchanged pixels form a subdued gray
  context.
- Different dimensions produce `sizeMismatch` with both original geometries;
  `diff`, pixel counts and ratio are `null`.
- A missing, corrupt or animated reference, invalid metadata, or resolver error
  fails the `designComparison` phase; an unreadable spec fails the
  `designAnalysis` phase. The captured render and failure remain in the
  manifest, and normal cleanup hooks still run.

Exact equality alone is too strict for design review — Figma and Flutter
rasterize glyphs and anti-aliased edges differently, so a correct screen still
differs in thousands of pixels — and too vague to act on. The design analysis
below adds tolerances and says *what* differs.

## Design analysis

Every variant with a design reference also gets a design analysis (turn it off
with `designAnalysis: GoldenDesignAnalysis.off`). It writes
`analysis/<suite>/<scenario>/<variant>.json` (`co_golden.design_report`, v1)
and adds a summary under `designComparison.analysis` in the manifest:

```json
"analysis": {
  "report": "analysis/auth/login/phone__light__ko.json",
  "verdict": "fail",
  "pixelStatus": "fail",
  "findings": {"error": 3, "warning": 1, "info": 0, "known": 1},
  "byCategory": {"typography": 1, "layout": 1, "component": 1, "color": 1},
  "ratio": 0.0042, "largestRegion": 45.5, "regionCount": 3,
  "diff": "analysis/auth/login/phone__light__ko.png"
}
```

What it compares:

- **Tolerant pixels.** A pixel differs only when its CIEDE2000 distance exceeds
  the tolerance, no matching color lies within a small positional radius in
  either image, and it is not an anti-aliased edge (pixelmatch rule). Inside
  text boxes the horizontal radius and color tolerance widen, because glyph
  advances drift along a line; vertical offsets still count. Differing pixels
  are grouped into regions, each attributed to the design node and the widget
  under it. The verdict passes when the differing ratio and the largest region
  are both within budget. The rules and defaults match `figma_compare.py` of the
  coco-de `visual-verify` skill, so both tools judge pixels alike.
- **Structure** (needs `specPath`). Design nodes are matched to what the widget
  tree rendered — texts by content (then similarity, then substring for split
  paragraphs), components by name and overlap, boxes, images and icons by
  overlap — and compared property by property.
- **Setup checks** that need no design: fonts that silently fell back to the
  test font, images captured before they were decoded, frame size and text
  scale mismatches.

Each finding has a category, a severity, a Korean message, the property
differences (design → implementation), the design node (id, layer path, text
style or role) and the widget (type, text, bounds, **source location**,
widget path, enclosing design-system component with its properties), who owns
the value (`owner`: `app` when the app's code drew or configured it,
`designSystem` when a design-system component drew it internally — fix or
track those in the design system, not in the app), and a fix hint when one can
be stated precisely:

| Category | Reports |
| --- | --- |
| `font` | A family that is not loaded in the test (every text then differs). |
| `frame` | Frame size or text scale that differs from the design. |
| `presence` | Design elements missing from the implementation; texts the design does not have. Missing boxes and icons are reported only with pixel evidence. |
| `component` | Wrong component type, a hand-built widget where the design uses a design-system component, variant properties that differ, and design components the catalog does not have (design-system extension candidates). |
| `typography` | Text role, font family, weight, size, line height, letter spacing, italic, decoration, alignment — also per styled run. |
| `content` | Different text, truncation the design does not have, a different line count. |
| `color` | Text, fill, border, and icon colors with CIEDE2000 distance and token names; the same value bound to a different token (it differs in another theme). |
| `layout` | Position relative to the nearest matched ancestor — so one shifted container does not flood its children — size, and the gap to the previous sibling. |
| `shape` | Corner radius, border width, shadow presence, icon size. |
| `visual` | Pixel regions that no finding explains (icon glyphs, images, gradients, clipping). |

```json
{
  "id": "typography@12:346",
  "category": "typography",
  "severity": "error",
  "message": "‘로그인’ 서체가 Figma와 다릅니다 — 텍스트 역할 titleMedium → bodyMedium, 굵기 700 → 600.",
  "diffs": [
    {"property": "role", "expected": "titleMedium", "actual": "bodyMedium", "severity": "error"},
    {"property": "fontWeight", "expected": 700, "actual": 600, "delta": -100, "severity": "error"}
  ],
  "design": {"id": "12:346", "name": "Title", "path": "Login / Header / Title", "textStyle": "Title/Medium", "role": "titleMedium"},
  "widget": {"type": "Text", "text": "로그인", "source": "lib/src/login_page.dart:42:9", "path": "LoginPage › Header › Text", "role": "bodyMedium"},
  "hint": "Text('…').titleMedium 처럼 Figma 텍스트 스타일 Title/Medium의 역할을 쓰세요…"
}
```

Source locations come from the widget creation locations that `flutter test`
tracks by default. Project files read as package-relative paths
(`lib/src/login_page.dart`), dependencies as `package:` URIs.

### Getting the design spec

`specPath` accepts any of:

- **`co_golden.design_spec`** — written by the `design-spec.figma.js` recipe of
  the coco-de skills (`cc-blueprint/references/recipes`) through the Figma MCP
  `use_figma` tool. It needs no API token and carries text styles, bound
  variable (token) names, component sets and variant properties.
- **Figma REST API** — the response of
  `GET /v1/files/:key/nodes?ids=:id` (or a file or node document). Variable
  names are not available through REST on most plans; bound variables appear as
  ids, so token findings fall back to values.
- **compare-frames output** — geometry only: regions are attributed to nodes and
  missing texts found, but fonts, colors and components are not compared.

### Configuration

```dart
final matrix = GoldenMatrix<ThemeData>(
  suite: 'auth',
  coverage: coverage,
  app: appBuilder,
  designAnalysis: GoldenDesignAnalysis(
    tolerance: const GoldenDesignTolerance(), // measured defaults
    maskSafeArea: true, // status bar and home indicator bands
    masks: [/* matrix-wide masks, each with a reason */],
    knownDifferences: [
      GoldenKnownDifference(
        widget: 'Card',
        category: 'layout',
        reason: 'Card body–footer gap differs in the library',
        issue: 'https://github.com/coco-de/coui/issues/5652',
      ),
    ],
    failOnMismatch: false, // true turns the verdict into a CI gate
  ),
);
```

- **Masks** exclude what changes on every run or what the app does not draw
  (clock, spinner, map tile). Each needs a reason, which the report records.
  `GoldenDesignMask.rect`, `.figmaNode`, and `.finder` are available. Masking
  more than `maxMaskRatio` (15%) of the frame makes the pixel verdict
  `undetermined`.
- **Known differences** stay in the report and the gallery, marked with their
  reason and issue, but do not count toward the verdict — for design-system
  issues the app cannot fix, or deviations design approved.
- **Tolerances** default to the `visual-verify` measurements:

| Value | Default | Meaning |
| --- | --- | --- |
| `pixel` | 1 | Positional radius of the pixel comparison (logical px) |
| `colorDeltaE` | 3 | CIEDE2000 below which pixel colors are equal |
| `textPixel` / `textDeltaE` | 2 / 10 | Horizontal radius and color tolerance inside text boxes |
| `budgetRatio` | 0.002 | Largest differing fraction that passes |
| `budgetRegion` | 32 | Largest differing region that passes (logical px²) |
| `maxMaskRatio` | 0.15 | Largest masked fraction |
| `position` / `textPosition` | 1 / 2 | Allowed offset of matched boxes / texts (logical px) |
| `size`, `radius` | 1, 1 | Allowed size and corner radius difference |
| `fontSize`, `lineHeight`, `letterSpacing` | 0.5, 1, 0.1 | Allowed typography differences (px) |
| `propertyDeltaE` / `majorDeltaE` | 3 / 10 | Color finding threshold / error threshold |
| `majorOffset` | 4 | Offset above which a layout finding is an error |

  Values that differ from the defaults are listed in the report under
  `tolerance.changed` for reviewers.

### Design systems and CoUI

Components and text roles are recognized through `GoldenDesignSystem`. The
default discovers CoUI's generated catalog
(`tools/figma-token-sync/src/data/components.json`) next to the `coui_flutter`
package the app resolves, so a CoUI app gets component and text-role checks
for exactly its CoUI version, with no configuration:

- A component is a widget the app creates that a design-system package
  implements (CoUI, plus Flutter's Material and Cupertino). Its identity
  properties are read from the conventional fields (`variant`, `size`, `shape`,
  and the catalog's axis enums) without importing the design system.
- A Figma instance matches when its component set is named like the widget
  (`Button` ↔ `Button`) and variant values are spelled like the enum members
  (`Variant=secondary` ↔ `CoreButtonVariant.secondary`). `State=disabled`
  compares with `enabled`; hover, focus, and pressed are runtime states.
- Text roles come from the catalog's typography (`Title/Medium` ↔
  `titleMedium`); a design text without a style can name its role through a
  bound `font-size/<role>` variable.
- A design component the catalog does not know is reported as a
  design-system extension candidate (`component`, `catalog`).

Other design systems, and axes that do not follow the convention, are
described explicitly:

```dart
GoldenDesignSystem(
  packages: {'my_design_system'}, // widgets from these packages are components
  components: [
    // Chip's Figma "Variant" axis holds chipColor values.
    GoldenComponentMapping(
      widget: 'Chip',
      properties: {'Variant': 'chipColor'},
      readers: {'chipColor': (widget) => (widget as Chip).chipColor},
    ),
    GoldenComponentMapping(widget: 'AppPrimaryButton', figma: 'Button'),
  ],
  textRoles: const [
    GoldenTextRole(name: 'titleMedium', fontSize: 18, fontWeight: 700, lineHeight: 1.6),
  ],
  // Names expected and actual colors in findings.
  colorTokens: (context) => {'on-surface': const Color(0xff14161a)},
)
```

For CoUI, name colors with the semantic variables of the color source your
app passes to CoUI (`--coui-on-surface` and `color/on-surface` both normalize
to `on-surface`). The theme's own scheme can hold unresolved tokens, so resolve
from the source:

```dart
GoldenDesignSystem(
  colorTokens: (context) => {
    for (final MapEntry(:key, :value) in PrimitiveCssGenerator.semanticVarsFor(
      CouiColorPresets.source, // the app's color source
      Theme.of(context).brightness == Brightness.dark
          ? CoreBrightness.dark
          : CoreBrightness.light,
    ).entries)
      // Values are CSS channel triples such as '20 22 26'.
      key: () {
        final [r, g, b] = value.split(' ').map(int.parse).toList();
        return Color.fromARGB(255, r, g, b);
      }(),
  },
)
```

### A correction loop for people and AI agents

1. Capture the same state as the Figma frame, with the spec.
2. Read the findings — errors first — and fix at the reported source locations,
   using design-system components and tokens instead of literal values.
3. Recapture and confirm the verdict; regenerate the design export only when
   the design itself changes.

[`co_golden_gallery`](../co_golden_gallery/README.md) shows the findings next to
the overlay and writes the same findings as Markdown (`--design-report`) for
pull requests and agents.

Limits: positions are compared from the top-left corner, so a frame of a
different size than the device yields a `frame` finding first; gradients and
images are compared by pixels only; shadows by presence; icon glyph identity by
pixels; designs are assumed at text scale 1. Passing the analysis means
agreement within tolerance, not design approval.

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
duration, image path (relative to the output directory), overflow count,
error descriptions, and the optional `designComparison` (with its `analysis`
summary). Design reports use schema `co_golden.design_report`, version 1.

## Acknowledgements

The matrix, sampling, and manifest ideas are inspired by
[ff_golden](https://pub.dev/packages/ff_golden) by ASO.dev (MIT). co_golden is
a separate implementation; no code was copied.
