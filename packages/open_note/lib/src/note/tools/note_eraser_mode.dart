/// How the eraser removes ink. The names are persisted.
enum NoteEraserMode {
  /// Removes every stroke the eraser touches as a whole.
  stroke,

  /// Removes only the parts under the eraser.
  pixel,
}
