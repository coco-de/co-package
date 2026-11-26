# Changelog

## [0.2.0](https://github.com/coco-de/co-package/compare/open_note-v0.1.0...open_note-v0.2.0) (2026-11-26)


### 기능

* **open_note:** ✨ 필기 노트 패키지 open_note 추가 ([#153](https://github.com/coco-de/co-package/issues/153)) ([34d0377](https://github.com/coco-de/co-package/commit/34d0377217be632ae9caa4b81b742aef48422692))


### 버그 수정

* ship third-party notices with distributed assets ([#156](https://github.com/coco-de/co-package/issues/156)) ([7efe296](https://github.com/coco-de/co-package/commit/7efe296adb0db87d6131a93cba6f2851de72182a))

## 0.1.0

- Preserve the Open Board MIT notice and credit the demo EPUB in the package archive.
- Start `open_note` as a separate package cloned from `open_board` 0.3.2 and
  renamed (`package:open_note/open_note.dart`, `OpenNoteStrings`). The engine's
  `Scribble*` API stays, so both packages can be used side by side with an
  import prefix.
- Engine additions: line styles (dashed, dotted, wavy, zigzag, double, with
  adjustable dash, gap and wave), 2-point shapes including 3-D solids with fill,
  corner radius and opacity (and outline-based erasing), pen stabilisation,
  smoothing and pressure settings, a partial (pixel) eraser and a pressure
  eraser, hold-to-snap shapes, a rectangle lasso, restyling and outline
  lettering of written strokes, styled text boxes and images (frame, crop,
  opacity), `ScribbleWidget` slots for extra layers and overlays, lasso and
  image selection reporting, a zoom lock, and per-stroke position correction.
- Engine fixes: `preserveViewTransform` is honoured by the zoom correction;
  `ScribbleController` no longer fails when it is re-entered while it
  registers; a disposed `ScribbleNotifier` leaves the global tool state.
- New note layer (`package:open_note/note.dart`, without Material): notebooks
  and pages (paper templates, mixed orientation, rotation, margins, page
  numbers, page import, endless pages), layers, objects (sticky notes, arrows
  and curved lines, links, stickers, tables, cover masks and tape), tools and
  favourites, library with folders, tags and covers, bookmarks, outline,
  excerpts, search and links, viewing aids, drawing along a ruler,
  import/export (vector PDF, backups, bundles), study tools,
  `NoteEditorView` composing them (with a sticker collection manager, Apple
  Pencil gesture settings, a quick tool palette and selecting text on imported
  PDF pages), and `NoteWorkspaceView` with tabs, two-page spreads and split
  views.
