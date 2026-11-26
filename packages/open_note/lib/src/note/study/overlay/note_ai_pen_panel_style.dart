import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours and metrics of `NoteAiPenResultPanel`.
@immutable
class NoteAiPenPanelStyle {
  /// Creates a style; every value has a usable default.
  const NoteAiPenPanelStyle({
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFFE0E0E0),
    this.accentColor = const Color(0xFF2962FF),
    this.textColor = const Color(0xFF212121),
    this.mutedTextColor = const Color(0xFF757575),
    this.errorColor = const Color(0xFFC62828),
    this.fontSize = 14,
    this.maxHeight = 360,
    this.cornerRadius = 12,
    this.padding = 12,
  }) : assert(maxHeight > 0, 'maxHeight must be positive');

  /// Panel background.
  final Color backgroundColor;

  /// Panel border and tab separator.
  final Color borderColor;

  /// Selected tab, spinner and action buttons.
  final Color accentColor;

  /// The answer.
  final Color textColor;

  /// Hints, unselected tabs and headings.
  final Color mutedTextColor;

  /// Failure messages.
  final Color errorColor;

  /// Size of all text.
  final double fontSize;

  /// The panel never grows taller; longer answers scroll.
  final double maxHeight;

  /// Corner radius of the panel.
  final double cornerRadius;

  /// Inner spacing.
  final double padding;

  @override
  bool operator ==(Object other) =>
      other is NoteAiPenPanelStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.accentColor == accentColor &&
      other.textColor == textColor &&
      other.mutedTextColor == mutedTextColor &&
      other.errorColor == errorColor &&
      other.fontSize == fontSize &&
      other.maxHeight == maxHeight &&
      other.cornerRadius == cornerRadius &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    accentColor,
    textColor,
    mutedTextColor,
    errorColor,
    fontSize,
    maxHeight,
    cornerRadius,
    padding,
  );
}
