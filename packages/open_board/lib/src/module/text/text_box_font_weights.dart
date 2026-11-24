import 'package:flutter/material.dart';

/// Display weights for the regular and bold styles of text box annotations.
typedef TextBoxFontWeights = ({FontWeight regular, FontWeight bold});

/// The standard display weights for a text box.
const TextBoxFontWeights defaultTextBoxFontWeights = (
  regular: FontWeight.normal,
  bold: FontWeight.bold,
);

extension TextBoxFontWeightStyle on TextBoxFontWeights {
  /// Resolves display weight without modifying the style used for persistence.
  TextStyle applyTo(TextStyle style) {
    if (this == defaultTextBoxFontWeights) return style;
    return switch (style.fontWeight) {
      null || FontWeight.normal => style.copyWith(fontWeight: regular),
      FontWeight.bold => style.copyWith(fontWeight: bold),
      _ => style,
    };
  }
}
