# co_golden_gallery

Builds a single-file, searchable HTML gallery from
[co_golden](../co_golden/README.md) capture output and plain golden PNG trees.

- Scenarios with a co_golden run manifest are shown as a **device × variant
  grid** (rows are devices, columns are theme · locale · text scale) with
  pass/fail status, overflow counts, and error messages.
- Other images below `images/` are shown as cards grouped by directory, so
  existing golden baselines can sit next to the matrix captures.
- Search, suite/device/theme/locale filters, a failures-only switch, a
  keyboard-friendly lightbox, and light/dark themes — all inline, no external
  scripts or styles.
- Images stay local, are copied next to the page, or are served from a URL
  prefix such as a storage bucket.

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

Without installing it as a dependency:

```sh
dart pub global activate --source git https://github.com/coco-de/co-package.git \
  --git-path packages/co_golden_gallery --git-ref <commit>
dart pub global run co_golden_gallery build --input build/co_golden
```

| Option | Meaning |
| --- | --- |
| `--input`, `-i` | Source root with `runs/` manifests and an `images/` tree. Repeatable. |
| `--output`, `-o` | Directory that receives `index.html` (default `build/golden-gallery`). |
| `--asset-base-url` | Serve every image from this http(s) prefix plus its gallery path. |
| `--copy-images` | Copy the images next to `index.html` for a self-contained folder. |
| `--noindex` | Add `<meta name="robots" content="noindex, nofollow">`. |
| `--title`, `--brand-color` | Page title and `#RRGGBB` accent. |
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

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | The gallery was written. |
| 64 | Invalid arguments. |
| 65 | Unusable input: missing directory, unreadable or foreign manifest, newer schema, missing images, or no image at all. |

Failed variants do not change the exit code — read them from `--summary`, so
a pipeline can publish the gallery and still fail afterwards.
