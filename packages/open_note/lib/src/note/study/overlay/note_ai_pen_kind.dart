/// What the AI pen is asked to do with a selection. The `name`s are persisted.
enum NoteAiPenKind {
  /// Solve the problem in the selection.
  solve,

  /// Explain what the selection says.
  explain,

  /// Translate the selection (into the request's target locale).
  translate,
}
