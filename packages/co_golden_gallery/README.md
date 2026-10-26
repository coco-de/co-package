# co_golden_gallery

Builds a searchable HTML gallery from
[co_golden](../co_golden/README.md) capture output and plain golden PNG trees.
Jaspr renders the page with `coui_web` cards, badges, buttons, and links.
Its dark-first palette, mint accent, typography, and flat panels follow
[`cocode-home`](https://github.com/coco-de/cocode-home) (`cocode.im`). The
generated page keeps CSS and browser behavior inline. Deploy `index.html`, its
favicon files, and any locally served images together.

- Scenarios with a co_golden run manifest are shown as a **device × variant
  grid** (rows are devices, columns are theme · locale · text scale) with
  pass/fail status, overflow counts, and error messages.
- Other images below `images/` are shown as cards grouped by directory, so
  existing golden baselines can sit next to the matrix captures.
- Search, suite/device/theme/locale filters, a failures-only switch, a
  keyboard-friendly lightbox, and dark/light/system themes — all inline, no
  external scripts or styles. Dark is the default.
- Design references recorded by co_golden appear beside each capture's status.
  Open a capture to switch between the implementation, design, opacity overlay,
  side-by-side view, tolerance difference map, and exact-pixel difference
  image. When co_golden also recorded a design analysis, a findings panel names
  the font, widget, or component that deviates, by how much, and the source
  line to fix; selecting a finding outlines it on both images. The
  **디자인 차이만** switch finds variants that need a design look even when
  capture passed.
- Images stay local, are copied next to the page, or are served from a URL
  prefix such as a storage bucket.
- The page carries the cocode favicon set — the same files as
  [cocode.im](https://cocode.im): `favicon.svg` (the "CO." mark, which follows
  the browser theme), `favicon.ico` (a 32 × 32 PNG for browsers without SVG
  favicons), and `apple-touch-icon.png` (180 × 180). They are written next to
  `index.html` in every mode and linked relatively, so the gallery also works
  below a path such as GitHub Pages' `/<repo>/`. They are files rather than
  data URIs because Safari does not show data URI favicons.

## Usage

```sh
dart run co_golden_gallery build \
  --input build/co_golden \
  --output build/golden-gallery \
  --title "Unibook Golden Gallery" \
  --asset-base-url https://example-bucket.s3.amazonaws.com/runs/abc1234/ \
  --noindex \
  --meta commit=abc1234 \
  --link GitHub=https://github.com/coco-de/unibook \
  --summary build/golden-gallery-summary.json \
  --design-report build/golden-gallery-design-report.md
```

From this workspace:

```sh
flutter pub get
cd packages/co_golden_gallery
dart run bin/co_golden_gallery.dart build --input ../../build/co_golden
```

`coui_web` and `coui_core` come from the private `coco-de/coui` repository at
the same pinned revision as `cocode-home`. Projects consuming this package
must repeat both `dependency_overrides` at their root. Git-based global
activation does not carry this package's overrides; use a runner project with
the two overrides and `dart run co_golden_gallery:co_golden_gallery`.
Dependency resolution requires Git credentials with access to the repository.

| Option | Meaning |
| --- | --- |
| `--input`, `-i` | Source root with `runs/` manifests and an `images/` tree. Repeatable. |
| `--output`, `-o` | Directory that receives `index.html` and the favicon files (default `build/golden-gallery`). |
| `--asset-base-url` | Serve every image from this http(s) prefix plus its gallery path. |
| `--copy-images` | Copy the images next to `index.html` for a self-contained folder. |
| `--noindex` | Add `<meta name="robots" content="noindex, nofollow">`. |
| `--title`, `--brand-color` | Page title and `#RRGGBB` accent (default `#5BE0C8`). |
| `--plain-title` | Heading of the section with images that have no device, theme, or locale (default `축 없는 이미지`). |
| `--meta label=value` | Header entries such as the commit. Repeatable. |
| `--link label=url` | Header links. Repeatable. |
| `--summary file` | Write counts, failed variants, design verdicts, and design findings as JSON (for CI summaries). |
| `--design-report file` | Write a Markdown report of the design findings, for AI agents and pull request comments. |
| `--allow-missing` | Build even when a manifest names a missing image. |

Without `--asset-base-url` or `--copy-images`, images are referenced relative
to the output directory.

### Deploying below a path (GitHub Pages)

The page needs no base-path option: `index.html` links its favicons and
images with relative URLs, so the same folder works at a domain root, at
`https://<owner>.github.io/<repo>/`, or at a sub-path such as
`/<repo>/golden/`.

- Use `--copy-images` so the images travel with the page, and publish the
  output folder as that sub-path of the Pages artifact:

  ```sh
  dart run co_golden_gallery:co_golden_gallery build \
    --input build/co_golden --output site/golden --copy-images --noindex
  # upload `site/` with actions/upload-pages-artifact; the gallery is /golden/
  ```

- `--asset-base-url` must be an absolute http(s) URL. Use it only for images
  on another host (such as a storage bucket), not for the Pages sub-path.

## Input layout

```
<input>/
├── runs/<suite>/<scenario>.json          # co_golden.run manifests
└── images/<suite>/<scenario...>/<file>   # captured and plain images
```

An image named by a manifest carries the manifest's metadata; any other image
is grouped by its path. Two inputs that provide the same gallery path are an
error.

### Figma and implementation review

Associate an exported Figma PNG with the exact device, theme, locale, and text
scale in [`GoldenMatrix.scenario(designReference:)`](../co_golden/README.md#design-references).
Capture again, then build the gallery with the existing command. No gallery
flag or separate hand-written comparison page is needed. The runner snapshots
the design under `references/` and writes exact RGBA differences under
`differences/`; the gallery includes both when copying assets or resolving CDN
and relative image URLs. These auxiliary assets do not inflate scenario or
capture counts. Existing manifests without references keep working.

The viewer starts with a 50% overlay. Use the opacity slider to alternate
between the original and the implementation, or choose **좌우 비교**,
**허용 오차 차이**, or **RGBA 차이 이미지**. The original design link opens from
the same viewer. Each variant resets the controls so a previous variant's
reference is never reused. Slider arrow keys adjust opacity; they do not
navigate to another capture.

The exact comparison uses decoded RGBA equality, with no tolerance, masks, or
acceptance budget. Fonts, platform rasterization, and fixture content can all
contribute. A capture's `passed` status describes its render diagnostics,
independently from agreement with the design. Images with different pixel
dimensions are shown side by side with both sizes; overlay and pixel diff are
disabled, and no percentage is invented. The runner never resizes the
reference to hide a mismatch.

#### Design analysis: tolerance, findings, and an AI report

When co_golden records a design analysis (`designComparison.analysis` in the
manifest, with its report under `analysis/`), the gallery reads each report at
build time:

- **Verdict line** — 일치 / 불일치 / 판정 불가 under tolerance, the differing
  pixel ratio and the largest region against their budgets, and the error,
  warning, info, and known-difference counts. Thumbnails show the same
  verdict, and **디자인 차이만** keeps `fail` and `undetermined` variants.
  Variants without an analysis keep the exact-pixel status.
- **Findings panel** — grouped as 폰트 로딩, 프레임, 누락/추가, 컴포넌트, 서체,
  내용, 색상, 레이아웃, 모양, and 픽셀, most severe first. Each finding shows
  the design value → implementation value (with the text run or sibling it
  applies to), the Figma node and text style, the widget with its source
  `file:line:column`, the design-system component and its properties, where
  to fix it (**고칠 곳**: the app's code, or the design system when a component
  drew the value internally), and a fix hint. Known differences stay listed with their reason and tracking issue
  but do not count.
- **Marks** — selecting or focusing a finding outlines the Figma position
  (pink) and the implementation position (blue, dashed) on the design, the
  implementation, the overlay, the side-by-side view, and the difference maps.
  A 픽셀 finding outlines its differing region (red) and keeps the widget
  under it as context. A rect is drawn on the other image only when both
  share one logical size. **픽셀 영역·가림 표시** draws every differing region
  and mask (blue); regions that no finding explains are labelled. co_golden
  turns at most 20 unexplained regions, largest first, into 픽셀 findings;
  the panel says how many more the region list holds. Up and down arrow keys
  move between findings.
- **Image size** — every view shows the images at their natural size, never
  enlarged, so the overlay keeps the design's pixel geometry. Images of one
  size shrink together on narrow screens, and the marks stay on the image
  even when a page stylesheet resizes it.
- **허용 오차 차이** shows co_golden's tolerance map: red differences, yellow
  anti-aliasing, and blue masks. **분석 리포트 JSON** opens the full report.

The report JSON and the tolerance map are copied, served, and checked like the
other auxiliary assets: unsafe paths are rejected, missing files follow
`--allow-missing`, and a report that is not `co_golden.design_report` version 1
or that belongs to another suite, scenario, or variant fails with exit code 65.

`--summary` includes `designComparisons`, `designVerdicts`
(`pass` / `fail` / `undetermined`), `designFindingCounts`, a
`designDifferences` list, and a flattened `designFindings` list.
`designDifferences` lists variants whose analysis verdict is not `pass`, or,
without an analysis, whose exact status is not `matched`. Each entry has suite,
scenario, variant, exact comparison status, ratio (null for a size mismatch),
reference path, and source URL; with an analysis it adds `analysis` (verdict,
pixel status, report and map paths, counts, verdict reasons). Each `designFindings` entry carries suite, scenario,
variant, report path, and the finding: id, category, severity, message, known
status, Figma node, widget and source location, component, property
differences, and hint. CI can publish the review first and apply its own
explicit design-acceptance policy afterwards. Gallery exit codes remain
unchanged. Missing references and diff artifacts follow `--allow-missing`.

`--design-report <file.md>` writes the same findings as Markdown for an AI
agent or a pull request comment: counts first, then every `fail` or
`undetermined` variant with its findings (element, design → implementation,
source location, component, hint), known differences, pixel regions that no
finding explains, and the next steps.

For a design correction loop: capture the same state as the Figma frame,
build the gallery with `--design-report`, fix the findings at their source
locations — errors first, with design-system components and tokens — then
recapture and rebuild until the verdict is 일치. Use the overlay, marks, and
tolerance map for what the findings do not explain. Update the design export
only when the design itself changes; do not replace it with an implementation
screenshot.

Matrix scenarios are grouped by suite and shown as a device × variant grid.
Rows and columns follow the coverage order that co_golden writes under
`plan.axes` (devices; themes × locales × text scales); manifests without it
fall back to the order in which each value first appears. Images without
axes, such as regression baselines, are collected in their own section after
the matrix suites (`--plain-title`) and are hidden while a device, theme, or
locale filter is set.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | The gallery was written. |
| 64 | Invalid arguments. |
| 65 | Unusable input: missing directory, unreadable or foreign manifest, newer schema, missing images, no image at all, or (with `--copy-images`) an image whose path would overwrite a favicon file. |

Failed variants do not change the exit code — read them from `--summary`, so
a pipeline can publish the gallery and still fail afterwards.

## CoUI v2 compatibility

Requires coui_web 0.162.0 or newer. Pin coui_core and coui_web to the same
commit in the consuming pub root. Scenario counts use outlined badges; failed
counts use the destructive tone with a filled variant.
