/// Where a search hit comes from. The names are persisted.
enum NoteSearchHitKind {
  /// A typed text box on a page.
  text,

  /// The label or note of an excerpt.
  excerpt,

  /// The title of a bookmark.
  bookmark,

  /// The title of an outline entry.
  outline,

  /// A tag.
  tag,

  /// Recognised handwriting (supplied by a host `NoteHandwritingIndexer`).
  handwriting,
}
