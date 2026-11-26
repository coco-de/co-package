/// The standard toolbar item ids. Item ids are plain strings, so hosts may add
/// their own; the standard values are persisted and never change.
abstract final class NoteToolbarItemIds {
  /// Pen tool.
  static const String pen = 'pen';

  /// Pencil tool.
  static const String pencil = 'pencil';

  /// Highlighter tool.
  static const String marker = 'marker';

  /// Eraser tool.
  static const String eraser = 'eraser';

  /// Lasso selection tool.
  static const String lasso = 'lasso';

  /// Shape tool.
  static const String shape = 'shape';

  /// Text tool.
  static const String text = 'text';

  /// Image tool.
  static const String image = 'image';

  /// Undo button.
  static const String undo = 'undo';

  /// Redo button.
  static const String redo = 'redo';

  /// Layers button.
  static const String layers = 'layers';

  /// Pen favourites.
  static const String presets = 'presets';

  /// The standard ids in their default order.
  static const List<String> standard = [
    pen,
    pencil,
    marker,
    eraser,
    lasso,
    shape,
    text,
    image,
    undo,
    redo,
    layers,
    presets,
  ];
}
