/// The ruling of a paper. The names are persisted.
enum NotePaperKind {
  /// Plain paper.
  blank,

  /// Horizontal rules.
  lined,

  /// Squares.
  grid,

  /// A dot grid.
  dotted,

  /// A cue column, a title area, a ruled note area and a summary area.
  cornell,

  /// Five-line staves.
  music,

  /// A picture used as the paper.
  image;

  /// Whether the kind draws ruling, so that line spacing and line width change
  /// what it looks like (`blank` and `image` do not).
  bool get isRuled => switch (this) {
    lined || grid || dotted || cornell || music => true,
    blank || image => false,
  };
}
