# open_epub

A customizable **EPUB 2 / EPUB 3** reader widget for Flutter, backed by a
Flutter-free pure-Dart parsing engine
([`open_epub_engine`](https://pub.dev/packages/open_epub_engine)). Reflowable and
fixed-layout rendering, text selection & highlights, CFI, Media Overlays, and
RTL / vertical writing.

[![pub package](https://img.shields.io/pub/v/open_epub.svg)](https://pub.dev/packages/open_epub)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/coco-de/open-epub/actions/workflows/ci.yaml/badge.svg)](https://github.com/coco-de/open-epub/actions/workflows/ci.yaml)

![example.git](example.gif)

## Platform Support

| Platform | Status | Notes |
| --- | --- | --- |
| ![iOS](https://img.shields.io/badge/iOS-supported-brightgreen) | ✅ Supported | Declared in `pubspec.yaml`; example app ships an iOS runner |
| ![Android](https://img.shields.io/badge/Android-supported-brightgreen) | ✅ Supported | Declared in `pubspec.yaml`; example app ships an Android runner |
| ![Web](https://img.shields.io/badge/Web-supported-brightgreen) | ✅ Supported | Declared in `pubspec.yaml`; example app ships a Web target |
| ![macOS](https://img.shields.io/badge/macOS-roadmap-yellow) | 🔜 Roadmap | Pure-Dart engine + Flutter desktop make it feasible; the platform declaration and desktop CI matrix are on the 1.0 release track |
| ![Windows / Linux](https://img.shields.io/badge/Windows%20%7C%20Linux-roadmap-yellow) | 🔜 Roadmap | As macOS; note that read-aloud audio backends (`just_audio`) vary on Windows / Linux |

> iOS, Android, and Web are the currently declared and CI-exercised targets.
> Desktop (macOS, Windows, Linux) is on the roadmap — the reader has no
> platform-locked dependency, but it is not yet declared in `pubspec.yaml` and
> not yet covered by the multi-platform CI matrix.

## Features

- **EPUB 2 & EPUB 3 parsing** via the pure-Dart `open_epub_engine`
- **Reflowable rendering** — pagination and continuous scroll, adjustable font
  size and line height
- **Fixed-layout rendering** — SVG / XHTML pages, pinch-zoom, one/two-page
  spread with an override toggle
- **Text selection & highlights** (`SelectionArea`-based)
- **Resume & interop** — `EpubPosition` tokens and standard **CFI** import/export
- **RTL page progression** and **vertical (`vertical-rl`) writing**
- **MathML** (→ TeX fallback) and **inline SVG** rendering
- **Media Overlays** (read-aloud) with narration highlight sync
- **Full-text search** index
- Load from **bytes, files, or URLs**
- **No JavaScript runtime** — script / iframe content is intentionally blocked
  (see [Security & Scripting Policy](#security--scripting-policy))

```bash
flutter pub add open_epub
```

## Quick Start

`EpubReader` opens and owns an `EpubBookSession` for you. 1.0 has no asset
source factory — load the bytes yourself, then hand them to `EpubSource.bytes`:

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_epub/open_epub.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _controller = EpubViewController();
  late final Future<Uint8List> _bytes = rootBundle
      .load('assets/book.epub')
      .then((data) => data.buffer.asUint8List());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return EpubReader(
          source: EpubSource.bytes(snapshot.data!),
          controller: _controller,
          paged: true, // page mode; false = continuous scroll
          fontSize: 16,
          lineHeight: 1.5,
          onSessionReady: (session) {
            // The session is owned by EpubReader — do not dispose it here.
            final meta = session.book.metadata;
            debugPrint('Opened: ${meta.title} by ${meta.author}');
          },
          onPositionChanged: (position) {
            // Persist position.toToken() to resume later (see below).
          },
        );
      },
    );
  }
}
```

## Opening a Book Without the Widget

`EpubBookSession` is the headless entry point (parsing, position, search,
analytics). You own the session and must dispose it:

```dart
final session = await EpubBookSession.open(EpubSource.bytes(bytes));

final book = session.book;
print('${book.metadata.title} — ${book.spine.length} spine items');

// Full-text search
final index = await session.buildSearchIndex();

await session.dispose();
```

## EPUB Sources

```dart
// In-memory bytes
EpubSource.bytes(Uint8List bytes)

// Local file path
EpubSource.file('/path/to/book.epub')

// Remote URL (optional headers)
EpubSource.url(Uri.parse('https://example.com/book.epub'))

// Assets: load the bytes first, then use EpubSource.bytes
final data = await rootBundle.load('assets/book.epub');
final source = EpubSource.bytes(data.buffer.asUint8List());
```

## Navigation

`EpubViewController` drives page/spine navigation and is a `ChangeNotifier`:

```dart
final controller = EpubViewController();

controller.nextPage();       // next screen (falls back to spine step)
controller.previousPage();
controller.goToSpine(3);     // jump to a spine item (e.g. a TOC target)

controller.currentSpineIndex; // current spine index
controller.spineCount;        // total spine items
controller.hasNext;           // false at the very end of the book
controller.hasPrevious;

// Rebuild custom bars when position changes
controller.addListener(() { /* ... */ });
```

## Reading Position & Resume

Positions are opaque, round-trip-safe tokens (`EpubPosition`). Persist the token
on change, restore it via `initialPosition`:

```dart
// Save
EpubReader(
  source: source,
  onPositionChanged: (position) {
    myStore.save(bookId, position.toToken()); // String token
  },
);

// Restore
final token = myStore.load(bookId); // String?
EpubReader(
  source: source,
  initialPosition: token == null ? null : EpubPosition.fromToken(token),
);
```

## EPUB 3 Capabilities

| Capability | How |
| --- | --- |
| Reflowable / Fixed Layout | Auto-detected from `rendition:layout` |
| Page vs. scroll mode | `EpubReader(paged: true/false)` |
| Fixed-layout spread toggle | `fixedLayoutSpreadOverride` |
| RTL page progression | `readingDirection: EpubPageProgression.rtl` |
| Vertical writing (`vertical-rl`) | `verticalWriting: true` |
| Media Overlays (read-aloud) | `mediaOverlayController` + `session.loadMediaOverlay(spineHref)` |
| MathML | Built-in MathML → TeX fallback render |
| Inline SVG | Rendered via `fwfh_svg` |
| CFI interop | `EpubCfiMapper` (import/export standard CFI) |
| Full-text search | `session.buildSearchIndex()` |
| Selection & highlights | `SelectionArea` + `EpubHighlight` |

Book-level signals (`BookCapabilities`, e.g. page-progression direction and
whether Media Overlays are present) are available from `session.book`.

## Pure-Dart Engine (`open_epub_engine`)

Parsing, the object model, and CFI location live in a separate, Flutter-free
package: **[open_epub_engine](https://pub.dev/packages/open_epub_engine)**
(ADR-002-a — published independently with lockstep versioning). `open_epub`
re-exports the moved types (`EpubBook`, `EpubSource`, `EpubPosition`,
`EpubMetadata`, …) through its barrel, so most apps only depend on `open_epub`.

Depend on the engine directly when you need pure-Dart EPUB parsing — CLI tools,
servers, or background isolates — without Flutter:

```bash
dart pub add open_epub_engine
```

## Security & Scripting Policy

open_epub renders book content **without a JavaScript runtime**. EPUB3 Scripted
Content (`<script>`, inline event handlers, `javascript:` URLs, embedded
`<iframe>`/WebView) is **intentionally not supported** — this is a security
decision, not a missing feature, and there is no plan to enable it.

**Why**

- Executing book-supplied scripts would expose the reader to arbitrary code
  execution, data exfiltration, and resource abuse. Book content is not trusted
  with that capability.
- The reflowable/fixed-layout renderer is `flutter_widget_from_html_core`, which
  has no JS engine, no DOM, and no WebView. The all-in-one
  `flutter_widget_from_html` is deliberately **not** used because it pulls in
  `fwfh_webview` (`<iframe>` → WebView), video, and audio.
- EPUB3 permits reading systems to disable scripting (it is an optional
  feature). Content marked `epub:scripted` should ship a static fallback.

**Defense in depth**

1. **Engine sanitize** — before rendering, `html_sanitizer` strips `<script>`
   and `<iframe>` elements (paired and self-closing). Controlled by
   `EpubSecurityConfig.blockExternalScripts` / `blockIframes` (both `true` by
   default).
2. **Renderer never executes** — `flutter_widget_from_html_core` does not render
   `<script>`/`<style>` and ignores inline event-handler attributes such as
   `onclick`; `javascript:` links are not routed (gated by `onTapUrl`).

**Scope**

- Applies to both reflowable body and fixed-layout XHTML pages (same render
  path).
- Static content is unaffected: script-free SVG, images, and math
  (MathML → TeX) render normally. Only executable code is blocked.

This policy is locked by widget regression tests (script/iframe not rendered,
inline handlers ignored). Other hardening — zip-slip path normalization,
cross-origin image handling, and a file-size limit — is configured through
`EpubSecurityConfig`.

## Migrating from 0.x

open_epub 1.0 is a breaking redesign (ADR-002). See
**[MIGRATION.md](MIGRATION.md)** for the full 0.x → 1.0 API mapping with
before/after examples. At a glance:

- `EpubReaderWidget` → `EpubReader`
- `EpubReaderController` → `EpubViewController` (navigation) + `EpubBookSession`
  (data / lifecycle)
- `EpubSourceAsset('assets/book.epub')` → load bytes, then `EpubSource.bytes(...)`
- page-index / progress restore → `EpubPosition` tokens (`toToken()` / `fromToken()`)

## License

MIT
