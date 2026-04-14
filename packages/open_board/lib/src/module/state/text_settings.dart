  import 'package:flutter/material.dart';

  /// Text alignment options
  enum TextAlignment { left, center, right }

  extension TextAlignmentExtension on TextAlignment {
    String get value {
      switch (this) {
        case .left:
          return 'left';
        case .center:
          return 'center';
        case .right:
          return 'right';
      }
    }

    TextAlign get textAlign {
      switch (this) {
        case .left:
          return .left;
        case .center:
          return .center;
        case .right:
          return .right;
      }
    }

    static TextAlignment fromString(String value) {
      switch (value) {
        case 'left':
          return .left;
        case 'center':
          return .center;
        case 'right':
          return .right;
        default:
          return .center;
      }
    }
  }

  /// Settings for text drawables
  class TextSettings {
    /// The text style to be used for new text drawables
    final TextStyle textStyle;

    /// The text alignment to be used for new text drawables
    final TextAlignment textAlignment;

    /// Creates a [TextSettings] object
    const TextSettings({
      this.textStyle = const TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: .normal,
      ),
      this.textAlignment = TextAlignment.center,
    });

    @override
    int get hashCode => textStyle.hashCode ^ textAlignment.hashCode;

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
        other is TextSettings &&
            runtimeType == other.runtimeType &&
            textStyle == other.textStyle &&
            textAlignment == other.textAlignment;
  }
