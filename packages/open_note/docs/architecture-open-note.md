# open_note — architecture and module specs

`open_note` is a Flutter handwriting-note engine. It started as a clone of
`open_board` (the drawing and annotation engine: `Scribble*`, pens, lasso, text,
images, multi-page, replay) and adds the note-taking layer found in apps such as
Noteful, Star Note, Notes+ and Free Notes: notebooks, pages and templates,
layers, objects (sticky notes, tables, masks…), tool presets, outline and
bookmarks, a library, split views, import/export and study aids.

This document is the contract between the people (and agents) implementing the
modules in parallel. **Read sections 1–4, then your own module in section 5.**

## 1. Layers

```
lib/
  open_note.dart          barrel: engine + note layer
  modules.dart ...        engine barrels (from open_board; do not edit)
  note.dart               barrel of the note layer (re-exports module barrels)
  src/
    module/ core/ data/   the engine: ScribbleNotifier, ScribbleWidget, protobuf
    note/                 the note layer (this document)
      core/               shared primitives (section 4) — already written
      template/ style/    5.1 render primitives
      tools/              5.2
      objects/            5.3
      table/              5.4
      study/overlay/      5.5
      study/utilities/    5.6
      nav/                5.7
      library/            5.8
      view/               5.9
      io/                 5.10
      layer/ document/ editor/   section 6
```

Page coordinates: a page has a logical size in PDF points (`NotePageSize`, A4 is
595 x 842), origin top-left, y down. Strokes, text, images and objects all use
page coordinates. A widget that overlays a page receives **tight constraints
equal to the page size** and draws in page coordinates; the host scales and
pans it (so never rely on the screen size, and never read `MediaQuery` to size
page content).

Ink is the engine's `Scribble` (protobuf: `Stroke`, `TextDrawable`,
`ImageDrawable`). A page has one `Scribble` per *layer*. Objects are not ink —
they are `NoteObject`s (section 4) kept beside the layers.

## 2. Waves

Wave 1 (parallel, independent): modules 5.1–5.10. A module may depend only on
`core`, the engine, and the Flutter SDK — **never on another wave-1 module**.
Wave 2 (integrator): engine extensions (line styles on strokes, pen settings,
pixel eraser, styled shapes/text/images), layers, the document aggregate and
repository, the editor widget, the example app. The integrator wires your
module's public API into those, so keep your API small, documented and stable.

## 3. Common rules (every module owner)

Paths: the package is
`packages/open_note` in this repository. All
commands below run from there.

**Ownership.** You own only `lib/src/note/<your path>/**` and
`test/note/<your path>/**`. Do not edit any other file: not `pubspec.yaml`, not
another module, not the engine (`lib/src/module`, `lib/src/core`,
`lib/src/data`), not `lib/note.dart`, not `core`. If something outside your
module must change, do not do it — write it in your final report. Your module
barrel `lib/src/note/<path>/<name>.dart` already exists as a stub: replace its
content with `export` lines for every public file.

**Forbidden.** `flutter pub get` / `pub add` / any dependency change; git
commands that change state (`add`, `commit`, `checkout`, `stash`, `reset`,
`restore`, `clean`); deleting anything outside your module; touching `build/`
or `.dart_tool/`; running `dcm format` or `dart format` on paths that are not
yours. Other module owners are editing the same working tree at the same time.

**Dependencies.** None may be added. You may use: Dart SDK libraries, the
Flutter SDK (`widgets`, `painting`, `rendering`, `gestures`, `services`,
`foundation`, `scheduler`, `animation`), and the package's own dependencies
(`protobuf`, `fixnum`, `vector_math`, `perfect_freehand`,
`value_notifier_tools`, `shared_preferences`, `path_provider`, `flutter_svg`).

**No design system.** Never import `package:flutter/material.dart` or
`cupertino.dart` in `lib/` (newer Flutter versions deprecate material.dart and
the analyzer then fails `--fatal-infos`; the package must not tie apps to a
design system). Build visuals from `widgets`/`painting` primitives. In tests
use `noteTestHost` (`test/note/support/note_test_host.dart`: a `WidgetsApp`
with Navigator, Overlay, MediaQuery) instead of `MaterialApp`.

**Style.**
- English identifiers and doc comments in new code. Every public type and member
  has a `///` comment that states *semantics* (units, ranges, defaults, what
  happens on bad input), not just the name.
- One primary public class per file, named after the file
  (`note_paper_template.dart` → `NotePaperTemplate`).
- Public type names are prefixed `Note` (`NotePaperTemplate`, `NoteLibrary`…);
  before naming, `grep -rn "class YourName" lib/` to avoid clashes.
- Immutable models: `@immutable`, `const` constructors where possible,
  `copyWith`, `==`/`hashCode` (`Object.hash`, `listEquals`/`mapEquals` from
  `package:flutter/foundation.dart`), `toJson()` and a lenient
  `fromJson(Object?)` built on `NoteJson`. `fromJson` never throws on malformed
  input: it clamps ranges, falls back on unknown enum names and skips bad list
  entries. Document the JSON schema in the class comment. Persisted keys and
  enum `name`s are forever — choose them carefully.
- Controllers extend `ChangeNotifier`; notify only on real changes; `dispose()`
  releases everything; methods after `dispose()` are no-ops (or assert).
- Time and ids are injectable (`NoteClock`, `NoteIdFactory`) so tests are
  deterministic.
- Persistence goes through `NoteStore` only (never `dart:io` directly, except
  where your spec says otherwise).
- Widgets: plain, usable default visuals; colors/sizes through constructor
  parameters or a small `...Style` class with defaults; all user-visible text
  from a per-module `...Strings` class with English defaults, passed as
  `strings:` so apps translate. Add `Semantics`/tooltips to interactive parts.
- Formatting is `dcm format` (80 columns, cascading widget extensions).
- Keep methods short and files focused (DCM warns about long methods and many
  methods per class; it is advisory, but do not pile everything into one class).

**Tests.** Every public model and controller has unit tests (JSON round trip and
malformed input, boundary values, invariants, undo where relevant). Every widget
has widget tests for its key interactions. Tests are fast and deterministic
(no real clocks, timers, randomness or network without injection). Put them in
`test/note/<your path>/`.

**Verify before you report** (keep output small):

```bash
dcm format lib/src/note/<path> test/note/<path>
dart analyze --fatal-infos lib/src/note/<path> test/note/<path>   # must say: No issues found!
flutter test --no-pub --reporter=compact test/note/<path> 2>&1 | tr '\r' '\n' | tail -5 | cut -c1-200
```

Diagnostics from files that are not yours (another owner mid-edit, or the
integrator's engine work) are not your problem — wait a minute and re-run; never
"fix" them. `flutter test` prints huge single lines with the compact reporter:
always pipe through `tr '\r' '\n' | tail`.

**Final report** (at most 60 lines): files created with line counts; the public
API (class names with one line each); JSON schemas; test counts and the
commands you ran with their results; spec items you did **not** implement or
deviated from, and why; what the integrator must do (engine wiring, host
callbacks).

## 4. Foundation — `lib/src/note/core` (already written and tested)

Import with `package:open_note/src/note/core/core.dart`.

| API | Purpose |
| --- | --- |
| `JsonMap`, `NoteJson` | lenient readers/writers: `string/integer/number/boolean/list/map/mapList/stringList/enumByName`, `colorToJson/colorFromJson`, `rect*`, `offset*`, `encode/decodeMap` |
| `NoteIdFactory`, `generateNoteId`, `NoteClock`, `systemNoteClock` | injectable ids and time |
| `NotePageSize`, `NotePageOrientation` | page size in PDF points; presets `a4 a5 letter square`; `rotated`, `withOrientation` |
| `NoteStore`, `NoteStoreKeys`, `MemoryNoteStore`, `FileNoteStore`, `NoteStoreException` | virtual file system: `exists/readBytes/readString/writeBytes/writeString/delete/deletePrefix/list(prefix)`; keys are safe relative `/` paths |
| `NoteUndoStack`, `NoteUndoable`, `NoteCallbackUndoable` | one linear undo history; pushes during an undo are ignored (`isApplying`) |
| `NoteLinkTarget` (`NotePageLink`, `NotePageIdLink`, `NoteNoteLink`, `NoteUrlLink`) | one-string link grammar: `page:N`, `pageid:PAGE_ID` (survives reordering; the editor writes this), `note:ID`, `note:ID#page:N`, URLs |
| `NoteObject`, `NoteObjectBase`, `NoteObjectDecoder`, `NoteObjectRegistry`, `NoteObjectViewScope`, `NoteObjectPaintContext`, `NoteUnknownObject` | the object contract (below) |
| `NoteSlider`, `NoteTextField` | plain-widget slider and text input every module reuses |

### The object contract

An object is an immutable `NoteObject` with `id`, `bounds` (page coordinates,
before rotation), `rotation` (clockwise radians about `bounds.center`),
`opacity`, `locked`, a unique `kind`, `withBase(...)`, `payloadToJson()` and
`paintToCanvas(canvas, context)` (export/capture; synchronous; the canvas is
already positioned, so draw inside `bounds`). A kind is registered with
`registry.register(kind, decoder: (base, payload) => ..., builder: (context,
object, scope) => widget)`. The widget is laid out inside `bounds` (tight
constraints) and is rotated and faded by the hosting layer: fill your
constraints. `NoteObjectViewScope` carries `selected`, `editing`, `interactive`
and the callbacks `onChanged(newObject)` (commit an edit; the host records undo),
`onLinkActivated`, `onRequestEdit`. A module that ships object kinds exposes
`void registerXxxObjects(NoteObjectRegistry registry)`.

## 5. Module specs

Names below are the required public names; file names are suggestions. Anything
not listed is yours to design. Ranges and defaults given here are binding (the
integrator relies on them).

### 5.1 render — `template/` and `style/`

One owner for both (rendering primitives: paper templates, line styles, shape,
text-box and image styles). Barrels: `template/template.dart`,
`style/style.dart`. Tests: `test/note/template/`, `test/note/style/`.

**template**
- `NotePaperKind { blank, lined, grid, dotted, cornell, music, image }`.
- `NotePaperTemplate` (immutable, JSON): `id`, `name`, `kind`, `size`
  (`NotePageSize`), `lineSpacing` (page units; **clamped 6–120**; per-kind
  defaults: lined 28, grid 24, dotted 24, cornell 28, music 10), `lineWidth`
  (**0.25–4**, default 0.6), `lineColor`, `backgroundColor` (default white),
  `accentColor` (cornell cue column / margin line), `margins` (left/top/right/
  bottom insets of the writable area), `showMarginLine`, `imageSource`
  (`String?`, for `image`), `imageFit` (`contain|cover|fill`), `imageOpacity`.
  Static factories per kind; `copyWith`; `fitted(NotePageSize)`.
- `NotePaperPainter` (`CustomPainter`, deterministic, `shouldRepaint` correct),
  `NotePaperView` (widget sized **exactly** to `template.size`, usable as a
  page background child; for `image` it resolves the source through an
  injectable `imageProviderResolver` defaulting to the engine's
  `resolveImageSource` in `lib/src/module/image/image_source_resolver.dart`, and
  shows plain paper until the image is ready).
- `NotePaperCatalog` (`ChangeNotifier`): built-ins with stable ids
  `builtin.blank|lined|grid|dotted|cornell|music`; `register`, `unregister`,
  `find(id)`, `byKind`.
- `NoteTemplateSource` (interface, the "resource center"):
  `Future<List<NoteTemplateDescriptor>> list({String? query, int offset = 0, int
  limit = 50})`, `Future<NotePaperTemplate?> fetch(String id)`;
  `NoteTemplateDescriptor {id, name, kind, thumbnailSource?, tags}`;
  `MemoryNoteTemplateSource` for tests and the example.
- `NotePaperPicker` widget: grid of live previews, selection callback, and
  optional line-spacing / line-width controls (`NoteSlider`) that update the
  preview immediately. `NotePaperStrings`.

**style** (pure geometry, codecs and painters — no engine types)
- `NoteLineStyleKind { solid, dashed, dotted, wavy, zigzag, double }` and
  `NoteLineStyle {kind, dashLength, gap, amplitude, wavelength, doubleGap}`; all
  lengths are **multiples of the stroke width** (so a style scales with
  thickness): dash/gap 0.2–10 (defaults dashed 1.4/1.6, dotted 0.1/1.6),
  amplitude 0.2–6 and wavelength 1–20 (wavy and zigzag), doubleGap 0.3–6.
  `encode()` → one compact string and `NoteLineStyle.decode(String?)` (unknown or
  malformed → `solid`): grammar `kind` or `kind:p1:p2…` with the parameters in the
  field order above; document it exactly (it is stored in a protobuf string).
- `NoteLinePath`: `smooth(List<Offset>)` (de-noise + Catmull-Rom/Chaikin, keeps
  the endpoints) and `renderPaths(points, width, style) → List<NoteStyledPath
  {Path path; double strokeWidth; StrokeCap cap}>` (dashed/dotted/wavy/zigzag
  stroke one decorated path; `double` yields two parallel paths), and
  `NoteStyledStrokePainter.paint(canvas, points, color, width, style)`.
- `NoteShapeKind` (at least `line, arrow, doubleArrow, rectangle,
  roundedRectangle, ellipse, triangle, rightTriangle, diamond, pentagon, hexagon,
  star, cube, cylinder, cone, pyramid, sphere`) and `NoteShapeGeometry.pathsFor(
  kind, Rect rect, {double cornerRadius})` → `NoteShapePaths {Path outline; Path?
  inner; Path? hidden}` (3-D kinds are isometric wire-frames: `inner` = visible
  interior edges, `hidden` = edges to draw dashed). All geometry stays inside
  `rect`.
- `NoteShapeStyle {fillColor?, fillOpacity, strokeOpacity, cornerRadius,
  lineStyle, headStyle}` (`headStyle`: `none|triangle|open|dot` for arrow kinds)
  with `encode()`/`decode()` as a compact JSON string, and `NoteShapePainter.
  paint(canvas, rect, kind, strokeColor, width, style)`.
- `NoteTextBoxStyle {backgroundColor?, borderColor?, borderWidth, borderLineStyle
  (solid|dashed), cornerRadius, padding (4 doubles), opacity, lineHeight
  (multiplier; 0 = font default)}` with `encode()`/`decode()` and
  `NoteTextBoxDecoration.paint(canvas, Rect textBounds, style)` /
  `outerRect(textBounds, style)` (padding inflates the box).
- `NoteImageStyle {borderColor?, borderWidth, cornerRadius, opacity, crop}` and
  `NoteImageCrop` (either fractional `l,t,r,b` of the image, or a freeform
  polygon in 0–1 image coordinates), `encode()`/`decode()`, and
  `NoteImageStylePainter.paint(canvas, ui.Image image, Rect dest, style)`
  (+ `clipPathFor(Rect dest, style)`).

### 5.2 tools — `tools/`

Barrel `tools/tools.dart`; tests `test/note/tools/`. Settings and presets are
plain models; the integrator maps them to the engine, so each exposes the plain
numbers the engine needs.

- `NotePenSettings {motionSmoothing (int 0–10, default 5), stabilization
  (0–1, default 0.2), pressureSensitivity (0–1, default 0.5)}` +
  `toEngineParams() → NotePenEngineParams {double streamline, smoothing,
  thinningScale, pressureGamma}`. Mapping (document and test it):
  `smoothing = motionSmoothing / 10`; `streamline = 0.1 + 0.8 * stabilization`;
  `thinningScale` is 1.0 at the default and moves in `[0.25, 1.5]`;
  `pressureGamma = 2^(2 * (pressureSensitivity - 0.5))` — 0.5 leaves pressure
  untouched, lower values make light touches *thicker*, higher values thinner.
- `NoteToolPreset {id, name, ink, color, width, lineStyle (opaque String,
  default 'solid'), shapeTarget (String, default '')}` — `ink` is one of the
  engine strings `pen|pencil|marker|fixedPen|uniformPen|shape|text`. `widthLabel`
  trims trailing zeros (`0.3`, `3`, `2.5`).
- `NoteToolPresetStore` (`ChangeNotifier`): `presets`, `activeId`, `add`,
  `addFrom({...})`, `update`, `remove`, `move(oldIndex, newIndex)`, `select(id)`,
  `byInk(ink)`, `maxPresets` (default 24), `NoteToolPresetStore.defaults()`
  (black/red/blue/white pens at distinct widths + a yellow marker),
  `load(NoteStore)` / `save(NoteStore)` at key `tools/presets.json`.
- `NoteTextStylePreset {id, name, fontFamily, fontSize, lineHeight, color, bold,
  italic, underline, align}` + `NoteTextStylePresetStore` (same API shape as the
  tool presets, key `tools/text_styles.json`). Applying a preset to existing text
  is the integrator's job; expose `toJson`/fields only.
- `NoteFontManager` (`ChangeNotifier`): `registerFont(String family, Uint8List
  bytes)` (loads through `FontLoader`; ignores duplicates; validates a TTF/OTF
  header), `families`, persistence of the font bytes through `NoteStore` under
  `fonts/<family>.<ext>` plus `fonts/index.json`, `restore(NoteStore)`;
  `NoteFontSource` (interface: `list({query})`, `download(id) → bytes`) and
  `MemoryNoteFontSource`.
- `NoteToolbarLayout {items: List<NoteToolbarItem {id, visible}>, placement
  (docked|floating), dockEdge (top|bottom|left|right), floatingOffset}` with
  `moveItem`, `setVisible`, `reset()`, JSON. Item ids: `pen pencil marker eraser
  lasso shape text image undo redo layers presets` (extensible strings).
- `NoteEraserSettings {mode (stroke|pixel), size (2–80, default 12),
  pressureSwitchEnabled (default false), pressureThreshold (0.1–1, default
  0.8)}`; `NoteLassoSettings {shape (freeform|rectangle)}`.
- `NotePencilGesture {doubleTap, squeeze}`, `NotePencilAction {none,
  switchPreviousTool, toggleEraser, undo, redo, showToolPalette, cyclePreset}`,
  `NotePencilGestureMap` (defaults: doubleTap → `switchPreviousTool`, squeeze →
  `showToolPalette`; JSON), `NoteToolActions` (interface: `currentTool`,
  `selectTool(ink)`, `previousTool()`, `toggleEraser()`, `undo()`, `redo()`,
  `showToolPalette()`, `cyclePreset()`), `NotePencilGestureDispatcher(map,
  actions).dispatch(gesture)`. The host binds the platform gesture to
  `dispatch`. `NotePencilGesturePanel(map, onChanged)` edits the map (the
  editor opens it from the pen options; `NoteToolController.gestures` is the
  live map). Unless the host gives `onShowToolPalette`, the editor shows its
  quick palette near the last pen hover position (in a workspace, the focused
  pane's).
- Colors: `NoteColorUtils.parseHex(String) → Color?` (`#RGB`, `#RRGGBB`,
  `#AARRGGBB`, with or without `#`, case-insensitive), `toHex(color, {alpha})`;
  `NoteHsv {h, s, v, a}` with `toColor`/`fromColor`; `NoteColorSlots` (ordered
  favorites + recents, `max`, JSON).
- Widgets: `NoteColorPicker` (hue strip + saturation/value plane + hex field +
  swatches + optional `Future<Color?> Function()? onEyedropper`),
  `NotePenSettingsSheet` (the three sliders with live numeric values and a
  "?" help text for each), `NoteToolPresetBar` (swatch + numeric width label per
  preset, tap selects, long-press reports for editing),
  `NoteEraserSettingsPanel`. `NoteToolsStrings`.

### 5.3 objects — `objects/`

Barrel `objects/objects.dart`; tests `test/note/objects/`.

- `NoteObjectController` (`ChangeNotifier`): constructor `({List<NoteObject>
  objects = const [], NoteUndoStack? history, NoteIdFactory? idFactory,
  NoteClock? clock})`; `objects` (unmodifiable, index 0 is the bottom),
  `selectedIds`, `selection`; `select(id, {additive})`, `selectAll`,
  `clearSelection`; `add(object, {select = true})`, `update(object)` (by id; no-op
  when equal), `moveBy(ids, delta)`, `resize(id, Rect)`, `rotate(id, radians)`,
  `remove(ids)`, `duplicate(ids, {offset})`, `bringToFront/sendToBack/
  moveForward/moveBackward(ids)`, `setLocked(ids, v)`, `setOpacity(ids, v)`,
  `replaceAll(objects)` (a load: no history, clears selection),
  `objectAt(Offset pagePoint)` (top-most hit, honouring rotation; ignores
  nothing), `selectionBounds`. Locked objects ignore move/resize/rotate/remove.
  With a `history`, every mutation pushes one `NoteUndoable` that restores the
  previous list *and* selection; a drag is one undo step (`beginGesture()` /
  `endGesture()` coalescing).
- `NoteObjectLayer` (widget): `({controller, registry, size, mode,
  onLinkActivated, selectionColor, handleSize})`, `NoteObjectLayerMode { view,
  edit, passThrough }`. It paints every object in z-order, positioned, rotated and
  faded, through `registry.buildView`. **`view`**: objects receive taps
  themselves (masks reveal, links activate); no selection. **`edit`**: tap
  selects the top-most object; drag moves the selection; a selection frame with
  eight resize handles and a rotation handle (resizing respects rotation; a
  minimum size of 12 units); double-tap requests inline editing (sets the
  `editing` flag of the scope); a locked object shows a lock mark and cannot be
  transformed. **`passThrough`**: ignores all pointers (used while drawing).
  Outside any object the layer must let pointers fall through to what is beneath
  (hit-test only where objects are).
- Kinds (each: immutable class, `kind`, JSON payload, widget, `paintToCanvas`):
  - `NoteStickyObject` (`kind 'sticky'`): `text`, `paperColor`, `textColor`,
    `fontSize`, `shadow`. Shows the text; while `scope.editing` shows a
    `NoteTextField` that commits through `onChanged`.
  - `NoteArrowObject` (`'arrow'`): `start`, `end` as fractions (0–1) of
    `bounds`, `color`, `width`, `headStyle` (`none|triangle|open`), `tailStyle`,
    `dashed`. Moving/resizing/rotating works through `bounds`.
  - `NoteLinkObject` (`'link'`): hotspot with `target` (wire form of
    `NoteLinkTarget`), `appearance` (`hidden|outline|underline`). In `view` mode a
    tap calls `scope.onLinkActivated(NoteLinkTarget.parse(target))`; its
    `linkTarget` getter returns the parsed target.
  - `NoteStickerObject` (`'sticker'`): `source` (opaque string, resolved with an
    injectable `ImageProvider` resolver defaulting to the engine's
    `resolveImageSource`), `flipHorizontal`. `paintToCanvas` draws
    `context.imageFor(source)` or, when absent, a light placeholder.
- Stickers: `NoteStickerItem {id, source, name?}`, `NoteStickerCollection {id,
  name, items}`, `NoteStickerStore` (`ChangeNotifier`): `collections`,
  `createCollection(name)`, `rename`, `delete`, `addItem(collectionId, source)`,
  `importAll(collectionId, List<String> sources)` (bulk import, skips duplicates
  by source), `removeItem`, `moveItem`, `load/save(NoteStore)` at
  `stickers/collections.json`. `NoteStickerManager(store, onSelected,
  onPickPictures)` lists and edits them (deleting a collection takes a second
  tap); it is the editor's sticker menu. Saving the store is the app's job.
- `void registerNoteObjects(NoteObjectRegistry registry)` registers sticky,
  arrow, link and sticker. `NoteObjectsStrings` for the layer's accessibility
  labels.

### 5.4 table — `table/`

Barrel `table/table.dart`; tests `test/note/table/`.

- `NoteTableObject` (`kind 'table'`, extends `NoteObject`): `rows × columns`
  grid. Model: `columnWidths` and `rowHeights` as fractions that each sum to 1,
  `cells` (row-major `NoteTableCell {text, rowSpan, columnSpan, fillColor?,
  textColor?, bold, align}`; a cell covered by a merge is marked `covered`),
  `style` (`NoteTableStyle {borderColor, borderWidth, headerRow, headerFill,
  cellPadding, fontSize, textColor}`). Invariants (assert in tests): the grid is
  always rectangular, spans never overlap or leave the grid, fractions sum to 1.
- Pure operations returning a new table: `insertRow(at)`, `insertColumn(at)`,
  `deleteRow(i)`, `deleteColumn(i)` (never below 1×1), `mergeCells(NoteTableRange)`,
  `splitCell(row, column)`, `setCellText`, `setCell`, `setColumnWidth(i, f)`
  (neighbour absorbs the change; minimum fraction 0.05), `setRowHeight`,
  `withSize(rows, columns)`. `NoteTableRange {firstRow, firstColumn, lastRow,
  lastColumn}` normalised, with `contains`, `intersects`.
- Widget: `NoteTableView` renders the grid inside `bounds`; with `scope.
  interactive` a tap selects a cell, a drag selects a rectangular range (shown
  with a highlight), double-tap (or `scope.editing`) edits the cell text with a
  `NoteTextField`; commits through `scope.onChanged`. `NoteTableToolbar`: row
  above/below, column left/right, delete row/column, merge, split — each calls a
  callback with the new table. `paintToCanvas` draws borders, fills and text.
- `void registerNoteTableObject(NoteObjectRegistry registry)`.
  `NoteTableStrings`.

### 5.5 study/overlay — `study/overlay/`

Barrel `study/overlay/overlay.dart`; tests `test/note/study/overlay/`.

- Masks (cover-up for memorising): `NoteMaskObject` (`kind 'mask'`): `shape`
  (`rect|stroke`; for `stroke`, `points` + `thickness`), `fill` (`NoteMaskFill`:
  solid color, `stripes`, `dots`, or an image `source`), `revealed`, `scope`
  (`NoteMaskScope { page, document }` — a `document` mask must be shown on every
  page; the integrator does that), `fillOpacity`. Tapping toggles `revealed`
  through `scope.onChanged` (the widget is a no-op when `!interactive`). When
  revealed the mask shows only a faint outline.
- Tape: `NoteTapeObject` (`'tape'`): a straight tape (`start`, `end`,
  `thickness`) or a rectangle, colour/pattern, `revealed`; same tap behaviour.
- `NoteMaskOps` (pure functions over `List<NoteObject>`): `revealAll`, `hideAll`
  (mask and tape kinds only), `clearAll` (remove them), `restyleAll(fill?,
  opacity?)`, `counts` → `(total, revealed)`; `NoteMaskPenSession`: feed it the
  pen's page points and get a `NoteMaskObject` back (rect from the bounding box,
  or `stroke` shape) with a configurable minimum size.
- Region selection: `NoteRegionSelector` widget (drag a rectangle in page
  coordinates over the page; handles, move, resize; `onRegionSelected(Rect)`,
  `onCancel`; minimum size; clamps to the page) — used by the AI pen and the
  screenshot pen.
- AI pen: `NoteAiPenKind {solve, explain, translate}`, `NoteAiPenRequest {kind,
  imagePng (Uint8List?), text?, targetLocale?}`, `NoteAiPenResult {text,
  kind, steps?}`, `NoteAiPenService` (interface: `Future<NoteAiPenResult>
  run(NoteAiPenRequest)`), `NoteAiPenException`, `UnconfiguredNoteAiPenService`
  (throws a typed exception), `FakeNoteAiPenService` (scripted answers, optional
  delay), `NoteAiPenController` (`idle|running|done|error`, `run(request)`,
  `cancel()` — a cancelled request's late result is dropped, `result`, `error`),
  `NoteAiPenResultPanel` (tabs for the three kinds, result text, copy and close
  callbacks, busy and error states). The package ships no network client: the
  host implements `NoteAiPenService`.
- Floating tool windows: `NoteFloatingWindowSpec {id, title, builder,
  initialRect, minSize, resizable, opacity}`, `NoteFloatingWindowController`
  (`ChangeNotifier`: `open/close/focus/move/resize/setOpacity/togglePin/
  minimize`, z-order, `windows`), `NoteFloatingWindowHost` (a `Stack` that draws
  windows with a title bar to drag, a corner to resize, close/minimize/pin
  buttons; clamps windows inside the host; the focused window is on top). The
  window body is whatever the host builds (a web view for a browser or a chat);
  the package embeds none.
- `void registerNoteStudyObjects(NoteObjectRegistry registry)` registers masks
  and tape. `NoteStudyOverlayStrings`.

### 5.6 study/utilities — `study/utilities/`

Barrel `study/utilities/utilities.dart`; tests `test/note/study/utilities/`.

- Timer: `NoteTimerController` (`ChangeNotifier`; countdown; `idle|running|
  paused|finished`; `start`, `pause`, `resume`, `reset`, `setDuration`, `remaining`;
  `tick(Duration elapsed)` is public so tests drive time; production uses an
  injectable periodic `NoteTicker`), `NoteStopwatchController` (`start/pause/
  reset/lap`, `laps`), widgets `NoteTimerView`, `NoteStopwatchView` (digits
  `mm:ss`, `h:mm:ss` above an hour, start/pause/reset buttons).
- Calculator: `NoteCalculator.evaluate(String) → double` (a hand-written
  parser: `+ - × ÷ * / ^ %`, parentheses, unary minus, decimals, `sqrt`, `sin`,
  `cos`, `tan`, `log`, `ln`, `abs`, `pi`, `e`; radians; throws
  `NoteCalculatorException` on bad input, division by zero, overflow),
  `NoteCalculatorController` (keypad state machine: digits, operators, parentheses,
  `clear`, `backspace`, `equals`, `memory +/-/recall/clear`, `display`,
  `history`), `NoteCalculatorView` (keypad grid + display).
- Scratchpad: `NoteScratchpadController` (owns a `ScribbleController`;
  `color`, `opacity` of the sheet, `clear()`), `NoteScratchpadView` (a small
  drawing surface on a coloured, translucent sheet built on the engine's
  `SimpleScribbleWidget`).
- Recordings: `NoteRecording {id, title, source, duration, createdAt,
  pageNumber?, playbackSpeed}`, `NoteAudioRecorder` (interface: `start() `,
  `stop() → NoteRecording`, `isRecording`, `elapsed` stream), `NoteAudioPlayer`
  (interface: `load(source)`, `play`, `pause`, `seek`, `setSpeed`, `position`
  stream, `state`), `FakeNoteAudioPlayer` (deterministic, for tests),
  `NoteRecordingController` (list of recordings, current playback, speed presets
  `0.5 0.75 1 1.25 1.5 2`, `rename`, `remove`, `attachToPage`), widget
  `NoteRecordingList` (rows with play/pause, speed cycle, delete).
- Attachments: `NoteAttachment {id, kind (audio|video|document|link), source,
  title, createdAt}`, `NoteAttachmentList` (`ChangeNotifier`: add, remove,
  rename, move, `byKind`, JSON). Hosts implement actual recording/playback with
  plugins; the package ships only the interfaces and the fakes.
- `NoteStudyUtilitiesStrings`.

### 5.7 nav — `nav/`

Barrel `nav/nav.dart`; tests `test/note/nav/`. Pages are referenced by **page id**
(stable across reordering); the page order is passed in where needed.

- Bookmarks: `NoteBookmark {id, pageId, title, createdAt}`, `NoteBookmarks`
  (`ChangeNotifier`): `toggle(pageId, {title})`, `isBookmarked`, `rename`,
  `remove`, `removePage(pageId)`, `ordered(List<String> pageOrder)`, JSON.
- Outline: `NoteOutlineEntry {id, title, pageId, children}`, `NoteOutline`
  (`ChangeNotifier`): `add(title, pageId, {parentId, index})`, `remove`, `rename`,
  `setTarget`, `move(id, newParentId, index)`, `indent(id)`, `outdent(id)`,
  `flatten()` (depth-first with depth), `entryForPage`, `breadcrumb(pageId)`,
  `removePage(pageId)`, JSON; `NoteOutlineBuilder.calendar({year, monthPageIds,
  titleOf})` builds a year → months outline for diaries.
- Excerpts: `NoteExcerpt {id, pageId, rect (fractions of the page 0–1), label?,
  note?, color?, createdAt}`, `NoteExcerpts` (`ChangeNotifier`): `add`, `update`,
  `remove`, `removePage`, `byPage`, `byLabel`, `labels` (distinct with counts),
  `search(query)` (label and note, case-insensitive), `ordered(pageOrder)`, JSON;
  `NoteExcerptFlashController` (`flash(excerptId)` drives a 1→0 progress over
  `duration` for the "jump and fade a highlight" effect; injectable ticker) and
  `NoteExcerptFlashOverlay` (paints the fading highlight over the excerpt rect).
- Tags: `NoteTagRef {noteId, pageId?}`, `NoteTags` (`ChangeNotifier`): `add(tag,
  ref)`, `remove`, `tagsOf(ref)`, `refsOf(tag)`, `rename(old, new)` (merges),
  `delete(tag)`, `allTags` with counts. Tags are normalised (trim, collapse
  whitespace, lower-case comparison, ≤ 40 characters; the first spelling is kept
  for display).
- Search: `NoteSearchHit {noteId, pageId, kind (text|excerpt|bookmark|outline|
  tag|handwriting), snippet, matchStart, matchEnd}`, `NoteSearchIndex`
  (`indexPage(noteId, pageId, texts)`, `removePage`, `removeNote`, `search(query,
  {limit, kinds})`: case-insensitive substring matching that works for Hangul
  and CJK (no word-boundary assumption); ranking exact > prefix > substring, then
  shorter snippet), `NotePageTextExtractor.fromScribble(Scribble) → List<String>`
  (text drawables in reading order: top to bottom, then left to right),
  `NoteHandwritingIndexer` (interface: `Future<List<String>> recognize(Scribble)`)
  and `NoopHandwritingIndexer`. Handwriting search is a host plug-in; the
  package ships none.
- Links: `NoteLinkNavigator` resolves a `NoteLinkTarget` against the page order
  and calls `goToPage(pageId)`, `openNote(noteId, pageId?)`, `openUrl(url)`;
  unresolvable targets call `onUnresolved`.
- Widgets (plain visuals, callbacks, strings): `NoteOutlinePanel` (tree with
  expand/collapse, tap to jump, edit mode with add/rename/delete/indent),
  `NoteBookmarkPanel`, `NoteExcerptPanel` (grouped by label, search field, label
  chips), `NoteTagEditor` (chips + input + suggestions), `NoteSearchPanel`.
  `NoteNavStrings`.

### 5.8 library — `library/`

Barrel `library/library.dart`; tests `test/note/library/`.

- `NoteCover {kind (builtin|color|image), builtinId?, color?, imageSource?,
  size (NotePageSize), orientation}` with `NoteCoverCatalog.builtIn` (at least 12
  ids), `NoteCoverView` (paints a cover at any size; image covers resolve
  through an injectable `ImageProvider` resolver).
- `NoteSummary {id, title, cover, tags, pinned, folderId?, createdAt, modifiedAt,
  pageCount}` (JSON) and `NoteFolder {id, name, iconKey, parentId?, order,
  createdAt}`; `NoteFolderIcons.keys` (at least 10) and `NoteFolderIconView`
  (a small vector glyph per key).
- `NoteLibrary` (`ChangeNotifier`): `folders`, `notes`, `trash`, view state.
  Folders: `createFolder`, `renameFolder`, `setFolderIcon`, `moveFolder`,
  `reorderFolder`, `deleteFolder({moveNotesTo})`. Notes: `createNote({title,
  cover, folderId})`, `renameNote`, `setCover`, `moveNotes(ids, folderId)`,
  `duplicateNotes(ids)` (new ids, titles suffixed "copy", pinned cleared),
  `deleteNotes(ids)` (to `trash`), `restoreNotes`, `emptyTrash`, `pin/unpin`,
  `addTag/removeTag`, `touch(id, {pageCount})` (updates `modifiedAt`). Selection:
  `selectionMode`, `selection`, `toggleSelect`, `selectAll`, `clearSelection`.
  Queries: `visibleNotes()` honouring `NoteLibraryViewState {layout (list|
  drawer), drawerZoom (0.5–2.0, default 1), sortField (name|modified|created),
  sortOrder, folderId?, tag?, query?}`; pinned notes first; name sort is
  case-insensitive and uses natural number ordering; `zoomDrawer(scaleDelta)`
  clamps. Callbacks: `onNotesRemoved(ids)` so the document layer deletes data.
- `NoteLibraryRepository(NoteStore, {debounce, scheduler})`: `load()`,
  `save()`, `bind(NoteLibrary)` to save after changes, debounced (injectable
  timer), key `library.json`; a corrupt file loads an empty library and keeps a
  backup copy `library.corrupt.json`.
- Widgets: `NoteLibraryView` (drawer grid of covers + list layout; pinch changes
  the drawer zoom; pinned section first; selection mode with checkmarks; callbacks
  `onOpenNote`, `onLongPressNote`), `NoteTile`, `NoteFolderSidebar` (icons, note
  counts, selection), `NoteThumbnailProvider` (interface so the host can render a
  page preview in a tile). `NoteLibraryStrings`.

### 5.9 view — `view/`

Barrel `view/view.dart`; tests `test/note/view/`.

- Layout: `NoteViewMode {single, twoPage, doubleReading, dualDocument, split}`,
  `NoteViewPane {id, noteId?, pageIndex}`, `NoteViewLayoutController`
  (`ChangeNotifier`): `mode`, `panes`, `ratio` (0.2–0.8), `axis`, `setMode`,
  `addPane`, `removePane`, `setPage(paneId, index)`, `swapPanes`, `openBeside(
  noteId, pageIndex, {side})` (what dropping a note on the edge does), JSON.
- Widgets: `NoteResizablePanes` (N panes with draggable dividers, min fraction,
  axis; reports ratios), `NoteSplitView` (two panes convenience), `NoteDropSplit
  Target` (a `DragTarget<NoteDragData>` showing the left/right/top/bottom drop
  zones and reporting the side), `NoteDragData {noteId, pageIndex?}`.
- Thumbnails: `NoteThumbnailGridController` (`columns` 1–6; `scaleBy(factor)`
  with hysteresis so a pinch changes columns in steps; `sidebarVisible`),
  `NoteThumbnailGrid` (scrolling grid; builder per page; current page ring;
  selection; pinch to change columns; tap callback).
- Zoom: `NoteZoomPresets` (`ChangeNotifier`; favourite zoom levels 0.25–8, ≤ 8
  of them, sorted, `toggle(zoom)`, JSON), `NoteZoomMath` (pure: `fitWidth`,
  `fitPage`, `zoomAround(matrix, focal, scale)`, `centerOn(Rect content, Size
  viewport, scale) → Matrix4`), `NoteZoomLock` (`ChangeNotifier` bool).
- Infinite canvas: `NoteInfiniteCanvas` (pure model: `size`, `contentBounds`,
  growth step; `ensureRoom(Rect strokeBounds)` returns `NoteCanvasGrowth {size,
  shift}` where `shift` is the translation to apply to existing content when the
  canvas grew left/up; `nearestContent`/`contentCenter` for "move to content").
- Display: `NoteDisplayMode {normal, night, eyeProtect}`, `NoteDisplayFilter`
  (`ColorFiltered`: night inverts luminance while keeping hue; eye-protect adds a
  warm tint with adjustable `strength`).
- Tools on the canvas: `NoteRulerController` (`center`, `angle`, `length`,
  `visible`, `unit (pt|mm|cm|in)`; `snap(Offset point, {threshold}) → Offset`
  projecting a point onto the ruler edge when close), `NoteRuler` (draggable,
  rotatable ruler with ticks and a length label); `NoteMagnifierController`
  (`center`, `zoom` 1.5–6, `diameter`), `NoteMagnifier` (movable lens built on
  `RawMagnifier`).
- Chrome: `NoteFullScreenController` (`chromeHidden`, `toggle`) and
  `NoteChromeVisibility` (animates toolbars away).
- Tabs: `NoteTabsController` (`ChangeNotifier`: open note ids with titles,
  `active`, `open(noteId, title)` (focus if already open), `close`, `move`,
  `closeOthers`, JSON) and `NoteTabBar` (scrollable tab strip: select, close,
  drag to reorder).
- `NoteViewStrings`.

### 5.10 io — `io/`

Barrel `io/io.dart`; tests `test/note/io/`. This is the one module that may use
`dart:ui` to rasterise and `dart:io` through a conditional import where noted.

- Rendering: `NotePageRenderLayer {Scribble scribble, double opacity, bool
  visible}`, `NotePageRenderInput {NotePageSize size, void Function(Canvas,
  Size)? paintBackground, List<NotePageRenderLayer> layers, List<NoteObject>
  objects, Map<String, ui.Image> images}`, `NotePageRenderer.paint(canvas, input,
  {Rect? clip, bool includeBackground = true})` (background → layers bottom to top
  (strokes, then text, then images of each layer — the screen order — honouring `hidden`) → objects via
  `paintToCanvas`), `renderToImage(input, {pixelRatio, Rect? region,
  includeBackground})`, `renderToPng(...)`. Reuse the engine's painting:
  `StrokePaintDelegate`, `ShapePaintDelegate`, `TextDrawablePainter` (study
  `lib/src/module/painter/`, `lib/src/module/text/text_painter.dart`).
  `NoteRegionCapture.capture(input, region, {transparentBackground})` returns a
  PNG of just the ink and objects in the region with no paper — this is how a
  sticker with a transparent background is made.
- Bundles: `NoteBundleCodec.pack(NoteStore, {prefix}) → Uint8List` and
  `unpack(bytes, NoteStore, {prefix, overwrite})`: one self-describing JSON
  document `{v:1, files:{key:{enc:'utf8'|'b64', data}}}`, keys validated on
  unpack (reject unsafe keys).
- PDF export: `NotePdfWriter` — a small self-contained PDF 1.4 writer (no
  dependency): pages, vector paths (`m l c h f S`, fill/stroke colours, line
  width, caps, even-odd fill), opacity through `ExtGState`, clipping, and image
  XObjects (RGB + soft mask; `FlateDecode` when `dart.library.io` is available,
  raw otherwise), correct xref table. `NotePdfExporter.export(List<NotePage
  RenderInput>, {includeBackground}) → Uint8List`: handwriting strokes become
  **vector** filled polygons (the engine's perfect_freehand outline — study
  `lib/src/module/painters/sketch_line_painter.dart` and
  `lib/src/core/utils/stroke_calculator.dart`; pencil/marker/fixed pens use
  stroked polylines), shapes become vector paths; text boxes, images and the paper
  background are embedded as rasterised images. Tests parse the output
  structurally (header, object count, xref offsets, page count, content stream
  operators) — do not assert pixel output.
- Import: `NoteImportSource {name, bytes, mimeType?}`, `NoteImportedPage {size,
  backgroundPng?, backgroundSource?}`, `NoteDocumentImporter` (interface:
  `Future<List<NoteImportedPage>> import(NoteImportSource, {List<int>?
  pageIndices})` — `pageIndices` imports only those pages), implementations
  `NoteImageImporter` (png/jpeg; decodes the size, fits it to the page width),
  `NotePdfRendererImporter(renderer)` where `NotePdfPageRenderer` is a host
  interface (`pageCount(bytes)`, `renderPage(bytes, index, {targetWidth})`),
  `NoteOfficeImporter(converter, pdfImporter)` where `NoteOfficeConverter`
  (`toPdf(NoteImportSource)`) is a host interface for PPT/DOC/e-book conversion,
  `NoteScanImporter(scanner)` with `NoteDocumentScanner` (host interface) and
  `NoteScanFilter {none, grayscale, blackWhite(threshold)}` (pure RGBA filters,
  tested). Importing a notebook exported as PDF from another app is just the PDF
  path (the pages are flattened; say so in the docs).
- PDF text markup: `NotePdfTextRun {text, rect}` and `NotePdfTextLayer`
  (host interface: `Future<List<NotePdfTextRun>> runs(int pageIndex)`),
  `NoteTextMarkupBuilder.build(runs selected, kind (highlight|underline|
  strikeout), color) → List<Stroke>` creating engine marker/pen strokes along the
  selected runs. `NotePdfTextSelection` orders runs for reading and selects
  from one point to another. `NotePdfRendererImporter` records a
  `NotePdfOrigin {document, pageIndex, size, picture?}` on each page (core;
  `documentKey` names the PDF, the file name by default), and
  `NotePage.pdf` keeps it. `NotePdfPageMapping(page, origin)` maps PDF points
  to the page the way the paper is shown (image fit, turns, margins). In
  `NoteEditorMode.pdfText` the controller loads runs from
  `pdfTextLayer(document)`, and marks are built along the PDF lines, then
  mapped point by point, so underlines stay under the text on turned pages.
- Backup: `NoteBackupDriver` (interface: `put(name, bytes)`, `get(name)`,
  `list() → List<NoteBackupEntry {name, size, modified}>`, `delete`),
  `MemoryNoteBackupDriver`, `DirectoryNoteBackupDriver(Directory)`,
  `NoteBackupService(store, driver, {clock, retention = 10})`: `backupNow()`,
  `restore(name, {overwrite})`, `prune()` keeps the newest `retention` backups;
  `NoteAutoBackup(service, {interval, debounce, scheduler})` triggers after
  `markChanged()` (debounced) and on the interval, injectable timers. Cloud
  drivers (Google Drive, OneDrive) are host plug-ins.
- Transfer (phone → tablet): `NoteTransferPairing {sessionId, qrPayload,
  expiresAt}`, `NoteIncomingImage {name, bytes}`, `NoteImageTransferChannel`
  (interface: `Future<NoteTransferPairing> open()`, `Stream<NoteIncomingImage>
  incoming`, `close()`), `LoopbackNoteImageTransferChannel` (in-process, for
  tests and the example). The network transport is a host plug-in.
- `NoteIoStrings` if any widget is added (none required).

## 6. Integration — engine, `layer/`, `document/`, `editor/`

### Engine additions

- Style strings in new protobuf fields (`Stroke.lineStyle`/`shapeStyle` = 20/21,
  `TextDrawable.boxStyle` = 20, `ImageDrawable.imageStyle` = 20; 11–19 are left
  to `open_board`). Fields are written only when used, so plain content encodes
  as before. `StrokeStyles` and the painters render them; the PDF export
  vectorises styled strokes (`NoteStyledVectorizer`).
- `ScribbleInputOptions` (stabilisation, pressure, line and shape style, eraser
  mode, pressure eraser, hold-to-snap, rectangle lasso); the eraser hit-tests
  2-point shapes by their outline.
- `ScribbleNotifier.restyleStrokes` (with text recolour), `outlineStrokes`,
  `onHistoryCommit`; a disposed notifier leaves `DrawingState`.
- `ScribbleNotifier.strokeConstraintFor` corrects the points of a stroke, chosen
  when it starts (drawing along the ruler).
- `ScribbleWidget`: `layersBelow`, `layersAbove`, `foreground`, `inkOpacity`,
  `lassoSelection` (`ScribbleLassoSelection`), `onImageSelectionChanged`,
  `zoomEnabled`.

### `layer/`

`NoteLayerStack` keeps one `ScribbleNotifier` per layer and puts every ink
commit and layer operation on one `NoteUndoStack` (share it with object
controllers). Never call a layer notifier's `undo` directly.
`NoteLayeredPageView` edits the active layer and paints the others read-only.

### `document/`

`NoteDocument` owns pages (`NotePage`: size, paper, paper turns, extended
margins, layers, objects), the page trash, numbering, bookmarks, outline,
excerpts, tags, attachments, recordings and every-page objects. Page operations
are reversible, not undoable. Copying pages gives new ids and re-points
`pageid:` links; recordings stay on their page id, and their 1-based numbers are
computed from the current order. `NoteDocumentRepository` writes
`notes/<id>/note.json`, `pages/<id>/page.json` and one protobuf per layer;
saves run one at a time, only changed pages are rewritten, and a page changed
while it was being saved stays dirty.

### `editor/`

`NoteEditorController` holds the open page's `NotePageSession` (layer stack,
page and every-page object controllers, one history), the tools
(`NoteToolController` writes the global `DrawingState`, which the engine
re-applies at every stroke), modes, page operations, lasso and image edits,
links, search and autosave. Page switches commit first. Rotating, margins and
paper changes are one undo step each (`NotePageSession.rearrange` groups the
moved ink, the moved page objects and the page settings with
`NoteUndoStack.group`). It adopts changes made to the document directly while
the page has no unsaved edits. A retired session is disposed after the next
frame. The ruler lives in page coordinates. Endless pages grow on any side;
growth after writing joins the writing's undo step (`NoteUndoStack.amend`), and
the view keeps the content where it was on screen, also on undo and redo. The
engine reports a finished stroke for undo, redo and programmatic ink changes
too (even in the middle of a layer operation), so the view checks for growth in
a microtask and `growAfterWriting` only acts on a new ink command
(`NoteUndoStack.pushCount`). Editors shown side by side share one
`NoteToolController`. The table view registers its open cell editor with the
object layer (the one wave-1 dependency between modules added at integration),
and undo flushes pending input first: on touch screens pressing elsewhere does
not blur a field, so typed text would otherwise merge into the next step. `NoteEditorView` composes the module widgets; platform
services are optional callbacks and interfaces. `note_export.dart` draws pages
without widgets (PDF, capture, thumbnails) and turns imported pages into note
pages.

`NoteWorkspaceController` runs several editors: `NoteViewLayoutController`
panes and `NoteTabsController` tabs, one editor per pane and note (kept while
the note has a tab) over one `NoteDocument` per note, all on one
`NoteToolController`; `tools.onUndo`/`onRedo` follow the focused pane. It
looks at editor changes in a microtask: a page turned in a pane moves the
layout (the other half of a spread follows), and a pane whose note another
editor also has commits each finished history step at once, so that editor
re-reads the page. Two editors on one page would each hold a copy and the last
commit would win, so a pane on the focused pane's page (or on the same note
while the focused pane edits an object) only mirrors until focused. Leaving a
pane commits it on a later task, after a text field that lost keyboard focus
handed in its text; an editor that leaves the screen commits at once. A tab or
pane that no longer needs an editor saves it and disposes it after the next
frame, and only then is `onDocumentClosed` called (reopening first reuses the
document). Only the second page of a two-page spread may point past the last
page; it offers a new page.

## 7. Feature map (what the reviewed apps do → where it lives)

| Feature seen in the review videos | Module |
| --- | --- |
| Motion smoothing / stroke stabilization / pressure sensitivity | tools `NotePenSettings` + engine |
| Pen favourites (colour + numeric width), toolbar order/placement | tools |
| Dashed / dotted / wavy / zigzag / double-line pens, dash length & gap | style + engine |
| Hold-to-snap shape, auto-shape toggle | engine |
| Pixel vs stroke eraser, eraser by pressure | tools settings + engine |
| Apple Pencil double-tap / squeeze | tools `NotePencilGestureDispatcher` (host binds) |
| Shapes (2-D and 3-D), corner radius, opacity; drag a line to bend it into a curve | style + engine; curves: objects `NoteArrowObject.bend` + editor grip |
| Tables with merge | table |
| Text style presets, text-box styling, custom fonts | tools + style + engine |
| Image frame / opacity / crop, multi-image insert | style + engine |
| Restyle written ink (colour/width/dash), outline-text effect | engine |
| Screenshot to transparent sticker, sticker collections | io `NoteRegionCapture` + objects stickers |
| Sticky notes, arrows, link hotspots | objects |
| Layers (re-solve, hide, merge, order) | layer (integrator) |
| Page templates (spacing, width, colour, size), image templates, template store | template |
| Mixed portrait/landscape pages, rotate, add before/after/last, import pages, page numbers, margin extension | document (integrator) |
| Infinite canvas, move to content, zoom favourites, zoom lock | view |
| Folders, pin, drawer view (pinch zoom), list view, sort, multi-select, covers | library |
| Tags on notes and pages | library + nav |
| Hyperlinks (long-press / tap), links on objects | objects + nav + core links |
| Bookmarks, outline, excerpts with labels and flash highlight | nav |
| Two-page, double reading, dual document, split view, tabs | view + editor `NoteWorkspaceView` |
| Thumbnails grid | view + editor pages panel |
| Night / eye-protect, ruler, magnifier, full screen | view |
| Import PDF/PPT/DOC/scan/GoodNotes-PDF, specific pages | io |
| Vector PDF export, PNG, bundles, backup | io |
| Text selection to underline/highlight on PDF | io `NoteTextMarkupBuilder` + host text layer |
| Cover-up pen / board / tape | study/overlay |
| AI pen (solve / explain / translate), screenshot pen | study/overlay + io |
| Floating ChatGPT/web windows | study/overlay `NoteFloatingWindowHost` |
| Calculator, timer, stopwatch, scratchpad | study/utilities |
| Audio recording with speed, video/doc attachments | study/utilities |
| Handwriting search, cloud sync, real-time sync | host plug-ins (`NoteHandwritingIndexer`, `NoteBackupDriver`) |

Features that need a platform service the package cannot ship (OCR, a PDF
renderer, a document scanner, microphone/camera, network, a browser view) are
provided as small interfaces with fakes, so apps plug their own implementation in.
