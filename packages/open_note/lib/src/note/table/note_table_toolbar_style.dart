import 'package:flutter/widgets.dart';

/// The look of a `NoteTableToolbar`, in logical pixels.
@immutable
class NoteTableToolbarStyle {
  /// Creates a style with light, neutral defaults.
  const NoteTableToolbarStyle({
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFFE0E0E0),
    this.buttonColor = const Color(0xFFF5F5F5),
    this.foregroundColor = const Color(0xFF212121),
    this.disabledColor = const Color(0xFFBDBDBD),
    this.fontSize = 13,
    this.spacing = 4,
    this.buttonPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
    this.radius = 6,
  });

  /// Background of the bar.
  final Color backgroundColor;

  /// Outline of the bar.
  final Color borderColor;

  /// Background of the buttons.
  final Color buttonColor;

  /// Label colour of enabled buttons.
  final Color foregroundColor;

  /// Label colour of disabled buttons.
  final Color disabledColor;

  /// Label text size.
  final double fontSize;

  /// Space between buttons and around the bar.
  final double spacing;

  /// Space inside each button.
  final EdgeInsets buttonPadding;

  /// Corner radius of the bar and buttons.
  final double radius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTableToolbarStyle &&
          other.backgroundColor == backgroundColor &&
          other.borderColor == borderColor &&
          other.buttonColor == buttonColor &&
          other.foregroundColor == foregroundColor &&
          other.disabledColor == disabledColor &&
          other.fontSize == fontSize &&
          other.spacing == spacing &&
          other.buttonPadding == buttonPadding &&
          other.radius == radius;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    buttonColor,
    foregroundColor,
    disabledColor,
    fontSize,
    spacing,
    buttonPadding,
    radius,
  );
}
