/// A stylus gesture the host reports (Apple Pencil). The names are persisted.
enum NotePencilGesture {
  /// Two quick taps on the side of the pencil.
  doubleTap,

  /// A squeeze of the pencil.
  squeeze,
}

/// What a stylus gesture does. The names are persisted.
enum NotePencilAction {
  /// Nothing.
  none,

  /// Goes back to the previously used tool.
  switchPreviousTool,

  /// Switches between the eraser and the tool used before it.
  toggleEraser,

  /// Undoes the last edit.
  undo,

  /// Redoes the last undone edit.
  redo,

  /// Opens the tool palette.
  showToolPalette,

  /// Selects the next pen favourite.
  cyclePreset,
}
