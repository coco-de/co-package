## Unreleased

- Render the gallery with Jaspr and `coui_web` components, using the
  `cocode-home` dark-first style and mint accent while retaining single-file
  output and the existing CLI options.

## 0.1.0

- Initial release: `co_golden_gallery build` turns co_golden run manifests
  and plain PNG trees into one self-contained `index.html` with a device ×
  variant grid per scenario, search and filters, and a lightbox.
- Images are referenced locally, copied with `--copy-images`, or served from
  `--asset-base-url`; `--noindex`, `--meta`, `--link`, and `--summary` for
  publishing pipelines.
- Strict input handling: foreign or newer manifests, missing images, and
  conflicting inputs fail with exit code 65.
