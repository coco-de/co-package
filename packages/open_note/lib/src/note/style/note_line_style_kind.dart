/// How a stroked line is decorated.
///
/// The names are persisted (see `NoteLineStyle.encode`), so they never change.
enum NoteLineStyleKind {
  /// A continuous line.
  solid,

  /// Dashes separated by gaps, with flat (butt) ends.
  dashed,

  /// Round dots separated by gaps.
  dotted,

  /// A sine wave around the base line.
  wavy,

  /// A triangular wave around the base line.
  zigzag,

  /// Two parallel lines.
  double,
}
