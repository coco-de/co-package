/// What pointers on the page do.
enum NoteEditorMode {
  /// Write, erase and select with the lasso; objects let pointers through.
  draw,

  /// Select, move, resize and edit objects.
  objects,

  /// Read: masks reveal on tap and links open; nothing is drawn.
  read,

  /// Drag over the page to cover part of it with a mask.
  maskPen,

  /// Drag a rectangle to cut it out (a sticker, or a question for the AI pen).
  region,

  /// Select text on an imported PDF page, to highlight, underline or copy it.
  pdfText,
}

/// Where a new or imported page goes, relative to the current one.
enum NotePageInsertPosition { before, after, end }
