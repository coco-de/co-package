# open_epub_engine

[![pub package](https://img.shields.io/pub/v/open_epub_engine.svg)](https://pub.dev/packages/open_epub_engine)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/coco-de/open-epub/actions/workflows/ci.yaml/badge.svg)](https://github.com/coco-de/open-epub/actions/workflows/ci.yaml)

Pure-Dart **EPUB 2 / EPUB 3** engine: OPF / NCX / nav / SMIL parsers, an
immutable object model, an EPUB **CFI** locator, **Media Overlay (SMIL)**
parsing, and a **full-text search** index — with **no Flutter dependency**.

It is the parsing layer behind [`open_epub`](https://pub.dev/packages/open_epub),
the Flutter reader widget, extracted so it can run headless. It replaces
`epubx` / `epub_view` and adapts the CFI subsystem from
[`epub_pro`](https://pub.dev/packages/epub_pro) (BSD-3 / MIT, ADR-010).

## Do you need this package?

> **Most apps should depend on [`open_epub`](https://pub.dev/packages/open_epub)**
> (the Flutter reader widget) instead — it re-exports this engine and adds
> rendering, gestures, text selection, and highlights.
>
> Depend on `open_epub_engine` **directly** only for **headless** use — CLIs,
> servers, batch/indexing jobs, tests — where you need EPUB parsing, CFI, SMIL,
> or search **without** a UI. This package pulls in **no Flutter**.

## Features

- **EPUB 2 & 3** — custom OPF / NCX / nav parsers, with EPUB-version
  cross-validation and compatibility patching (plus per-book diagnostics).
- **Immutable object model** — metadata, spine, outline, landmarks / page-list
  navigation, renditions, capabilities (PPD / writing-mode / MO), resources.
- **EPUB CFI** — `charOffset ↔ CFI` mapping and standard `epubcfi(...)`
  import / export for interop.
- **Media Overlays** — on-demand SMIL parsing (text/audio pars, clip times).
- **Full-text search** — build an index over the spine and query it for hits
  (`spineHref`, `charOffset`, snippet).
- **Compact position tokens** — `BookPosition` v1 codec (JSON ≤ 512 bytes,
  lossless round-trip) for persisting reading location.
- **Pure Dart** — runs on the Dart VM, servers, and CLIs. (`EpubSource.file`
  needs `dart:io`; use `EpubSource.bytes` / `EpubSource.url` on the web.)

## Install

```yaml
dependencies:
  open_epub_engine: ^1.0.0
```

## Quick start (headless)

```dart
import 'package:open_epub_engine/open_epub_engine.dart';

Future<void> main(List<String> args) async {
  // Open from a file, raw bytes, or a URL.
  final session = await EpubBookSession.open(
    EpubSource.file(args.single), // EpubSource.bytes(...) / EpubSource.url(...)
  );
  try {
    // 1. Metadata
    final meta = session.book.metadata;
    print('${meta.title} — ${meta.author ?? 'unknown'} '
        '(EPUB ${meta.epubVersion})');

    // 2. Table of contents (outline tree)
    for (final item in session.outline.items) {
      print('· ${item.title}  ->  ${item.spineHref}');
    }

    // 3. Full-text search
    final index = await session.buildSearchIndex();
    for (final hit in await index.search('whale')) {
      print('${hit.spineHref}@${hit.charOffset}: ${hit.snippet}');

      // Optional: export a standard interop CFI for the hit's position.
      final cfi = session.exportPositionCfi(session.positionForHit(hit));
      if (cfi != null) print('  cfi: $cfi');
    }
  } finally {
    await session.dispose();
  }
}
```

A complete, runnable version lives in [`example/`](example/) — it takes an
`.epub` path (and an optional search term) on the command line:

```sh
dart run packages/open_epub_engine/example/open_epub_engine_example.dart book.epub "whale"
```

## Public API (1.0)

The barrel `package:open_epub_engine/open_epub_engine.dart` **is** the semver
contract (frozen in S6.1). It exports:

| Group | Highlights |
| --- | --- |
| **Session** | `EpubBookSession` (open / jumpTo / paging / hot-swap / analytics), `EpubSource`, `EpubBook`, `EpubPosition` |
| **Parsers** | `OpfParser`, `NcxParser`, `NavParser`, `ContainerParser`, `SmilParser` |
| **Domain model** | metadata, spine, outline, navigation, rendition, capabilities, media overlay, highlight, selection, resource, failures |
| **CFI** | `EpubCfiMapper` (`charOffset ↔ CFI`) + interop |
| **Search** | `TextIndexBuilder`, `BuildSearchIndexUseCase`, `BookSearchIndex` |
| **Codec** | `BookPositionCodec` (compact position tokens) |
| **Security / compat / text** | `HtmlSanitizer`, `EncryptionParser`, `PatchCatalog`, `SpineTextExtractor`, `SearchHighlighter` |

Implementation details are **not** exported: the repository implementation
(`EpubRepositoryImpl`) and the use cases the session orchestrates internally
(`open` / `apply-patches` / `resolve-position`) stay private — consumers enter
through `EpubBookSession.open()` and, when a type is needed, the domain contract
`EpubRepository`. Test fixtures live in a separate barrel
`package:open_epub_engine/testing.dart` (not part of the production surface).

## Architecture (monorepo)

`open_epub_engine` is the pure-Dart layer of the `open_epub` monorepo. It keeps
a Clean Architecture split; Flutter render/widget/controller code stays in
`open_epub`, and the pure-Dart boundary is enforced by
`test/architecture/no_flutter_import_test.dart`.

```
open_epub_engine/
├── lib/
│   ├── open_epub_engine.dart   # public barrel (production API — the semver contract)
│   ├── testing.dart            # EPUB ZIP fixtures — test-only
│   └── src/
│       ├── schema/opf/         # EpubVersion + version cross-validation
│       ├── api/                # EpubBookSession · EpubBook · EpubSource · EpubPosition …
│       ├── domain/             # entity · repository contract · usecase
│       ├── data/               # parser (OPF/NCX/nav/SMIL) · compat · codec · search · security · text
│       └── cfi/                # CFI mapper + ported primitives (epub_pro, internal)
├── example/                    # pure-Dart runnable CLI (dart run)
└── test/                       # dart test (schema · parser · codec · compat · domain · usecase · api · architecture)
```

### Test topology

- **engine** — `dart test` (pure Dart, fast): parsers, codec, domain, use cases,
  API units.
- **open_epub** — `flutter test`: widget, BDD, presentation.
- CI (`.github/workflows/ci.yaml`) runs both jobs in parallel.

## Relationship to open_epub

| | `open_epub_engine` (this package) | [`open_epub`](https://pub.dev/packages/open_epub) |
| --- | --- | --- |
| Runtime | Pure Dart (VM / server / CLI) | Flutter |
| Responsibility | Parse · model · CFI · SMIL · search | Render · gestures · selection · highlights |
| Depend on it when | You need headless EPUB processing | You are building a reader UI |

The reader re-exports the moved engine types, so its 1.0 public surface is
unchanged.

## License & attribution

MIT — see [`LICENSE`](LICENSE). Third-party notices (including the adapted
`epub_pro` CFI primitives) are in
[`THIRD_PARTY_LICENSES`](THIRD_PARTY_LICENSES). Design informed by
[vers-one/EpubReader](https://github.com/vers-one/EpubReader).
