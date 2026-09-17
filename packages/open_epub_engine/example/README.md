# open_epub_engine example

A pure-Dart, Flutter-free command-line demo. It opens an EPUB 2/3 file and
prints its **metadata**, **table of contents**, compatibility **diagnostics**,
and — when a search term is supplied — **full-text search** hits plus an
exported **CFI** for the first hit.

Everything goes through the public barrel
`package:open_epub_engine/open_epub_engine.dart` via
[`EpubBookSession.open`](https://pub.dev/documentation/open_epub_engine/latest/) —
no Flutter and no internal imports.

## Run

```sh
# From the repository root:
dart run packages/open_epub_engine/example/open_epub_engine_example.dart <book.epub> [search-query]
```

- `<book.epub>` — path to an EPUB 2 or EPUB 3 file (**required**).
- `[search-query]` — optional term to run against the built search index.

With no arguments the program prints usage and exits with code `64` (`EX_USAGE`).

> The example takes the `.epub` path as an argument instead of bundling a
> sample, so it stays self-contained and depends on no committed EPUB asset.

## Example output

```text
== Metadata ==
Title:    Alice's Adventures in Wonderland
Author:   Lewis Carroll
Language: en
EPUB:     3.0 (epub3)
Layout:   reflowable
Spine:    13 document(s)

== Table of contents ==
- Down the Rabbit-Hole  ->  chapter-1.xhtml
- The Pool of Tears      ->  chapter-2.xhtml
...

== Search: "rabbit" ==
chapter-1.xhtml@42: … the White Rabbit with pink eyes ran close by her …
first hit CFI: epubcfi(/6/4[chapter-1]!/4/2:42)
```

## What it demonstrates

| Step | Public API |
| --- | --- |
| Open a book from a file | `EpubBookSession.open(EpubSource.file(path))` |
| Read metadata | `session.book.metadata` (`title`, `author`, `version`, …) |
| Walk the outline / TOC | `session.outline` → `EpubOutlineItem` tree |
| Inspect compat diagnostics | `session.diagnostics` |
| Build & query a search index | `session.buildSearchIndex()` → `BookSearchIndex.search(query)` |
| Locate a hit + export CFI | `session.positionForHit(hit)` + `session.exportPositionCfi(...)` |
