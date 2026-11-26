# Open Note

A note-taking toolkit for Flutter. It is the [`open_board`](../open_board)
drawing engine plus a **note layer** that does what note apps do: notebooks and
pages, layers, objects, tools, a library, navigation, reading aids,
import/export and study tools — composed by one widget, `NoteEditorView`.

The note layer does not use Material, so it fits any design system. Anything
that needs a platform service (rendering PDF pages, scanning, OCR, AI, audio,
web views, cloud storage) is a small interface with a fake, so apps plug in
their own.

## Install

```yaml
dependencies:
  open_note:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/open_note
      ref: <commit or open_note-vX.Y.Z tag>
```

`package:open_note/open_note.dart` exports the engine and the note layer;
`package:open_note/note.dart` exports the note layer alone.

## Quick start

```dart
final tables = NoteTableSelectionController();
final registry = standardNoteObjectRegistry(tableSelection: tables);
final documents = NoteDocumentRepository(
  FileNoteStore(Directory(appFolder)), // or your own NoteStore
  registry: registry,
);

final loaded = await documents.load('lecture-1');
final document = loaded?.document ??
    NoteDocument(
      id: 'lecture-1',
      registry: registry,
      defaultTemplate: NotePaperTemplate.lined(),
    );

final editor = NoteEditorController(
  document: document,
  repository: documents, // saves a few seconds after changes
  tableSelection: tables,
  onOpenUrl: openInBrowser,
);

// In the widget tree (any app widget):
NoteEditorView(
  controller: editor,
  strings: const NoteEditorStrings(), // translate here
  onPickImages: pickImages, // optional: your picker
  onStoreImage: saveImage, // optional: keeps captures as stickers
  aiPenService: myAiService, // optional
  onExport: () => exportNotePdf(document).then(share),
);

// When leaving:
await editor.save();
editor.dispose(); // never saves by itself
document.dispose();
```

The example app (`example/`, "Note Demo") has a library, a seeded tour note,
search and the whole editor.

## What the note layer does

| Area | Module | Highlights |
| --- | --- | --- |
| Notebooks and pages | `document/` | Paper per page, portrait/landscape, page sizes, rotate, extend margins (the ruling continues), endless pages, add before/after/at end, duplicate, move, trash and restore, import pages from another note, page numbers, pages with ink |
| Ink layers | `layer/` | Per-layer ink with one undo history, hide, lock, opacity, order, merge, move a selection to another layer |
| Editor | `editor/` | Rearrangeable toolbar (docked or floating), tool settings, lasso restyle, text styles and outline lettering, object, read, cover and capture modes, panels (layers, pages, bookmarks, outline, excerpts), page tags, drawing along the ruler, zoom favourites and "go to writing", swipe to turn pages while reading, recording and attachments; `NoteWorkspaceView` with tabs of open notes, two-page spread, one note twice, two notes and split views |
| Papers | `template/` | Blank, lined, grid, dotted, Cornell, music, image papers; spacing, line width, colours, sizes, live preview, template sources |
| Styles | `style/` | Line styles, 2-D and 3-D shapes, text boxes, image frame/crop/opacity |
| Tools | `tools/` | Pen stabilisation and pressure, favourites, text style favourites, eraser and lasso settings, custom TTF/OTF fonts, Apple Pencil gesture settings (a quick tool palette answers "show tool palette") |
| Objects | `objects/`, `table/` | Sticky notes, arrows and curved lines, link areas (pages, notes, URLs), stickers and a collection manager (create, rename, delete, add and reorder), tables with merged cells |
| Library | `library/` | Folders with icons, covers, pinning, drawer and list views with pinch zoom, sorting, multi-select, tags, trash |
| Finding things | `nav/` | Bookmarks, outline, excerpts with labels and a flash highlight, page tags, typed-text search, page and note links |
| Reading | `view/` | Page thumbnails, night and eye-comfort colours, ruler, magnifier, full screen, zoom lock and zoom favourites (in the editor); the layout and tab controllers behind the workspace, and split-drop targets |
| In and out | `io/` | Import PDF pages, office files, scans and images through your renderer; vector PDF and PNG export; note bundles; automatic and manual backups; image transfer pairing |
| Study | `study/` | Cover pen, boards and tape, AI pen over a captured region, floating windows, calculator, timer, stopwatch, scratchpad, recordings with speed, attachments |

## What your app provides

These are interfaces (with fakes for tests and previews):

| Need | Interface |
| --- | --- |
| PDF pages as pictures | `NotePdfPageRenderer` (used by `NotePdfRendererImporter`) |
| PDF text positions to select, highlight and copy | `NotePdfTextLayer`, given by PDF key as `NoteEditorController.pdfTextLayer` |
| Office/e-book files, document scanner | `NoteOfficeConverter`, `NoteDocumentScanner` |
| Pictures from the user, keeping captures | `NoteEditorView.onPickImages`, `onStoreImage` |
| AI answers | `NoteAiPenService` |
| Recording and playback | `NoteAudioRecorder`, `NoteAudioPlayer` |
| Web or chat windows | `NoteEditorView.studyWindows` |
| Handwriting search (OCR) | `NoteHandwritingIndexer` |
| Cloud backup | `NoteBackupDriver` (`DirectoryNoteBackupDriver` ships) |
| Sending an image to another device | `NoteImageTransferChannel` |
| Apple Pencil double tap / squeeze | call `NoteToolController.dispatcher.dispatch`; save `tools.gestures` to keep the user's choice |

## Storage

Everything goes through `NoteStore` (`FileNoteStore`, `MemoryNoteStore` or
your own):

- `library.json` — `NoteLibraryRepository` (folders, notes, view state).
- `notes/<note>/note.json` — page order, bookmarks, outline, excerpts, tags,
  attachments, recordings, every-page objects.
- `notes/<note>/pages/<page>/page.json` and `layer-<layer>.pb` — one engine
  `Scribble` per layer.

Saves run one after another and only rewrite changed pages. Files that cannot
be read are kept as `*.corrupt` and reported. Connect the library to the
documents with `onNotesRemoved` (delete) and `onNotesDuplicated` (duplicate).

## The drawing engine

The engine is `open_board` 0.3.2 with additions for the note layer (see
`CHANGELOG.md`); [`GUIDE.md`](GUIDE.md) covers using it on its own. Existing
files stay readable: the new protobuf fields start at 20 and are only written
when a style is used. The engine keeps the current tool in a global
`DrawingState`; `NoteToolController` writes it for the editor.

## Known limits

- PDF export keeps ink and shapes as vectors, but paper, text boxes and objects
  are embedded as images, so exported text is not selectable.
- Page links typed as `page:N` follow the page number. Links the editor makes
  (`pageid:…`) follow the page when pages move.
- Applying a paper to every page is undone for the open page only.
- Search covers typed text; handwriting needs a `NoteHandwritingIndexer`.
  There is no real-time sync.
- Objects shown on every page keep their place when an endless page grows to
  the left or top.
- Editors shown side by side must share one `NoteToolController` (the engine's
  tool state is global); `NoteWorkspaceController` does this for its panes.
- A workspace pane that shows the same page as the focused one is read-only
  until tapped; its first tap only moves the focus. Its undo history starts
  again when the other side changes that page.
- Selecting PDF text needs your `NotePdfTextLayer` (the editor does the
  selection, marks and copy). Text boxes are in the page size the PDF renderer
  reports, and the mode is offered only while the page's paper still shows the
  imported picture. It takes the pointer like the cover pen: zoom from the view
  menu while selecting.
- Sending images between devices: your app draws the pairing QR code and
  provides the `NoteImageTransferChannel`.
- Apple Pencil double tap and squeeze arrive through your platform code; pass
  them to `NoteToolController.dispatcher.dispatch`.

## Development

`docs/architecture-open-note.md` describes the modules and their rules.

```bash
cd packages/open_note
flutter test
dart analyze   # the engine's material.dart deprecation notes are expected
```

## License

BSD 3-Clause. See `LICENSE`.
