import 'package:flutter/widgets.dart';

/// The look of the interactive parts of a `NoteTableView` (not persisted).
/// Lengths are page units, as the view is laid out in page coordinates.
@immutable
class NoteTableViewStyle {
  /// Creates a style with defaults that read on white paper.
  const NoteTableViewStyle({
    this.selectionColor = const Color(0xFF2962FF),
    this.selectionFillColor = const Color(0x1F2962FF),
    this.selectionBorderWidth = 1.5,
    this.editorColor = const Color(0xFFFFFFFF),
    this.cursorColor = const Color(0xFF2962FF),
  });

  /// Border of the selection highlight and of the cell editor.
  final Color selectionColor;

  /// Translucent fill over the selected cells.
  final Color selectionFillColor;

  /// Width of those borders.
  final double selectionBorderWidth;

  /// Background of the cell editor.
  final Color editorColor;

  /// Text cursor of the cell editor.
  final Color cursorColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTableViewStyle &&
          other.selectionColor == selectionColor &&
          other.selectionFillColor == selectionFillColor &&
          other.selectionBorderWidth == selectionBorderWidth &&
          other.editorColor == editorColor &&
          other.cursorColor == cursorColor;

  @override
  int get hashCode => Object.hash(
    selectionColor,
    selectionFillColor,
    selectionBorderWidth,
    editorColor,
    cursorColor,
  );
}
