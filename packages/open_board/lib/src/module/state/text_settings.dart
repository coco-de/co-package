import 'package:flutter/material.dart';

/// Text alignment options
enum TextAlignment { left, center, right }

extension TextAlignmentExtension on TextAlignment {
  String get value {
    switch (this) {
      case TextAlignment.left:
        return 'left';
      case TextAlignment.center:
        return 'center';
      case TextAlignment.right:
        return 'right';
    }
  }

  TextAlign get textAlign {
    switch (this) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }

  static TextAlignment fromString(String value) {
    switch (value) {
      case 'left':
        return TextAlignment.left;
      case 'center':
        return TextAlignment.center;
      case 'right':
        return TextAlignment.right;
      default:
        return TextAlignment.center;
    }
  }
}

/// Settings for text drawables
class TextSettings {
  /// The text style to be used for new text drawables
  final TextStyle textStyle;

  /// The text alignment to be used for new text drawables
  final TextAlignment textAlignment;

  /// Focus node for the text field
  final FocusNode? focusNode;

  /// Creates a [TextSettings] object
  const TextSettings({
    this.textStyle = const TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.normal,
    ),
    this.textAlignment = TextAlignment.center,
    this.focusNode,
  });

  /// Creates a copy of this [TextSettings] with the given fields replaced
  TextSettings copyWith({
    TextStyle? textStyle,
    TextAlignment? textAlignment,
    FocusNode? focusNode,
  }) {
    return TextSettings(
      textStyle: textStyle ?? this.textStyle,
      textAlignment: textAlignment ?? this.textAlignment,
      focusNode: focusNode ?? this.focusNode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSettings &&
          runtimeType == other.runtimeType &&
          textStyle == other.textStyle &&
          textAlignment == other.textAlignment &&
          focusNode == other.focusNode;

  @override
  int get hashCode =>
      textStyle.hashCode ^ textAlignment.hashCode ^ focusNode.hashCode;
}
