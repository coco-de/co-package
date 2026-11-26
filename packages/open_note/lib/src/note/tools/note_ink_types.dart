/// The tool strings of the engine, as the tool layer uses them.
///
/// The values are the ones the engine stores in `Stroke.ink` and accepts in its
/// tool selection (`InkModes`). They are repeated here because that engine file
/// depends on `material.dart`, which this module must not import. They are
/// persisted inside presets, so they never change.
abstract final class NoteInkTypes {
  /// Pressure sensitive pen.
  static const String pen = 'pen';

  /// Textured pencil.
  static const String pencil = 'pencil';

  /// Translucent highlighter.
  static const String marker = 'marker';

  /// Pen whose width stays the same on screen while the page is zoomed.
  static const String fixedPen = 'fixedPen';

  /// Pen with a uniform width that scales with the page.
  static const String uniformPen = 'uniformPen';

  /// Shape tool.
  static const String shape = 'shape';

  /// Text tool.
  static const String text = 'text';

  /// Eraser. A tool, never the ink of a preset.
  static const String erase = 'erase';

  /// Lasso selection. A tool, never the ink of a preset.
  static const String lasso = 'lasso';

  /// Image tool. A tool, never the ink of a preset.
  static const String image = 'image';

  /// The inks a tool preset may use, in the order a UI should offer them.
  static const List<String> presetInks = [
    pen,
    pencil,
    marker,
    fixedPen,
    uniformPen,
    shape,
    text,
  ];

  /// Whether [ink] is one of [presetInks] (case sensitive).
  static bool isPresetInk(String ink) => presetInks.contains(ink);
}
