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
  --summary build/golden-gallery-summary.json
```

From this workspace:

```sh
flutter pub get
cd packages/co_golden_gallery
dart run bin/co_golden_gallery.dart build --input ../../build/co_golden
```

`coui_web` and `coui_core` come from the private `coco-de/coui` repository at
the same pinned revision as `cocode-home`. The workspace root pins both in
`dependency_overrides`; projects consuming this package must pin both to that
revision too. Dependency resolution requires Git credentials with access to
the repository.

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
| `--summary file` | Write counts and failed variants as JSON (for CI summaries). |
| `--allow-missing` | Build even when a manifest names a missing image. |

Without `--asset-base-url` or `--copy-images`, images are referenced relative
to the output directory.

## Input layout

```
<input>/
├── runs/<suite>/<scenario>.json          # co_golden.run manifests
└── images/<suite>/<scenario...>/<file>   # captured and plain images
```

An image named by a manifest carries the manifest's metadata; any other image
is grouped by its path. Two inputs that provide the same gallery path are an
error.

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
