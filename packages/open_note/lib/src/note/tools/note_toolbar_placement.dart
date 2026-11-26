/// Whether the toolbar sits on an edge or floats over the page. The names are
/// persisted.
enum NoteToolbarPlacement {
  /// Attached to the edge given by `NoteToolbarLayout.dockEdge`.
  docked,

  /// Free over the page at `NoteToolbarLayout.floatingOffset`.
  floating,
}
