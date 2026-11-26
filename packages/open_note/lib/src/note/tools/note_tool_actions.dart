/// What a stylus gesture (or any shortcut) can ask the editor to do. The editor
/// implements it and `NotePencilGestureDispatcher` calls it.
///
/// A tool is an engine string: one of `NoteInkTypes.presetInks`, or `erase`,
/// `lasso` or `image`.
abstract interface class NoteToolActions {
  /// The tool in use.
  String get currentTool;

  /// Selects the tool [ink].
  void selectTool(String ink);

  /// Selects the tool that was in use before the current one.
  void previousTool();

  /// Switches between the eraser and the tool used before it.
  void toggleEraser();

  /// Undoes the last edit.
  void undo();

  /// Redoes the last undone edit.
  void redo();

  /// Opens the tool palette.
  void showToolPalette();

  /// Selects the next pen favourite (see `NotePresetStore.selectNext`) and
  /// applies it.
  void cyclePreset();
}
