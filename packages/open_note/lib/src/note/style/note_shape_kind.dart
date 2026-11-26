/// The shapes the note editor can draw. The names are persisted. Where a shape
/// sits in its rectangle is documented on `NoteShapeGeometry`.
enum NoteShapeKind {
  /// A straight segment.
  line,

  /// A segment with a head at its end.
  arrow,

  /// A segment with a head at both ends.
  doubleArrow,

  /// A rectangle (rounded only with a corner radius).
  rectangle,

  /// A rectangle that is always rounded.
  roundedRectangle,

  /// The ellipse inscribed in the rectangle.
  ellipse,

  /// An isosceles triangle, apex up.
  triangle,

  /// A right triangle with the right angle at the bottom left.
  rightTriangle,

  /// A rhombus through the middle of each edge.
  diamond,

  /// A pentagon, apex up.
  pentagon,

  /// A hexagon with a flat top and bottom.
  hexagon,

  /// A five-pointed star.
  star,

  /// An isometric cube.
  cube,

  /// An upright cylinder.
  cylinder,

  /// A cone, apex up.
  cone,

  /// A square pyramid.
  pyramid,

  /// A sphere with its equator.
  sphere;

  /// `line`, `arrow` and `doubleArrow`: open shapes that run from the first
  /// corner of their rectangle to the opposite one.
  bool get isLinear => this == line || this == arrow || this == doubleArrow;

  /// The isometric 3-D wire frames, which have hidden edges.
  bool get isThreeDimensional => switch (this) {
    cube || cylinder || cone || pyramid || sphere => true,
    _ => false,
  };
}
