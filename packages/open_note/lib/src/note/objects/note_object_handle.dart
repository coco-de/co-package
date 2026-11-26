/// A grip of the selection frame around a single object.
///
/// For the eight resize grips, [horizontal] and [vertical] say which sides of
/// the unrotated bounds the grip moves: `-1` is the left or top side, `1` the
/// right or bottom side and `0` leaves that axis alone.
enum NoteObjectHandle {
  /// Resizes the left and top sides.
  topLeft(-1, -1),

  /// Resizes the top side.
  top(0, -1),

  /// Resizes the right and top sides.
  topRight(1, -1),

  /// Resizes the right side.
  right(1, 0),

  /// Resizes the right and bottom sides.
  bottomRight(1, 1),

  /// Resizes the bottom side.
  bottom(0, 1),

  /// Resizes the left and bottom sides.
  bottomLeft(-1, 1),

  /// Resizes the left side.
  left(-1, 0),

  /// Rotates the object about its center; moves no side.
  rotate(0, 0);

  const NoteObjectHandle(this.horizontal, this.vertical);

  /// The horizontal side this grip moves: `-1`, `0` or `1`.
  final int horizontal;

  /// The vertical side this grip moves: `-1`, `0` or `1`.
  final int vertical;

  /// Whether this grip changes the size (every grip except [rotate]).
  bool get isResize => this != rotate;
}
